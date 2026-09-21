# Day 04 — kubectl Core Verbs and Output Formats

Author: Sagar Saitwal

| | |
|---|---|
| **Date** | 2026-09-21 |
| **Day** | 04 |
| **Module** | 01 — Kubernetes Fundamentals |
| **Topic** | kubectl core verbs and output formats |
| **Status** | COMPLETED |
| **Cluster** | `k8s-lab` — 3 nodes, Kubernetes v1.37.0, kind v0.33.0 (on `IT-SAGARS`) |

---

## Today's Objective

Build real fluency with `kubectl`'s output formats and verbs beyond the
default table view — `-o yaml`, `-o jsonpath`, `--dry-run=server`,
`-o custom-columns`, `logs`, `exec` — against a live Deployment, interpreting
every result instead of just running the command and moving on.

## Module

01 — Kubernetes Fundamentals

## Section

kubectl

## Topic

Output formats (`-o yaml`, `-o jsonpath`, `-o custom-columns`), `--dry-run=server`,
`logs`, `exec`

## Subtopic

Recovering a stopped kind node container; diagnosing `ErrImagePull` caused by
a corporate TLS-inspecting proxy; the actual scope of `--dry-run=server`

---

## Theory Learned

**`-o yaml` returns the object exactly as etcd stored it** — not the manifest
as written. Compared directly against `nginx-deployment.yaml`: the stored
object carries `resourceVersion`, `uid`, `creationTimestamp`,
`kubectl.kubernetes.io/last-applied-configuration`, and defaulted fields
(`progressDeadlineSeconds: 600`, `revisionHistoryLimit: 10`,
`imagePullPolicy: IfNotPresent`) that were never written by hand.

**`-o jsonpath` extracts one exact value, scriptable, with no trailing
newline.** `{.spec.template.spec.containers[0].image}` pulled
`nginx:1.27-alpine` straight out of the object — useful for scripts or CI,
where a human-readable table is the wrong shape. The missing newline is by
design, not a bug; it's meant to be piped, not read.

**`--dry-run=server` only runs admission on the object actually submitted —
not on anything a controller will create afterward.** This was the real
finding of the day. Day 03 showed `kube-apiserver` injecting two
`NoExecute` tolerations onto the **Pod** object via the
`DefaultTolerationSeconds` admission plugin. Today's dry-run submitted the
**Deployment**, and `grep -A3 tolerations` against its output returned
nothing — correctly. The Deployment's Pod *template* is not a Pod; the
ReplicaSet controller creates the real Pod object as a separate API call,
after the Deployment already exists, and admission only runs against a
specific request at the moment it's made. Dry-run previews that one request;
it does not simulate the reconciliation cascade it will trigger.

**`-o custom-columns` builds an arbitrary table from JSONPath-style field
selectors**, and `--sort-by` orders it by one of them. Useful whenever the
built-in `-o wide` doesn't surface the one field actually needed.

**`kubectl logs` reads what the container runtime captured from the
container's stdout/stderr.** `kubectl exec -it ... -- <cmd>` is different in
kind — it runs a *new* process inside the already-running container, live,
not a historical record.

**A stopped kind node is just a stopped Docker container**, and `docker ps`
(without `-a`) hides stopped containers entirely, which is why the
control-plane node looked "missing" instead of "stopped" at first glance.

**Image pull failures have stages.** `ErrImagePull` is the *first* failed
attempt; `ImagePullBackOff` is what the kubelet reports once it starts
backing off and retrying rather than failing immediately. Seeing one after
the other on the same Pod is expected, not two different problems.

## Why It Matters

Knowing exactly what each output format and verb actually confirms — and
what it explicitly does *not* — is what turns "I ran a command and it looked
fine" into a diagnosis that can be trusted. The dry-run finding specifically
means: never assume a dry-run against a Deployment/StatefulSet/DaemonSet has
previewed what its child Pods will look like — it hasn't.

---

## Commands Used

### `docker ps -a --filter "name=k8s-lab" --format 'table {{.Names}}\t{{.Status}}'`

- **What it does:** lists Docker containers matching a name filter, including
  stopped ones (`-a`), which plain `docker ps` hides.
- **Why I used it:** `kubectl get nodes` was refusing connections and
  `docker ps` (no `-a`) showed only 2 of 3 `k8s-lab` containers — needed to
  confirm whether the third had exited or never existed.
- **Expected output:** all three `k8s-lab-*` containers, with a `STATUS`
  column revealing which was down.
- **Actual output:** confirmed `k8s-lab-control-plane` was stopped while the
  two workers were up.

### `docker start k8s-lab-control-plane`

