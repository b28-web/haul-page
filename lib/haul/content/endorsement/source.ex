defmodule Haul.Content.Endorsement.Source do
  @moduledoc false
  use Ash.Type.Enum, values: [:google, :yelp, :direct, :facebook]
end
