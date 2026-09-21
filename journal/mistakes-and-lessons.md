# Mistakes and Lessons

Author: Sagar Saitwal

Accumulated record of everything that went wrong, why it went wrong, and what
the correct approach was.

**This file is never cleaned up.** A mistake stays here permanently even after
it is understood, because the diagnostic path is worth more than the answer.

---

## How to use this file

When something breaks during a lab:

1. Record the symptom **before** knowing the cause. The first guess is part of
   the record.
2. Record the commands actually used to investigate, in order.
3. Record the root cause once proven — not once suspected.
4. Record how the fix was verified.

The goal is that a future incident can be matched by symptom, not by memory.

---

## Entry template

```markdown
## Mistake NNN

Date:
Module / Topic:

### What I did

### What happened

### What I initially thought was wrong

### Why it actually happened

### Correct approach

### Commands used to diagnose

### Verification

### Lesson
```

---

## Entries

## Mistake 001

Date: 2026-09-16
Module / Topic: 01 — LAB 01 challenge (node failure detection)

### What I did

Ran `docker stop k8s-lab-worker2` to simulate a worker node failure, then
watched `kubectl get nodes -w` in another terminal for the status to change.

### What happened

Hit Ctrl+C on the watch and ran `docker start k8s-lab-worker2` to restore the
node within a few seconds — well before the 40-second grace period the theory
predicted. `kubectl get pods -n kube-system -o wide` still showed `kube-proxy`
and `kindnet` as `1/1 Running` on `worker2` at that moment.

### What I initially thought was wrong

That the experiment had run and shown no visible effect — i.e. that stopping
the node hadn't (yet) caused anything to change.

### Why it actually happened

Not enough time had elapsed for the Node Lifecycle Controller's grace period
to expire, so there was nothing to observe yet — the test was aborted before
it could produce a result, not a result of "nothing happens." Separately, the
`Running` status seen on the Pods was stale: it was the kubelet's last report
before the node went dark, not a live re-check by anything in the cluster.

### Correct approach

Re-ran the same experiment, timestamped with `date`, and left the node down
for over a minute without touching anything. `kubectl get nodes -w` then
printed `NotReady`, and `kubectl describe node`'s `Events` section showed
`(x2 over 26m)` on the `NodeNotReady` event — proving the first attempt had, in
fact, triggered a real (if very brief) transition that simply wasn't caught
live.

### Commands used to diagnose

```bash
date; docker stop k8s-lab-worker2
kubectl get nodes -w
kubectl describe node k8s-lab-worker2
```

### Verification

Second attempt measured 44 seconds from `docker stop` to the `Ready`
condition's `LastTransitionTime` flipping to `Unknown`, matching the predicted
~40s `node-monitor-grace-period`. Recovery confirmed by the same node's taint
clearing and `Ready` returning to `True` after `docker start`.

### Lesson

Before concluding a mechanism "doesn't do X," confirm the experiment actually
ran long enough for X to be possible. And a Pod's last-reported status is not
proof of its current state once its node stops reporting — it's frozen, not
re-verified.

---

## Mistake 002

Date: 2026-09-18
Module / Topic: 01 — reading `kube-scheduler.yaml` (stateless vs stateful)

### What I did

Was asked to classify `kube-scheduler.yaml` as stateless or stateful,
immediately after correctly reasoning through the same question for
`kube-apiserver.yaml` (stateless) and `etcd.yaml` (stateful — it has
`--data-dir=/var/lib/etcd` plus a real `etcd-data` volume mount).

### What happened

Answered "stateful." Wrong — `kube-scheduler` is stateless, in the same
category as `kube-apiserver`.

### What I initially thought was wrong

No specific reasoning was given at the time — the answer was a guess rather
than a check against the criterion that had just been established for `etcd`.

### Why it actually happened

Had not yet turned "stateful vs stateless" into a concrete, mechanically
repeatable test. `kube-scheduler.yaml` has no `--data-dir` flag anywhere in
its command list, and its only volume mount is:

```yaml
volumeMounts:
- mountPath: /etc/kubernetes/scheduler.conf
  name: kubeconfig
```

A `kubeconfig` file holds client credentials, not cluster data — the same
kind of file `kubectl` itself uses to talk *to* the API server. Nothing here
stores anything.

### Correct approach