- **What it does:** restarts a stopped Docker container from where it left
  off — not a fresh container, the same one, same filesystem state.
- **Why I used it:** the lightest possible fix to try before assuming the
  cluster needed to be deleted and recreated.
- **Expected output:** container starts; `kubectl get nodes` should recover
  within a few seconds once the API server inside it comes back up.
- **Actual output:** worked immediately — all 3 nodes `Ready` again, no data
  lost, no recreation needed.

### `kubectl apply -f nginx-deployment.yaml`

- **What it does:** declares desired state to the API server; idempotent.
- **Why I used it:** `nginx-trace` from Day 03 does not exist on this
  cluster — it was created on `Nero`, a completely separate cluster object,
  even though both share the name `k8s-lab`.
- **Expected output:** `deployment.apps/nginx-trace created`.
- **Actual output:** exactly that, followed by all 3 Pods stuck in
  `ErrImagePull` (see Investigation, below).

### `kubectl get deployment nginx-trace -o yaml`

- **What it does:** full stored object.
- **Why I used it:** compare against the written manifest to see what
  changed on the way through the API server.
- **Actual output:** matched theory — see Theory Learned above.

### `kubectl get deployment nginx-trace -o jsonpath='{.spec.template.spec.containers[0].image}'`

- **What it does:** extracts exactly one field.
- **Actual output:** `nginx:1.27-alpine` — confirmed present, though it
  printed directly against the next shell prompt with no newline, which
  briefly looked like nothing had happened.

### `kubectl apply -f nginx-deployment.yaml --dry-run=server -o yaml | grep -A3 tolerations`

- **What it does:** previews the API server's admission/defaulting effect on
  the submitted object without persisting it.
- **Why I used it:** check whether the Day 03 toleration injection would show
  up here too.
- **Expected output (going in):** the same two `NoExecute` tolerations from
  Day 03.
- **Actual output:** nothing — correctly. See Theory Learned: the
  tolerations are injected onto the Pod, not the Deployment, and dry-run
  doesn't simulate the ReplicaSet→Pod cascade.

### `kubectl get pods -o custom-columns='NAME:.metadata.name,NODE:.spec.nodeName,RESTARTS:.status.containerStatuses[0].restartCount' --sort-by='.status.containerStatuses[0].restartCount'`

- **What it does:** arbitrary table, sorted by one field.
- **Actual output:** all 3 Pods, `RESTARTS: 0` across the board — sort had
  nothing to reorder, but the mechanism worked as expected.

### `kubectl describe pod nginx-trace-647575f7d8-9ggck | grep -A5 Events`

- **What it does:** surfaces the Pod's Events history — where the kubelet
  reports what the container runtime actually said.
- **Why I used it:** `ErrImagePull` alone doesn't say *why* the pull failed;
  the reason only lives in Events.
- **Actual output:**
  ```text
  Warning  Failed  5m31s (x5 over 8m21s)  kubelet  spec.containers{nginx}: Failed to pull image "nginx:1.27-alpine": failed to pull and unpack image "docker.io/library/nginx:1.27-alpine": failed to resolve reference "docker.io/library/nginx:1.27-alpine": failed to do request: Head "https://registry-1.docker.io/v2/library/nginx/manifests/1.27-alpine": tls: failed to verify certificate: x509: certificate signed by unknown authority
  ```

### `kubectl rollout restart deployment nginx-trace`

- **What it does:** tells the Deployment controller to recreate its Pods
  under a new ReplicaSet generation, without changing the manifest —
  reconciliation triggered manually.
- **Why I used it:** force a fresh pull attempt on all replicas after
  removing the actual blocker (see Root Cause).
- **Actual output:** `deployment.apps/nginx-trace restarted`; watched via
  `kubectl get pods -o wide -w` as the new ReplicaSet (`855cf8f8cc`) rolled
  out and the old one (`647575f7d8`) terminated. All 3 new Pods reached
  `1/1 Running`.

### `kubectl logs nginx-trace-855cf8f8cc-pqvq5`

- **Actual output:** standard nginx startup log. `worker_processes auto;` in
  `nginx.conf` produced exactly 8 worker processes — matching IT-SAGARS's
  8 CPU cores from `SystemInfo.md`. Not a coincidence: `auto` reads the
  container's visible CPU count and spawns one worker per core.

### `kubectl exec -it nginx-trace-855cf8f8cc-pqvq5 -- cat /etc/nginx/nginx.conf`

- **Actual output:** the default nginx config, unmodified — expected, since
  the manifest mounts no ConfigMap or volume. `include
  /etc/nginx/conf.d/*.conf;` is why the startup log mentioned the
  entrypoint script generating `default.conf` into that directory.

