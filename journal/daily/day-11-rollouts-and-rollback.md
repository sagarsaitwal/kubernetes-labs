# Day 11 — Rollout History, Rollback, Update Strategies

Author: Sagar Saitwal

| | |
|---|---|
| **Date** | 2026-09-29 |
| **Day** | 11 |
| **Module** | 02 — Workloads |
| **Topic** | Rollout history, rollback, update strategies |
| **Status** | COMPLETED |
| **Cluster** | `k8s-lab` — 3 nodes, Kubernetes v1.37.0, kind v0.33.0 (on `IT-SAGARS`) |

---

## Today's Objective

Go deeper than Day 10: roll back to a *specific* revision, not just the
previous one, with `CHANGE-CAUSE` actually meaning something this time; and
directly contrast `RollingUpdate` against `Recreate` by watching both
strategies handle the same kind of change.

## Module

02 — Workloads

## Section

Deployments — rollout mechanics

## Topic

`kubectl rollout undo --to-revision=N`; `kubectl annotate ...
change-cause`; `spec.strategy.type: Recreate` vs `RollingUpdate`

## Subtopic

A leftover-file-state gotcha (Day 10's `rollout undo` never touched the
YAML); rollback itself is a rolling update, just targeting an existing
ReplicaSet; `Recreate`'s real availability gap, watched live

---

## Theory Learned

**`kubectl rollout undo --to-revision=N` jumps directly to any revision
still in history**, skipping intermediate ones entirely — different from
plain `undo`, which only ever goes one step back.

**`CHANGE-CAUSE` requires deliberate recording** —
`kubectl annotate deployment <name> kubernetes.io/change-cause="..." --overwrite`
right after each `apply` that should be remembered. Without it, `rollout
history` is just a list of anonymous revision numbers.

**A real, unplanned confirmation of Day 10's finding, hitting immediately
today:** the `deployment-demo.yaml` file was still at `1.28-alpine` from
Day 10, because `kubectl rollout undo` (imperative) never touched it. The
first `apply` today silently created the Deployment on `1.28-alpine`, not
`1.27-alpine` as assumed — caught via `unchanged` on the next reapply
attempt (a third occurrence of the exact Day 09/10 pattern, recognized
instantly), then confirmed with a direct `custom-columns` check rather
than continuing on assumption.

**Rollback is not a separate mechanism — it's the identical rolling-update
engine, just pointed at an already-existing ReplicaSet instead of a
freshly created one.** Running `rollout undo --to-revision=1` produced a
transient **3-Pod** state — the same `maxSurge` behavior from any ordinary
rolling update — while the reactivated ReplicaSet (`7c589f7d94`, the exact
same object and hash from Day 10) scaled up and the current one scaled
down. Confirmed hash-determinism (Day 09) held even across the Deployment
being deleted and recreated between sessions.

**`spec.strategy.type: Recreate` produces a real, visible availability
gap — watched directly, not inferred.** Both old Pods reached `Terminating`
→ `Completed` **together**, and only *after* both were fully gone did the
new Pods even reach `Pending`. There was a genuine window with **zero**
Pods `Ready`. Direct contrast with `RollingUpdate`'s behavior (old and new
coexisting the whole time, `READY` never dropping below desired count) —
opposite risk profiles for the same goal.

## Why It Matters

Targeted rollback matters the moment "the previous version" isn't the safe
one to return to — a real operational scenario, not an edge case.
Understanding that rollback reuses the rolling-update mechanism (rather
than being special-cased) means everything already known about
`maxSurge`/pacing applies to rollbacks too. Knowing `Recreate`'s real cost
concretely (not just "it's more disruptive") is what makes the trade-off
an informed choice rather than a guess.

---

## Commands Used

### `kubectl annotate deployment deployment-demo kubernetes.io/change-cause="..." --overwrite`

- **What it does:** records a human-readable reason on the Deployment,
  attached to whichever revision is current at that moment.
