defmodule Haul.Accounts.User.Role do
  @moduledoc false
  use Ash.Type.Enum, values: [:owner, :dispatcher, :crew]
end
