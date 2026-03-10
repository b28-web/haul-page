defmodule HaulWeb.App.OnboardingLiveUnitTest do
  use ExUnit.Case, async: true

  import Haul.Test.LiveHelpers

  alias HaulWeb.App.OnboardingLive

  describe "next event" do
    test "increments step" do
      socket = build_socket(%{step: 1})
      assert {:noreply, socket} = apply_event(OnboardingLive, "next", %{}, socket)
      assert socket.assigns.step == 2
    end

    test "increments from middle step" do
      socket = build_socket(%{step: 3})
      assert {:noreply, socket} = apply_event(OnboardingLive, "next", %{}, socket)
      assert socket.assigns.step == 4
    end

    test "clamps at step 6" do
      socket = build_socket(%{step: 6})
      assert {:noreply, socket} = apply_event(OnboardingLive, "next", %{}, socket)
      assert socket.assigns.step == 6
    end

    test "step 5 goes to 6" do
      socket = build_socket(%{step: 5})
      assert {:noreply, socket} = apply_event(OnboardingLive, "next", %{}, socket)
      assert socket.assigns.step == 6
    end
  end

  describe "back event" do
    test "decrements step" do
      socket = build_socket(%{step: 3})
      assert {:noreply, socket} = apply_event(OnboardingLive, "back", %{}, socket)
      assert socket.assigns.step == 2
    end

    test "clamps at step 1" do
      socket = build_socket(%{step: 1})
      assert {:noreply, socket} = apply_event(OnboardingLive, "back", %{}, socket)
      assert socket.assigns.step == 1
    end

    test "step 2 goes to 1" do
      socket = build_socket(%{step: 2})
      assert {:noreply, socket} = apply_event(OnboardingLive, "back", %{}, socket)
      assert socket.assigns.step == 1
    end
  end

  describe "goto event" do
    test "navigates to valid step" do
      socket = build_socket(%{step: 1})
      assert {:noreply, socket} = apply_event(OnboardingLive, "goto", %{"step" => "3"}, socket)
      assert socket.assigns.step == 3
    end

    test "navigates to step 1" do
      socket = build_socket(%{step: 4})
      assert {:noreply, socket} = apply_event(OnboardingLive, "goto", %{"step" => "1"}, socket)
      assert socket.assigns.step == 1
    end

    test "navigates to step 6" do
      socket = build_socket(%{step: 1})
      assert {:noreply, socket} = apply_event(OnboardingLive, "goto", %{"step" => "6"}, socket)
      assert socket.assigns.step == 6
    end

    test "ignores step 0 (out of range)" do
      socket = build_socket(%{step: 3})
      assert {:noreply, socket} = apply_event(OnboardingLive, "goto", %{"step" => "0"}, socket)
      assert socket.assigns.step == 3
    end

    test "ignores step 7 (out of range)" do
      socket = build_socket(%{step: 3})
      assert {:noreply, socket} = apply_event(OnboardingLive, "goto", %{"step" => "7"}, socket)
      assert socket.assigns.step == 3
    end

    test "ignores step 99 (out of range)" do
      socket = build_socket(%{step: 1})
      assert {:noreply, socket} = apply_event(OnboardingLive, "goto", %{"step" => "99"}, socket)
      assert socket.assigns.step == 1
    end
  end

  describe "validate_logo event" do
    test "returns socket unchanged" do
      socket = build_socket(%{step: 4})
      assert {:noreply, ^socket} = apply_event(OnboardingLive, "validate_logo", %{}, socket)
    end
  end
end