- **Actual effect:** turned `rollout history`'s `CHANGE-CAUSE` column from
  3× `<none>` (Day 10) into 3 real descriptions.

### `kubectl rollout history deployment/deployment-demo`

- **Actual output:**
  ```text
  REVISION  CHANGE-CAUSE
  1         deploy nginx 1.28 (initial)
  2         downgrade to nginx 1.27
  3         add DEMO_VERSION env var
  ```

### `kubectl rollout undo deployment/deployment-demo --to-revision=1`

- **What it does:** rolls back directly to revision `1`, skipping `2`
  entirely.
- **Actual output:** the same `last-applied-configuration` warning from
  Day 10 (expected, same imperative-command category); a transient 3-Pod
  state (`maxSurge` in action); settled to exactly 2 Pods on
  `1.28-alpine`, no `DEMO_VERSION` — confirmed revision 2 was never
  touched.

### `kubectl exec <pod> -- printenv DEMO_VERSION`

- **Why I used it:** confirm the env var was genuinely live before the
  rollback, not just present in the manifest.
- **Actual output:** `v3`.

### `kubectl apply -f deployment-demo.yaml` (with `strategy.type: Recreate` + image change)

- **Actual output:** `deployment.apps/deployment-demo configured`, followed
  by the full `Recreate` sequence — both old Pods `Terminating` →
  `Completed` together, then both new Pods `Pending` →
  `ContainerCreating` → `Running`, only after the old ones were fully gone.

### `kubectl delete deployment deployment-demo`

- Cleanup.

---

## YAML / Configuration

`fundamentals/labs/deployment-demo.yaml` — reused and evolved through 4
real states this session (revision 1 through 3, plus the `Recreate`
variant):

```yaml
apiVersion: apps/v1
kind: Deployment

metadata:
  name: deployment-demo

spec:
  replicas: 2
  strategy:
    type: Recreate
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
          image: nginx:1.27-alpine
          env:
            - name: DEMO_VERSION
              value: "v3"
```

