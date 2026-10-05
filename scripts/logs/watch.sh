#!/usr/bin/env bash
# watch.sh scans a log file for lines added since the last run, alerts if error-pattern matches exceed the threshold.


set -uo pipefail
SCRIPT_DIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/config.sh"
source "$SCRIPT_DIR/../../lib/alert.sh"

STATE_FILE="${LOG_WATCH_STATE_FILE:-$DATA_DIR/log_watch.state}"

_SCAN_ERROR_COUNT=0

scan_log_source(){
	local target="$1" state_file="$2"
	local current_size prev_offset new_content

	_SCAN_ERROR_COUNT=0

	if [[ ! -f "$target" ]]; then
		log_warn "Log scan: target '$target' does not exist, nothing to scan"
	return 0
	fi

	current_size=$(stat -c '%s' "$target")
	
	if [[ -f "$state_file" ]]; then
		read -r prev_offset < "$state_file"
	else
		prev_offset=0
	fi
	
	if ((current_size < prev_offset)); then
		log_warn "Log watcher: target shrank since last read (rotated/truncated), restarting from offset 0"
		prev_offset=0
	fi
	
	if ((current_size == prev_offset)); then
		log_info "Log watcher: no new content in $target"
		echo "$current_size" > "$state_file"
		return 0
	fi
	
	new_content="$(tail -c +"$((prev_offset + 1))" "$target")"
	_SCAN_ERROR_COUNT="$(grep -cE "$LOG_ERROR_PATTERN" <<< "$new_content" || true)"

	log_info "Log watcher: scanned $((current_size - prev_offset)) new bytes, ${error_count} error-pattern matches"

	echo "$current_size" > "$state_file"
}
main(){
	scan_log_source "$LOG_TARGET_PATH" "$STATE_FILE"
	local error_count="$_SCAN_ERROR_COUNT"

	if ((error_count >= LOG_ERROR_RATE_WARN)); then
		alert WARN "Log error rate high: ${error_count} matches (>= ${LOG_ERROR_RATE_WARN} threshold) in ${LOG_TARGET_PATH}"
	fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main
fi

