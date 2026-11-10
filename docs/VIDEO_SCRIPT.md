# Video script and recording guide (owner: Alvi; all three contribute)

**Length limit:** `____` (from the module guidelines; fill in). Below is a ~13-minute target. If the limit is shorter, shorten scenes 1, 5 and 9 first, then trim narration in 2, 3 and 6. **Never shorten scene 8 (scaling, 10 marks) or scene 7 (database policies, 3 marks).**

Not every member needs to speak. Suggested narration so each person explains what they built: Alvi scenes 1, 8, 9; Katie scenes 3, 4; Steven scenes 2, 5, 6, 7.

## 1. Before recording

**Evidence matrix (all must be a tick):**

| Criterion | Marks | Evidence on screen | Rehearsed |
|---|---|---|---|
| REST API | 6 | CRUD with status codes incl. 422, 404 | [ ] |
| External REST | 6 | Live weather call, cache hit, changed comparison, failure fallback | [ ] |
| Cloud database | 5 | Cloud SQL console, restart service, data survives | [ ] |
| Documentation | 1 | Docstrings, README | [ ] |
| Scaling | 10 | Run A vs B, instance chart, per-instance counts | [ ] |
| HTTPS | 3 | Certificate details, `https://` URL | [ ] |
| Hash authentication | 3 | Stored hash, wrong password, tampered token | [ ] |
| User accounts and access | 3 | Five users, 401/403/404 | [ ] |
| Database policies | 3 | psql denials as each role | [ ] |

**Environment checklist:**

- [ ] Final code deployed to Cloud Run; `main` tagged `v1.0`.
- [ ] Demo data seeded: users `alice` (organiser), `bob` (editor), `cara` (lead), `dan` (viewer), `eve` (outsider), all with fake `@example.com` emails and a throwaway password. One event "Society Summer Picnic" with 8 activities and 3 plans.
- [ ] Weather snapshot cached and fresh (refresh once shortly before recording).
- [ ] psql sessions ready: Cloud SQL Auth Proxy running; one terminal tab per role; passwords supplied through the `PGPASSWORD` environment variable set **before** recording, never typed or shown on screen.
- [ ] Locust command in a terminal tab ready; Cloud Run Metrics page open; Logs Explorer open with the filter applied.
- [ ] Browser: clean profile, no bookmarks or personal tabs; zoom 125 percent; dark text readable.
- [ ] Terminal font large (at least 16 pt). Notifications off (Windows Focus mode). Phone silent.
- [ ] No secrets visible: no `.env`, no Secret Manager values, no Google account email or billing page, no full tokens (show only the first characters).
- [ ] `--min-instances` reset to 0 afterwards (note after recording).

**Tools:** OBS Studio (free) at 1920x1080, 30 fps, microphone checked. Record each scene as its own clip, except scene 8, which is one live take. Edit in Clipchamp or DaVinci Resolve. Add on-screen title cards naming the criterion for each scene ("Scene 4: external REST API, 6 marks").

## 2. Scenes

### Scene 1: Overview and HTTPS (about 1:15) — HTTPS 3

Show: the live `https://…run.app` URL, padlock, certificate details (issuer, validity). Architecture diagram (browser, Cloud Run instances, Cloud SQL, Open-Meteo). Run `curl -I http://<url>` and show whatever happens; **do not claim an HTTP redirect unless you actually see one**.
Say: what the app is for, the stack, that Cloud Run serves it over HTTPS with a Google-managed certificate.

### Scene 2: Hash-based authentication (about 1:15) — 3

Show: register a new user in the UI; a login with the wrong password (401); a correct login. In psql as `planb_auth`, `SELECT email, password_hash FROM users` showing a value beginning `$argon2id$`. Copy the JWT, change one character, call `/users/me`: 401.
Say: passwords are hashed with Argon2id with a random salt per user, verified on login, never stored in plain text; tokens are HMAC-signed so tampering is detected.

### Scene 3: REST API (about 2:00) — 6

Show (UI plus a terminal or Postman for status codes): create an event (201 and `Location`), list and read it, PATCH an activity (200), DELETE a disposable activity (204), then an invalid duration (422) and a missing ID (404).
Say: resources, verbs, status codes, validation, pagination.

