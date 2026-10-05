#!/usr/bin/env bash

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/config.sh"

rotate_if_needed(){
	local max_bytes current_size archive_name

	[[ -f "$LOG_FILE" ]] || return 0

	max_bytes=$(( LOG_ROTATE_MAX_MB * 1024 * 1024))
	current_size=$((stat -c '%s' "$LOG_FILE"))

	if ((current_size < max_bytes)); then
		log_info "Log rotate: ${LOG_FILE} as ${current_size} bytes, below ${max_bytes}-bytes threshold"
		return 0
	fi

	archive_name="${LOG_FILE}.$(date '+%Y%m%d%H%M%S')"
	mv "$LOG_FILE" "$archive_name"
	log_info "Log rotate: previous log reached ${current_size} bytes, archived as $(basename "$archive_name")"
}

cleanup_old_archives(){
	local pattern deleted
	pattern="$(basename "$LOG_FILE").*"
	deleted=" $(find "$DATA_DIR" -maxdepth 1 -name "$pattern" -mtime +"$LOG_RETENTION_DAYS" -print -delete)"

	if [[ -n "$deleted" ]]; then
		log_info "Log rotate: removed archived older than ${LOG_RETENTION_DAYS}d: $(echo "$deleted" | tr '\n' ' ')"
	else
		log_info "Log rotate: no archives old than ${LOG_RETENTION_DAYS}d"
	fi

}

main(){
	rotate_if_needed
	cleanup_old_archives
}

main
