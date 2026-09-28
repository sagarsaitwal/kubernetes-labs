# Day 08 — Pod Failures: Pending, CrashLoopBackOff, ImagePullBackOff

Author: Sagar Saitwal

| | |
|---|---|
| **Date** | 2026-09-28 |
| **Day** | 08 |
| **Module** | 02 — Workloads |
| **Topic** | Pod failures: `Pending`, `CrashLoopBackOff`, `ImagePullBackOff` (break/fix) |
| **Status** | COMPLETED |
| **Cluster** | `k8s-lab` — 3 nodes, Kubernetes v1.37.0, kind v0.33.0 (on `IT-SAGARS`) |

---

## Today's Objective

A dedicated break/fix day — deliberately trigger `Pending` and
`CrashLoopBackOff` (not `ImagePullBackOff`, already solidly proven on Day 04
and Day 07) and diagnose each with real evidence, finally giving the
`Pending`/`Failed` phases deferred since Day 06 their direct treatment.

## Module

02 — Workloads

## Section

Pod troubleshooting

## Topic

Scheduling failure (`Pending`); container crash-restart backoff
(`CrashLoopBackOff`)

## Subtopic

`resources.requests` (minimal introduction); QoS class `Burstable`;
`spec.restartPolicy` default (`Always`); `kubectl logs --previous`;
container log retention limits

---

## Theory Learned

**`Pending` can mean two structurally different things: never scheduled, or
scheduled but stuck starting.** `describe`'s `Node:` field distinguishes
them immediately — empty means the scheduler never placed it.

**`spec.containers[].resources.requests` is what the scheduler filters
nodes against, before ever scoring them.** An impossible request (`100Gi`
memory) guarantees no node qualifies — a clean, reproducible `Pending` with
no external interference (no Zscaler, no real bug).

**The scheduler evaluates every applicable rule for every node
simultaneously, and reports each node's specific reason — not just "no
capacity anywhere."** `pending-demo`'s Events showed **two independent
failure reasons across 3 nodes**: 1 excluded by the control-plane's
`NoSchedule` taint (Day 03's mechanism, recurring), 2 excluded by
`Insufficient memory` (the reason actually engineered). This is a richer,
more accurate model than "not enough room" — multiple filters can fail at
once, on different nodes, for different reasons.

**`QoS Class` is a direct, checkable consequence of what `resources` fields
are set — not a manually chosen setting.** `BestEffort` (no
requests/limits at all, seen Day 06 and again on `crash-demo`) vs.
`Burstable` (requests set without matching limits, seen on `pending-demo`)
vs. `Guaranteed` (requests == limits, not yet demonstrated) — full depth is
Day 29, but the distinguishing rule is now concrete.

**`spec.restartPolicy` (Pod-level, default `Always`, present on every Pod
so far without ever mattering) restarts a container after *any* exit —
success or failure — unless a container-specific rule applies.** This is
exactly the mechanism that turns one crash into a *loop*: the container
exits, `Always` says bring it back, it exits again, immediately, until the
kubelet's own exponential backoff on restarts (not just pulls — the same
mechanism, different trigger) starts spacing attempts out. Confirmed
directly: restart gaps grew from `12s` to `30s` to `50s` in the live watch.

