# Day 06 — Pod Anatomy, YAML, Lifecycle, Phases

Author: Sagar Saitwal

| | |
|---|---|
| **Date** | 2026-09-22 |
| **Day** | 06 |
| **Module** | 01 — Kubernetes Fundamentals |
| **Topic** | Pod anatomy, YAML, lifecycle, phases |
| **Status** | COMPLETED |
| **Cluster** | `k8s-lab` — 3 nodes, Kubernetes v1.37.0, kind v0.33.0 (on `IT-SAGARS`) |

---

## Today's Objective

Write a Pod manifest by hand for the first time (every prior day reused
`nginx-deployment.yaml` unmodified), apply it, observe the Pod-level phase
vs. container-level state distinction directly, then prove — by deleting it
— that a bare Pod has no controller watching over it.

## Module

01 — Kubernetes Fundamentals

## Section

Pods

## Topic

Pod anatomy (minimum required YAML fields), Pod lifecycle phases, container
state

## Subtopic

A bare Pod's lack of a controller; admission injecting tolerations onto any
Pod, not just controller-created ones

---

## Theory Learned

**A Pod is the smallest deployable unit — a wrapper around one or more
containers sharing a network namespace** (same IP, reachable over
`localhost`) and, optionally, storage volumes. On plain Docker this sharing
only happens if containers are explicitly composed together; inside a Pod
it's the default.

**The minimum valid Pod manifest needs exactly 6 fields:** `apiVersion: v1`
(Pod is a core resource, no group prefix, unlike `apps/v1` for Deployment),
`kind: Pod`, `metadata.name`, and per container: `name` and `image`. Labels
are optional but are what make an object selectable later (Day 05).

**A Deployment's `spec.template` is literally a Pod spec, embedded.**
Having now written one standalone, the shape inside `nginx-deployment.yaml`
is recognizable as the exact same structure, just nested one level deeper
under a Deployment's own `spec`.

**Pod-level `status.phase` and container-level state are two different
signals.** Phase (`Pending`/`Running`/`Succeeded`/`Failed`/`Unknown`) is
coarse. Container state (`Waiting`/`Running`/`Terminated`, visible under
`describe`'s `Containers:` block or `-o yaml`'s `status.containerStatuses`)
is per-container and carries a reason/exit code. A Pod can report one phase
while its container state carries the actual explanation.

**A bare Pod has no controller.** Confirmed by direct deletion: after
`kubectl delete pod manual-pod`, `kubectl get pods` showed only the
pre-existing `nginx-trace` Pods — nothing replaced it. Contrast with any
`nginx-trace` Pod, which the ReplicaSet controller would replace within
seconds of deletion.

**Admission's toleration injection (Day 03) applies to *any* Pod creation,
not just ones created via a Deployment/ReplicaSet.** `manual-pod`'s
`describe` output carried the identical two `NoExecute` tolerations seen on
`nginx-trace` — proof this is the API server acting on the Pod object
itself during admission, regardless of what created it.

**A cached image skips the `Pending` phase almost entirely.** The watch
never caught a meaningful `Pending` state — `nginx:1.27-alpine` was already
present on `k8s-lab-worker` from `nginx-trace` running there since
Day 03/04, so there was nothing to pull. `Pending` is largely about
waiting on exactly that kind of thing when it's actually needed.

## Why It Matters

Understanding the bare Pod shape is what makes a Deployment's `template`
block legible as "a Pod spec, plus a controller," rather than an opaque
piece of syntax. The no-controller finding is also the direct motivation
for why Deployments exist at all — a Pod alone gives you none of the
self-healing behavior every prior day's `nginx-trace` exercises relied on
without naming it.

---

## Commands Used

### `kubectl apply -f manual-pod.yaml`

- **What it does:** creates the Pod object from the hand-written manifest.
- **Expected / Actual output:** `pod/manual-pod created`.

### `kubectl get pod manual-pod` / `kubectl get pod manual-pod -w`

