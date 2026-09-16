# Next Steps

Author: Sagar Saitwal

Last updated: 2026-09-16

---

## Immediate next action

Session continues on the **same machine (`Nero`)** unless stated otherwise —
check `SystemInfo.md` at the repository root to confirm before assuming. Start
with the resume ritual:

```bash
cd /mnt/d/Kubernetes && git pull
cat progress/current-progress.md
bash scripts/utilities/check-dependencies.sh
```

If the cluster is reported missing (expected on a different machine — clusters
never travel):

```bash
cd /mnt/d/Kubernetes/fundamentals/labs
kind create cluster --name k8s-lab --config kind-cluster-config.yaml
```

Day 01's LAB 01 challenge is now **done** — see
`journal/daily/day-01-cluster-setup.md`. Two smaller items carry over into
finishing Day 02:

### Carried over from Day 01 into Day 02

| # | Item | Command |
|:--:|---|---|
| 1 | See static Pod manifests on disk — the files the kubelet starts without an API server | `docker exec -it k8s-lab-control-plane ls -l /etc/kubernetes/manifests/` |
| 2 | Check whether both CoreDNS replicas landed on the same node | `kubectl get pods -n kube-system -o wide \| grep coredns` |

Then continue Day 02 with the remaining control-plane components (`etcd`,
`kube-scheduler`, `kube-controller-manager`) on the live cluster — the
node-failure/recovery half of Day 02 (heartbeats, Lease objects, the Node
Lifecycle Controller, taints) is already done; see
`journal/daily/day-02-control-plane-and-nodes.md`.

---

## Session queue

Full plan: `progress/daily-plan.md` (Day 00 - Day 130)

| Day | Item | Journal file | Blocked by |
|:--:|---|---|---|
| 01 | LAB 01 — cluster created, verified, challenge complete | `day-01-cluster-setup.md` | — |
| 02 | Control plane vs worker node — heartbeat/taint mechanism done; manifests + CoreDNS check + remaining components outstanding | `day-02-control-plane-and-nodes.md` | — |
| 03 | Architecture and the request flow | `day-03-architecture-request-flow.md` | Day 02 |
| 04 | kubectl core verbs and output formats | `day-04-kubectl-core.md` | Day 03 |
| 05 | Namespaces, labels, selectors, annotations | `day-05-namespaces-labels-selectors.md` | Day 04 |
| 06 | Pod anatomy, YAML, lifecycle, phases | `day-06-pod-basics.md` | Day 05 |

---

## Decisions made

### 1. Cluster topology — DECIDED, and now built

**1 control-plane + 2 workers**, declared in
`fundamentals/labs/kind-cluster-config.yaml`.

A single-node cluster cannot demonstrate scheduling across nodes, pod
anti-affinity, topology spread, DaemonSet behaviour, or — most importantly —
node failure and rescheduling. Cost is ~1.2 GiB of 7.0 GiB available.

Reversible. **Revisit after Module 11**, when there is enough scheduling
knowledge to evaluate the reasoning independently.

---

## Deliberately deferred

| Item | Revisit at |
|---|---|
| Building a cluster by hand with `kubeadm` | Module 22 — Production Kubernetes |
| Cloud clusters (EKS / AKS) | Modules 23-24, after local fundamentals are solid |
| Service mesh, eBPF, Gateway API | Module 27 |
| Docker phase open items | Out of scope here; tracked in `docker-labs` |

---

## Environment facts to re-verify on a new device

This repository is meant to be portable. On a new machine, confirm these before
resuming, because several later labs depend on them:

```bash
uname -r                      # WSL2 kernel version
stat -fc %T /sys/fs/cgroup    # must be cgroup2fs for kind to work cleanly
docker version                # Engine must be reachable without sudo
nproc && free -h              # cluster size is limited by these
kubectl get nodes             # does a cluster already exist here?
kind get clusters             # which kind clusters exist on this machine?
```

Recorded values from the original environment (2026-09-16):

| Fact | Value |
|---|---|
| Host | Windows 11 Pro |
| Linux | WSL2, FedoraLinux-44 |
| Kernel | 6.18.33.2-microsoft-standard-WSL2 |
| Architecture | x86_64 |
| cgroup | cgroup2fs (v2 unified) |
| systemd | active |
| Docker | Engine 29.7.2, installed inside Fedora, not Docker Desktop |
| CPU | 8 |
| Memory | 7.6 GiB total |
| Disk free | 952 GiB |
