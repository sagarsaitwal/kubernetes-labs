# Current Kubernetes Learning Progress

Author: Sagar Saitwal

Last updated: 2026-09-21

> This file is the single source of truth for where the learning stopped.
> On any new session or new device, read this file FIRST.

**Current Day: 05**

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

Day 04 COMPLETED. Day 05 — Namespaces, labels, selectors, annotations —
**queued, not started.** Teaching content was given in the previous session
(concepts below), but **no commands were run yet** — resume directly with
the six-command list, don't re-derive the plan. Re-explain only if it's been
long enough that a refresher is warranted.

## Current Subtopic

### Concepts already taught, not yet exercised

- **Namespaces** — partition one physical cluster into isolated virtual
  clusters. Solves name collisions, gives a boundary for access control,
  quotas, and environment separation (`dev`/`staging`/`prod` on one
  cluster). Not everything is namespaced — Nodes, PersistentVolumes, and
  namespaces themselves are cluster-scoped; Pods/Deployments/Services are
  namespaced. Every command run so far implicitly targeted `default`.
- **Labels** — key-value pairs on an object's metadata. Not just
  organizational tags: this is the **actual mechanism** connecting objects
  to each other. A Service finds its Pods by matching labels, not by name;
  a Deployment finds its own Pods the same way, via `spec.selector`.
- **Selectors** — the query language over labels. Equality-based
  (`app=nginx-trace`) or set-based (`environment in (dev, staging)`). A
  Service/Deployment's selector is a live, continuously-evaluated query, not
  a one-time snapshot — add a matching label to any Pod and it's picked up
  immediately, no code change.
- **Annotations** — key-value pairs like labels, syntactically, but
  **never used for selection**. Already seen one in the wild:
  `kubectl.kubernetes.io/last-applied-configuration`, which `kubectl apply`
  writes to itself to compute future diffs. Rule of thumb: if you'll ever
  want to query a set of objects by it, it's a label; if it's just
  descriptive metadata nobody will filter on, it's an annotation.

### The six queued commands

```bash
# 1. Create a namespace — cluster-scoped object, new to the API server
kubectl create namespace dev

# 2. See it alongside the 4 that exist in every cluster by default
kubectl get namespaces

# 3. Filter by label instead of reading the whole list
kubectl get pods -l app=nginx-trace

# 4. Deploy the SAME manifest into the new namespace — proves isolation,
#    since nothing about the object name collides with default's copy
kubectl apply -f nginx-deployment.yaml -n dev

# 5. Compare — two separate lists, same cluster
kubectl get pods
kubectl get pods -n dev

# 6. Add an annotation, then try to SELECT by it — proves annotations are
#    invisible to selectors, not just a naming convention
kubectl annotate deployment nginx-trace learning-day=05 --overwrite
kubectl get deployment nginx-trace -l learning-day=05
```

Expected result for #6's last line specifically: **empty** — that's the
point of the exercise, not a failure.

## Learning Status

🟡 IN PROGRESS

Day 00 through Day 04 are all fully COMPLETED. Day 05 is next.

## Last Completed Lab

**Day 04 — kubectl core verbs and output formats.** COMPLETED. Ran and
interpreted six commands (`-o yaml`, `-o jsonpath`, `--dry-run=server`,
`-o custom-columns` + `--sort-by`, `logs`, `exec`) against `nginx-trace`,
recreated fresh on this machine's cluster. Along the way: recovered a
stopped `k8s-lab-control-plane` container (`docker start`, no data lost),
and diagnosed a real `ErrImagePull` failure to a corporate TLS-inspecting
proxy (Zscaler) — confirmed via the exact `x509: certificate signed by
unknown authority` error in the Pod's Events, fixed by disabling the proxy
and forcing a retry with `kubectl rollout restart`. New finding: `--dry-run=
server` only previews admission on the submitted object, not on anything a
controller creates afterward — the Day 03 toleration injection (which
happens on the Pod, not the Deployment) correctly did not show up here.

## Last Commands Practiced

