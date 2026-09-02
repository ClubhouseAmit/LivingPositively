#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../recover_ios_vm_service.sh"
test_directory=$(mktemp -d)
trap 'rm -f "$test_directory/flutter.log" "$test_directory/simulator.log"; rmdir "$test_directory"' EXIT
flutter_log="$test_directory/flutter.log"
simulator_log="$test_directory/simulator.log"

# Fake only the external simulator commands and passage of time. Exercise
# the production log predicates and recovery sequence with real log files.
sleep() {
  [ "$1" = 120 ] || return 1
  if [ "$connect_during_wait" = true ]; then
    printf 'VM Service URL on device: http://127.0.0.1:61515/token/\n' >> "$flutter_log"
  fi
  if [ "$replace_during_wait" = true ]; then
    printf 'com.clubhouse.livingpositively: 40051\n' >> "$flutter_log"
  fi
  if [ "$exit_during_wait" = true ]; then
    process_alive=false
  fi
}
kill() { [ "$1" = -0 ] && [ "$2" = 40050 ] && [ "$process_alive" = true ]; }
xcrun() {
  calls+=("$*")
  [ "$2" != "$failed_command" ]
}

reset_case() {
  calls=()
  process_alive=true
  connect_during_wait=false
  replace_during_wait=false
  exit_during_wait=false
  failed_command=''
  printf '%s\n' '[+6460 ms] com.clubhouse.livingpositively: 40050' \
    '[ ] Waiting for VM Service port to be available...' > "$flutter_log"
  printf '%s\n' '2026-09-02 07:52:56.868 Df Runner[40050:50d58] (Flutter) flutter: The Dart VM service is listening on http://127.0.0.1:61515/token/' > "$simulator_log"
}
expect_result() {
  local expected="$1" actual=0
  recover_ios_vm_service_once test-device "$flutter_log" "$simulator_log" || actual=$?
  [ "$actual" -eq "$expected" ] || { echo "Expected status $expected, got $actual" >&2; exit 1; }
}

reset_case
expect_result 0
[ "${#calls[@]}" -eq 2 ]
[ "${calls[0]}" = 'simctl terminate test-device com.clubhouse.livingpositively' ]
[ "${calls[1]}" = 'simctl launch test-device com.clubhouse.livingpositively --enable-dart-profiling --disable-vm-service-publication --enable-checked-mode --verify-entry-points' ]

reset_case
printf 'VM Service URL on device: http://127.0.0.1:61515/token/\nTest failed\n' >> "$flutter_log"
expect_result 0
[ "${#calls[@]}" -eq 0 ]

reset_case
connect_during_wait=true
expect_result 0
[ "${#calls[@]}" -eq 0 ]

reset_case
process_alive=false
expect_result 2
[ "${#calls[@]}" -eq 0 ]

reset_case
replace_during_wait=true
expect_result 2
[ "${#calls[@]}" -eq 0 ]

reset_case
exit_during_wait=true
expect_result 2
[ "${#calls[@]}" -eq 0 ]

reset_case
: > "$flutter_log"
expect_result 2
[ "${#calls[@]}" -eq 0 ]

reset_case
printf 'Waiting for VM Service port to be available...\n' > "$flutter_log"
expect_result 2
[ "${#calls[@]}" -eq 0 ]

reset_case
printf '%s\n' 'Runner[99999:50d58] The Dart VM service is listening on http://127.0.0.1:61515/token/' > "$simulator_log"
expect_result 2
[ "${#calls[@]}" -eq 0 ]

reset_case
: > "$simulator_log"
expect_result 2
[ "${#calls[@]}" -eq 0 ]

reset_case
printf 'exiting with code 1\n' >> "$flutter_log"
expect_result 0
[ "${#calls[@]}" -eq 0 ]

reset_case
failed_command=terminate
expect_result 1
[ "${#calls[@]}" -eq 1 ]

reset_case
failed_command=launch
expect_result 1
[ "${#calls[@]}" -eq 2 ]

echo 'PASS: iOS VM-service recovery (13 scenarios)'
