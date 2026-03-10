# haul-page — operator interface
#
# These are the commands you can count on.
# Run `just` to see them, `just <command>` to use them.

import '.just/system.just'

# Start local development (singleton — safe to call from multiple agents)
dev:
    @just _dev

# Check if dev server is running (pid, port, health, memory)
dev-status:
    @just _dev-status

# Show recent dev server logs (default: last 50 lines)
dev-log *args='50':
    @just _dev-log {{ args }}

# Stop the dev server
dev-down:
    @just _dev-down

# Deploy to production
deploy:
    @just _deploy

# Introduce an LLM coder to this repo
llm:
    @just _llm

# Show project status (tickets, DAG, progress)
status:
    lisa status

# Quick OVERVIEW.md refresh — read-only survey, update, exit
overview:
    @just _overview

# Full status briefing + interactive planning session
status-agent:
    @just _status-agent

# Commit, test, push, and file bugs for failures
commit-agent:
    @just _commit-agent

# Report the test pyramid shape (tier distribution)
test-pyramid:
    @just _test-pyramid

# Run only tests affected by recent source changes
test-stale *args='':
    @just _test-stale {{ args }}

# Run tests for a specific file or file:line
test-file FILE *args='':
    @just _test-file {{ FILE }} {{ args }}

# Run the implementation agent swarm
work:
    lisa loop
