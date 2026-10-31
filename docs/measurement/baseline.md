# Engineering metrics: baseline availability

Queried 2026-10-31. This report separates measurements from scenario data. The
files under `ops/` explicitly contain invented names, hosts and figures; none
of their durations or release counts are actual measurements of this
repository or a production service.

## Measured from this repository

| Metric | Actual measured value | Measurement period | Source and query | Sample size | Limitations |
| --- | --- | --- | --- | --- | --- |
| CI workflow duration | 24 s and 31 s; median **27.5 s** | 2026-10-31 (UTC) | GitHub Actions API: `GET /repos/sayali-nagarro/ai-in-sdlc/actions/runs?per_page=100`; each run's `GET /repos/sayali-nagarro/ai-in-sdlc/actions/runs/{run_id}/timing` and `run_duration_ms` | 2 completed `CI` runs, both successful pushes to `main` | Only two observations on one day. The workflow builds and tests; it does not deploy. This is CI execution time, not change lead time or a production metric. |

The two observed run IDs were `41189245644` (24,000 ms) and `41197817586`
(31,000 ms). The API reported two runs total when queried. The median is
reported as a descriptive statistic only; this sample is too small to
establish a stable baseline.

Reproduce the query against the public repository:

```sh
curl -fsS 'https://api.github.com/repos/sayali-nagarro/ai-in-sdlc/actions/runs?per_page=100' \
  | jq '.workflow_runs[] | {id, name, event, head_branch, conclusion}'
curl -fsS 'https://api.github.com/repos/sayali-nagarro/ai-in-sdlc/actions/runs/41189245644/timing' \
  | jq '.run_duration_ms'
curl -fsS 'https://api.github.com/repos/sayali-nagarro/ai-in-sdlc/actions/runs/41197817586/timing' \
  | jq '.run_duration_ms'
```

## Unavailable metrics

| Metric | Actual measured value | Measurement period | Source and query | Sample size | Why unavailable |
| --- | --- | --- | --- | --- | --- |
| Change lead time (first commit to production deployment) | **Unavailable** | Repository history checked through 2026-10-31 | GitHub API `GET /repos/sayali-nagarro/ai-in-sdlc/pulls?state=all&per_page=100` and `GET /repos/sayali-nagarro/ai-in-sdlc/deployments?per_page=100`; both returned empty lists | 0 pull requests; 0 deployments | No production deployment records exist to calculate a start-to-production interval. A CI duration is not a substitute. |
| Change failure rate | **Unavailable** | Deployment history checked through 2026-10-31 | GitHub API `GET /repos/sayali-nagarro/ai-in-sdlc/deployments?per_page=100`; returned an empty list | 0 successful deployments; no denominator | With no deployment records there is no rate to calculate. This is not a measured 0% failure rate. |
| Review turnaround | **Unavailable** | Pull-request history checked through 2026-10-31 | GitHub API `GET /repos/sayali-nagarro/ai-in-sdlc/pulls?state=all&per_page=100`; returned an empty list | 0 pull requests | No review events exist from which to calculate turnaround. |

The empty API results describe only the repository data available at query
time. They do not establish that production deployments or reviews never
happened elsewhere.

## Excluded scenario figures

`ops/pipeline/run-timings.csv` and the incident/release packs describe an
invented planned-production scenario, as documented in [ops/README.md](../../ops/README.md).
Their reported timing distribution and release/incident counts are not
measurements of this repository, and are excluded from the actual baseline.
In particular, do not report the scenario's 31.3-minute median or its
change-failure estimate as actual measurements.

## How to establish a future baseline

Capture these values from authoritative events once the relevant workflow
exists. Report the actual period, query, sample size, and limitations alongside
every statistic; keep unavailable metrics explicitly unavailable.

### Change lead time

- Record merged PR commit timestamps and the timestamp of the first successful
  production deployment for the merge SHA.
- Calculate first commit to successful deployment per change, then report the
  sample size, median, and 90th percentile.
- The repository currently has no deployment workflow or deployment records.

### Change failure rate

- Denominator: successful production deployments during the measurement window.
- Numerator: those deployments linked to an incident, rollback, or hotfix.
- Link incidents to the release that caused them; do not infer missing releases
  from version-number gaps.
- Report numerator, denominator, window, and rate. If the denominator is zero,
  report the metric as unavailable.

### Review turnaround

- For each PR, record time from ready-for-review to first substantive review
  and to approval; identify whether the reviewer was human or agent.
- Report the number of eligible PRs and the period. If there are no eligible
  PRs, report unavailable.

For future comparisons, use at least four weeks of real observations and
segment meaningful operating periods only when supported by real traffic data.
Do not treat a difference smaller than the observed variation as evidence of
improvement.
