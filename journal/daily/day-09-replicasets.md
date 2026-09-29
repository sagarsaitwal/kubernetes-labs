# Day 09 — ReplicaSets and Why You Rarely Write One

Author: Sagar Saitwal

| | |
|---|---|
| **Date** | 2026-09-29 |
| **Day** | 09 |
| **Module** | 02 — Workloads |
| **Topic** | ReplicaSets and why you rarely write one directly |
| **Status** | COMPLETED |
| **Cluster** | `k8s-lab` — 3 nodes, Kubernetes v1.37.0, kind v0.33.0 (on `IT-SAGARS`) |

---

## Today's Objective

Write a bare ReplicaSet by hand, then deliberately prove — not just assert
— the exact gap that makes Deployments necessary: a ReplicaSet enforces
replica *count*, never Pod *content*, and has no update mechanism at all.

## Module

02 — Workloads

## Section

ReplicaSets

## Topic

Replica-count reconciliation; the "no rollout" limitation; `kubectl scale`

## Subtopic

`get rs`'s `DESIRED`/`CURRENT`/`READY` columns; refined Pod-naming rule;
old ReplicaSets as rollback history; `apply`'s `unchanged` as real
diagnostic signal

---

## Theory Learned

**A ReplicaSet is the actual mechanism behind every self-healing Pod
observed since Day 01** — it ensures a specified number of Pods matching a
label selector exist, and replaces any that disappear. Naming the
mechanism directly, rather than trusting it implicitly, was the point.

**A ReplicaSet's `spec.selector.matchLabels` must exactly match
`spec.template.metadata.labels`**, or the object is invalid — a
ReplicaSet's selector has to be able to find the very Pods its own
template creates.

**`kubectl get rs` has its own column set, not reused from `get pods` or
`get deployments`:** `DESIRED` (from `spec.replicas`), `CURRENT` (Pod
objects that exist right now), `READY` (how many pass readiness) — three
numbers that can diverge, e.g. while images are still pulling.

**A bare ReplicaSet's Pod naming is `<name>-<5 random chars>`, one hash,
not two.** This refines Day 02's naming table: that single-hash pattern
isn't DaemonSet-specific — it's what any ReplicaSet produces when it
creates Pods directly. The **double**-hash pattern
(`<name>-<10 chars>-<5 chars>`) specifically marks a Pod created by a
**Deployment's** ReplicaSet — one hash per layer of ownership.

**The core finding, proven in three concrete steps, not asserted:** a
ReplicaSet's controller reconciles only on **count**, never on **content**.
1. Edited the template's image, reapplied — the ReplicaSet object updated
   instantly, but both existing Pods kept the old image. Count (`2`
   desired, `2` existing) was already satisfied; the controller had
   nothing to do and never inspects what a satisfied-count Pod is running.
2. Scaled to `3` — the **new** Pod (`mb9sj`) picked up the current
   template (`1.28-alpine`), because the template is only ever read *at
   Pod-creation time*.
3. Deleted an old-image Pod (`kwn7t`) directly — its replacement (`s6stl`)
   also came up on the new image, while the untouched original (`vjl29`)
   stayed on the old one. Confirms the rule fully: template changes only
   ever reach *newly created* Pods, whether from scaling or replacement,
   never existing ones.

**An unplanned, real confirmation of the same lesson, found before the
exercise even started:** `kubectl get rs` showed two leftover ReplicaSets
from Day 03/04 — `nginx-trace-647575f7d8` (`DESIRED: 0`, the original,
pre-Zscaler-fix generation) and `nginx-trace-855cf8f8cc` (`DESIRED: 3`, the
post-fix generation). The **Deployment** managing `nginx-trace` had scaled
the old one to zero rather than deleting it — preserved as rollback
history (the `revisionHistoryLimit: 10` field first seen in Day 03's
`-o yaml`, now with a concrete meaning). Managing `nginx-trace` as a bare
ReplicaSet the whole time would never have given this for free.

**`kubectl apply` reporting `unchanged` is a real diagnostic signal, not a
null result.** The first reapply attempt returned `unchanged` because the
YAML edit hadn't actually been saved — `apply`'s diff correctly found
nothing to do, and that response itself was the evidence needed to catch
the mistake before assuming the exercise had failed.

**`kubectl scale` is imperative — it changes the live object's
`spec.replicas` directly, without touching the YAML file at all.** After
scaling to `3`, `replicaset-demo.yaml` on disk still says `replicas: 2` —
file and live state have quietly diverged. Directly relevant to one of the
two gaps flagged in `progress/next-steps.md` on 2026-09-22: "declarative
vs imperative" was never given its own lesson, and this is exactly the
kind of drift that idea is about.

## Why It Matters

