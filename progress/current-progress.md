# Current Kubernetes Learning Progress

Author: Sagar Saitwal

Last updated: 2026-09-16

> This file is the single source of truth for where the learning stopped.
> On any new session or new device, read this file FIRST.

**Current Day: 02**

> The line above is machine-readable. `scripts/utilities/check-dependencies.sh`
> parses it to decide which dependencies this day actually requires. Keep the
> exact format `Current Day: NN` when updating it.

---

## Machine this session ran on

**Nero** — see `SystemInfo.md` (repository root) for full per-machine tool
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

Day 01 COMPLETED. Day 02 — Control Plane vs Worker Node — IN PROGRESS.

## Current Subtopic

Node health detection (heartbeats, Lease objects, Node Lifecycle Controller,
taints) — taught and verified live. Still to do: static Pod manifests on disk,
CoreDNS placement re-check, remaining control-plane components.

## Learning Status

🟡 IN PROGRESS

Day 00 and Day 01 are fully COMPLETED, including the LAB 01 challenge. Day 02
has started — the node-failure/recovery mechanism (its actual subject matter)
was taught and directly observed via that challenge. Two verification items
and the rest of Day 02 remain.

## Last Completed Lab

**LAB 01 — Set up the Kubernetes learning environment.** COMPLETED.

Cluster created, fully verified, and the break/fix challenge (stop a worker
node, predict, observe, recover) completed with real timed output.

## Last Commands Practiced

```bash
kubectl get nodes -w                        # stream node status changes live
date; docker stop k8s-lab-worker2           # simulate node failure, timestamped
kubectl describe node k8s-lab-worker2       # taints, conditions, Lease, Events
docker start k8s-lab-worker2                # restore the node
```

## Last YAML Practiced

None new today — used the existing `fundamentals/labs/kind-cluster-config.yaml`
cluster from Day 01.

## What I Learned

- **The worker reports in; the control plane never polls it.** Each kubelet
  renews a small `Lease` object roughly every 10s. The Node Lifecycle
  Controller (inside `kube-controller-manager`) watches these leases, not the
  node directly.
- **`node-monitor-grace-period` (default 40s)** is how long a missed heartbeat
  is tolerated before a node flips to `NotReady`. Measured directly: 44s from
  `docker stop` to the `Ready` condition's `LastTransitionTime`.
- **A taint doesn't decide a Pod's fate — its owning controller does.**
  `NoExecute` on an unreachable node gives ordinary Pods 300s
  (`tolerationSeconds`) before eviction and rescheduling by their
  ReplicaSet/Deployment. DaemonSet Pods get an automatic, **indefinite**
  toleration for the same taint — they are never evicted by it, because a
  DaemonSet's contract ("one per node") has no "elsewhere" to reschedule to.
- **`kubectl get nodes -w` fires on every watch event, not every visible
  change.** Multiple identical-looking lines can mean multiple underlying
  writes (e.g. several conditions flipping in sequence).
- **Event history beats terminal scrollback.** A `(x2 over 26m)` count on a
  `NodeNotReady` event proved an earlier, seemingly-aborted experiment had
  actually triggered a real transition nobody saw live.

## What I Broke

Deliberately: `k8s-lab-worker2` stopped via `docker stop` to observe node
failure detection (the LAB 01 challenge). Restored via `docker start`.

## Errors Encountered

None — this was a deliberate, successful experiment, not a failure to
diagnose.

## Root Cause

N/A

## How It Was Fixed

N/A

## Mistakes Made

- First challenge attempt: interrupted the watch and restarted the node
  **before** the 40s grace period elapsed, then read stale cached Pod status
  as if it were live confirmation. Nothing had actually been tested yet.
  Lesson: before concluding "nothing happened," confirm enough time actually
  passed for something to happen.

## Important Lessons

- A Pod's last-reported status is frozen at whatever the kubelet said last
  once its node stops reporting — it is not re-verified by anyone until the
  node comes back.
- `kubectl describe <object>`'s `Events` section is the reliable record of
  what happened; a live `-w` session only shows you events while you're
  actually connected and watching.

## Unresolved Issues

1. Verify static Pod manifests directly on disk:
   ```bash
   docker exec -it k8s-lab-control-plane ls -l /etc/kubernetes/manifests/
   ```
2. Confirm CoreDNS replica placement by hand:
   ```bash
   kubectl get pods -n kube-system -o wide | grep coredns
   ```
3. Continue Day 02 — inspect `etcd`, `kube-scheduler`, `kube-controller-manager`
   on the live cluster.

## Next Topic

Finish Day 02 — Control Plane vs Worker Node.

## Next Lab

Continue `journal/daily/day-02-control-plane-and-nodes.md` — start with the two
unresolved verification commands above, then the remaining control-plane
components.

## Overall Progress

Day 01 of 130 COMPLETE. Day 02 IN PROGRESS. 0 of 30 modules completed, 1 in
progress. 0 of 10 projects.

```text
[                              ] 2%
```

Full day-by-day plan: `progress/daily-plan.md`
