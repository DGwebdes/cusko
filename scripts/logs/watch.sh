#!/usr/bin/env bash
# watch.sh scans a log file for lines added since the last run, alerts if error-pattern matches exceed the threshold.


set -uo pipefail
SCRIPT_DIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/config.sh"
source "$SCRIPT_DIR/../../lib/alert.sh"

STATE_FILE="${LOG_WATCH_STATE_FILE:-$DATA_DIR/log_watch.state}"

main(){
	if [[ ! -f "$LOG_TARGET_PATH" ]]; then
		log_warn "Log watcher: target '$LOG_TARGET_PATH' does not exist, nothing to scan"
		return 0
	fi

	local current_size prev_offset new_content error_count
	current_size=$(stat -c '%s' "$LOG_TARGET_PATH")

	if [[ -f "$STATE_FILE" ]]; then
		read -r prev_offset < "$STATE_FILE"
	else
		prev_offset=0
	fi

	if ((current_size < prev_offset)); then
		log_warn "Log watcher: target shrank since last read (rotated/truncated), restarting from offset 0"
		prev_offset=0
	fi

	if ((current_size == prev_offset)); then
		log_info "Log watcher: no new content in $LOG_TARGET_PATH"
		echo "$current_size" > "$STATE_FILE"
		return 0
	fi

	new_content="$(tail -c +"$((prev_offset + 1))" "$LOG_TARGET_PATH")"
	error_count="$(grep -cE "$LOG_ERROR_PATTERN" <<< "$new_content" || true)"

	log_info "Log watcher: scanned $((current_size - prev_offset)) new bytes, ${error_count} error-pattern matches"

	if ((error_count >= LOG_ERROR_RATE_WARN)); then
		alert WARN "Log error rate high: ${error_count} matches (>= ${LOG_ERROR_RATE_WARN} threshold) in ${LOG_TARGET_PATH}"
	fi

	echo "$current_size" > "$STATE_FILE"
}

main

