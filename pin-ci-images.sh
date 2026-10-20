#!/usr/bin/env bash
# Exit immediately if a command exits with a non-zero status
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# --- Configuration ---
LOG_FILE="/tmp/renovate.log"
PYTHON_SCRIPT="${SCRIPT_DIR}/extract-docker-pins.py"
RENOVATE_CONFIG_FILE="${SCRIPT_DIR}/config.js"
TARGET_FILE="ci/.gitlab-ci.yml"
# ---------------------

if ! command -v crane &> /dev/null; then
    echo "Error: 'crane' could not be found. Please install it first."
    exit 1
fi

echo "Step 1: Running Renovate locally (dry-run: lookup)..."
LOG_LEVEL=debug RENOVATE_CONFIG_FILE="${RENOVATE_CONFIG_FILE}" renovate --dry-run=lookup >> "$LOG_FILE" 2>&1

echo "Step 2: Parsing Renovate logs for Docker pins..."
EXTRACTED_DATA=$(python3 "$PYTHON_SCRIPT" "$LOG_FILE")

if [ -z "$EXTRACTED_DATA" ]; then
    echo "No dependencies found to process. Exiting."
    exit 0
fi

if [ ! -f "$TARGET_FILE" ]; then
    echo "Warning: Target file '$TARGET_FILE' does not exist. Digests will be fetched but not replaced."
fi

echo "Step 3 & 4: Fetching digests and updating $TARGET_FILE..."
echo ""
printf "%-40s | %s\n" "Image:Tag" "Digest"
printf "%s\n" "--------------------------------------------------------------------------------------"

# Read the pipe-separated output from Python
while IFS="|" read -r PKG CUR_TAG NEW_TAG; do
    IMAGE="${PKG}:${NEW_TAG}"

    # Fetch digest
    DIGEST=$(crane digest "$IMAGE" 2>/dev/null || echo "ERROR")

    if [ "$DIGEST" != "ERROR" ]; then
        printf "%-40s | %s\n" "$IMAGE" "$DIGEST"

        if [ -f "$TARGET_FILE" ]; then
            # The sed regex matches: <package>:<old_tag> AND an optional @sha256:<hash>
            # It replaces it with: <package>:<new_tag>@<new_digest>
            sed -i "s|${PKG}:${CUR_TAG}\(@sha256:[a-f0-9]*\)\?|${PKG}:${NEW_TAG}@${DIGEST}|g" "$TARGET_FILE"
        fi
    else
        printf "%-40s | %s\n" "$IMAGE" "ERROR: Could not fetch digest"
    fi

done <<< "$EXTRACTED_DATA"

echo ""
echo "Done!"