---

## YAML / Configuration

`fundamentals/labs/nginx-deployment.yaml` — same file from Day 03, reapplied
here because it did not carry over from `Nero`'s cluster (clusters are local,
not shared — see `CLAUDE.md`, MULTI-DEVICE WORKING).

---

## Lab Performed

1. Session-start check found `k8s-lab-control-plane` container stopped;
   recovered with `docker start`, no data loss.
2. Reapplied `nginx-trace` to this (different) cluster.
3. Hit `ErrImagePull` on all 3 replicas — diagnosed via `describe pod`
   Events, root-caused to a corporate TLS-inspecting proxy (Zscaler)
   intercepting the registry connection.
4. Disabled the proxy, forced a retry with `kubectl rollout restart`,
   confirmed all 3 Pods reached `Running` on a new ReplicaSet.
5. Ran the six planned output-format/verb commands against the now-healthy
   Deployment.

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

All six kubectl output-format/verb commands run and interpreted against a
healthy `nginx-trace` Deployment.

## Actual Result

Matched, plus two unplanned real incidents diagnosed and fixed along the way
— a stopped node container, and a proxy-blocked image pull — both handled
with real evidence rather than guessing.

## What Worked

- `docker ps -a` (not the default `docker ps`) was the right first move once
  a container "disappeared" — it was stopped, not gone.
- `describe pod`'s Events section again supplied the exact failure reason,
  same pattern established on Day 01-03.

## What Failed

Nothing left unresolved — both incidents were fully diagnosed and fixed
within the session.

---

## What I Broke

Nothing broken by anything I ran. Two things were found broken and fixed:

1. **`k8s-lab-control-plane` container was stopped** at session start — not
   caused by anything today, almost certainly a side effect of a Docker/WSL
   restart roughly 4 hours earlier (the two worker containers showed the
   same "Up 4 hours" age). Fixed with a plain `docker start`; no cluster
   recreation needed.
2. **All 3 `nginx-trace` Pods stuck in `ErrImagePull`** after being
   reapplied — caused by the corporate Zscaler proxy performing TLS
   inspection on this machine, which `containerd` inside the kind node
   rejected as an untrusted certificate.

## Error Message

```text
Warning  Failed  5m31s (x5 over 8m21s)  kubelet  spec.containers{nginx}: Failed to pull image "nginx:1.27-alpine": failed to pull and unpack image "docker.io/library/nginx:1.27-alpine": failed to resolve reference "docker.io/library/nginx:1.27-alpine": failed to do request: Head "https://registry-1.docker.io/v2/library/nginx/manifests/1.27-alpine": tls: failed to verify certificate: x509: certificate signed by unknown authority
```

## Investigation

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}'
docker ps -a --filter "name=k8s-lab" --format 'table {{.Names}}\t{{.Status}}'
docker start k8s-lab-control-plane
kubectl get nodes
kubectl apply -f nginx-deployment.yaml
kubectl get pods -o wide
kubectl describe pod nginx-trace-647575f7d8-9ggck | grep -A5 Events
```

`docker ps` alone made the control-plane container look absent; `-a`
revealed it as stopped, not missing. Once the cluster was healthy again,
`ErrImagePull` on all 3 Pods ruled out a node-specific problem (all 3
failed identically, on both worker nodes) — pointing at something shared by
every pull attempt, i.e. the network path out, not the cluster.
`describe pod`'s Events gave the literal TLS error, which named the actual
mechanism (certificate trust) rather than leaving it a guess.

## Root Cause

1. Control-plane container: stopped by an external event (Docker/WSL
   restart), unrelated to any Kubernetes mechanism.
2. Image pull failure: Zscaler (or an equivalent TLS-inspecting corporate
   proxy) intercepting the HTTPS connection to `registry-1.docker.io` and
   presenting its own re-signed certificate, which `containerd` inside the
   kind node — running its own independent trust store — correctly refused
   to trust.

## Solution

1. `docker start k8s-lab-control-plane`.
2. Disabled Zscaler, then `kubectl rollout restart deployment nginx-trace`
   to force fresh Pods and fresh pull attempts.

## Verification

1. `kubectl get nodes` showed all 3 `Ready` immediately after the restart.
2. `kubectl get pods -o wide -w` showed the new ReplicaSet's 3 Pods each
   reaching `1/1 Running`, while the old ReplicaSet's Pods terminated
   cleanly.

---

## Mistake

See `journal/mistakes-and-lessons.md`, **Mistake 003** — the `ErrImagePull`
incident, including the initial assumption and the corrected diagnostic
path. The stopped control-plane container is not filed separately — it was
a mechanical environment issue with a light, one-command fix, not a
misunderstanding of anything Kubernetes-specific.

## Lesson Learned

1. `docker ps` hides stopped containers by default — `-a` is required to see
   the full picture, and "container disappeared" and "container stopped"
   look identical until you check.
2. `--dry-run=server` only previews admission on the object you submit
   directly — it does not simulate what controllers will create afterward.
   Never trust it to preview a Deployment's eventual Pods.
3. On a machine behind corporate TLS inspection, image pulls inside any
   local Kubernetes cluster (kind, minikube, etc.) can fail even though the
   host's own browser/OS traffic works fine — the container runtime has its
   own trust store, separate from Windows's.
4. `ErrImagePull` → `ImagePullBackOff` is a progression, not two separate
   problems — the second is just the kubelet's retry/backoff state for the
   same unresolved failure.

## Troubleshooting Knowledge

```text
SYMPTOM: A kind node's kubectl commands suddenly refuse connections, and
         `docker ps` seems to be missing one of the cluster's containers.