Apply the exact test just confirmed on `etcd`: does the manifest have a
`--data-dir` flag AND a matching data-holding volume mount? If yes, stateful.
If the only volume is a kubeconfig or certificate file, the component is a
stateless client of the API server — restartable with zero data loss, because
it never held anything to lose.

### Commands used to diagnose

```bash
docker exec -it k8s-lab-control-plane cat /etc/kubernetes/manifests/kube-scheduler.yaml
```

Compared its `command:` flags and `volumeMounts:` directly against the
already-read `etcd.yaml` and `kube-apiserver.yaml`.

### Verification

No `--data-dir` flag present anywhere in `kube-scheduler.yaml`'s command list;
its sole volume mount is a `kubeconfig` file. This matches the stateless
pattern already confirmed for `kube-apiserver`, not the stateful pattern
confirmed for `etcd`.

### Lesson

"Stateful vs stateless" for a Kubernetes control-plane component is not a
judgment call based on how central or important a component sounds — it is a
concrete, checkable fact sitting in its own manifest. Once a test like
"data-dir + data volume, present or absent" is established on one example, it
should be applied mechanically to the next case, not re-guessed from a fresh
impression.

---

## Mistake 003

Date: 2026-09-21
Module / Topic: 01 — Day 04, image pull failure on a corporate machine

### What I did

Reapplied `nginx-trace` (Day 03's Deployment) to the cluster on a different
machine (`IT-SAGARS`), since clusters don't travel between devices.

### What happened

All 3 replicas stuck in `ErrImagePull`, then `ImagePullBackOff`. Assumed it
was Zscaler (a corporate TLS-inspecting proxy running on this machine)
without first checking the Pod's actual Events.

### What I initially thought was wrong

Suspected Zscaler correctly, but as a guess — hadn't yet looked at the exact
error text to confirm it, versus it being DNS, a network path issue, or
something else entirely.

### Why it actually happened

Confirmed via `kubectl describe pod ... | grep -A5 Events`:
```text
tls: failed to verify certificate: x509: certificate signed by unknown authority
```
Zscaler re-signs HTTPS traffic with its own certificate. Windows trusts it
because IT installed the certificate into the OS trust store. `containerd`
running inside the kind node container has its own, separate trust store,
which was never given that certificate — so it correctly rejected the
connection to `registry-1.docker.io` as untrusted.

### Correct approach

Read the exact `Events` text before naming a root cause, even when a guess
turns out right — `x509: certificate signed by unknown authority`
specifically means TLS/certificate trust, not DNS (`no such host`) or
network path (`connection refused`), and those three look identical from
the Pod's `STATUS` column alone.

### Commands used to diagnose

```bash
kubectl describe pod nginx-trace-647575f7d8-9ggck | grep -A5 Events
```

### Verification

Disabled Zscaler, then `kubectl rollout restart deployment nginx-trace` to
force fresh Pods and fresh pull attempts. All 3 Pods on the new ReplicaSet
reached `1/1 Running`.

### Lesson

A local Kubernetes cluster's container runtime has its own trust store,
independent of the host OS. Corporate TLS-inspection tooling that the
browser and OS handle transparently can still break image pulls inside
`kind`/`minikube`/any container runtime that was never given the
proxy's certificate — and the fix (disable the proxy, or import its CA into
the runtime's trust store) is different from fixing a DNS or network
problem, even though all three can present as the same `ErrImagePull`
status.

---

## Carried-over lessons from the Docker phase

Not mistakes made in this repository, but hard-won conclusions that will change
how Kubernetes problems get diagnosed. Recorded here so they are not relearned.

| Lesson | Why it matters in Kubernetes |
|---|---|
| Exit 137 alone does not prove OOM; only `OOMKilled: true` does | A Pod showing exit 137 may have been evicted, preempted, or killed by a liveness probe — not necessarily out of memory |
| A healthcheck only proves what its own command tests | A readiness probe hitting `/` can stay green while the database dependency is dead |
| Stats sampling can miss a crash loop entirely | `kubectl top` can look fine while a container is restarting between samples; `kubectl describe` is ground truth |
| A hardcoded log string is not proof of runtime state | An application logging "connected to database" proves a line was reached, not that a connection exists |
| A typo can produce a completely different failure than expected | Wrong `command:` in a Pod spec may surface as a module error, not "command not found" |
| The build cache lives in the daemon, not the shell | Cluster state lives in etcd, not in your YAML files — deleting a manifest does not delete the object |
