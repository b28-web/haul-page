import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :haul, Haul.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "haul_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :haul, HaulWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "f3mV8d6c4lIg0xdY3/Sh6wpo6jEDHLsDsBL+K581O3EbmdsEBBt2vaLsChZPeni6",
  server: false

# In test we don't send emails
config :haul, Haul.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# SMS — use sandbox adapter in test (no Twilio calls)
config :haul, :sms_adapter, Haul.SMS.Sandbox

# Payments — use sandbox adapter in test (no Stripe calls)
config :haul, :payments_adapter, Haul.Payments.Sandbox

# Billing — use sandbox adapter in test (no Stripe calls)
config :haul, :billing_adapter, Haul.Billing.Sandbox
config :haul, :stripe_price_pro, "price_test_pro"
config :haul, :stripe_price_business, "price_test_business"
config :haul, :stripe_price_dedicated, "price_test_dedicated"

# AI — use sandbox adapter in test (no LLM calls)
config :haul, :ai_adapter, Haul.AI.Sandbox

# Places — use sandbox adapter in test (no Google API calls)
config :haul, :places_adapter, Haul.Places.Sandbox

# Chat — use sandbox adapter in test (no Anthropic API calls)
config :haul, :chat_adapter, Haul.AI.Chat.Sandbox

# Domains — use sandbox adapter in test (no Fly API calls)
config :haul, :cert_adapter, Haul.Domains.Sandbox

config :stripity_stripe, api_key: "sk_test_fake"

# Oban — manual testing mode (jobs don't run automatically)
config :haul, Oban, testing: :manual

# Base domain for tenant resolver tests
config :haul, :base_domain, "haulpage.test"

# Fast bcrypt in test (default 12 rounds → 1 round)
config :bcrypt_elixir, log_rounds: 1

# Fast extraction debounce in test (default 800ms → 50ms)
config :haul, extraction_debounce_ms: 50

# Lower chat message limit for faster rate-limit tests (default 50 → 10)
config :haul, max_chat_messages: 10

# Enable dev routes (proxy tenant, LiveDashboard) in test
config :haul, dev_routes: true

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true
