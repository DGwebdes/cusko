#!/usr/bin/env bash

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/config.sh"

readonly TCP_STATE_TIME_WAIT="06"

_tcp_files(){
	local f
	for f in /proc/net/tcp /proc/net/tcp6; do
		[[ -r "$f" ]] && echo "$f"
	done
}

sample_conn_total(){
	local total=0 f
	for f in $(_tcp_files); do
		total=$((total + $(tail -n +2 "$f" | wc -l)))
	done

	echo "$total"
}

sample_time_wait_count(){
	local st count=0 f
	for f in $(_tcp_files); do
		while read -r _ _ _ st _; do
			[[ "$st" == "TCP_STATE_TIME_WAIT" ]] && ((count++))
		done < <(tail -n +2 "$f")
	done

	echo "$count"
}

main(){
	local total time_wait
	total="$(sample_conn_total)"
	time_wait="$(sample_time_wait_count)"

	log_info "conn_total=${total} time_wait=${time_wait}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main
fi
