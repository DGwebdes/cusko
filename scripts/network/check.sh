#!/usr/bin/env bash

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/config.sh"
source "$SCRIPT_DIR/../../lib/alert.sh"
source "$SCRIPT_DIR/sampler.sh"

check_metric(){
	local name="$1" value="$2" warn="$3"

	if ((value >= warn )); then
		alert WARN "${name} at ${value} (>= warn threshold ${warn})"
	fi
}

trigger_resource_snapshot(){
	local reason="$1"
	log_info "Chaining: ${reason} triggered a resource snapshot"

	"$SCRIPT_DIR/../resources/sampler.sh"
}

main(){
	local total time_wait breached=0
	total="$(sample_conn_total)"
	time_wait="$(sample_time_wait_count)"

	log_info "conn_total=${total} time_wait=${time_wait}"

	check_metric "Connections" "$total" "$CONN_WARN_COUNT"
	check_metric "TIME_WAIT connections" "$time_wait" "$TIME_WAIT_WARN_COUNT"

	if ((breached)) && [[ "$CHAIN_SNAPSHOT_ON_BREACH" == "true" ]]; then
		trigger_resource_snapshot "network threshold breach"
	fi
}

main
