#!/usr/bin/env bash
# ==============================================================================
# grade.sh - Automated Grader for Assignment 1: Linux, Bash & Networking
# Evaluates code, structure, runtime behavior, error handling, logging & git history
# TS Academy DevOps Practical Assignments - Total Rubric: 100 Points
# ==============================================================================

set -uo pipefail

TOTAL_SCORE=0
MAX_SCORE=100

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

pass_check() {
    local points="$1"
    local desc="$2"
    TOTAL_SCORE=$((TOTAL_SCORE + points))
    echo -e "  [${GREEN}PASS${NC}] (+${points} pts) ${desc}"
}

fail_check() {
    local points="$1"
    local desc="$2"
    echo -e "  [${RED}FAIL${NC}] (0/${points} pts) ${desc}"
}

section_header() {
    local title="$1"
    local max="$2"
    echo ""
    echo -e "${BOLD}${BLUE}=== Section: ${title} (Max: ${max} pts) ===${NC}"
}

echo "================================================================="
echo -e "${BOLD}       DEVOPS ASSIGNMENT 1: AUTOMATED GRADING SUITE              ${NC}"
echo "================================================================="
echo "Testing environment: $(uname -s) $(uname -r)"
echo "Grading initiated at: $(date)"

# Clean previous test logs for fresh testing
rm -f logs/*.log 2>/dev/null || true

# ------------------------------------------------------------------------------
# 1. LINUX COMMANDS (20 Points)
# ------------------------------------------------------------------------------
section_header "Linux Commands" 20

SYSTEM_OUT="$(./system-info.sh 2>&1 || true)"

# Check Hostname & User (4 pts)
if echo "${SYSTEM_OUT}" | grep -iq "Hostname" && echo "${SYSTEM_OUT}" | grep -iq "Current User"; then
    pass_check 4 "system-info.sh reports Hostname and Current User"
else
    fail_check 4 "system-info.sh missing Hostname or Current User"
fi

# Check OS & Kernel (4 pts)
if echo "${SYSTEM_OUT}" | grep -iq "Operating System" && echo "${SYSTEM_OUT}" | grep -iq "Kernel Version"; then
    pass_check 4 "system-info.sh reports Operating System and Kernel Version"
else
    fail_check 4 "system-info.sh missing Operating System or Kernel Version"
fi

# Check Uptime (4 pts)
if echo "${SYSTEM_OUT}" | grep -iq "Uptime"; then
    pass_check 4 "system-info.sh reports System Uptime"
else
    fail_check 4 "system-info.sh missing System Uptime"
fi

# Check CPU & Memory (4 pts)
if echo "${SYSTEM_OUT}" | grep -iq "CPU" && echo "${SYSTEM_OUT}" | grep -iq "Memory"; then
    pass_check 4 "system-info.sh reports CPU and Memory metrics"
else
    fail_check 4 "system-info.sh missing CPU or Memory metrics"
fi

# Check Working Directory & Dynamic Execution (4 pts)
CURRENT_PWD="$(pwd)"
if echo "${SYSTEM_OUT}" | grep -q "${CURRENT_PWD}"; then
    pass_check 4 "system-info.sh dynamically captures current working directory"
else
    fail_check 4 "system-info.sh failed to capture current working directory dynamically"
fi

# ------------------------------------------------------------------------------
# 2. BASH SCRIPTING (25 Points)
# ------------------------------------------------------------------------------
section_header "Bash Scripting" 25

# Check Required Files (5 pts)
REQ_FILES=("system-info.sh" "disk-check.sh" "network-check.sh" "README.md" "logs/.gitkeep")
ALL_FILES_EXIST=1
for f in "${REQ_FILES[@]}"; do
    if [ ! -f "${f}" ]; then
        ALL_FILES_EXIST=0
        break
    fi
done
if [ "${ALL_FILES_EXIST}" -eq 1 ]; then
    pass_check 5 "All required files and directory structure present"
else
    fail_check 5 "Missing required files in repository structure"
fi

# Check Shebangs (5 pts)
VALID_SHEBANG=1
for f in system-info.sh disk-check.sh network-check.sh; do
    FIRST_LINE="$(head -n1 "${f}")"
    if [[ ! "${FIRST_LINE}" =~ ^#!/(bin/bash|usr/bin/env[[:space:]]+bash) ]]; then
        VALID_SHEBANG=0
        break
    fi
done
if [ "${VALID_SHEBANG}" -eq 1 ]; then
    pass_check 5 "Proper Bash shebangs (#/bin/bash or #!/usr/bin/env bash)"
else
    fail_check 5 "Invalid shebang found in one or more scripts"
fi

# Check Syntax with bash -n (5 pts)
SYNTAX_OK=1
for f in system-info.sh disk-check.sh network-check.sh; do
    if ! bash -n "${f}" 2>/dev/null; then
        SYNTAX_OK=0
        break
    fi
done
if [ "${SYNTAX_OK}" -eq 1 ]; then
    pass_check 5 "All Bash scripts pass syntax validation (bash -n)"
else
    fail_check 5 "Syntax error detected in Bash scripts"
fi

# Check Executable Permissions (5 pts)
EXEC_OK=1
for f in system-info.sh disk-check.sh network-check.sh; do
    if [ ! -x "${f}" ]; then
        EXEC_OK=0
        break
    fi
done
if [ "${EXEC_OK}" -eq 1 ]; then
    pass_check 5 "Executable permissions (+x) verified on all scripts"
else
    fail_check 5 "Missing executable permissions on one or more scripts"
fi

# Check disk-check.sh functionality (5 pts)
# Threshold of 100% should exit 0 on any normal filesystem
set +e
./disk-check.sh 100 / >/dev/null 2>&1
DISK_EXIT_100=$?
./disk-check.sh 1 / >/dev/null 2>&1
DISK_EXIT_1=$?
set -e
if [ "${DISK_EXIT_100}" -eq 0 ] && [ "${DISK_EXIT_1}" -eq 1 ]; then
    pass_check 5 "disk-check.sh correctly evaluates threshold (exit 0 < threshold, exit 1 >= threshold)"
else
    fail_check 5 "disk-check.sh threshold logic failed (100% exit: ${DISK_EXIT_100}, 1% exit: ${DISK_EXIT_1})"
fi

# ------------------------------------------------------------------------------
# 3. NETWORKING (20 Points)
# ------------------------------------------------------------------------------
section_header "Networking" 20

NET_OUT="$(./network-check.sh 127.0.0.1 2>&1 || true)"

# Host resolution (5 pts)
if echo "${NET_OUT}" | grep -iq "Resolved Address"; then
    pass_check 5 "network-check.sh resolves host and displays address"
else
    fail_check 5 "network-check.sh did not display resolved host address"
fi

# Connectivity check (5 pts)
if echo "${NET_OUT}" | grep -iq "Connectivity Check" || echo "${NET_OUT}" | grep -iq "Ping"; then
    pass_check 5 "network-check.sh executes basic connectivity check (Ping/ICMP)"
else
    fail_check 5 "network-check.sh missing basic connectivity check"
fi

# Network interface information (5 pts)
if echo "${NET_OUT}" | grep -iq "Interface" || echo "${NET_OUT}" | grep -E -q "lo|eth|wlan"; then
    pass_check 5 "network-check.sh reports local network interface information"
else
    fail_check 5 "network-check.sh missing network interface information"
fi

# TCP Port check when provided (5 pts)
set +e
./network-check.sh 127.0.0.1 65530 >/dev/null 2>&1
PORT_CHECK_RUN=$?
set -e
# Port check should execute and return exit 0 or 1 depending on whether port is open
if [ "${PORT_CHECK_RUN}" -eq 0 ] || [ "${PORT_CHECK_RUN}" -eq 1 ]; then
    pass_check 5 "network-check.sh successfully performs TCP port connectivity check"
else
    fail_check 5 "network-check.sh port check crashed or failed unexpectedly (exit: ${PORT_CHECK_RUN})"
fi

# ------------------------------------------------------------------------------
# 4. ERROR HANDLING (10 Points)
# ------------------------------------------------------------------------------
section_header "Error Handling" 10

set +e
# Test disk-check with missing args, non-numeric, out-of-range, non-existent path
./disk-check.sh >/dev/null 2>&1
D_ERR1=$?
./disk-check.sh abc >/dev/null 2>&1
D_ERR2=$?
./disk-check.sh 150 >/dev/null 2>&1
D_ERR3=$?
./disk-check.sh 50 /non_existent_path_xyz_123 >/dev/null 2>&1
D_ERR4=$?

if [ "${D_ERR1}" -eq 2 ] && [ "${D_ERR2}" -eq 2 ] && [ "${D_ERR3}" -eq 2 ] && [ "${D_ERR4}" -eq 2 ]; then
    pass_check 5 "disk-check.sh returns exit code 2 on all invalid inputs"
else
    fail_check 5 "disk-check.sh exit codes on invalid input incorrect (got: ${D_ERR1}, ${D_ERR2}, ${D_ERR3}, ${D_ERR4}, expected 2)"
fi

# Test network-check with missing host, invalid port, out-of-range port
./network-check.sh >/dev/null 2>&1
N_ERR1=$?
./network-check.sh 127.0.0.1 notaport >/dev/null 2>&1
N_ERR2=$?
./network-check.sh 127.0.0.1 99999 >/dev/null 2>&1
N_ERR3=$?
set -e

if [ "${N_ERR1}" -eq 2 ] && [ "${N_ERR2}" -eq 2 ] && [ "${N_ERR3}" -eq 2 ]; then
    pass_check 5 "network-check.sh returns exit code 2 on all invalid arguments"
else
    fail_check 5 "network-check.sh exit codes on invalid input incorrect (got: ${N_ERR1}, ${N_ERR2}, ${N_ERR3}, expected 2)"
fi

# ------------------------------------------------------------------------------
# 5. LOGGING (10 Points)
# ------------------------------------------------------------------------------
section_header "Logging" 10

if [ -d "logs" ] && [ -f "logs/.gitkeep" ]; then
    pass_check 2 "logs/ directory exists with .gitkeep tracking"
else
    fail_check 2 "logs/ directory or .gitkeep missing"
fi

# Run scripts to trigger logging
./system-info.sh >/dev/null 2>&1 || true
./disk-check.sh 90 / >/dev/null 2>&1 || true
./network-check.sh 127.0.0.1 >/dev/null 2>&1 || true

LOGS_CREATED=0
if [ -f "logs/system-info.log" ] && [ -f "logs/disk-check.log" ] && [ -f "logs/network-check.log" ]; then
    LOGS_CREATED=1
fi

if [ "${LOGS_CREATED}" -eq 1 ]; then
    pass_check 4 "Log files generated in logs/ for all three scripts"
else
    fail_check 4 "One or more script log files not created in logs/"
fi

# Check log format for timestamp and description
LOG_FORMAT_OK=0
if grep -E -q "\[[0-9]{4}-[0-9]{2}-[0-9]{2}.*\]" logs/system-info.log 2>/dev/null && \
   grep -E -q "\[[0-9]{4}-[0-9]{2}-[0-9]{2}.*\]" logs/disk-check.log 2>/dev/null && \
   grep -E -q "\[[0-9]{4}-[0-9]{2}-[0-9]{2}.*\]" logs/network-check.log 2>/dev/null; then
    LOG_FORMAT_OK=1
fi

if [ "${LOG_FORMAT_OK}" -eq 1 ]; then
    pass_check 4 "Logs contain valid timestamps and descriptive operation records"
else
    fail_check 4 "Log entries lack standard timestamp or operation description"
fi

# ------------------------------------------------------------------------------
# 6. GIT WORKFLOW (10 Points)
# ------------------------------------------------------------------------------
section_header "Git Workflow" 10

COMMIT_COUNT=0
if [ -d ".git" ]; then
    COMMIT_COUNT="$(git rev-list --count HEAD 2>/dev/null || echo 0)"
fi

if [ "${COMMIT_COUNT}" -ge 5 ]; then
    pass_check 5 "Git history verified with ${COMMIT_COUNT} commits (>= 5 required)"
else
    fail_check 5 "Fewer than 5 Git commits detected (found: ${COMMIT_COUNT})"
fi

# Check for branch history / merge commit
HAS_BRANCH_OR_MERGE=0
if [ -d ".git" ]; then
    # Look for merge commits or multiple branches
    BRANCH_COUNT="$(git branch -a 2>/dev/null | wc -l || echo 0)"
    MERGE_COMMITS="$(git log --merges -n 1 --oneline 2>/dev/null || echo "")"
    if [ -n "${MERGE_COMMITS}" ] || [ "${BRANCH_COUNT}" -ge 2 ]; then
        HAS_BRANCH_OR_MERGE=1
    fi
fi

if [ "${HAS_BRANCH_OR_MERGE}" -eq 1 ]; then
    pass_check 5 "Feature branch workflow and merge history verified"
else
    fail_check 5 "No feature branch or merge commit detected in Git history"
fi

# ------------------------------------------------------------------------------
# 7. README DOCUMENTATION (5 Points)
# ------------------------------------------------------------------------------
section_header "README Documentation" 5

if [ -s "README.md" ]; then
    pass_check 2 "README.md exists and is well populated"
else
    fail_check 2 "README.md is missing or empty"
fi

README_COMPLETE=0
if grep -iq "installation" README.md && \
   grep -iq "usage" README.md && \
   grep -iq "exit code" README.md && \
   grep -iq "testing" README.md; then
    README_COMPLETE=1
fi

if [ "${README_COMPLETE}" -eq 1 ]; then
    pass_check 3 "README.md covers Setup, Usage, Testing, and Exit Codes"
else
    fail_check 3 "README.md missing one or more required documentation sections"
fi

# ------------------------------------------------------------------------------
# FINAL SCORE CALCULATION
# ------------------------------------------------------------------------------
echo ""
echo "================================================================="
echo -e "${BOLD}                     FINAL GRADE REPORT                          ${NC}"
echo "================================================================="
if [ "${TOTAL_SCORE}" -eq "${MAX_SCORE}" ]; then
    echo -e "Final Score: ${GREEN}${BOLD}${TOTAL_SCORE} / ${MAX_SCORE} (100% - PERFECT SCORE)${NC}"
else
    echo -e "Final Score: ${YELLOW}${BOLD}${TOTAL_SCORE} / ${MAX_SCORE}${NC}"
fi
echo "================================================================="

if [ "${TOTAL_SCORE}" -eq "${MAX_SCORE}" ]; then
    exit 0
else
    exit 1
fi
