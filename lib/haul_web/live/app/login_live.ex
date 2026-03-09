defmodule HaulWeb.App.LoginLive do
  use HaulWeb, :live_view

  alias Haul.Accounts.User

  @impl true
  def mount(_params, session, socket) do
    tenant =
      session["tenant"] ||
        case session["tenant_slug"] do
          slug when is_binary(slug) ->
            Haul.Accounts.Changes.ProvisionTenant.tenant_schema(slug)

          _ ->
            Map.get(socket.assigns, :tenant, nil)
        end

    {:ok,
     socket
     |> assign(:page_title, "Sign In")
     |> assign(:tenant, tenant)
     |> assign(:trigger_submit, false)
     |> assign(:form, to_form(%{"email" => "", "password" => ""}, as: :session))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-background px-4">
      <div class="w-full max-w-sm space-y-8">
        <div class="text-center">
          <h1 class="font-display text-3xl uppercase tracking-wider text-foreground">Sign In</h1>
          <p class="mt-2 text-sm text-muted-foreground">Access your operator dashboard</p>
        </div>

        <HaulWeb.Layouts.flash_group flash={@flash} />

        <.form
          for={@form}
          action={~p"/app/session"}
          phx-submit="login"
          phx-trigger-action={@trigger_submit}
          class="space-y-6"
        >
          <.input field={@form[:email]} type="email" label="Email" required autocomplete="email" />
          <.input
            field={@form[:password]}
            type="password"
            label="Password"
            required
            autocomplete="current-password"
          />
          <input type="hidden" name="session[token]" value={@form[:token].value} />
          <input type="hidden" name="session[tenant]" value={@tenant} />
          <.button type="submit" class="w-full">
            Sign in
          </.button>
        </.form>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("login", %{"session" => %{"email" => email, "password" => password}}, socket) do
    tenant = socket.assigns.tenant

    result =
      User
      |> Ash.Query.for_read(
        :sign_in_with_password,
        %{email: email, password: password},
        tenant: tenant
      )
      |> Ash.read_one()

    case result do
      {:ok, %User{} = user} ->
        token = user.__metadata__.token

        form =
          to_form(
            %{"email" => email, "password" => password, "token" => token},
            as: :session
          )

        {:noreply,
         socket
         |> assign(:form, form)
         |> assign(:trigger_submit, true)}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid email or password")
         |> assign(:form, to_form(%{"email" => email, "password" => ""}, as: :session))}
    end
  end
end
