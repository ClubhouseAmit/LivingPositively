"""Exercise the real watcher entrypoint and workflow cleanup in child shells."""

import os
from pathlib import Path
import re
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

    def test_should_stop_late_children_even_after_owner_exit_without_signalling_other_jobs(self):
        workflow = (ROOT / ".github/workflows/main.yml").read_text()
        match = re.search(r"^          terminate_process_group\(\) \{\n.*?^          \}$", workflow, re.M | re.S)
        self.assertIsNotNone(match)
        cleanup_function = "\n".join(line[10:] for line in match[0].splitlines())
        owner = self.path / "owner.sh"
        owner.write_text(r'''
touch "$TEST_DIRECTORY/owner-ready"
until [ -f "$TEST_DIRECTORY/spawn" ]; do command sleep 0.01; done
bash -c 'trap "" TERM; command sleep 60' &
printf '%s\n' "$!" > "$TEST_DIRECTORY/late-child.pid"
if [ "$OWNER_EXITS" = true ]; then exit 0; fi
wait
''')
        driver = self.path / "late-child-driver.sh"
        driver.write_text(cleanup_function + r'''
set -m
bash "$TEST_DIRECTORY/owner.sh" &
owner_pid=$!
set +m
command sleep 60 &
unrelated_pid=$!
trap 'builtin kill -KILL -- "-$owner_pid" "$unrelated_pid" 2>/dev/null || true; wait "$unrelated_pid" 2>/dev/null || true' EXIT
until [ -f "$TEST_DIRECTORY/owner-ready" ]; do command sleep 0.01; done
kill() {
  if [ "$1" = -STOP ]; then
    # Fork after cleanup starts, not when the original owner was launched.
    touch "$TEST_DIRECTORY/spawn"
    until [ -f "$TEST_DIRECTORY/late-child.pid" ]; do command sleep 0.01; done
    if [ "$OWNER_EXITS" = true ]; then wait "$owner_pid"; fi
  fi
  builtin kill "$@"
}
terminate_process_group "$owner_pid" || exit 10
builtin kill -0 "$unrelated_pid" || exit 11
''')
        for owner_exits in ("false", "true"):
            with self.subTest(owner_exits=owner_exits):
                for name in ("owner-ready", "spawn", "late-child.pid"):
                    (self.path / name).unlink(missing_ok=True)
                self.environment["OWNER_EXITS"] = owner_exits
                result = subprocess.run(
                    ["bash", str(driver)], cwd=self.path, env=self.environment,
                    text=True, capture_output=True, timeout=15,
                )
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                pid = (self.path / "late-child.pid").read_text().strip()
                status = subprocess.run(["ps", "-o", "stat=", "-p", pid], text=True, capture_output=True)
                self.assertTrue(not status.stdout.strip() or status.stdout.strip().startswith("Z"), status.stdout)

    def test_should_reap_poll_and_grace_sleepers_before_next_attempt(self):
        workflow = (ROOT / ".github/workflows/main.yml").read_text()
        functions = []
        for name in ("terminate_process_group", "stop_vm_service_recovery", "run_ios_fcm_test"):
            match = re.search(rf"^          {name}\(\) \{{\n.*?^          \}}$", workflow, re.M | re.S)
            self.assertIsNotNone(match, name)
            functions.append("\n".join(line[10:] for line in match[0].splitlines()))
        scripts = self.path / "scripts"
        scripts.mkdir()
        shutil.copyfile(WATCHER, scripts / WATCHER.name)
        diagnostics = self.path / "ci-ios-diagnostics"
        diagnostics.mkdir()
        (diagnostics / "simulator.log").write_text(ANNOUNCEMENT)
        driver = self.path / "driver.sh"
        driver.write_text("\n".join(functions) + r'''
DEVICE_ID=test-device
flutter() {
  if [ "$SCENARIO" = cleanup-grace ]; then
    printf '%s\n%s' "$LAUNCH" "$WAITING"
    printf '%s' "$ANNOUNCEMENT" >> ci-ios-diagnostics/simulator.log
  fi
  until [ -f "$TEST_DIRECTORY/ready" ]; do command sleep 0.01; done
  printf '%s\n' "$VM_RECOVERY_PID" > "$TEST_DIRECTORY/watcher.pid"
  return "$FLUTTER_EXIT"
}
trap stop_vm_service_recovery EXIT
run_ios_fcm_test first
[ "$TEST_EXIT" -eq "$FLUTTER_EXIT" ] || exit 10
[ -z "$VM_RECOVERY_PID" ] || exit 11
# Simulate retry/forensics only after the production attempt wrapper reaps.
printf 'next-attempt\n' > "$TEST_DIRECTORY/next-attempt"
''')
        for scenario, flutter_exit in (("cleanup-poll", "0"), ("cleanup-grace", "1")):
            with self.subTest(scenario=scenario):
                for name in ("ready", "watcher.pid", "sleep.pid", "next-attempt"):
                    (self.path / name).unlink(missing_ok=True)
                self.environment.update(SCENARIO=scenario, FLUTTER_EXIT=flutter_exit, ANNOUNCEMENT=ANNOUNCEMENT)
                result = subprocess.run(
                    ["bash", str(driver)], cwd=self.path, env=self.environment,
                    capture_output=True, text=True, timeout=15,
                )
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertTrue((self.path / "next-attempt").exists())
                for name in ("watcher.pid", "sleep.pid"):
                    pid = (self.path / name).read_text().strip()
                    status = subprocess.run(["ps", "-o", "stat=", "-p", pid], text=True, capture_output=True)
                    self.assertTrue(not status.stdout.strip() or status.stdout.strip().startswith("Z"), status.stdout)
                self.assert_no_simulator_commands()


if __name__ == "__main__":
    unittest.main()
