# Detailed phase guide: what to do and how

Read `PLAN.md` first for the overview, ownership and the rules. This file breaks each phase into numbered tasks: **what to do, how, and when it is done**. Task IDs: `P<phase>-<A|K|S|ALL><n>` (A = Alvi, K = Katie, S = Steven). Give the IDs to Claude Code (see `docs/CLAUDE_PROMPTS.md`).

Hour estimates are rough guesses to help planning, not measurements.

## Team rhythm

- **Mon, Wed, Fri:** 15-minute check-in (what I finished, what blocks me, what I do next).
- **Every Friday:** 30-minute gate review. Run the gate checklist together. If it fails, decide on cuts that day.
- **Pull requests:** every merge to `main` is a PR reviewed by someone else within 24 hours. Reviewer rotation: Alvi's PRs are reviewed by Katie, Katie's by Steven, Steven's by Alvi. **No direct pushes to `main`. `main` must always be deployable.**
- **Branches:** `alvi/phase-1`, `katie/phase-1`, `steven/phase-1`, and so on. Small PRs, at least one per task.
- **File ownership** (to avoid merge conflicts): Alvi owns `Dockerfile`, `app/__init__.py`, `app/config.py`, `scripts/deploy.sh`, `loadtest/`. Katie owns `app/weather.py`, `app/stress.py`, and the routes for events, activities, plans, weather and comparisons. Steven owns `db/migrations/`, `app/db.py`, `app/auth.py`, and the routes for auth, members and decisions. Ask the owner before editing someone else's file.

## Target repository layout

```
app/
  __init__.py  config.py  db.py  auth.py  weather.py  stress.py
  routes/   auth.py events.py members.py activities.py plans.py weather.py
            comparisons.py decisions.py ops.py
  static/   index.html  app.js  style.css
db/migrations/  001_roles.sql  002_schema.sql  003_policies.sql
tests/
loadtest/  locustfile.py
scripts/   deploy.sh  seed_demo.py  seed_loadtest.py  check-authors.sh
docs/
Dockerfile  .dockerignore  requirements.txt  docker-compose.yml  .env.example
```

---

# Phase 0: Foundations (Tue 10 Nov to Fri 13 Nov)

## All

**P0-ALL1: Put the repo on GitHub (Alvi, today).**
1. github.com, New repository `ECS781P-PlanB`, **public** (the brief accepts a public GitHub URL), no README, no .gitignore.
2. In `D:\ECS781P-PlanB`: `git remote add origin <repo url>` then `git push -u origin main`.
3. Settings, Collaborators: add Katie and Steven.
4. If available, Settings, Branches: require a pull request before merging into `main`.
Done when: Katie and Steven can clone it.

**P0-ALL2: Identity and hook on each machine (Katie and Steven, Alvi checks).**
1. `git clone <url>` then `cd ECS781P-PlanB`.
2. `git config user.name "Your Name"`, `git config user.email "<email verified on your GitHub account>"`, `git config core.hooksPath .githooks`.
3. Check: `git config --list | grep user`.
4. Test the hook: `git commit --allow-empty -m "test Claude"` must be **rejected**.
5. On a branch `<name>/setup`, fill in your row in the table in `CLAUDE.md`, commit, push, open a PR.
Done when: the PR is merged and `git log` shows your own name.

**P0-ALL3: Read the module guidelines (all, 30 min).** Record the video length limit in `PLAN.md` (section 2 and section 7) and `docs/VIDEO_SCRIPT.md`. Note anything about submission format.

**P0-ALL4: Lab questions and email (Alvi, at the next lab).** Ask: does Cloud Run's default `run.app` HTTPS count for the HTTPS marks; one database login role per person or per type of user; unlisted YouTube accepted. Email Sukhpal: "Confirming we can use AI coding tools as long as we understand and can explain the code." Keep his reply.

