defmodule Haul.Test.LiveHelpers do
  @moduledoc """
  Lightweight helpers for testing LiveView handle_event/3 and handle_info/2
  callbacks without mounting a full LiveView process.

  Use these for callbacks that are essentially pure functions on socket assigns
  (no DB, no file I/O, no PubSub). Keep full-mount integration tests for
  rendering, routing, auth, and HTML assertions.

  ## Example

      import Haul.Test.LiveHelpers

      test "next increments step" do
        socket = build_socket(%{step: 1})
        assert {:noreply, socket} = apply_event(OnboardingLive, "next", %{}, socket)
        assert socket.assigns.step == 2
      end
  """

  @doc "Creates a minimal `%Phoenix.LiveView.Socket{}` with the given assigns."
  def build_socket(assigns \\ %{}) do
    %Phoenix.LiveView.Socket{
      assigns: Map.merge(%{__changed__: %{}, flash: %{}}, assigns)
    }
  end

  @doc "Calls `module.handle_event(event, params, socket)` directly."
  def apply_event(module, event, params, socket) do
    module.handle_event(event, params, socket)
  end

  @doc "Calls `module.handle_info(msg, socket)` directly."
  def apply_info(module, msg, socket) do
    module.handle_info(msg, socket)
  end

  @doc "Extracts an assign value from a handle_event/handle_info return tuple."
  def get_assign({:noreply, socket}, key), do: socket.assigns[key]
  def get_assign({:reply, _map, socket}, key), do: socket.assigns[key]
end
