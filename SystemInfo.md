# System Info — per-machine installation tracker

Author: Sagar Saitwal

Last updated: 2026-09-16

---

## What this file is for

This repository is worked on from more than one machine, and host tools
(`kubectl`, `kind`, ...) are installed **per machine**, not per repository —
installing something on one machine does not put it on the other.

This file answers one question fast, at the start of any session: **what does
*this specific machine* (by hostname) already have, and what is still missing
before today's work can start?**

It sits **directly under the repository root** — not inside `progress/` — so it
is the first thing found, on either OS, before anything else. Read it together
with `progress/current-progress.md`. It is a companion to two other files, not
a replacement:

| File | Answers |
|---|---|
| `SystemInfo.md` (this file) | What is installed on **which named machine**, right now |
| `progress/environments.md` | Deeper environment facts and the reasoning behind them |
| `progress/dependencies.md` | Which day first **needs** which dependency |

Whenever `check-dependencies.sh` reports a `[MISS]`, or `setup-machine.sh`
installs something, update this file for the machine it ran on. Identify a
machine by its **hostname** (`hostname`, or the `user@host` shown in the shell
prompt) — specs like Docker version or cgroup mode can look identical across
two different physical machines, so hostname is the only reliable check.

---

## Machines

### IT-SAGARS

Last verified: 2026-09-18

| Item | Value |
|---|---|
| Host OS | Windows 11 Pro 10.0.26200 |
| WSL distro | FedoraLinux-44 |
| Kernel | 6.18.33.2-microsoft-standard-WSL2 |
| Architecture | x86_64 |
| cgroup | cgroup2fs (v2 unified) |
| Docker | Engine 29.7.2 |
| CPU | 8 cores |
| Memory | 7.6 GiB total (6 GiB available at last check) |
| Disk free | 952 GiB |
| `kubectl` | v1.37.0 |
| `kind` | v0.33.0 |
| `k8s-lab` cluster | created 2026-09-16 (Day 01), **re-verified 2026-09-18** via `check-dependencies.sh` — 3/3 nodes `Ready`, server v1.37.0, uptime spans both Day 01 and Day 02 work on this machine |

### Nero

Last verified: 2026-09-16

| Item | Value |
|---|---|
| Host OS | Windows (WSL2 host) |
| WSL distro | FedoraLinux-44 |
| Kernel | 6.6.87.2-microsoft-standard-WSL2 |
| Architecture | x86_64 |
| cgroup | cgroup2fs (v2 unified) |
| Docker | Engine 29.7.2 |
| CPU | 12 cores |
| Memory | 7 GiB total |
| Disk free | 953 GiB |
| `kubectl` | v1.37.0 — installed 2026-09-16 via `setup-machine.sh` |
| `kind` | v0.33.0 — installed 2026-09-16 via `setup-machine.sh` |
| `k8s-lab` cluster | created 2026-09-16, 3/3 nodes `Ready` (verified) |

> Note from 2026-09-16: despite matching Docker version and cgroup mode with
> IT-SAGARS, this machine had **no `kubectl`, no `kind`, no cluster** — a
> reminder that similar specs do not mean the same machine. The kernel build
> number (`6.18` vs `6.6`) was the tell.

---

## Cross-machine dependency gaps

What one machine has that the other does not, as of the dates above. Re-check
with `check-dependencies.sh` at the start of every session — this table is a
snapshot, not a live source of truth.

| Dependency | IT-SAGARS | Nero | Restore command |
|---|:--:|:--:|---|
| `kubectl` v1.37.0 | present | present | `bash scripts/utilities/setup-machine.sh` |
| `kind` v0.33.0 | present | present | `bash scripts/utilities/setup-machine.sh` |
| `k8s-lab` cluster | present (unverified since Day 01) | present (verified) | `kind create cluster --name k8s-lab --config fundamentals/labs/kind-cluster-config.yaml` |
| `helm` | not yet needed (Day 49) | not yet needed (Day 49) | see `progress/dependencies.md` |
| `jq` | not yet needed (Day 55) | not yet needed (Day 55) | see `progress/dependencies.md` |

As of 2026-09-16 both machines are at parity for everything Day 01-02 needs.
No action required before continuing Day 02.

---

## Session-start checklist (either machine)

1. Confirm which machine this is: `hostname` (or read the shell prompt).
2. Find that machine's block above. If it is not listed yet, add it after
   running `setup-machine.sh`.
3. Run the live check — this file can go stale, the script cannot:
   ```bash
   bash /mnt/d/Kubernetes/scripts/utilities/check-dependencies.sh
   ```
4. Anything the script reports `[MISS]` that this file says "present" means
   drift since the last update (WSL reset, Docker reinstall, disk cleanup) —
   trust the live script, then correct this file.
5. If the cluster is missing (expected on a machine switch — clusters never
   travel):
   ```bash
   cd /mnt/d/Kubernetes/fundamentals/labs
   kind create cluster --name k8s-lab --config kind-cluster-config.yaml
   ```
6. After installing or removing anything, update this file's table for the
   machine you're on, so the *other* machine's next session starts from an
   accurate picture instead of a guess.