**P0-ALL5: Kick-off meeting (all, 45 min, today or tomorrow).**
1. Read `docs/API_SPEC.md` together. Change anything unclear by PR.
2. Agree the demo cast: alice (organiser), bob (editor), cara (lead), dan (viewer), eve (outsider).
3. Agree the weather defaults: venue London (51.5074, -0.1278), tolerances per activity.
Done when: API spec approved by all three.

## Alvi (infrastructure)

**P0-A1: Google Cloud project (about 1 h).**
1. console.cloud.google.com, create project `planb-studio-<something>`. Link it to the billing account that holds the $47.76 ECS781P credit (Billing, Account management).
2. Install the Google Cloud CLI (Windows installer), then `gcloud auth login`, `gcloud config set project <PROJECT_ID>`, `gcloud config set run/region europe-west2`.
3. `gcloud services enable run.googleapis.com sqladmin.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com secretmanager.googleapis.com`
Done when: `gcloud run services list` runs without error.

**P0-A2: Budget alerts (15 min).** Billing, Budgets and alerts, Create budget, scope: this project. Amount $45. Alert thresholds at about 33, 67 and 89 percent (roughly $15, $30, $40). Add all three emails. Budgets only send alerts; they **do not stop spending**.

**P0-A3: Check the old `landobot-host` project (15 min).** In the console project selector open it and look for running Compute Engine VMs or other billable resources against the same credit. Shut down anything you do not need.

**P0-A4: Hello-world on Cloud Run (about 2 h).**
1. Create a minimal Flask app: `app/__init__.py` with `GET /healthz` and `GET /api/v1/whoami` (returns a random instance id generated once at start, and also sets `X-Served-By` on every response), `requirements.txt`, `Dockerfile` (python slim image, gunicorn with `--workers 1 --threads 8`, listens on `$PORT`), `.dockerignore`.
2. Deploy: `gcloud run deploy planb-api --source . --region europe-west2 --allow-unauthenticated --max-instances 3`
Done when: `curl https://<url>/healthz` returns 200 and `whoami` shows an instance id.

**P0-A5: Cloud SQL instance (about 2 h).**
1. Create (check `gcloud sql instances create --help`; flags change): `gcloud sql instances create planb-db --database-version=POSTGRES_16 --edition=ENTERPRISE --tier=db-f1-micro --region=europe-west2 --storage-size=10GB`
2. `gcloud sql users set-password postgres --instance=planb-db --password=<strong password>` (store it in a password manager, never in git).
3. `gcloud sql databases create planb --instance=planb-db`
4. Install the Cloud SQL Auth Proxy (cloud.google.com/sql/docs/postgres/sql-proxy), run `gcloud auth application-default login` once, then `cloud-sql-proxy <PROJECT>:europe-west2:planb-db --port 5432` in a spare terminal.
5. Connect: `psql "host=127.0.0.1 port=5432 dbname=planb user=postgres"`.
Done when: psql connects through the proxy. The `postgres` account is for migrations and admin only; **the app never uses it**.

**P0-A6: Give teammates access (30 min).** For Katie's and Steven's Google accounts: `gcloud projects add-iam-policy-binding <PROJECT_ID> --member=user:<email> --role=roles/cloudsql.client`, plus `roles/run.viewer` and `roles/logging.viewer`. Alvi stays the only person who deploys.

## Katie (weather and stress-test design)

**P0-K1: Try the real API (1 h).** From a terminal: `curl "https://api.open-meteo.com/v1/forecast?latitude=51.5074&longitude=-0.1278&hourly=precipitation_probability,precipitation,wind_speed_10m,temperature_2m&timezone=Europe%2FLondon&start_date=<today>&end_date=<today>"`. Save the output as `docs/samples/open-meteo-sample.json`. Check: the exact field names, the units block (`hourly_units`), 24 hourly values, any nulls, and what an invalid request returns. Open-Meteo's free service is for non-commercial use with attribution (CC BY 4.0): put a credit in the app footer.

