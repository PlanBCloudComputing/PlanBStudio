# API specification (the contract between Alvi, Katie and Steven)

Everyone codes against this file. If something needs to change, change it here first (small PR, all three approve), then change the code.

- Prefix: `/api/v1`. JSON in and out. Timestamps are ISO 8601 UTC. IDs are UUIDs.
- Auth: `Authorization: Bearer <token>` on everything except `register`, `login`, `healthz`, `readyz` and `whoami`.
- Token: JWT signed with HMAC-SHA256 (HS256), 30-minute expiry, claims `sub` (user id), `exp`, `iat`.
- Every response carries `X-Served-By: <instance id>` so load balancing is visible.
- Errors are always `{"error": "<short_code>", "message": "<human text>"}`.

## Roles (per event)

`viewer` < `lead` < `editor` < `organiser`. A **lead** is not a general editor: a lead may change only activities assigned to them (`lead_user_id`), and only the fields listed under Activities. The role comes from the `event_members` table, not the token.

## Status code rules

| Code | When |
|---|---|
| 200 | Successful read or update |
| 201 | Created (include a `Location` header) |
| 204 | Deleted, no body |
| 400 | Malformed JSON |
| 401 | No token, bad token, expired token, wrong password |
| 403 | Logged in and a member, but the role is too low |
| 404 | Not found **or** the user is not a member of that event (hides existence) |
| 409 | Conflict: duplicate email, duplicate member, activity already in the plan, last organiser |
| 422 | Valid JSON but failed validation |
| 502 | Weather provider returned something unusable |
| 503 | Weather provider down or rate limiting us; include `Retry-After` |

## Endpoints

### Auth and users (owner: Steven)

| Method and path | Who | Body or notes | Success | Errors |
|---|---|---|---|---|
| POST `/auth/register` | anyone | `email`, `display_name`, `password` (min 10 chars) | 201 `{id,email,display_name}` | 409, 422 |
| POST `/auth/login` | anyone | `email`, `password` | 200 `{access_token, token_type:"Bearer", expires_in}` | 401 (same message for unknown email and wrong password), 422 |
| GET `/users/me` | any user | | 200 | 401 |

### Events (owner: Katie)

| Method and path | Who | Body or notes | Success | Errors |
|---|---|---|---|---|
| POST `/events` | any user | `title`, `event_date`, `timezone`, `venue_name`, `venue_lat`, `venue_lon`; creator becomes `organiser` | 201 | 401, 422 |
| GET `/events` | any user | the user's events with their role; `?limit=&offset=` | 200 | 401 |
| GET `/events/{id}` | member | | 200 | 401, 404 |
| PATCH `/events/{id}` | editor+ | any of the create fields | 200 | 401, 403, 404, 422 |
| DELETE `/events/{id}` | organiser | cascades | 204 | 401, 403, 404 |

### Members (owner: Steven)

| Method and path | Who | Body or notes | Success | Errors |
|---|---|---|---|---|
| GET `/events/{id}/members` | member | | 200 | 401, 404 |
| POST `/events/{id}/members` | organiser | `email`, `role` | 201 | 401, 403, 404 (unknown user), 409, 422 |
| PATCH `/events/{id}/members/{user_id}` | organiser | `role`; cannot remove the last organiser | 200 | 401, 403, 404, 409, 422 |
| DELETE `/events/{id}/members/{user_id}` | organiser | cannot remove the last organiser | 204 | 401, 403, 404, 409 |

### Activities (owner: Katie)

Fields: `title`, `start_time` (HH:MM), `duration_minutes` (5-480), `outdoor` (bool), `max_precip_prob` (0-100, %), `max_wind_kmh` (0-120), `lead_user_id` (optional), `fallback_title`, `fallback_duration_minutes` (optional), `notes`. Maximum 20 activities per event (422 if exceeded). Activities must fit inside the event day.

| Method and path | Who | Notes | Success | Errors |
|---|---|---|---|---|
| POST `/events/{id}/activities` | editor+ | | 201 | 401, 403, 404, 422 |
| GET `/events/{id}/activities` | member | | 200 | 401, 404 |
| GET `/activities/{id}` | member | | 200 | 401, 404 |
| PATCH `/activities/{id}` | editor+, or the assigned lead | a lead may change only `title`, `notes`, `duration_minutes`, `max_precip_prob`, `max_wind_kmh`, `fallback_title`, `fallback_duration_minutes` | 200 | 401, 403, 404, 422 |
| DELETE `/activities/{id}` | editor+ | | 204 | 401, 403, 404 |

### Plans and plan items (owner: Katie)

A plan is a named arrangement of the event's activities. Maximum 3 plans per event.

