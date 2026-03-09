defmodule Haul.AI.Domain do
  @moduledoc false
  use Ash.Domain

  resources do
    resource Haul.AI.Conversation
  end
end