**P0-K2: Write `docs/STRESS_TEST.md` (3 h).** Fill every heading. Defaults to start from (change if you can justify it): perturb precipitation probability by a random amount with standard deviation 15 percentage points (clipped to 0 to 100); perturb wind speed by a random multiplier around 1 with standard deviation 0.2; shift the whole hourly series by a random whole number of hours from -2 to +2. An outdoor activity **fails** in a run if any hour of it exceeds its `max_precip_prob` or `max_wind_kmh`. A plan is "within tolerance" in a run if no activity fails. Output per plan: share of runs within tolerance and the activity that fails most often. State clearly that the variations are our assumptions, so the output is **not** a probability of success.
Done when: another team member can explain it in one sentence.

**P0-K3: Local environment (1 h).** Install Python 3.12, Docker Desktop, VS Code. `python -m venv .venv`, activate, `pip install flask gunicorn pytest requests`.

**P0-K4: Review `docs/API_SPEC.md` (1 h).** List questions as comments on the kick-off PR.

## Steven (database and auth design)

**P0-S1: Write `docs/ROLE_DESIGN.md` (4 h).** Seven login roles including `planb_auth` (see `PLAN.md` section 5 and the notes below). For each table, list its columns, then which role may do what, then each RLS policy. Include the psql denial script outline.
Design notes to settle:
- **Who reads the users table at login?** `planb_auth`: SELECT and INSERT on `users`, SELECT on `event_members` (for the role lookup). Nothing else.
- **How does an event get its first organiser?** Any logged-in user may create an event. Do it as `planb_organiser` in one transaction with a policy allowing the insert only when `owner_id = app.user_id`, then insert the creator's `organiser` membership row.
- **How does a lead's rule work?** Update policy on `activities` for `planb_lead` requires `lead_user_id = app.user_id`.
- **Foreign keys** make cross-event references impossible at the database level (for example plan item to activity of another event): enforce with a composite key or a check.

**P0-S2: Local Postgres (3 h).** `docker-compose.yml` with `postgres:16`, mounting `db/migrations` into `/docker-entrypoint-initdb.d`. Draft `001_roles.sql` (roles), `002_schema.sql` (tables), `003_policies.sql` (GRANTs and RLS). `docker compose up` and connect with psql.

**P0-S3: Interface stubs (2 h).** Commit `app/db.py` and `app/auth.py` with the function signatures from `docs/API_SPEC.md`, full docstrings and placeholder bodies, so Katie can import them from Monday. PR to `main` by Fri 13 Nov.

**P0-S4: Reading (1 h).** PostgreSQL docs: CREATE ROLE, GRANT, and Row Security Policies. argon2-cffi README. PyJWT README.

## Gate: Fri 13 Nov

- [ ] Repo on GitHub; all three identities visible in `git log`; hook rejects a test commit
- [ ] Hello-world live over HTTPS; Cloud SQL reachable by psql through the proxy
- [ ] `STRESS_TEST.md`, `ROLE_DESIGN.md` written; `API_SPEC.md` approved
- [ ] Interface stubs on `main`
- [ ] Video length limit recorded; lecturer questions asked

If more than one item fails, cut scope now (see `PLAN.md` section 8).

---

# Phase 1: Working skeleton (Sat 14 Nov to Fri 20 Nov)

Goal: a live HTTPS URL where you can register, log in, create an event and see a real weather response cached, plus one psql denial.

## Alvi

**P1-A1: `scripts/deploy.sh` (1 h).** One command that deploys the current `main`:
`gcloud run deploy planb-api --source . --region europe-west2 --allow-unauthenticated --max-instances 3 --min-instances 0 --concurrency 4 --cpu 1 --memory 512Mi --timeout 60 --cpu-boost --add-cloudsql-instances <PROJECT>:europe-west2:planb-db --set-secrets JWT_SECRET=planb-jwt-secret:latest,DB_PASSWORDS_JSON=planb-db-passwords:latest --set-env-vars DB_NAME=planb,DB_INSTANCE_CONNECTION_NAME=<PROJECT>:europe-west2:planb-db`

