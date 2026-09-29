# Module 02 — Workloads Cheatsheet

Author: Sagar Saitwal

Covers: Day 06 – Day 10. Updated after each day of this module.

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
- **`resources.requests` is what the scheduler filters nodes against,
  before scoring.** An impossible request guarantees a clean, reproducible
  `Pending` — no ambiguity about cause.
- **A `Pending` Pod's Events can list multiple independent scheduling
  failures at once**, across different nodes — read all of them, not just
  the first.
- **`QoS Class` is a mechanical consequence of which `resources` fields
  are set** — `BestEffort` (none set), `Burstable` (requests set, no
  matching limits), `Guaranteed` (requests == limits for everything).
- **`spec.restartPolicy: Always` (the unstated default on every Pod)
  restarts a container after *any* exit, success or failure.** This is the
  literal mechanism that turns one crash into a loop — restart backoff is
  exponential, same mechanism as image-pull backoff, just a different
  trigger.
- **Pod-level `Status:` and container-level `State:` can look
  contradictory — `Status: Running` at the top while the container says
  `State: Waiting, Reason: CrashLoopBackOff` below it.** Read the container
  block specifically; the top line alone can mislead.
- **`kubectl logs --previous` is exactly one generation back, and not
  guaranteed to still exist.** The runtime prunes old crash logs; grab
  `--previous` early, before more restarts happen.
- **A ReplicaSet's `spec.selector.matchLabels` must exactly match
  `spec.template.metadata.labels`** — it has to be able to find the Pods
  its own template creates.
- **A ReplicaSet reconciles only on Pod count, never content.** Editing
  its template and reapplying updates the object instantly but leaves
  every already-running Pod untouched. The template is only read at the
  moment a new Pod is created — scale-up or replacing a deleted one.
- **A bare ReplicaSet's Pod naming is a single `<name>-<5 chars>` hash** —
  not DaemonSet-specific, it's what any ReplicaSet produces directly. The
  double-hash pattern (`<name>-<10 chars>-<5 chars>`) specifically marks a
  Deployment-managed Pod.
- **A Deployment keeps its superseded ReplicaSet at `0` replicas rather
  than deleting it** — rollback history a bare ReplicaSet never gives you.
- **`kubectl apply` returning `unchanged` is real diagnostic signal.** It
  means the diff found nothing — check whether your own edit actually
  saved before assuming the cluster didn't do something.
- **`kubectl scale` is imperative** — it changes the live object's
  `spec.replicas` directly, silently diverging from what the YAML file on
  disk says.
- **A Deployment's `spec` is structurally identical to a ReplicaSet's** —
  `replicas`/`selector`/`template`. The entire difference is behavioral:
  when the template changes, a Deployment creates a **new ReplicaSet
  generation** and orchestrates a gradual handover, instead of silently
  updating an object with no effect on existing Pods.
- **`kubectl get deployment` has its own column set** — `READY`,
  `UP-TO-DATE`, `AVAILABLE` — which can diverge mid-rollout.
- **`kubectl rollout history`'s `CHANGE-CAUSE` isn't automatic.** It stays
  `<none>` unless deliberately recorded (the deprecated `--record` flag,
  or the `kubernetes.io/change-cause` annotation).
- **`kubectl rollout undo` is imperative and does not update `kubectl
  apply`'s `last-applied-configuration` annotation.** After a rollback,
  the live object, the YAML file, and `apply`'s own diff-tracking
  annotation can all genuinely disagree — the exact same category of
  drift as `kubectl scale`.

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
| `kubectl logs <pod> --previous` | The prior terminated instance's logs, if the runtime still has them | Diagnosing a crash — grab this early, it's not guaranteed to persist |
| `kubectl get rs` | ReplicaSets, with `DESIRED`/`CURRENT`/`READY` columns | Check whether a count mismatch, not just a Pod problem, is the actual issue |
| `kubectl scale replicaset <name> --replicas=N` | Imperatively change replica count on the live object | Quick manual adjustment — remember it doesn't touch the YAML file |
| `kubectl rollout status deployment/<name>` | Blocks and streams live rollout progress | Watching a rolling update happen, instead of polling `get pods` by hand |
| `kubectl rollout history deployment/<name>` | Lists revisions | Check `CHANGE-CAUSE` — empty unless deliberately recorded |
| `kubectl rollout undo deployment/<name>` | Rolls back to the previous revision, reactivating its ReplicaSet | The actual capability a bare ReplicaSet never has |

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

