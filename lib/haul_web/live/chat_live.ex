defmodule HaulWeb.ChatLive do
  use HaulWeb, :live_view

  alias Haul.AI.Chat
  alias Haul.AI.Conversation
  alias Haul.AI.Extractor
  alias Haul.AI.OperatorProfile
  alias Haul.AI.Prompt
  alias Haul.RateLimiter
  alias Haul.Workers.ProvisionSite

  require Logger

  @max_messages 50
  @rate_window 86_400
  @extraction_debounce_ms 800
  @total_profile_fields 7

  @impl true
  def mount(_params, session, socket) do
    # If LLM is not configured, silently redirect to manual signup
    unless Chat.configured?() do
      {:ok, redirect(socket, to: ~p"/app/signup")}
    else
      system_prompt =
        case Prompt.load("onboarding_agent") do
          {:ok, content} -> content
          {:error, _} -> "You are a helpful onboarding assistant for a junk removal business."
        end

      session_id = session["chat_session_id"] || Ecto.UUID.generate()
      {conversation, messages, message_count} = load_or_create_conversation(session_id)

      if connected?(socket) do
        Phoenix.PubSub.subscribe(Haul.PubSub, "provisioning:#{session_id}")
      end

      {:ok,
       socket
       |> assign(:page_title, "Get Started")
       |> assign(:messages, messages)
       |> assign(:input, "")
       |> assign(:streaming?, false)
       |> assign(:message_count, message_count)
       |> assign(:session_id, session_id)
       |> assign(:conversation, conversation)
       |> assign(:system_prompt, system_prompt)
       |> assign(:task_ref, nil)
       |> assign(:profile, nil)
       |> assign(:missing_fields, all_profile_fields())
       |> assign(:extraction_ref, nil)
       |> assign(:extraction_timer, nil)
       |> assign(:profile_complete?, false)
       |> assign(:show_profile?, false)
       |> assign(:provisioning?, false)
       |> assign(:provisioned_url, nil)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-dvh bg-background text-foreground md:flex-row">
      <%!-- Chat column --%>
      <div class="flex flex-col flex-1 min-w-0">
        <%!-- Header --%>
        <header class="flex-none border-b border-border px-4 py-3 flex items-center justify-between">
          <div>
            <h1 class="text-lg font-display uppercase tracking-wide">Get Started</h1>
            <p class="text-sm text-muted-foreground">
              Tell us about your business —
              <a href={~p"/app/signup"} class="underline hover:text-foreground">
                or sign up manually
              </a>
            </p>
          </div>
          <%!-- Mobile profile toggle --%>
          <%= if @profile do %>
            <button
              phx-click="toggle_profile"
              class="md:hidden rounded-full px-3 py-1.5 text-xs font-medium bg-zinc-700 text-zinc-100 hover:bg-zinc-600 transition-colors"
            >
              {if @show_profile?, do: "Hide Profile", else: "View Profile"}
            </button>
          <% end %>
        </header>

        <%!-- Mobile profile card --%>
        <%= if @show_profile? and @profile do %>
          <div class="md:hidden border-b border-border">
            <.profile_panel
              profile={@profile}
              missing_fields={@missing_fields}
              profile_complete?={@profile_complete?}
              provisioning?={@provisioning?}
              provisioned_url={@provisioned_url}
            />
          </div>
        <% end %>

        <%!-- Messages --%>
        <div
          id="chat-messages"
          phx-hook="ChatScroll"
          class="flex-1 overflow-y-auto px-4 py-4 space-y-3"
        >
          <%= if @messages == [] do %>
            <div class="flex items-center justify-center h-full">
              <p class="text-muted-foreground text-center max-w-xs">
                Hi! I'm here to help set up your business page.
                <br />Tell me about your junk removal business.
              </p>
            </div>
          <% else %>
            <%= for msg <- @messages do %>
              <div class={[
                "flex",
                if(msg.role == :user, do: "justify-end", else: "justify-start")
              ]}>
                <div class={[
                  "max-w-[85%] rounded-2xl px-4 py-2 text-sm leading-relaxed",
                  if(msg.role == :user,
                    do: "bg-zinc-700 text-zinc-100 rounded-br-sm",
                    else: "bg-card text-foreground border border-border rounded-bl-sm"
                  )
                ]}>
                  <p class="whitespace-pre-wrap">{msg.content}</p>
                </div>
              </div>
            <% end %>

            <%!-- Typing indicator --%>
            <%= if @streaming? and not has_assistant_content?(@messages) do %>
              <div class="flex justify-start">
                <div class="bg-card border border-border rounded-2xl rounded-bl-sm px-4 py-3">
                  <div class="flex space-x-1.5">
                    <div class="w-2 h-2 bg-muted-foreground rounded-full animate-bounce [animation-delay:0ms]">
                    </div>
                    <div class="w-2 h-2 bg-muted-foreground rounded-full animate-bounce [animation-delay:150ms]">
                    </div>
                    <div class="w-2 h-2 bg-muted-foreground rounded-full animate-bounce [animation-delay:300ms]">
                    </div>
                  </div>
                </div>
              </div>
            <% end %>
          <% end %>
        </div>

        <%!-- Input --%>
        <div class="flex-none border-t border-border px-4 py-3">
          <form phx-submit="send_message" class="flex gap-2">
            <input
              type="text"
              name="text"
              value={@input}
              phx-change="update_input"
              placeholder="Type a message..."
              autocomplete="off"
              disabled={@streaming?}
              class={[
                "flex-1 rounded-full px-4 py-2 text-sm",
                "bg-card border border-border text-foreground",
                "placeholder:text-muted-foreground",
                "focus:outline-none focus:ring-1 focus:ring-zinc-500",
                "disabled:opacity-50"
              ]}
            />
            <button
              type="submit"
              disabled={@streaming? or String.trim(@input) == ""}
              class={[
                "rounded-full px-4 py-2 text-sm font-medium",
                "bg-zinc-700 text-zinc-100 hover:bg-zinc-600",
                "disabled:opacity-50 disabled:cursor-not-allowed",
                "transition-colors"
              ]}
            >
              Send
            </button>
          </form>

          <%= if @message_count >= 50 do %>
            <p class="text-xs text-red-400 mt-1 text-center">
              Message limit reached. Please refresh to start a new session.
            </p>
          <% end %>

          <p class="text-xs text-muted-foreground mt-2 text-center">
            Prefer a form?
            <a href={~p"/app/signup"} class="underline hover:text-foreground">
              Fill out a form instead
            </a>
          </p>
        </div>
      </div>

      <%!-- Desktop profile sidebar --%>
      <div class="hidden md:block w-80 border-l border-border overflow-y-auto">
        <.profile_panel
          profile={@profile}
          missing_fields={@missing_fields}
          profile_complete?={@profile_complete?}
          provisioning?={@provisioning?}
          provisioned_url={@provisioned_url}
        />
      </div>
    </div>
    """
  end

  # Profile panel function component
  defp profile_panel(assigns) do
    filled = @total_profile_fields - length(assigns.missing_fields)
    completeness_pct = round(filled / @total_profile_fields * 100)

    assigns =
      assigns
      |> assign(:filled, filled)
      |> assign(:total, @total_profile_fields)
      |> assign(:completeness_pct, completeness_pct)

    ~H"""
    <div class="p-4 space-y-4">
      <div>
        <h2 class="text-sm font-display uppercase tracking-wide text-foreground">Your Profile</h2>
        <p class="text-xs text-muted-foreground mt-1">
          {@filled} of {@total} fields collected
        </p>
      </div>

      <%!-- Progress bar --%>
      <div class="w-full bg-zinc-800 rounded-full h-2">
        <div
          class="bg-zinc-400 h-2 rounded-full transition-all duration-500 ease-out"
          style={"width: #{@completeness_pct}%"}
        >
        </div>
      </div>

      <%= if @profile do %>
        <div class="space-y-3">
          <.profile_field label="Business Name" value={@profile.business_name} />
          <.profile_field label="Owner" value={@profile.owner_name} />
          <.profile_field label="Phone" value={@profile.phone} />
          <.profile_field label="Email" value={@profile.email} />
          <.profile_field label="Service Area" value={@profile.service_area} />

          <%!-- Services --%>
          <div>
            <p class="text-xs text-muted-foreground uppercase tracking-wide">Services</p>
            <%= if @profile.services != [] do %>
              <ul class="mt-1 space-y-1">
                <%= for svc <- @profile.services do %>
                  <li class="text-sm text-foreground transition-colors duration-300">
                    {svc.name}
                  </li>
                <% end %>
              </ul>
            <% else %>
              <p class="text-sm text-muted-foreground mt-1 italic">Not yet provided</p>
            <% end %>
          </div>

          <%!-- Differentiators --%>
          <div>
            <p class="text-xs text-muted-foreground uppercase tracking-wide">What Sets You Apart</p>
            <%= if @profile.differentiators != [] do %>
              <ul class="mt-1 space-y-1">
                <%= for diff <- @profile.differentiators do %>
                  <li class="text-sm text-foreground transition-colors duration-300">
                    {diff}
                  </li>
                <% end %>
              </ul>
            <% else %>
              <p class="text-sm text-muted-foreground mt-1 italic">Not yet provided</p>
            <% end %>
          </div>
        </div>

        <%!-- Profile complete CTA --%>
        <%= if @profile_complete? do %>
          <div class="mt-4 p-3 rounded-lg bg-zinc-800 border border-zinc-600">
            <%= if @provisioned_url do %>
              <p class="text-sm font-medium text-foreground">Your site is live!</p>
              <a
                href={@provisioned_url}
                target="_blank"
                class="mt-2 block w-full text-center rounded-full px-4 py-2 text-sm font-medium bg-zinc-100 text-zinc-900 hover:bg-white transition-colors"
              >
                View your site
              </a>
            <% else %>
              <p class="text-sm font-medium text-foreground">Your profile is complete!</p>
              <button
                phx-click="provision_site"
                disabled={@provisioning?}
                class={[
                  "mt-2 block w-full text-center rounded-full px-4 py-2 text-sm font-medium transition-colors",
                  if(@provisioning?,
                    do: "bg-zinc-500 text-zinc-300 cursor-wait",
                    else: "bg-zinc-100 text-zinc-900 hover:bg-white"
                  )
                ]}
              >
                {if @provisioning?, do: "Building your site...", else: "Build my site"}
              </button>
            <% end %>
          </div>
        <% end %>
      <% else %>
        <p class="text-sm text-muted-foreground italic">
          Start chatting to build your profile...
        </p>
      <% end %>
    </div>
    """
  end

  defp profile_field(assigns) do
    ~H"""
    <div>
      <p class="text-xs text-muted-foreground uppercase tracking-wide">{@label}</p>
      <p class={[
        "text-sm mt-0.5 transition-colors duration-300",
        if(@value, do: "text-foreground", else: "text-muted-foreground italic")
      ]}>
        {@value || "Not yet provided"}
      </p>
    </div>
    """
  end

  @impl true
  def handle_event("update_input", %{"text" => text}, socket) do
    {:noreply, assign(socket, :input, text)}
  end

  # Ignore form wrapper params from phx-change
  def handle_event("update_input", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("send_message", %{"text" => text}, socket) do
    text = String.trim(text)

    cond do
      text == "" ->
        {:noreply, socket}

      socket.assigns.streaming? ->
        {:noreply, socket}

      socket.assigns.message_count >= @max_messages ->
        {:noreply, put_flash(socket, :error, "Message limit reached for this session.")}

      true ->
        case RateLimiter.check_rate(
               {:chat, socket.assigns.session_id},
               @max_messages,
               @rate_window
             ) do
          :ok ->
            send_user_message(socket, text)

          {:error, :rate_limited} ->
            {:noreply, put_flash(socket, :error, "Too many messages. Please try again later.")}
        end
    end
  end

  def handle_event("provision_site", _params, socket) do
    %{
      profile_complete?: complete?,
      provisioning?: provisioning?,
      profile: profile,
      conversation: conv,
      session_id: session_id
    } = socket.assigns

    cond do
      not complete? ->
        {:noreply, put_flash(socket, :error, "Please complete your profile first.")}

      provisioning? ->
        {:noreply, socket}

      is_nil(conv) ->
        {:noreply, put_flash(socket, :error, "Session error. Please refresh.")}

      true ->
        case ProvisionSite.enqueue(conv.id, profile, session_id) do
          {:ok, _job} ->
            system_msg = %{
              id: Ecto.UUID.generate(),
              role: :assistant,
              content: "Building your site — this takes about 20 seconds..."
            }

            {:noreply,
             socket
             |> assign(:provisioning?, true)
             |> assign(:messages, socket.assigns.messages ++ [system_msg])
             |> push_event("scroll_to_bottom", %{})}

          {:error, reason} ->
            Logger.error("[ChatLive] Failed to enqueue provisioning: #{inspect(reason)}")
            {:noreply, put_flash(socket, :error, "Something went wrong. Please try again.")}
        end
    end
  end

  def handle_event("toggle_profile", _params, socket) do
    {:noreply, assign(socket, :show_profile?, !socket.assigns.show_profile?)}
  end

  @impl true
  def handle_info({:ai_chunk, text}, socket) do
    messages = append_to_last_assistant(socket.assigns.messages, text)

    {:noreply,
     socket
     |> assign(:messages, messages)
     |> push_event("scroll_to_bottom", %{})}
  end

  def handle_info({:ai_done}, socket) do
    # Persist completed assistant message to DB
    case List.last(socket.assigns.messages) do
      %{role: :assistant, content: content} when content != "" ->
        persist_message(socket.assigns.conversation, %{
          "role" => "assistant",
          "content" => content
        })

      _ ->
        :ok
    end

    {:noreply,
     socket
     |> assign(:streaming?, false)
     |> assign(:task_ref, nil)}
  end

  def handle_info({:ai_error, reason}, socket) do
    if socket.assigns.message_count == 1 do
      # First message failed — redirect to manual signup
      {:noreply,
       socket
       |> assign(:streaming?, false)
       |> assign(:task_ref, nil)
       |> put_flash(:error, "Chat is temporarily unavailable — use this form instead")
       |> redirect(to: ~p"/app/signup")}
    else
      error_msg =
        if is_binary(reason), do: reason, else: "Something went wrong. Please try again."

      {:noreply,
       socket
       |> assign(:streaming?, false)
       |> assign(:task_ref, nil)
       |> put_flash(:error, error_msg)}
    end
  end

  def handle_info(:run_extraction, socket) do
    messages = socket.assigns.messages
    lv_pid = self()

    # Only extract if there are user messages
    user_messages = Enum.filter(messages, &(&1.role == :user))

    if user_messages == [] do
      {:noreply, assign(socket, :extraction_timer, nil)}
    else
      transcript = build_transcript(messages)

      {:ok, task_pid} =
        Task.start(fn ->
          case Extractor.extract_profile(transcript) do
            {:ok, profile} -> send(lv_pid, {:extraction_result, {:ok, profile}})
            {:error, reason} -> send(lv_pid, {:extraction_result, {:error, reason}})
          end
        end)

      ref = Process.monitor(task_pid)

      {:noreply,
       socket
       |> assign(:extraction_ref, ref)
       |> assign(:extraction_timer, nil)}
    end
  end

  def handle_info({:extraction_result, {:ok, %OperatorProfile{} = profile}}, socket) do
    missing = Extractor.validate_completeness(profile)
    required_missing = Enum.filter(missing, &(&1 in [:business_name, :phone, :email]))

    # Persist extracted profile to conversation
    save_extracted_profile(socket.assigns.conversation, profile)

    {:noreply,
     socket
     |> assign(:profile, profile)
     |> assign(:missing_fields, missing)
     |> assign(:profile_complete?, required_missing == [])
     |> assign(:show_profile?, true)
     |> assign(:extraction_ref, nil)}
  end

  def handle_info({:extraction_result, {:error, reason}}, socket) do
    Logger.warning("Profile extraction failed: #{inspect(reason)}")
    {:noreply, assign(socket, :extraction_ref, nil)}
  end

  def handle_info({:provisioning_complete, result}, socket) do
    success_msg = %{
      id: Ecto.UUID.generate(),
      role: :assistant,
      content: "Your site is live! Visit it here: #{result.site_url}"
    }

    {:noreply,
     socket
     |> assign(:provisioning?, false)
     |> assign(:provisioned_url, result.site_url)
     |> assign(:messages, socket.assigns.messages ++ [success_msg])
     |> push_event("scroll_to_bottom", %{})}
  end

  def handle_info({:provisioning_failed, _details}, socket) do
    error_msg = %{
      id: Ecto.UUID.generate(),
      role: :assistant,
      content:
        "Something went wrong building your site. We'll get it sorted out — please try again or sign up manually."
    }

    {:noreply,
     socket
     |> assign(:provisioning?, false)
     |> assign(:messages, socket.assigns.messages ++ [error_msg])
     |> push_event("scroll_to_bottom", %{})}
  end

  def handle_info({:DOWN, ref, :process, _pid, reason}, socket) do
    cond do
      socket.assigns.task_ref == ref and reason != :normal ->
        {:noreply,
         socket
         |> assign(:streaming?, false)
         |> assign(:task_ref, nil)
         |> put_flash(:error, "Something went wrong. Please try again.")}

      socket.assigns.extraction_ref == ref and reason != :normal ->
        Logger.warning("Extraction task crashed: #{inspect(reason)}")
        {:noreply, assign(socket, :extraction_ref, nil)}

      true ->
        {:noreply, socket}
    end
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  # Private

  defp send_user_message(socket, text) do
    user_msg = %{id: Ecto.UUID.generate(), role: :user, content: text}
    messages = socket.assigns.messages ++ [user_msg]
    count = socket.assigns.message_count + 1

    # Persist user message to DB
    persist_message(socket.assigns.conversation, %{"role" => "user", "content" => text})

    # Add placeholder for assistant response
    assistant_msg = %{id: Ecto.UUID.generate(), role: :assistant, content: ""}
    messages_with_placeholder = messages ++ [assistant_msg]

    # Spawn streaming task
    lv_pid = self()
    system_prompt = socket.assigns.system_prompt

    # Only send role + content to the API (not id)
    api_messages = Enum.map(messages, fn msg -> %{role: msg.role, content: msg.content} end)

    {:ok, task_pid} =
      Task.start(fn ->
        Chat.stream_message(api_messages, system_prompt, lv_pid)
      end)

    ref = Process.monitor(task_pid)

    {:noreply,
     socket
     |> assign(:messages, messages_with_placeholder)
     |> assign(:input, "")
     |> assign(:streaming?, true)
     |> assign(:message_count, count)
     |> assign(:task_ref, ref)
     |> schedule_extraction()
     |> push_event("scroll_to_bottom", %{})}
  end

  defp schedule_extraction(socket) do
    # Cancel any pending extraction timer
    if socket.assigns.extraction_timer do
      Process.cancel_timer(socket.assigns.extraction_timer)
    end

    timer_ref = Process.send_after(self(), :run_extraction, @extraction_debounce_ms)
    assign(socket, :extraction_timer, timer_ref)
  end

  defp build_transcript(messages) do
    messages
    |> Enum.reject(&(&1.content == ""))
    |> Enum.map(fn msg -> "#{msg.role}: #{msg.content}" end)
    |> Enum.join("\n")
  end

  defp append_to_last_assistant(messages, text) do
    case List.last(messages) do
      %{role: :assistant} = msg ->
        updated = %{msg | content: msg.content <> text}
        List.replace_at(messages, -1, updated)

      _ ->
        messages
    end
  end

  defp has_assistant_content?(messages) do
    case List.last(messages) do
      %{role: :assistant, content: content} when content != "" -> true
      _ -> false
    end
  end

  defp all_profile_fields do
    [:business_name, :owner_name, :phone, :email, :service_area, :services, :differentiators]
  end

  defp load_or_create_conversation(session_id) do
    case Conversation
         |> Ash.Query.for_read(:by_session_id, %{session_id: session_id})
         |> Ash.read_one() do
      {:ok, %Conversation{} = conv} ->
        messages = restore_messages(conv.messages)
        {conv, messages, length(messages)}

      _ ->
        case Conversation
             |> Ash.Changeset.for_create(:start, %{session_id: session_id})
             |> Ash.create() do
          {:ok, conv} -> {conv, [], 0}
          {:error, _} -> {nil, [], 0}
        end
    end
  end

  defp restore_messages(db_messages) when is_list(db_messages) do
    Enum.map(db_messages, fn msg ->
      %{
        id: Ecto.UUID.generate(),
        role: String.to_existing_atom(msg["role"]),
        content: msg["content"] || ""
      }
    end)
  end

  defp restore_messages(_), do: []

  defp persist_message(nil, _message), do: :ok

  defp persist_message(conversation, message) do
    conversation
    |> Ash.Changeset.for_update(:add_message, %{message: message})
    |> Ash.update()
    |> case do
      {:ok, updated} -> {:ok, updated}
      {:error, reason} -> Logger.warning("Failed to persist message: #{inspect(reason)}")
    end
  end

  defp save_extracted_profile(nil, _profile), do: :ok

  defp save_extracted_profile(conversation, %OperatorProfile{} = profile) do
    profile_map = deep_to_map(profile)

    conversation
    |> Ash.Changeset.for_update(:save_profile, %{extracted_profile: profile_map})
    |> Ash.update()
    |> case do
      {:ok, _} -> :ok
      {:error, reason} -> Logger.warning("Failed to save profile: #{inspect(reason)}")
    end
  end

  defp deep_to_map(%{__struct__: _} = struct) do
    struct
    |> Map.from_struct()
    |> Map.new(fn {k, v} -> {k, deep_to_map(v)} end)
  end

  defp deep_to_map(list) when is_list(list), do: Enum.map(list, &deep_to_map/1)
  defp deep_to_map(value), do: value
end
