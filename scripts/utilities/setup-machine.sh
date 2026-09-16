#!/usr/bin/env bash
#
# setup-machine.sh — prepare a machine for the Kubernetes learning labs.
#
# Author: Sagar Saitwal
#
# Run once per machine, from inside WSL / Linux, at the repository root:
#
#     bash scripts/utilities/setup-machine.sh
#
# What it does:
#   1. Verifies the environment can actually run a kind cluster
#   2. Installs kubectl and kind if they are missing (with checksum verification)
#   3. Prints this machine's environment facts for progress/environments.md
#
# It is safe to re-run. Nothing is installed twice.
#
# This repository is expected at the SAME path on every machine:
#     Windows      D:\Kubernetes
#     WSL / Linux  /mnt/d/Kubernetes
# Keeping that identical is what lets every command in this repository be
# copied verbatim between machines.

set -euo pipefail

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------
ok()   { printf '  [ OK ]  %s\n' "$*"; }
warn() { printf '  [WARN]  %s\n' "$*"; }
fail() { printf '  [FAIL]  %s\n' "$*"; }
head2() { printf '\n== %s ==\n' "$*"; }

FAILED=0

# ---------------------------------------------------------------------------
# Resolve the repository root from this script's own location, so the script
# works regardless of where the repository was cloned or which directory it is
# invoked from.
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
EXPECTED_ROOT="/mnt/d/Kubernetes"

head2 "Repository"
if [ -f "${REPO_ROOT}/CLAUDE.md" ] && [ -d "${REPO_ROOT}/progress" ]; then
  ok "repository root: ${REPO_ROOT}"
else
  fail "does not look like the kubernetes-labs repository: ${REPO_ROOT}"
  exit 1
fi

# The repository is expected at the same path on every machine, so that every
# command in the labs can be copied verbatim between them. This is a warning
# rather than an error — the repository still works elsewhere, but paths in the
# lab documents will not match.
if [ "${REPO_ROOT}" = "${EXPECTED_ROOT}" ]; then
  ok "path matches the convention (${EXPECTED_ROOT})"
else
  warn "repository is at ${REPO_ROOT}, not ${EXPECTED_ROOT}"
  warn "commands in the lab documents assume ${EXPECTED_ROOT} and will need adjusting"
fi

# ---------------------------------------------------------------------------
# 1. Environment prerequisites
# ---------------------------------------------------------------------------
head2 "Prerequisites"

KERNEL="$(uname -r)"
ok "kernel: ${KERNEL}"

ARCH="$(uname -m)"
if [ "${ARCH}" = "x86_64" ]; then
  ok "architecture: ${ARCH}"
else
  warn "architecture: ${ARCH} — download URLs below assume amd64"
fi

# cgroup v2 is the single most important check for kind on WSL2. kind runs each
# Kubernetes node as a container, and the kubelet inside it needs a writable
# cgroup hierarchy to enforce Pod resource limits. cgroup v1 / a read-only
# hybrid mount breaks node startup in ways that look unrelated.
CGROUP="$(stat -fc %T /sys/fs/cgroup)"
if [ "${CGROUP}" = "cgroup2fs" ]; then
  ok "cgroup: ${CGROUP} (v2 unified)"
else
  fail "cgroup: ${CGROUP} — kind needs cgroup2fs. Node startup will fail."
  FAILED=1
fi

if docker info >/dev/null 2>&1; then
  ok "docker: $(docker version --format '{{.Server.Version}}') — reachable without sudo"
else
  fail "docker daemon not reachable. Try: sudo systemctl start docker"
  FAILED=1
fi

CPUS="$(nproc)"
MEM_AVAIL="$(free -g | awk '/Mem:/ {print $7}')"
MEM_TOTAL="$(free -g | awk '/Mem:/ {print $2}')"
ok "cpu: ${CPUS} cores"
if [ "${MEM_AVAIL}" -ge 2 ]; then
  ok "memory: ${MEM_AVAIL} GiB available of ${MEM_TOTAL} GiB"
else
  warn "memory: only ${MEM_AVAIL} GiB available — a 3-node cluster needs ~1.2 GiB"
fi

DISK_AVAIL="$(df -h / | awk 'NR==2 {print $4}')"
ok "disk: ${DISK_AVAIL} free on /"