**A deliberately impossible `resources.requests.memory: "100Gi"` failed
scheduling for TWO independent reasons at once** — 1 node excluded by the
control-plane taint, 2 nodes excluded by insufficient memory — richer than
the single-reason failure that was predicted going in.

**A deliberately crashing container (`exit 1`) showed exponential restart
backoff directly** — restart-gap timestamps grew `12s` → `30s` → `50s` in
a live watch, same mechanism as image-pull backoff, different trigger.
`kubectl logs --previous` failed by the 4th restart — the runtime had
already pruned that instance's logs.

**`kubectl get rs` on this cluster shows Day 03/04's old `nginx-trace`
ReplicaSet still preserved at `DESIRED: 0`** — real, unplanned evidence
that a Deployment keeps a superseded generation around as rollback
history rather than deleting it, discovered while working through Day 09.

**Editing `replicaset-demo`'s image and reapplying left both existing
Pods on the old image; only a scale-up and a delete-and-replace produced
Pods on the new one** — the count-vs-content reconciliation rule, proven
in three predicted-then-verified steps rather than asserted.

**`deployment-demo`'s rolling update produced a second ReplicaSet
(`7c589f7d94`) alongside the original (`6c6864b58f`), scaled inversely
(0↔2) at each stage** — the exact Day 09 mechanism, this time driven on
purpose via a rolling update and rollback, not found as leftover evidence.

**`kubectl rollout undo` on `deployment-demo` warned about
`last-applied-configuration` — and the warning was real.** After the
rollback, reapplying the file (still at the "new" image) would have
reported `unchanged`, matching `apply`'s own stale annotation rather than
what was actually running.

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

A Pod stays Pending indefinitely?
   -> kubectl describe pod <name>   -- check Node: (assigned at all?) and
      Events: FailedScheduling -- read EVERY reason listed, not just one.
   -> commonly: resources.requests no node can satisfy, an untolerated
      taint, or a nodeSelector/affinity rule with no match.

A Pod cycles Running / Error / CrashLoopBackOff, RESTARTS climbing?
   -> kubectl describe pod <name>  -- Last State: Terminated, Exit Code.
   -> kubectl logs <name>          -- current attempt.
   -> kubectl logs <name> --previous -- prior attempt, IF still retained.
   -> this is application-level (the container's own exit code/behavior),
      not a scheduling or cluster problem -- restartPolicy: Always just
      keeps bringing it back.

Edited a ReplicaSet's template, reapplied, but nothing seems to have changed?
   -> kubectl apply -f <file>  -- "configured" (real diff) or "unchanged"
      (edit never saved -- check the file's actual content first)?
   -> if "configured": existing Pods will NOT pick up the change -- a
      ReplicaSet only reads its template when creating a NEW Pod. Verify
      with -o custom-columns=...IMAGE... rather than assuming.
   -> there is no fix at the ReplicaSet level for this -- it's exactly
      why Deployments exist (Day 10).

After `kubectl rollout undo`, a later `apply` reports "unchanged" even
though the live object clearly differs from the file?
   -> apply's diff compares the file against its OWN last-applied-
      configuration annotation, not directly against the live object.
   -> rollout undo (like scale) changes the live object without updating
      that annotation -- file, live object, and the annotation can all
      genuinely disagree.
   -> prefer changing the YAML and reapplying over imperative commands
      when the change should be durable, not a one-off fix.
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
11. Why can a single `Pending` Pod fail scheduling for more than one
    reason at once?
12. Why does a container that exits with code `0` still get restarted
    under the default `restartPolicy`?
13. Why might `kubectl logs --previous` fail even though the Pod has
    clearly restarted multiple times?
14. A Pod's top-level `Status:` says `Running`. Does that guarantee its
    container is healthy right now?
15. You edit a ReplicaSet's Pod template and reapply. What happens to
    already-running Pods, and why?
16. What's the practical difference between `kubectl scale` and editing
    `replicas:` in a YAML file and reapplying?
17. A Deployment's old ReplicaSet is still visible via `kubectl get rs`,
    scaled to zero. What is it for?
18. Why does a bare ReplicaSet's Pod get a single hash suffix while a
    Deployment-managed one gets two?
19. What's actually different, behaviorally, between a Deployment and a
    ReplicaSet, given their `spec` fields are otherwise identical?
20. Why might `kubectl rollout history` show revisions with no useful
    `CHANGE-CAUSE`?
21. Why does `kubectl rollout undo` warn about
    `last-applied-configuration`, and what could go wrong if ignored?
