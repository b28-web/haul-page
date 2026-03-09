import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/haul start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :haul, HaulWeb.Endpoint, server: true
end

config :haul, HaulWeb.Endpoint, http: [port: String.to_integer(System.get_env("PORT", "4000"))]

# Base domain for tenant subdomain extraction (e.g., "haulpage.com")
# When set, also configures check_origin to allow wildcard subdomain WebSocket connections.
if base_domain = System.get_env("BASE_DOMAIN") do
  config :haul, :base_domain, base_domain

  config :haul, HaulWeb.Endpoint, check_origin: ["//*.#{base_domain}", "//#{base_domain}"]
end

# Operator config — override defaults from config.exs with env vars.
# Only fields with env vars set are overridden; the rest keep their defaults.
operator_overrides =
  [
    business_name: System.get_env("OPERATOR_BUSINESS_NAME"),
    phone: System.get_env("OPERATOR_PHONE"),
    email: System.get_env("OPERATOR_EMAIL"),
    tagline: System.get_env("OPERATOR_TAGLINE"),
    service_area: System.get_env("OPERATOR_SERVICE_AREA"),
    coupon_text: System.get_env("OPERATOR_COUPON_TEXT")
  ]
  |> Enum.reject(fn {_k, v} -> is_nil(v) end)

if operator_overrides != [] do
  base = Application.get_env(:haul, :operator, [])
  config :haul, :operator, Keyword.merge(base, operator_overrides)
end

# Storage configuration — S3-compatible (Fly Tigris) when env vars are set
if System.get_env("STORAGE_BUCKET") do
  config :haul, :storage,
    backend: :s3,
    bucket: System.get_env("STORAGE_BUCKET")

  config :ex_aws,
    access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
    secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
    region: System.get_env("AWS_REGION", "auto")

  tigris_endpoint = System.get_env("STORAGE_ENDPOINT", "fly.storage.tigris.dev")

  config :ex_aws, :s3,
    scheme: "https://",
    host: tigris_endpoint
end

# Google Places — autocomplete proxy (optional, only if env var is set)
if places_key = System.get_env("GOOGLE_PLACES_API_KEY") do
  config :haul, :places_adapter, Haul.Places.Google
  config :haul, :google_places_api_key, places_key
end

# Fly.io certificate provisioning — enable when API token is set
if fly_token = System.get_env("FLY_API_TOKEN") do
  config :haul, :cert_adapter, Haul.Domains.FlyApi
  config :haul, :fly_api_token, fly_token

  config :haul,
         :fly_app_name,
         System.get_env("FLY_APP_NAME") ||
           raise("FLY_APP_NAME is required when FLY_API_TOKEN is set")
end

# AI / BAML — store API key for all envs, but only switch adapter outside test
if anthropic_key = System.get_env("ANTHROPIC_API_KEY") do
  config :haul, :anthropic_api_key, anthropic_key

  if config_env() != :test do
    config :haul, :ai_adapter, Haul.AI.Baml
    config :haul, :chat_adapter, Haul.AI.Chat.Anthropic
  end
else
  # In production without an API key, disable chat so /start redirects to /signup
  if config_env() == :prod do
    config :haul, :chat_available, false
  end
end

# Sentry error tracking — enable when DSN is set (any environment)
if sentry_dsn = System.get_env("SENTRY_DSN") do
  config :sentry, dsn: sentry_dsn
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :haul, Haul.Repo,
    ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    # For machines with several cores, consider starting multiple pools of `pool_size`
    # pool_count: 4,
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"

  config :haul, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :haul, HaulWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0}
    ],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :haul, HaulWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :haul, HaulWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # Payments — Stripe (optional, only if env vars are set)
  if stripe_key = System.get_env("STRIPE_SECRET_KEY") do
    config :haul, :payments_adapter, Haul.Payments.Stripe
    config :stripity_stripe, api_key: stripe_key

    if pk = System.get_env("STRIPE_PUBLISHABLE_KEY") do
      config :haul, :stripe_publishable_key, pk
    end

    if webhook_secret = System.get_env("STRIPE_WEBHOOK_SECRET") do
      config :stripity_stripe, signing_secret: webhook_secret
    end

    # Billing webhook secret — falls back to payment webhook secret if not set
    billing_webhook_secret =
      System.get_env("STRIPE_BILLING_WEBHOOK_SECRET") ||
        System.get_env("STRIPE_WEBHOOK_SECRET")

    if billing_webhook_secret do
      config :haul, :stripe_billing_webhook_secret, billing_webhook_secret
    end

    # Billing adapter — use Stripe when Stripe keys are present
    config :haul, :billing_adapter, Haul.Billing.Stripe

    if price_pro = System.get_env("STRIPE_PRICE_PRO") do
      config :haul, :stripe_price_pro, price_pro
    end

    if price_business = System.get_env("STRIPE_PRICE_BUSINESS") do
      config :haul, :stripe_price_business, price_business
    end

    if price_dedicated = System.get_env("STRIPE_PRICE_DEDICATED") do
      config :haul, :stripe_price_dedicated, price_dedicated
    end
  end

  # SMS — Twilio (optional, only if env vars are set)
  if twilio_sid = System.get_env("TWILIO_ACCOUNT_SID") do
    config :haul, :sms_adapter, Haul.SMS.Twilio

    config :haul, :twilio,
      account_sid: twilio_sid,
      auth_token:
        System.get_env("TWILIO_AUTH_TOKEN") ||
          raise("TWILIO_AUTH_TOKEN is required when TWILIO_ACCOUNT_SID is set"),
      from_number:
        System.get_env("TWILIO_FROM_NUMBER") ||
          raise("TWILIO_FROM_NUMBER is required when TWILIO_ACCOUNT_SID is set")
  end

  # Mailer — Postmark (preferred) or Resend via env var
  cond do
    api_key = System.get_env("POSTMARK_API_KEY") ->
      config :haul, Haul.Mailer,
        adapter: Swoosh.Adapters.Postmark,
        api_key: api_key

    api_key = System.get_env("RESEND_API_KEY") ->
      config :haul, Haul.Mailer,
        adapter: Swoosh.Adapters.Resend,
        api_key: api_key

    true ->
      raise """
      No email adapter configured for production.
      Set POSTMARK_API_KEY or RESEND_API_KEY environment variable.
      """
  end
end
