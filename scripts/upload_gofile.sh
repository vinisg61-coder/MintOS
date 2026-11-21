#!/usr/bin/env bash
set -euo pipefail

file="${1:?usage: upload_gofile.sh <rom.zip>}"
if [[ ! -s "$file" ]]; then
    echo "GoFile upload input is missing or empty: $file" >&2
    exit 1
fi

servers="$(curl --fail --silent --show-error --retry 3 --retry-all-errors \
    --connect-timeout 30 https://api.gofile.io/servers)"
server="$(jq -er '.data.servers[0].name | select(type == "string" and length > 0)' <<< "$servers")"
if [[ ! "$server" =~ ^[A-Za-z0-9-]+$ ]]; then
    echo "GoFile returned an invalid upload server name" >&2
    exit 1
fi

echo "Uploading $(basename "$file") to GoFile server $server..."
response="$(curl --fail-with-body --silent --show-error --connect-timeout 30 \
    -X POST "https://${server}.gofile.io/uploadFile" \
    -F "file=@${file}")"
status="$(jq -er '.status' <<< "$response")"
if [[ "$status" != "ok" ]]; then
    echo "GoFile upload failed (status: $status)" >&2
    exit 1
fi

url="$(jq -er '.data.downloadPage | select(type == "string" and startswith("https://gofile.io/"))' <<< "$response")"
echo "GoFile download URL: $url"
echo "url=$url" >> "$GITHUB_OUTPUT"
