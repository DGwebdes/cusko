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
LOG_TARGET_PATH="${LOG_TARGET_PATH:-$DATA_DIR/app.log}"
LOG_SOURCES="${LOG_SOURCES:-$LOG_TARGET_PATH}"
LOG_ERROR_PATTERN="${LOG_ERROR_PATTERN:-ERROR|CRIT|FATAL}"
LOG_ERROR_RATE_WARN="${LOG_ERROR_RATE_WARN:-10}"
LOG_RETENTION_DAYS="${LOG_RETENTION_DAYS:-14}"
LOG_ROTATE_MAX_MB="${LOG_ROTATE_MAX_MB:-10}"

# Network threshold
CONN_WARN_COUNT="${CONN_WARN_COUNT:-500}"
TIME_WAIT_WARN_COUNT="${TIME_WAIT_WARN_COUNT:-200}"
REACHABILITY_TARGET="${REACHABILITY_TARGET:-https://google.com}"
REACHABILITY_LATENCY_WARN_MS="${REACHABILITY_LATENCY_WARN_MS:-1000}"

# Alert dispatch backend - read be alert.sh, not chosen by individual script
ALERT_BACKEND="${ALERT_BACKEND:-log}"   ## log | email | webhook


# Cross-scrip chaining = network breach triggers a resource snapshot
CHAIN_SNAPSHOT_ON_BREACH="${CHAIN_SNAPSHOT_ON_BREACH:-true}"

# Scheduling - how often run_all.sh should run via cron
TOOLKIT_RUN_INTERVAL_MIN="${TOOLKIT_RUN_INTERVAL_MIN:-5}"


