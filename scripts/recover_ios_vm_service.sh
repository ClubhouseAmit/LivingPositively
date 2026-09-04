#!/usr/bin/env bash

# CI-only workaround for Flutter 3.44's simulator log-reader startup race.
# Return 2 while waiting, 0 when finished, and 1 on a failed recovery. The
# caller still requires the original flutter test process to report success.
recover_ios_vm_service_once() {
  local device_id="$1" flutter_log="$2" simulator_log="$3" simulator_log_offset="$4"
  local runner_pid current_pid launch_arguments
  local expected_arguments='--enable-dart-profiling --disable-vm-service-publication --enable-checked-mode --verify-entry-points'

  if grep -Eq 'VM Service URL on device|Successfully connected to service protocol|exiting with code' "$flutter_log" 2>/dev/null; then
    return 0
  fi
  grep -Fq 'Waiting for VM Service port to be available' "$flutter_log" 2>/dev/null || return 2
  runner_pid=$(sed -n 's/.*com\.clubhouse\.livingpositively: \([0-9][0-9]*\).*/\1/p' "$flutter_log" | tail -n 1)
  [ -n "$runner_pid" ] || return 2
  kill -0 "$runner_pid" 2>/dev/null || return 2
  # Require independent evidence that this exact, still-running app started
  # its VM service. Never relaunch a crashed app or retry a test assertion.
  # The log stream spans attempts. Ignore all bytes recorded before this
  # attempt began, including announcements from a previously reused PID.
  tail -c "+$((simulator_log_offset + 1))" "$simulator_log" 2>/dev/null |
    grep -Eq "Runner\[$runner_pid:.*The Dart VM service is listening on http://127\.0\.0\.1:" || return 2

  launch_arguments=$(sed -n "s/.*executing: .*simctl launch $device_id com\.clubhouse\.livingpositively //p" "$flutter_log" | tail -n 1)
  if [ "$launch_arguments" != "$expected_arguments" ]; then
    echo '::warning::Flutter launch arguments are missing or differ from the verified recovery flags; leaving the original test untouched.'
    return 0
  fi

  sleep 120
  if grep -Eq 'VM Service URL on device|Successfully connected to service protocol|exiting with code' "$flutter_log"; then
    return 0
  fi
  current_pid=$(sed -n 's/.*com\.clubhouse\.livingpositively: \([0-9][0-9]*\).*/\1/p' "$flutter_log" | tail -n 1)
  [ "$current_pid" = "$runner_pid" ] || return 2
  kill -0 "$runner_pid" 2>/dev/null || return 2

  echo '::warning::Runner announced its VM service but Flutter missed it; relaunching once with the log reader now attached.'
  # The recorded IOSSimulator.startApp command was checked above. Keep the
  # original Flutter process alive to connect and run the test.
  xcrun simctl terminate "$device_id" com.clubhouse.livingpositively || return 1
  xcrun simctl launch "$device_id" com.clubhouse.livingpositively \
    --enable-dart-profiling --disable-vm-service-publication \
    --enable-checked-mode --verify-entry-points || return 1
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  set -u
  if [ "$#" -ne 4 ] || [[ ! "$1" =~ ^[[:alnum:]-]+$ ]] || [[ ! "$4" =~ ^(0|[1-9][0-9]*)$ ]]; then
    echo 'Usage: recover_ios_vm_service.sh DEVICE_ID FLUTTER_LOG SIMULATOR_LOG SIMULATOR_LOG_BYTE_OFFSET' >&2
    exit 1
  fi
  # Cold native builds can take 40+ minutes. The parent test step owns the
  # 90-minute deadline and terminates this watcher when the test exits.
  for ((attempt = 0; attempt < 1080; attempt++)); do
    recover_ios_vm_service_once "$@"
    recovery_exit=$?
    if [ "$recovery_exit" -ne 2 ]; then
      exit "$recovery_exit"
    fi
    sleep 5
  done
  echo 'No recoverable VM-service announcement race observed.'
fi
