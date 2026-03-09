defmodule Haul.Domains.Sandbox do
  @moduledoc false
  @behaviour Haul.Domains.CertAdapter

  @impl true
  def add_cert(_domain), do: {:ok, %{status: "pending"}}

  @impl true
  def check_cert(_domain), do: {:ok, :ready}

  @impl true
  def remove_cert(_domain), do: :ok
end
