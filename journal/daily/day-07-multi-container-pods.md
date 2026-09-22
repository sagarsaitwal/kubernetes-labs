# Day 07 — Multi-Container Pods, Sidecars, Init Containers

Author: Sagar Saitwal

| | |
|---|---|
| **Date** | 2026-09-22 |
| **Day** | 07 |
| **Module** | 02 — Workloads |
| **Topic** | Multi-container Pods, sidecars, init containers |
| **Status** | COMPLETED |
| **Cluster** | `k8s-lab` — 3 nodes, Kubernetes v1.37.0, kind v0.33.0 (on `IT-SAGARS`) |

---

## Today's Objective

Write a single Pod combining both a classic init container and the modern
native sidecar mechanism (`restartPolicy: Always` on an init container
entry), then prove — not just assert — that the init container's setup
work genuinely lands before the main container starts, via a shared volume.

## Module

02 — Workloads

## Section

Multi-container Pods

## Topic

Init containers (sequential, must-complete-before-main) vs. native sidecar
containers (`restartPolicy: Always`)

## Subtopic

`-c <container>` flag for `logs`/`exec`; `Init:X/Y` status; shell
redirection vs. container logs

---

## Theory Learned

**A second container belongs in the same Pod only for tight coupling** —
shared network namespace, shared volumes, same lifecycle. An independent
service still belongs in its own Pod/Deployment, reached over the network.

**Init containers (`spec.initContainers`) run sequentially, before any
`spec.containers` entry, and each must exit `0` before the next starts.**
Confirmed directly: `setup`'s `describe` output showed `State: Terminated`,
`Reason: Completed`, `Exit Code: 0`, with `Started` and `Finished` the same
second — a real completion gate, not a background task.

**A native sidecar is an `initContainers` entry with `restartPolicy:
Always` added.** That one field changes what happens *after* it starts —
it doesn't block on completion, stays alive for the Pod's whole life, gets
restarted if it crashes, and counts toward the Pod's `READY` count — a
classic init container never does any of that.

**A native sidecar still respects its position in the `initContainers`
list — `restartPolicy: Always` doesn't let it skip ahead.** Proven by
accident, via the Zscaler incident (see Investigation): while `setup` was
stuck in `ImagePullBackOff`, `log-sidecar` sat in `Waiting: PodInitializing`
too, despite its own image having nothing wrong with it. Its "always
running" behavior only applies once it's had its turn — being a sidecar
changes its lifecycle after starting, not when it's allowed to start.

**`kubectl logs`/`exec` need `-c <container>` once a Pod has more than one
container** — every prior day's Pods only ever had one, so this had never
come up. Omitting it errors rather than guessing which container was meant.

**A container writing to a file, not stdout, produces empty `kubectl
logs`.** `setup`'s command was `echo '...' > /work/index.html` — the `>`
redirected output into the shared volume, never touching stdout. `kubectl
logs -c setup` correctly returned nothing; the container still did exactly
what it was told.

## Why It Matters

Init-container ordering and native sidecars are the actual mechanism behind
patterns used constantly in real clusters — waiting for a dependency,
preparing a shared volume, running a log shipper or proxy alongside an app.
Understanding that a stuck init container blocks *everything* after it,
sidecar included, is what makes a genuinely stuck multi-container Pod
diagnosable instead of confusing.

---

## Commands Used

### `kubectl apply -f multi-container-demo.yaml`

- **What it does:** creates the 3-container Pod (2 init, 1 main) from the
  hand-written manifest.
- **First attempt:** `pod/multi-container-demo created`, but `setup` hit
  `ImagePullBackOff` — see Investigation.
- **Second attempt (after fixing the pull issue):** succeeded cleanly.

### `kubectl get pod multi-container-demo -w`

- **What it does:** live status stream.
- **Why I used it:** try to catch the `Init:X/Y` phase before the Pod
  settles into `Running`.

### `kubectl describe pod multi-container-demo`

- **What it does:** full detail, with `Init Containers:` and `Containers:`
  as genuinely separate sections this time (3 entries total, not 1).
