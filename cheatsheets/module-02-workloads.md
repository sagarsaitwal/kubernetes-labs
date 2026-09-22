# Module 02 — Workloads Cheatsheet

Author: Sagar Saitwal

Covers: Day 06 – Day 07. Updated after each day of this module.

This is **quick reference only** — the reasoning, the mistakes, and the full
command output live in `journal/daily/`. Come here to look something up fast;
go there to see how it was actually learned.

Module 01's cheatsheet (`module-01-fundamentals.md`) is capped at Day 05 —
its own scope (cluster setup, control plane, architecture, kubectl basics,
namespaces/labels). This file starts fresh at Day 06, where the subject
matter genuinely changes to workloads: Pods, ReplicaSets, Deployments,
StatefulSets, DaemonSets, Jobs, CronJobs (`progress/daily-plan.md`, Phase 2,
Days 06-13).

---

## Core concepts

- **A Pod's minimum valid manifest needs exactly 6 fields:** `apiVersion:
  v1` (Pod is a core resource, no group prefix — unlike `apps/v1` for
  Deployment), `kind: Pod`, `metadata.name`, and per container: `name` +
  `image`.
- **A Deployment's `spec.template` is literally a Pod spec, nested one
  level deeper.** Writing a standalone Pod first makes that shape
  recognizable rather than new syntax.
- **Pod-level `status.phase` and container-level `state` are different
  signals.** Phase (`Pending`/`Running`/`Succeeded`/`Failed`/`Unknown`) is
  coarse; container state (`Waiting`/`Running`/`Terminated`, under
  `describe`'s `Containers:` block or `-o yaml`'s
  `status.containerStatuses`) is per-container and carries a reason/exit
  code. The phase alone can be too coarse to explain what one container is
  actually doing.
- **A bare Pod has no controller.** Delete one directly and nothing
  replaces it — proven, not assumed. Contrast with a Deployment-managed
  Pod, replaced by its ReplicaSet within seconds.
- **Admission's toleration injection (Module 01, Day 03) applies to *any*
  Pod creation**, not just ones created via a ReplicaSet — confirmed on a
  bare, hand-written Pod carrying the identical two `NoExecute` tolerations.
- **A cached image can make `Pending` nearly invisible.** The phase
  reflects real waiting (usually on an image pull); if the image is already
  on the node, there's often nothing to wait for.
- **`kubectl get -w` reflects changes from *any* terminal acting on the
  same object**, not just its own session — an apparent "unexplained"
  transition in one watch can simply be a command run concurrently
  elsewhere.
- **A second container belongs in the same Pod only for tight coupling** —
  shared network namespace, shared volumes, same lifecycle. An independent
  service is a separate Pod/Deployment, reached over the network.
- **Init containers (`spec.initContainers`) run sequentially, before any
  `spec.containers` entry — each must exit `0` before the next starts.**
  A stuck init container blocks everything after it, including a sidecar.
- **A native sidecar is an `initContainers` entry with `restartPolicy:
  Always`.** It doesn't block on completion, stays alive for the Pod's
  whole life, restarts on crash, and counts toward `READY` — a classic
  init container never does any of that.
- **A native sidecar still respects its position in the init sequence.**
  `restartPolicy: Always` changes what happens *after* it starts, not
  *when* — it still waits behind every earlier `initContainers` entry.
- **`kubectl logs`/`exec` need `-c <container>` once a Pod has more than
  one container** — omitting it errors rather than guessing.
- **A container that redirects output to a file produces empty `kubectl
  logs`, correctly.** `kubectl logs` only ever captures stdout/stderr;
  `echo ... > file` never touches either.

---

## Commands

| Command | What it does | When to reach for it |
|---|---|---|
| `kubectl apply -f <file>` | Create/update from a manifest, hand-written or not | Standard way to submit any object |
| `kubectl get pod <name> -w` | Live stream of one Pod's status | Watching a phase transition — remember it reflects all sessions, not just this one |
| `kubectl describe pod <name>` | Full detail, including per-container `State:` separate from Pod-level `Status:` | Distinguishing what the whole Pod reports vs. what one container is actually doing |
| `kubectl delete pod <name>` | Deletes the Pod object directly | Proving/testing whether something owns a Pod — nothing recreates a bare one |
| `kubectl logs <pod> -c <container>` | Logs from one specific container | Required once a Pod has more than one container |
| `kubectl exec <pod> -c <container> -- <cmd>` | Run a command in one specific container | Same reason — kubectl won't guess which one you meant |

---

## Findings on THIS cluster (observed, not generic theory)

**A hand-written bare Pod (`manual-pod`) skipped a visible `Pending` phase
almost entirely** — its image (`nginx:1.27-alpine`) was already cached on
`k8s-lab-worker` from `nginx-trace` running there since Day 03/04.
`describe`'s Events showed `Pulled ... "already present on machine"`, not a
real pull.

**Deleting `manual-pod` directly proved the no-controller behavior for
real, not just in theory.** `kubectl get pods` afterward showed only the
pre-existing `nginx-trace` Pods — nothing replaced it.

**Zscaler blocked `multi-container-demo`'s `setup` init container's pull
on the first attempt** — same `x509: certificate signed by unknown
authority` signature as Mistake 003 (Day 04). Recognized immediately from
the error text and fixed by disabling Zscaler, then deleting/reapplying
the Pod fresh (no `rollout restart` equivalent for a bare Pod).

**A native sidecar (`log-sidecar`) sat in `Waiting: PodInitializing`
while an earlier init container (`setup`) was stuck** — direct, unplanned
proof that `restartPolicy: Always` does not let a sidecar skip ahead in
the init sequence, even though its own image had nothing wrong with it.

---

## Troubleshooting habits established so far

```text
A `kubectl get -w` watch shows a transition with no apparent cause?
   -> check every OTHER terminal/session for a mutating command
      (delete, apply, scale, rollout) run against the same object.
   -> a live watch reflects the object's true state regardless of which
      session changed it -- it is not scoped to "this terminal's own
      actions."