```bash
docker ps -a --filter "name=k8s-lab" --format 'table {{.Names}}\t{{.Status}}'
docker start k8s-lab-control-plane
kubectl apply -f nginx-deployment.yaml
kubectl get deployment nginx-trace -o yaml
kubectl get deployment nginx-trace -o jsonpath='{.spec.template.spec.containers[0].image}'
kubectl apply -f nginx-deployment.yaml --dry-run=server -o yaml
kubectl get pods -o custom-columns='NAME:.metadata.name,NODE:.spec.nodeName,RESTARTS:.status.containerStatuses[0].restartCount' --sort-by='.status.containerStatuses[0].restartCount'
kubectl describe pod <pod> | grep -A5 Events
kubectl rollout restart deployment nginx-trace
kubectl logs <pod>
kubectl exec -it <pod> -- cat /etc/nginx/nginx.conf
```

## Last YAML Practiced

`fundamentals/labs/nginx-deployment.yaml` — same file reused from Day 03
(reapplied here because clusters don't travel between machines).

## What I Learned

- `-o yaml` shows the fully stored object, including everything admission
  and defaulting added beyond what was written by hand.
- `-o jsonpath` prints with no trailing newline by design — easy to mistake
  for "no output" when reading a terminal directly.
- **`--dry-run=server` only previews admission on the object you submit** —
  not on objects a controller will create afterward (Deployment → ReplicaSet
  → Pod). The Day 03 toleration injection happens at Pod creation, a
  separate API call, so a Deployment dry-run correctly shows nothing.
- `docker ps` hides stopped containers by default; `-a` is required to tell
  "stopped" apart from "gone."
- A local cluster's container runtime (`containerd`, inside each kind node)
  has its own TLS trust store, independent of the host OS — corporate
  TLS-inspection proxies the browser handles transparently can still break
  image pulls inside it.
- `ErrImagePull` → `ImagePullBackOff` is a progression (first failure, then
  retry/backoff state), not two different problems.

## What I Broke

Nothing broken by anything run today. Two things found broken and fixed —
see Mistakes Made below.

## Errors Encountered

```text
tls: failed to verify certificate: x509: certificate signed by unknown authority
```
(on all 3 `nginx-trace` Pods, pulling `nginx:1.27-alpine`)

## Root Cause

Zscaler (corporate TLS-inspecting proxy) intercepting the HTTPS connection
to `registry-1.docker.io`; `containerd` inside the kind node rejected the
proxy's re-signed certificate as untrusted.

## How It Was Fixed

Disabled Zscaler; `kubectl rollout restart deployment nginx-trace` to force
fresh Pods and fresh pull attempts. All 3 reached `1/1 Running`.

## Mistakes Made

**Mistake 003** (see `journal/mistakes-and-lessons.md`) — named Zscaler as
the likely cause before checking the Pod's actual `Events` text. Turned out
correct, but the lesson is to confirm with the literal error message first,
since `ErrImagePull` looks identical whether the real cause is TLS, DNS, or
network path.

## Important Lessons

- `docker ps -a` (not plain `docker ps`) is the right first check whenever a
  cluster container seems to have "disappeared."
- Read the exact `Events` error text before naming a root cause, even when a
  guess turns out right.

## Unresolved Issues

None blocking. Carried forward, unchanged from Day 03:

1. Steps 1-3 (client encode/POST, authn, authz) and step 5 (etcd write) of
   the request flow — deferred to Day 39-41, Day 45, Day 65/80.
2. Why only some static Pods got a fresh `Age` after a node reboot —
   deferred to Day 68.
3. CoreDNS anti-affinity fix — deliberately deferred to Day 34/36.

## Next Topic

Day 05 — Namespaces, labels, selectors, annotations.

## Next Lab

LAB 05 — not yet written. File to create:
`journal/daily/day-05-namespaces-labels-selectors.md`.

## Overall Progress

Day 04 of 130 COMPLETE. Day 05 starting next session. 0 of 30 modules
completed, 1 in progress. 0 of 10 projects.

```text
[■                             ] 3%
```

Full day-by-day plan: `progress/daily-plan.md`
