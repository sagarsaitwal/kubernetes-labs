# CLAUDE.md — Working agreement for this repository

Author: Sagar Saitwal

This file is read automatically at the start of every session, on every machine.
It is the mechanism that makes this repository portable across devices.

---

## What this repository is

A long-term Kubernetes learning journey — **Day 00 to Day 130** — documented as a
public record of actual hands-on work, including every failure and fix.

It is **not** a notes dump. It is a training programme with a fixed structure,
defined in `Reference/`:

| File | Role |
|---|---|
| `Reference/LearningPrompt.md` | Repository structure, journaling rules, authorship, session procedures |
| `Reference/Learning Strategy.md` | 15-step teaching structure, 30-module syllabus |
| `Reference/LearningPath.md` | Linear topic ordering |
| `Reference/DockerSummary.md` | Verified Docker prerequisite baseline — what can be assumed known |

**Treat those four files as operating instructions, not documentation.**

---

## SESSION START PROCEDURE — do this first, every time

Before teaching, answering, or creating anything:

1. Read `progress/current-progress.md` — the single source of truth for where
   learning stopped.
2. Read the most recent file in `journal/daily/`.
3. Read `progress/next-steps.md` — the queue and any open decisions.
4. Check `progress/daily-plan.md` for the scheduled topic of the current day.
5. Summarise the previous session in 3-5 bullets.
6. State today's objective.
7. Continue from exactly where the last session stopped.

**Never restart the course from the beginning.** Never assume a session is
independent of the ones before it.

---

## SESSION END PROCEDURE

After any meaningful session, update:

| File | Update |
|---|---|
| `journal/daily/day-NN-topic.md` | Full detail — write it from `journal/TEMPLATE-daily-entry.md` |
| `progress/current-progress.md` | Overwrite with the new resume point |
| `progress/completed-topics.md` | Append **only** if theory + lab + verification + exercise all happened |
| `progress/next-steps.md` | Re-queue what is next |
| `progress/daily-plan.md` | Update the day's status; log any plan change in the Revision log |
| `journal/learning-journal.md` | Add one row to the index |
| `journal/mistakes-and-lessons.md` | Add an entry **only** if something actually broke |
| `README.md` | Module progress table and daily journal table |

Then commit and push, so the other machine can pick it up.

---

## HARD RULES

### Authorship

- The author is **Sagar Saitwal**. Only.
- **No AI attribution anywhere** — not in commits, not in `Co-Authored-By`
  trailers, not in PR descriptions, not in Markdown, YAML comments, or metadata.
- Where an author field is required: `Author: Sagar Saitwal`

### Progress honesty

- A topic is `COMPLETED` **only** when theory was understood, the lab was run,
  verification output was actually seen, and the exercise was done.
- Otherwise: `IN PROGRESS`, or `NEEDS REVISION` if completed but gaps showed.
- Never report progress that did not happen.

### Teaching

- **Design decisions are decided and explained, not delegated.** Sagar is
  learning from scratch. Never ask him to choose something whose reasoning
  requires material he has not covered — decide it, show the full reasoning,
  state whether it is reversible, and name the module after which he can
  challenge it.
- **Lab execution is his.** Give the task, let him run it, let him hit the
  error. Do not hand over the answer. Symptoms first, then progressively
  stronger hints only if he is stuck.
- Every command gets explained: what it does, what each flag means, which
  Kubernetes component is involved, what to expect.
- Deliberately break things, then make him diagnose them.

### The journal

- `journal/` records **Sagar's** learning: concepts, labs, commands, what broke,
  how it was diagnosed.
- It is **not** a log of tooling problems, editor friction, or assistant errors.
  Those get fixed silently and left out.
- Never erase history. A wrong understanding stays documented next to its
  correction.

### Public repository

- No credentials, keys, tokens, certificates, account IDs, or private
  infrastructure detail. Ever.
- Placeholders only: `<YOUR_REGION>`, `<YOUR_REGISTRY>`, `<YOUR_DOMAIN>`,
  `<YOUR_AWS_ACCOUNT_ID>`, `<YOUR_SECRET>`.
- **Run a secret scan before every push.**
- A Kubernetes Secret is base64-encoded, not encrypted. A Secret manifest with
  real values is as sensitive as a plaintext password file.

---

## MULTI-DEVICE WORKING

This repository is used from more than one machine. Two rules make that work.

### 1. Never hard-code an absolute path

The repository lives at a different path on each machine. Inside WSL, its
location is always available as `$KLAB`:

```bash
cd "$KLAB"                      # repository root
cd "$KLAB/fundamentals/labs"    # a lab directory
```

`$KLAB` is set in `~/.bashrc` by `scripts/utilities/setup-machine.sh`.

**In documentation, labs, and scripts: use `$KLAB` or a path relative to the
repository root. Never `/mnt/d/...`, never `~/kubernetes-labs`, never `D:\...`.**

### 2. The repository is the shared state, not this conversation

Anything that must survive a device switch belongs in a committed file. If it
only exists in the conversation, it is lost.

### Setting up a new machine

```bash
git clone https://github.com/sagarsaitwal/kubernetes-labs.git
cd kubernetes-labs
bash scripts/utilities/setup-machine.sh
```

The script verifies prerequisites, installs `kubectl` and `kind` if missing,
sets `$KLAB`, and records the machine's environment facts.

Per-machine environment details live in `progress/environments.md`.

### Clusters are local, not shared

A `kind` cluster exists only on the machine that created it. Switching devices
means recreating it — which is cheap, and why `kind` was chosen:

```bash
kind create cluster --name k8s-lab --config "$KLAB/fundamentals/labs/kind-cluster-config.yaml"
```

**Cluster state is disposable. Repository state is not.** Anything worth keeping
must be a committed manifest, not a live object.

---

## COMMANDS

```bash
# Where am I?
cat "$KLAB/progress/current-progress.md"

# What is today's topic?
grep -A3 "day-NN" "$KLAB/progress/daily-plan.md"

# Cluster health
kubectl get nodes -o wide
kubectl get pods -A

# Recreate the lab cluster
kind delete cluster --name k8s-lab
kind create cluster --name k8s-lab --config "$KLAB/fundamentals/labs/kind-cluster-config.yaml"
```

## Commit style

```text
docs: add Kubernetes pod fundamentals
lab: complete first pod deployment
fix: correct service selector troubleshooting steps
project: add nginx service project
chore: pin line endings to LF
```

Describe what the commit contains, never how it was produced. No trailers.

---

## Status markers

| Marker | Meaning |
|---|---|
| NOT STARTED | Not begun |
| IN PROGRESS | Partially completed |
| COMPLETED | Theory + lab + verification + exercise all done |
| NEEDS REVISION | Completed, but knowledge gaps were demonstrated |
| BLOCKED | Cannot proceed until something is resolved |