**P1-A2: Secrets (1 h).**
1. JWT key: `python -c "import secrets; print(secrets.token_urlsafe(48))"`, then create a secret `planb-jwt-secret` with that value (Secret Manager, or `gcloud secrets create planb-jwt-secret --data-file=-`).
2. A second secret `planb-db-passwords`: a JSON object mapping each role name to its password (Steven generates the passwords).
3. Let the Cloud Run runtime account read them and use Cloud SQL: find the runtime account (`gcloud projects describe <PROJECT_ID> --format="value(projectNumber)"` gives the number; the default is `<NUMBER>-compute@developer.gserviceaccount.com`), then grant `roles/secretmanager.secretAccessor` and `roles/cloudsql.client` with `gcloud projects add-iam-policy-binding`.
Never put secrets in git, in the console history screenshots, or in the video.

**P1-A3: `app/config.py` and `.env.example` (1 h).** Read settings from environment variables only: `DB_INSTANCE_CONNECTION_NAME`, `DB_NAME`, `DB_PASSWORDS_JSON`, `JWT_SECRET`, `OPEN_METEO_BASE_URL` (default the real API). Locally, the database host is `localhost`; on Cloud Run it is the socket `/cloudsql/<connection name>`. `.env.example` lists names with fake values.

**P1-A4: First load-test script (2 h).** `loadtest/locustfile.py` and `scripts/seed_loadtest.py` as specified in `docs/SCALING_PLAYBOOK.md` section 3. For now test `GET /healthz` and `GET /events` only. The comparison task comes in Phase 2.

**P1-A5: HTTPS evidence (30 min).** `curl -vI https://<url>` and note the certificate issuer and expiry; `curl -I http://<url>` and note the behaviour; screenshot the browser padlock. Save notes in `docs/https_evidence.md`.

**P1-A6: Deploy Katie's and Steven's merged work** each time they ask (`sh scripts/deploy.sh`), and check `/readyz`.

## Katie

**P1-K1: Weather adapter `app/weather.py` (4 h).** `fetch_forecast(lat, lon, date)`:
- Timeout 5 seconds; up to 2 retries with a short delay on timeouts and 5xx errors.
- Map outcomes to distinct exceptions: provider 429 becomes `UpstreamRateLimited` (route returns 503 with `Retry-After`), timeout or 5xx becomes `UpstreamUnavailable` (503), a response that does not match the expected shape becomes `UpstreamBadResponse` (502).
- Base URL comes from `config.OPEN_METEO_BASE_URL` so it can be pointed at a dead host for the failure demo.
- Unit tests with mocked HTTP (`requests-mock` or `responses`); never call the real API from tests.

**P1-K2: Snapshot cache (2 h).** Table `weather_snapshots` (id, event_id, provider, query, fetched_at, expires_at, payload JSON, checksum). Cache first: if a snapshot younger than 60 minutes exists, use it.

**P1-K3: Events routes (4 h).** POST, GET list, GET one, PATCH, DELETE exactly as in `docs/API_SPEC.md`: validation, `Location` header, pagination, 404 for non-members.

**P1-K4: Weather routes (2 h).** `GET /events/{id}/weather` and `POST /events/{id}/weather/refresh`.

**P1-K5: Tests (2 h).** `tests/test_events.py` and `tests/test_weather.py` with the Flask test client against the local Postgres.

## Steven

**P1-S1: Migrations (4 h).** Finish `001_roles.sql`, `002_schema.sql`, `003_policies.sql`. Apply them locally. Then apply on Cloud SQL **as `postgres` through the Auth Proxy**: `psql "host=127.0.0.1 port=5432 dbname=planb user=postgres" -f db/migrations/001_roles.sql` and so on. Generate a strong random password for every login role, and give them to Alvi to put in `planb-db-passwords` (never in the repo).

