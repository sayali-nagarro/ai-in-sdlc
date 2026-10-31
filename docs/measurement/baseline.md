# Baseline measurement plan

Capture these before the first rotation starts, so any later claim ("the agent made us faster", "the pipeline change was safe") has something to be compared with. Each metric below names the exact source. Two are captured now from what the repository and its CI history hold. One cannot be captured yet, and the reason is stated.

| Metric | Status |
| --- | --- |
| Lead time for changes | Partly captured: the CI portion only (below) |
| Change failure rate | Captured from the incident and release evidence, with a small sample (below) |
| Review turnaround | Not capturable today |

## What was captured today

### Lead time for changes: the CI part

Source: [ops/pipeline/run-timings.csv](../../ops/pipeline/run-timings.csv). Per-step durations summed per `run_number`. 20 runs, 2026-01-19 to 2026-02-02.

| Statistic | Value |
| --- | --- |
| Runs | 20 (19 with all 19 steps, 1 failed run with 17) |
| Mean | 1,880 s (31.3 min) |
| Median | 1,876 s (31.3 min) |
| 90th percentile | 2,072 s (34.5 min) |
| Fastest / slowest | 1,702 s (28.4 min) / 2,108 s (35.1 min) |

This is a floor for lead time, not lead time. A change cannot reach production faster than its pipeline, so about 31 minutes is the minimum for every change, before review and before deployment.

Command used (reproducible):

```
python3 - <<'EOF'
import csv, statistics as st, collections
runs = collections.defaultdict(int)
for row in csv.DictReader(open('ops/pipeline/run-timings.csv')):
    runs[int(row['run_number'])] += int(row['duration_seconds'])
print(st.mean(runs.values()), st.median(runs.values()))
EOF
```

**Why the real number is missing.** Lead time for changes is first commit to running in production. Production is not observable here:

- [.github/workflows](../../.github/workflows) has only `ci.yml`. There is no deploy workflow and no deployment event.
- The git history has 6 commits, by 2 authors, on 2026-10-05 and 2026-10-12, all committed directly to `main` with no pull requests. A commit-to-merge time would be zero and would mean nothing.

### Change failure rate

Definition: the share of production releases that led to a degraded service needing a rollback, a hotfix or an incident.

Sources: the release list in [INC-2047 recent-changes.md](../../ops/incidents/INC-2047/recent-changes.md) and the incident packs [INC-2041](../../ops/incidents/INC-2041/README.md) and INC-2047.

| Release | Date | Led to an incident? |
| --- | --- | --- |
| 2.14.0 | 2026-01-14 | Yes, INC-2041 (per-request `HttpClient` exhausted sockets) |
| 2.14.3 | 2026-01-16 | No. It restored the pooled handler, so it is the fix for the above |
| 2.15.0 | 2026-01-21 | No |
| 2.15.1 | 2026-01-28 | Yes, INC-2047 (event type rename silently dropped by a subscription filter) |

2 incidents from at least 6 releases is **at most 33%**. The six comes from the version numbers: 2.14.1 and 2.14.2 must exist between 2.14.0 and 2.14.3 but are not listed anywhere, so I counted them as non-failing releases. The sample is far too small to be a rate you can act on. It says only that the failures were not rare in this window.

The CI failure rate is a different thing and is not a change failure. 2 of 20 runs failed (runs 6 and 14, 10%). Both were on pull-request branches (2 of 12 PR runs), and none of the 8 runs on `main` failed. The file records only a run-level result, so I cannot say which step failed.

**Caveat on both numbers.** The `ops/` README says its names, hosts and figures are invented and that it describes the planned deployment. These are the baseline for the scenario, and they should be replaced by real data from January.

## Real GitHub data (queried 2026-10-24)

The local `gh` token is invalid (`gh auth status`: bad credentials, HTTP 401), so `gh pr list` and `gh api .../deployments` failed. I did not re-authenticate, because that needs your own login. The repository is public, so I ran the same read-only queries unauthenticated against `https://api.github.com/repos/NITIN1670/ai-in-sdlc-assignment`.

| Query | Result |
| --- | --- |
| `/pulls?state=all` (review turnaround source) | 0 pull requests |
| `/deployments` (lead time and change failure source) | 0 deployments |
| `/commits` | 6 commits, 2 authors, 2026-10-05 and 2026-10-12, all on `main` |
| `/actions/runs` | 1 run: workflow `CI`, push to `main`, conclusion `success`, 31 seconds (09:41:04 to 09:41:35 on 2026-10-14) |

What this means:

- **Review turnaround:** cannot be measured. There is nothing to measure until work goes through pull requests.
- **Lead time and change failure rate:** cannot be measured from GitHub. There are no deployment records.
- **The one real CI run took 31 seconds**, against a mean of 31.3 minutes in the invented pipeline data. That is because `.github/workflows/ci.yml` is the cut-down demo pipeline (build and test only), while `ops/pipeline/ci-pipeline.yml` is the planned full one. Both numbers are correct for their pipeline, and they must not be mixed.
- One run is not a baseline. Do not read a commit-to-run gap off it: the commit's author date (2026-10-12) is not the time it was pushed.

For the commands below, replace the placeholder `{owner}/{repo}` with `NITIN1670/ai-in-sdlc-assignment`, and re-authenticate with `gh auth login -h github.com` first if you want `gh` to work for private data.

## What to capture before the rotation, with the exact source

Capture at least four weeks, and report month-end weeks separately from the rest, because 60% of the volume falls in the last three working days and a mean across the month would hide the difference.

### 1. Lead time for changes

- First, make production observable: add a deploy job that creates a GitHub Deployment and records its status (`success`). Without it nothing below exists.
- For each merged PR: first commit time is `gh api repos/{owner}/{repo}/pulls/{n}/commits --jq '.[0].commit.committer.date'`.
- Deployment time is the `created_at` of the first successful deployment status whose SHA contains the merge commit: `gh api repos/{owner}/{repo}/deployments` and, for each, `.../deployments/{id}/statuses`.
- Report the median and the 90th percentile of the difference, not the mean.

Run on 2026-10-24: the deployments query returned an empty list (see "Real GitHub data"), and the deploy workflow it depends on does not exist yet.

### 2. Change failure rate

- Denominator: count of successful deployments in the window, from the same deployment records.
- Numerator: deployments linked to an incident, a rollback or a hotfix. Record `caused_by_release` as a required field on every incident ticket, so it is queried and not guessed.
- Also count a fix-forward release (like 2.14.3) as remediation for the release it fixes.

### 3. Review turnaround

- Source: `gh pr list --state merged --limit 200 --json number,createdAt,mergedAt,reviews` and take, per PR, the time from `createdAt` (or from marking it ready) to the first review's `submittedAt`, and also to the approval.
- Record whether the first reviewer was a person or an agent, so a later change in review use is visible.

Run on 2026-10-24: the pull request query returned an empty list. There are no pull requests in the history, so this cannot be captured today.

## Rules for using the baseline

- Do not compare across a month-end boundary without saying so.
- A before-and-after difference smaller than the spread of the baseline is noise. With three releases in a fortnight, expect most differences to be noise for a while.
- If any of these numbers becomes a target, add a counter-metric (for example, change failure rate beside lead time), because each can be improved by damaging the other.