**Pod-level phase and container-level state can look almost contradictory,
for real, not just in theory.** `crash-demo`'s `describe` showed `Status:
Running` at the top while `Containers: crasher: State: Waiting, Reason:
CrashLoopBackOff` directly below it — the exact Day 06 distinction,
recurring as the actual explanation for a confusing-looking status instead
of a hypothetical.

**`kubectl logs --previous` only works if the runtime still retains the
prior terminated instance's log — and it doesn't keep unlimited history.**
By the 4th restart, `--previous` returned `unable to retrieve container
logs`, not log content. The runtime (containerd, on a lightweight `kind`
node) had already pruned at least one earlier instance's logs. `--previous`
gets exactly one generation back, and even that isn't guaranteed to still
exist by the time you ask.

## Why It Matters

`Pending` and `CrashLoopBackOff` are two of the most common real-world
symptoms, and both were reproduced with a root cause that was *engineered*,
not guessed — the same discipline applied to every incident since Day 04.
The `--previous` limitation specifically matters for real incidents: it
means grabbing crash logs early, before more restarts prune the evidence
you need.

---

## Commands Used

### `kubectl apply -f pending-demo.yaml`

- **Expected / Actual output:** `pod/pending-demo created`.

### `kubectl get pod pending-demo`

- **Actual output:** `STATUS: Pending`, `READY: 0/1` — no node assigned.

### `kubectl describe pod pending-demo`

- **What it does:** full detail; here, the `Events:` section is where the
  scheduler explains *why* placement failed.
- **Actual output:**
  ```text
  Warning  FailedScheduling  0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 Insufficient memory. preemption: 0/3 nodes are available: 3 Preemption is not helpful for scheduling.
  ```
  Richer than predicted — two independent reasons, not one; see Theory
  Learned.

### `kubectl delete pod pending-demo`

- Cleanup once the exercise's evidence was captured.

### `kubectl apply -f crash-demo.yaml`

- **Expected / Actual output:** `pod/crash-demo created`.

### `kubectl get pod crash-demo -w`

- **Actual output:** repeating cycle — `CrashLoopBackOff` → `Running` →
  `Error` → `CrashLoopBackOff`, `RESTARTS` climbing 1→2→3→4, restart-gap
  timestamps growing `12s`→`30s`→`50s` (exponential backoff, directly
  observed).

### `kubectl describe pod crash-demo`

- **Actual output:** `Status: Running` (Pod-level) alongside `State:
  Waiting, Reason: CrashLoopBackOff` (container-level) — the Day 06
  phase/state distinction, recurring for real. `Last State: Terminated,
  Reason: Error, Exit Code: 1` matched the manifest's `exit 1` exactly.
  Events: `Created`/`Started` `(x5 over 2m41s)`, `BackOff ...` `(x6 over
  2m40s)` — the `(xN over duration)` counting format from Day 01/02,
  reused, not new syntax.

### `kubectl logs crash-demo`

- **Actual output:** `I am about to crash` — current attempt only.

### `kubectl logs crash-demo --previous`

- **Actual output:** `unable to retrieve container logs for
  containerd://...` — not log content. See Theory Learned: the runtime had
  already pruned the prior instance's logs by the 4th restart.

### `kubectl delete pod crash-demo`

- Cleanup.

---

## YAML / Configuration

`fundamentals/labs/pending-demo.yaml` — third hand-written manifest:

```yaml
apiVersion: v1
kind: Pod

metadata:
  name: pending-demo

spec:
  containers:
    - name: nginx
      image: nginx:1.27-alpine
      resources:
        requests:
          memory: "100Gi"
```

`fundamentals/labs/crash-demo.yaml` — fourth hand-written manifest:

```yaml
apiVersion: v1
kind: Pod

metadata:
  name: crash-demo

spec:
  containers:
    - name: crasher
      image: busybox:1.36
      command:
        - sh
        - -c
        - echo I am about to crash; exit 1
```

Both correct on the first attempt.

---

## Lab Performed

1. Wrote and applied `pending-demo.yaml` (impossible memory request);
   diagnosed the exact scheduling-failure reason via `describe`'s Events;
   found it was actually two independent reasons, not one; cleaned up.
2. Wrote and applied `crash-demo.yaml` (guaranteed-crash command); watched
   the full backoff cycle live; diagnosed via `describe` (Pod phase vs.
   container state) and both `logs` variants (including the `--previous`
   log-retention limitation); cleaned up.
3. Deliberately did **not** re-trigger `ImagePullBackOff` — already
   thoroughly proven with real incidents on Day 04 and Day 07.

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

`Pending` and `CrashLoopBackOff` both reproduced deliberately and diagnosed
with real evidence; `ImagePullBackOff` treated as already covered.

## Actual Result

Matched, with two findings richer than predicted: the multi-reason
scheduling failure, and the `--previous` log-retention limitation.

## What Worked

- Using an impossible `resources.requests` value produced a clean, 100%
  reproducible `Pending` with zero external interference — no Zscaler,
  no ambiguity about cause.
- `exit 1` in a `sh -c` command produced an equally clean, deterministic
  `CrashLoopBackOff` on demand.

## What Failed

Nothing — both exercises worked as designed. The `--previous` command
"failing" was itself the intended lesson, not an unplanned problem.

---

## What I Broke

Nothing — both failures were deliberately engineered for this exercise, not
accidental breaks.

## Error Message

```text
0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 Insufficient memory. preemption: 0/3 nodes are available: 3 Preemption is not helpful for scheduling.
```

```text
unable to retrieve container logs for containerd://c93f14f917880fc73634fde081e3fe69e21bc8ad781109d88b64fd2f19d585dc
```

## Investigation

Both root causes were known in advance (deliberately engineered), so
"investigation" here means confirming the *mechanism* matched the
prediction:

```bash
kubectl describe pod pending-demo   # confirmed scheduler-level, multi-reason
kubectl describe pod crash-demo     # confirmed kubelet-level, backoff visible
kubectl logs crash-demo --previous  # confirmed runtime log-retention limit
```

## Root Cause

`pending-demo`: an unschedulable resource request, compounded by the
pre-existing control-plane taint. `crash-demo`: a container whose command
always exits non-zero, restarted forever by the Pod's default
`restartPolicy: Always`.

## Solution

