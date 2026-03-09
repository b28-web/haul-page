defmodule HaulWeb.App.DomainSettingsLive do
  use HaulWeb, :live_view

  alias Haul.Billing
  alias Haul.Domains
  alias Haul.Workers.ProvisionCert

  @impl true
  def mount(_params, _session, socket) do
    company = socket.assigns.current_company
    can_custom_domain = Billing.can?(company, :custom_domain)
    base_domain = Application.get_env(:haul, :base_domain, "localhost")

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Haul.PubSub, "domain:#{company.id}")
    end

    {:ok,
     socket
     |> assign(:page_title, "Domain Settings")
     |> assign(:can_custom_domain, can_custom_domain)
     |> assign(:base_domain, base_domain)
     |> assign(:domain, company.domain)
     |> assign(:domain_status, company.domain_status)
     |> assign(:domain_input, "")
     |> assign(:domain_error, nil)
     |> assign(:verifying, false)
     |> assign(:verify_error, nil)
     |> assign(:confirm_remove, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl space-y-8">
      <h1 class="font-display text-3xl uppercase tracking-wider">Domain Settings</h1>

      <div class="bg-card border border-border rounded-lg p-6">
        <div class="flex items-center gap-3 mb-4">
          <.icon name="hero-globe-alt" class="size-5 text-muted-foreground" />
          <h2 class="font-display text-lg uppercase tracking-wider">Current Address</h2>
        </div>
        <p class="text-muted-foreground">
          Your site is available at
          <a
            href={"https://#{@current_company.slug}.#{@base_domain}"}
            class="text-foreground underline"
            target="_blank"
          >
            {@current_company.slug}.{@base_domain}
          </a>
        </p>
        <p :if={@domain && @domain_status == :active} class="mt-2">
          <span class="inline-flex items-center gap-2">
            <span class="size-2 rounded-full bg-green-500"></span>
            <span>Custom domain:</span>
            <a href={"https://#{@domain}"} class="text-foreground underline" target="_blank">
              {@domain}
            </a>
            <span class="text-xs text-green-500 font-medium">(verified)</span>
          </span>
        </p>
      </div>

      <%= if !@can_custom_domain do %>
        <.upgrade_prompt />
      <% else %>
        <%= cond do %>
          <% @domain == nil or @domain == "" -> %>
            <.add_domain_form
              domain_input={@domain_input}
              domain_error={@domain_error}
              base_domain={@base_domain}
            />
          <% @domain_status in [nil, :pending] -> %>
            <.pending_verification
              domain={@domain}
              base_domain={@base_domain}
              verifying={@verifying}
              verify_error={@verify_error}
              confirm_remove={@confirm_remove}
            />
          <% @domain_status == :provisioning -> %>
            <.provisioning_tls domain={@domain} confirm_remove={@confirm_remove} />
          <% @domain_status in [:verified, :active] -> %>
            <.domain_active domain={@domain} confirm_remove={@confirm_remove} />
          <% true -> %>
            <.add_domain_form
              domain_input={@domain_input}
              domain_error={@domain_error}
              base_domain={@base_domain}
            />
        <% end %>
      <% end %>

      <.remove_confirmation :if={@confirm_remove} domain={@domain} />
    </div>
    """
  end

  defp upgrade_prompt(assigns) do
    ~H"""
    <div class="bg-card border border-border rounded-lg p-6">
      <div class="flex items-center gap-3 mb-4">
        <.icon name="hero-lock-closed" class="size-5 text-yellow-500" />
        <h2 class="font-display text-lg uppercase tracking-wider">Custom Domain</h2>
      </div>
      <p class="text-muted-foreground mb-4">
        Custom domains are available on the Pro plan and above.
        Upgrade your plan to use your own domain for your hauling site.
      </p>
      <.link
        navigate={~p"/app/settings/billing"}
        class="inline-flex items-center gap-2 px-4 py-2 bg-foreground text-background rounded hover:opacity-90 transition-opacity text-sm"
      >
        <.icon name="hero-arrow-up-circle" class="size-4" /> Upgrade Plan
      </.link>
    </div>
    """
  end

  defp add_domain_form(assigns) do
    ~H"""
    <div class="bg-card border border-border rounded-lg p-6">
      <div class="flex items-center gap-3 mb-4">
        <.icon name="hero-plus-circle" class="size-5 text-muted-foreground" />
        <h2 class="font-display text-lg uppercase tracking-wider">Add Custom Domain</h2>
      </div>
      <p class="text-muted-foreground mb-4">
        Enter the domain you'd like to use for your hauling site.
      </p>
      <form phx-submit="save_domain" phx-change="validate_domain" class="space-y-4">
        <div>
          <label for="domain_input" class="block text-sm font-medium mb-1">Domain</label>
          <input
            type="text"
            id="domain_input"
            name="domain"
            value={@domain_input}
            placeholder="www.example.com"
            class="w-full px-3 py-2 bg-background border border-border rounded text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-1 focus:ring-foreground"
          />
          <p :if={@domain_error} class="mt-1 text-sm text-red-500">{@domain_error}</p>
          <p class="mt-1 text-xs text-muted-foreground">
            After adding, you'll need to configure a CNAME record pointing to {@base_domain}
          </p>
        </div>
        <button
          type="submit"
          class="px-4 py-2 text-sm bg-foreground text-background rounded hover:opacity-90 transition-opacity"
        >
          Add Domain
        </button>
      </form>
    </div>
    """
  end

  defp pending_verification(assigns) do
    ~H"""
    <div class="bg-card border border-border rounded-lg p-6">
      <div class="flex items-center gap-3 mb-4">
        <span class="size-2 rounded-full bg-yellow-500 animate-pulse"></span>
        <h2 class="font-display text-lg uppercase tracking-wider">Pending Verification</h2>
      </div>
      <p class="text-muted-foreground mb-4">
        Configure the following DNS record, then click "Verify DNS" to confirm.
      </p>
      <div class="bg-background border border-border rounded p-4 font-mono text-sm space-y-2">
        <div class="flex gap-4">
          <span class="text-muted-foreground w-16">Type</span>
          <span>CNAME</span>
        </div>
        <div class="flex gap-4">
          <span class="text-muted-foreground w-16">Name</span>
          <span>{@domain}</span>
        </div>
        <div class="flex gap-4">
          <span class="text-muted-foreground w-16">Value</span>
          <span>{@base_domain}</span>
        </div>
      </div>

      <p :if={@verify_error} class="mt-4 text-sm text-red-500">
        {@verify_error}
      </p>

      <div class="mt-6 flex gap-3">
        <button
          phx-click="verify_dns"
          disabled={@verifying}
          class={[
            "px-4 py-2 text-sm rounded transition-opacity",
            if(@verifying,
              do: "bg-muted text-muted-foreground cursor-not-allowed",
              else: "bg-foreground text-background hover:opacity-90"
            )
          ]}
        >
          <%= if @verifying do %>
            Checking DNS...
          <% else %>
            Verify DNS
          <% end %>
        </button>
        <button
          phx-click="remove_domain"
          class="px-4 py-2 text-sm border border-border rounded hover:bg-muted transition-colors"
        >
          Remove Domain
        </button>
      </div>
    </div>
    """
  end

  defp provisioning_tls(assigns) do
    ~H"""
    <div class="bg-card border border-border rounded-lg p-6">
      <div class="flex items-center gap-3 mb-4">
        <span class="size-2 rounded-full bg-blue-500 animate-pulse"></span>
        <h2 class="font-display text-lg uppercase tracking-wider">Setting up SSL...</h2>
      </div>
      <p class="text-muted-foreground mb-4">
        DNS verified! We're provisioning a TLS certificate for <strong class="text-foreground">{@domain}</strong>.
        This usually takes a few minutes.
      </p>
      <div class="flex gap-3 mt-6">
        <button
          phx-click="remove_domain"
          class="px-4 py-2 text-sm border border-border rounded hover:bg-muted transition-colors"
        >
          Remove Domain
        </button>
      </div>
    </div>
    """
  end

  defp domain_active(assigns) do
    ~H"""
    <div class="bg-card border border-border rounded-lg p-6">
      <div class="flex items-center gap-3 mb-4">
        <span class="size-2 rounded-full bg-green-500"></span>
        <h2 class="font-display text-lg uppercase tracking-wider">Custom Domain Active</h2>
      </div>
      <p class="text-muted-foreground">
        Your site is live at
        <a href={"https://#{@domain}"} class="text-foreground underline" target="_blank">
          {@domain}
        </a>
      </p>
      <div class="flex gap-3 mt-6">
        <button
          phx-click="remove_domain"
          class="px-4 py-2 text-sm border border-red-700 text-red-400 rounded hover:bg-red-900/20 transition-colors"
        >
          Remove Domain
        </button>
      </div>
    </div>
    """
  end

  defp remove_confirmation(assigns) do
    ~H"""
    <div
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/50"
      phx-click="cancel_remove"
    >
      <div
        class="bg-card border border-border rounded-lg p-6 max-w-md mx-4"
        phx-click-away="cancel_remove"
      >
        <h2 class="font-display text-xl uppercase tracking-wider">Remove Custom Domain</h2>
        <p class="mt-3 text-sm text-muted-foreground">
          This will remove <strong class="text-foreground">{@domain}</strong>
          and revert your site to the subdomain address. Any existing TLS certificate will be cleaned up.
        </p>
        <div class="mt-6 flex gap-3 justify-end">
          <button
            phx-click="cancel_remove"
            class="px-4 py-2 text-sm border border-border rounded hover:bg-muted transition-colors"
          >
            Cancel
          </button>
          <button
            phx-click="confirm_remove"
            class="px-4 py-2 text-sm bg-red-600 text-white rounded hover:bg-red-700 transition-colors"
          >
            Remove Domain
          </button>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("validate_domain", %{"domain" => input}, socket) do
    normalized = Domains.normalize_domain(input)

    error =
      cond do
        input == "" ->
          nil

        not Domains.valid_domain?(normalized) ->
          "Please enter a valid domain (e.g., www.example.com)"

        normalized == socket.assigns.base_domain ->
          "Cannot use the platform domain"

        true ->
          nil
      end

    {:noreply, assign(socket, domain_input: input, domain_error: error)}
  end

  @impl true
  def handle_event("save_domain", %{"domain" => input}, socket) do
    normalized = Domains.normalize_domain(input)

    cond do
      not Domains.valid_domain?(normalized) ->
        {:noreply,
         assign(socket, domain_error: "Please enter a valid domain (e.g., www.example.com)")}

      normalized == socket.assigns.base_domain ->
        {:noreply, assign(socket, domain_error: "Cannot use the platform domain")}

      true ->
        company = socket.assigns.current_company

        case company
             |> Ash.Changeset.for_update(:update_company, %{
               domain: normalized,
               domain_status: :pending
             })
             |> Ash.update() do
          {:ok, updated} ->
            {:noreply,
             socket
             |> assign(:current_company, updated)
             |> assign(:domain, normalized)
             |> assign(:domain_status, :pending)
             |> assign(:domain_input, "")
             |> assign(:domain_error, nil)
             |> put_flash(:info, "Domain added. Configure your DNS record, then verify.")}

          {:error, _changeset} ->
            {:noreply,
             assign(socket, domain_error: "Domain is already in use by another account")}
        end
    end
  end

  @impl true
  def handle_event("verify_dns", _params, socket) do
    socket = assign(socket, verifying: true, verify_error: nil)
    domain = socket.assigns.domain
    base_domain = socket.assigns.base_domain

    case Domains.verify_dns(domain, base_domain) do
      :ok ->
        company = socket.assigns.current_company

        {:ok, updated} =
          company
          |> Ash.Changeset.for_update(:update_company, %{domain_status: :provisioning})
          |> Ash.update()

        {:ok, _} =
          Oban.insert(ProvisionCert.new(%{"company_id" => company.id, "action" => "add"}))

        {:noreply,
         socket
         |> assign(:current_company, updated)
         |> assign(:domain_status, :provisioning)
         |> assign(:verifying, false)
         |> put_flash(:info, "DNS verified! Provisioning SSL certificate...")}

      {:error, :no_cname} ->
        {:noreply,
         socket
         |> assign(:verifying, false)
         |> assign(
           :verify_error,
           "DNS not yet propagated — no CNAME record found. Try again in a few minutes."
         )}

      {:error, :wrong_cname} ->
        {:noreply,
         socket
         |> assign(:verifying, false)
         |> assign(
           :verify_error,
           "CNAME record found but doesn't point to #{base_domain}. Please check your DNS settings."
         )}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(:verifying, false)
         |> assign(:verify_error, "DNS lookup failed. Please try again in a few minutes.")}
    end
  end

  @impl true
  def handle_event("remove_domain", _params, socket) do
    {:noreply, assign(socket, confirm_remove: true)}
  end

  @impl true
  def handle_event("cancel_remove", _params, socket) do
    {:noreply, assign(socket, confirm_remove: false)}
  end

  @impl true
  def handle_event("confirm_remove", _params, socket) do
    company = socket.assigns.current_company
    old_domain = company.domain

    {:ok, updated} =
      company
      |> Ash.Changeset.for_update(:update_company, %{
        domain: nil,
        domain_status: nil,
        domain_verified_at: nil
      })
      |> Ash.update()

    if old_domain do
      Oban.insert(
        ProvisionCert.new(%{
          "company_id" => company.id,
          "domain" => old_domain,
          "action" => "remove"
        })
      )
    end

    {:noreply,
     socket
     |> assign(:current_company, updated)
     |> assign(:domain, nil)
     |> assign(:domain_status, nil)
     |> assign(:confirm_remove, false)
     |> assign(:domain_input, "")
     |> put_flash(:info, "Custom domain removed. Your site is available at your subdomain.")}
  end

  @impl true
  def handle_info({:domain_status_changed, new_status}, socket) do
    company = socket.assigns.current_company

    case Ash.get(Haul.Accounts.Company, company.id) do
      {:ok, updated} ->
        {:noreply,
         socket
         |> assign(:current_company, updated)
         |> assign(:domain_status, new_status)
         |> assign(:domain, updated.domain)}

      _ ->
        {:noreply, assign(socket, :domain_status, new_status)}
    end
  end
end
