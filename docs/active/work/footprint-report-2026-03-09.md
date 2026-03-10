# haul-page Footprint Report — 2026-03-09

System: Mac Mini M4, 10-core, 16GB unified memory. Observed during normal
multi-repo workload (2 lisa loops + Claude Code sessions active).

## Summary

haul-page's total footprint is **~6.5 GB** — roughly 40% of system RAM.
Docker infrastructure is the dominant cost, not the application itself.

## Breakdown

### Docker VM (the big number)

| Process | RSS | Notes |
|---------|-----|-------|
| `com.docker.krun` | **4.7 GB** | The lightweight VM. This is the floor cost of running Docker Desktop on Apple Silicon. |
| Docker Desktop (Electron) | 179 MB | Renderer process |
| `com.docker.backend` (×3) | 195 MB total | API server, build engine |
| Desktop Helper (GPU) | 54 MB | |
| `cagent` | 21 MB | Docker telemetry agent |
| `com.docker.build` | 23 MB | BuildKit |
| **Docker total** | **~5.2 GB** | |

**Docker VM is allocated 6 CPUs and ~5.8 GB RAM.** These are the Docker Desktop
defaults — not tuned for this workload.

### haul-pg Container

| Metric | Value |
|--------|-------|
| Container memory | 1.44 GB (of 5.8 GB VM limit) |
| CPU | 0.23% |
| Network I/O | 1.72 GB in / 963 MB out (cumulative) |
| Block I/O | 8.47 MB read / **36.8 GB written** |
| Resource limits | **None set** (0 memory limit, 0 CPU limit) |

The 36.8 GB of block writes is notable — that's a lot of disk I/O for a
Postgres container. Likely WAL + checkpoint activity if the database is
under heavy write load, or possibly vacuum/analyze cycles.

### BEAM (native, outside Docker)

| Process | RSS | CPU | Notes |
|---------|-----|-----|-------|
| `beam.smp` (main) | 32 MB | 0.1% | The Phoenix app — very lean at rest |
| `beam.smp` (burst) | 180 MB | 140% | Observed spike, likely compilation or heavy request |
| `tailwind-macos-arm64` | 28 MB | 0% | Asset watcher |
| `esbuild-darwin-arm64` | 25 MB | 1.2% | JS bundler |
| `mac_listener` | 5 MB | 0% | File system watcher |
| **BEAM total** | **~270 MB** | | |

### Docker Disk

| Type | Total | Reclaimable |
|------|-------|-------------|
| Images | 2.16 GB | 1.88 GB (87%) |
| Volumes | 1.18 GB | 0 (active) |
| Build cache | 1.47 GB | 1.20 GB (81%) |
| Containers | 20 KB | 0 |

**~3 GB reclaimable** via `docker system prune` (unused image + build cache).

## Leads to Investigate

### 1. Docker Desktop VM allocation is untuned
The VM claims 5.8 GB and 6 CPUs by default. The haul-pg container only uses
1.44 GB. Consider reducing the VM memory allocation in Docker Desktop settings
to 3-4 GB — that alone could free 1.5-2 GB for the host.

**Where**: Docker Desktop → Settings → Resources → Memory/CPU

### 2. The krun overhead question
`com.docker.krun` at 4.7 GB RSS for a single Postgres container is the dominant
cost. Investigate whether:
- **OrbStack** would be lighter (commonly reported 50-70% less overhead than
  Docker Desktop on Apple Silicon)
- **Native Postgres via mise/brew** would eliminate the container entirely.
  If Postgres is only used for local dev, `brew services start postgresql@16`
  or `mise` managed Postgres removes the entire Docker layer (~5 GB savings)
- **Colima** as a lighter Docker runtime (uses Lima VMs, less overhead than
  Docker Desktop's krun)

### 3. The 36.8 GB block write volume
That's a lot of writes for a dev database. Check:
- Is `fsync` or `synchronous_commit` set aggressively?
- Are there runaway migrations, heavy seed scripts, or test suites hammering the DB?
- WAL configuration: `max_wal_size`, checkpoint frequency
- `docker logs haul-pg` for checkpoint warnings

### 4. Anonymous volume
There's an anonymous Docker volume (1.18 GB). This is likely the Postgres data
directory. Consider making it a named volume for easier management:
```
docker volume create haul-pg-data
```

### 5. Reclaimable disk
3 GB of images + build cache are reclaimable. Not urgent but easy:
```
docker system prune --volumes  # if you want to nuke everything unused
docker image prune             # just unused images
docker builder prune           # just build cache
```

### 6. BEAM burst to 180 MB / 140% CPU
One `beam.smp` process spiked during observation. If this is compilation
(`mix compile`), that's expected and transient. If it's runtime, check:
- Hot code paths doing heavy computation
- ETS table growth
- Process mailbox buildup (`Process.info(pid, :message_queue_len)`)

### 7. erl_crash.dump exists
There's an `erl_crash.dump` in the project root. This means the BEAM has
crashed at some point. Worth reading — it contains the full process state,
memory allocation, and the reason for the crash:
```
head -50 erl_crash.dump  # crash reason is near the top
```

## Bottom Line

The app itself (BEAM + watchers) is lean at ~270 MB. Docker infrastructure
is 20× the app's cost. The highest-leverage investigation is whether Docker
Desktop can be replaced or downsized for this use case.
