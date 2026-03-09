defmodule Haul.AI.Domain do
  @moduledoc false
  use Ash.Domain

  resources do
    resource Haul.AI.Conversation
    resource Haul.AI.CostEntry
  end
end
