"""Exercise the real watcher entrypoint and workflow cleanup in child shells."""

import os
from pathlib import Path
import signal
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
WATCHER = ROOT / "scripts/recover_ios_vm_service.sh"
LAUNCH = (
    "[ ] executing: xcrun simctl launch test-device com.clubhouse.livingpositively "
    "--enable-dart-profiling --disable-vm-service-publication "
    "--enable-checked-mode --verify-entry-points"
)
WAITING = "com.clubhouse.livingpositively: 40050\nWaiting for VM Service port to be available\n"
ANNOUNCEMENT = "Runner[40050:123] The Dart VM service is listening on http://127.0.0.1:1234/token/\n"


class WatcherCliTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.path = Path(self.directory.name)
        self.flutter_log = self.path / "flutter.log"
        self.simulator_log = self.path / "simulator.log"
        self.flutter_log.write_text("")
        self.simulator_log.write_text(ANNOUNCEMENT)
        self.environment_file = self.path / "environment.sh"
        self.environment_file.write_text(r'''
polls=0
kill() { if [ "$1" = -0 ]; then return 0; else builtin kill "$@"; fi; }
xcrun() {
  printf '%s\n' "$*" >> "$TEST_DIRECTORY/calls"
  [ "$2" != "${FAILED_COMMAND:-}" ]
}
sleep() {
  printf '%s\n' "$1" >> "$TEST_DIRECTORY/sleeps"
  if [ "$1" = 5 ]; then
    polls=$((polls + 1))
    if [ "$SCENARIO" = late ] && [ "$polls" -eq 961 ]; then
      printf '%s\n%s' "$LAUNCH" "$WAITING" > "$TEST_DIRECTORY/flutter.log"
    fi
  fi
  if { [ "$SCENARIO" = cleanup-poll ] && [ "$1" = 5 ]; } ||
     { [ "$SCENARIO" = cleanup-grace ] && [ "$1" = 120 ]; }; then
    command sleep 60 &
    printf '%s\n' "$!" > "$TEST_DIRECTORY/sleep.pid"
    touch "$TEST_DIRECTORY/ready"
    wait "$!"
  fi
}
''')
        self.environment = dict(
            os.environ,
            BASH_ENV=str(self.environment_file),
            TEST_DIRECTORY=str(self.path),
            SCENARIO="normal",
            LAUNCH=LAUNCH,
            WAITING=WAITING,
        )
        self.args = ["test-device", str(self.flutter_log), str(self.simulator_log), "0"]

    def run_watcher(self, args=None):
        return subprocess.run(
            ["bash", str(WATCHER), *(self.args if args is None else args)],
            env=self.environment, text=True, capture_output=True, timeout=45,
        )

    def assert_no_simulator_commands(self):
        self.assertFalse((self.path / "calls").exists())

    def test_should_reject_missing_or_invalid_arguments(self):
        for args in ([], self.args[:3], [*self.args[:3], "-1"], [*self.args[:3], "oops"]):
            with self.subTest(args=args):
                result = self.run_watcher(args)
                self.assertEqual(result.returncode, 1, result.stderr)
                self.assertIn("Usage:", result.stderr)
                self.assert_no_simulator_commands()

    def test_should_exit_without_recovery_after_connection_or_flutter_failure(self):
        for line in ("VM Service URL on device", "exiting with code 1"):
            with self.subTest(line=line):
                self.flutter_log.write_text(line)
                result = self.run_watcher()
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assert_no_simulator_commands()
                self.assertFalse((self.path / "sleeps").exists())

    def test_should_poll_for_the_full_ninety_minute_parent_budget(self):
        result = self.run_watcher()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.path / "sleeps").read_text().splitlines(), ["5"] * 1080)
        self.assertIn("No recoverable", result.stdout)
        self.assert_no_simulator_commands()

    def test_should_still_recover_after_eighty_minutes(self):
        self.environment["SCENARIO"] = "late"
        result = self.run_watcher()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.path / "sleeps").read_text().splitlines(), ["5"] * 961 + ["120"])
        self.assertEqual((self.path / "calls").read_text().splitlines(), [
            "simctl terminate test-device com.clubhouse.livingpositively",
            LAUNCH.split("xcrun ", 1)[1],
        ])

    def test_should_propagate_recovery_command_failure(self):
        self.flutter_log.write_text(LAUNCH + "\n" + WAITING)
        for command, count in (("terminate", 1), ("launch", 2)):
            with self.subTest(command=command):
                (self.path / "calls").unlink(missing_ok=True)
                self.environment["FAILED_COMMAND"] = command
                result = self.run_watcher()
                self.assertEqual(result.returncode, 1, result.stderr)
                self.assertEqual(len((self.path / "calls").read_text().splitlines()), count)

class WorkflowCleanupTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.path = Path(self.directory.name)
        workflow = (ROOT / ".github/workflows/main.yml").read_text()
        # Execute the complete production step, including launch wiring, the
        # actual EXIT trap, retries, final status, and post-test diagnostics.
        step = workflow.split("      - name: Run iOS integration test with diagnostics\n", 1)[1]
        block = step.split("        run: |\n", 1)[1].split("\n      - name:", 1)[0]
        self.production = "\n".join(line[10:] if line else "" for line in block.splitlines())
        self.driver = self.path / "driver.sh"
        self.driver.write_text(self.production)
        scripts = self.path / "scripts"
        scripts.mkdir()
        shutil.copyfile(WATCHER, scripts / WATCHER.name)
        self.environment_file = self.path / "environment.sh"
        self.environment_file.write_text(r'''
record_process() {
  printf '%s %s\n' "$1" "$BASHPID" >> "$TEST_DIRECTORY/processes"
}
sleep() {
  if [ "$1" = 5 ] && { [ "$SCENARIO" = grace ] || [ "$SCENARIO" = owner-completes ]; }; then
    until grep -Eq 'Waiting for VM Service|exiting with code' ci-ios-diagnostics/flutter-test-first.log; do command sleep 0.01; done
    return 0
  fi
  if [ "$1" = 4800 ] || [ "$1" = 5 ] || [ "$1" = 120 ]; then
    record_process "sleep-$1"
    command sleep 60 &
    printf 'sleeper %s\n' "$!" >> "$TEST_DIRECTORY/processes"
    touch "$TEST_DIRECTORY/ready-$1"
    if [ "$1" = 5 ] && [[ "$SCENARIO" == late-child* ]]; then
      until [ -f "$TEST_DIRECTORY/spawn-late-child" ]; do command sleep 0.01; done
      bash -c 'trap "" TERM; command sleep 60' &
      printf 'late-child %s\n' "$!" >> "$TEST_DIRECTORY/processes"
      touch "$TEST_DIRECTORY/late-child-ready"
      if [ "$SCENARIO" = late-child-completes ]; then return 0; fi
    fi
    wait "$!"
  else
    command sleep "$@"
  fi
}
xcrun() {
  printf '%s\n' "$*" >> "$TEST_DIRECTORY/simulator-calls"
  if [ "$2" = spawn ]; then
    record_process simulator
    touch "$TEST_DIRECTORY/simulator-ready"
    command sleep 60 &
    printf 'simulator-child %s\n' "$!" >> "$TEST_DIRECTORY/processes"
    wait "$!"
  fi
}
find() { :; }
ps() {
  if [ "$1" = -axo ] && [ "$2" = pgid=,stat= ] &&
     [ "$FAULT" = post-kill ] && [ -f "$TEST_DIRECTORY/watcher-killed" ]; then
    return 1
  fi
  if [ "$1" = -o ] && [ "$2" = pid=,pgid=,ppid=,lstart= ]; then
    local owner="${@: -1}" identity role
    if [ "$FAULT" = post-kill ] && [ -f "$TEST_DIRECTORY/watcher-killed" ] &&
       [ "$owner" = "${VM_RECOVERY_PID:-}" ]; then
      # Simulate a stale successful identity read after KILL. The retirement
      # fence must reject this before consulting ps or signalling the ID again.
      cat "$TEST_DIRECTORY/identity-$owner"
      return 0
    fi
    identity=$(command ps "$@") || return
    printf '%s\n' "$identity" > "$TEST_DIRECTORY/identity-$owner"
    role=watcher
    [ "$owner" != "${SIM_LOG_PID:-}" ] || role=simulator
    [ "$owner" != "${WATCHDOG_PID:-}" ] || role=watchdog
    printf '%s %s\n' "$role" "$owner" >> "$TEST_DIRECTORY/owners"
    if [ -f "$TEST_DIRECTORY/inject-failure" ] && [ "$role" = "$FAILED_ROLE" ]; then
      case "$FAULT" in
        missing) return 1 ;;
        reused) printf '%s different-start-time\n' "$identity"; return ;;
        pgid) printf '%s %s %s fake-start-time\n' "$owner" "$$" "$$"; return ;;
      esac
    fi
    printf '%s\n' "$identity"
  else
    command ps "$@"
  fi
}
kill() {
  if [ "$1" = -0 ]; then return 0; fi
  printf '%s\n' "$*" >> "$TEST_DIRECTORY/signals"
  if [ "$FAULT" = post-kill ] && [ -f "$TEST_DIRECTORY/watcher-killed" ] &&
     [ "${@: -1}" = "-${VM_RECOVERY_PID:-}" ]; then
    # A broken retirement fence is observable, but never send a real signal
    # to the numeric identity after the original process has been killed.
    return 1
  fi
  if [ "$1" = -STOP ] && [[ "$SCENARIO" == late-child* ]] &&
     [ "${@: -1}" = "-${VM_RECOVERY_PID:-}" ]; then
    touch "$TEST_DIRECTORY/spawn-late-child"
    until [ -f "$TEST_DIRECTORY/late-child-ready" ]; do command sleep 0.01; done
    if [ "$SCENARIO" = late-child-completes ]; then
      until command ps -o stat= -p "$VM_RECOVERY_PID" | grep -q T; do command sleep 0.01; done
    fi
  fi
  if [ "$1" = -KILL ] && [ -f "$TEST_DIRECTORY/inject-failure" ] &&
     [ "$FAULT" = kill ] && [ "${@: -1}" = "-${VM_RECOVERY_PID:-}" ]; then
    return 1
  fi
  builtin kill "$@" || return
  if [ "$1" = -KILL ] && [ "$FAULT" = post-kill ] &&
     [ "${@: -1}" = "-${VM_RECOVERY_PID:-}" ]; then
    touch "$TEST_DIRECTORY/watcher-killed"
  fi
}
flutter() {
  if [ "$1" = devices ]; then return 0; fi
  record_process flutter
  printf 'attempt\n' >> "$TEST_DIRECTORY/attempts"
  until [ -f "$TEST_DIRECTORY/simulator-ready" ] && [ -f "$TEST_DIRECTORY/ready-4800" ]; do command sleep 0.01; done
  if [ "$SCENARIO" = grace ]; then
    printf '%s\n%s' "$LAUNCH" "$WAITING"
    printf '%s' "$ANNOUNCEMENT" >> ci-ios-diagnostics/simulator.log
    until [ -f "$TEST_DIRECTORY/ready-120" ]; do command sleep 0.01; done
  elif [ "$SCENARIO" = owner-completes ]; then
    printf 'exiting with code 0\n'
    until command ps -o stat= -p "$VM_RECOVERY_PID" | grep -q T; do command sleep 0.01; done
  else
    until [ -f "$TEST_DIRECTORY/ready-5" ]; do command sleep 0.01; done
    if [ "$SCENARIO" = late-child-completes ]; then printf 'exiting with code 0\n'; fi
  fi
  touch "$TEST_DIRECTORY/inject-failure"
  if [ "$SCENARIO" = frontboard ]; then printf 'is unknown to FrontBoard\n'; fi
  return "$FLUTTER_EXIT"
}
''')
        self.environment = dict(
            os.environ, BASH_ENV=str(self.environment_file), TEST_DIRECTORY=str(self.path),
            DEVICE_ID="test-device", SCENARIO="poll", FLUTTER_EXIT="0", FAILED_ROLE="",
            FAULT="", LAUNCH=LAUNCH, WAITING=WAITING, ANNOUNCEMENT=ANNOUNCEMENT,
        )

    def run_workflow(self, **environment):
        self.environment.update(environment)
        # A real unrelated process is in a different group and never a mock
        # signal target. Fixture cleanup only targets our recorded child groups.
        unrelated = subprocess.Popen(["sleep", "60"], start_new_session=True)
        output = self.path / "output"
        try:
            with output.open("w") as stream:
                result = subprocess.run(
                    ["bash", "-e", "-o", "pipefail", str(self.driver)],
                    cwd=self.path, env=self.environment, stdout=stream, stderr=stream, timeout=20,
                )
            self.assertIsNone(unrelated.poll(), output.read_text())
            # Capture liveness BEFORE fixture cleanup so a no-op production
            # cleanup cannot pass because the test's finally block kills it.
            self.remaining_jobs = {}
            for line in (self.path / "processes").read_text().splitlines():
                name, pid = line.split()
                state = subprocess.run(["ps", "-o", "stat=", "-p", pid], text=True, capture_output=True).stdout.strip()
                if state and not state.startswith("Z"):
                    self.remaining_jobs[f"{name}: {pid}"] = state
            return result.returncode, output.read_text()
        finally:
            if (self.path / "owners").exists():
                for owner in set(int(line.split()[1]) for line in (self.path / "owners").read_text().splitlines()):
                    try:
                        os.killpg(owner, signal.SIGKILL)
                    except ProcessLookupError:
                        pass
            unrelated.terminate()
            unrelated.wait(timeout=5)

    def owners(self):
        return dict(line.split() for line in (self.path / "owners").read_text().splitlines())

    def assert_jobs_stopped(self):
        self.assertEqual(self.remaining_jobs, {})

    def test_should_reap_poll_sleepers_and_all_diagnostics_on_success(self):
        status, output = self.run_workflow()
        self.assertEqual(status, 0, output)
        self.assert_jobs_stopped()
        signals = (self.path / "signals").read_text().splitlines()
        for owner in self.owners().values():
            self.assertEqual(signals.count(f"-KILL -- -{owner}"), 1)
        self.assertTrue((self.path / "ci-ios-diagnostics/post-test.txt").exists())

    def test_should_reap_grace_sleepers_and_preserve_test_failure(self):
        status, output = self.run_workflow(SCENARIO="grace", FLUTTER_EXIT="42")
        self.assertEqual(status, 42, output)
        self.assert_jobs_stopped()
        self.assertNotIn("simctl terminate", (self.path / "simulator-calls").read_text())

    def test_should_keep_completed_watcher_leader_until_cleanup(self):
        status, output = self.run_workflow(SCENARIO="owner-completes")
        self.assertEqual(status, 0, output)
        self.assert_jobs_stopped()

    def test_should_stop_a_child_forked_after_cleanup_starts(self):
        status, output = self.run_workflow(SCENARIO="late-child")
        self.assertEqual(status, 0, output)
        self.assertTrue((self.path / "late-child-ready").exists())
        self.assert_jobs_stopped()

    def test_should_stop_a_late_child_after_the_watcher_command_completes(self):
        status, output = self.run_workflow(SCENARIO="late-child-completes")
        self.assertEqual(status, 0, output)
        self.assertTrue((self.path / "late-child-ready").exists())
        self.assert_jobs_stopped()

    def test_should_reject_unverified_group_without_any_signal_and_clean_other_jobs(self):
        status, output = self.run_workflow(FAULT="pgid", FAILED_ROLE="watcher", FLUTTER_EXIT="42")
        self.assertEqual(status, 42, output)
        owners = self.owners()
        signals = (self.path / "signals").read_text()
        self.assertNotIn(f"-- -{owners['watcher']}\n", signals)
        for role in ("simulator", "watchdog"):
            self.assertIn(f"-KILL -- -{owners[role]}\n", signals)
        self.assertFalse((self.path / "ci-ios-diagnostics/post-test.txt").exists())

    def test_should_not_signal_a_reused_owner_identity(self):
        status, output = self.run_workflow(FAULT="reused", FAILED_ROLE="watcher", FLUTTER_EXIT="17")
        self.assertEqual(status, 17, output)
        self.assertNotIn(f"-- -{self.owners()['watcher']}\n", (self.path / "signals").read_text())

    def test_should_preserve_success_when_exit_cleanup_cannot_find_a_diagnostic_owner(self):
        status, output = self.run_workflow(FAULT="missing", FAILED_ROLE="simulator")
        self.assertEqual(status, 0, output)
        self.assertIn("::warning::One or more", output)
        signals = (self.path / "signals").read_text()
        self.assertNotIn(f"-- -{self.owners()['simulator']}\n", signals)
        self.assertIn(f"-KILL -- -{self.owners()['watchdog']}\n", signals)

    def test_should_stop_retry_when_watcher_cleanup_fails_and_preserve_test_status(self):
        status, output = self.run_workflow(FAULT="kill", FAILED_ROLE="watcher", FLUTTER_EXIT="42", SCENARIO="frontboard")
        self.assertEqual(status, 42, output)
        self.assertEqual((self.path / "attempts").read_text().splitlines(), ["attempt"])
        self.assertNotIn("simctl uninstall", (self.path / "simulator-calls").read_text())
        signals = (self.path / "signals").read_text()
        for role in ("simulator", "watchdog"):
            self.assertIn(f"-KILL -- -{self.owners()[role]}\n", signals)

    def test_should_fail_successful_attempt_when_its_watcher_cannot_be_reaped(self):
        status, output = self.run_workflow(FAULT="kill", FAILED_ROLE="watcher")
        self.assertEqual(status, 1, output)
        self.assertFalse((self.path / "ci-ios-diagnostics/post-test.txt").exists())

    def test_should_never_resignal_retired_group_after_liveness_query_failure(self):
        status, output = self.run_workflow(FAULT="post-kill", FLUTTER_EXIT="42")
        self.assertEqual(status, 42, output)
        signals = (self.path / "signals").read_text().splitlines()
        owner = self.owners()['watcher']
        self.assertEqual(signals.count(f"-STOP -- -{owner}"), 1)
        self.assertEqual(signals.count(f"-KILL -- -{owner}"), 1)


if __name__ == "__main__":
    unittest.main()
