#!/usr/bin/env bash
# ==============================================================================
# system-info.sh - Collect and display comprehensive Linux system information
# Part of DevOps Assignment 1: Linux, Bash & Networking Toolkit
# ==============================================================================

set -euo pipefail

# Determine script and logs directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/system-info.log"

# Ensure logs directory exists
mkdir -p "${LOG_DIR}"

TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S %Z')"
ISO_TIMESTAMP="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

echo "================================================================="
echo "                  SYSTEM INFORMATION REPORT                      "
echo "================================================================="
echo "Report Generated at : ${TIMESTAMP}"
echo "-----------------------------------------------------------------"

# 1. Hostname & Current User
HOSTNAME_VAL="$(hostname 2>/dev/null || cat /etc/hostname 2>/dev/null || uname -n)"
CURRENT_USER="$(id -un 2>/dev/null || whoami 2>/dev/null || echo "${USER:-unknown}")"
echo "Hostname            : ${HOSTNAME_VAL}"
echo "Current User        : ${CURRENT_USER}"

# 2. Operating System & Kernel Version
if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    OS_NAME="$(. /etc/os-release && echo "${PRETTY_NAME:-Linux}")"
elif command -v lsb_release >/dev/null 2>&1; then
    OS_NAME="$(lsb_release -d -s)"
else
    OS_NAME="$(uname -s)"
fi
KERNEL_VERSION="$(uname -r)"
echo "Operating System    : ${OS_NAME}"
echo "Kernel Version      : ${KERNEL_VERSION}"

# 3. System Uptime
if [ -f /proc/uptime ]; then
    UPTIME_SECONDS="$(awk '{print int($1)}' /proc/uptime)"
    UPTIME_DAYS=$((UPTIME_SECONDS / 86400))
    UPTIME_HOURS=$(((UPTIME_SECONDS % 86400) / 3600))
    UPTIME_MINUTES=$(((UPTIME_SECONDS % 3600) / 60))
    UPTIME_STR="${UPTIME_DAYS}d ${UPTIME_HOURS}h ${UPTIME_MINUTES}m"
elif command -v uptime >/dev/null 2>&1; then
    UPTIME_STR="$(uptime -p 2>/dev/null || uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')"
else
    UPTIME_STR="N/A"
fi
echo "Uptime              : ${UPTIME_STR}"

# 4. CPU Information
CPU_CORES="$(nproc 2>/dev/null || grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo "1")"
if [ -f /proc/cpuinfo ]; then
    CPU_MODEL="$(grep -m1 'model name' /proc/cpuinfo | awk -F': ' '{print $2}' | xargs || echo "Unknown CPU")"
else
    CPU_MODEL="$(uname -m)"
fi
if [ -f /proc/loadavg ]; then
    LOAD_AVG="$(awk '{print $1, $2, $3}' /proc/loadavg)"
else
    LOAD_AVG="N/A"
fi
echo "CPU Model           : ${CPU_MODEL}"
echo "CPU Cores           : ${CPU_CORES}"
echo "Load Average (1/5/15): ${LOAD_AVG}"

# 5. Memory Information
if command -v free >/dev/null 2>&1; then
    MEM_TOTAL="$(free -h | awk '/^Mem:/ {print $2}')"
    MEM_USED="$(free -h | awk '/^Mem:/ {print $3}')"
    MEM_FREE="$(free -h | awk '/^Mem:/ {print $4}')"
elif [ -f /proc/meminfo ]; then
    TOTAL_KB="$(awk '/MemTotal:/ {print $2}' /proc/meminfo)"
    FREE_KB="$(awk '/MemFree:/ {print $2}' /proc/meminfo)"
    MEM_TOTAL="$((TOTAL_KB / 1024)) MB"
    MEM_FREE="$((FREE_KB / 1024)) MB"
    MEM_USED="$(((TOTAL_KB - FREE_KB) / 1024)) MB"
else
    MEM_TOTAL="N/A"
    MEM_USED="N/A"
    MEM_FREE="N/A"
fi
echo "Memory Total        : ${MEM_TOTAL}"
echo "Memory Used         : ${MEM_USED}"
echo "Memory Free         : ${MEM_FREE}"

# 6. Current Working Directory
CWD_VAL="$(pwd)"
echo "Current Working Dir : ${CWD_VAL}"
echo "================================================================="

# Log execution
LOG_ENTRY="[${ISO_TIMESTAMP}] [system-info] Hostname=${HOSTNAME_VAL} User=${CURRENT_USER} OS='${OS_NAME}' Kernel=${KERNEL_VERSION} CWD=${CWD_VAL} Status=SUCCESS"
echo "${LOG_ENTRY}" >> "${LOG_FILE}"

exit 0
