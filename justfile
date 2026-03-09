# haul-page — operator interface
#
# These are the commands you can count on.
# Run `just` to see them, `just <command>` to use them.

import '.just/system.just'

# Start local development
dev:
    @just _dev

# Deploy to production
deploy:
    @just _deploy

# Introduce an LLM coder to this repo
llm:
    @just _llm

# Show project status (tickets, DAG, progress)
status:
    lisa status

# Run the implementation agent swarm
work:
    lisa loop
