# Day 03 — Architecture and the Request Flow

Author: Sagar Saitwal

| | |
|---|---|
| **Date** | 2026-09-18 |
| **Day** | 03 |
| **Module** | 01 — Kubernetes Fundamentals |
| **Topic** | Architecture and the request flow |
| **Status** | COMPLETED |
| **Cluster** | `k8s-lab` — 3 nodes, Kubernetes v1.37.0, kind v0.33.0 (on `Nero`) |

---

## Today's Objective

Stop taking Lesson 01's 14-step `kubectl apply` theory on trust. Apply a real
Deployment to the live cluster and match each step to actual, observed
evidence instead.

## Module

01 — Kubernetes Fundamentals

## Section

Architecture

## Topic

The request flow: `kubectl` → API server → etcd → controllers → scheduler →
kubelet → container runtime

## Subtopic

Admission/defaulting made visible; scheduler filtering via taints; ReplicaSet
naming; closing the Day 02 CoreDNS-placement question

---

## Theory Learned

**Steps 6-14 of Lesson 01's flow are now backed by direct evidence, not just
diagram.** Applied `nginx-trace` (a plain 3-replica Deployment) and traced it
through `kubectl get rs`, `kubectl get pods`, and `kubectl describe pod`:

- Step 7 (Deployment → ReplicaSet): `kubectl get rs` showed one ReplicaSet,
  `nginx-trace-647575f7d8` — the same hash appears in the ReplicaSet's own
  name, every Pod's name, and every Pod's `pod-template-hash` label. One
  fingerprint, three places it shows up.
- Steps 9-10 (Pending → Scheduled): Pod `Events` named `default-scheduler`
  directly, same pattern as Day 02's `node-controller` discovery — a
  component name in `From:`, not just "the control plane."
- Steps 11-13 (pull, create, start): `Events` attributed to `kubelet`, with
  real timing — `8.699s` image pull, **10 seconds total** from Pod creation
  (`20:42:04`) to the container reporting `Started` (`20:42:14`).
- Step 14 (Running): `kubectl get pods` STATUS column.

**Step 4 (admission) turned out to be directly observable after all.** The
written manifest specified zero tolerations. The stored Pod object has two:
```
node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
```
injected by the `DefaultTolerationSeconds` admission plugin on the way
through the API server — the exact `tolerationSeconds: 300` mechanism from
Day 01's LAB 01 challenge, now seen sitting on a real Pod's spec instead of
being described in theory. The gap between "what was submitted" and "what
got persisted" *is* admission, made visible.

**Steps 1-3 (client encode/POST, authentication, authorization) and step 5
(the `etcd` write itself) remain theory-plus-inference.** No tooling yet to
observe these directly — deferred honestly to Day 39-41 (RBAC), Day 45 (a
real authorization denial), and Day 65 (`etcdctl`, not installed until Day
80 per `progress/dependencies.md`, so even later for hands-on `etcd` reads).

**The scheduler's node filtering, seen for the first time with a real Pod
that isn't a system component.** All three `nginx-trace` replicas landed on
`k8s-lab-worker`/`k8s-lab-worker2` — **none** on `k8s-lab-control-plane`.
`kubectl describe node k8s-lab-control-plane` explained why:
```
Taints:  node-role.kubernetes.io/control-plane:NoSchedule
```
An ordinary Deployment Pod has no toleration for this taint, so the
scheduler's filtering step excludes that node before scoring ever happens.

**This closes Day 02's open CoreDNS question.** `kubectl describe pod -n
kube-system coredns-...` shows CoreDNS explicitly tolerates the same taint:
```
Tolerations:  CriticalAddonsOnly op=Exists
              node-role.kubernetes.io/control-plane:NoSchedule
              node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
              node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
