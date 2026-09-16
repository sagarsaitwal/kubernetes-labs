#!/usr/bin/env bash
#
# check-dependencies.sh — verify this machine can continue the learning journey.
#
# Author: Sagar Saitwal
#
# Run after switching machines, or after any long gap:
#
#     bash /mnt/d/Kubernetes/scripts/utilities/check-dependencies.sh
#     bash .../check-dependencies.sh 55      # check as if on Day 55
#
# It reads the current day from progress/current-progress.md and reports only
# what that day actually requires — host tools, cluster state, and in-cluster
# components. Anything not yet needed is listed as "not needed yet" rather than
# as a failure.
#
# Full reference: progress/dependencies.md

set -uo pipefail

ok()      { printf '  \033[32m[ OK ]\033[0m  %s\n' "$*"; }
missing() { printf '  \033[31m[MISS]\033[0m  %s\n' "$*"; MISSING=$((MISSING+1)); }
skip()    { printf '  \033[90m[ -- ]\033[0m  %s\n' "$*"; }
warn()    { printf '  \033[33m[WARN]\033[0m  %s\n' "$*"; }
head2()   { printf '\n\033[1m== %s ==\033[0m\n' "$*"; }

MISSING=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PROGRESS="${REPO_ROOT}/progress/current-progress.md"

