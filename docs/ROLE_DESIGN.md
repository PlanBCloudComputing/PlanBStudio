# Role design (owner: Steven) — due Fri 13 Nov

Fill this in before any database code. It drives the schema, the auth code and the psql denial demo. See the starting table in `PLAN.md` section 5.

## 1. Login roles and GRANTs

| Role | Login? | Tables and actions allowed |
|---|---|---|
| `planb_migrator` | No | Owns tables; migrations only |
| `planb_auth` | Yes | SELECT and INSERT on `users`; SELECT on `event_members`; nothing else (used for login and role lookup) |
| `planb_viewer` | Yes | |
| `planb_editor` | Yes | |
| `planb_lead` | Yes | |
| `planb_organiser` | Yes | |
| `weather_ingest` | Yes | |

## 2. Row-level security policies

For each table: which policy, which role it applies to, and the membership condition it checks. Include the lead-only-own-activity rule and the `SET LOCAL` setting Flask uses to pass the user ID.

## 3. Schema

Tables, keys, foreign keys, indexes. Include `users`, `events`, `event_members` (role per event), `activities` (the fallback is stored in `fallback_title` and `fallback_duration_minutes` columns, no separate table), `plans`, `plan_items`, `weather_snapshots`, `comparisons`, `decision_log`. Column names must match `docs/API_SPEC.md`.

Settle these before coding (see `docs/PHASES.md` task P0-S1): how an event gets its first organiser; who reads `users` at login; how the lead rule works; how foreign keys stop cross-event references.

## 4. Connection handling

One small pool per role (1-2 connections), created lazily; how Cloud Run max instances (3) keeps total connections under the Cloud SQL limit.

## 5. Demo script (psql, no Flask)

Exact commands and the output we expect: `\du` (no bypass), `\dp`, viewer INSERT denied, editor cannot write `decision_log`, lead changes 0 rows on another's activity, organiser INSERT works but UPDATE/DELETE denied, DROP TABLE denied.

## 6. Open questions for the lecturer

- One login role per person, or per type of user? (We designed per type.)