**P1-S2: Row-level security on `events` and `event_members` (3 h).** Policies keyed on `current_setting('app.user_id')`. Test with psql: set the setting inside a transaction, confirm you see only your events.

**P1-S3: Auth (5 h).** Register and login with Argon2id (`argon2-cffi`) and PyJWT (HS256, 30 minutes). Tests: wrong password gives 401, duplicate email gives 409, short password gives 422, expired or tampered token gives 401.

**P1-S4: `app/db.py` real implementation (4 h).** One small connection pool per role (1-2 connections), created lazily; `get_conn(role, user_id)` opens a transaction and runs `set_config('app.user_id', <id>, true)` so the setting lasts only for that transaction. Never use a global "current user".

**P1-S5: psql demo script v1 (1 h).** `docs/psql_demo.sql`: commands and expected output for one denial (viewer INSERT denied) and one success (organiser INSERT works).

## Gate: Fri 20 Nov

Run this list together on the **deployed** URL:

- [ ] Register and log in (UI or curl) over HTTPS
- [ ] Create an event; it appears after a redeploy (data is in Cloud SQL)
- [ ] `POST /events/{id}/weather/refresh` returns a real forecast; a second `GET` shows `source: "cache"`
- [ ] psql shows one denial as `planb_viewer`
- [ ] The app connects with an app role, **not** `postgres` (`SELECT current_user` through the app, or check config)
- [ ] Docstring header in every file

If this fails, cut scope immediately (`PLAN.md` section 8). Do not start Phase 2 features until it passes.

---

# Phase 2: Full features (Sat 21 Nov to Fri 27 Nov)

## Katie

**P2-K1: Activities routes (4 h)** per the spec: max 20 per event, times inside the event day, the lead field rules (coordinate with Steven for the database side).
**P2-K2: Plans and plan items routes (4 h):** max 3 plans, one entry per activity per plan (409), no cross-event activities (422).
**P2-K3: Stress-test engine and comparisons (8 h).** `app/stress.py` implementing `docs/STRESS_TEST.md`: deterministic for a given seed (use a local random generator object seeded from the stored seed), stores seed, snapshot id and method version `v1` in the `comparisons` table, per-activity breakdown ("why this plan won"). Tests with tiny hand-calculated cases. **Deliver a deployable first version by Mon 23 Nov** so Alvi can start the scaling experiment. Calibrate `runs` so one call takes 0.3 to 1.0 seconds on the deployed 1-vCPU instance (Alvi measures; adjust the default or the algorithm cost honestly; no sleeps).
**P2-K4: Failure handling (2 h):** the 502/503 paths, `Retry-After`, `cached_snapshot_id` in error bodies, and a documented way to demo failure (set `OPEN_METEO_BASE_URL` to a dead host on a tagged test revision, or run locally).
**P2-K5: UI screens (6 h):** event detail with activity cards, plan builder, comparison panel with result bars, forecast strip, "Fetch live" button. Forms first; drag-and-drop only after freeze if time remains.

## Steven

**P2-S1: Members routes (3 h)** including the last-organiser protection (409).
**P2-S2: Row-level security on every table (5 h):** activities (including the lead rule), plans, plan items, comparisons, weather snapshots (`weather_ingest` writes, others read), decision log. Test each policy for each role.
**P2-S3: Decision log and routes (3 h):** `decision_log` is INSERT-only for `planb_organiser`; nobody can UPDATE or DELETE (also revoke from PUBLIC). `POST /events/{id}/commit` and `GET /events/{id}/decisions`.
**P2-S4: Full psql demo (3 h):** `docs/psql_demo.sql` and `docs/psql_demo_output.txt` (real output, run through the Auth Proxy as each role). Matches video scene 7.
**P2-S5: Cross-user tests (3 h):** user A cannot read user B's event (404); forged parent IDs rejected; role matrix tests (viewer 403, lead own activity 200 and another's 403, outsider 404).
**P2-S6: UI screens (4 h):** register, login, members and roles, decision log.