# ---------------------------------------------------------------------------
# 2. Tooling
# ---------------------------------------------------------------------------
head2 "Tooling"

install_kubectl() {
  local ver tmp
  ver="$(curl -Ls https://dl.k8s.io/release/stable.txt)"
  tmp="$(mktemp -d)"
  printf '  installing kubectl %s\n' "${ver}"
  curl -sLo "${tmp}/kubectl"        "https://dl.k8s.io/release/${ver}/bin/linux/amd64/kubectl"
  curl -sLo "${tmp}/kubectl.sha256" "https://dl.k8s.io/release/${ver}/bin/linux/amd64/kubectl.sha256"

  # Verify integrity before running anything as root. This catches corrupt
  # downloads and tampered mirrors. It does NOT prove authenticity — both the
  # binary and the hash came from the same host.
  if ! (cd "${tmp}" && echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check --quiet); then
    fail "kubectl checksum mismatch — refusing to install"
    rm -rf "${tmp}"
    return 1
  fi

  sudo install -o root -g root -m 0755 "${tmp}/kubectl" /usr/local/bin/kubectl
  rm -rf "${tmp}"
}

install_kind() {
  local ver tmp
  ver="$(curl -Ls https://api.github.com/repos/kubernetes-sigs/kind/releases/latest \
         | grep -oP '"tag_name": "\K[^"]+')"
  tmp="$(mktemp -d)"
  printf '  installing kind %s\n' "${ver}"
  curl -sLo "${tmp}/kind" "https://kind.sigs.k8s.io/dl/${ver}/kind-linux-amd64"
  chmod +x "${tmp}/kind"
  sudo install -o root -g root -m 0755 "${tmp}/kind" /usr/local/bin/kind
  rm -rf "${tmp}"
}

if command -v kubectl >/dev/null 2>&1; then
  ok "kubectl: $(kubectl version --client -o json 2>/dev/null | grep -oP '"gitVersion": "\K[^"]+' | head -1)"
else
  install_kubectl && ok "kubectl installed: $(kubectl version --client 2>/dev/null | head -1)"
fi

if command -v kind >/dev/null 2>&1; then
  ok "kind: $(kind version | awk '{print $2}')"
else
  install_kind && ok "kind installed: $(kind version | awk '{print $2}')"
fi

# ---------------------------------------------------------------------------
# 3. Existing clusters
# ---------------------------------------------------------------------------
head2 "Clusters on this machine"

if command -v kind >/dev/null 2>&1; then
  EXISTING="$(kind get clusters 2>/dev/null || true)"
  if [ -n "${EXISTING}" ]; then
    printf '  existing kind clusters:\n'
    printf '%s\n' "${EXISTING}" | sed 's/^/    - /'
  else
    ok "no kind clusters yet"
  fi
fi

# ---------------------------------------------------------------------------
# 4. Environment facts for progress/environments.md
# ---------------------------------------------------------------------------
head2 "Record these in progress/environments.md"

cat <<EOF

| Item | Value |
|---|---|
| Hostname | $(hostname) |
| Linux | $(grep -oP '^PRETTY_NAME="\K[^"]+' /etc/os-release 2>/dev/null || echo unknown) |
| Kernel | ${KERNEL} |
| Architecture | ${ARCH} |
| cgroup | ${CGROUP} |
| Docker | $(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "not reachable") |
| CPU | ${CPUS} |
| Memory | ${MEM_TOTAL} GiB total |
| Disk free | ${DISK_AVAIL} |
| kubectl | $(kubectl version --client 2>/dev/null | grep -oP 'Client Version: \K.*' || echo "not installed") |
| kind | $(kind version 2>/dev/null | awk '{print $2}' || echo "not installed") |
| Repository path | ${REPO_ROOT} |

EOF

# ---------------------------------------------------------------------------
head2 "Result"
if [ "${FAILED}" -eq 0 ]; then
  ok "machine is ready"
  printf '\nNext:\n'
  printf '  cd %s/fundamentals/labs\n' "${REPO_ROOT}"
  printf '  kind create cluster --name k8s-lab --config kind-cluster-config.yaml\n\n'
else
  fail "fix the failures above before creating a cluster"
  exit 1
fi