- **What it does:** the first is a single snapshot; `-w` streams status
  changes live.
- **Actual output:** `Running` almost immediately (11s), since the image
  was already cached — no meaningful `Pending` window to observe. The watch
  later showed `Terminating` → `Completed` at `102s`, which turned out to
  be the `delete` command run concurrently in a second terminal reaching
  this Pod — not a separate, unexplained event (see Investigation).

### `kubectl describe pod manual-pod`

- **What it does:** full detail, including per-container `State:`,
  separate from the Pod-level `Status:` line above it.
- **Actual output:** `Status: Running`; under `Containers: nginx:`,
  `State: Running`, `Started: ...`, `Restart Count: 0`. Also surfaced,
  unprompted: the same two `NoExecute` tolerations from Day 03/04, a
  `kube-api-access` token volume auto-mounted from the `default`
  ServiceAccount, and `QoS Class: BestEffort` — all previewed briefly, none
  taught in full today (Tolerations already covered; ServiceAccounts is
  Day 42; requests/limits/QoS is Day 29).

### `kubectl delete pod manual-pod`

- **What it does:** deletes the Pod object directly.
- **Why I used it:** the actual point of the exercise — prove nothing
  recreates a bare Pod.
- **Expected output:** the Pod disappears and stays gone.
- **Actual output:** `pod "manual-pod" deleted from default namespace`,
  confirmed by the next command.

### `kubectl get pods`

- **Actual output:** only the 3 pre-existing `nginx-trace` Pods —
  `manual-pod` did not come back. Confirms the no-controller finding
  directly.

---

## YAML / Configuration

`fundamentals/labs/manual-pod.yaml` — **first manifest written by hand this
course**, not reused or copied:

```yaml
apiVersion: v1
kind: Pod

metadata:
  name: manual-pod
  labels:
    app: manual-pod

spec:
  containers:
    - name: nginx
      image: nginx:1.27-alpine
```

Correct on the first attempt — every required field present, nothing
extraneous.

---

## Lab Performed

1. Written manifest reviewed before applying (structure checked against the
   6 required fields, one filename typo caught and fixed — `manua-pod.yaml`
   → `manual-pod.yaml` — before it propagated into later commands).
2. Applied; watched for a `Pending` window (none meaningful — image
   already cached on this node).
3. `describe`'d while `Running`, read the container-level `State:` block
   specifically, separate from the Pod-level `Status:`.
4. Deleted, confirmed via `kubectl get pods` that nothing replaced it.

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

A hand-written Pod manifest applies cleanly, its container-level state is
distinguishable from its Pod-level phase, and deleting it proves no
controller recreates it.

## Actual Result

Matched exactly. One apparent anomaly (a `Terminating`/`Completed`
transition appearing in a `-w` watch before any `delete` command had
seemingly been run) was resolved as a two-terminal timing artifact, not a
real finding — see Investigation.

## What Worked

- Reviewing the manifest before applying caught a filename typo early,
  before it could cause confusion in later commands.
- Running `describe` and `delete` in a second terminal while the first kept
  watching turned into an unplanned but accurate demonstration of how
  `kubectl get -w` reflects changes made from anywhere, not just the same
  session.

## What Failed

Nothing. The one thing that looked like a failure (watch showing
`Terminating` seemingly out of nowhere) was fully explained, not a real
break — see below.

---

## What I Broke

Nothing broke. The one moment worth documenting precisely, because it
looked confusing in the terminal at the time:

## Error Message

Not applicable — no error, just an unexplained-looking state transition in
a live watch.

## Investigation

```bash
# Session 1 (kept running throughout):
kubectl get pod manual-pod -w

# Session 2 (run afterward, concurrently):
kubectl describe pod manual-pod
kubectl delete pod manual-pod
kubectl get pods
```

