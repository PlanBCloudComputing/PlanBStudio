# Forecast stress test (owner: Katie) — due Fri 13 Nov

Fill this in before writing the engine. Every team member must be able to explain it in one sentence.

**One-sentence explanation (write it first):**

> (e.g. "We rerun the saved plan against N slightly altered copies of the real forecast and report the share of runs in which no activity exceeds its tolerance.")

## 1. What is perturbed

Which forecast fields (precipitation probability, wind speed, temperature), and whether a front can shift in time (for example plus or minus 2 hours).

## 2. How much

The size and distribution of each perturbation, and why it is reasonable. State plainly that these are our assumptions, not a statistical model of forecast error.

## 3. Reproducibility

How the random seed, forecast snapshot ID and method version are stored with every saved comparison, so the same inputs always give the same result.

## 4. Output

What the endpoint returns (for example the share of runs within tolerance, and the weakest activity). Never present it as a "probability of success".

## 5. Cost and scaling

Number of variations options (for example 500 / 2000 / 5000), the real CPU work involved, and the CPU request and concurrency we will use on Cloud Run so that load visibly triggers autoscaling. No artificial sleeps or padded loops.

## 6. Tests

Hand-calculated small examples the engine must match.
