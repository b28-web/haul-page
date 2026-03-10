defmodule HaulWeb.Admin.AccountsLive do
  use HaulWeb, :live_view

  alias Haul.Accounts.Company
  alias Haul.Admin.AccountHelpers
  alias Haul.Content.SiteConfig

  import Haul.Admin.AccountHelpers, only: [sort_indicator: 3]
  import Haul.Formatting, only: [plan_badge_class: 1]

  @impl true
  def mount(_params, _session, socket) do
    companies = Ash.read!(Company)
    tenant_schemas = list_tenant_schemas()
    statuses = build_statuses(companies, tenant_schemas)

    sorted = Enum.sort_by(companies, & &1.inserted_at, {:desc, DateTime})

    {:ok,
     assign(socket,
       page_title: "Accounts",
       companies: companies,
       filtered_companies: sorted,
       statuses: statuses,
       search: "",
       sort_by: :inserted_at,
       sort_dir: :desc
     )}
  end

  @impl true
  def handle_event("search", %{"search" => term}, socket) do
    filtered = AccountHelpers.filter_companies(socket.assigns.companies, term)

    sorted =
      AccountHelpers.sort_companies(filtered, socket.assigns.sort_by, socket.assigns.sort_dir)

    {:noreply, assign(socket, search: term, filtered_companies: sorted)}
  end

  def handle_event("navigate", %{"slug" => slug}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/admin/accounts/#{slug}")}
  end

  def handle_event("sort", %{"field" => field}, socket) do
    field = String.to_existing_atom(field)

    dir =
      if socket.assigns.sort_by == field do
        AccountHelpers.toggle_dir(socket.assigns.sort_dir)
      else
        :asc
      end

    sorted = AccountHelpers.sort_companies(socket.assigns.filtered_companies, field, dir)
    {:noreply, assign(socket, sort_by: field, sort_dir: dir, filtered_companies: sorted)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex items-center justify-between">
        <h1 class="font-display text-2xl uppercase tracking-wider text-foreground">
          Accounts
        </h1>
        <span class="text-sm text-muted-foreground">
          {length(@companies)} total
        </span>
      </div>

      <div>
        <form phx-change="search" class="max-w-sm">
          <input
            type="text"
            name="search"
            value={@search}
            placeholder="Search by name or slug..."
            phx-debounce="200"
            class="w-full rounded-md border border-border bg-input px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
          />
        </form>
      </div>

      <div class="overflow-x-auto rounded-lg border border-border">
        <table class="min-w-full divide-y divide-border">
          <thead class="bg-card">
            <tr>
              <th class="px-4 py-3 text-left text-xs font-medium uppercase tracking-wider text-muted-foreground">
                <button phx-click="sort" phx-value-field="slug" class="hover:text-foreground">
                  Slug {sort_indicator(:slug, @sort_by, @sort_dir)}
                </button>
              </th>
              <th class="px-4 py-3 text-left text-xs font-medium uppercase tracking-wider text-muted-foreground">
                <button phx-click="sort" phx-value-field="name" class="hover:text-foreground">
                  Business Name {sort_indicator(:name, @sort_by, @sort_dir)}
                </button>
              </th>
              <th class="px-4 py-3 text-left text-xs font-medium uppercase tracking-wider text-muted-foreground">
                Plan
              </th>
              <th class="px-4 py-3 text-left text-xs font-medium uppercase tracking-wider text-muted-foreground">
                Domain
              </th>
              <th class="px-4 py-3 text-left text-xs font-medium uppercase tracking-wider text-muted-foreground">
                <button phx-click="sort" phx-value-field="inserted_at" class="hover:text-foreground">
                  Created {sort_indicator(:inserted_at, @sort_by, @sort_dir)}
                </button>
              </th>
              <th class="px-4 py-3 text-left text-xs font-medium uppercase tracking-wider text-muted-foreground">
                Status
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-border bg-background">
            <tr
              :for={company <- @filtered_companies}
              class="hover:bg-card/50 cursor-pointer"
              phx-click="navigate"
              phx-value-slug={company.slug}
            >
              <td class="px-4 py-3 text-sm font-mono text-foreground">
                <.link navigate={~p"/admin/accounts/#{company.slug}"} class="hover:underline">
                  {company.slug}
                </.link>
              </td>
              <td class="px-4 py-3 text-sm text-foreground">
                {company.name}
              </td>
              <td class="px-4 py-3 text-sm">
                <span class={plan_badge_class(company.subscription_plan)}>
                  {company.subscription_plan}
                </span>
              </td>
              <td class="px-4 py-3 text-sm text-muted-foreground">
                {company.domain || "—"}
              </td>
              <td class="px-4 py-3 text-sm text-muted-foreground">
                {Calendar.strftime(company.inserted_at, "%Y-%m-%d")}
              </td>
              <td class="px-4 py-3 text-sm">
                <.status_badges statuses={Map.get(@statuses, company.id, %{})} />
              </td>
            </tr>
            <tr :if={@filtered_companies == []}>
              <td colspan="6" class="px-4 py-8 text-center text-sm text-muted-foreground">
                No accounts found.
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  defp status_badges(assigns) do
    ~H"""
    <div class="flex items-center gap-2">
      <span
        :if={@statuses[:provisioned]}
        title="Tenant provisioned"
        class="inline-block h-2 w-2 rounded-full bg-green-500"
      />
      <span
        :if={!@statuses[:provisioned]}
        title="Not provisioned"
        class="inline-block h-2 w-2 rounded-full bg-red-500"
      />
      <span
        :if={@statuses[:has_content]}
        title="Has content"
        class="inline-block h-2 w-2 rounded-full bg-blue-500"
      />
      <span
        :if={@statuses[:domain_verified]}
        title="Domain verified"
        class="inline-block h-2 w-2 rounded-full bg-purple-500"
      />
    </div>
    """
  end

  defp list_tenant_schemas do
    case Ecto.Adapters.SQL.query(Haul.Repo, """
         SELECT schema_name FROM information_schema.schemata
         WHERE schema_name LIKE 'tenant_%'
         """) do
      {:ok, result} -> Enum.map(result.rows, fn [name] -> name end) |> MapSet.new()
      _ -> MapSet.new()
    end
  end

  defp build_statuses(companies, tenant_schemas) do
    Map.new(companies, fn company ->
      schema_name = "tenant_#{company.slug}"
      provisioned = MapSet.member?(tenant_schemas, schema_name)

      has_content =
        if provisioned do
          case Ash.read(SiteConfig, tenant: schema_name) do
            {:ok, [_ | _]} -> true
            _ -> false
          end
        else
          false
        end

      domain_verified = company.domain_status in [:verified, :active]

      {company.id,
       %{provisioned: provisioned, has_content: has_content, domain_verified: domain_verified}}
    end)
  end
end