This is the actual, provable reason Deployments exist, not a
documentation claim taken on trust: a bare ReplicaSet gives you
self-healing count-enforcement and nothing else — no safe way to change
what's running without manually deleting Pods one at a time and hoping
nothing breaks mid-way. A Deployment automates exactly that orchestration.

---

## Commands Used

### `kubectl apply -f replicaset-demo.yaml`

- **Expected / Actual output:** `replicaset.apps/replicaset-demo created`.

### `kubectl get rs`

- **Actual output:** 3 ReplicaSets — `replicaset-demo` (new) plus the two
  leftover `nginx-trace-*` generations from Day 03/04. See Theory Learned.

### `kubectl get pods -l app=rs-demo -o wide`

- **Actual output:** `replicaset-demo-kwn7t`, `replicaset-demo-vjl29` —
  single-hash naming, confirmed and used to refine the Day 02 naming rule.

### `kubectl get pods -l app=rs-demo -o custom-columns='NAME:...,IMAGE:...'`

- **Why I used it:** track exactly which Pod runs which image, across
  every step of the exercise.
- **Actual output (three checkpoints):**
  1. Before any change: both Pods `1.27-alpine`.
  2. After editing the template and reapplying (first attempt): `apply`
     returned `unchanged` — the edit hadn't been saved; confirmed via
     `cat replicaset-demo.yaml`, then genuinely edited, confirmed again.
  3. After a real reapply (`configured`): both **existing** Pods still
     `1.27-alpine` — the core finding, directly observed.

### `kubectl scale replicaset replicaset-demo --replicas=3`

- **What it does:** imperatively sets `spec.replicas` on the live object.
- **Actual output:** `replicaset.apps/replicaset-demo scaled`; the new
  Pod (`mb9sj`) came up on `1.28-alpine`.

### `kubectl delete pod replicaset-demo-kwn7t`

- **Why I used it:** test whether a *replacement* Pod (as opposed to a
  scale-up Pod) also picks up the current template.
- **Actual output:** replacement `replicaset-demo-s6stl` came up on
  `1.28-alpine`, confirming the rule applies to both creation paths.

### `kubectl delete replicaset replicaset-demo`

- **What it does:** deletes the ReplicaSet and cascades to every Pod it
  owns.
- **Actual output:** `replicaset.apps "replicaset-demo" deleted from
  default namespace` — all 3 remaining Pods removed with it.

---

## YAML / Configuration

`fundamentals/labs/replicaset-demo.yaml` — fifth hand-written manifest,
first `apps/v1` object written by hand (previous manifests were all
`v1` Pods):

```yaml
apiVersion: apps/v1
kind: ReplicaSet

metadata:
  name: replicaset-demo

spec:
  replicas: 2
  selector:
    matchLabels:
      app: rs-demo
  template:
    metadata:
      labels:
        app: rs-demo
    spec:
      containers:
        - name: nginx
          image: nginx:1.28-alpine   # edited mid-exercise from 1.27-alpine
```

Correct on the first attempt.

---

## Lab Performed

1. Wrote and applied the ReplicaSet; inspected `get rs`'s new column set
   and found two unrelated leftover ReplicaSets from Day 03/04, which
   turned out to be directly relevant evidence.
2. Confirmed Pod naming and refined the Day 02 naming rule.
3. Recorded both Pods' starting image via custom-columns.
4. Edited the template's image, reapplied — caught a real mistake
   (`unchanged`, edit not saved) before it could confuse the result;
   fixed, reapplied for real, confirmed existing Pods were unaffected.
5. Scaled up; confirmed the new Pod got the new image.
6. Deleted an old-image Pod directly; confirmed its replacement also got
   the new image.
7. Cleaned up by deleting the ReplicaSet (cascaded to all Pods).

---

## Environment

| Item | Value |
|---|---|
| Kubernetes version | v1.37.0 (client and server) |
| Node count | 3 — 1 control-plane, 2 workers |
| Machine | `IT-SAGARS` — Windows 11 / WSL2 FedoraLinux-44, kernel 6.18.33.2 |
| Container runtime | containerd 2.3.4 |
| CNI | kindnet |

---

## Expected Result

A bare ReplicaSet's "no content reconciliation" limitation demonstrated
with real, three-step evidence, plus an unplanned but directly relevant
confirmation from Day 03/04's own leftover ReplicaSets.

## Actual Result

Matched, plus a genuine, self-caught mistake along the way (`unchanged`
from an unsaved edit) that became its own useful lesson rather than a
wasted step.

## What Worked

- Tracking images via `custom-columns` at every checkpoint made the whole
  mechanism visible as a clean before/after table rather than something to
  take on faith.
