# Day 05 — Namespaces, Labels, Selectors, Annotations

Author: Sagar Saitwal

| | |
|---|---|
| **Date** | 2026-09-22 |
| **Day** | 05 |
| **Module** | 01 — Kubernetes Fundamentals |
| **Topic** | Namespaces, labels, selectors, annotations |
| **Status** | COMPLETED |
| **Cluster** | `k8s-lab` — 3 nodes, Kubernetes v1.37.0, kind v0.33.0 (on `IT-SAGARS`) |

---

## Today's Objective

Move past the default namespace entirely: create a second one, prove
isolation between them, and pin down the mechanism (labels/selectors) that
actually connects Services and Deployments to their Pods — then prove,
empirically rather than by assertion, that annotations are excluded from
that mechanism.

## Module

01 — Kubernetes Fundamentals

## Section

Namespaces / Labels / Selectors / Annotations

## Topic

Cluster partitioning and the label-based object-matching mechanism

## Subtopic

`kind`'s extra default namespace; `kubectl get`'s name-vs-selector exclusion
rule; ReplicaSet hash determinism across namespaces

---

## Theory Learned

**Namespaces partition one physical cluster into isolated virtual
clusters.** Object names only have to be unique *within* a namespace, not
across the whole cluster — the same `nginx-trace` Deployment name exists
independently in both `default` and the new `dev` namespace, verified
directly rather than assumed.

**Not every object type is namespaced.** Confirmed by contrast: `namespace`
objects themselves, along with Nodes and PersistentVolumes (not tested
today, but the same category), are cluster-scoped. Pods, Deployments,
Services are namespaced — every command run through Day 04 implicitly
targeted `default` without ever saying so.

**`kind` ships a fifth default namespace beyond the four a bare cluster
has.** Expected `default`, `kube-node-lease`, `kube-public`, `kube-system`.
Actual output also included **`local-path-storage`** — the namespace for
`kind`'s bundled dynamic-storage provisioner (`rancher.io/local-path`),
which will matter directly once PersistentVolumeClaims are covered
(Day 25-26). This corrects something I was told incorrectly going in — see
Mistake note below.

**Labels are the real connective mechanism, not just organizational tags.**
`kubectl get pods -l app=nginx-trace` returned exactly the 3
already-running Pods — the same equality-match a Service's `spec.selector`
or a Deployment's `spec.selector.matchLabels` uses internally, just run
interactively instead of by a controller.

**Annotations are excluded from selection, provably, not just by
convention.** Added `learning-day=05` as an annotation via `kubectl
annotate`, then tried `kubectl get deployment -l learning-day=05` —
returned `No resources found`, even though the annotation is genuinely
present on the object (confirmable with `-o yaml`). Kubernetes doesn't
almost-support selecting by annotation; it's a hard boundary.

**A ReplicaSet's name hash is computed from the Pod template's content
alone, not from namespace or history.** The `dev` namespace's freshly
created ReplicaSet came back named `nginx-trace-647575f7d8` — the *exact*
hash Day 03's very first ReplicaSet had in `default`, before that one was
superseded by `855cf8f8cc` during the Day 04 Zscaler rollout-restart.
Same template text, same hash, regardless of which namespace or when it was
applied.

**`kubectl get <type> <name>` and `kubectl get <type> -l <selector>` are
mutually exclusive query modes.** Attempted `kubectl get deployment
nginx-trace -l learning-day=05` — kubectl refused outright:
`error: name cannot be provided when a selector is specified`. Naming an
object already picks exactly one; a selector asks for a *set* matching a
condition. Combining them is a contradiction the API rejects before it even
runs the query, not a soft warning.

## Why It Matters

Namespace isolation and the label/selector mechanism are what make
multi-tenant clusters and self-healing controllers both possible — a
Service or Deployment "finding" its Pods isn't magic, it's the exact
equality-match just run by hand today. Knowing annotations are structurally
excluded from that matching (not just conventionally different) prevents a
real mistake later: putting something in an annotation that a Service or
NetworkPolicy selector was actually meant to key off of.

---

## Commands Used

### `kubectl create namespace dev`

- **What it does:** creates a new cluster-scoped `Namespace` object.
- **Why I used it:** get a second, isolated space to prove namespace
  boundaries concretely rather than read about them.
