defmodule HaulWeb.Admin.AccountDetailLive do
  use HaulWeb, :live_view

  alias Haul.Accounts.Company
  alias Haul.Accounts.User
  alias Haul.Content.SiteConfig

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    companies = Ash.read!(Company)
    company = Enum.find(companies, &(&1.slug == slug))

    if company do
      schema_name = "tenant_#{company.slug}"
      provisioned = schema_exists?(schema_name)

      {users, has_content} =
        if provisioned do
          users =
            case Ash.read(User, tenant: schema_name, authorize?: false) do
              {:ok, users} -> users
              _ -> []
            end

          has_content =
            case Ash.read(SiteConfig, tenant: schema_name) do
              {:ok, [_ | _]} -> true
              _ -> false
            end

          {users, has_content}
        else
          {[], false}
        end

      domain_verified = company.domain_status in [:verified, :active]

      {:ok,
       assign(socket,
         page_title: "Account: #{company.name}",
         company: company,
         users: users,
         provisioned: provisioned,
         has_content: has_content,
         domain_verified: domain_verified
       )}
    else
      {:ok,
       socket
       |> put_flash(:error, "Account not found")
       |> push_navigate(to: ~p"/admin/accounts")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-8">
      <div class="flex items-center justify-between">
        <div>
          <.link
            navigate={~p"/admin/accounts"}
            class="text-sm text-muted-foreground hover:text-foreground"
          >
            &larr; Back to accounts
          </.link>
          <h1 class="font-display text-2xl uppercase tracking-wider text-foreground mt-2">
            {@company.name}
          </h1>
        </div>
        <%= if @provisioned do %>
          <form method="post" action={~p"/admin/impersonate/#{@company.slug}"}>
            <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />
            <button
              type="submit"
              class="rounded-md bg-amber-600 px-4 py-2 text-sm text-black font-medium hover:bg-amber-500"
            >
              Impersonate
            </button>
          </form>
        <% else %>
          <button
            disabled
            title="Tenant not provisioned"
            class="rounded-md bg-zinc-700 px-4 py-2 text-sm text-zinc-400 cursor-not-allowed"
          >
            Impersonate
          </button>
        <% end %>
      </div>

      <%!-- Status indicators --%>
      <div class="flex items-center gap-4">
        <.status_badge active={@provisioned} label="Provisioned" />
        <.status_badge active={@has_content} label="Has Content" />
        <.status_badge active={@domain_verified} label="Domain Verified" />
      </div>

      <%!-- Company attributes --%>
      <div class="rounded-lg border border-border bg-card p-6">
        <h2 class="font-display text-lg uppercase tracking-wider text-foreground mb-4">
          Company Details
        </h2>
        <dl class="grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-4">
          <.detail_item label="Slug" value={@company.slug} mono />
          <.detail_item label="Name" value={@company.name} />
          <.detail_item label="Plan" value={to_string(@company.subscription_plan)} />
          <.detail_item label="Timezone" value={@company.timezone} />
          <.detail_item label="Domain" value={@company.domain || "—"} />
          <.detail_item
            label="Domain Status"
            value={if @company.domain_status, do: to_string(@company.domain_status), else: "—"}
          />
          <.detail_item
            label="Onboarding Complete"
            value={if @company.onboarding_complete, do: "Yes", else: "No"}
          />
          <.detail_item
            label="Stripe Customer"
            value={@company.stripe_customer_id || "—"}
            mono
          />
          <.detail_item
            label="Stripe Subscription"
            value={@company.stripe_subscription_id || "—"}
            mono
          />
          <.detail_item
            label="Created"
            value={Calendar.strftime(@company.inserted_at, "%Y-%m-%d %H:%M UTC")}
          />
          <.detail_item
            label="Updated"
            value={Calendar.strftime(@company.updated_at, "%Y-%m-%d %H:%M UTC")}
          />
        </dl>
      </div>

      <%!-- Users table --%>
      <div class="rounded-lg border border-border bg-card p-6">
        <h2 class="font-display text-lg uppercase tracking-wider text-foreground mb-4">
          Users ({length(@users)})
        </h2>
        <div :if={@users != []} class="overflow-x-auto">
          <table class="min-w-full divide-y divide-border">
            <thead>
              <tr>
                <th class="px-4 py-2 text-left text-xs font-medium uppercase tracking-wider text-muted-foreground">
                  Email
                </th>
                <th class="px-4 py-2 text-left text-xs font-medium uppercase tracking-wider text-muted-foreground">
                  Role
                </th>
                <th class="px-4 py-2 text-left text-xs font-medium uppercase tracking-wider text-muted-foreground">
                  Created
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-border">
              <tr :for={user <- @users}>
                <td class="px-4 py-2 text-sm text-foreground">{user.email}</td>
                <td class="px-4 py-2 text-sm text-muted-foreground">{user.role}</td>
                <td class="px-4 py-2 text-sm text-muted-foreground">
                  {Calendar.strftime(user.inserted_at, "%Y-%m-%d")}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <p :if={@users == []} class="text-sm text-muted-foreground">
          No users found.
        </p>
      </div>
    </div>
    """
  end

  defp status_badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-medium",
      if(@active,
        do: "bg-green-900/50 text-green-400",
        else: "bg-zinc-800 text-zinc-500"
      )
    ]}>
      <span class={[
        "h-1.5 w-1.5 rounded-full",
        if(@active, do: "bg-green-400", else: "bg-zinc-600")
      ]} />
      {@label}
    </span>
    """
  end

  attr :label, :string, required: true
  attr :value, :string, required: true
  attr :mono, :boolean, default: false

  defp detail_item(assigns) do
    ~H"""
    <div>
      <dt class="text-xs font-medium uppercase tracking-wider text-muted-foreground">{@label}</dt>
      <dd class={["mt-1 text-sm text-foreground", @mono && "font-mono"]}>{@value}</dd>
    </div>
    """
  end

  defp schema_exists?(schema_name) do
    case Ecto.Adapters.SQL.query(
           Haul.Repo,
           "SELECT 1 FROM information_schema.schemata WHERE schema_name = $1",
           [schema_name]
         ) do
      {:ok, %{num_rows: n}} when n > 0 -> true
      _ -> false
    end
  end
end
