#!/usr/bin/env bash

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/config.sh"
source "$SCRIPT_DIR/../../lib/alert.sh"
source "$SCRIPT_DIR/watch.sh"

state_file_for(){
	local source="$1"
	echo "$DATA_DIR/log_agg_$(echo "$source" | tr '\n' '_').state"
}

main(){
	local source total=0 summary=""

	for source in $LOG_SOURCES; do
		scan_log_source "$source" "$(state_file_for "$source")"
		total=$((total + _SCAN_ERROR_COUNT))
		summary+="${source}=${_SCAN_ERROR_COUNT} "
	done

	log_info "Log aggregates: ${summary}total=${total}"

	if ((total >= LOG_ERROR_RATE_WARN)); then
		alert WARN "Aggregate log error rate high: ${total} matches across $(echo "$LOG_SOURCES" | wc -w) sources (>= ${LOG_ERROR_RATE_WARN} threshold)"
	fi
}

main
