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
   learning stopped. The `Current Day: NN` line gives the day number.
2. Read the most recent file in `journal/daily/`.
3. Read `progress/next-steps.md` — the queue and any open decisions.
4. Check `progress/daily-plan.md` for the scheduled topic of that day.
5. Check `progress/dependencies.md` for what that day requires.
6. **Verify the machine.** Run, and report the result:
   ```bash
   bash /mnt/d/Kubernetes/scripts/utilities/check-dependencies.sh
   ```

**Never restart the course from the beginning.** Never assume a session is
independent of the ones before it.

### Required format of the first response

The first response of any session must contain these four sections, in order,
before any teaching begins:

```text
1. WHERE I LEFT OFF
   Day NN, module, topic. 3-5 bullets summarising the previous session:
   what was learned, what was completed, what broke, what was unresolved.

2. MACHINE STATE
   Output of check-dependencies.sh, interpreted — not pasted raw.
   Explicitly: is this the same machine as last session, or a different one?

3. WHAT IS MISSING (if anything)
   Each missing dependency, why it is needed for this day, and the exact
   command to restore it. Distinguish clearly:
     - host tools      -> install once, permanent
     - cluster         -> local, never travels, recreate it
     - in-cluster      -> lost with the cluster, reinstall per cluster
     - credentials     -> configure per machine, never committed

4. TODAY'S OBJECTIVE
   The scheduled topic for this day, and the first concrete action.
```

**If a dependency is missing, resolve it before teaching anything.** Continuing
a lab on a machine that cannot run it produces confusing errors that look like
Kubernetes problems and are not.

### Switching machines

Clusters do not travel. A different machine will legitimately report the cluster
and every in-cluster component as missing — that is expected, not a failure.
Say so plainly, then recreate what is needed.

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

This repository is used from more than one machine. The rule is deliberately
simple: **the repository lives at the same path on every machine.**

| | Path |
|---|---|
| Windows | `D:\Kubernetes` |
| WSL / Linux | `/mnt/d/Kubernetes` |

One folder. One copy. Edited from Windows, run from WSL, synchronised through
GitHub. There is no second lab directory and nothing is copied by hand.

### Setting up a new machine

```bash
git clone https://github.com/sagarsaitwal/kubernetes-labs.git /mnt/d/Kubernetes
cd /mnt/d/Kubernetes
bash scripts/utilities/setup-machine.sh
```

The clone path is not optional — matching it is what keeps every command in this
repository valid on both machines. The script then verifies prerequisites and
installs `kubectl` and `kind` if they are missing.

Per-machine environment details: `progress/environments.md`

### The repository is the shared state, not the conversation

Anything that must survive a device switch belongs in a committed file. If it
only exists in a conversation, it is lost.

### Clusters are local, not shared

A `kind` cluster exists only on the machine that created it. Switching devices
means recreating it — cheap, and precisely why `kind` was chosen:

```bash
kind create cluster --name k8s-lab \
  --config /mnt/d/Kubernetes/fundamentals/labs/kind-cluster-config.yaml
```

**Cluster state is disposable. Repository state is not.** Anything worth keeping
must be a committed manifest, not a live object.

---

## COMMANDS

```bash
# Where am I?
cat /mnt/d/Kubernetes/progress/current-progress.md

# Cluster health
kubectl get nodes -o wide
kubectl get pods -A

# Recreate the lab cluster
kind delete cluster --name k8s-lab
kind create cluster --name k8s-lab \
  --config /mnt/d/Kubernetes/fundamentals/labs/kind-cluster-config.yaml
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
