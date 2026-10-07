# server-toolkit

A small set of bash scripts for watching a Linux server's resources, logs,
and network — built as a learning project, kept intentionally simple and
dependency-light.

## What it does

Three independent areas get checked:

- **resources** — CPU, memory, disk usage, and how fast disk is filling up
- **logs** — scans a log file for errors, rotates its own log, can combine
  several log sources into one view
- **network** — connection counts, and whether a target is reachable and
  how fast it responds

Each area can alert you when something crosses a threshold you set. Alerts
always get written to a log file, and can optionally also go out by email
or webhook.

## Layout

```
server-toolkit/
├── lib/                  shared code every script relies on
│   ├── common.sh           logging
│   ├── config.sh           all the tunable settings, in one place
│   └── alert.sh             sends alerts (log / email / webhook)
├── scripts/
│   ├── resources/
│   │   ├── sample.sh        reads current CPU/mem/disk/FDs
│   │   ├── check.sh         same, but alerts if a threshold is crossed
│   │   └── disk_growth.sh    tracks how fast disk use is growing
│   ├── logs/
│   │   ├── watch.sh         scans a log for new errors since last run
│   │   ├── rotate.sh         rotates/cleans up this toolkit's own log
│   │   └── aggregate.sh      same as watch.sh, across multiple logs
│   ├── network/
│   │   ├── sample.sh        reads current connection counts
│   │   ├── check.sh         same, but alerts if a threshold is crossed
│   │   └── reachability.sh   checks a target is up and how fast it responds
│   ├── run_all.sh          runs every script above, in order
│   └── install_cron.sh      prints (or installs) the cron line for run_all.sh
└── data/                  everything the scripts write — logs, state, archives
```

## How it works, briefly

Every script sources `lib/common.sh` (logging), `lib/config.sh` (settings),
and, if it can alert, `lib/alert.sh`. Nothing is hardcoded — thresholds,
paths, and intervals all live in `config.sh` and can be overridden with
environment variables without editing any file.

Some checks (disk growth, log scanning) need to compare "now" against "last
time this ran" — those keep a small state file in `data/` between runs.

One check can trigger another: if `network/check.sh` sees a breach, it also
runs a resource snapshot, so you have CPU/mem/disk context from that exact
moment. This is configurable (`CHAIN_SNAPSHOT_ON_BREACH`).

## How to use it

**Run one check by hand:**
```bash
./scripts/resources/check.sh
```

**Run everything** (this is what you'd point cron at):
```bash
./scripts/run_all.sh
```
It runs all nine scripts in order and keeps going even if one of them
fails — one broken check shouldn't stop the rest from reporting in.

**Change a setting**, without editing any file:
```bash
CPU_WARN_PCT=60 ./scripts/resources/check.sh
```
Anything in `lib/config.sh` can be overridden this way. A few of the more
commonly-touched ones:

| Variable | Default | What it controls |
|---|---|---|
| `CPU_WARN_PCT` / `CPU_CRIT_PCT` | 75 / 90 | CPU usage alert thresholds |
| `DISK_GROWTH_WARN_MB_PER_MIN` | 50 | how fast is "filling up too quickly" |
| `LOG_TARGET_PATH` | `data/app.log` | which log `watch.sh` scans |
| `LOG_ERROR_PATTERN` | `ERROR\|CRIT\|FATAL` | what counts as an error line |
| `REACHABILITY_TARGET` | `https://example.com` | what `reachability.sh` checks |
| `ALERT_BACKEND` | `log` | `log`, `email`, or `webhook` |
| `TOOLKIT_RUN_INTERVAL_MIN` | 5 | how often `run_all.sh` should run |

**Turn on real alerts** (email or webhook instead of just the log file):
```bash
ALERT_BACKEND=email ALERT_EMAIL_TO=you@example.com ./scripts/run_all.sh
ALERT_BACKEND=webhook ALERT_WEBHOOK_URL=https://... ./scripts/run_all.sh
```

**Schedule it:**
```bash
./scripts/install_cron.sh            # just shows you the line
./scripts/install_cron.sh --install  # actually adds it to your crontab
```
It only touches your real crontab if you pass `--install`.

## Deferred — not done, not forgotten

Small things, left for after the core was working, that only matter if
you're polishing rather than using the toolkit:

- Log file paths shown in output look messy (e.g. `scripts/logs/../../lib/../data/toolkit.log`) — works correctly, just not pretty.
- Aggregate log state filenames get long for absolute paths.
- The dual-stack (IPv6) path in network sampling has never run against real IPv6 traffic — this was only ever built and tested on an IPv4-only system.

## Known tradeoff: a broken script can take down its caller

`check.sh` in each domain reuses its paired `sample.sh` by **sourcing** it
(so both scripts share the same sampling functions instead of duplicating
them). The cost: sourced code runs in the same process, so if `sample.sh`
ever hit something fatal enough to call `exit`, it would exit `check.sh`
too — not just fail cleanly and let `check.sh` continue.

This has never actually happened in normal use — none of the sampler
scripts call `exit` in their own logic today. It only surfaced during
testing, when a script was deliberately replaced with `exit 1` to test
`run_all.sh`'s resilience. `run_all.sh` itself handled it fine (it caught
and logged the failure, and moved on to the next script) — the fragility
is specifically in the sourcing relationship between a domain's `check.sh`
and its own `sample.sh`.

**Possible fix:** have `check.sh` run `sample.sh` as a separate process
(like `run_all.sh` does with every script) instead of sourcing it. That
isolates failures completely, at the cost of losing direct function reuse —
`check.sh` would need another way to get the sampled values back (e.g.
having `sample.sh` print them in a simple parseable format). Not done yet;
