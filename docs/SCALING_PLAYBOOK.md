# Scaling playbook (owner: Alvi) — worth 10 marks

Goal: show **in the video** that more instances handle more load, and prove it with numbers. "Effect in practice" means we run the same load twice, once restricted to one instance and once allowed three, and show the difference.

Sukhpal's answer: Cloud Run's built-in load balancing and autoscaling counts "if it works". Our job is to make it visibly work.

## 1. Why the stress test matters

A Flask endpoint that only reads one database row barely uses CPU, so the autoscaler may never add an instance. The comparison endpoint (`POST /events/{id}/comparisons`) is real CPU work: it reruns the plan against hundreds of altered forecasts. We tune it so one call takes about **0.3 to 1.0 seconds** on a 1-vCPU instance. Do **not** add sleeps or empty loops; an examiner will notice, and it is dishonest.

## 2. Settings that make scaling visible

| Setting | Value | Why |
|---|---|---|
| Container | gunicorn `--workers 1 --threads 8` | One process per instance, so each instance has one clear identity (`X-Served-By`). Python threads share one CPU core, so CPU saturates quickly. |
| `--cpu` | 1 | |
| `--memory` | 512Mi | |
| `--concurrency` | 4 to start | Low concurrency makes Cloud Run add instances earlier. Tune after the first test. |
| `--max-instances` | 1 (control run), 3 (scaled run) | |
| `--min-instances` | 1 for both runs, back to 0 afterwards | Removes cold-start noise during the experiment. Costs a little while it is set. |
| `--cpu-boost` | on | Faster start for new instances. |
| Database pool | 1-2 connections per role per instance | 3 instances times 6 pools must stay under the Cloud SQL connection limit. Check the limit for your tier. |

Cloud Run's autoscaler adds instances when request concurrency or CPU utilisation gets high (it aims for about 60 percent). That can take 30 to 90 seconds, so the load needs to run for **3 to 4 minutes**.

## 3. Load generator (loadtest/locustfile.py)

Run Locust from a laptop (`pip install locust`). Spec:

- On start, each simulated user logs in once as one of N seeded load-test users. Each of those users owns an event with 20 activities, 3 plans and a cached weather snapshot (`scripts/seed_loadtest.py` creates them).
- Task weights: `GET /events/{id}/plans` (3), `GET /plans/{id}` (3), **`POST /events/{id}/comparisons` with runs=500 (4)**, `PATCH /activities/{id}` (1). Wait 0.5 to 1.5 seconds between tasks.
- Never call the weather refresh endpoint in a load test (it would hit Open-Meteo). The comparison endpoint uses the cached snapshot.
- Record the `X-Served-By` header of every response. When the test ends, print a table: requests per instance id. This is the clearest proof of load balancing.

## 4. Experiment procedure

Replace `<URL>` with the Cloud Run URL. Commands are one line each.

**Run A: one instance**

```
gcloud run services update planb-api --region europe-west2 --min-instances 1 --max-instances 1 --concurrency 4
locust -f loadtest/locustfile.py --headless -u 40 -r 4 -t 4m --host <URL> --csv results/run_a_max1
```

**Run B: up to three instances, identical load**

```
gcloud run services update planb-api --region europe-west2 --min-instances 1 --max-instances 3 --concurrency 4
locust -f loadtest/locustfile.py --headless -u 40 -r 4 -t 4m --host <URL> --csv results/run_b_max3
```

(`-u` simulated users, `-r` users started per second, `-t` duration. `--csv` writes result files.)

**Afterwards:** `gcloud run services update planb-api --region europe-west2 --min-instances 0` to stop paying for an idle instance.

Each `update` creates a new revision that takes all traffic. That is fine; the comparison is between runs with the same workload.

## 5. What to capture each time (save in `docs/scaling/`)

| Evidence | Where | Shows |
|---|---|---|
| Locust numbers: requests per second, p50 and p95 latency, failures | Locust CSV files | The effect: higher throughput or lower latency with 3 instances |
| Requests per instance id | Locust end-of-run table | Load is spread across instances |
| Container instance count chart | Cloud Run, service page, Metrics tab | Instances rising from 1 to 2 or 3 |
| Request count, request latency, CPU utilisation charts | Same tab | Cause and effect |
| A few request logs with different `instanceId` values | Logs Explorer, filter: `resource.type="cloud_run_revision" resource.labels.service_name="planb-api"`, expand a request entry and look for the instance id label (check the exact field name in your console) | Different instances serving overlapping requests |

Console charts lag by a minute or two. Plan the on-camera run around that (see `VIDEO_SCRIPT.md`, scene 8).

## 6. Results table to fill in (`docs/SCALING_RESULTS.md`)

| Run | Max instances | Users | Peak instances seen | Requests/s | p50 ms | p95 ms | Failures |
|---|---|---|---|---|---|---|---|
| A | 1 | 40 | 1 | | | | |
| B | 3 | 40 | | | | | |

Interpret honestly. A good result: B sustains more requests per second or has much lower p95 latency, with instances visibly increasing.

## 7. If it does not scale

| Symptom | Likely cause | Fix |
|---|---|---|
| Instance count never goes above 1 | Load too light, or CPU work too small | Raise users (`-u 60`), raise `runs` to 1000 in the comparison task, lower `--concurrency` to 2 |
| Latency high but instance count stays 1 | Concurrency too high for the load pattern | Lower `--concurrency` |
| Many 500 or 503 errors | Database connection limit hit | Smaller pools (1 connection each), cap max instances at 3, check Cloud SQL connections |
| Errors only at the start | Cold starts | Set `--min-instances 1`, `--cpu-boost` |
| Locust itself is the bottleneck (CPU at 100 percent) | Laptop or Wi-Fi limit | Lower users, use wired network, or run Locust from Cloud Shell |
| B is no faster than A | Database is the bottleneck, or the endpoint is too light | Check Cloud SQL CPU in the console; tune the stress test, not the claim |

If B does not beat A after tuning, report that honestly and diagnose it. Never fake a graph.

## 8. Cost control

A few minutes at three 1-vCPU instances costs cents. The risk is leaving `--min-instances 1` set. Reset it to 0 after every experiment, and check the Cloud Run service page after each session.

## 9. Rehearsals

Do the whole sequence **three times** before recording (Phase 3). Note actual numbers each time. Record the final scene live, unedited.