CHECK:   Is the "missing" container actually stopped, not gone?
COMMAND: docker ps -a --filter "name=<cluster-name>"
INTERPRETATION: `docker ps` without -a only lists running containers —
         a stopped one looks absent, not stopped, unless you ask for all.
ROOT CAUSE: Commonly a host-level event (Docker Desktop/WSL restart, memory
         pressure, manual stop) rather than anything Kubernetes-specific.
FIX:     docker start <container-name> — kind nodes are ordinary containers;
         starting them resumes the same state, no data lost.
PREVENTION: Check `docker ps -a` (not just `docker ps`) as a standard first
         step whenever a cluster that worked before suddenly can't be
         reached.
```

```text
SYMPTOM: Pods stuck in ErrImagePull / ImagePullBackOff, on every node,
         for an image that should be pullable.
CHECK:   What does the Pod's Events section say, specifically?
COMMAND: kubectl describe pod <name> | grep -A5 Events
INTERPRETATION: "x509: certificate signed by unknown authority" means TLS
         verification failed — the container runtime received a
         certificate it does not trust, not a DNS or connectivity problem.
ROOT CAUSE: A TLS-inspecting corporate proxy (Zscaler and similar) re-signs
         HTTPS traffic with its own certificate. The OS/browser trusts it
         because IT installed it into the Windows trust store; the
         container runtime inside a kind node has its own separate trust
         store that was never given that certificate.
FIX:     Disable the proxy for the duration of the lab, or (longer-term,
         not done here) import the proxy's root CA into the node's trust
         store. Then retrigger the pull — `kubectl rollout restart
         deployment <name>`, or delete the affected Pods so their
         controller recreates them.
PREVENTION: On a corporate machine, treat any first-time ErrImagePull as a
         possible TLS-interception issue before assuming a Kubernetes or
         registry problem — check the exact Events text before guessing.
```

---

## Interview Questions

1. What is the actual difference between what `kubectl apply` writes to disk
   versus what `kubectl get -o yaml` shows you afterward?
2. Why does `-o jsonpath` output look like it produced nothing, even when it
   worked correctly?
3. `--dry-run=server` against a Deployment shows no injected tolerations,
   even though the same cluster injects them on real Pods. Why isn't this a
   contradiction?
4. What is the practical difference between `ErrImagePull` and
   `ImagePullBackOff`?
5. Why would a corporate laptop's browser work fine on the internet while a
   local Kubernetes cluster on the same machine fails every image pull?
6. Why does `docker ps` alone potentially mislead you about whether a kind
   node's container still exists?
7. What does `kubectl rollout restart` actually do differently from deleting
   and reapplying a Deployment's manifest?

## Challenge

The six planned output-format/verb commands served as the day's structured
exercise; the stopped-container recovery and the Zscaler diagnosis were
unplanned, real failures worked through live rather than staged.

---

## End-of-Day Status

| Item | State |
|---|---|
| Stopped control-plane container recovered | Done |
| `nginx-trace` recreated on this cluster | Done |
| `ErrImagePull` root-caused and fixed | Done |
| `-o yaml` | Done |
| `-o jsonpath` | Done |
| `--dry-run=server` + tolerations check | Done — new finding, not a repeat of Day 03 |
| `-o custom-columns` + `--sort-by` | Done |
| `logs` | Done |
| `exec` | Done |

## Next Session

Next journal file: `journal/daily/day-05-namespaces-labels-selectors.md`

1. Run the resume ritual (`git pull`, `current-progress.md`,
   `check-dependencies.sh`, check `SystemInfo.md` for this machine).
2. Day 05 — Namespaces, labels, selectors, annotations.
