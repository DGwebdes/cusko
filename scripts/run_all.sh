#!/usr/bin/env bash

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

SCRIPTS=(
	"resources/sampler.sh"
	"resources/check.sh"
	"resources/disk_growth.sh"
	"logs/watch.sh"
	"logs/aggregate.sh"
	"logs/rotate.sh"
	"network/sampler.sh"
	"network/check.sh"
	"network/reachability.sh"
)

main(){
	local script failure=0

	log_info "run_all: starting full pass (${#SCRIPTS[@]} scripts)"

	for script in "${SCRIPTS[@]}"; do
		if ! "$SCRIPT_DIR/$script"; then
			log_warn "run_all: ${script} exited non-zero, continuing with the rest"
			((failure++))
		fi
	done

	log_info "run_all: pass complete, ${failure} scripts(s) reported failure"
}

main
