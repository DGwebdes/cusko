#!/usr/bin/env bash

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/config.sh"

sample_cpu(){
	local u1 n1 s1 i1 io1 irq1 sirq1 st1
	local u2 n2 s2 i2 io2 irq2 sirq2 st2
	local idle1 total1 idle2 total2 idle_delta total_delta

	read -r _ u1 n1 s1 i1 io1 irq1 sirq1 st1 _ _ < /proc/stat
	idle1=$((i1 + io1))
	total1=$((u1 + n1 + s1 + i1 + io1 + irq1 + sirq1 + st1))

	sleep 1

	read -r _ u2 n2 s2 i2 io2 irq2 sirq2 st2 _ _ < /proc/stat
	idle2=$((i2 + io2))
	total2=$((u2 + n2 + s2 + i2 + io2 + irq2 + sirq2 + st2))

	idle_delta=$((idle2 - idle1))
	total_delta=$((total2 - total1))

	if ((total_delta > 0)); then
		echo $(( 100 * (total_delta - idle_delta) / total_delta))
	else
		echo 0
	fi
}

sample_mem(){
	local total avail
	total="$(grep -m1 '^MemTotal:' /proc/meminfo | grep -o '[0-9]\+')"
	avail="$(grep -m1 '^MemAvailable:' /proc/meminfo | grep -o '[0-9]\+')"

	if [[ -n "$total" && "$total" -gt 0 ]]; then
		echo $(( 100 * (total - avail) / total))
	else
		echo 0
	fi
}

sample_disk(){
	local line pct
	line="$(df -P "$DATA_DIR" | tail -1)"
	read -r _ _ _ _ pct _ <<< "$line"
	echo "${pct%\%}"
}

sample_disk_used_mb(){
	local line used_kb
	line="$(df -P "$DATA_DIR" | tail -1)"
	read -r _ _ used_kb _ _ _ <<< "$line"
	echo $(( used_kb / 1024 ))
}

sample_fds(){
	local allocated max
	read -r allocated _ max < /proc/sys/fs/file-nr
	echo "${allocated}/${max}"
}

main(){
	local cpu mem disk fds
	cpu="$(sample_cpu)"
	mem="$(sample_mem)"
	disk="$(sample_disk)"
	fds="$(sample_fds)"

	log_info "cpu=${cpu}% mem=${mem}% disk=${disk}% fds=${fds}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main
fi
