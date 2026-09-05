#!/usr/bin/env bash
# ==============================================================================
# disk-check.sh - Check filesystem disk usage against a threshold
# Part of DevOps Assignment 1: Linux, Bash & Networking Toolkit
# Usage: ./disk-check.sh <threshold> [path]
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/disk-check.log"

mkdir -p "${LOG_DIR}"

log_message() {
    local status="$1"
    local desc="$2"
    local iso_ts
    iso_ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    echo "[${iso_ts}] [disk-check] Status=${status} ${desc}" >> "${LOG_FILE}"
}

usage() {
    cat <<EOF
Usage: $0 <threshold> [path]
  threshold : Integer percentage from 1 to 100
  path      : Target filesystem path to inspect (default: /)

Exit Codes:
  0 : Usage is below threshold (OK)
  1 : Usage reaches or exceeds threshold (ALERT)
  2 : Invalid input or arguments
EOF
}

# Validate argument count
if [ $# -lt 1 ]; then
    echo "Error: Missing required threshold argument." >&2
    usage >&2
    log_message "ERROR" "Missing threshold argument"
    exit 2
fi

THRESHOLD="$1"
TARGET_PATH="${2:-/}"

# Validate threshold is an integer
if ! [[ "${THRESHOLD}" =~ ^[0-9]+$ ]]; then
    echo "Error: Threshold must be a positive integer (received: '${THRESHOLD}')." >&2
    usage >&2
    log_message "ERROR" "Invalid non-integer threshold: '${THRESHOLD}'"
    exit 2
fi

# Validate threshold range 1 to 100
if [ "${THRESHOLD}" -lt 1 ] || [ "${THRESHOLD}" -gt 100 ]; then
    echo "Error: Threshold must be between 1 and 100 (received: ${THRESHOLD})." >&2
    usage >&2
    log_message "ERROR" "Threshold out of range [1-100]: ${THRESHOLD}"
    exit 2
fi

# Validate path existence
if [ ! -e "${TARGET_PATH}" ]; then
    echo "Error: Target path does not exist: '${TARGET_PATH}'." >&2
    log_message "ERROR" "Target path not found: '${TARGET_PATH}'"
    exit 2
fi

# Determine disk usage percentage using POSIX df -P
# df -P output: Filesystem 1024-blocks Used Available Capacity Mounted on
DF_OUTPUT="$(df -P "${TARGET_PATH}" 2>/dev/null | awk 'NR==2')"
if [ -z "${DF_OUTPUT}" ]; then
    echo "Error: Unable to retrieve disk usage for '${TARGET_PATH}'." >&2
    log_message "ERROR" "df command failed for path: '${TARGET_PATH}'"
    exit 2
fi

FILESYSTEM="$(echo "${DF_OUTPUT}" | awk '{print $1}')"
TOTAL_BLOCKS="$(echo "${DF_OUTPUT}" | awk '{print $2}')"
USED_BLOCKS="$(echo "${DF_OUTPUT}" | awk '{print $3}')"
AVAIL_BLOCKS="$(echo "${DF_OUTPUT}" | awk '{print $4}')"
USAGE_PCT_STR="$(echo "${DF_OUTPUT}" | awk '{print $5}')" # e.g. "45%"
USAGE_PCT="${USAGE_PCT_STR%\%}" # strip % sign
MOUNT_POINT="$(echo "${DF_OUTPUT}" | awk '{print $6}')"

echo "================================================================="
echo "                    DISK USAGE CHECK REPORT                      "
echo "================================================================="
echo "Target Path         : ${TARGET_PATH}"
echo "Mounted Filesystem  : ${FILESYSTEM}"
echo "Mount Point         : ${MOUNT_POINT}"
echo "Total Space (KB)    : ${TOTAL_BLOCKS}"
echo "Used Space (KB)     : ${USED_BLOCKS}"
echo "Available (KB)      : ${AVAIL_BLOCKS}"
echo "Current Usage       : ${USAGE_PCT}%"
echo "Configured Threshold: ${THRESHOLD}%"
echo "-----------------------------------------------------------------"

if [ "${USAGE_PCT}" -ge "${THRESHOLD}" ]; then
    echo "ALERT: Disk usage (${USAGE_PCT}%) has reached or exceeded threshold (${THRESHOLD}%)!"
    echo "Status: CRITICAL"
    echo "================================================================="
    log_message "ALERT" "Path='${TARGET_PATH}' Usage=${USAGE_PCT}% Threshold=${THRESHOLD}% MountedOn='${MOUNT_POINT}'"
    exit 1
else
    echo "OK: Disk usage (${USAGE_PCT}%) is strictly below threshold (${THRESHOLD}%)."
    echo "Status: OK"
    echo "================================================================="
    log_message "OK" "Path='${TARGET_PATH}' Usage=${USAGE_PCT}% Threshold=${THRESHOLD}% MountedOn='${MOUNT_POINT}'"
    exit 0
fi
