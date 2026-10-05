#!/usr/bin/env bash

# config.sh is the central tunables fpr every script in this repo
# Source this, don't execute it directly


# Paths

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_DIR="${DATA_DIR:-$REPO_ROOT/data}"
LOG_FILE="${LOG_FILE:-$DATA_DIR/toolkit.log}"

# Sampling intervals 
RESOURCE_SAMPLE_INTERVAL="${RESOURCE_SAMPLE_INTERVAL:-10}"
NETWORK_SAMPLE_INTERVAL="${NETWORK_SAMPLE_INTERVAL:-10}"

# Resource thresholds
CPU_WARN_PCT="${CPU_WARN_PCT:-75}"
CPU_CRIT_PCT="${CPU_CRIT_PCT:-90}"
MEM_WARN_PCT="${MEM_WARN_PCT:-80}"
MEM_CRIT_PCT="${MEM_CRIT_PCT:-95}"
DISK_WARN_PCT="${DISK_WARN_PCT:-80}"
DISK_CRIT_PCT="${DISK_CRIT_PCT:-90}"
DISK_GROWTH_WARN_MB_PER_MIN="${DISK_GROWTH_WARN_MB_PER_MIN:-50}"

# LOG MONITORING

LOG_ERROR_RATE_WARN="${LOG_ERROR_RATE_WARN:-10}"
LOG_RETENTION_DAYS="${LOG_RETENTION_DAYS:-14}"

# Network threshold
CONN_WARN_COUNT="${CONN_WARN_COUNT:-500}"
TIME_WAIT_WARN_COUNT="${TIME_WAIT_WARN_COUNT:-200}"

ALERT_BACKEND="${ALERT_BACKEND:-log}"   ## log | email | webhook