- **Actual output (after the fix):** `setup` — `Terminated`/`Completed`/
  exit `0`; `log-sidecar` — `Running`, started the same second `setup`
  finished; `nginx` — `Running`, started one second after that. Events
  confirmed the full chain in order: pull → create → start, for each
  container in sequence.

### `kubectl exec multi-container-demo -c nginx -- cat /usr/share/nginx/html/index.html`

- **What it does:** runs `cat` inside specifically the `nginx` container
  (`-c` required — 3 containers exist).
- **Why I used it:** the actual proof the volume handoff worked.
- **Expected / Actual output:** `written by init container` — exactly what
  `setup` wrote, nothing else.

### `kubectl logs multi-container-demo -c log-sidecar`

- **Actual output:** dozens of `sidecar alive at ...` lines, 5 seconds
  apart, still increasing — confirms genuine persistence, not a one-shot
  that happened to look alive.

### `kubectl logs multi-container-demo -c setup`

- **Actual output:** empty. Correct — see Theory Learned; the command
  redirected its output to a file, never to stdout.

---

## YAML / Configuration

`fundamentals/labs/multi-container-demo.yaml` — second hand-written
manifest of the course:

```yaml
apiVersion: v1
kind: Pod

metadata:
  name: multi-container-demo

spec:
  volumes:
    - name: shared-data
      emptyDir: {}

  initContainers:
    - name: setup
      image: busybox:1.36
      command:
        - sh
        - -c
        - echo 'written by init container' > /work/index.html
      volumeMounts:
        - name: shared-data
          mountPath: /work

    - name: log-sidecar
      image: busybox:1.36
      restartPolicy: Always
      command:
        - sh
        - -c
        - while true; do echo sidecar alive at $(date); sleep 5; done

  containers:
    - name: nginx
      image: nginx:1.27-alpine
      volumeMounts:
        - name: shared-data
          mountPath: /usr/share/nginx/html
```

Correct on the first attempt — no structural corrections needed, unlike
Day 06's filename typo.

---

## Lab Performed

1. Manifest written and reviewed before applying — confirmed correct.
2. First `apply` hit `ImagePullBackOff` on `setup` — diagnosed as Zscaler
   (same pattern as Day 04), fixed by disabling it.
3. Deleted and reapplied fresh rather than waiting out the existing
   backoff timer (a bare Pod has no `rollout restart` to lean on).
4. Confirmed via `describe`, `exec`, and two `logs -c` calls that both
   patterns behaved exactly as explained: sequential init-then-sidecar
   handoff, shared-volume proof, persistent sidecar, and empty-but-correct
   logs for the file-writing init container.

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

A Pod combining an init container, a native sidecar, and a main container,
with the ordering and shared-volume handoff provable from real command
output.

## Actual Result

Matched, after resolving a recurring Zscaler image-pull block.

## What Worked

- Reviewing the manifest before applying caught nothing this time — it was
  correct on the first attempt.
- The Zscaler incident, while unplanned, incidentally proved something
  true about native sidecars that hadn't been fully explained: they still
  wait their turn in the init sequence.

## What Failed

`setup`'s first pull attempt — see What I Broke.

---

## What I Broke

Nothing broken by the manifest itself. The image pull failed on the first
`apply`, caused by the environment (Zscaler), not the YAML:

## Error Message

```text
Failed to pull image "busybox:1.36": failed to pull and unpack image "docker.io/library/busybox:1.36": failed to resolve reference "docker.io/library/busybox:1.36": failed to do request: Head "https://registry-1.docker.io/v2/library/busybox/manifests/1.36": tls: failed to verify certificate: x509: certificate signed by unknown authority
```

## Investigation

```bash
kubectl describe pod multi-container-demo   # Events: setup ImagePullBackOff, x509 error
```