Wondering whether a Pod not showing a visible Pending phase is suspicious?
   -> check whether its image was already cached on the node it landed on
      (`describe`'s Events: "already present on machine" vs. an actual
      pull with duration).
   -> Pending reflects real waiting, not a guaranteed visible step every
      Pod passes through.

Want to know if something is actually managing (and will replace) a Pod?
   -> delete it directly and watch `kubectl get pods` afterward.
   -> nothing reappears = no controller. A replacement within seconds =
      something (ReplicaSet, etc.) owns it.

A multi-container Pod is stuck, and some containers show
Waiting: PodInitializing even though their own image is fine?
   -> kubectl describe pod <name>   -- read Init Containers TOP TO BOTTOM.
   -> initContainers run strictly in sequence, sidecars included --
      restartPolicy: Always changes behavior AFTER starting, not WHEN.
   -> the real problem is the EARLIEST stuck entry, not the last one.

Recognize this error text? ("x509: certificate signed by unknown authority")
   -> Zscaler / corporate TLS interception (see Module 01's Mistake 003).
   -> disable the proxy; for a bare Pod, delete + reapply fresh rather
      than waiting out the existing backoff timer.
```

---

## Interview questions accumulated (Day 06–present)

1. What is the minimum set of fields a valid Pod manifest needs?
2. What does a Deployment's `spec.template` actually contain, structurally?
3. What's the difference between a Pod's `status.phase` and a container's
   `state`, and why can't one substitute for the other?
4. Why might a Pod skip a visible `Pending` phase almost entirely?
5. If you delete a bare Pod versus a Pod owned by a Deployment, what's the
   observable difference, and why?
6. Why would a bare, hand-written Pod carry the same auto-injected
   tolerations as a Deployment-managed one?
7. What's the practical difference between a classic init container and a
   native sidecar (`restartPolicy: Always`)?
8. A native sidecar's image is fine, but it still won't start. What's the
   first thing to check?
9. Why does `kubectl logs`/`exec` need `-c <container>` on some Pods but
   not others?
10. A container clearly ran successfully, but `kubectl logs` shows
    nothing for it. What's the likely explanation?
