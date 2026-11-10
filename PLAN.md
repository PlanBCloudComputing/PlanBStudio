# ECS781P Mini-Project: Plan B Studio, Phase-by-Phase Plan

**Module:** ECS781P Cloud Computing, Queen Mary University of London
**Team:** Alvi Hossain, Katie, Steven
**Due:** Thursday 10 December 2026, 11:59pm. **Our target submission: Tuesday 8 December.**
**Lecturer:** Sukhpal (answers recorded in section 2)
**Plan written:** Tuesday 10 November 2026

> This plan assumes we are starting nearly from scratch on 10 November. If more already exists, skip ahead to the matching phase gate.
> Nothing here guarantees 40/40. Partial credit inside each criterion is the lecturer's decision. The plan is built to make every criterion visibly demonstrable.

---

## 1. What Plan B Studio is

A planning tool for small outdoor events (for example a student society's one-day programme). An organiser builds a programme as activity cards, each with a rain and wind tolerance and an indoor fallback. The app fetches a real forecast from Open-Meteo, saves the exact snapshot, and compares up to three plan versions by how many minutes fall outside each activity's tolerances.

A **forecast stress test** reruns a plan against a few hundred slightly altered forecasts and reports how often it stays within tolerance. This is both the feature that makes the weather API matter and the genuinely CPU-heavy work that makes the autoscaler react.

The organiser commits one plan. The commit is saved, with the forecast snapshot, random seed and method version it relied on, in an append-only decision log.

**Scope limits:** one venue, one day, at most 20 activities, three plans. No maps, notifications or auto-rebooking. The result is never called a "probability of success", because it depends on our assumed variations (documented in `docs/STRESS_TEST.md`).

**Stack:** Python and Flask, gunicorn, Docker, Google Cloud Run, Cloud SQL (PostgreSQL), Open-Meteo.

### Detailed guides (read these for the exact steps)

| File | What it gives you |
|---|---|
| [`docs/PHASES.md`](docs/PHASES.md) | Every task with an ID, how to do it, estimated hours, and the gate checklist for each phase. Includes commands, repo layout and troubleshooting. |
| [`docs/API_SPEC.md`](docs/API_SPEC.md) | The API contract: every endpoint, role rule, status code, and the Python interfaces the three of you share. |
| [`docs/SCALING_PLAYBOOK.md`](docs/SCALING_PLAYBOOK.md) | Exactly how to run and evidence the 10-mark scaling experiment. |
| [`docs/VIDEO_SCRIPT.md`](docs/VIDEO_SCRIPT.md) | Recording checklist and a scene-by-scene script mapped to every mark. |
| [`docs/CLAUDE_PROMPTS.md`](docs/CLAUDE_PROMPTS.md) | Copy-and-paste Claude Code prompts for each person, review and debugging. |
| [`docs/ROLE_DESIGN.md`](docs/ROLE_DESIGN.md), [`docs/STRESS_TEST.md`](docs/STRESS_TEST.md) | Design pages Steven and Katie complete in Phase 0. |

---

## 2. Lecturer's answers (Sukhpal)

| Question | Answer | What it means for us |
|---|---|---|
| Does Cloud Run's load balancing and autoscaling count for the 10 marks? | "Yes, if it works" | Use Cloud Run. We must show metrics and several instances handling requests. |
| Is Kubernetes expected? | No, it is an example | Not needed. |
| Must we show both load balancing and scaling? | Horizontal scaling and load balancing are the same if nodes are used to balance load | One experiment shows both. |
| Does Supabase Auth hashing satisfy hash-based authentication? | "If it meets the hash-based authentication, then it's fine" | Not a clear yes. We write our own Argon2id or bcrypt in Flask to remove doubt. |
| Does Row Level Security alone satisfy database role-based policies? | **No. Login roles are needed.** | Separate PostgreSQL login roles plus RLS. See section 5. |
| What is a "dynamically generated REST API"? | Both readings are fine | Dynamic JSON responses; OpenAPI docs are a bonus. |
| Cached external API responses allowed? | Yes, if the video also shows a real API call | Cache-first design with a visible "fetch live" action. |
| Time limit for the video? | Read the guidelines | **TO CHECK: video length limit.** |
| Must every member speak? | No | One voice is fine. |
| Hosting after the deadline? | He marks within a week | **Keep deployment live until about 24 December.** |
| Can we adapt lab or tutorial code? | Use as reference, write your own | See AI assistance note below. |

**Still to confirm in the lab:**
- Does Cloud Run's default HTTPS URL count for the 3 HTTPS marks? (He did not address this.)
- Does he want one database login role per person, or one per type of user? We have designed per type.
- AI-written code: the team understands this is acceptable. Send him one line to confirm in writing: *"Confirming we can use AI coding tools as long as we understand and can explain the code."*

**AI assistance:** the team uses Claude Code. Each member reviews and can explain all of their own code. A short disclosure goes in the README.

---

## 3. Who owns what

| Person | Owns | Marks it evidences |
|---|---|---|
| **Alvi** | GCP project, Cloud Run, Cloud SQL, HTTPS, scaling experiments, video recording, editing and upload | Scaling 10, HTTPS 3 |
| **Katie** | REST API, Open-Meteo adapter and cache, stress-test engine, README and docstring pass | REST 6, external API 6, documentation 1 |
| **Steven** | Database roles and row-level security, password hashing, accounts and roles, persistence | Persistence 5, hashing 3, accounts 3, database policies 3 |

Each person also builds the screens for their own features, so no one becomes a UI bottleneck. All three review each other's merges.

---

## 4. Rules for Claude Code and git (read before every session)

The full machine-readable version is in `CLAUDE.md`. Summary:

1. **One person, one machine, one session.** Each member runs Claude Code on their own laptop, in their own clone, working only on their own phase tasks. The commit author is then that machine's git identity.
2. **Commits are made as the person doing the work.** Alvi's phase work is committed as Alvi, Katie's as Katie, Steven's as Steven. Never as Claude, and never as another team member.
3. **Claude Code must never:** change `user.name` or `user.email`; use `--author` or `--reset-author`; add `Co-Authored-By` or "Generated with Claude Code" lines to commits or pull requests; mention Claude or AI in a commit message.
4. If someone is stuck, they pull the other person's branch and ask that person to commit. Nobody commits on someone else's behalf.
5. Set identity once per machine before the first session:
   - `git config user.name "Your Name"`
   - `git config user.email "<email verified on your GitHub account>"`
   - `git config core.hooksPath .githooks` (installs the commit-message check)
6. Verify with `git config --list | grep user`.
7. Commit often, one feature per commit, with plain messages such as `Add event CRUD endpoints`.
8. Pre-submission audit: `scripts/check-authors.sh` must list only Alvi, Katie and Steven.

---

## 5. Database design (agree in Phase 0, do not change casually)

Login roles are **capability tiers, not people**. Users and per-event membership live in tables (that is the "accounts" criterion). The "database policies" criterion is only what PostgreSQL itself refuses. Do not present one feature as both.

| Role | Login? | What the database allows |
|---|---|---|
| `planb_migrator` | No | Owns the tables, runs migrations. The app never connects as it. |
| `planb_auth` | Yes | Login and role lookup only: SELECT and INSERT on `users`, SELECT on `event_members`. Nothing else. |
| `planb_viewer` | Yes | SELECT only |
| `planb_editor` | Yes | SELECT, plus INSERT/UPDATE/DELETE on activities, plans and plan items |
| `planb_lead` | Yes | SELECT, plus UPDATE on activities, limited to allowed columns |
| `planb_organiser` | Yes | Editor rights, membership management, INSERT on `decision_log` |
| `weather_ingest` | Yes | Write on `weather_snapshots` only; used only by the weather adapter |

- Nobody gets UPDATE or DELETE on `decision_log`, not even the organiser (append-only).
- **Row-level security** sits on top: policies check the user's membership role on that event. Leads can only update activities assigned to them. Flask passes the user ID with a per-transaction `SET LOCAL`.
- **The app must never connect as the table owner, `postgres` or any superuser or BYPASSRLS role.** That would void the 3 database marks. `\du` in the demo should show no bypass on the app roles.
- RLS often returns zero rows or changes zero rows instead of an error. Show unchanged data, not an error we hoped for. Only an INSERT that violates a policy errors.
- Flask keeps one small pool (1-2 connections) per role, created lazily, to avoid exhausting Cloud SQL connections when Cloud Run scales. Max instances capped at 3.

---

## 6. Phase plan

Dates are 2026. Each phase ends with a **gate**. If a gate fails, cut scope immediately rather than carrying the problem forward.

> This section is the summary. The step-by-step version, with task IDs, commands and "done when" checks, is in [`docs/PHASES.md`](docs/PHASES.md).

### Phase 0: Foundations (Tue 10 Nov to Fri 13 Nov)

**All**
- [ ] First commit is `.gitignore` (already provided). Never commit `.env`, keys or certificates.
- [ ] Each member sets their own git identity and `core.hooksPath` (section 4).
- [ ] One branch per person; a teammate reviews every merge into `main`.
- [ ] Read the module guidelines: note the **video length limit** here: `____`.
- [ ] In the lab, ask Sukhpal the open questions in section 2.

**Alvi**
- [ ] Create the GCP project; set budget alerts at $15, $30 and $40.
- [ ] Check that nothing is running in the old `landobot-host` project on the same billing account.
- [ ] Deploy a hello-world Flask container to Cloud Run and note its HTTPS URL.
- [ ] Create the Cloud SQL (PostgreSQL) instance (keeps running through marking, unlike pausing free tiers). Set `--disk-size` small.

**Katie**
- [ ] Fill in `docs/STRESS_TEST.md`: what is perturbed, by how much, how the seed is stored, and how to explain it in one sentence.

**Steven**
- [ ] Fill in `docs/ROLE_DESIGN.md`: the six roles, GRANTs, RLS policies and the schema.

**Gate (Fri 13 Nov):** both design pages written; hello-world URL live; repo has all three members' identities committed.

### Phase 1: Working skeleton (Sat 14 Nov to Fri 20 Nov)

**Alvi**
- [ ] Dockerfile and gunicorn config; deploy from the repo to Cloud Run.
- [ ] Cloud SQL connection from Cloud Run; secrets via environment or Secret Manager, never in git.
- [ ] Max instances 3, low concurrency; a first Locust run against the deployed app.

**Katie**
- [ ] Open-Meteo call for a fixed venue, cached in the database with provider, query, retrieval time and expiry.
- [ ] Full CRUD on the first resource (events) with proper status codes (201 + Location, 204, 404, 422).

**Steven**
- [ ] Create the login roles and GRANTs on Cloud SQL; RLS on one table.
- [ ] Argon2id (or bcrypt) register and login written by us; wrong password rejected.
- [ ] First psql denial script (viewer INSERT denied, organiser INSERT works).

**Gate (Fri 20 Nov):** a live HTTPS URL where you can register, log in, create an event and see a real weather response cached. psql shows one denial. **If this fails, cut scope now.**

### Phase 2: Full features (Sat 21 Nov to Fri 27 Nov)

**Alvi**
- [ ] As soon as Katie's stress endpoint exists (about Mon 23 Nov), run the scaling experiment: max 1 instance vs max 3 instances, identical Locust workload.
- [ ] Capture RPS, p50/p95 latency, errors, the Cloud Run instance-count chart and request logs showing different instance IDs.
- [ ] Tune CPU and concurrency until the autoscaler visibly adds instances. **Find out now if it won't fire.**
- [ ] Confirm HTTPS evidence: certificate details, HTTP to HTTPS behaviour.

**Katie**
- [ ] Activities, plans and comparisons CRUD.
- [ ] Stress test storing seed, forecast snapshot and method version; per-activity "why this plan won" breakdown.
- [ ] Upstream failure handling: 502 for upstream down, 503 + Retry-After for rate-limited, cached fallback, and a "fetch live" action.

**Steven**
- [ ] Membership and the four roles; connection pool chosen per request.
- [ ] RLS on every table; append-only `decision_log` writable only via the organiser role.
- [ ] 401 / 403 behaviour for each role; admin-style endpoints to change roles.

**Gate (Fri 27 Nov, FEATURE FREEZE):** all nine criteria demonstrable once, however ugly. Nothing new after this.

### Phase 3: Prove it (Sat 28 Nov to Wed 2 Dec)

- [ ] **Katie:** README (architecture diagram, endpoint table, status codes, setup, deployment, teardown, AI assistance note). Docstring/header comment check in every source file.
- [ ] **Steven:** tests for CRUD, 401/403 and cross-user denials; final psql denial script.
- [ ] **Alvi:** three live, unedited scaling rehearsals; write the video script; record a rough cut by Wed 2 Dec.
- [ ] **All:** each person walks the others through their own code without reading it out (the brief says we must be able to explain what the application does and how).

**Gate (Wed 2 Dec):** a rough full video exists that shows all nine criteria. If it cannot, cut features until it can.

### Phase 4: Final video and clean-up (Thu 3 Dec to Sun 6 Dec)

- [ ] **Alvi:** record the final video (see section 7); upload to YouTube; check the visibility setting works for submission.
- [ ] **Steven:** clone the repo fresh and follow the README start to finish; confirm it runs.
- [ ] **Katie:** final documentation pass.
- [ ] **All:** run `scripts/check-authors.sh`; confirm no secrets or Claude attribution in history.

### Phase 5: Submit (Mon 7 Dec to Tue 8 Dec)

- [ ] **Submit by Tue 8 Dec.** Links needed: the git repository and the YouTube video.
- [ ] Wed 9 and Thu 10 Dec are **emergency buffer only**.

### After submission (11 Dec to about 24 Dec)

- [ ] Do not change the repo or the deployment.
- [ ] Check Cloud SQL and Cloud Run are still running; check billing credit.
- [ ] He marks within a week of submission, so the live deployment must be reachable.

---

## 7. Video plan

Time limit: `____` (TO CHECK in the guidelines). Label each scene on screen with the criterion it evidences. Warm the cache and database first. Record the scaling scene in one live, unedited take.

| # | Scene | Shows | Criterion (marks) |
|---|---|---|---|
| 1 | Live HTTPS URL | Padlock, certificate details, architecture diagram, HTTP to HTTPS | HTTPS (3) |
| 2 | Register and login | Wrong password rejected; show the stored Argon2id/bcrypt hash; explain salt and verification | Hash authentication (3) |
| 3 | REST CRUD | Event, activity and plan CRUD with status codes, including a 422 and a 404 | REST API (6) |
| 4 | External API | One real weather call, then a cache hit; compare plans and show the forecast changing a saved result; show a 502/503 fallback | External REST (6) |
| 5 | Persistence | Restart or redeploy the service; the same event, snapshot and committed plan return from Cloud SQL | Cloud database (5) |
| 6 | Accounts | Organiser, editor, lead, viewer and outsider; 401 and 403 responses; role change | User accounts and access (3) |
| 7 | Database policies | Direct psql, **no Flask**: `\du` (no bypass), `\dp`, viewer INSERT denied, editor cannot write `decision_log`, lead changes 0 rows on another's activity, organiser INSERT works but not UPDATE/DELETE, DROP TABLE denied | Database role policies (3) |
| 8 | Scaling | Locust against max 1 vs max 3 instances; instance-count chart; logs from different instance IDs; show the effect on throughput or p95 latency | Load balancing/scaling (10) |
| 9 | Documentation | Repo docstrings, README, endpoint table | Documentation (1) |

---

## 8. If we fall behind: cut in this order

1. Activity-lead role
2. Drag-and-drop
3. Multi-model forecast spread
4. "Suggest Plan B" search
5. UI polish

**Never cut:** scaling and the database login roles (13 marks), nor the working base (REST, external API, cloud database).

---

## 9. Where marks are most likely to be lost

| Risk | Mitigation |
|---|---|
| Phase 1 slips, and everything after it | Hard gates; cut scope at the first failed gate |
| Autoscaler never fires | Real CPU-heavy stress endpoint, low CPU request, low concurrency; test in Phase 2, not at the end |
| App connects as owner or superuser (database marks voided) | Review every merge; `\du` check; never connect as `postgres` |
| Weather only decorates the screen | The forecast must visibly change a saved comparison |
| Thin CRUD (no update or delete, always 200) | Proper status codes on every endpoint |
| Cloud SQL connection exhaustion during scaling | 1-2 connections per pool, lazy pools, max 3 instances |
| API outage during recording | Cache-first, warm cache, show the fallback deliberately |
| Secrets committed | `.gitignore`, never commit `.env`; check history before submission |
| Claude attribution in commits | Settings, hook and `check-authors.sh` (section 4) |
| Hosting dies before marking | Keep Cloud SQL and Cloud Run up until about 24 Dec; watch billing |
| Other coursework in these weeks | Move dates earlier, never later |

---

## 9a. Cost notes

- Credit available: $47.76 (ECS781P education credit). Check the expiry on the billing page.
- Rough estimates only: Cloud SQL f1-micro about $8 a month; Cloud Run a few cents at coursework traffic; load balancer not needed on Cloud Run. Check the billing report after the first few days.
- Never leave experiments running. Budget alerts email only; they do not stop spending.

---

## 10. Open items

- [ ] Video length limit (guidelines)
- [ ] Does Cloud Run's default HTTPS URL count for HTTPS marks?
- [ ] One DB login role per person or per type of user? (We designed per type.)
- [ ] Written confirmation that AI coding tools are acceptable
- [ ] Katie's and Steven's verified GitHub email addresses (for `CLAUDE.md` setup)
- [ ] How much of the repo already exists elsewhere (merge into this repo if so)