Same exact `x509: certificate signed by unknown authority` signature as
Day 04's Mistake 003 — recognized immediately from the error text rather
than needing fresh diagnosis. Also observed, while the Pod was stuck:
`log-sidecar` sat in `Waiting: PodInitializing` despite its own image
(`busybox:1.36`, already resolved to the same broken pull) never having
been attempted — direct evidence that a native sidecar's `restartPolicy:
Always` behavior only kicks in once it's had its turn in the init sequence,
not before.

## Root Cause

Zscaler TLS interception, same mechanism as Day 04 — the container
runtime's independent trust store rejecting the proxy's re-signed
certificate.

## Solution

Disabled Zscaler; deleted and reapplied the Pod fresh (no `rollout restart`
equivalent exists for a bare Pod).

## Verification

Second `describe` showed all 3 containers in their expected final states
(`setup` `Terminated`/`Completed`, `log-sidecar` and `nginx` both
`Running`), and every downstream command (`exec`, both `logs -c` calls)
returned exactly the expected content.

---

## Mistake

No new `journal/mistakes-and-lessons.md` entry — this is a **recurrence**
of Mistake 003's already-documented root cause (Zscaler/x509), not a new
failure mode requiring its own entry. Recognized and fixed faster than
Day 04 specifically *because* it was already documented there.

## Lesson Learned

1. A native sidecar (`restartPolicy: Always`) changes its lifecycle
   *after* starting, not *when* it's allowed to start — it still waits
   behind every earlier `initContainers` entry.
2. `kubectl logs` only ever captures stdout/stderr — a container that
   redirects its own output to a file will correctly show empty logs; that
   is not evidence the container did nothing.
3. Recognizing a previously-documented root cause (the exact `x509` string)
   turns a second occurrence into a fast fix instead of a fresh
   investigation — this is the actual value of keeping
   `mistakes-and-lessons.md` and cheatsheets up to date.

## Troubleshooting Knowledge

```text
SYMPTOM: A multi-container Pod is stuck; some containers show
         Waiting: PodInitializing even though their own image is fine.
CHECK:   Is an EARLIER entry in spec.initContainers stuck or failing?
COMMAND: kubectl describe pod <name>   -- read Init Containers top to
         bottom, in list order.
INTERPRETATION: initContainers run strictly in sequence, including native
         sidecars (restartPolicy: Always) -- a sidecar's "always running"
         behavior only applies once it's had its turn. A stuck EARLIER
         entry blocks every later one, sidecar or main container alike.
ROOT CAUSE: Whatever is actually failing on the earliest stuck entry --
         check ITS Events, not the ones after it.
FIX:     Resolve the earliest failure first; later containers will
         proceed on their own once it clears.
PREVENTION: When a multi-container Pod looks stuck, always start reading
         Init Containers from the top -- the real problem is rarely the
         last thing you'd check first.
```

---

## Interview Questions

1. What's the practical difference between a classic init container and a
   native sidecar (`restartPolicy: Always`)?
2. If a native sidecar's image is fine but the Pod still won't start it,
   what's the first thing to check?
3. Why would `kubectl logs` return nothing for a container that clearly
   ran successfully?
4. Why does `kubectl exec`/`logs` require `-c <container>` on some Pods but
   not others?
5. What does it prove, concretely, that a main container can read a file
   an init container wrote, rather than just being told they share a
   volume?

## Challenge

Building and debugging the 3-container Pod (2 init, 1 main) served as
today's exercise, including working through a real, recurring Zscaler
incident live.

---

## End-of-Day Status

| Item | State |
|---|---|
| Manifest with init container + native sidecar + main container written | Done — correct on first attempt |
| Zscaler image-pull block recognized and fixed (recurrence of Mistake 003) | Done |
| Init-then-sidecar-then-main ordering confirmed via `describe`/Events | Done |
| Shared-volume handoff proven via `exec -c nginx` | Done |
| Sidecar persistence proven via `logs -c log-sidecar` | Done |
| Empty init-container logs explained (stdout vs. file redirection) | Done |

## Next Session

Next journal file: `journal/daily/day-08-pod-troubleshooting.md`

1. Run the resume ritual (`git pull`, `current-progress.md`,
   `check-dependencies.sh`, check `SystemInfo.md` for this machine).
2. Day 08 — Pod failures: `Pending`, `CrashLoopBackOff`, `ImagePullBackOff`
   — a dedicated break/fix day. This is also where the `Pending`/`Failed`
   phases deferred from Day 06 get their deliberate, direct treatment.
