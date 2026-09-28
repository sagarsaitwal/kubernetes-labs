# Current Kubernetes Learning Progress

Author: Sagar Saitwal

Last updated: 2026-09-28

> This file is the single source of truth for where the learning stopped.
> On any new session or new device, read this file FIRST.

**Current Day: 09**

> The line above is machine-readable. `scripts/utilities/check-dependencies.sh`
> parses it to decide which dependencies this day actually requires. Keep the
> exact format `Current Day: NN` when updating it.

---

## Machine this session ran on

**IT-SAGARS** — see `SystemInfo.md` (repository root) for full per-machine
tool versions and the cross-machine dependency table. If the next session is
on a different machine, `kubectl`/`kind`/the cluster will legitimately be
missing — expected, not a failure. Recreate:

```bash
cd /mnt/d/Kubernetes && git pull
bash scripts/utilities/check-dependencies.sh

cd /mnt/d/Kubernetes/fundamentals/labs
kind create cluster --name k8s-lab --config kind-cluster-config.yaml
```

---

## Current Module

Module 02 — Workloads

## Current Topic

Day 08 COMPLETED. Day 09 — ReplicaSets and why you rarely write one — **not
yet started.** No teaching content prepared yet.

## Current Subtopic

Day 09 has not started.

## Learning Status

🟡 IN PROGRESS

Day 00 through Day 08 are all fully COMPLETED. Day 09 is next.

## Last Completed Lab

**Day 08 — Pod failures: `Pending`, `CrashLoopBackOff`, `ImagePullBackOff`
(break/fix).** COMPLETED. Deliberately engineered both `Pending` (an
impossible `100Gi` memory request) and `CrashLoopBackOff` (a container that
always `exit 1`s), predicted the mechanism in advance, and confirmed it
against real output. `ImagePullBackOff` deliberately not re-triggered —
already thoroughly proven on Day 04 and Day 07. Two findings richer than
predicted: `pending-demo` failed scheduling for **two independent reasons**
across 3 nodes (control-plane taint + insufficient memory on both
workers), and `kubectl logs --previous` failed with "unable to retrieve
container logs" after 4 restarts — the runtime doesn't retain unlimited
crash history. Also got a real, live recurrence of Day 06's Pod-phase vs.
container-state distinction: `describe` showed `Status: Running` at the top
while the container itself said `State: Waiting, Reason: CrashLoopBackOff`.

## Last Commands Practiced

```bash
kubectl apply -f pending-demo.yaml
kubectl get pod pending-demo
kubectl describe pod pending-demo
kubectl delete pod pending-demo
kubectl apply -f crash-demo.yaml
kubectl get pod crash-demo -w
kubectl describe pod crash-demo
kubectl logs crash-demo
kubectl logs crash-demo --previous
kubectl delete pod crash-demo
```

## Last YAML Practiced

`fundamentals/labs/pending-demo.yaml` (impossible `resources.requests`) and
`fundamentals/labs/crash-demo.yaml` (guaranteed-crash command) — third and
fourth hand-written manifests of the course.

## What I Learned

- `resources.requests` is what the scheduler filters nodes against, before
  scoring — an impossible request guarantees a clean, reproducible
  `Pending`.
- The scheduler reports every node's specific failure reason independently
  — a Pod can fail scheduling for more than one reason at once, across
  different nodes.
- `QoS Class` (`BestEffort`/`Burstable`/`Guaranteed`) is a direct,
  mechanical consequence of which `resources` fields are set.
- `spec.restartPolicy: Always` (the unstated default on every Pod so far)
  restarts a container after *any* exit, success or failure — the literal
  mechanism that turns one crash into a loop.
- Restart backoff is exponential, same mechanism as image-pull backoff,
  just triggered by a crashing container instead — confirmed directly via
  growing restart-gap timestamps (`12s`→`30s`→`50s`).
- Pod-level phase and container-level state can look contradictory for
  real — `Status: Running` at the top, `State: Waiting,
  Reason: CrashLoopBackOff` in the container block below it.
- `kubectl logs --previous` only works if the runtime still retains the
  prior terminated instance's log — not guaranteed, especially after
  several more restarts.

## What I Broke

Nothing — both `Pending` and `CrashLoopBackOff` were deliberately
engineered for this exercise, not accidental breaks.

## Errors Encountered

```text
0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 Insufficient memory.
unable to retrieve container logs for containerd://...
```

## Root Cause

`pending-demo`: unschedulable resource request + pre-existing control-plane
taint. `crash-demo`: a container that always exits non-zero, restarted
forever by the Pod's default `restartPolicy: Always`. `--previous` error:
containerd's log retention limit, not a bug.

## How It Was Fixed

Both were deliberate demonstrations, not incidents — cleaned up via
`kubectl delete pod` once each exercise's evidence was captured.

## Mistakes Made

None — no `journal/mistakes-and-lessons.md` entry. Both engineered failures
behaved as predicted, with richer real detail than expected rather than a
wrong prediction.

## Important Lessons

- A `Pending` Pod's Events can list multiple independent scheduling
  failures at once — read all of them, not just the first.
- Grab `--previous` crash logs as early as possible; the runtime does not
  retain unlimited crash history.

## Unresolved Issues

None blocking. Carried forward:

1. Steps 1-3 and 5 of the request flow — deferred to Day 39-41, 45, 65/80.
2. Why only some static Pods got a fresh `Age` after a node reboot —
   deferred to Day 68.
3. CoreDNS anti-affinity fix — deliberately deferred to Day 34/36.
4. All 3 `nginx-trace` Pods showed a simultaneous restart on Day 05
   (`162m ago`), not investigated — chase if it recurs.
5. "Declarative vs imperative" and "Kubernetes objects and the API" never
   given a dedicated day (found 2026-09-22 during `fundamentals/README.md`
   reconciliation) — no fix scheduled, tracked in `next-steps.md`.

## Next Topic

Day 09 — ReplicaSets and why you rarely write one.

## Next Lab

LAB 09 — not yet written. File to create:
`journal/daily/day-09-replicasets.md`.

## Overall Progress

Day 08 of 130 COMPLETE. Day 09 starting next session. 0 of 30 modules
completed, 1 in progress. 0 of 10 projects.

```text
[■■                            ] 6%
```

Full day-by-day plan: `progress/daily-plan.md`
