#!/usr/bin/env bash

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/config.sh"
source "$SCRIPT_DIR/../../lib/alert.sh"

source "$SCRIPT_DIR/sampler.sh"

check_metrics(){
	local name="$1" value="$2" warn="$3" crit="$4"
	if (( value >= crit )); then
		alert CRIT "${name} at ${value}% (>= crit threshold ${crit}%)"
	elif (( value >= warn )); then
		alert WARN "${name} at ${value}% (>= warn threshold ${warn}%)"
	fi
}

main(){
	local cpu mem disk fds
	cpu="$(sample_cpu)"
	mem="$(sample_mem)"
	disk="$(sample_disk)"
	fds="$(sample_fds)"

	log_info "cpu=${cpu}% mem=${mem}% disk=${disk}% fds=${fds}"

	check_metrics "CPU" "$cpu" "$CPU_WARN_PCT" "$CPU_CRIT_PCT"
	check_metrics "Mem" "$mem" "$MEM_WARN_PCT" "$MEM_CRIT_PCT"
	check_metrics "Disk" "$disk" "$DISK_WARN_PCT" "$DISK_CRIT_PCT"
}

main