### Scene 4: External REST service (about 2:00) — 6

Show: click "Fetch live forecast". Show the request to Open-Meteo in the log and the stored snapshot (provider, time, expiry). Click again: served from cache. Run a comparison; change a plan's outdoor slot; run again; the numbers change. Show a simulated outage (tagged revision or local run with a bad base URL) returning 503 with `Retry-After` and the UI falling back to the cached snapshot.
Say: what the forecast changes in the stored decision, why we cache, how upstream failures are mapped (502 and 503).

### Scene 5: Cloud database persistence (about 1:00) — 5

Show: the Cloud SQL instance in the console (not the password page). Redeploy or restart the Cloud Run service (`gcloud run services update … --update-env-vars RESTART=<time>`), reload the app; the same event, snapshot and committed plan are still there.
Say: the application is stateless; all state is in Cloud SQL, which is why any instance can serve any request.

### Scene 6: Accounts and access management (about 1:30) — 3

Show: log in as each of alice (organiser), bob (editor), cara (lead), dan (viewer), eve (outsider). Viewer tries to edit (403). Lead edits their own activity (200) and another's (403). Outsider requests the event (404). No token (401). Organiser changes a member's role.
Say: membership per event, four roles, what each may do.

### Scene 7: Database role-based policies (about 1:30) — 3

Show **directly in psql, with Flask not involved**: `\du` (no BYPASSRLS on the app roles), `\dp`; as `planb_viewer`, INSERT denied; as `planb_editor`, UPDATE works but writing `decision_log` is denied; as `planb_lead`, updating another lead's activity changes 0 rows; as `planb_organiser`, INSERT into `decision_log` works but UPDATE and DELETE are denied; DROP TABLE denied for every app role.
Say: separate login roles with least privilege plus row-level security; the database enforces this even if the application is bypassed. Zero-row results are how row-level security hides data.

### Scene 8: Load balancing and scaling (about 3:30) — 10

Show, **one live take**: split screen with Locust, Cloud Run Metrics and the terminal.
1. Say the setup: gunicorn one process per instance, concurrency 4, 1 vCPU, same workload both runs.
2. Run A (max 1): start Locust (4 minutes). While it runs, narrate. Show rising latency and flat throughput.
3. Update to max 3 (command visible), run B with the identical command.
4. Show the instance count chart climbing to 2 or 3, the Locust table of requests per instance, Logs Explorer entries with different instance ids.
5. Show the results table: throughput and p95 for A and B.
Say: what changed, why more instances helped, and what you would do next. Pre-start Run A's Locust run before the video's voice-over if timing is tight, but keep the commands and charts on screen and unedited. Console charts lag by a minute or two; fill the time with the explanation.

### Scene 9: Documentation (about 0:45) — 1

Show: the GitHub repo, README (architecture, endpoints, status codes, setup, deployment, AI assistance note), a file header docstring, `docs/` folder.

### Closing (about 0:20)

Recap each criterion with the scene number.

## 3. After recording

1. Watch the whole video once, listening for secrets, personal information and mistakes.
2. Upload: YouTube Studio, Create, Upload videos. Title: "ECS781P Mini Project: Plan B Studio". Visibility: **Unlisted** (anyone with the link can watch; confirm with Sukhpal that unlisted is accepted).
3. Wait until HD processing finishes. Open the link in a private window to check it plays.
4. Add timestamps for each scene to the description.
5. Reset `--min-instances` to 0.

## 4. Questions each person must be able to answer

- Why does a weather planner need autoscaling? (Many organisers re-run the stress test at once; it is CPU-bound.)
- What is the stress test, in one sentence, and is it a probability? (No: it depends on our assumed variations.)
- How is a password stored and checked? What does the salt do?
- What is the difference between GRANT, row-level security and the application's role check?
- Why does Flask use a different database role per request?
- What happens if Open-Meteo is down? What if it rate-limits us?
- Why is the app stateless, and why does that matter for scaling?
- Which instance served this request, and how do you know?
- What would you change to scale beyond three instances? (Connection pooling, read replicas, caching.)
