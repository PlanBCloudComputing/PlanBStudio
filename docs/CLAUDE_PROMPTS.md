# Claude Code prompts (copy, fill in the blanks, paste at the start of a session)

Rules that always apply are in `CLAUDE.md`. Task IDs (like `P1-K2`) are in `docs/PHASES.md`.

## Start-of-session prompt

> I am **<Alvi | Katie | Steven>**. Today I am working on **<task IDs, e.g. P1-K1 and P1-K2>** from `docs/PHASES.md`.
> First run `git config user.name` and `git config user.email` and confirm they are mine. Read `CLAUDE.md`, `docs/API_SPEC.md` and the guide for my tasks. Create or switch to my branch **<alvi|katie|steven>/phase-<N>**. Do only these tasks. Write simple, readable code with a header docstring in every file, explain what you wrote, and commit in small steps with plain messages. Do not mention Claude or AI in commit messages.

## Per-person focus lines

**Alvi:** "I own `Dockerfile`, `app/config.py`, `app/__init__.py`, `scripts/deploy.sh`, `loadtest/`, `app/static` layout shell, and the Cloud Run and Cloud SQL setup. Do not edit other members' routes or migrations."

**Katie:** "I own `app/weather.py`, `app/stress.py`, `app/routes/events.py`, `activities.py`, `plans.py`, `weather.py`, `comparisons.py` and the matching tests and UI screens. Do not edit `app/db.py`, `app/auth.py` or `db/migrations`."

**Steven:** "I own `db/migrations`, `app/db.py`, `app/auth.py`, `app/routes/auth.py`, `members.py`, `decisions.py` and the matching tests, psql scripts and UI screens. The app must never connect as a superuser or any BYPASSRLS role."

## Review prompt (when reviewing a teammate's pull request)

> Review this pull request against `CLAUDE.md` and `docs/API_SPEC.md`. Check: status codes and response shapes match the spec; every file has a header docstring; no secrets or `.env` committed; no database connection as owner, `postgres` or a bypass role; no cross-event ID leaks; tests exist. List problems as a short checklist. Do not change code unless I ask.

## Debug prompt

> This fails: <error text or command>. Read the relevant files, explain the cause in simple terms first, then propose the smallest fix. Do not widen database privileges or switch to an admin role to make it pass.

## Explain-it prompt (before the code walkthrough, Phase 3)

> Explain `<file>` to me as if I must present it to the lecturer. List each function, what it does, and the two questions an examiner is most likely to ask about it, with short answers.

## Before-merge prompt

> Run the tests, then check `git log --format='%an <%ae> %s' -n 10` shows only my identity and no mention of Claude or AI. Summarise what changed in this branch in five lines for the pull request description.
