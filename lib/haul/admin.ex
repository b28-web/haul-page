defmodule Haul.Admin do
  @moduledoc false
  use Ash.Domain

  resources do
    resource Haul.Admin.AdminUser
    resource Haul.Admin.AdminToken
  end
end
