# Current Kubernetes Learning Progress

Author: Sagar Saitwal

Last updated: 2026-09-22

> This file is the single source of truth for where the learning stopped.
> On any new session or new device, read this file FIRST.

**Current Day: 06**

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

Day 05 COMPLETED. Day 06 — Pod anatomy, YAML, lifecycle, phases — **not yet
started.** No teaching content prepared yet.

## Current Subtopic

Day 06 has not started. This is the first day involving hand-written YAML
(everything so far reused `fundamentals/labs/nginx-deployment.yaml`
unmodified).

## Learning Status

🟡 IN PROGRESS

Day 00 through Day 05 are all fully COMPLETED. Day 06 is next.

## Last Completed Lab

**Day 05 — Namespaces, labels, selectors, annotations.** COMPLETED. Created
a `dev` namespace; proved isolation by applying the same manifest into both
`default` and `dev` with no collision; filtered Pods by label selector;
proved annotations are structurally excluded from selection (`kubectl get
deployment -l learning-day=05` found nothing, even though the annotation
was genuinely present). Corrected two of my own planning errors live: `kind`
ships a 5th default namespace (`local-path-storage`), and `kubectl get`
rejects combining an object name with a selector.

## Last Commands Practiced

```bash
kubectl create namespace dev
kubectl get namespaces
kubectl get pods -l app=nginx-trace
kubectl apply -f nginx-deployment.yaml -n dev
kubectl get pods
kubectl get pods -n dev
kubectl annotate deployment nginx-trace learning-day=05 --overwrite
kubectl get deployment -l learning-day=05
```

## Last YAML Practiced

`fundamentals/labs/nginx-deployment.yaml` — same file, reused a third time
(applied into a second namespace, not edited). First hand-written YAML is
still Day 06.

## What I Learned

- Namespaces partition one cluster into isolated virtual clusters — object
  names only need to be unique *within* a namespace, proven by running the
  identical Deployment name in both `default` and `dev` with zero conflict.
- Labels are the actual mechanism Services/Deployments use to find their
  Pods, not just organizational tags — `kubectl get pods -l app=...` runs
  the same equality-match by hand.
- Annotations are structurally excluded from selection — not a convention,
  a hard API boundary, proven directly rather than asserted.
- `kind` ships a 5th default namespace (`local-path-storage`) beyond the 4
  a bare cluster has, for its bundled dynamic-storage provisioner.
- `kubectl get <type> <name>` and `kubectl get <type> -l <selector>` are
  mutually exclusive — combining them is rejected outright, not a warning.
- A ReplicaSet's name hash is computed purely from its Pod template's
  content — identical templates produce identical hashes regardless of
  namespace or timing.

## What I Broke

Nothing. Two planning errors were mine (assistant), not Sagar's — see
`journal/daily/day-05-namespaces-labels-selectors.md`, "What Failed."
Neither affected cluster state; both were corrected live.

## Errors Encountered

```text
error: name cannot be provided when a selector is specified
```
(from an invalid command the assistant gave — corrected within the session,
not a Sagar misunderstanding, so not filed as a formal Mistake.)

## Root Cause

`kubectl get` treats "one named object" and "a set matching a selector" as
mutually exclusive query modes.

## How It Was Fixed

Dropped the object name, kept the selector:
`kubectl get deployment -l learning-day=05`.

## Mistakes Made

None — no `journal/mistakes-and-lessons.md` entry for Day 05. Both
corrections this session were the assistant's planning errors, not gaps in
Sagar's understanding.

## Important Lessons

- Check `kubectl get namespaces` on a real cluster rather than assuming the
  textbook-minimal default set — `kind` specifically ships an extra one.
- `kubectl get`'s name and selector arguments cannot be combined — worth
  remembering before scripting anything that filters a known object further.

## Unresolved Issues

None blocking. Carried forward:

1. Steps 1-3 and 5 of the request flow — deferred to Day 39-41, 45, 65/80.
2. Why only some static Pods got a fresh `Age` after a node reboot —
   deferred to Day 68.
3. CoreDNS anti-affinity fix — deliberately deferred to Day 34/36.
4. **New:** all 3 `nginx-trace` Pods in `default` showed a simultaneous
   restart, `RESTARTS: 1 (162m ago)`, noticed during Day 05's label-filter
   command but not investigated — no `describe`/Events check done yet. Not
   blocking; chase if it recurs or affects a future day's work.

## Next Topic

Day 06 — Pod anatomy, YAML, lifecycle, phases.

## Next Lab

LAB 06 — not yet written. File to create:
`journal/daily/day-06-pod-basics.md`.

## Overall Progress

Day 05 of 130 COMPLETE. Day 06 starting next session. 0 of 30 modules
completed, 1 in progress. 0 of 10 projects.

```text
[■■                            ] 4%
```

Full day-by-day plan: `progress/daily-plan.md`
