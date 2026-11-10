# CLAUDE.md — rules for Claude Code in this repository

This is the ECS781P (Cloud Computing, QMUL) mini-project "Plan B Studio". Team: Alvi Hossain, Katie, Steven. Read `PLAN.md` for the phase plan, database design and who owns what.

## Git rules (must follow, no exceptions)

1. **Commit only with the git identity already configured on this machine.** Run `git config user.name` and `git config user.email` at the start of the session and tell the user what they are. The user is the author of every commit made in their session.
2. **Never change `user.name` or `user.email`**, locally or globally. Never use `--author` or `--reset-author`. Never set `GIT_AUTHOR_*` or `GIT_COMMITTER_*` environment variables.
3. **Never add** `Co-Authored-By` trailers, "Generated with Claude Code", or any mention of Claude, Anthropic or AI to commit messages, PR titles or PR descriptions. Commit messages are short, plain and in the imperative, for example `Add event CRUD endpoints`.
4. **Never commit on behalf of another team member.** If the user asks for work that belongs to someone else's phase tasks, say so and stop; they should ask that person.
5. **Work only on the tasks the user names** (their own phase tasks and files in `PLAN.md`). Do not edit another member's area. Work on the user's own branch, never directly on `main`.
6. One feature per commit. Do not squash other people's commits or rewrite shared history. Never force-push.
7. **Never commit** `.env` files, keys, certificates, passwords, tokens or service-account JSON. If you notice one staged, unstage it and tell the user.

## Project rules

- **Every source file needs a header docstring or comment** explaining its purpose and any important logic. Documentation is a marked criterion.
- **Never connect to the database as the table owner, `postgres` or any superuser/BYPASSRLS role.** The app connects only as `planb_viewer`, `planb_editor`, `planb_lead`, `planb_organiser` or `weather_ingest`. Connecting with a bypass role voids the database-policy marks. If a connection fails, fix the grants or policy; do not switch to an admin role "to make it work".
- Hash passwords with Argon2id (or bcrypt) written by the team in Flask. Do not delegate hashing to a third-party auth service.
- Return proper HTTP status codes (201 + Location, 204, 400, 401, 403, 404, 409, 422, 502, 503 + Retry-After).
- Never hit the Open-Meteo API from a load test; use the database cache.
- The application must remain stateless (no local sessions, files or SQLite) so Cloud Run replicas behave identically.
- Do not add features beyond the scope in `PLAN.md` before the Phase 2 feature freeze, and none after it.
- The team must be able to explain every line. Prefer simple, readable code over clever code, and explain what you wrote when asked.

## Start-of-session template (the user pastes this)

> I am **<name>**, working on **<Phase N tasks from PLAN.md>**. Check `git config user.name` and `git config user.email`, confirm they match me, then follow `CLAUDE.md`.

## Per-member identity setup (once per machine)

```
git config user.name "Your Name"
git config user.email "<email verified on your GitHub account>"
git config core.hooksPath .githooks
git config --list | grep user
```

| Member | Name for git | Email | Verified on GitHub |
|---|---|---|---|
| Alvi | Alvi Hossain | alvi997@outlook.com | [ ] confirm |
| Katie | (fill in) | (fill in) | [ ] |
| Steven | (fill in) | (fill in) | [ ] |

## Safeguards already in the repo

- `.githooks/commit-msg` rejects any commit whose message mentions Claude, Anthropic, "Generated with" or `Co-Authored-By`, or whose author identity mentions Claude or Anthropic. Enabled by `git config core.hooksPath .githooks`.
- `.claude/settings.json` switches off Claude Code's automatic commit and PR attribution. If your installed version still adds a trailer, the hook will reject the commit; remove the trailer and commit again.
- `scripts/check-authors.sh` lists every commit author and fails if any commit or message mentions Claude or Anthropic. Run it before submission.
