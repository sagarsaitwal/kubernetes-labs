# Next Steps

Author: Sagar Saitwal

Last updated: 2026-09-16

---

## Immediate next action

**LAB 01 — Set up the Kubernetes learning environment.**

File: `fundamentals/labs/lab-01-lab-environment-setup.md`

Nothing else proceeds until a cluster exists and `kubectl get nodes` reports
`Ready`.

### Why this is first

Every remaining module is hands-on. Without a working cluster there is nothing
to apply YAML to, nothing to break, and nothing to troubleshoot.

---

## Session queue

Full plan: `progress/daily-plan.md` (Day 00 - Day 130)

| Day | Item | Journal file | Blocked by |
|:--:|---|---|---|
| 01 | LAB 01 — install kubectl + kind, create the 3-node cluster, verify | `day-01-cluster-setup.md` | Nothing |
| 02 | Control plane vs worker node, inspected on the real cluster | `day-02-control-plane-and-nodes.md` | Day 01 |
| 03 | Architecture and the request flow | `day-03-architecture-request-flow.md` | Day 02 |
| 04 | kubectl core verbs and output formats | `day-04-kubectl-core.md` | Day 03 |
| 05 | Namespaces, labels, selectors, annotations | `day-05-namespaces-labels-selectors.md` | Day 04 |
| 06 | Pod anatomy, YAML, lifecycle, phases | `day-06-pod-basics.md` | Day 05 |

---

## Decisions made

### 1. Cluster topology — DECIDED

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
