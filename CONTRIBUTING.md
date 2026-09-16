# Contributing

Author: Sagar Saitwal

This is a personal learning repository. It documents one person's actual
hands-on Kubernetes journey, including the mistakes.

## If you are reading this to learn

You are welcome to read, clone, and run any lab here. Suggested route:

1. Read `README.md` for the roadmap and current position.
2. Read `progress/roadmap.md` to see module ordering.
3. Start at `fundamentals/` and work forward.
4. Read `journal/mistakes-and-lessons.md` early — the failures are more
   instructive than the successes.

## Conventions used in this repository

| Convention | Rule |
|---|---|
| Status markers | `⬜ NOT STARTED` `🟡 IN PROGRESS` `🟢 COMPLETED` `🔵 NEEDS REVISION` `🔴 BLOCKED` |
| Completion | A topic is only `🟢 COMPLETED` when theory was understood, the lab was run, and verification output was seen |
| Failures | Never deleted. A broken attempt stays documented next to its fix |
| Secrets | Never committed. Placeholders only: `<YOUR_REGION>`, `<YOUR_REGISTRY>`, `<YOUR_DOMAIN>` |
| Daily journal | `journal/daily/day-NN-topic.md`, one file per learning day |
| Commands | Every command documented with what it does and why it was used |

## Authorship and commits

This repository is authored by **Sagar Saitwal**. That applies to every commit,
document, manifest, and comment in it.

| Rule | Detail |
|---|---|
| Author field | `Author: Sagar Saitwal` |
| Commit trailers | None. No `Co-Authored-By` lines |
| Pull request descriptions | No generation notices or tool credits |
| Documents, YAML comments, metadata | No third-party or tooling attribution |

### Commit message style

Conventional, scoped to what the commit actually is:

```text
docs: add Kubernetes pod fundamentals
lab: complete first pod deployment
lab: document service networking exercise
fix: correct service selector troubleshooting steps
docs: update Kubernetes learning progress
project: add nginx service project
```

A commit is described by what it contains, not by how it was produced.

## Daily journal naming

```text
journal/daily/day-NN-topic.md
```

Example: `day-00-setup-and-what-is-kubernetes.md`

| Part | Purpose |
|---|---|
| `day-NN` | Learning day counter, zero-padded. Sorts in learning order. Skipped calendar days do not consume a number |
| `topic` | Short kebab-case subject, so the directory listing reads as a curriculum |

The calendar date is **not** in the filename. It lives in a metadata table at the
top of each file, alongside the day number, module, topic, status, and cluster
state.

This is deliberate: the day number is progress, the date is a fact about when
that progress happened. A week's break advances the date by seven and the day
number by zero — so numbering by day keeps the file list reading as a
curriculum rather than a calendar.

## Journal scope

`journal/` records **the learning process** — concepts studied, labs run,
commands used, things broken, and how they were diagnosed and fixed.

It is not a log of tooling problems, editor issues, or environment friction
unrelated to Kubernetes. Those get fixed and left out.

## Reporting an error

If you find something factually wrong, open an issue. Corrections are welcome —
a wrong explanation left standing defeats the purpose of the repository.
