defmodule HaulWeb.Admin.LoginLive do
  use HaulWeb, :live_view

  alias Haul.Admin.AdminUser

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Admin Sign In")
     |> assign(:trigger_submit, false)
     |> assign(:form, to_form(%{"email" => "", "password" => ""}, as: :session))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-background px-4">
      <div class="w-full max-w-sm space-y-8">
        <div class="text-center">
          <h1 class="font-display text-3xl uppercase tracking-wider text-foreground">
            Admin Sign In
          </h1>
        </div>

        <HaulWeb.Layouts.flash_group flash={@flash} />

        <.form
          for={@form}
          action={~p"/admin/session"}
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
    result =
      AdminUser
      |> Ash.Query.for_read(
        :sign_in_with_password,
        %{email: email, password: password}
      )
      |> Ash.read_one()

    case result do
      {:ok, %AdminUser{setup_completed: true} = admin} ->
        token = admin.__metadata__.token

        form =
          to_form(
            %{"email" => email, "password" => password, "token" => token},
            as: :session
          )

        {:noreply,
         socket
         |> assign(:form, form)
         |> assign(:trigger_submit, true)}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid email or password")
         |> assign(:form, to_form(%{"email" => email, "password" => ""}, as: :session))}
    end
  end
end
