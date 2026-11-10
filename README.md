# Plan B Studio

ECS781P Cloud Computing mini-project, Queen Mary University of London (2026-27).
Team: Alvi Hossain, Katie, Steven.

Plan B Studio helps a small organiser compare an outdoor event programme against its wet-weather fallback using a real, saved weather forecast, and tests how robust a plan is by rerunning it against many slightly altered forecasts.

> **Status:** project set-up. This README will be completed in Phase 3 (architecture diagram, endpoint table, status codes, setup, deployment, teardown). See [`PLAN.md`](PLAN.md) for the phase plan.

## Stack

Python, Flask, gunicorn, Docker, Google Cloud Run, Cloud SQL (PostgreSQL), Open-Meteo forecast API.

## Repository layout

| Path | Purpose |
|---|---|
| `PLAN.md` | Phase-by-phase plan, ownership, database design, video script, risks |
| `CLAUDE.md` | Rules for Claude Code sessions, including git commit attribution |
| `docs/ROLE_DESIGN.md` | Database login roles, GRANTs, row-level security and schema (Steven) |
| `docs/STRESS_TEST.md` | Forecast stress-test method and assumptions (Katie) |
| `.githooks/commit-msg` | Rejects commits that mention Claude/Anthropic or Co-Authored-By |
| `scripts/check-authors.sh` | Pre-submission check of commit authorship |

## AI assistance

The team used Claude Code as a coding assistant, with the lecturer's agreement. Each member reviewed, understands and can explain the code they are responsible for. Commits are made by the team member whose work it is.

## Getting started (each member, once per machine)

```
git clone <repo-url>
cd ECS781P-PlanB
git config user.name "Your Name"
git config user.email "<email verified on your GitHub account>"
git config core.hooksPath .githooks
```

Never commit `.env` files, keys or certificates.
