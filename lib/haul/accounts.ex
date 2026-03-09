defmodule Haul.Accounts do
  @moduledoc false
  use Ash.Domain

  resources do
    resource Haul.Accounts.Company
    resource Haul.Accounts.User
    resource Haul.Accounts.Token
  end
end
