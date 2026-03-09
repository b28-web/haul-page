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

# Places — use sandbox adapter in test (no Google API calls)
config :haul, :places_adapter, Haul.Places.Sandbox
config :stripity_stripe, api_key: "sk_test_fake"

# Oban — manual testing mode (jobs don't run automatically)
config :haul, Oban, testing: :manual

# Base domain for tenant resolver tests
config :haul, :base_domain, "haulpage.test"

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
