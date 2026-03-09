# Script for populating the database. Run with:
#
#     mix run priv/repo/seeds.exs
#
# Idempotent — safe to run multiple times.

# --- Operator identity (config-driven) ---
# Operator data lives in application config (config.exs / runtime.exs),
# not in the database. Log it here to confirm the dev environment is
# correctly configured.

operator = Application.get_env(:haul, :operator, [])

Mix.shell().info("""
\n=== Dev Environment Seed Summary ===
Operator: #{operator[:business_name]}
Phone:    #{operator[:phone]}
Email:    #{operator[:email]}
Area:     #{operator[:service_area]}
Services: #{length(operator[:services] || [])} configured
============================================\n\
""")

# --- Default company ---
# Ensures the operator's tenant schema exists for the booking form.
alias Haul.Accounts.Company

slug = operator[:slug] || "default"

case Ash.read(Company) do
  {:ok, []} ->
    Company
    |> Ash.Changeset.for_create(:create_company, %{
      name: operator[:business_name],
      slug: slug
    })
    |> Ash.create!()

    Mix.shell().info("Created default company: #{operator[:business_name]} (slug: #{slug})")

  {:ok, companies} ->
    Mix.shell().info("#{length(companies)} company(ies) already exist, skipping seed.")
end