```
Day 02 established *that* both CoreDNS replicas landed on the control-plane
node and *why they stayed there* (scheduled once, never re-evaluated). Today
answers the missing piece: *why the control-plane node was ever an eligible
choice for CoreDNS at all*, when it demonstrably isn't for an ordinary
workload — CoreDNS is explicitly built to tolerate the taint that filters
everything else out.

**A useful distinction, surfaced by a coincidence:** the node reboot from
earlier in the session (Docker/WSL restart) had left visible traces on
CoreDNS's own Pod — `Restart Count: 2`, two `SandboxChanged` events, and
transient `503`/connection-refused readiness-probe failures while it came
back up. Its Pod's `Start Time`, however, was still the *original* creation
timestamp. That separates two different things that can look similar:
**`Restart Count`** tracks a container restarting *inside* a still-existing
Pod object; **`AGE`/`Start Time`** only changes if the Pod object itself is
deleted and recreated. `etcd`/`kube-apiserver` showing a freshly-reset `Age`
after the same reboot (noticed while reading the control-plane node's
`describe` output) is therefore a different, stronger event than what
happened to CoreDNS — worth keeping distinct, though *why* only some static
Pods got fully new objects on that reboot is still unresolved (flagged for
Day 68, kubelet/CRI internals, not chased today).

## Why It Matters

This is the same discipline Day 02 applied to the static-Pod bootstrap
claim, now applied to the request path itself: "created" (Lesson 01's step
6) is the *only* step `kubectl apply` waits for, and everything after it —
ReplicaSet creation, scheduling, image pull, container start — happens
asynchronously and can fail independently. Having watched all of that
actually happen, with real timing, makes "why is my Deployment stuck in
`Pending`" a diagnosable question later instead of a black box.

---

## Commands Used

### `kubectl apply -f fundamentals/labs/nginx-deployment.yaml`

- **What it does:** sends the manifest to the API server; declares desired
  state rather than issuing a one-time create.
- **Why `apply` and not `create`:** `apply` is idempotent — safe to re-run,
  it diffs against desired state rather than erroring if the object exists.
  This is the reconciliation loop from Lesson 01, made concrete.
- **Expected output:** `deployment.apps/nginx-trace created`.
- **Actual output:** exactly that.

### `kubectl get pods -o wide -w`

- **What it does:** live stream of Pod status changes, with the `NODE`
  column visible.
- **Why I used it:** to try to catch the transient `Pending`/
  `ContainerCreating` states before the Pods settled.
- **Actual output:** started too late — by the time it connected, all three
  Pods were already `78s` old and `Running`. Same pattern as Day 01's first
  node-failure attempt: the live watch missed the transition entirely.

### `kubectl describe pod <name>`

- **What it does:** full Pod detail, including the `Events` history, which
  persists even if nobody was watching live (~1hr default `event-ttl`).
- **Why I used it:** recover the transition evidence the watch missed —
  same technique, same lesson, as Day 02's `(x2 over 26m)` discovery.
- **Actual output:** full `Scheduled`/`Pulling`/`Pulled`/`Created`/`Started`
  sequence with real timestamps (see Theory Learned), plus the two
  auto-injected `Tolerations` not present in the written manifest.

### `kubectl get rs`

- **What it does:** lists ReplicaSets.
- **Why I used it:** direct confirmation of step 7 — the Deployment
  controller creating a ReplicaSet — which nothing else in this session's
  commands showed on its own.
- **Actual output:** `nginx-trace-647575f7d8   3   3   3   6m37s`.

### `kubectl describe node k8s-lab-control-plane`

- **What it does:** as used on Day 02 — taints, conditions, Lease, the Pods
  currently on this node, and its Event history.
- **Why I used it:** confirm the hypothesis that a control-plane taint
  explains why `nginx-trace` never scheduled there.
- **Actual output:** `Taints: node-role.kubernetes.io/control-plane:NoSchedule`
  — confirmed. Also surfaced the `Rebooted` event and the
  younger-`Age`-for-only-some-static-Pods observation (see Theory Learned).

### `kubectl describe pod -n kube-system coredns-<hash>`

- **What it does:** as used before, this time to read `Tolerations`
  specifically rather than `Events`.
- **Why I used it:** close the Day 02 open question — confirm CoreDNS
  explicitly tolerates the control-plane taint.
- **Actual output:** `CriticalAddonsOnly`, `node-role.kubernetes.io/control-
  plane:NoSchedule`, plus the same two `NoExecute` tolerations `nginx-trace`
  got automatically. Confirmed.

---

## YAML / Configuration

`fundamentals/labs/nginx-deployment.yaml` — written for this exercise (not
authored by Sagar; first hand-written YAML is Day 06):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-trace
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-trace
  template:
    metadata:
      labels:
        app: nginx-trace
    spec:
      containers:
        - name: nginx
          image: nginx:1.27-alpine
```

---

## Lab Performed

