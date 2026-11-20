#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <output-path> <apk-library-arch>" >&2
    exit 2
fi

OUTPUT_PATH="$1"
APK_ARCH="$2"
case "$APK_ARCH" in
    arm64-v8a|x86_64) ;;
    *)
        echo "Unsupported Magisk APK architecture: $APK_ARCH" >&2
        exit 2
        ;;
esac

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

API_URL="https://api.github.com/repos/topjohnwu/Magisk/releases/latest"
CURL_ARGS=(
    --fail-with-body
    --location
    --silent
    --show-error
    --retry 5
    --retry-all-errors
    --retry-delay 2
    --retry-max-time 90
    --connect-timeout 20
    --max-time 120
    -H "Accept: application/vnd.github+json"
    -H "User-Agent: MintOS-build"
)

# Authenticate the public API request when Actions provides a token to avoid
# unauthenticated rate limits. Do not send this header to the asset host.
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    CURL_ARGS+=(-H "Authorization: Bearer $GITHUB_TOKEN")
fi

if ! RELEASE_JSON="$(curl "${CURL_ARGS[@]}" "$API_URL")"; then
    echo "Unable to fetch the latest Magisk release metadata after retries." >&2
    exit 1
fi

if ! APK_URL="$(jq -er '[.assets[]? | select(.name | test("^Magisk-v[0-9]+([.][0-9]+)*[.]apk$")) | .browser_download_url][0] // empty' <<< "$RELEASE_JSON")"; then
    echo "The latest Magisk release did not contain the expected Magisk-v<version>.apk asset." >&2
    exit 1
fi

APK_PATH="$TMP_DIR/magisk.apk"
curl \
    --fail-with-body \
    --location \
    --silent \
    --show-error \
    --retry 5 \
    --retry-all-errors \
    --retry-delay 2 \
    --retry-max-time 90 \
    --connect-timeout 20 \
    --max-time 300 \
    -o "$APK_PATH" \
    "$APK_URL"

unzip -p "$APK_PATH" "lib/$APK_ARCH/libmagiskboot.so" > "$TMP_DIR/magiskboot"
if [[ ! -s "$TMP_DIR/magiskboot" ]]; then
    echo "The downloaded Magisk APK has no lib/$APK_ARCH/libmagiskboot.so." >&2
    exit 1
fi

install -D -m 0755 "$TMP_DIR/magiskboot" "$OUTPUT_PATH"
