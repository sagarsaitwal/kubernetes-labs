# Current Kubernetes Learning Progress

Author: Sagar Saitwal

Last updated: 2026-09-22

> This file is the single source of truth for where the learning stopped.
> On any new session or new device, read this file FIRST.

**Current Day: 07**

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

Module 01 — Kubernetes Fundamentals

## Current Topic

Day 06 COMPLETED. Day 07 — Multi-container Pods, sidecars, init containers —
**not yet started.** No teaching content prepared yet.

## Current Subtopic

Day 07 has not started.

## Learning Status

🟡 IN PROGRESS

Day 00 through Day 06 are all fully COMPLETED. Day 07 is next.

## Last Completed Lab

**Day 06 — Pod anatomy, YAML, lifecycle, phases.** COMPLETED. Wrote the
course's first hand-authored manifest (`fundamentals/labs/manual-pod.yaml`),
correct on the first attempt. Applied it, observed the Pod-level `Status:`
vs. container-level `State:` distinction directly via `describe`, then
deleted it and confirmed via `kubectl get pods` that nothing recreated it —
proving a bare Pod has no controller, unlike every `nginx-trace` Pod used
since Day 03. Also found the same Day 03 toleration-injection applies to
any Pod, not just controller-created ones.

## Last Commands Practiced

```bash
kubectl apply -f manual-pod.yaml
kubectl get pod manual-pod
kubectl get pod manual-pod -w
kubectl describe pod manual-pod
kubectl delete pod manual-pod
kubectl get pods
```

## Last YAML Practiced

`fundamentals/labs/manual-pod.yaml` — first hand-written manifest of the
course. Minimal Pod: `apiVersion: v1`, `kind: Pod`, one container
(`nginx:1.27-alpine`).

## What I Learned

- A Pod's minimum valid manifest needs exactly 6 fields: `apiVersion`,
  `kind`, `metadata.name`, and per container `name` + `image`.
- A Deployment's `spec.template` is literally a Pod spec, nested — writing
  a standalone Pod first makes that shape recognizable rather than new
  syntax.
- Pod-level `status.phase` and container-level `state` are different
  signals — phase is coarse, container state carries the actual
  reason/exit code.
- A bare Pod has no controller — deleting one is final, unlike a
  Deployment-managed Pod, which gets replaced within seconds.
- Admission's toleration injection (Day 03) applies to any Pod creation,
  not just ones created via a ReplicaSet.
- A cached image can make the `Pending` phase nearly invisible — it
  reflects real waiting, not a mandatory visible step.
- A `kubectl get -w` watch reflects changes from *any* terminal acting on
  the same object, not just its own session — explains an apparent
  "unexplained" transition that turned out to be a `delete` run
  concurrently in a second terminal.

## What I Broke

Nothing. One filename typo (`manua-pod.yaml`) caught and fixed before it
caused any downstream issue.

## Errors Encountered

None.

## Root Cause

N/A

## How It Was Fixed

N/A

## Mistakes Made

None — no `journal/mistakes-and-lessons.md` entry for Day 06.

## Important Lessons

- A live watch (`-w`) isn't scoped to "this terminal's own actions" — it
  reflects the object's real state regardless of which session changed it.
- Reviewing a hand-written manifest before applying catches small errors
  (like a filename typo) before they propagate into later commands.

## Unresolved Issues

None blocking. Carried forward:

1. Steps 1-3 and 5 of the request flow — deferred to Day 39-41, 45, 65/80.
2. Why only some static Pods got a fresh `Age` after a node reboot —
   deferred to Day 68.
3. CoreDNS anti-affinity fix — deliberately deferred to Day 34/36.
4. All 3 `nginx-trace` Pods showed a simultaneous restart on Day 05
   (`162m ago`), not investigated — chase if it recurs.
5. **New:** `Pending`/`Failed`/`CrashLoopBackOff` phases not yet observed
   directly (today's Pod skipped `Pending` due to a cached image) —
   deliberately deferred to Day 08, a dedicated break/fix day.

## Next Topic

Day 07 — Multi-container Pods, sidecars, init containers.

## Next Lab

LAB 07 — not yet written. File to create:
`journal/daily/day-07-multi-container-pods.md`.

## Overall Progress

Day 06 of 130 COMPLETE. Day 07 starting next session. 0 of 30 modules
completed, 1 in progress. 0 of 10 projects.

```text
[■■                            ] 5%
```

Full day-by-day plan: `progress/daily-plan.md`
