defmodule HaulWeb.App.SignupLive do
  use HaulWeb, :live_view

  alias Haul.Onboarding
  alias Haul.RateLimiter

  @impl true
  def mount(_params, session, socket) do
    base_domain = Application.get_env(:haul, :base_domain, "haulpage.com")
    remote_ip = session["remote_ip"] || "unknown"

    {:ok,
     socket
     |> assign(:page_title, "Create Your Site")
     |> assign(:base_domain, base_domain)
     |> assign(:remote_ip, remote_ip)
     |> assign(:slug, "")
     |> assign(:slug_available, nil)
     |> assign(:trigger_submit, false)
     |> assign(:submitting, false)
     |> assign(:token, nil)
     |> assign(:tenant, nil)
     |> assign(:form, to_form(default_params(), as: :signup))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-background px-4 py-12">
      <div class="w-full max-w-md space-y-8">
        <div class="text-center">
          <h1 class="font-display text-3xl uppercase tracking-wider text-foreground">
            Get Your Hauling Site Live
          </h1>
          <p class="mt-2 text-sm text-muted-foreground">
            Free to start. No credit card required.
          </p>
        </div>

        <HaulWeb.Layouts.flash_group flash={@flash} />

        <.form
          for={@form}
          action={~p"/app/session"}
          phx-change="validate"
          phx-submit="submit"
          phx-trigger-action={@trigger_submit}
          class="space-y-5"
        >
          <.input
            field={@form[:name]}
            type="text"
            label="Business Name"
            required
            placeholder="Joe's Hauling"
            phx-debounce="300"
            autocomplete="organization"
          />

          <div :if={@slug != ""} class="text-sm text-muted-foreground -mt-3 ml-1">
            Your site: <span class="text-foreground font-medium">{@slug}.{@base_domain}</span>
            <span :if={@slug_available == true} class="text-green-500 ml-1">Available</span>
            <span :if={@slug_available == false} class="text-red-500 ml-1">Taken</span>
          </div>

          <.input
            field={@form[:email]}
            type="email"
            label="Email"
            required
            placeholder="joe@example.com"
            phx-debounce="300"
            autocomplete="email"
          />

          <.input
            field={@form[:phone]}
            type="tel"
            label="Phone"
            placeholder="(555) 123-4567"
            phx-debounce="300"
            autocomplete="tel"
          />

          <.input
            field={@form[:area]}
            type="text"
            label="Service Area"
            placeholder="Denver metro area"
            phx-debounce="300"
          />

          <.input
            field={@form[:password]}
            type="password"
            label="Password"
            required
            autocomplete="new-password"
            phx-debounce="blur"
          />

          <.input
            field={@form[:password_confirmation]}
            type="password"
            label="Confirm Password"
            required
            autocomplete="new-password"
            phx-debounce="blur"
          />

          <%!-- Honeypot field — hidden from real users --%>
          <div aria-hidden="true" style="position: absolute; left: -9999px; top: -9999px;">
            <.input field={@form[:website]} type="text" label="Website" tabindex="-1" />
          </div>

          <input type="hidden" name="session[token]" value={@token} />
          <input type="hidden" name="session[tenant]" value={@tenant} />

          <.button type="submit" class="w-full" disabled={@submitting}>
            {if @submitting, do: "Creating your site...", else: "Create My Site"}
          </.button>
        </.form>

        <p class="text-center text-sm text-muted-foreground">
          Already have an account?
          <.link navigate={~p"/app/login"} class="text-foreground underline">Sign in</.link>
        </p>

        <p class="text-center text-sm text-muted-foreground">
          Or <a href={~p"/start"} class="text-foreground underline">try our AI assistant</a>
        </p>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"signup" => params}, socket) do
    name = Map.get(params, "name", "")
    slug = Onboarding.derive_slug(name)

    slug_available =
      if slug != "" do
        Onboarding.slug_available?(slug)
      else
        nil
      end

    form = to_form(params, as: :signup)

    {:noreply,
     socket
     |> assign(:form, form)
     |> assign(:slug, slug)
     |> assign(:slug_available, slug_available)}
  end

  @impl true
  def handle_event("submit", %{"signup" => params}, socket) do
    # Honeypot check — silently reject bots
    if Map.get(params, "website", "") != "" do
      {:noreply,
       socket
       |> put_flash(:info, "Your site is being created...")
       |> assign(:submitting, true)}
    else
      do_submit(params, socket)
    end
  end

  defp do_submit(params, socket) do
    ip = socket.assigns.remote_ip

    case RateLimiter.check_rate({:signup, ip}, 5, 3600) do
      {:error, :rate_limited} ->
        {:noreply,
         socket
         |> put_flash(:error, "Too many signup attempts. Please try again in an hour.")}

      :ok ->
        signup_params = %{
          name: Map.get(params, "name", ""),
          email: Map.get(params, "email", ""),
          phone: Map.get(params, "phone", ""),
          area: Map.get(params, "area", ""),
          password: Map.get(params, "password", ""),
          password_confirmation: Map.get(params, "password_confirmation", "")
        }

        socket = assign(socket, :submitting, true)

        case Onboarding.signup(signup_params) do
          {:ok, result} ->
            token = result.user.__metadata__.token

            {:noreply,
             socket
             |> assign(:token, token)
             |> assign(:tenant, result.tenant)
             |> assign(:trigger_submit, true)}

          {:error, :validation, message} ->
            {:noreply,
             socket
             |> assign(:submitting, false)
             |> put_flash(:error, message)}

          {:error, :user_create, message} when is_binary(message) ->
            {:noreply,
             socket
             |> assign(:submitting, false)
             |> put_flash(:error, message)}

          {:error, _step, _reason} ->
            {:noreply,
             socket
             |> assign(:submitting, false)
             |> put_flash(:error, "Something went wrong creating your site. Please try again.")}
        end
    end
  end

  defp default_params do
    %{
      "name" => "",
      "email" => "",
      "phone" => "",
      "area" => "",
      "password" => "",
      "password_confirmation" => "",
      "website" => ""
    }
  end
end
