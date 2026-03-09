# haul-page

A website + booking system for junk removal operators. Dark, minimal, prints as a poster. Built with Phoenix + Ash, deployed on Fly.io for < $15/month.

## Pages

| Route | What | Tech |
|-------|------|------|
| `/` | Landing page + printable poster | Server-rendered HEEx |
| `/scan` | QR code landing — schedule CTA + before/after gallery | LiveView |
| `/book` | Online booking form — creates a lead | LiveView |

## Quick start

```
mise install           # Elixir 1.19 + Erlang/OTP 28
just dev               # deps, migrate, start server
```

Requires Postgres running locally (or set `DATABASE_URL`).

## Commands

```
just dev               # Start local development
just deploy            # Deploy to Fly.io
just status            # Show ticket DAG and progress
just work              # Launch lisa agent swarm
just llm               # Print repo context for LLM coders
```

## Stack

Elixir, Phoenix, Ash Framework, LiveView, Tailwind CSS, Neon Postgres, Fly.io.

See [docs/knowledge/specification.md](docs/knowledge/specification.md) for the full spec.

## License

See [LICENSE](LICENSE).
