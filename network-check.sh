#!/usr/bin/env bash
# ==============================================================================
# network-check.sh - Network diagnostic and connectivity validation script
# Part of DevOps Assignment 1: Linux, Bash & Networking Toolkit
# Usage: ./network-check.sh <hostname-or-ip> [port]
# ==============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/network-check.log"

mkdir -p "${LOG_DIR}"

log_message() {
    local status="$1"
    local desc="$2"
    local iso_ts
    iso_ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    echo "[${iso_ts}] [network-check] Status=${status} ${desc}" >> "${LOG_FILE}"
}

usage() {
    cat <<EOF
Usage: $0 <hostname-or-ip> [port]
  hostname-or-ip : Domain name or IPv4/IPv6 address to test (Required)
  port           : Optional TCP port number (1-65535) to test connectivity

Exit Codes:
  0 : Network and port checks succeeded
  1 : Connectivity or port test failed
  2 : Invalid input or arguments
EOF
}

# 1. Input Validation - Host
if [ $# -lt 1 ]; then
    echo "Error: Hostname or IP address argument is required." >&2
    usage >&2
    log_message "ERROR" "Missing host argument"
    exit 2
fi

TARGET_HOST="$1"
TARGET_PORT="${2:-}"

if [ -z "${TARGET_HOST}" ] || [[ "${TARGET_HOST}" =~ ^[[:space:]]+$ ]]; then
    echo "Error: Host argument cannot be empty or whitespace." >&2
    usage >&2
    log_message "ERROR" "Empty host argument provided"
    exit 2
fi

# Validate Port if provided
if [ -n "${TARGET_PORT}" ]; then
    if ! [[ "${TARGET_PORT}" =~ ^[0-9]+$ ]]; then
        echo "Error: Port must be a numeric integer between 1 and 65535 (received: '${TARGET_PORT}')." >&2
        usage >&2
        log_message "ERROR" "Invalid non-numeric port: '${TARGET_PORT}'"
        exit 2
    fi

    if [ "${TARGET_PORT}" -lt 1 ] || [ "${TARGET_PORT}" -gt 65535 ]; then
        echo "Error: Port out of range [1-65535] (received: ${TARGET_PORT})." >&2
        usage >&2
        log_message "ERROR" "Port out of range: ${TARGET_PORT}"
        exit 2
    fi
fi

echo "================================================================="
echo "                  NETWORK DIAGNOSTIC REPORT                      "
echo "================================================================="
echo "Target Host         : ${TARGET_HOST}"
if [ -n "${TARGET_PORT}" ]; then
    echo "Target TCP Port     : ${TARGET_PORT}"
fi
echo "-----------------------------------------------------------------"

OVERALL_SUCCESS=0

# 2. Host Resolution
echo "[+] DNS Resolution:"
RESOLVED_IP=""
if command -v getent >/dev/null 2>&1; then
    RESOLVED_IP="$(getent ahostsv4 "${TARGET_HOST}" 2>/dev/null | awk '{print $1}' | head -n1 || true)"
    if [ -z "${RESOLVED_IP}" ]; then
        RESOLVED_IP="$(getent hosts "${TARGET_HOST}" 2>/dev/null | awk '{print $1}' | head -n1 || true)"
    fi
fi

if [ -z "${RESOLVED_IP}" ] && command -v nslookup >/dev/null 2>&1; then
    RESOLVED_IP="$(nslookup "${TARGET_HOST}" 2>/dev/null | awk '/^Address: / {print $2}' | tail -n1 || true)"
fi

if [ -z "${RESOLVED_IP}" ] && command -v host >/dev/null 2>&1; then
    RESOLVED_IP="$(host "${TARGET_HOST}" 2>/dev/null | awk '/has address/ {print $4}' | head -n1 || true)"
fi

# If target is already an IP address
if [[ "${TARGET_HOST}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || [[ "${TARGET_HOST}" == "localhost" ]]; then
    if [ -z "${RESOLVED_IP}" ]; then
        RESOLVED_IP="${TARGET_HOST}"
    fi
fi

if [ -n "${RESOLVED_IP}" ]; then
    echo "    Resolved Address: ${RESOLVED_IP}"
    log_message "INFO" "Resolved '${TARGET_HOST}' -> '${RESOLVED_IP}'"
else
    echo "    Warning: Could not resolve '${TARGET_HOST}'."
    log_message "WARN" "Resolution failed for '${TARGET_HOST}'"
fi

# 3. Basic Connectivity Check (Ping)
echo ""
echo "[+] ICMP Connectivity Check (Ping):"
PING_CMD=""
if command -v ping >/dev/null 2>&1; then
    PING_CMD="ping -c 2 -W 2"
fi

PING_OK=0
if [ -n "${PING_CMD}" ]; then
    if ${PING_CMD} "${TARGET_HOST}" >/dev/null 2>&1; then
        echo "    Ping Status     : REACHABLE"
        PING_STATS="$(${PING_CMD} "${TARGET_HOST}" 2>&1 | tail -n 2)"
        echo "    Statistics      :"
        echo "${PING_STATS}" | sed 's/^/      /'
        PING_OK=1
    else
        echo "    Ping Status     : UNREACHABLE or ICMP blocked"
        PING_OK=0
    fi
else
    echo "    Ping Status     : 'ping' utility not installed (skipping ICMP test)"
    PING_OK=1
fi

# 4. Local Network Interface Information
echo ""
echo "[+] Local Network Interfaces:"
if command -v ip >/dev/null 2>&1; then
    ip -br addr show 2>/dev/null || ip addr show
elif command -v ifconfig >/dev/null 2>&1; then
    ifconfig
else
    echo "    Interface information utility ('ip' or 'ifconfig') not found."
fi

# 5. Optional TCP Port Connectivity
PORT_OK=1
if [ -n "${TARGET_PORT}" ]; then
    echo ""
    echo "[+] TCP Port Check (${TARGET_HOST}:${TARGET_PORT}):"
    PORT_CONNECTED=0
    
    # Try netcat if available
    if command -v nc >/dev/null 2>&1; then
        if nc -z -w 3 "${TARGET_HOST}" "${TARGET_PORT}" >/dev/null 2>&1; then
            PORT_CONNECTED=1
        fi
    elif (timeout 3 bash -c "cat < /dev/null > /dev/tcp/${TARGET_HOST}/${TARGET_PORT}") >/dev/null 2>&1; then
        PORT_CONNECTED=1
    fi

    if [ "${PORT_CONNECTED}" -eq 1 ]; then
        echo "    Port Status     : OPEN / REACHABLE"
        log_message "OK" "Host='${TARGET_HOST}' Port=${TARGET_PORT} Status=OPEN"
        PORT_OK=1
    else
        echo "    Port Status     : CLOSED / FILTERED / UNREACHABLE"
        log_message "FAIL" "Host='${TARGET_HOST}' Port=${TARGET_PORT} Status=CLOSED_OR_UNREACHABLE"
        PORT_OK=0
    fi
fi

echo "================================================================="

# Determine overall exit code
# If host could not be resolved and ping failed, or if port check failed -> exit 1
if [ -n "${TARGET_PORT}" ]; then
    if [ "${PORT_OK}" -eq 1 ]; then
        echo "Final Status        : SUCCESS"
        log_message "SUCCESS" "Host='${TARGET_HOST}' Port=${TARGET_PORT} Completed successfully"
        exit 0
    else
        echo "Final Status        : PORT CHECK FAILED"
        exit 1
    fi
else
    if [ "${PING_OK}" -eq 1 ] || [ -n "${RESOLVED_IP}" ]; then
        echo "Final Status        : SUCCESS"
        log_message "SUCCESS" "Host='${TARGET_HOST}' Completed successfully"
        exit 0
    else
        echo "Final Status        : HOST UNREACHABLE"
        log_message "FAIL" "Host='${TARGET_HOST}' Unreachable"
        exit 1
    fi
fi
