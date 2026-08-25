#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "iOS release configuration error: $1" >&2
  exit 1
}

require_value() {
  local name="$1"
  local value="${!name:-}"
  [[ -n "${value//[[:space:]]/}" ]] || fail "$name must be set"
}

for value_name in \
  APPLE_SIGN_IN_ENABLED \
  GOOGLE_SIGN_IN_SERVER_CLIENT_ID \
  GOOGLE_SIGN_IN_IOS_CLIENT_ID \
  GOOGLE_SIGN_IN_IOS_REVERSED_CLIENT_ID; do
  require_value "$value_name"
done

[[ "$APPLE_SIGN_IN_ENABLED" == "true" ]] || fail "APPLE_SIGN_IN_ENABLED must be true"

config_file="ios/Flutter/GoogleSignIn.xcconfig"
[[ -f "$config_file" ]] || fail "copy and populate $config_file from GoogleSignIn.xcconfig.example"

config_value() {
  local key="$1"
  sed -nE "s/^[[:space:]]*$key[[:space:]]*=[[:space:]]*(.*)[[:space:]]*$/\1/p" "$config_file" | tail -n 1
}

[[ "$(config_value GOOGLE_SIGN_IN_SERVER_CLIENT_ID)" == "$GOOGLE_SIGN_IN_SERVER_CLIENT_ID" ]] || fail "Google server client ID does not match $config_file"
[[ "$(config_value GOOGLE_SIGN_IN_IOS_CLIENT_ID)" == "$GOOGLE_SIGN_IN_IOS_CLIENT_ID" ]] || fail "Google iOS client ID does not match $config_file"
[[ "$(config_value GOOGLE_SIGN_IN_IOS_REVERSED_CLIENT_ID)" == "$GOOGLE_SIGN_IN_IOS_REVERSED_CLIENT_ID" ]] || fail "Google iOS reversed client ID does not match $config_file"

flutter build ipa \
  --dart-define=APPLE_SIGN_IN_ENABLED="$APPLE_SIGN_IN_ENABLED" \
  --dart-define=GOOGLE_SIGN_IN_SERVER_CLIENT_ID="$GOOGLE_SIGN_IN_SERVER_CLIENT_ID" \
  --dart-define=GOOGLE_SIGN_IN_IOS_CLIENT_ID="$GOOGLE_SIGN_IN_IOS_CLIENT_ID"