No dedicated `LAB 03` file exists yet — conducted directly, same pattern as
Day 02's node-failure challenge: apply a Deployment, miss the live watch
window, recover the evidence from `Events`, then follow two side questions
(the control-plane taint, and CoreDNS's toleration for it) that came
directly out of what the first evidence showed.

---

## Environment

| Item | Value |
|---|---|
| Kubernetes version | v1.37.0 (client and server) |
| Node count | 3 — 1 control-plane, 2 workers |
| Machine | `Nero` — WSL2 FedoraLinux-44, kernel 6.6.87.2 |
| Container runtime | containerd 2.3.4 |
| CNI | kindnet |

---

## Expected Result

Full 14-step theory confirmed with direct evidence for as many steps as
current tooling allows; the rest identified and honestly deferred.

## Actual Result

Matched. Steps 4 (partial), 6-14 all confirmed with real command output;
steps 1-3 and 5 explicitly deferred rather than assumed.

## What Worked

- The admission/defaulting proof came for free from a command run for a
  different reason (`describe pod`'s `Tolerations` block) — evidence was
  already on screen, same shape as Day 02's CoreDNS restart-count finding.
- Chasing the "why no Pods on control-plane" observation immediately, rather
  than filing it away, led directly to closing Day 02's open question in the
  same session.

## What Failed

The live watch (`kubectl get pods -o wide -w`) again started too late to
catch any transient state — not a new mistake, a repeat of a known pattern,
so not given its own `mistakes-and-lessons.md` entry.

---

## What I Broke

Nothing — inspection and one straightforward `apply`, no mutating commands
beyond creating the Deployment itself.

## Error Message

None.

## Investigation

Not applicable — nothing failed; the "investigation" here was retrospective
evidence-gathering (`describe`) after a missed live observation, not a fix
for a broken thing.

## Root Cause

N/A.

## Solution

N/A.

## Verification

Every claimed step backed by literal `kubectl`/`describe` output quoted in
Theory Learned and Commands Used above, not paraphrased from memory.

---

## Mistake

None new today — the missed watch window is the same pattern as Day 01's
first attempt, not a new failure mode.

## Lesson Learned

1. `kubectl describe`'s `Events` history is the reliable fallback whenever a
   live watch is started too late — this is now the second time it's
   recovered evidence a `-w` session missed.
2. Admission/defaulting doesn't need a special technique to observe — diff
   what was written against what `describe` shows was stored, and injected
   defaults show up on their own.
3. `Restart Count` (container-level) and `Age`/`Start Time` (Pod-object
   level) answer different questions and can diverge after the same
   underlying event — worth checking which one a symptom is actually about.

## Troubleshooting Knowledge

```text
SYMPTOM: A Deployment's Pods aren't landing where expected (or aren't
         landing on a specific node at all).
CHECK:   Does the target node have a taint this Pod doesn't tolerate?
COMMAND: kubectl describe node <name>        (Taints: line)
         kubectl describe pod <name>         (Tolerations: line)
INTERPRETATION: The scheduler filters out any node whose taints aren't
         tolerated, before scoring ever happens — a taint mismatch means
         the node was never a candidate, not that it lost on merit.
ROOT CAUSE: Missing (or mismatched) toleration for a taint present on the
         target node.
FIX:     Add the matching toleration to the Pod spec, or target a
         different, untainted node.
PREVENTION: When a workload needs to run somewhere unusual (e.g. a
         control-plane node), check that node's Taints first — most system
         add-ons that do this (CoreDNS included) carry an explicit
         toleration for exactly this reason.
```

---

## Interview Questions

1. `kubectl apply` prints `created`. Which of the 14 steps does that actually
   confirm, and which does it say nothing about?
2. What does the `DefaultTolerationSeconds` admission plugin do, and how
   would you prove it ran without reading Kubernetes source?
3. Why did all three `nginx-trace` replicas land on worker nodes and none on
   the control-plane node, when nothing in the manifest mentioned node
   placement at all?
4. Why is CoreDNS able to schedule onto the control-plane node when an
   ordinary Deployment Pod cannot?
5. What's the difference between a Pod's `Restart Count` and its `Age`, and
   what does each one actually tell you happened?

## Challenge

None issued for Day 03 specifically — the trace-and-verify exercise doubled
as the day's practical work, same pattern as Day 02.

---

## End-of-Day Status

COMPLETED

| Item | State |
|---|---|
| Steps 6-14 traced with real evidence | Done |
| Step 4 (admission) observed | Done |
| Steps 1-3, 5 identified and deferred | Done — honestly, not silently skipped |
| Day 02 CoreDNS open question closed | Done |
| Control-plane taint hypothesis confirmed | Done |

## Next Session

Next journal file: `journal/daily/day-04-kubectl-core.md`

1. Run the resume ritual (`git pull`, `current-progress.md`,
   `check-dependencies.sh`, check `SystemInfo.md` for this machine).
2. Day 04 — kubectl core verbs and output formats.
