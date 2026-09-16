# Current Kubernetes Learning Progress

Author: Sagar Saitwal

Last updated: 2026-09-16

> This file is the single source of truth for where the learning stopped.
> On any new session or new device, read this file FIRST.

**Current Day: 01**

> The line above is machine-readable. `scripts/utilities/check-dependencies.sh`
> parses it to decide which dependencies this day actually requires. Keep the
> exact format `Current Day: NN` when updating it.

---

## Current Module

Module 01 — Kubernetes Fundamentals

## Current Topic

Lesson 01 — What is Kubernetes and why do we need it?

## Current Subtopic

Lab environment setup (kind on WSL2 Fedora)

## Learning Status

🟡 IN PROGRESS

Theory for Lesson 01 has been written. LAB 01 has been defined but **not yet
performed**. No Kubernetes tooling is installed and no cluster exists yet.

## Last Completed Lab

None. LAB 01 is the first lab and is not yet started.

## Last Commands Practiced

None yet in Kubernetes. Environment was inspected only:

```bash
wsl --list --verbose          # confirmed FedoraLinux-44, WSL2
uname -r                      # 6.18.33.2-microsoft-standard-WSL2
stat -fc %T /sys/fs/cgroup    # cgroup2fs
docker version                # Engine 29.7.2
```

## Last YAML Practiced

None yet.

## What I Learned

Nothing marked as learned yet — Lesson 01 theory is written but not yet
discussed or tested.

Carried forward from the Docker phase (see `Reference/DockerSummary.md`):
container vs VM model, image layers, volumes vs bind mounts, user-defined
networks and embedded DNS, PID 1 signal handling, multi-stage builds,
`OOMKilled` diagnosis via `docker inspect`.

## What I Broke

Nothing yet.

## Errors Encountered

None yet.

## Root Cause

N/A

## How It Was Fixed

N/A

## Mistakes Made

None recorded yet.

## Important Lessons

None recorded yet.

## Unresolved Issues

None. Cluster topology is decided (1 control-plane + 2 workers) and
`fundamentals/labs/kind-cluster-config.yaml` is complete.

LAB 01 is ready to run: install `kubectl`, install `kind`, create the cluster,
verify.

## Next Topic

Module 01, Lesson 02 — Kubernetes architecture: Control Plane vs Worker Node

## Next Lab

LAB 01 — Set up the Kubernetes learning environment (kind cluster on WSL2)

See `fundamentals/labs/lab-01-lab-environment-setup.md`

## Overall Progress

Day 00 of 130. 0 of 30 modules completed, 1 in progress. 0 of 10 projects.

```text
[                              ] 0%
```

Full day-by-day plan: `progress/daily-plan.md`
