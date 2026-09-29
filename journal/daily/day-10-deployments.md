# Day 10 — Deployments and Rolling Updates

Author: Sagar Saitwal

| | |
|---|---|
| **Date** | 2026-09-29 |
| **Day** | 10 |
| **Module** | 02 — Workloads |
| **Topic** | Deployments and rolling updates |
| **Status** | COMPLETED |
| **Cluster** | `k8s-lab` — 3 nodes, Kubernetes v1.37.0, kind v0.33.0 (on `IT-SAGARS`) |

---

## Today's Objective

Prove, with a real rolling update and rollback, exactly how a Deployment
closes the gap Day 09 demonstrated: a bare ReplicaSet reconciles Pod count
but never content, and keeps no way to safely transition or undo a change.

## Module

02 — Workloads

## Section

Deployments

## Topic

Rolling updates (`RollingUpdate` strategy); `kubectl rollout
status`/`history`/`undo`

## Subtopic

`get deployment`'s own column set; `CHANGE-CAUSE` and why it was empty; the
`last-applied-configuration` drift warning on `rollout undo`

---

## Theory Learned

**A Deployment's `spec` is structurally identical to a ReplicaSet's**
(`replicas`, `selector`, `template`) — nothing new to learn syntactically.
**The entire difference is behavioral:** when a Deployment's template
changes, it creates a **new ReplicaSet generation** and orchestrates a
gradual handover between old and new, rather than silently updating an
object with no effect on existing Pods (Day 09's proven limitation).

**`kubectl get deployment` has its own column set** — `READY` (ready Pods
/ desired), `UP-TO-DATE` (Pods matching the current template revision),
`AVAILABLE` (ready **and** stayed ready long enough per
`minReadySeconds`). These three can diverge mid-rollout in a way `get rs`
and `get pods` don't directly show.

**A rolling update was watched live, not just described:** `kubectl
rollout status` streamed `Waiting for deployment "deployment-demo" rollout
to finish: 1 old replicas are pending termination...` before reporting
`successfully rolled out` — the Deployment controller bringing up
new-template Pods while retiring old ones, in real time.

**`kubectl apply` returning `unchanged` recurred for the exact same reason
as Day 09** — an image edit hadn't actually been saved before reapplying.
Recognized immediately this time, without needing fresh investigation,
because it had already been diagnosed and journaled once.

**The superseded ReplicaSet is kept, not deleted — confirmed directly on
a real Deployment this time, not found by accident as on Day 09.** After
the rolling update, `get rs` showed the original ReplicaSet
(`6c6864b58f`) at `DESIRED: 0` and a new one (`7c589f7d94`) at `DESIRED:
2` — the exact mechanism behind Day 09's unplanned `nginx-trace` finding,
now produced and watched on purpose.

**`kubectl rollout history` tracks *that* a revision happened, but not
automatically *why*.** `CHANGE-CAUSE` showed `<none>` for both revisions —
it's only populated via the deprecated `--record` flag or a deliberately
set `kubernetes.io/change-cause` annotation. Real gap worth knowing for an
actual team environment.

**`kubectl rollout undo` is imperative, and its own warning says so
directly.** Running it produced:
```text
Warning: resource deployments/deployment-demo was previously managed with 'kubectl apply'. Rolling back will not update the kubectl.kubernetes.io/last-applied-configuration annotation...
```
This is real, not boilerplate: after the rollback, the **live** object
reverted to `1.27-alpine`, but the `last-applied-configuration` annotation
(maintained by `kubectl apply`) still says `1.28-alpine`. A subsequent
`kubectl apply -f deployment-demo.yaml` (file still at `1.28-alpine`)
would report `unchanged` — matching its own stale annotation, not what's
actually running. A concrete, witnessed instance of the "declarative vs
imperative" drift flagged as an open gap since Day 09.

## Why It Matters

This is the actual reason a Deployment, not a bare ReplicaSet or Pod, is
the default choice for any stateless workload: it automates exactly the
orchestration that would otherwise be manual, risky, and irreversible. The
rollback specifically — reusing the old ReplicaSet rather than rebuilding
from scratch — is the concrete capability Day 09 proved was structurally
impossible without it.

---

## Commands Used

### `kubectl apply -f deployment-demo.yaml`

- **Expected / Actual output:** `deployment.apps/deployment-demo created`.

### `kubectl get deployment deployment-demo`

- **Actual output:** `READY: 2/2`, `UP-TO-DATE: 2`, `AVAILABLE: 2` —
  healthy baseline before any change.

### `kubectl get rs -l app=deploy-demo`

- **Actual output (baseline):** one ReplicaSet, `deployment-demo-6c6864b58f`
  — double-hash naming, confirming Day 09's refined naming rule on a real
  Deployment.

### `kubectl rollout status deployment/deployment-demo`

- **What it does:** blocks and streams live rollout progress, instead of
  polling `get pods` by hand.
- **First attempt:** ran against an unsaved edit — reported success
  instantly, because nothing had actually changed (`apply` had returned
  `unchanged`).
- **Second attempt (real edit saved):** streamed `1 old replicas are
  pending termination...` twice, then `successfully rolled out`.

### `kubectl get rs -l app=deploy-demo` / `get pods ... -o custom-columns`

- **Actual output (post-rollout):** two ReplicaSets — old at `0`, new
  (`7c589f7d94`) at `2`; both Pods on `1.28-alpine`.

### `kubectl rollout history deployment/deployment-demo`

- **Actual output:** 2 revisions, both `CHANGE-CAUSE: <none>` — see Theory
  Learned.

### `kubectl rollout undo deployment/deployment-demo`

- **What it does:** rolls back to the previous revision, reusing its
  ReplicaSet rather than rebuilding one.
- **Actual output:** the `last-applied-configuration` drift warning (see
  Theory Learned), then `deployment.apps/deployment-demo rolled back`.

### `kubectl get rs -l app=deploy-demo` / `get pods ... -o custom-columns` (post-rollback)

- **Actual output:** old ReplicaSet back at `2`, new one back at `0`, both
  Pods back on `1.27-alpine` — full round trip confirmed.

### `kubectl delete deployment deployment-demo`

- Cleanup — cascades to both ReplicaSets and all Pods.

---

## YAML / Configuration

`fundamentals/labs/deployment-demo.yaml` — sixth hand-written manifest,
first Deployment written by hand:

```yaml
apiVersion: apps/v1
kind: Deployment

metadata:
  name: deployment-demo

spec:
  replicas: 2
  selector:
    matchLabels:
      app: deploy-demo
  template:
    metadata:
      labels:
        app: deploy-demo
    spec:
      containers:
        - name: nginx
          image: nginx:1.27-alpine   # edited to 1.28-alpine mid-exercise, then rolled back
```

Correct on the first attempt.

---

## Lab Performed

1. Wrote and applied the Deployment; confirmed baseline `get
   deployment`/`get rs`/`get pods` state.
2. Attempted a rolling update — hit the same `unchanged` pattern as Day 09
   (unsaved edit), recognized immediately from prior experience, fixed.
3. Watched the real rolling update live via `rollout status`; confirmed
   the new ReplicaSet took over and all Pods moved to the new image.
4. Ran `rollout history`; noted the empty `CHANGE-CAUSE`.
5. Ran `rollout undo`; read the `last-applied-configuration` warning
   carefully rather than dismissing it as boilerplate; confirmed the
   rollback fully reverted both the ReplicaSet balance and the Pods'
   image.
6. Cleaned up.

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

A rolling update and a rollback both demonstrated live, with the
mechanism behind each step confirmed via `get rs`/`get pods`, not assumed.

## Actual Result

Matched, plus a real, informative warning message on `rollout undo` that
turned out to be directly relevant to an already-flagged open gap
(declarative vs imperative drift).

## What Worked

- Recognizing the `unchanged` pattern immediately from Day 09's journal
  entry, rather than re-diagnosing it from scratch, saved real time.
- Reading the `rollout undo` warning message in full, rather than treating
  it as routine noise, surfaced a genuine and useful caveat.

## What Failed

Nothing — the first `unchanged` result was the same known, harmless
pattern from Day 09, not a new failure.

---

## What I Broke

Nothing — the "unchanged" moment was an unsaved edit, immediately
recognized and fixed, not a break.

## Error Message

Not applicable — `unchanged` and the `rollout undo` warning are both
correct, informative, non-error output.

## Investigation

```bash
kubectl apply -f deployment-demo.yaml   # returned "unchanged" again
cat deployment-demo.yaml                # (implicitly) confirmed via vi re-edit
```

Recognized as the identical Day 09 pattern rather than treated as new.

## Root Cause

Unsaved edit before reapplying — same as Day 09.

## Solution

Re-edited and saved the file properly, then reapplied.

## Verification

Second `apply` returned `configured`; `rollout status` streamed real
progress; `get rs`/`get pods` confirmed the new image was actually live.

---

## Mistake

No `journal/mistakes-and-lessons.md` entry — the `unchanged` moment was a
recurrence of an already-understood pattern, not a new misunderstanding.

## Lesson Learned

1. A Deployment's rolling update is the Day 09 "new ReplicaSet generation"
   mechanism, now driven on purpose and watched live via `rollout status`,
   rather than found as leftover evidence.
2. `CHANGE-CAUSE` in `rollout history` is not automatic — it requires
   deliberately recording it, or it stays `<none>` forever.
3. `kubectl rollout undo` is imperative and does not update `kubectl
   apply`'s own diff-tracking annotation — a real, witnessed source of
   drift between the YAML file, the live object, and `apply`'s internal
   state, not just a hypothetical caution in a warning message.

## Troubleshooting Knowledge

```text
SYMPTOM: After `kubectl rollout undo`, a later `kubectl apply -f <file>`
         reports "unchanged" even though the live object clearly differs
         from what's in the file.
CHECK:   Has `rollout undo` (or `kubectl scale`, or any other imperative
         command) been used on this object since the last real `apply`?
COMMAND: kubectl get deployment <name> -o yaml   -- compare
         .metadata.annotations."kubectl.kubernetes.io/last-applied-configuration"
         against the live .spec, and against the YAML file on disk.
INTERPRETATION: `apply`'s "unchanged"/"configured" diff compares the new
         file against its OWN stored last-applied-configuration
         annotation -- not directly against the live object. Imperative
         commands (rollout undo, scale) change the live object without
         updating that annotation, so the three can genuinely disagree.
ROOT CAUSE: Mixing imperative commands with a declarative apply workflow
         on the same object.
FIX:     Treat the YAML file as the source of truth after any imperative
         change -- reapply it deliberately to resynchronize, or accept
         the imperative state and update the file to match.
PREVENTION: Prefer changing the YAML file and reapplying over imperative
         commands (`scale`, `rollout undo`) whenever the change should be
         durable and repeatable, not just a one-off fix.
```

---

## Interview Questions

1. Structurally, what's different between a Deployment's `spec` and a
   ReplicaSet's? What's actually different in behavior?
2. What does `kubectl rollout status` do that `kubectl get pods -w`
   doesn't?
3. Why might `kubectl rollout history` show revisions with no useful
   `CHANGE-CAUSE`?
4. Why does `kubectl rollout undo` warn about
   `last-applied-configuration`, and what could go wrong if you ignore it?
5. After a rollback, is the ReplicaSet that comes back up a new object or
   the same one that existed before the update? How would you prove it?

## Challenge

Driving a full rolling-update-then-rollback cycle deliberately, predicting
each `get rs`/`get pods` result before checking it, and reading the
`rollout undo` warning as real information rather than routine noise
served as today's exercise.

---

## End-of-Day Status

| Item | State |
|---|---|
| Deployment written and applied, correct on first attempt | Done |
| Rolling update watched live via `rollout status` | Done |
| New ReplicaSet generation confirmed via `get rs`/`get pods` | Done |
| `rollout history` and its empty `CHANGE-CAUSE` understood | Done |
| `rollout undo` performed; rollback confirmed via `get rs`/`get pods` | Done |
| `last-applied-configuration` drift warning understood, not dismissed | Done |

## Next Session

Next journal file: `journal/daily/day-11-rollouts-and-rollback.md`

1. Run the resume ritual (`git pull`, `current-progress.md`,
   `check-dependencies.sh`, check `SystemInfo.md` for this machine).
2. Day 11 — Rollout history, rollback, update strategies (deeper than
   today's introduction — `maxSurge`/`maxUnavailable` tuning, rollback to
   a specific revision, `Recreate` vs `RollingUpdate`).