Session 1's watch showed `manual-pod` transition straight from `Running` to
`Terminating` to `Completed` at the `102s` mark, with no `delete` command
having visibly been run yet in the pasted transcript order. Re-reading both
sessions' commands against their actual timestamps resolved it: `describe`
(session 2) ran while the Pod was still healthy (`Events` showed it only
`57s` old at that point), and `delete` (session 2, run right after) is
exactly what session 1's watch picked up moments later. Two terminals
watching/acting on the same object will interleave this way — not a
Kubernetes anomaly, just parallel sessions.

## Root Cause

Not a defect — a `kubectl delete` issued in one terminal is naturally
visible, with a short delay, to a `kubectl get -w` running in another.

## Solution

None needed. Documented so the pattern is recognizable next time two
terminals are used against the same object.

## Verification

`kubectl get pods` after the delete showed only the pre-existing
`nginx-trace` Pods — `manual-pod` genuinely gone, matching both terminals'
final state.

---

## Mistake

No `journal/mistakes-and-lessons.md` entry — nothing was actually broken or
misunderstood. The filename typo was caught and fixed before it caused any
downstream confusion, and the watch/delete timing was explained, not a real
error.

## Lesson Learned

1. A Deployment's `spec.template` is a Pod spec — recognizing that shape
   directly, after writing a standalone one, makes Deployment YAML read as
   "familiar plus a controller" instead of new syntax.
2. Pod-level phase and container-level state are separate signals; the
   phase alone can be too coarse to explain what a specific container is
   actually doing.
3. A cached image can make `Pending` nearly invisible — the phase reflects
   real waiting, not a mandatory step every Pod passes through visibly.
4. `kubectl get -w` in one terminal reflects actions taken in any other
   terminal against the same object, with a short delay — worth recognizing
   before assuming an unexplained transition is a bug.

## Troubleshooting Knowledge

```text
SYMPTOM: A `kubectl get <type> -w` watch in one terminal shows a state
         transition (e.g. Terminating) with no apparent cause.
CHECK:   Was a mutating command (delete, apply, scale, rollout) run
         against the same object in a different terminal or session?
COMMAND: kubectl describe <type> <name>   -- check Events' timestamps
         against when each command was actually run in every terminal.
INTERPRETATION: A live watch reflects the object's real state regardless
         of which session changed it — it is not scoped to "this
         terminal's own actions."
ROOT CAUSE: Multiple terminals/sessions acting on the same cluster object
         concurrently.
FIX:     Not a bug to fix — reconstruct the actual command order across
         all sessions involved before concluding something unexpected
         happened.
PREVENTION: When running a live watch alongside other commands, keep track
         of what's being run in every terminal, not just the one being
         watched.
```

---

## Interview Questions

1. What is the minimum set of fields a valid Pod manifest needs?
2. What does a Deployment's `spec.template` actually contain, structurally?
3. What's the difference between a Pod's `status.phase` and a container's
   `state`, and why can't one substitute for the other?
4. Why might a Pod skip a visible `Pending` phase almost entirely?
5. If you delete a bare Pod versus a Pod owned by a Deployment, what's the
   observable difference?
6. Why did admission inject the same tolerations onto a bare Pod that it
   injected onto a Deployment-managed one on Day 03?

## Challenge

Writing and applying the first hand-authored manifest of the course served
as today's exercise; the "delete and observe nothing recreates it" step was
the deliberate proof of the day's core lesson.

---

## End-of-Day Status

| Item | State |
|---|---|
| First hand-written YAML — written, structurally correct on first attempt | Done |
| Pod applied, reached `Running` | Done |
| Pod-level phase vs. container-level state distinguished via `describe` | Done |
| No-controller finding proven by deletion | Done |
| Watch/delete timing artifact investigated and explained | Done |

## Next Session

Next journal file: `journal/daily/day-07-multi-container-pods.md`

1. Run the resume ritual (`git pull`, `current-progress.md`,
   `check-dependencies.sh`, check `SystemInfo.md` for this machine).
2. Day 07 — Multi-container Pods, sidecars, init containers.