Both were deliberate demonstrations, not incidents to fix — cleaned up via
`kubectl delete pod` once each exercise's evidence was captured.

## Verification

`pending-demo`'s Events named the exact scheduling filters that failed;
`crash-demo`'s `RESTARTS` count and growing backoff timestamps matched the
predicted mechanism exactly.

---

## Mistake

No `journal/mistakes-and-lessons.md` entry — nothing was misunderstood.
Both engineered failures behaved as predicted, with additional real detail
(multi-reason scheduling, log-retention limit) rather than a wrong
prediction.

## Lesson Learned

1. The scheduler reports every node's specific failure reason
   independently — a `Pending` Pod can fail for more than one reason at
   once, across different nodes.
2. `QoS Class` is a direct, mechanical consequence of which `resources`
   fields are set, not a separate setting to choose.
3. `spec.restartPolicy: Always` (the unstated default on every Pod so far)
   restarts a container after *any* exit, success or failure — this is the
   literal mechanism that turns a single crash into a loop.
4. `kubectl logs --previous` is not a full crash history — it's exactly
   one generation back, and even that can already be gone by the time you
   ask, especially after several more restarts have occurred.

## Troubleshooting Knowledge

```text
SYMPTOM: A Pod stays Pending indefinitely.
CHECK:   Was it ever assigned a node?
COMMAND: kubectl describe pod <name>   -- check Node: and Events:
INTERPRETATION: Node: <none> means the scheduler never placed it -- read
         Events for FailedScheduling and every reason listed; a Pod can
         fail for MULTIPLE independent reasons across different nodes at
         once, not just one.
ROOT CAUSE: Commonly: resource requests no node can satisfy, an
         untolerated taint, or a nodeSelector/affinity rule with no match.
FIX:     Lower the request, add a toleration, or free capacity/add a node.
PREVENTION: Know each node's real allocatable resources before setting
         requests -- an ambitious request is functionally identical to a
         typo, from the scheduler's point of view.
```

```text
SYMPTOM: A Pod cycles through Running / Error / CrashLoopBackOff
         repeatedly, RESTARTS climbing.
CHECK:   What does the container actually do right before it exits?
COMMAND: kubectl describe pod <name>        -- Last State: Terminated,
         Exit Code, and the BackOff event's (xN over duration) count
         kubectl logs <name>                -- current attempt's output
         kubectl logs <name> --previous     -- prior attempt's output,
         IF the runtime still has it retained (not guaranteed)
INTERPRETATION: Pod-level Status: can say "Running" while the container's
         own State: says Waiting/CrashLoopBackOff -- read the container
         block specifically, not just the top line.
ROOT CAUSE: The container's own exit code and behavior -- restartPolicy:
         Always (the default) restarts it regardless, so the loop is
         inherent to the container failing, not a scheduling problem.
FIX:     Fix whatever the container's own logs/exit code point to --
         this is application-level, not cluster-level.
PREVENTION: Grab --previous logs as early as possible after a crash is
         noticed -- the runtime does not retain unlimited crash history,
         and it can already be gone after just a few more restarts.
```

---

## Interview Questions

1. A Pod is stuck `Pending`. What's the first field in `describe`'s output
   that tells you whether it's a scheduling problem at all?
2. Why can a single `Pending` Pod fail scheduling for more than one reason
   at once?
3. What determines whether a Pod's QoS class is `BestEffort`, `Burstable`,
   or `Guaranteed`?
4. Why does a container that exits with code `0` still get restarted under
   the default `restartPolicy`?
5. Why might `kubectl logs --previous` fail even though the Pod has clearly
   restarted multiple times?
6. A Pod's top-level `Status:` says `Running`. Does that guarantee its
   container is actually healthy right now? Why or why not?

## Challenge

Deliberately engineering both `Pending` (impossible resource request) and
`CrashLoopBackOff` (guaranteed-exit command), predicting the mechanism in
advance, and confirming it against real `describe`/`logs` output served as
today's exercise — including two findings that turned out richer than the
prediction.

---

## End-of-Day Status

| Item | State |
|---|---|
| `Pending` reproduced and diagnosed (scheduler-level) | Done — multi-reason finding |
| `CrashLoopBackOff` reproduced and diagnosed (kubelet-level) | Done |
| Pod-phase vs. container-state distinction recurred with real evidence | Done |
| `kubectl logs --previous` and its retention limit demonstrated | Done |
| `ImagePullBackOff` — confirmed already covered, not repeated | Done |

## Next Session

Next journal file: `journal/daily/day-09-replicasets.md`

1. Run the resume ritual (`git pull`, `current-progress.md`,
   `check-dependencies.sh`, check `SystemInfo.md` for this machine).
2. Day 09 — ReplicaSets and why you rarely write one.
