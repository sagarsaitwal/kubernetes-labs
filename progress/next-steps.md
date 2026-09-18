# Next Steps

Author: Sagar Saitwal

Last updated: 2026-09-18

---

## Immediate next action

Session continues on **whichever machine you resume on** — check `SystemInfo.md`
at the repository root to confirm which one before assuming. Start with the
resume ritual:

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

**Day 03 is now fully COMPLETE** — see
`journal/daily/day-03-architecture-request-flow.md`. Nothing carries over
except the deliberately deferred items below.

### Day 04 — first concrete action

**Queued, not started.** Teaching content was already given in the previous
session (verb families table, `kubectl explain`, output formats, `kubectl
diff`/`--dry-run=server`, `logs`/`exec`) but no commands were run — resume
directly with the six-command list in `progress/current-progress.md` rather
than re-deriving the plan. No lesson file was written for this — same
pattern as Days 02-03, built live and journaled afterward once actually run.

---

## Session queue

Full plan: `progress/daily-plan.md` (Day 00 - Day 130)

| Day | Item | Journal file | Blocked by |
|:--:|---|---|---|
| 01 | LAB 01 — cluster created, verified, challenge complete | `day-01-cluster-setup.md` | — |
| 02 | Control plane vs worker node — COMPLETE (heartbeat/taint mechanism, static manifests, stateless/stateful test, CoreDNS placement) | `day-02-control-plane-and-nodes.md` | — |
| 03 | Architecture and the request flow — COMPLETE (steps 6-14 + partial step 4 traced live; CoreDNS taint question closed) | `day-03-architecture-request-flow.md` | — |
| 04 | kubectl core verbs and output formats | `day-04-kubectl-core.md` | — |
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

## Findings awaiting a scheduled fix

Not blocking — recorded here so they are not silently forgotten before their
scheduled day arrives.

| Finding | Verified on | Fix scheduled |
|---|---|---|
| Both CoreDNS replicas landed on `k8s-lab-control-plane` — a real, verified single point of failure, corroborated by identical simultaneous restart counts; Day 03 confirmed *why it was even eligible* (explicit toleration for the control-plane taint) | Day 02-03, both machines' clusters | Day 34 (`required` pod anti-affinity) / Day 36 (topology spread constraints) |
| Steps 1-3 and 5 of the request-flow theory (auth, authz, etcd write) not yet directly observed | Day 03 | Day 39-41 (RBAC), Day 45 (a real denial), Day 65/80 (`etcdctl`) |
| Why only some static Pods (`etcd`, `kube-apiserver`) got a fresh `Age` after a node reboot, while others apparently didn't | Day 03, `Nero` | Day 68 (kubelet/CRI internals) |

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

Per-machine values are tracked in `SystemInfo.md` (quick lookup) and
`progress/environments.md` (full detail and reasoning).
