# Current Kubernetes Learning Progress

Author: Sagar Saitwal

Last updated: 2026-09-29

> This file is the single source of truth for where the learning stopped.
> On any new session or new device, read this file FIRST.

**Current Day: 11**

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

Day 10 COMPLETED. Day 11 — Rollout history, rollback, update strategies —
**not yet started.** No teaching content prepared yet.

## Current Subtopic

Day 11 has not started. This goes deeper than Day 10's introduction:
`maxSurge`/`maxUnavailable` tuning, rollback to a specific revision (not
just "previous"), and `Recreate` vs `RollingUpdate` strategies.

## Learning Status

🟡 IN PROGRESS

Day 00 through Day 10 are all fully COMPLETED. Day 11 is next.

## Last Completed Lab

**Day 10 — Deployments and rolling updates.** COMPLETED. Wrote a
Deployment by hand (`fundamentals/labs/deployment-demo.yaml`), correct on
the first attempt. Drove a full rolling-update-then-rollback cycle:
watched `kubectl rollout status` stream real progress
(`1 old replicas are pending termination...`), confirmed a **new**
ReplicaSet generation took over (the exact Day 09 mechanism, now produced
deliberately), then used `kubectl rollout undo` to roll back — confirming
the **old** ReplicaSet was reactivated rather than rebuilt. Hit the same
`unchanged`/unsaved-edit pattern as Day 09, recognized immediately this
time. `rollout undo`'s warning about `last-applied-configuration` turned
out to be a real, witnessed instance of the "declarative vs imperative"
drift flagged as an open gap since Day 09 — not boilerplate.

## Last Commands Practiced

```bash
kubectl apply -f deployment-demo.yaml
kubectl get deployment deployment-demo
kubectl get rs -l app=deploy-demo
kubectl get pods -l app=deploy-demo -o custom-columns='NAME:.metadata.name,IMAGE:.spec.containers[0].image'
kubectl rollout status deployment/deployment-demo
kubectl rollout history deployment/deployment-demo
kubectl rollout undo deployment/deployment-demo
kubectl delete deployment deployment-demo
```

## Last YAML Practiced

`fundamentals/labs/deployment-demo.yaml` — sixth hand-written manifest,
first Deployment written by hand.

## What I Learned

- A Deployment's `spec` is structurally identical to a ReplicaSet's —
  `replicas`/`selector`/`template` — the entire difference is behavioral.
- `kubectl get deployment` has its own column set: `READY`, `UP-TO-DATE`,
  `AVAILABLE` — these can diverge mid-rollout.
- A rolling update creates a new ReplicaSet generation and gradually shifts
  Pods from old to new — watched live via `rollout status`.
- `rollout history`'s `CHANGE-CAUSE` isn't automatic — it stays `<none>`
  unless deliberately recorded.
- `rollout undo` is imperative — it reactivates the old ReplicaSet but does
  **not** update `kubectl apply`'s `last-applied-configuration` annotation,
  a real source of drift between file, live object, and `apply`'s own
  diff-tracking state.

## What I Broke

Nothing. One recurrence of Day 09's `unchanged`/unsaved-edit pattern,
recognized immediately rather than re-diagnosed.

## Errors Encountered

None — `unchanged` and the `rollout undo` warning were both correct,
informative, non-error output.

## Root Cause

N/A — see What I Broke.

## How It Was Fixed

N/A.

## Mistakes Made

None — no `journal/mistakes-and-lessons.md` entry.

## Important Lessons

- Mixing imperative commands (`scale`, `rollout undo`) with a declarative
  `apply` workflow on the same object can cause the file, the live object,
  and `apply`'s own tracking annotation to genuinely disagree.
- Recognizing a previously-documented pattern (yesterday's `unchanged`)
  immediately, without re-diagnosing, is itself a skill worth noticing.

## Unresolved Issues

None blocking. Carried forward:

1. Steps 1-3 and 5 of the request flow — deferred to Day 39-41, 45, 65/80.
2. Why only some static Pods got a fresh `Age` after a node reboot —
   deferred to Day 68.
3. CoreDNS anti-affinity fix — deliberately deferred to Day 34/36.
4. All 3 `nginx-trace` Pods showed a simultaneous restart on Day 05
   (`162m ago`), not investigated — chase if it recurs.
5. "Declarative vs imperative" and "Kubernetes objects and the API" never
   given a dedicated day — Day 10's `rollout undo` drift is further real
   evidence for the first one, still tracked in `next-steps.md`.

## Next Topic

Day 11 — Rollout history, rollback, update strategies.

## Next Lab

LAB 11 — not yet written. File to create:
`journal/daily/day-11-rollouts-and-rollback.md`.

## Overall Progress

Day 10 of 130 COMPLETE. Day 11 starting next session. 0 of 30 modules
completed, 1 in progress. 0 of 10 projects.

```text
[■■■                           ] 8%
```

Full day-by-day plan: `progress/daily-plan.md`