## Alvi

**P2-A1: Keep `main` deployed (ongoing).** Deploy on request and every Mon, Wed, Fri; run `/readyz` after each.
**P2-A2: Scaling experiment (8 h):** follow `docs/SCALING_PLAYBOOK.md`. Start the moment the stress endpoint is on `main` (about Mon 23 Nov). Find out early if it will not scale.
**P2-A3: Seed scripts (3 h):** `scripts/seed_demo.py` (the five demo users and the demo event) and `scripts/seed_loadtest.py` (N load-test users with events, plans and a cached snapshot). Scripts must be idempotent and use fake data.
**P2-A4: UI shell (4 h):** `app/static/index.html`, `app.js` (an `api()` helper that adds the token and shows errors), navigation, footer with the Open-Meteo credit, and a small ops panel showing `X-Served-By`.
**P2-A5: Locust comparison task (1 h)** once the endpoint exists.

## Gate: Fri 27 Nov (FEATURE FREEZE)

Do the **nine-criteria dry run** on the deployed app. Every row must be demonstrable once, however ugly:

| Criterion | Dry-run check | Pass |
|---|---|---|
| REST API | CRUD on events, activities, plans with correct codes | [ ] |
| External REST | Live refresh, cache hit, comparison changes with the forecast | [ ] |
| Cloud database | Redeploy; data survives | [ ] |
| Documentation | README draft exists; every file has a header | [ ] |
| Scaling | Run A and Run B done at least once with numbers | [ ] |
| HTTPS | Certificate details captured | [ ] |
| Hashing | Stored `$argon2id$` hash shown; tampered token 401 | [ ] |
| Accounts | Five demo users behave per role | [ ] |
| DB policies | psql denials as each role captured | [ ] |

No new features after today. Polish and drag-and-drop only if everything above passes.

---

# Phase 3: Prove it (Sat 28 Nov to Wed 2 Dec)

**P3-K1: README (4 h)**: what it is; architecture diagram; endpoint table with status codes; setup (local and cloud); deployment; teardown; AI assistance note; Open-Meteo attribution.
**P3-K2: Docstring audit (3 h):** run through every file: header comment, a docstring on every function and class explaining purpose, inputs and outputs. Documentation is a marked criterion.
**P3-S1: Test suite (4 h):** CRUD, 401/403/404, cross-user denials, auth edge cases; `pytest` passes from a clean clone.
**P3-S2: Final psql script and output (2 h)** re-run against the final deployment.
**P3-A1: Three scaling rehearsals (6 h):** follow the playbook end to end, note the numbers each time.
**P3-A2: Results file (2 h):** `docs/SCALING_RESULTS.md` with the final table and screenshots in `docs/scaling/`.
**P3-A3: Rough cut (6 h):** record every scene of `docs/VIDEO_SCRIPT.md` roughly, stitch together. Due **Wed 2 Dec**.
**P3-ALL1: Code walkthroughs (all, 3 x 30 min).** Each person walks the other two through their own code **without reading it aloud**, using the "Explain-it prompt" in `docs/CLAUDE_PROMPTS.md` to prepare. The listeners ask the questions in `docs/VIDEO_SCRIPT.md` section 4.
**P3-ALL2: Bug bash (all, 2 h):** use the app as a stranger would; file issues; fix only things that break a demo.

## Gate: Wed 2 Dec

- [ ] A rough full video exists showing all nine criteria
- [ ] README complete; every file has docstrings
- [ ] Tests pass from a clean clone
- [ ] Three scaling rehearsals done; numbers recorded
- [ ] Each member can explain every part of the system in outline

If the rough cut cannot show all nine, cut features until it can.

---

# Phase 4: Final video and clean-up (Thu 3 Dec to Sun 6 Dec)

