# Current Kubernetes Learning Progress

Author: Sagar Saitwal

Last updated: 2026-09-18

> This file is the single source of truth for where the learning stopped.
> On any new session or new device, read this file FIRST.

**Current Day: 04**

> The line above is machine-readable. `scripts/utilities/check-dependencies.sh`
> parses it to decide which dependencies this day actually requires. Keep the
> exact format `Current Day: NN` when updating it.

---

## Machine this session ran on

**Nero** — see `SystemInfo.md` (repository root) for full per-machine tool
versions and the cross-machine dependency table. If the next session is on a
different machine, `kubectl`/`kind`/the cluster will legitimately be missing —
expected, not a failure. Recreate:

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

Day 03 COMPLETED. Day 04 — kubectl core verbs and output formats — **queued,
not started.** Teaching content was prepared and given in the previous
session (verb families, `kubectl explain`, output formats, `diff`/`dry-run`,
`logs`/`exec`), but **no commands were actually run** — session ended before
any hands-on work happened. Do not treat this as progress; resume from the
plan below.

## Current Subtopic

Day 04 has not started. Resume with the six queued commands below — the
explanation for each was already given last session; re-explain only if it's
been long enough that a refresher is warranted, otherwise go straight to
running them.

```bash
# 1. Full stored object — compare mentally against fundamentals/labs/nginx-deployment.yaml
kubectl get deployment nginx-trace -o yaml

# 2. Extract one exact field with jsonpath
kubectl get deployment nginx-trace -o jsonpath='{.spec.template.spec.containers[0].image}'

# 3. See admission's effect BEFORE creating anything (dry-run=server)
kubectl apply -f fundamentals/labs/nginx-deployment.yaml --dry-run=server -o yaml | grep -A3 tolerations

# 4. A custom table, sorted
kubectl get pods -o custom-columns='NAME:.metadata.name,NODE:.spec.nodeName,RESTARTS:.status.containerStatuses[0].restartCount' --sort-by='.status.containerStatuses[0].restartCount'

# 5. Read one Pod's logs
kubectl logs <one of the nginx-trace pods — check `kubectl get pods` for current names>

# 6. Run a command inside it
kubectl exec -it <same pod> -- cat /etc/nginx/nginx.conf
```

Note: `nginx-trace` was still running and healthy (3/3, 34m old) as of last
session, on `Nero`. Re-verify it's still there before assuming — if this
session is on a different machine or the cluster was recreated, it won't be.

## Learning Status

🟡 IN PROGRESS

Day 00, Day 01, Day 02, and Day 03 are all fully COMPLETED. Day 04 is next.

## Last Completed Lab

**Day 03 — traced `kubectl apply` through the live cluster.** COMPLETED.
Applied a plain `nginx-trace` Deployment; confirmed steps 6-14 of Lesson 01's
14-step flow with real `kubectl`/`describe` evidence, plus a partial
confirmation of step 4 (admission/defaulting, via auto-injected tolerations).
Also closed Day 02's open CoreDNS-placement question by confirming the
control-plane node's `NoSchedule` taint and CoreDNS's explicit toleration for
it.

## Last Commands Practiced

```bash
kubectl apply -f fundamentals/labs/nginx-deployment.yaml
kubectl get pods -o wide -w
kubectl describe pod <nginx-trace pod>
kubectl get rs
kubectl describe node k8s-lab-control-plane
kubectl describe pod -n kube-system <coredns pod>
```

## Last YAML Practiced

`fundamentals/labs/nginx-deployment.yaml` — written for the exercise, not
authored by Sagar (first hand-written YAML is still Day 06).

## What I Learned

- **`kubectl apply` is idempotent by design** — it diffs against desired
  state rather than erroring on an existing object, which is Lesson 01's
  reconciliation loop made concrete.
- **Admission/defaulting is directly observable** — diff what was written
  against what `kubectl describe` shows was stored. Our manifest specified
  zero tolerations; the stored Pod had two, injected by the
  `DefaultTolerationSeconds` admission plugin.
- **The scheduler filters nodes by taint before it ever scores them.** All
  three plain Deployment Pods landed only on workers — `k8s-lab-control-
  plane` carries `node-role.kubernetes.io/control-plane:NoSchedule`, which
  an ordinary Pod doesn't tolerate.
- **This closes Day 02's open question:** CoreDNS carries an explicit
  toleration for that exact taint, which is *why* it was ever eligible to
  land on the control-plane node in the first place.
- **`Restart Count` (container-level) and `Age`/`Start Time` (Pod-object
  level) are different signals** that can diverge after the same event — a
  container restarting inside an existing Pod is not the same as a new Pod
  object being created.

## What I Broke

Nothing — one straightforward `apply`, otherwise inspection only.

## Errors Encountered

None.

## Root Cause

N/A

## How It Was Fixed

N/A

## Mistakes Made

None new today. The live watch (`kubectl get pods -o wide -w`) again started
too late to catch a transient state — a repeat of a known pattern (Day 01),
not a new failure mode, so not given its own `mistakes-and-lessons.md` entry.

## Important Lessons

- `kubectl describe`'s `Events` history is the reliable fallback whenever a
  live watch starts too late — now confirmed twice (Day 02, Day 03).
- Injected defaults from admission show up for free in `describe` output;
  no special technique needed beyond comparing "what I wrote" to "what got
  stored."

## Unresolved Issues

None blocking. Carried forward, not urgent:

1. Steps 1-3 (client encode/POST, authn, authz) and step 5 (etcd write)
   of the request flow remain theory-plus-inference — deferred to Day 39-41,
   Day 45, and Day 65/80 respectively.
2. Why `etcd`/`kube-apiserver` got fresh Pod objects after today's node
   reboot while other static Pods apparently didn't — deferred to Day 68
   (kubelet/CRI internals).
3. CoreDNS anti-affinity fix — deliberately deferred to Day 34/36 (unchanged
   from Day 02).

## Next Topic

Day 04 — kubectl core verbs and output formats.

## Next Lab

LAB 04 — not yet written. File to create:
`journal/daily/day-04-kubectl-core.md`.

## Overall Progress

Day 03 of 130 COMPLETE. Day 04 starting next session. 0 of 30 modules
completed, 1 in progress. 0 of 10 projects.

```text
[■                             ] 2%
```

Full day-by-day plan: `progress/daily-plan.md`
