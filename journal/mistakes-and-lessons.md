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

*No Kubernetes mistakes recorded yet. LAB 01 has not been performed.*

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