- **Expected output:** `namespace/dev created`.
- **Actual output:** exactly that.

### `kubectl get namespaces`

- **What it does:** lists all namespace objects, cluster-wide (namespaces
  themselves aren't namespaced).
- **Expected output (going in):** 5 — `default`, `dev`, plus the 3 system
  ones.
- **Actual output:** 6 — also included `local-path-storage`, which I hadn't
  accounted for. See Theory Learned.

### `kubectl get pods -l app=nginx-trace`

- **What it does:** filters Pods in the current namespace (`default`) by an
  equality-based label selector.
- **Why I used it:** demonstrate the same matching mechanism Services and
  Deployments use internally, run directly from the command line.
- **Expected / Actual output:** exactly the 3 `nginx-trace` Pods, all
  `Running`. One side observation: all 3 showed `RESTARTS: 1 (162m ago)` —
  a simultaneous restart roughly 2.7 hours before this session, unexplained
  and not chased today (see Unresolved Issues).

### `kubectl apply -f nginx-deployment.yaml -n dev`

- **What it does:** applies the same manifest used since Day 03, this time
  into the `dev` namespace via `-n`.
- **Why I used it:** prove that identical object names in different
  namespaces don't collide.
- **Expected / Actual output:** `deployment.apps/nginx-trace created` —
  succeeded independently of the identically-named Deployment already
  running in `default`.

### `kubectl get pods` / `kubectl get pods -n dev`

- **What it does:** the first lists `default`'s Pods (the implicit
  namespace); the second explicitly targets `dev`.
- **Actual output:** two completely disjoint 3-Pod lists — `default`'s
  original Pods, unaffected and still `Running`/`23h` old; `dev`'s brand
  new Pods, `ContainerCreating`/`0s` old, on ReplicaSet
  `nginx-trace-647575f7d8`.

### `kubectl annotate deployment nginx-trace learning-day=05 --overwrite`

- **What it does:** adds (or overwrites) an annotation on the named object.
- **Why `--overwrite`:** without it, `kubectl annotate` refuses to change a
  key that already exists — not needed here since this key was new, but
  safe to include as a habit.
- **Expected / Actual output:** `deployment.apps/nginx-trace annotated`.

### `kubectl get deployment nginx-trace -l learning-day=05`

- **What it does (attempted):** meant to prove the annotation isn't
  selectable.
- **Actual output:** rejected outright —
  `error: name cannot be provided when a selector is specified`. This was
  my planning error, not a Sagar misunderstanding — see the note below.

### `kubectl get deployment -l learning-day=05` (corrected)

- **What it does:** the same selector query, without naming a specific
  object — lets the selector alone decide what matches.
- **Expected / Actual output:** `No resources found in default namespace.`
  — confirms the actual point: `learning-day=05` exists as an annotation on
  `nginx-trace`, and is completely invisible to `-l`.

---

## YAML / Configuration

`fundamentals/labs/nginx-deployment.yaml` — same file, reused a third time,
this time applied into a second namespace via `-n dev` rather than edited.

---

## Lab Performed

1. Created the `dev` namespace and listed all namespaces.
2. Filtered `default`'s Pods by label.
3. Deployed the same manifest into `dev`, confirmed isolation via two
   separate `kubectl get pods` calls.
4. Annotated `nginx-trace`, then attempted (and initially got wrong) a
   selector query to prove the annotation isn't matchable; corrected the
   command and confirmed.

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

Namespace isolation and the label/annotation selectability boundary both
demonstrated with direct command output.

## Actual Result

Matched, after correcting two things I had wrong going in (see below) —
both caught immediately from real output, not discovered later.

## What Worked

- Reusing the same manifest across namespaces made isolation obvious with
  zero extra YAML to write.
- The selector-rejection error, once fixed, produced a cleaner proof of the
  label/annotation boundary than a silently-empty result would have — the
  API actively distinguishing "specific object" queries from "set" queries
  is itself worth knowing.

## What Failed

Two things I (the assistant) got wrong while planning this session — not
Sagar mistakes, and not filed in `journal/mistakes-and-lessons.md`, which
is reserved for his own learning errors, but recorded here since they
happened during today's work and were corrected using real cluster
evidence:

