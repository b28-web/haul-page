# T-031-02 Research: verify-test-switching

## Current Adapter Architecture (post T-031-01)

### Compile-time adapter dispatch (7 modules)

All adapter dispatch modules use `@adapter Application.compile_env(...)`:

| Module | Config key | Default (Sandbox) | Prod adapter |
|--------|-----------|-------------------|--------------|
| `Haul.AI` | `:ai_adapter` | `Haul.AI.Sandbox` | `Haul.AI.Baml` |
| `Haul.AI.Chat` | `:chat_adapter` | `Haul.AI.Chat.Sandbox` | `Haul.AI.Chat.Anthropic` |
| `Haul.Payments` | `:payments_adapter` | `Haul.Payments.Sandbox` | `Haul.Payments.Stripe` |
| `Haul.Billing` | `:billing_adapter` | `Haul.Billing.Sandbox` | `Haul.Billing.Stripe` |
| `Haul.SMS` | `:sms_adapter` | `Haul.SMS.Sandbox` | `Haul.SMS.Twilio` |
| `Haul.Places` | `:places_adapter` | `Haul.Places.Sandbox` | `Haul.Places.Google` |
| `Haul.Domains` | `:cert_adapter` | `Haul.Domains.Sandbox` | `Haul.Domains.FlyApi` |

### Config layer analysis

| Config file | Adapter keys set? | Purpose |
|-------------|:-:|---------|
| `config/config.exs` | Yes (all 7 → Sandbox) | Base defaults |
| `config/dev.exs` | No (inherits base) | Dev inherits Sandbox |
| `config/test.exs` | Yes (6 of 7 → Sandbox) | Explicit sandbox. Missing `:chat_adapter` and `:cert_adapter` — these fall through to config.exs defaults (also Sandbox) |
| `config/prod.exs` | Yes (all 7 → production) | Production adapters |
| `config/runtime.exs` | **No adapter keys** | Only API keys, secrets, feature gates |

### Runtime `get_env` calls (intentionally kept)

~30 `Application.get_env` calls remain in lib/. All are for runtime values:
- API keys and secrets (Stripe, Twilio, Anthropic, Google, Fly)
- Feature gates (`chat_available`)
- Operator config overrides
- Stripe price IDs
- Storage backend selection (`:local` vs `:s3`)
- Base domain for tenant resolution

None are adapter dispatch calls. All correctly use runtime config.

### Sandbox adapter capabilities

All 7 sandbox adapters:
- Implement `@behaviour` for their service
- Provide deterministic responses
- Most offer per-test override mechanisms (`set_response`, process dictionary)
- Do not make external API calls

### Test suite status

975 tests, 0 failures, 1 excluded (`:baml_live` tag). All sandbox adapters activate correctly in test.

### Edge case: runtime.exs adapter overrides

Verified: **no adapter keys** appear in `config/runtime.exs`. The `compile_env` calls will never conflict with runtime overrides. This was the key edge case from the acceptance criteria.

### Documentation gap

`docs/knowledge/test-architecture.md` covers test tiers, factories, and async rules. It does **not** document:
- How adapter switching works
- How to add a new adapter
- The recompilation requirement after config changes

This is the main deliverable for this ticket.
