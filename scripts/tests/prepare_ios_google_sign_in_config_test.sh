#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
temporary_root="$(mktemp -d)"
trap 'rm -rf "$temporary_root"' EXIT

mkdir -p "$temporary_root/scripts" "$temporary_root/ios/Flutter"
cp "$repository_root/scripts/prepare_ios_google_sign_in_config.sh" \
  "$temporary_root/scripts/prepare_ios_google_sign_in_config.sh"

config_file="$temporary_root/ios/Flutter/GoogleSignIn.xcconfig"

# An Apple-only build must remove a generated file from a previous build.
touch "$config_file"
(
  cd "$temporary_root"
  env -u GOOGLE_SIGN_IN_SERVER_CLIENT_ID \
    -u GOOGLE_SIGN_IN_IOS_CLIENT_ID \
    -u GOOGLE_SIGN_IN_IOS_REVERSED_CLIENT_ID \
    -u GOOGLE_SIGN_IN_WEB_CLIENT_ID \
    bash scripts/prepare_ios_google_sign_in_config.sh
)
[[ ! -e "$config_file" ]]

# Partial Google configuration is unsafe: native and Dart configuration could
# otherwise disagree, so the pre-build step must reject it.
if (
  cd "$temporary_root"
  GOOGLE_SIGN_IN_SERVER_CLIENT_ID='123-web.apps.googleusercontent.com' \
    bash scripts/prepare_ios_google_sign_in_config.sh
); then
  echo 'Expected partial Google configuration to fail.' >&2
  exit 1
fi

(
  cd "$temporary_root"
  GOOGLE_SIGN_IN_SERVER_CLIENT_ID='123-web.apps.googleusercontent.com' \
  GOOGLE_SIGN_IN_WEB_CLIENT_ID='123-web.apps.googleusercontent.com' \
  GOOGLE_SIGN_IN_IOS_CLIENT_ID='456-ios.apps.googleusercontent.com' \
  GOOGLE_SIGN_IN_IOS_REVERSED_CLIENT_ID='com.googleusercontent.apps.456-ios' \
    bash scripts/prepare_ios_google_sign_in_config.sh
)

grep -qx 'GOOGLE_SIGN_IN_IOS_CLIENT_ID = 456-ios.apps.googleusercontent.com' "$config_file"
grep -qx 'GOOGLE_SIGN_IN_SERVER_CLIENT_ID = 123-web.apps.googleusercontent.com' "$config_file"

