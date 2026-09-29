# Current Kubernetes Learning Progress

Author: Sagar Saitwal

Last updated: 2026-09-29

> This file is the single source of truth for where the learning stopped.
> On any new session or new device, read this file FIRST.

**Current Day: 12**

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

Day 11 COMPLETED. Day 12 — DaemonSets, Jobs, CronJobs — **not yet
started.** No teaching content prepared yet.

## Current Subtopic

Day 12 has not started.

## Learning Status

🟡 IN PROGRESS

Day 00 through Day 11 are all fully COMPLETED. Day 12 is next.

## Last Completed Lab

**Day 11 — Rollout history, rollback, update strategies.** COMPLETED.
Built a real 3-revision history on `deployment-demo` with meaningful
`CHANGE-CAUSE` annotations, then used `kubectl rollout undo --to-revision=1`
to jump directly to revision 1, deliberately skipping revision 2 — confirmed
via image and env-var checks, and via a caught-mid-transition 3-Pod surge
state proving rollback uses the same rolling-update mechanism as any
forward update. Then added `spec.strategy.type: Recreate` and watched a
real, full stop-then-start rollout live: both old Pods terminated together,
a genuine window with zero Pods `Ready`, then both new Pods started
together — direct contrast with `RollingUpdate`'s overlapping handover.
Also hit a real, unplanned recurrence of Day 10's file/live-state drift
right at the start (the file was still on `1.28-alpine` from Day 10, since
`rollout undo` never touches files) — caught via a now-familiar `unchanged`
signal and corrected through direct evidence rather than assumption.

## Last Commands Practiced

```bash
kubectl apply -f deployment-demo.yaml
kubectl annotate deployment deployment-demo kubernetes.io/change-cause="..." --overwrite
kubectl rollout history deployment/deployment-demo
kubectl rollout undo deployment/deployment-demo --to-revision=1
kubectl exec <pod> -- printenv DEMO_VERSION
kubectl get pods -l app=deploy-demo -o custom-columns='NAME:.metadata.name,IMAGE:.spec.containers[0].image'
kubectl delete deployment deployment-demo
```

## Last YAML Practiced

`fundamentals/labs/deployment-demo.yaml` — evolved through 4 real states
this session (3 annotated revisions plus a `strategy.type: Recreate`
variant), reusing the same file from Day 10.

## What I Learned

- `kubectl rollout undo --to-revision=N` jumps directly to any revision in
  history, skipping intermediate ones — different from plain `undo`.
- `CHANGE-CAUSE` requires deliberate recording via `kubectl annotate ...
  kubernetes.io/change-cause` — otherwise `rollout history` stays
  anonymous.
- Rollback is not a separate mechanism — it's the same rolling-update
  engine, pointed at an existing ReplicaSet instead of a new one, and
  `maxSurge` applies to it exactly the same way.
- `spec.strategy.type: Recreate` produces a real, measurable availability
  gap (all old Pods gone before any new one starts) — the direct opposite
  risk profile from `RollingUpdate`'s overlap.
- Any imperative command (`rollout undo`, `scale`) leaves the YAML file
  stale relative to the live object — always verify the real state with a
  direct command rather than assuming the file is current.

## What I Broke

Nothing. One real, unplanned finding: the file was stale from Day 10
(still `1.28-alpine`), caught via `unchanged` and corrected through direct
evidence before it affected the exercise's conclusions.

## Errors Encountered

None — `unchanged` and the `rollout undo` warning were both correct,
informative, non-error output.

## Root Cause

`kubectl rollout undo` (Day 10) is imperative and never touched
`deployment-demo.yaml`.

## How It Was Fixed

Confirmed the real live image via `custom-columns`, relabeled the
annotation accurately, and adjusted the planned revision sequence.

## Mistakes Made

None — no `journal/mistakes-and-lessons.md` entry. The stale-file issue was
a direct, already-understood consequence of Day 10's documented finding.

## Important Lessons

- Verify a manifest's assumed starting state with a direct command before
  building a multi-step exercise on top of it, especially after any
  imperative command was used previously.
- `Recreate`'s cost is real and measurable, not an abstract warning —
  worth choosing deliberately.

## Unresolved Issues

None blocking. Carried forward:

1. Steps 1-3 and 5 of the request flow — deferred to Day 39-41, 45, 65/80.
2. Why only some static Pods got a fresh `Age` after a node reboot —
   deferred to Day 68.
3. CoreDNS anti-affinity fix — deliberately deferred to Day 34/36.
4. All 3 `nginx-trace` Pods showed a simultaneous restart on Day 05
   (`162m ago`), not investigated — chase if it recurs.
5. "Declarative vs imperative" and "Kubernetes objects and the API" never
   given a dedicated day — Day 11's stale-file finding is further real
   evidence for the first one, still tracked in `next-steps.md`.

## Next Topic

Day 12 — DaemonSets, Jobs, CronJobs.

## Next Lab

LAB 12 — not yet written. File to create:
`journal/daily/day-12-daemonsets-jobs-cronjobs.md`.

## Overall Progress

Day 11 of 130 COMPLETE. Day 12 starting next session. 0 of 30 modules
completed, 1 in progress. 0 of 10 projects.

```text
[■■■                           ] 8%
```

Full day-by-day plan: `progress/daily-plan.md`
