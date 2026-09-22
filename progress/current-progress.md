# Current Kubernetes Learning Progress

Author: Sagar Saitwal

Last updated: 2026-09-22

> This file is the single source of truth for where the learning stopped.
> On any new session or new device, read this file FIRST.

**Current Day: 08**

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

Module 02 — Workloads

## Current Topic

Day 07 COMPLETED. Day 08 — Pod failures: `Pending`, `CrashLoopBackOff`,
`ImagePullBackOff` (a dedicated break/fix day) — **not yet started.** No
teaching content prepared yet.

## Current Subtopic

Day 08 has not started. This is also where the `Pending`/`Failed` phases
deliberately deferred from Day 06 get their direct treatment.

## Learning Status

🟡 IN PROGRESS

Day 00 through Day 07 are all fully COMPLETED. Day 08 is next.

## Last Completed Lab

**Day 07 — Multi-container Pods, sidecars, init containers.** COMPLETED.
Wrote a 3-container Pod by hand (`fundamentals/labs/multi-container-demo.yaml`)
— one classic init container, one native sidecar (`restartPolicy: Always`),
one main container — correct on the first attempt. Hit a recurring Zscaler
`ImagePullBackOff` on the first apply (same `x509` signature as Day 04's
Mistake 003, recognized and fixed fast). Confirmed, with real command
output: init-then-sidecar-then-main ordering; a native sidecar still waits
its turn in the init sequence despite `restartPolicy: Always`; the
shared-volume handoff (main container served the exact file the init
container wrote); sidecar persistence (`logs -c` showed it still running,
5s apart, minutes later); and why an init container that redirects its
output to a file correctly shows empty `kubectl logs`.

## Last Commands Practiced

```bash
kubectl apply -f multi-container-demo.yaml
kubectl get pod multi-container-demo -w
kubectl describe pod multi-container-demo
kubectl exec multi-container-demo -c nginx -- cat /usr/share/nginx/html/index.html
kubectl logs multi-container-demo -c log-sidecar
kubectl logs multi-container-demo -c setup
kubectl delete pod multi-container-demo
```

## Last YAML Practiced

`fundamentals/labs/multi-container-demo.yaml` — second hand-written
manifest of the course. 2 init containers (one classic, one native
sidecar) + 1 main container, sharing an `emptyDir` volume.

## What I Learned

- A second container belongs in the same Pod only for tight coupling
  (shared network/volumes/lifecycle) — an independent service is a
  separate Pod/Deployment.
- Init containers run sequentially; each must exit `0` before the next
  starts — confirmed via `Terminated`/`Completed`/exit `0` in `describe`.
- A native sidecar is an `initContainers` entry with `restartPolicy:
  Always` — it doesn't block on completion, stays alive, restarts on
  crash, and counts toward `READY`.
- A native sidecar still respects its position in the `initContainers`
  list — proven by accident when a stuck earlier entry (Zscaler) also
  blocked the sidecar, despite the sidecar's own image being fine.
- `kubectl logs`/`exec` need `-c <container>` once a Pod has more than one
  container.
- A container that redirects its output to a file (`echo ... > file`)
  correctly produces empty `kubectl logs` — not a sign anything failed.

## What I Broke

Nothing broken by the manifest. The first `apply` hit `ImagePullBackOff` on
`setup`, caused by Zscaler (recurrence of Day 04's Mistake 003), not by
anything in the YAML.

## Errors Encountered

```text
Failed to pull image "busybox:1.36": ... tls: failed to verify certificate: x509: certificate signed by unknown authority
```

## Root Cause

Zscaler TLS interception — same mechanism as Mistake 003.

## How It Was Fixed

Disabled Zscaler; deleted and reapplied the Pod fresh.

## Mistakes Made

None new — this was a **recurrence** of the already-documented Mistake 003
(Zscaler/x509), not a new failure mode. Recognized and fixed faster than
Day 04 specifically because it had already been diagnosed once.

## Important Lessons

- A previously-documented root cause (the exact `x509` error text) turns a
  second occurrence into a fast fix instead of a fresh investigation.
- When a multi-container Pod looks stuck, start reading `Init Containers`
  from the top — the real problem is rarely the last entry.

## Unresolved Issues

None blocking. Carried forward:

1. Steps 1-3 and 5 of the request flow — deferred to Day 39-41, 45, 65/80.
2. Why only some static Pods got a fresh `Age` after a node reboot —
   deferred to Day 68.
3. CoreDNS anti-affinity fix — deliberately deferred to Day 34/36.
4. All 3 `nginx-trace` Pods showed a simultaneous restart on Day 05
   (`162m ago`), not investigated — chase if it recurs.
5. `Pending`/`Failed`/`CrashLoopBackOff` phases not yet observed directly —
   deliberately deferred to **Day 08, starting next session.**

## Next Topic

Day 08 — Pod failures: `Pending`, `CrashLoopBackOff`, `ImagePullBackOff`
(dedicated break/fix day).

## Next Lab

LAB 08 — not yet written. File to create:
`journal/daily/day-08-pod-troubleshooting.md`.

## Overall Progress

Day 07 of 130 COMPLETE. Day 08 starting next session. 0 of 30 modules
completed, 1 in progress. 0 of 10 projects.

```text
[■■                            ] 5%
```

Full day-by-day plan: `progress/daily-plan.md`