(Final on-disk state, `Recreate` strategy demonstration — the `env` block
was left over from revision 3 and produced the same template hash again,
noted but not chased further since it didn't affect the strategy contrast.)

---

## Lab Performed

1. Recreated `deployment-demo`; discovered the file was already at
   `1.28-alpine` from Day 10 (leftover, since `rollout undo` never touches
   files) — corrected the plan rather than fighting the assumption.
2. Built 3 real, annotated revisions (`1.28-alpine` → `1.27-alpine` →
   `1.27-alpine` + env var), confirming each with `custom-columns`.
3. Used `rollout undo --to-revision=1` to skip revision 2 entirely;
   confirmed via image, env var absence, and a caught-mid-transition
   3-Pod surge state.
4. Added `strategy.type: Recreate`, changed the image again, and watched
   the full stop-then-start sequence live via `-w`.
5. Cleaned up.

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

Targeted rollback to a specific, non-adjacent revision, and a direct,
observed contrast between `RollingUpdate` and `Recreate`.

## Actual Result

Matched, plus a real, unplanned recurrence of the file/live-state drift
issue right at the start, corrected through evidence rather than
assumption.

## What Worked

- Recording `CHANGE-CAUSE` before each change made `rollout history`
  genuinely informative for the first time this course.
- Predicting the Pod-count direction (above vs. below desired) before each
  strategy's watch output made the `RollingUpdate`/`Recreate` contrast a
  real confirm-or-correct check, not passive observation.

## What Failed

The first `apply` created the Deployment on the wrong assumed image
(`1.28-alpine` instead of `1.27-alpine`) because the file was stale from
Day 10 — caught via `unchanged`, not discovered later as a confusing
result.

---

## What I Broke

Nothing — the stale-file issue was corrected before it affected the
exercise's conclusions, and both strategy demonstrations behaved exactly
as predicted.

## Error Message

Not applicable — `unchanged` and the `rollout undo` warning were both
correct, informative, non-error output, same category as Day 09/10.

## Investigation

```bash
kubectl get pods -l app=deploy-demo -o custom-columns='NAME:.metadata.name,IMAGE:.spec.containers[0].image'
```
Used to ground the actual live image in evidence rather than continuing on
the assumption that revision 1 was `1.27-alpine`.

## Root Cause

`kubectl rollout undo` (Day 10) is imperative and never touched
`deployment-demo.yaml` — the file stayed at whatever it was last edited
to, independent of the live object's rolled-back state.

## Solution

Confirmed the real live image, relabeled the annotation accurately, and
adjusted the planned revision sequence to still produce 3 genuinely
distinct states.

## Verification

`rollout history` showed 3 meaningful, accurate `CHANGE-CAUSE` entries;
the targeted rollback and the `Recreate` demonstration both produced
exactly the predicted results.

---

## Mistake

No `journal/mistakes-and-lessons.md` entry — the stale-file issue was a
direct, already-understood consequence of Day 10's own documented finding
(imperative commands not updating the YAML file), not a new
misunderstanding.

## Lesson Learned

1. `kubectl rollout undo` (any form) never touches the YAML file — always
   verify the file's actual assumed starting state with a real command
   before building a multi-step exercise on top of it.
2. Rollback uses the same rolling-update mechanism as any other update —
   `maxSurge` applies to it too, which is why a rollback can transiently
   show more Pods than desired, exactly like a forward rollout.
3. `Recreate`'s cost is a real, measurable window of zero available Pods,
   not an abstract warning — worth choosing deliberately, not by default.

## Troubleshooting Knowledge

```text
SYMPTOM: Applied a manifest expecting one starting state, but the created
         object is on a different image/config than expected.
CHECK:   What does the file on disk actually contain right now, verified
         directly?
COMMAND: cat <file>
         kubectl get pods -l <selector> -o custom-columns='...'
INTERPRETATION: Any earlier imperative command (kubectl scale, kubectl
         rollout undo) on this object may have left the live cluster in a
         state the YAML file was never updated to match. The file only
         ever reflects the last thing YOU edited and saved into it.
ROOT CAUSE: Imperative/declarative drift, carried over from a previous
         session or exercise.
FIX:     Verify the real current state before planning further steps
         around an assumed one; adjust the plan to the evidence, not the
         other way around.
PREVENTION: After any imperative command, treat the YAML file as
         out-of-date until proven otherwise -- don't assume it reflects
         the live object just because it was correct when last written.
```

---

## Interview Questions

1. What's the practical difference between `kubectl rollout undo` and
   `kubectl rollout undo --to-revision=N`?
2. Why is `CHANGE-CAUSE` empty by default, and what makes it populated?
3. Why can a rollback transiently show more Pods than the Deployment's
   desired replica count?
4. What specifically does `Recreate` cost that `RollingUpdate` doesn't,
   and when would that cost be worth paying?
5. If a Deployment's `rollout undo` was used since the last real `apply`,
   what should you check before trusting the YAML file's contents?

## Challenge

Building a real, 3-revision history with meaningful `CHANGE-CAUSE` text,
performing a targeted (non-adjacent) rollback, and directly observing the
`Recreate` availability gap — including correcting course mid-exercise
when the assumed starting state turned out to be wrong — served as
today's exercise.

---

## End-of-Day Status

| Item | State |
|---|---|
| 3 annotated revisions built, `CHANGE-CAUSE` meaningful | Done |
| Targeted rollback (`--to-revision=1`, skipping revision 2) proven | Done |
| Rollback confirmed to use the same rolling-update mechanism (`maxSurge`) | Done |
| `Recreate` strategy's real availability gap watched live | Done |
| Stale-file assumption caught and corrected via direct evidence | Done |

## Next Session

Next journal file: `journal/daily/day-12-daemonsets-jobs-cronjobs.md`

1. Run the resume ritual (`git pull`, `current-progress.md`,
   `check-dependencies.sh`, check `SystemInfo.md` for this machine).
2. Day 12 — DaemonSets, Jobs, CronJobs.
