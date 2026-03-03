#!/usr/bin/env bash
# Quiet Hacker - Shell Preview
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="/tmp/quiet-hacker.log"
readonly MAX_RETRIES=3
readonly GREEN='\033[0;32m'
readonly RESET='\033[0m'

log() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "$LOG_FILE"
}

die() {
    log "ERROR" "$@" >&2
    exit 1
}

check_dependencies() {
    local deps=("curl" "jq" "git" "docker")
    local missing=()

    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        die "Missing dependencies: ${missing[*]}"
    fi

    log "INFO" "All dependencies found"
}

fetch_with_retry() {
    local url="$1"
    local output="${2:-/dev/stdout}"
    local attempt=0

    while ((attempt < MAX_RETRIES)); do
        ((attempt++))
        log "INFO" "Attempt $attempt/$MAX_RETRIES: $url"

        if curl -sSf --max-time 30 "$url" -o "$output" 2>/dev/null; then
            log "INFO" "Success"
            return 0
        fi

        sleep $((attempt * 2))
    done

    log "ERROR" "Failed after $MAX_RETRIES attempts"
    return 1
}

process_files() {
    local dir="$1"
    local pattern="${2:-*.json}"
    local count=0

    while IFS= read -r -d '' file; do
        if jq empty "$file" 2>/dev/null; then
            echo -e "${GREEN}valid${RESET}: $file"
            ((count++))
        else
            echo "invalid: $file"
        fi
    done < <(find "$dir" -name "$pattern" -print0)

    log "INFO" "Processed $count valid files"
}

main() {
    log "INFO" "Starting quiet-hacker script"
    check_dependencies

    local target_dir="${1:-.}"
    [[ -d "$target_dir" ]] || die "Directory not found: $target_dir"

    process_files "$target_dir" "*.json"

    log "INFO" "Done"
}

main "$@"
