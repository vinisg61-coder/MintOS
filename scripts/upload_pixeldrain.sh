#!/usr/bin/env bash
set -euo pipefail

file="${1:?usage: upload_pixeldrain.sh <rom.zip>}"
if [[ ! -s "$file" ]]; then
    echo "Pixeldrain upload input is missing or empty: $file" >&2
    exit 1
fi
if [[ -z "${PIXELDRAIN_API_KEY:-}" ]]; then
    echo "PIXELDRAIN_API_KEY is missing. Add it under repository Settings > Secrets and variables > Actions." >&2
    exit 1
fi

name="$(basename "$file")"
if [[ ! "$name" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "Unexpected ZIP filename for Pixeldrain upload: $name" >&2
    exit 1
fi

echo "Uploading $name to Pixeldrain..."
response="$(printf 'header = "Authorization: Bearer %s"\n' "$PIXELDRAIN_API_KEY" |
    curl --config - --fail-with-body --silent --show-error --connect-timeout 30 \
        --upload-file "$file" "https://pixeldrain.com/api/file/$name")"
if [[ "$(jq -er '.success' <<< "$response")" != "true" ]]; then
    echo "Pixeldrain did not confirm the upload" >&2
    exit 1
fi
file_id="$(jq -er '.id | select(type == "string" and length > 0)' <<< "$response")"
url="https://pixeldrain.com/u/$file_id"
echo "Pixeldrain download URL: $url"
echo "url=$url" >> "$GITHUB_OUTPUT"