1. Told him to expect 4 default namespaces; `kind` actually ships a 5th
   (`local-path-storage`).
2. Gave `kubectl get deployment nginx-trace -l learning-day=05` as the
   final command — invalid syntax, since a name and a selector can't be
   combined. Corrected to `kubectl get deployment -l learning-day=05`
   within the same session.

---

## What I Broke

Nothing — no cluster state was affected by either correction above; the
invalid command was rejected immediately by the API, before touching
anything.

## Error Message

```text
error: name cannot be provided when a selector is specified
```

## Investigation

Not applicable in the usual sense — this was an immediate syntax rejection,
not a state that needed diagnosing. The fix was re-reading the error
message literally: it names the exact conflict (name + selector together),
so the correction was direct.

## Root Cause

`kubectl get <type> <name>` and `kubectl get <type> -l <selector>` are two
mutually exclusive query modes in the API's own contract — not a soft
preference kubectl could reasonably guess around.

## Solution

Dropped the object name, kept the selector: `kubectl get deployment -l
learning-day=05`.

## Verification

Correct command returned `No resources found in default namespace.` —
confirms the annotation exists (checkable via `-o yaml`) but is invisible
to label selectors, which was the actual point of the exercise.

---

## Mistake

No `mistakes-and-lessons.md` entry for this session — nothing Sagar
misunderstood; both corrections above were errors in my own planning,
caught and fixed live. See What Failed, above.

## Lesson Learned

1. `kind` doesn't produce the "textbook minimal" set of default
   namespaces — check `kubectl get namespaces` on a real `kind` cluster
   rather than assuming from general Kubernetes knowledge alone.
2. `kubectl get`'s name and selector arguments are mutually exclusive, not
   just redundant — worth remembering before scripting anything that
   combines them.
3. A ReplicaSet's name hash is a pure function of its Pod template content
   — identical templates produce identical hashes regardless of namespace,
   timing, or history.

## Troubleshooting Knowledge

```text
SYMPTOM: `kubectl get <type> <name> -l <selector>` fails immediately with
         "name cannot be provided when a selector is specified."
CHECK:   Are both a specific object name AND a label selector present in
         the same `kubectl get` call?
COMMAND: kubectl get <type> -l <selector>          (drop the name)
         kubectl get <type> <name>                 (drop the selector)
INTERPRETATION: These are two different query modes — "get exactly this
         one object" vs. "get every object matching this condition" —
         and the API rejects mixing them rather than guessing which you
         meant.
ROOT CAUSE: Providing an object name already uniquely identifies a single
         object; a selector alongside it is a contradiction in the
         request itself.
FIX:     Use one or the other, never both, in the same `kubectl get`.
PREVENTION: When filtering a known object further, use `-o yaml` /
         `describe` on the named object instead of adding `-l` to it.
```

---

## Interview Questions

1. What's the practical difference between a namespace-scoped object and a
   cluster-scoped one? Name one of each you've directly interacted with.
2. How does a Service actually find the Pods it routes to — by name, or by
   something else?
3. Why does adding `-l <selector>` alongside a specific object name in
   `kubectl get` fail, instead of just being redundant?
4. Two Deployments are both named `nginx-trace` and both exist at the same
   time without conflict. How is that possible?
5. You add a value to an object as an annotation instead of a label. What
   capability do you lose by doing that?

## Challenge

The six planned commands (create namespace, list namespaces, label filter,
cross-namespace apply, namespace comparison, annotation-vs-selector proof)
served as the day's structured exercise, including working through my own
planning error on the final command live rather than silently fixing it
beforehand.

---

## End-of-Day Status

| Item | State |
|---|---|
| `dev` namespace created and confirmed | Done |
| Label selector filtering demonstrated | Done |
| Namespace isolation demonstrated (same name, two namespaces) | Done |
| Annotation added and confirmed non-selectable | Done — corrected command, real proof |
| `kind`'s extra default namespace noted | Done |

## Next Session

Next journal file: `journal/daily/day-06-pod-basics.md`

1. Run the resume ritual (`git pull`, `current-progress.md`,
   `check-dependencies.sh`, check `SystemInfo.md` for this machine).
2. Day 06 — Pod anatomy, YAML, lifecycle, phases. First hand-written YAML
   of the course.
