# Implementation Plan - DevOps Practical Assignments Execution & Submission

This plan outlines the complete execution strategy for the **TS Academy (Hajime Cohort) DevOps Practical Assignments** based on the brief in [DevOps_Assignment_Brief_With_Grade_Scripts.pdf](file:///C:/Users/pc/Downloads/DevOps_Assignment_Brief_With_Grade_Scripts.pdf).

The assignment comprises three distinct practical projects that must be developed, tested against a 100-point rubric, tracked in Git with structured branch/merge history, pushed to separate GitHub repositories under `@echeck246`, and prepared for form submission.

---

## User Review Required

> [!IMPORTANT]
> - **GitHub Repositories**: We will create 3 public repositories under your GitHub account (`echeck246`):
>   1. `devops-assignment-1` (Linux, Bash & Networking Toolkit)
>   2. `devops-assignment-2` (Dockerized Diagnostic CLI)
>   3. `devops-assignment-3` (CI/CD Pipeline with GitHub Actions)
> - **Execution Environment**: All scripts and Docker containers will be validated locally in WSL (Ubuntu) and Docker to ensure 100% Linux parity and proper file permissions before pushing to GitHub.
> - **Grading Scripts (`grade.sh`)**: Each repository will contain a self-contained, automated grading script strictly evaluating every item in the instructor's 100-point rubric and outputting a verified 100/100 score.

---

## Proposed Implementation

### 1. Assignment 1 — Linux, Bash & Networking (`assignment-1`)

**Target Structure:**
```text
assignment-1/
├── README.md
├── system-info.sh
├── disk-check.sh
├── network-check.sh
├── grade.sh
└── logs/
    └── .gitkeep
```

- **`system-info.sh`**:
  - Dynamically collects and formats: Hostname, current user, date/time, OS distribution, kernel version, system uptime, CPU info (cores, model, load), memory info (total, used, free), and current working directory.
  - Dynamically writes an audit entry to `logs/system-info.log` with an ISO-8601 timestamp and description.
  - Exit code: `0`.
- **`disk-check.sh`**:
  - Arguments: `./disk-check.sh <threshold> [path]`, defaults `path` to `/`.
  - Strict input validation: Integer check (1–100), directory existence check. Exits `2` on invalid input.
  - Runtime disk usage calculation via `df -P`. Exits `0` if usage < threshold, exits `1` if usage >= threshold.
  - Logs execution details to `logs/disk-check.log`.
- **`network-check.sh`**:
  - Arguments: `./network-check.sh <hostname-or-ip> [port]`.
  - Input validation: Requires hostname/IP (exits `2` if missing); validates port number (1–65535, exits `2` if non-numeric or out-of-range).
  - DNS resolution: Displays resolved IP address using `getent` / `nslookup` / `host`.
  - Connectivity check: ICMP ping check with concise latency/packet statistics.
  - Interface info: Displays active network interfaces and IP addresses (`ip -br addr` / `ip addr`).
  - Optional TCP port check: Tests connectivity to `<host>:<port>` via `nc` or `/dev/tcp` socket.
  - Logs operations to `logs/network-check.log`.
- **`grade.sh`**:
  - Automated test runner testing all rubrics:
    - Linux commands (20 pts)
    - Bash scripting (25 pts)
    - Networking (20 pts)
    - Error handling & exit codes (10 pts)
    - Logging in `logs/` (10 pts)
    - Git commit & branch history (10 pts)
    - README documentation (5 pts)
  - Verifies 100/100 total score.
- **Git History**:
  - Minimum 5 meaningful commits.
  - Branching: Create `feature/network-check`, implement features, and merge into `main` with `--no-ff`.

---

### 2. Assignment 2 — Dockerized Diagnostic CLI (`assignment-2`)

**Target Structure:**
```text
assignment-2/
├── README.md
├── app/
│   ├── diagnostic.sh
│   └── health-check.sh
├── Dockerfile
├── compose.yaml
├── .dockerignore
├── test.sh
└── grade.sh
```

- **`app/diagnostic.sh`**:
  - Modular CLI with subcommands:
    - `diagnostic system`: Displays CPU, memory, uptime, OS, kernel.
    - `diagnostic network <host>`: Resolves host and checks connectivity.
    - `diagnostic disk`: Displays filesystem disk space and mount point usage.
    - `diagnostic help`: Comprehensive command syntax and parameter reference.
  - Proper exit codes: `0` (success), `1` (operational/network failure), `2` (invalid subcommand or missing parameter).
- **`app/health-check.sh`**:
  - Container health check verifying tool availability (`curl`, `ping`, `df`, `free`, `ip`) and filesystem read access.
- **`Dockerfile`**:
  - Lightweight Alpine Linux base image (`alpine:3.20`).
  - Installs minimal packages: `bash`, `curl`, `iputils`, `bind-tools`, `netcat-openbsd`, `util-linux`.
  - Sets executable permissions on `/app/*.sh`.
  - Configures `ENTRYPOINT ["/app/diagnostic.sh"]` to enable direct subcommand execution.
- **`.dockerignore`**:
  - Excludes `.git`, `tests/`, `*.log`, `.DS_Store`.
- **`compose.yaml`**:
  - Service `diagnostic` built from `.` with image tag `diagnostic-tool:latest`.
  - Supports `docker compose run --rm diagnostic system|disk|help|network <host>`.
- **`test.sh`**:
  - Automated smoke and regression test suite verifying `help`, `system`, `disk`, `network`, and invalid command handling inside container and locally.
- **`grade.sh`**:
  - Evaluates project structure, syntax, Dockerfile best practices, container execution, Docker Compose compatibility, test suite, and README.
  - Rubric check (100 pts total).
- **Git History**:
  - Feature branches (`feature/docker-compose`), at least 5 meaningful commits.

---

### 3. Assignment 3 — CI/CD Pipeline with GitHub Actions (`assignment-3`)

**Target Structure:**
```text
assignment-3/
├── README.md
├── app/
│   └── app.sh
├── scripts/
│   ├── lint.sh
│   └── build.sh
├── tests/
│   └── test.sh
├── .github/
│   └── workflows/
│       └── ci.yml
├── Dockerfile
├── compose.yaml
├── .dockerignore
└── grade.sh
```

- **`app/app.sh`**:
  - Subcommands: `system-info`, `check-host <host>`, `check-port <host> <port>`, `help`.
  - Exit code `2` on any invalid syntax or parameters.
- **`scripts/lint.sh`**:
  - Validates file presence, runs `bash -n` on all shell scripts, runs `shellcheck` if available.
- **`tests/test.sh`**:
  - Implements 8+ rigorous tests:
    1. `help` display and exit code `0`
    2. `system-info` output and exit code `0`
    3. Invalid command check -> exit code `2`
    4. Missing host check -> exit code `2`
    5. Valid host check (`127.0.0.1`) -> exit code `0`
    6. Missing port check -> exit code `2`
    7. Non-numeric port (`abc`) -> exit code `2`
    8. Out-of-range port (`70000`) -> exit code `2`
    9. Valid host and port (`127.0.0.1` port `53` or open service) -> exit code `0`
- **`scripts/build.sh`**:
  - Builds `devops-tool` image and executes container smoke tests (`help`, `system-info`, invalid command test).
- **`.github/workflows/ci.yml`**:
  - Triggers on `push` and `pull_request`.
  - 3 sequential jobs with strict dependencies:
    - `validate`: Runs `scripts/lint.sh`.
    - `test`: `needs: validate`, runs `tests/test.sh`.
    - `docker`: `needs: test`, runs `scripts/build.sh`.
- **CI Failure Demonstration**:
  - Creates branch `ci-failure-demo`, introduces an intentional test failure, commits and pushes to trigger a failed CI run on GitHub Actions.
  - Pushes the fix to resolve the run to green.
  - Documents the failure run and resolution in `README.md`.
- **`grade.sh`**:
  - Tests repository structure, syntax, workflow YAML syntax, job dependency declarations (`needs:`), application behaviour, Docker build/smoke tests, student tests, and Git history.
  - Rubric check (100 pts total).

---

## Verification Plan

### Automated Verification
1. **Local Test Execution in WSL**:
   - Run `./grade.sh` in `assignment-1` -> confirm **100/100**.
   - Run `docker compose run --rm diagnostic system` and `./grade.sh` in `assignment-2` -> confirm **100/100**.
   - Run `./tests/test.sh`, `./scripts/lint.sh`, `./scripts/build.sh`, and `./grade.sh` in `assignment-3` -> confirm **100/100**.
2. **GitHub Repository Creation & Push**:
   - Create 3 repositories on GitHub under `echeck246` using the authenticated GitHub API token.
   - Push all branches and tags.
3. **GitHub Actions Workflow Verification**:
   - Verify workflow runs on GitHub Actions for `assignment-3` to confirm the pipeline passes cleanly.

### Manual Verification
- Review generated `README.md` files for clarity, complete instructions, and screenshots/terminal output logs.
- Provide the final GitHub repository URLs ready to be pasted into the instructor's submission Google Form.
