# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :haul,
  ecto_repos: [Haul.Repo],
  generators: [timestamp_type: :utc_datetime],
  ash_domains: [Haul.Accounts, Haul.Operations, Haul.Content, Haul.AI.Domain]

# Base domain for subdomain extraction (e.g., "haulpage.com" in production)
config :haul, :base_domain, "localhost"

# Operator identity — displayed on the landing page and used in templates.
# Override individual fields via env vars in runtime.exs.
config :haul, :operator,
  slug: "junk-and-handy",
  business_name: "Junk & Handy",
  phone: "(555) 123-4567",
  email: "hello@junkandhandy.com",
  tagline:
    "Fast, honest, affordable junk removal and handyman services for homes and businesses.",
  service_area: "Your Area",
  coupon_text: "10% OFF",
  deposit_amount_cents: 5000,
  services: [
    %{
      title: "Junk Removal",
      description: "Furniture, appliances, debris — hauled away same day.",
      icon: "hero-truck"
    },
    %{
      title: "Cleanouts",
      description: "Garages, basements, storage units cleared out completely.",
      icon: "hero-trash"
    },
    %{
      title: "Yard Waste",
      description: "Branches, clippings, dirt — gone before you know it.",
      icon: "hero-sparkles"
    },
    %{
      title: "Repairs",
      description: "Small fixes, patching, and maintenance around the house.",
      icon: "hero-wrench"
    },
    %{
      title: "Assembly",
      description: "Furniture, equipment, shelving — built and placed right.",
      icon: "hero-wrench-screwdriver"
    },
    %{
      title: "Moving Help",
      description: "Loading, unloading, rearranging — extra hands when you need them.",
      icon: "hero-cube"
    }
  ]

# Configure the endpoint
config :haul, HaulWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: HaulWeb.ErrorHTML, json: HaulWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Haul.PubSub,
  live_view: [signing_salt: "4LFVL0P2"]

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :haul, Haul.Mailer, adapter: Swoosh.Adapters.Local

# SMS adapter — Sandbox for dev, Twilio for prod (configured in runtime.exs)
config :haul, :sms_adapter, Haul.SMS.Sandbox

# Oban job processing
config :haul, Oban,
  repo: Haul.Repo,
  queues: [notifications: 10, default: 5, certs: 3],
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       {"0 6 * * *", Haul.Workers.CheckDunningGrace},
       {"0 3 * * *", Haul.Workers.CleanupConversations}
     ]}
  ]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  haul: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.12",
  haul: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure ex_money / ex_cldr
config :ex_money,
  default_cldr_backend: Haul.Cldr

# Payments — Sandbox for dev/test, Stripe for prod (configured in runtime.exs)
config :haul, :payments_adapter, Haul.Payments.Sandbox
config :haul, :stripe_publishable_key, ""
config :stripity_stripe, api_key: ""

# Cert provisioning — Sandbox for dev/test, FlyApi for prod (configured in runtime.exs)
config :haul, :cert_adapter, Haul.Domains.Sandbox

# Billing — Sandbox for dev/test, Stripe for prod (configured in runtime.exs)
config :haul, :billing_adapter, Haul.Billing.Sandbox
config :haul, :stripe_price_pro, ""
config :haul, :stripe_price_business, ""
config :haul, :stripe_price_dedicated, ""

# Billing webhook secret — separate from payment webhook secret
config :haul, :stripe_billing_webhook_secret, ""

# AI / BAML — Sandbox for dev, Baml for prod (configured in runtime.exs)
config :haul, :ai_adapter, Haul.AI.Sandbox
config :haul, :chat_adapter, Haul.AI.Chat.Sandbox

# Photo upload storage — :local for dev/test, :s3 for prod (Fly Tigris)
config :haul, :storage, backend: :local

# Token signing secret for AshAuthentication (override in runtime.exs for prod)
config :haul, :token_signing_secret, "dev-only-signing-secret-replace-in-prod"

# Sentry error tracking — DSN set via env var in runtime.exs; no-op without DSN
config :sentry,
  environment_name: config_env(),
  enable_source_code_context: true,
  root_source_code_paths: [File.cwd!()]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
