# Current Kubernetes Learning Progress

Author: Sagar Saitwal

Last updated: 2026-09-29

> This file is the single source of truth for where the learning stopped.
> On any new session or new device, read this file FIRST.

**Current Day: 10**

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

Day 09 COMPLETED. Day 10 — Deployments and rolling updates — **not yet
started.** No teaching content prepared yet.

## Current Subtopic

Day 10 has not started. This is where the exact gap Day 09 proved (bare
ReplicaSets never reconcile Pod content) gets its solution.

## Learning Status

🟡 IN PROGRESS

Day 00 through Day 09 are all fully COMPLETED. Day 10 is next.

## Last Completed Lab

**Day 09 — ReplicaSets and why you rarely write one.** COMPLETED. Wrote a
bare ReplicaSet by hand (`fundamentals/labs/replicaset-demo.yaml`), correct
on the first attempt. Proved in three concrete steps that a ReplicaSet
reconciles only on Pod *count*, never *content*: editing the template and
reapplying left existing Pods untouched; scaling up gave the new Pod the
updated template; deleting an old-image Pod gave its replacement the
updated template too. Unplanned bonus finding: `kubectl get rs` showed two
leftover ReplicaSets from Day 03/04 (the pre/post-Zscaler-fix generations)
— the old one preserved at `0` replicas as rollback history, a Deployment
behavior a bare ReplicaSet would never give you. Also refined Day 02's Pod
naming rule (single-hash naming isn't DaemonSet-specific, it's what any
ReplicaSet produces directly) and correctly diagnosed a real `unchanged`
`apply` result as an unsaved edit, not a failure.

## Last Commands Practiced

```bash
kubectl apply -f replicaset-demo.yaml
kubectl get rs
kubectl get pods -l app=rs-demo -o wide
kubectl get pods -l app=rs-demo -o custom-columns='NAME:.metadata.name,IMAGE:.spec.containers[0].image'
kubectl scale replicaset replicaset-demo --replicas=3
kubectl delete pod replicaset-demo-kwn7t
kubectl delete replicaset replicaset-demo
```

## Last YAML Practiced

`fundamentals/labs/replicaset-demo.yaml` — fifth hand-written manifest,
first `apps/v1` object written by hand.

## What I Learned

- A ReplicaSet's `spec.selector.matchLabels` must exactly match
  `spec.template.metadata.labels`, or the object is invalid.
- `kubectl get rs`'s `DESIRED`/`CURRENT`/`READY` columns can diverge and
  each means something distinct.
- A bare ReplicaSet's Pod naming is a single `<name>-<5 chars>` hash — this
  isn't DaemonSet-specific, it's what any ReplicaSet produces directly; the
  double-hash pattern specifically marks a Deployment-managed Pod.
- A ReplicaSet reconciles only on count, never content — proven via
  template-edit (no effect on existing Pods), scale-up (new Pod gets new
  template), and delete-and-replace (replacement also gets new template).
- A Deployment's old, superseded ReplicaSet is kept at `0` replicas as
  rollback history — found unplanned, from Day 03/04's own leftover
  objects.
- `kubectl apply` returning `unchanged` is real diagnostic information —
  it means the diff found nothing, which caught an unsaved edit before it
  could confuse the exercise.
- `kubectl scale` is imperative — it changes the live object directly,
  silently diverging from whatever the YAML file says.

## What I Broke

Nothing. One real, self-caught mistake: reapplied before actually saving
an edit, correctly diagnosed from `apply`'s `unchanged` response rather
than assumed to be a cluster problem.

## Errors Encountered

None — `unchanged` was a correct, honest response, not an error.

## Root Cause

N/A — see What I Broke.

## How It Was Fixed

Re-edited the file, confirmed via `cat` before reapplying.

## Mistakes Made

None — no `journal/mistakes-and-lessons.md` entry. The unsaved-edit moment
was a normal edit-verify-retry step, not a Kubernetes misunderstanding.

## Important Lessons

- `kubectl apply`'s `unchanged`/`configured` responses are themselves
  diagnostic signal — trust them over assuming your own edit worked.
- Never expect a bare ReplicaSet to roll out a template change to
  already-existing Pods — verify with `custom-columns`, don't assume.

## Unresolved Issues

None blocking. Carried forward:

1. Steps 1-3 and 5 of the request flow — deferred to Day 39-41, 45, 65/80.
2. Why only some static Pods got a fresh `Age` after a node reboot —
   deferred to Day 68.
3. CoreDNS anti-affinity fix — deliberately deferred to Day 34/36.
4. All 3 `nginx-trace` Pods showed a simultaneous restart on Day 05
   (`162m ago`), not investigated — chase if it recurs.
5. "Declarative vs imperative" and "Kubernetes objects and the API" never
   given a dedicated day — `kubectl scale`'s file/live-state drift today
   is directly relevant evidence for the first one, still tracked in
   `next-steps.md`.

## Next Topic

Day 10 — Deployments and rolling updates.

## Next Lab

LAB 10 — not yet written. File to create:
`journal/daily/day-10-deployments.md`.

## Overall Progress

Day 09 of 130 COMPLETE. Day 10 starting next session. 0 of 30 modules
completed, 1 in progress. 0 of 10 projects.

```text
[■■                            ] 7%
```

Full day-by-day plan: `progress/daily-plan.md`
