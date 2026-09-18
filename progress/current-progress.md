# Current Kubernetes Learning Progress

Author: Sagar Saitwal

Last updated: 2026-09-18

> This file is the single source of truth for where the learning stopped.
> On any new session or new device, read this file FIRST.

**Current Day: 03**

> The line above is machine-readable. `scripts/utilities/check-dependencies.sh`
> parses it to decide which dependencies this day actually requires. Keep the
> exact format `Current Day: NN` when updating it.

---

## Machine this session ran on

**IT-SAGARS** — see `SystemInfo.md` (repository root) for full per-machine tool
versions and the cross-machine dependency table. If the next session is on a
different machine, `kubectl`/`kind`/the cluster will legitimately be missing —
expected, not a failure. Recreate:

```bash
cd /mnt/d/Kubernetes && git pull
bash scripts/utilities/check-dependencies.sh

cd /mnt/d/Kubernetes/fundamentals/labs
kind create cluster --name k8s-lab --config kind-cluster-config.yaml
```

---

## Current Module

Module 01 — Kubernetes Fundamentals

## Current Topic

Day 02 COMPLETED. Next: Day 03 — Architecture and the request flow.

## Current Subtopic

Day 03 has not started. First action: trace `kubectl apply -f deployment.yaml`
through all 14 steps against the live cluster, confirming each step rather
than taking Lesson 01's theory-only version on trust.

## Learning Status

🟡 IN PROGRESS

Day 00, Day 01, and Day 02 are all fully COMPLETED. Day 03 is next.

## Last Completed Lab

**Day 02 — static Pod manifest inspection and CoreDNS placement check.**
COMPLETED. `etcd.yaml`, `kube-apiserver.yaml`, and `kube-scheduler.yaml` all
read in full on the live cluster; CoreDNS placement checked and a real
single-point-of-failure finding confirmed with corroborating evidence.

## Last Commands Practiced

```bash
docker exec -it k8s-lab-control-plane ls -l /etc/kubernetes/manifests/
docker exec -it k8s-lab-control-plane cat /etc/kubernetes/manifests/kube-apiserver.yaml
docker exec -it k8s-lab-control-plane cat /etc/kubernetes/manifests/etcd.yaml
docker exec -it k8s-lab-control-plane cat /etc/kubernetes/manifests/kube-scheduler.yaml
kubectl get pods -n kube-system -o wide | grep coredns
```

## Last YAML Practiced

None hand-written yet — read three existing static Pod manifests
(`kube-apiserver.yaml`, `etcd.yaml`, `kube-scheduler.yaml`) rather than
authoring new YAML. First hand-written YAML is Day 06 (Pod basics).

## What I Learned

- **Static Pod manifests exist exactly where theory said**, timestamped
  identically at cluster bootstrap, root-only permissions, and missing the two
  files (`kube-proxy`, `kindnet`) that theory said would be missing because
  they're DaemonSets, not static Pods.
- **Stateless vs stateful has a concrete, checkable test:** `--data-dir` plus a
  real data volume mount means stateful (`etcd`, the only one on this
  cluster); a kubeconfig/cert-only volume means stateless (`kube-apiserver`,
  `kube-scheduler`, `kube-controller-manager`).
- **Two different HA mechanisms live in one control plane:** `etcd` uses Raft
  consensus (all members vote on every write); `kube-scheduler` and
  `kube-controller-manager` use `--leader-elect=true` (one active leader,
  the rest idle standbys). Different because one is stateful and one isn't.
- **`kube-apiserver` and `etcd` trust nothing by default, not even
  localhost** — `--client-cert-auth=true` on etcd's side, matching client
  certificate flags on the apiserver's side. Verified by reading both files
  and matching the flags.
- **CoreDNS has a real, verified single point of failure on this cluster** —
  both replicas on the control-plane node, confirmed by the `NODE` column and
  corroborated by identical, simultaneous restart counts. Root cause: CoreDNS
  is created before workers finish joining, and Kubernetes never re-schedules
  an already-running Pod just because a better node appears later.
- **A concrete test, once established, should be applied mechanically** — not
  re-guessed from impression. This is exactly what went wrong with
  `kube-scheduler.yaml` (see What I Broke).

## What I Broke

Nothing in the cluster. Got a classification wrong (see Mistakes Made) —
recorded, not hidden.

## Errors Encountered

None — inspection only, no mutating commands run against the live objects.

## Root Cause

N/A for this session (see Mistakes Made for the one wrong answer's root
cause).

## How It Was Fixed

N/A

## Mistakes Made

- Classified `kube-scheduler.yaml` as "stateful" on first attempt, immediately
  after correctly classifying `kube-apiserver` (stateless) and `etcd`
  (stateful) using the same file. Root cause: hadn't yet turned the
  distinction into a mechanical test (`--data-dir` + data volume, present or
  absent) — answered from impression instead of checking the file's own
  volume mounts. Full detail: `journal/mistakes-and-lessons.md`, Mistake 002.

## Important Lessons

- A concrete, checkable test beats a general impression every time — "does
  this sound important" is not a substitute for "does this file have a
  `--data-dir` flag."
- Corroborating evidence often sits in output already on screen for another
  reason — the CoreDNS restart counts weren't specifically searched for, but
  confirmed the finding more strongly than the placement column alone.
- Kubernetes' scheduler places a Pod once, at creation, and never
  re-evaluates already-running Pods — a cluster's layout can go stale purely
  from *when* something happened to be created relative to which nodes
  existed yet.

## Unresolved Issues

None blocking. One forward-looking item, not urgent:

1. CoreDNS anti-affinity fix (`required` affinity or topology spread
   constraints) is a real, verified gap on this cluster. Deliberately
   deferred to Day 34/36 — not a Day 02/03 task.

## Next Topic

Day 03 — Architecture and the request flow: `kubectl` → API server → etcd →
controller → scheduler → kubelet → container runtime, confirmed live rather
than taken on theory alone from Lesson 01.

## Next Lab

LAB 03 — trace a real `kubectl apply` through the cluster and match each of
the 14 steps from Lesson 01 to something observable (API server logs, etcd
writes via `etcdctl` where possible, scheduler decisions, kubelet actions).

File not yet written: `journal/daily/day-03-architecture-request-flow.md`

## Overall Progress

Day 02 of 130 COMPLETE. Day 03 starting next session. 0 of 30 modules
completed, 1 in progress. 0 of 10 projects.

```text
[■                             ] 2%
```

Full day-by-day plan: `progress/daily-plan.md`
