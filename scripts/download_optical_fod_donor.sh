#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REVISION="$(tr -d '\r\n' < "$SCRIPT_DIR/optical_fod_donor.version")"
MANIFEST="$SCRIPT_DIR/optical_fod_donor.sha256"
BASE_URL="https://raw.githubusercontent.com/salvogiangri/UN1CA/$REVISION"
DONOR_ROOT="$REPO_ROOT/prebuilts/samsung/r9qxxx"
MARKER="$DONOR_ROOT/.optical-fod-version"

if [[ ! "$REVISION" =~ ^[0-9a-f]{40}$ ]]; then
    echo "Invalid UN1CA optical FOD revision: $REVISION" >&2
    exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

while read -r expected_hash relative_path; do
    [[ -n "${expected_hash:-}" ]] || continue
    if [[ ! "$expected_hash" =~ ^[0-9a-f]{64}$ || "$relative_path" != prebuilts/samsung/r9qxxx/system/* ]]; then
        echo "Invalid optical FOD donor manifest entry: $expected_hash $relative_path" >&2
        exit 1
    fi

    download_path="$tmp_dir/$relative_path"
    mkdir -p "$(dirname "$download_path")"
    echo "Downloading UN1CA optical FOD blob: $relative_path"
    curl --fail --location --silent --show-error --retry 3 --retry-all-errors \
        "$BASE_URL/$relative_path" --output "$download_path"
    printf '%s  %s\n' "$expected_hash" "$download_path" | sha256sum --check --status

    install_mode=644
    [[ "$relative_path" == prebuilts/samsung/r9qxxx/system/bin/surfaceflinger ]] && install_mode=755
    install -D -m "$install_mode" "$download_path" "$REPO_ROOT/$relative_path"
done < "$MANIFEST"

printf '%s\n' "$REVISION" > "$MARKER"
echo "Prepared and verified UN1CA optical FOD blobs from $REVISION"
