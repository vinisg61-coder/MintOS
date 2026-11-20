#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <output-path>" >&2
    exit 2
fi

OUTPUT_PATH="$1"
VERSION="2.2.0"
case "$(uname -m)" in
    x86_64|amd64)
        ARCH="x86_64"
        SHA256="f6029dcce75b8a66acc1975529085c53903f7cdb35505e0ac0a973f2652480ff"
        ;;
    aarch64|arm64)
        ARCH="aarch64"
        SHA256="c17addb7693adc4a5f6b52eb2aa27a3398433ded980319b9dcd3cd9f7a6d267e"
        ;;
    *)
        echo "Unsupported architecture for samloader-rs: $(uname -m)" >&2
        exit 2
        ;;
esac

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

ZIP_PATH="$TMP_DIR/samloader.zip"
URL="https://github.com/topjohnwu/samloader-rs/releases/download/$VERSION/samloader-v$VERSION-linux-$ARCH.zip"
curl \
    --fail-with-body \
    --location \
    --silent \
    --show-error \
    --retry 5 \
    --retry-all-errors \
    --retry-delay 2 \
    --connect-timeout 20 \
    --max-time 180 \
    -o "$ZIP_PATH" \
    "$URL"

if ! printf '%s  %s\n' "$SHA256" "$ZIP_PATH" | sha256sum --check --status; then
    echo "samloader-rs v$VERSION archive checksum mismatch." >&2
    exit 1
fi

unzip -q "$ZIP_PATH" -d "$TMP_DIR/unpacked"
if [[ ! -f "$TMP_DIR/unpacked/samloader" ]]; then
    echo "samloader-rs archive does not contain the samloader executable." >&2
    exit 1
fi

install -D -m 0755 "$TMP_DIR/unpacked/samloader" "$OUTPUT_PATH"