# ---------------------------------------------------------------------------
# Which day are we on?
# ---------------------------------------------------------------------------
if [ $# -ge 1 ]; then
  DAY="$1"
elif [ -f "${PROGRESS}" ]; then
  # Look for a line like:  Current Day: 01
  DAY="$(grep -oP '^\s*\*{0,2}Current Day\*{0,2}\s*:\s*\K[0-9]+' "${PROGRESS}" | head -1)"
fi
DAY="${DAY:-1}"
DAY=$((10#${DAY}))   # strip any leading zero so arithmetic works

printf '\n\033[1mDependency check — Day %02d\033[0m\n' "${DAY}"
printf 'Repository: %s\n' "${REPO_ROOT}"

# needed_from <day-first-required> -> 0 if that dependency applies now
needed_from() { [ "${DAY}" -ge "$1" ]; }

# ---------------------------------------------------------------------------
head2 "Baseline environment"

CGROUP="$(stat -fc %T /sys/fs/cgroup 2>/dev/null || echo unknown)"
if [ "${CGROUP}" = "cgroup2fs" ]; then
  ok "cgroup v2 unified"
else
  missing "cgroup is ${CGROUP}, kind needs cgroup2fs"
fi

if docker info >/dev/null 2>&1; then
  ok "docker reachable — $(docker version --format '{{.Server.Version}}' 2>/dev/null)"
else
  missing "docker daemon unreachable — try: sudo systemctl start docker"
fi

MEM_AVAIL="$(free -g 2>/dev/null | awk '/Mem:/ {print $7}')"
if [ -n "${MEM_AVAIL}" ] && [ "${MEM_AVAIL}" -ge 2 ]; then
  ok "memory: ${MEM_AVAIL} GiB available"
else
  warn "memory: only ${MEM_AVAIL:-?} GiB available — a 3-node cluster needs ~1.2 GiB"
fi

# ---------------------------------------------------------------------------
head2 "Host tools"

# check_tool <first-needed-day> <binary> <version-command> <install-hint>
check_tool() {
  local from="$1" bin="$2" vercmd="$3" hint="$4"
  if ! needed_from "${from}"; then
    skip "${bin} — not needed until Day ${from}"
    return
  fi
  if command -v "${bin}" >/dev/null 2>&1; then
    ok "${bin} — $(eval "${vercmd}" 2>/dev/null | head -1)"
  else
    missing "${bin} — needed from Day ${from}. ${hint}"
  fi
}

check_tool  1 kubectl "kubectl version --client 2>/dev/null | head -1"  "run setup-machine.sh"
check_tool  1 kind    "kind version"                                    "run setup-machine.sh"
check_tool 49 helm    "helm version --short"                            "see progress/dependencies.md"
check_tool 55 jq      "jq --version"                                    "sudo dnf install -y jq"
check_tool 80 etcdctl "etcdctl version | head -1"                       "sudo dnf install -y etcd"
check_tool 83 aws     "aws --version"                                   "see Day 83"
check_tool 83 eksctl  "eksctl version"                                  "see Day 83"
check_tool 89 az      "az version --output tsv 2>/dev/null | head -1"   "see Day 89"
check_tool 99 argocd  "argocd version --client --short 2>/dev/null"     "see Day 99"

# ---------------------------------------------------------------------------
head2 "Cluster"

CLUSTER_UP=0
if ! command -v kind >/dev/null 2>&1; then
  missing "cannot check cluster — kind is not installed"
elif kind get clusters 2>/dev/null | grep -qx "k8s-lab"; then
  ok "kind cluster 'k8s-lab' exists"

  if kubectl cluster-info --context kind-k8s-lab >/dev/null 2>&1; then
    NOT_READY="$(kubectl get nodes --no-headers 2>/dev/null | grep -vc ' Ready ' || true)"
    TOTAL="$(kubectl get nodes --no-headers 2>/dev/null | wc -l)"
    if [ "${NOT_READY}" -eq 0 ] && [ "${TOTAL}" -gt 0 ]; then
      ok "all ${TOTAL} nodes Ready"
    else
      missing "${NOT_READY} of ${TOTAL} nodes not Ready — kubectl describe node <name>"
    fi

    CVER="$(kubectl version -o json 2>/dev/null | grep -oP '"gitVersion":\s*"\K[^"]+' | tail -1)"
    KVER="$(kubectl version --client -o json 2>/dev/null | grep -oP '"gitVersion":\s*"\K[^"]+' | head -1)"
    [ -n "${CVER}" ] && ok "server ${CVER} / client ${KVER}"
    CLUSTER_UP=1
  else
    missing "cluster exists but API server is unreachable — is docker running?"
  fi
else
  missing "kind cluster 'k8s-lab' does not exist on this machine"
  printf '           Clusters are local and do not travel between machines. Create it:\n'
  printf '             cd %s/fundamentals/labs\n' "${REPO_ROOT}"
  printf '             kind create cluster --name k8s-lab --config kind-cluster-config.yaml\n'
fi

# ---------------------------------------------------------------------------
head2 "In-cluster components"

printf '  These live in the cluster etcd, not on the machine.\n'
printf '  They are lost on every "kind delete cluster" and must be reinstalled.\n\n'

# check_incluster <first-needed-day> <namespace> <label> <description>
check_incluster() {
  local from="$1" ns="$2" desc="$3"
  if ! needed_from "${from}"; then
    skip "${desc} — not installed until Day ${from}"
    return
  fi
  if [ "${CLUSTER_UP}" -ne 1 ]; then
    missing "${desc} — cannot check, no reachable cluster"
    return
  fi
  local running
  running="$(kubectl get pods -n "${ns}" --no-headers 2>/dev/null | grep -c 'Running' || true)"
  if [ "${running}" -gt 0 ]; then
    ok "${desc} — ${running} pod(s) Running in ${ns}"
  else
    missing "${desc} — nothing Running in namespace '${ns}'. Reinstall: see Day ${from}"
  fi
}

check_incluster 46 ingress-nginx "NGINX Ingress Controller"
check_incluster 54 kube-system   "metrics-server (kube-system)"
check_incluster 55 monitoring    "Prometheus / Grafana stack"
check_incluster 58 logging       "Log collection"
check_incluster 99 argocd        "Argo CD"
check_incluster 104 istio-system "Istio"
check_incluster 106 kyverno      "Kyverno"

# ---------------------------------------------------------------------------
head2 "Result"

if [ "${MISSING}" -eq 0 ]; then
  printf '  \033[32mReady to continue from Day %02d.\033[0m\n\n' "${DAY}"
  exit 0
else
  printf '  \033[31m%d dependency issue(s) to resolve before continuing.\033[0m\n' "${MISSING}"
  printf '  Full reference: %s/progress/dependencies.md\n\n' "${REPO_ROOT}"
  exit 1
fi