- Predicting the outcome before each command (naming pattern, new Pod's
  image, replacement Pod's image) turned each result into a real
  confirm-or-correct check rather than passive observation.

## What Failed

The first reapply attempt did nothing (`unchanged`) because the YAML edit
hadn't been saved — caught immediately via the honest `unchanged` response
and `cat`-ing the file, not discovered later as a confusing result.

---

## What I Broke

Nothing broken — the `unchanged` result was a real signal correctly
interpreted, not a failure requiring a fix.

## Error Message

Not applicable — no error, an accurate `unchanged` status.

## Investigation

```bash
kubectl apply -f replicaset-demo.yaml   # returned "unchanged" unexpectedly
cat replicaset-demo.yaml                # confirmed image line still read 1.27-alpine
```

## Root Cause

The image-tag edit had not actually been saved to disk before the reapply
was attempted.

## Solution

Re-edited the file, confirmed via `cat` before reapplying.

## Verification

Second `apply` returned `configured` (a real diff existed this time), and
the subsequent custom-columns check showed the expected before/after
pattern.

---

## Mistake

No `journal/mistakes-and-lessons.md` entry — this was a normal
edit-verify-retry step, not a misunderstanding of any Kubernetes mechanism.

## Lesson Learned

1. `kubectl apply` returning `unchanged` is real diagnostic information —
   it means the diff genuinely found nothing, which is worth trusting over
   assuming your own edit must have applied.
2. A ReplicaSet's template is read only at Pod-creation time — scaling up
   and replacing a deleted Pod are the only two ways to get a newly
   created Pod, and both were tested directly rather than assumed to
   behave the same way.
3. `kubectl scale` is a fast, imperative escape hatch — useful, but it
   silently diverges the live cluster from whatever's committed in the
   YAML file, worth remembering before treating the file as the current
   truth.

## Troubleshooting Knowledge

```text
SYMPTOM: Edited a manifest's image/config, reapplied, but nothing in the
         cluster appears to have changed for a plain ReplicaSet (not a
         Deployment).
CHECK:   Did `kubectl apply` report "configured" or "unchanged"?
COMMAND: kubectl apply -f <file>
         kubectl get pods -l <selector> -o custom-columns='...IMAGE...'
INTERPRETATION: "unchanged" means the edit never reached the file that
         was applied -- check the file's actual saved content before
         assuming the object failed to update.
         "configured" means the ReplicaSet OBJECT updated correctly, but
         its EXISTING Pods will not -- a ReplicaSet only reads its
         template when creating a NEW Pod (scale-up or replacement),
         never retroactively.
ROOT CAUSE: Either an unsaved edit (before "unchanged"), or a correct but
         misunderstood limitation of bare ReplicaSets (after "configured").
FIX:     For the unsaved-edit case, save and reapply. For the "existing
         Pods didn't update" case, there is no fix at the ReplicaSet
         level -- this is precisely why Deployments exist (Day 10).
PREVENTION: Never expect a bare ReplicaSet to roll out a template change
         to Pods that already exist -- verify with custom-columns rather
         than assuming.
```

---

## Interview Questions

1. What two things does `spec.selector.matchLabels` and
   `spec.template.metadata.labels` need to have in common, and why does
   the API enforce it?
2. `kubectl get rs` shows `DESIRED: 3, CURRENT: 3, READY: 1`. What does
   each number mean, and what would explain them diverging?
3. You edit a ReplicaSet's Pod template and reapply. What happens to
   already-running Pods, and why?
4. What's the practical difference between `kubectl scale` and editing
   `replicas:` in a YAML file and reapplying?
5. A Deployment's old ReplicaSet is still visible via `kubectl get rs`,
   scaled to zero. What is it for?
6. Why does a bare ReplicaSet's Pod get a single hash suffix while a
   Deployment-managed one gets two?

## Challenge

Proving the "no content reconciliation" limitation in three concrete,
predicted-then-verified steps (template edit, scale-up, delete-and-replace)
served as today's exercise, including catching and correcting a real
unsaved-edit mistake along the way.

---

## End-of-Day Status

| Item | State |
|---|---|
| Bare ReplicaSet written and applied, correct on first attempt | Done |
| `get rs` column set and refined Pod-naming rule confirmed | Done |
| Old Day 03/04 ReplicaSets found as unplanned rollback-history evidence | Done |
| Template-edit limitation proven (existing Pods unaffected) | Done |
| Scale-up and delete-and-replace both confirmed to use the current template | Done |
| `apply`'s `unchanged` response correctly diagnosed and resolved | Done |

## Next Session

Next journal file: `journal/daily/day-10-deployments.md`

1. Run the resume ritual (`git pull`, `current-progress.md`,
   `check-dependencies.sh`, check `SystemInfo.md` for this machine).
2. Day 10 — Deployments and rolling updates.