| Method and path | Who | Body or notes | Success | Errors |
|---|---|---|---|---|
| POST `/events/{id}/plans` | editor+ | `label` | 201 | 401, 403, 404, 422 (more than 3) |
| GET `/events/{id}/plans` | member | | 200 | 401, 404 |
| GET `/plans/{id}` | member | includes items | 200 | 401, 404 |
| PATCH `/plans/{id}` | editor+ | `label` | 200 | 401, 403, 404, 422 |
| DELETE `/plans/{id}` | editor+ | | 204 | 401, 403, 404 |
| POST `/plans/{id}/items` | editor+ | `activity_id`, `start_time`, `use_fallback` | 201 | 401, 403, 404, 409 (activity already in plan), 422 (activity belongs to another event) |
| PATCH `/plans/{id}/items/{item_id}` | editor+ | `start_time`, `use_fallback` | 200 | 401, 403, 404, 422 |
| DELETE `/plans/{id}/items/{item_id}` | editor+ | | 204 | 401, 403, 404 |

### Weather (owner: Katie)

| Method and path | Who | Notes | Success | Errors |
|---|---|---|---|---|
| GET `/events/{id}/weather` | member | latest cached snapshot; body has `source:"cache"`, `fetched_at`, `expires_at`, `hourly` | 200 | 401, 404 (no snapshot yet) |
| POST `/events/{id}/weather/refresh` | editor+ | live Open-Meteo call, saves a new snapshot | 201 | 401, 403, 404, 502, 503 + `Retry-After` |

Snapshot time-to-live: 60 minutes. If a refresh fails and a cached snapshot exists, the error body includes `"cached_snapshot_id"` so the UI can fall back.

### Comparisons, the stress test (owner: Katie)

| Method and path | Who | Body or notes | Success | Errors |
|---|---|---|---|---|
| POST `/events/{id}/comparisons` | editor+ | `plan_ids` (1-3), `runs` (100-5000, default 500), optional `seed`, optional `snapshot_id` (default: latest) | 201 | 401, 403, 404, 409 (no weather snapshot), 422 |
| GET `/events/{id}/comparisons` | member | | 200 | 401, 404 |
| GET `/comparisons/{id}` | member | | 200 | 401, 404 |

Result shape:

```json
{
  "id": "...", "event_id": "...", "snapshot_id": "...",
  "method_version": "v1", "seed": 12345, "runs": 500,
  "results": [
    {"plan_id": "...", "label": "Original",
     "exposure_minutes_forecast": 90,
     "share_within_tolerance": 0.82,
     "weakest_activity": {"id": "...", "title": "Rounders", "share_failing": 0.31}}
  ],
  "created_by": "...", "created_at": "..."
}
```

This is the CPU-heavy endpoint used for the scaling experiment. See `docs/STRESS_TEST.md`.

### Decisions (owner: Steven)

| Method and path | Who | Body or notes | Success | Errors |
|---|---|---|---|---|
| POST `/events/{id}/commit` | organiser | `plan_id`, `comparison_id`, optional `note`; writes one row to the append-only `decision_log` | 201 | 401, 403, 404, 422 |
| GET `/events/{id}/decisions` | member | | 200 | 401, 404 |

### Operations (owner: Alvi)

| Method and path | Who | Notes | Success | Errors |
|---|---|---|---|---|
| GET `/healthz` | anyone | no database call | 200 `{"status":"ok"}` | |
| GET `/readyz` | anyone | checks the database | 200 | 503 |
| GET `/whoami` | anyone | `{instance_id, revision}`; used in the scaling demo | 200 | |

## Validation rules (all 422)

- Email format; password at least 10 characters; display name 1-60 characters.
- `venue_lat` -90..90, `venue_lon` -180..180; `event_date` must be today or later, within 14 days for weather refresh (provider limit).
- Activity times must be inside the event day and `duration_minutes` 5-480.
- IDs in a body must belong to the same event as the URL (no cross-event references).

## Python interfaces (so the three of you can work in parallel)

Steven commits stubs of these by Fri 13 Nov. Katie and Alvi import them from the start.

```
app/db.py
  get_conn(role, user_id=None)
    Context manager. Opens a transaction on the pool for the given database role
    ('auth' | 'viewer' | 'lead' | 'editor' | 'organiser' | 'weather_ingest'),
    runs set_config('app.user_id', <user_id>, true), yields the connection,
    commits on success and rolls back on error.

app/auth.py
  require_auth       decorator: validates the token, sets g.user_id, else 401
  require_role(min)  decorator: looks up the caller's role on the event in the URL,
                     sets g.role, 404 if not a member, 403 if too low.
  role_to_pool(role) maps the membership role to the database role name to use

app/weather.py (Katie)      fetch_forecast(lat, lon, date) -> dict ; raises UpstreamError subclasses
app/stress.py  (Katie)      run_comparison(activities, plan_items, forecast, runs, seed) -> list[result]
app/config.py  (Alvi)       settings read from environment variables only
```

Routes live in `app/routes/<resource>.py` as Flask blueprints. `app/__init__.py` registers them (Alvi owns this file; add a line via PR).
