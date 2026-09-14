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

require_value APPLE_SIGN_IN_ENABLED
[[ "$APPLE_SIGN_IN_ENABLED" == "true" || "$APPLE_SIGN_IN_ENABLED" == "false" ]] || fail "APPLE_SIGN_IN_ENABLED must be true or false"

bash scripts/prepare_ios_google_sign_in_config.sh

flutter build ipa \
  --dart-define=APPLE_SIGN_IN_ENABLED="$APPLE_SIGN_IN_ENABLED" \
  --dart-define=GOOGLE_SIGN_IN_SERVER_CLIENT_ID="$GOOGLE_SIGN_IN_SERVER_CLIENT_ID" \
  --dart-define=GOOGLE_SIGN_IN_IOS_CLIENT_ID="$GOOGLE_SIGN_IN_IOS_CLIENT_ID"
