defmodule HaulWeb.Admin.SetupLive do
  use HaulWeb, :live_view

  alias Haul.Admin.AdminUser

  require Ash.Query

  @impl true
  def mount(%{"token" => raw_token}, _session, socket) do
    token_hash =
      :crypto.hash(:sha256, raw_token) |> Base.encode16(case: :lower)

    case find_pending_admin(token_hash) do
      {:ok, admin} ->
        {:ok,
         socket
         |> assign(:admin, admin)
         |> assign(:raw_token, raw_token)
         |> assign(:page_title, "Set Up Admin Account")
         |> assign(:form, to_form(%{"password" => "", "password_confirmation" => ""}, as: :setup))}

      :not_found ->
        {:ok, socket |> redirect(to: "/404")}
    end
  end

  defp find_pending_admin(token_hash) do
    case AdminUser
         |> Ash.Query.filter(setup_token_hash == ^token_hash and setup_completed == false)
         |> Ash.read_one(authorize?: false) do
      {:ok, %AdminUser{} = admin} -> {:ok, admin}
      _ -> :not_found
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-background px-4">
      <div class="w-full max-w-sm space-y-8">
        <div class="text-center">
          <h1 class="font-display text-3xl uppercase tracking-wider text-foreground">
            Admin Setup
          </h1>
          <p class="mt-2 text-sm text-muted-foreground">Set your password to complete setup</p>
        </div>

        <HaulWeb.Layouts.flash_group flash={@flash} />

        <.form for={@form} phx-submit="setup" class="space-y-6">
          <.input
            field={@form[:password]}
            type="password"
            label="Password"
            required
            autocomplete="new-password"
          />
          <.input
            field={@form[:password_confirmation]}
            type="password"
            label="Confirm Password"
            required
            autocomplete="new-password"
          />
          <.button type="submit" class="w-full">
            Set Password
          </.button>
        </.form>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("setup", %{"setup" => params}, socket) do
    %{"password" => password, "password_confirmation" => confirmation} = params
    admin = socket.assigns.admin

    cond do
      String.length(password) < 8 ->
        {:noreply, put_flash(socket, :error, "Password must be at least 8 characters")}

      password != confirmation ->
        {:noreply, put_flash(socket, :error, "Passwords do not match")}

      true ->
        hashed = Bcrypt.hash_pwd_salt(password)

        case admin
             |> Ash.Changeset.for_update(:complete_setup, %{hashed_password: hashed},
               authorize?: false
             )
             |> Ash.update() do
          {:ok, _} ->
            {:noreply,
             socket
             |> put_flash(:info, "Account created. Please sign in.")
             |> redirect(to: ~p"/admin/login")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Something went wrong. Please try again.")}
        end
    end
  end
end
