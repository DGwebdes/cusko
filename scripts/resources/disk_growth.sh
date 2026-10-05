#!/usr/bin/env bash

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/config.sh"
source "$SCRIPT_DIR/../../lib/alert.sh"
source "$SCRIPT_DIR/sampler.sh"

STATE_FILE="${DISK_GROWTH_STATE_FILE:-$DATA_DIR/disk_growth.state}"

main(){
	local now used_mb prev_time prev_used delta_sec delta_mb rate_per_min

	now="$(date +%s)"
	used_mb="$(sample_disk_used_mb)"

	if [[ ! -f "$STATE_FILE" ]]; then
		log_info "Disk Growth Watcher: no prior sample, establishing baseline (${used_mb}MB)"
		echo "$now $used_mb" > "$STATE_FILE"
		return 0
	fi

	read -r prev_time prev_used < "$STATE_FILE"
	delta_sec=$(( now - prev_time ))
	delta_mb=$(( used_mb - prev_used ))

	if ((delta_sec <= 0)); then
		log_warn "DGW: non-positive interval (${delta_sec}s) since last sample, skipping"
		echo "$now $used_mb" > "$STATE_FILE"
		return 0
	fi

	rate_per_min=$(( (delta_mb * 60 + delta_sec / 2) / delta_sec ))

	log_info "Disk growth: ${used_mb}MB used, ${rate_per_min}MB/min over last ${delta_sec}s"

	if (( rate_per_min >= DISK_GROWTH_WARN_MB_PER_MIN )); then
		alert WARN "Disk filling fast: ${rate_per_min}MB/min (>= ${DISK_GROWTH_WARN_MB_PER_MIN}MB/min threshold)"
	fi

	echo "$now $used_mb" > "$STATE_FILE"
}

main
