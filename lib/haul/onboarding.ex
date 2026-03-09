defmodule Haul.Onboarding do
  @moduledoc """
  Provisions a new operator tenant on the shared multi-tenant instance.

  Orchestrates: Company creation → tenant schema → content seeding → owner user.
  Idempotent — safe to re-run for the same operator.
  """

  alias Haul.Accounts.Changes.ProvisionTenant
  alias Haul.Accounts.{Company, User}
  alias Haul.Content.{Seeder, SiteConfig}

  @type params :: %{
          name: String.t(),
          phone: String.t(),
          email: String.t(),
          area: String.t()
        }

  @type result :: %{
          company: Company.t(),
          tenant: String.t(),
          user: User.t(),
          content: map(),
          existing_company: boolean()
        }

  @doc "Returns true if the slug is not taken by an existing company."
  @spec slug_available?(String.t()) :: boolean()
  def slug_available?(slug) when is_binary(slug) and slug != "" do
    case Ash.read!(Company) |> Enum.find(&(&1.slug == slug)) do
      nil -> true
      _ -> false
    end
  end

  def slug_available?(_), do: false

  @doc """
  Signs up a new operator via the web form. Like `run/1` but accepts a
  user-provided password and returns the user with JWT token metadata
  for auto-login.

  Returns `{:ok, result}` or `{:error, step, reason}`.
  """
  @spec signup(map()) :: {:ok, result()} | {:error, atom(), term()}
  def signup(params) do
    with {:ok, name} <- validate_required(params, :name),
         {:ok, email} <- validate_required(params, :email),
         {:ok, password} <- validate_required(params, :password),
         {:ok, password_confirmation} <- validate_required(params, :password_confirmation),
         :ok <- validate_password_match(password, password_confirmation),
         :ok <- validate_password_length(password),
         phone <- Map.get(params, :phone, ""),
         area <- Map.get(params, :area, ""),
         slug = derive_slug(name),
         {:ok, company, existing?} <- find_or_create_company(name, slug),
         tenant = ProvisionTenant.tenant_schema(company.slug),
         {:ok, content} <- seed_content(tenant),
         :ok <- update_site_config(tenant, %{phone: phone, email: email, service_area: area}),
         {:ok, user} <- create_signup_owner(tenant, email, password, password_confirmation, phone) do
      {:ok,
       %{
         company: company,
         tenant: tenant,
         user: user,
         content: content,
         existing_company: existing?
       }}
    end
  end

  @doc """
  Onboards a new operator. Creates company, provisions tenant, seeds content,
  creates owner user.

  Returns `{:ok, result}` or `{:error, step, reason}`.
  """
  @spec run(params()) :: {:ok, result()} | {:error, atom(), term()}
  def run(params) do
    with {:ok, name} <- validate_required(params, :name),
         {:ok, email} <- validate_required(params, :email),
         phone <- Map.get(params, :phone, ""),
         area <- Map.get(params, :area, ""),
         slug = derive_slug(name),
         {:ok, company, existing?} <- find_or_create_company(name, slug),
         tenant = ProvisionTenant.tenant_schema(company.slug),
         {:ok, content} <- seed_content(tenant),
         :ok <- update_site_config(tenant, %{phone: phone, email: email, service_area: area}),
         {:ok, user} <- find_or_create_owner(tenant, email, phone) do
      {:ok,
       %{
         company: company,
         tenant: tenant,
         user: user,
         content: content,
         existing_company: existing?
       }}
    end
  end

  @doc "Derives a URL-safe slug from a business name."
  def derive_slug(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end

  @doc "Returns the live site URL for a given slug."
  def site_url(slug) do
    base_domain = Application.get_env(:haul, :base_domain, "haulpage.com")
    "https://#{slug}.#{base_domain}"
  end

  defp validate_required(params, key) do
    case Map.get(params, key) do
      nil -> {:error, :validation, "#{key} is required"}
      "" -> {:error, :validation, "#{key} is required"}
      value -> {:ok, value}
    end
  end

  defp find_or_create_company(name, slug) do
    case Ash.read!(Company) |> Enum.find(&(&1.slug == slug)) do
      nil ->
        case Company
             |> Ash.Changeset.for_create(:create_company, %{name: name, slug: slug})
             |> Ash.create() do
          {:ok, company} -> {:ok, company, false}
          {:error, error} -> {:error, :company_create, error}
        end

      existing ->
        # Update name if it changed
        if existing.name != name do
          case existing
               |> Ash.Changeset.for_update(:update_company, %{name: name})
               |> Ash.update() do
            {:ok, updated} -> {:ok, updated, true}
            {:error, error} -> {:error, :company_update, error}
          end
        else
          {:ok, existing, true}
        end
    end
  end

  defp seed_content(tenant) do
    try do
      summary = Seeder.seed!(tenant, defaults_content_root())
      {:ok, summary}
    rescue
      e -> {:error, :content_seed, Exception.message(e)}
    end
  end

  defp defaults_content_root do
    :haul
    |> :code.priv_dir()
    |> Path.join("content/defaults")
  end

  defp update_site_config(tenant, attrs) do
    # Filter out empty values
    attrs = Map.reject(attrs, fn {_k, v} -> v == "" or is_nil(v) end)

    if map_size(attrs) == 0 do
      :ok
    else
      case Ash.read!(SiteConfig, tenant: tenant) do
        [config] ->
          case config
               |> Ash.Changeset.for_update(:edit, attrs)
               |> Ash.update() do
            {:ok, _} -> :ok
            {:error, error} -> {:error, :site_config_update, error}
          end

        [] ->
          # SiteConfig not seeded yet — skip update
          :ok
      end
    end
  end

  defp find_or_create_owner(tenant, email, phone) do
    existing =
      User
      |> Ash.read!(tenant: tenant, authorize?: false)
      |> Enum.find(&(to_string(&1.email) == email))

    case existing do
      nil ->
        password = generate_temp_password()

        case User
             |> Ash.Changeset.for_create(
               :register_with_password,
               %{
                 email: email,
                 password: password,
                 password_confirmation: password
               },
               tenant: tenant,
               authorize?: false
             )
             |> Ash.create() do
          {:ok, user} ->
            # Set role to :owner
            case user
                 |> Ash.Changeset.for_update(:update_user, %{role: :owner, phone: phone},
                   tenant: tenant,
                   authorize?: false
                 )
                 |> Ash.update() do
              {:ok, owner} -> {:ok, owner}
              {:error, error} -> {:error, :user_role_update, error}
            end

          {:error, error} ->
            {:error, :user_create, error}
        end

      user ->
        {:ok, user}
    end
  end

  defp generate_temp_password do
    :crypto.strong_rand_bytes(24) |> Base.url_encode64(padding: false)
  end

  defp validate_password_match(password, confirmation) do
    if password == confirmation, do: :ok, else: {:error, :validation, "passwords do not match"}
  end

  defp validate_password_length(password) do
    if String.length(password) >= 8,
      do: :ok,
      else: {:error, :validation, "password must be at least 8 characters"}
  end

  defp create_signup_owner(tenant, email, password, password_confirmation, phone) do
    existing =
      User
      |> Ash.read!(tenant: tenant, authorize?: false)
      |> Enum.find(&(to_string(&1.email) == email))

    case existing do
      nil ->
        case User
             |> Ash.Changeset.for_create(
               :register_with_password,
               %{email: email, password: password, password_confirmation: password_confirmation},
               tenant: tenant,
               authorize?: false
             )
             |> Ash.create() do
          {:ok, user} ->
            case user
                 |> Ash.Changeset.for_update(:update_user, %{role: :owner, phone: phone},
                   tenant: tenant,
                   authorize?: false
                 )
                 |> Ash.update() do
              {:ok, owner} ->
                # Preserve the token metadata from the original create
                {:ok, %{owner | __metadata__: user.__metadata__}}

              {:error, error} ->
                {:error, :user_role_update, error}
            end

          {:error, error} ->
            {:error, :user_create, error}
        end

      _user ->
        {:error, :user_create, "An account with this email already exists"}
    end
  end
end
