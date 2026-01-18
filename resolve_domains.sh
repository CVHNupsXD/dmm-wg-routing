#!/usr/bin/env bash
set -euo pipefail


DOH_URL="https://public.dns.iij.jp/dns-query"
INPUT_FILE="domains.txt"
OUTPUT_FILE="ips.txt"
TEMP_FILE="$(mktemp)"

echo "Starting domain resolution using JP DoH (IIJ)..."

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: $INPUT_FILE not found!"
    exit 1
fi

if ! command -v dog &> /dev/null; then
    echo "Error: 'dog' DNS tool not found. Please install it first."
    echo "GitHub: https://github.com/ogham/dog"
    exit 1
fi

> "$TEMP_FILE"

while IFS= read -r line || [[ -n "$line" ]]; do
    line=$(echo "$line" | xargs)

    if [[ -z "$line" ]] || [[ "$line" =~ ^# ]]; then
        continue
    fi
    
    domain="$line"
    echo "Resolving: $domain"
    

    if result=$(dog A "$domain" --https @"$DOH_URL" --short 2>&1); then
        while IFS= read -r ip; do
            if [[ -n "$ip" ]]; then
                if [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                    echo "$domain=$ip" >> "$TEMP_FILE"
                fi
            fi
        done <<< "$result"
    else
        echo "Warning: Failed to resolve $domain" >&2
    fi
done < "$INPUT_FILE"

sort "$TEMP_FILE" > "$OUTPUT_FILE"

rm -f "$TEMP_FILE"

line_count=$(wc -l < "$OUTPUT_FILE" | xargs)
echo "Completed! Generated $line_count entries in $OUTPUT_FILE"
