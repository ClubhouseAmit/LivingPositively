#!/usr/bin/env bash

# CI-only workaround for Flutter 3.44's simulator log-reader startup race.
# Return 2 while waiting, 0 when finished, and 1 on a failed recovery. The
# caller still requires the original flutter test process to report success.
recover_ios_vm_service_once() {
  local device_id="$1" flutter_log="$2" simulator_log="$3"
  local runner_pid current_pid

  if grep -Eq 'VM Service URL on device|Successfully connected to service protocol|exiting with code' "$flutter_log" 2>/dev/null; then
    return 0
  fi
  grep -Fq 'Waiting for VM Service port to be available' "$flutter_log" 2>/dev/null || return 2
  runner_pid=$(sed -n 's/.*com\.clubhouse\.livingpositively: \([0-9][0-9]*\).*/\1/p' "$flutter_log" | tail -n 1)
  [ -n "$runner_pid" ] || return 2
  kill -0 "$runner_pid" 2>/dev/null || return 2
  # Require independent evidence that this exact, still-running app started
  # its VM service. Never relaunch a crashed app or retry a test assertion.
  grep -Eq "Runner\[$runner_pid:.*The Dart VM service is listening on http://127\.0\.0\.1:" "$simulator_log" 2>/dev/null || return 2

  sleep 120
  if grep -Eq 'VM Service URL on device|Successfully connected to service protocol|exiting with code' "$flutter_log"; then
    return 0
  fi
  current_pid=$(sed -n 's/.*com\.clubhouse\.livingpositively: \([0-9][0-9]*\).*/\1/p' "$flutter_log" | tail -n 1)
  [ "$current_pid" = "$runner_pid" ] || return 2
  kill -0 "$runner_pid" 2>/dev/null || return 2

  echo '::warning::Runner announced its VM service but Flutter missed it; relaunching once with the log reader now attached.'
  # Match IOSSimulator.startApp's debug flags. Keep the original Flutter
  # process alive so it connects to the new announcement and runs the test.
  xcrun simctl terminate "$device_id" com.clubhouse.livingpositively || return 1
  xcrun simctl launch "$device_id" com.clubhouse.livingpositively \
    --enable-dart-profiling --disable-vm-service-publication \
    --enable-checked-mode --verify-entry-points || return 1
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  set -u
  if [ "$#" -ne 3 ]; then
    echo 'Usage: recover_ios_vm_service.sh DEVICE_ID FLUTTER_LOG SIMULATOR_LOG' >&2
    exit 1
  fi
  # Cold native builds can take 40+ minutes. The parent test step owns the
  # 90-minute deadline and terminates this watcher when the test exits.
  for ((attempt = 0; attempt < 960; attempt++)); do
    recover_ios_vm_service_once "$@"
    recovery_exit=$?
    if [ "$recovery_exit" -ne 2 ]; then
      exit "$recovery_exit"
    fi
    sleep 5
  done
  echo 'No recoverable VM-service announcement race observed.'
fi