**P4-A1: Freeze and tag (1 h).** Deploy the final `main`, then `git tag v1.0` and `git push --tags`. Confirm the deployed service matches the tag.
**P4-A2: Record the final video (6 h)** following `docs/VIDEO_SCRIPT.md`. Scene 8 in one live take. Then edit, upload to YouTube (unlisted), wait for processing, check the link in a private window.
**P4-S1: Clean-clone test (2 h).** On a different machine or fresh folder: clone, follow the README exactly, run the tests and the app locally. Fix any README gap by PR.
**P4-K1: Final documentation pass (2 h).** README matches reality (endpoints, commands, URLs); sample requests work.
**P4-ALL1: Repository audit (all, 1 h).**
- `sh scripts/check-authors.sh` lists only Alvi, Katie and Steven and reports no Claude or AI attribution
- `git grep -nEi "password|secret|api_key|token" -- . ":!docs"` and check nothing real is committed; `git ls-files | grep -E "\.env$|\.pem$|\.key$"` finds nothing
- No `Co-Authored-By` anywhere in history
- If a secret was ever committed, **rotate it** (changing the secret matters; deleting the file from git does not remove history)

---

# Phase 5: Submit (Mon 7 Dec to Tue 8 Dec)

- [ ] **Tue 8 Dec:** open the submission page and paste the **GitHub repository URL** and the **YouTube video URL**. Take a screenshot of the confirmation. All three check the links in a private browser window.
- [ ] Wed 9 and Thu 10 Dec are emergency buffer only. Do not start new work.

## After submission (11 Dec to about 24 Dec)

Sukhpal marks within a week, so the live deployment must keep working.
- [ ] Do not change the repo or the deployment.
- [ ] Check on 11, 14, 17, 21 and 24 Dec: open the URL, log in as a demo user, load an event, check `/readyz`, check billing credit.
- [ ] **When marking is finished** (after about 24 Dec, or when your grade is released), stop the bill: delete the Cloud Run service and the Cloud SQL instance, or delete the whole project.

---

# Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `permission denied for table …` | Missing GRANT for that role | Fix the GRANT in `003_policies.sql`; do not switch to `postgres` |
| Query returns 0 rows when you expected data | `app.user_id` not set for that transaction, or the RLS policy does not match | Set it with `set_config(..., true)` inside the transaction; test the policy in psql |
| UPDATE says `UPDATE 0` | RLS hid the row (expected for the wrong lead or viewer) | Check the role and policy; this is also the normal denial result |
| `password authentication failed` | Wrong role password or secret not updated | Check `planb-db-passwords`; redeploy |
| `too many connections` | Pools too big times instances | 1 connection per pool, max 3 instances; check Cloud SQL limit |
| Cloud Run cannot reach the database | Missing `--add-cloudsql-instances` or `roles/cloudsql.client` | Check the deploy command and IAM |
| Secret not found | Runtime account lacks `secretAccessor` | Grant it (P1-A2) |
| Cold start errors during tests | No warm instance | `--min-instances 1` during experiments, `--cpu-boost` |
| Open-Meteo returns 429 or errors | Too many calls | Use the cache; never call it from load tests |
| `git commit` rejected by the hook | Message mentions Claude or similar | Reword the message; check `git config user.name` is yours |
| Merge conflict in `app/__init__.py` | Two people registered blueprints | Keep both lines; ask Alvi (owner) |
| Cloud SQL Auth Proxy fails | Not logged in or wrong connection name | `gcloud auth application-default login`; `gcloud sql instances describe planb-db --format="value(connectionName)"` |

# Cost reminders

- Credit: $47.76. Alerts at $15, $30, $40.
- Cloud SQL runs all the time (needed through marking). Cloud Run costs only while serving traffic.
- After every scaling session: `gcloud run services update planb-api --region europe-west2 --min-instances 0`.
- Check the billing report after the first few days and update this plan if the estimates were wrong.
