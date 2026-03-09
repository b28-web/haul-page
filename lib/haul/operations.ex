defmodule Haul.Operations do
  @moduledoc false
  use Ash.Domain

  resources do
    resource Haul.Operations.Job
  end
end
