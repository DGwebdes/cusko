#!/usr/bin/env bash

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/config.sh"
source "$SCRIPT_DIR/../../lib/alert.sh"

seconds_to_ms(){
	local val="$1" sec frac
	sec="${val%%.*}"
	frac="${val#*.}"
	frac="${frac}000000"
	frac="${frac:0:6}"
	echo $(( 10#$sec * 1000 + ( 10#$frac + 500 ) / 1000 ))
}

check_reachability(){
	local target="$1" out http_code time_total_s curl_exit latency_ms

	out="$(curl -s -o /dev/null -w '%{http_code} %{time_total}' --max-time 5 "$target")"
	curl_exit=$?

	if ((curl_exit != 0)); then
		alert WARN "Unreachable: ${target} (curl exit code ${curl_exit})"
	fi

	read -r http_code time_total_s <<< "$out"
	latency_ms="$(seconds_to_ms "$time_total_s")"

	log_info "Reachability: ${target} http=${http_code} latency=${latency_ms}"

	if ((latency_ms >= REACHABILITY_LATENCY_WARN_MS)); then
		alert WARN "High latency: ${target} responded in ${latency_ms}ms (>= ${REACHABILITY_LATENCY_WARN_MS}ms threshold)"
	fi
}

main(){
	check_reachability "$REACHABILITY_TARGET"
}

main
