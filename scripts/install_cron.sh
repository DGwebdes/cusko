#!/usr/bin/env bash

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/config.sh"

RUN_ALL_PATH="$SCRIPT_DIR/run_all.sh"
CRON_LINE="*/${TOOLKIT_RUN_INTERVAL_MIN} * * * * ${RUN_ALL_PATH} >> ${DATA_DIR}/cron.log 2>&1"

main(){
	echo "Suggested crontab entry (runs every ${TOOLKIT_RUN_INTERVAL_MIN} minutes):"
	echo "  ${CRON_LINE}"
	echo

	if [[ "${1:-}" != "--install" ]]; then
		echo "To install: re-run with --install, or add the line above manually via 'crontab -e'."
		return 0
	fi
	
	if ! command -v crontab >/dev/null 2>&1; then
		log_warn "install_cron: --install request but 'crontab' is not available on this system"
		echo "crontab is not installed here. Add the line above via your system's own scheduler instead"
		return 1
	fi

	( crontab -l 2>/dev/null; echo "$CRON_LINE" ) | crontab -
	log_info "install_cron: installed crontab entry"
	echo "Installed. Verify with: crontab -l"
}

main "$@"
