#!/usr/bin/env bash


set -uo pipefail

LOG_FILE="${LOG_FILE:-$(dirname "${BASH_SOURCE[0]}")/../data/toolkit.log}"

_log(){
	local level="$1"; shift
	local ts line
	ts="$(date '+%Y-%m-%d %H:%M:%S')"
	line="[$ts] [$level] $*" 

	mkdir -p "$(dirname "$LOG_FILE")"
	echo "$line" >> "$LOG_FILE"

	if [[ "$level" == "CRIT" ]]; then
		echo "$line" >&2
	else
		echo "$line"
	fi
}

log_info() { _log "INFO" "$@"; }
log_warn() { _log "WARN" "$@"; }
log_crit() { _log "CRIT" "$@"; }

die() {
	log_crit "$*"
	exit 1
}
