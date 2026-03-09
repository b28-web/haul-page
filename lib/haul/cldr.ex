defmodule Haul.Cldr do
  @moduledoc """
  CLDR backend for locale-aware number and money formatting.
  """

  use Cldr,
    locales: ["en"],
    default_locale: "en",
    providers: [Cldr.Number, Money]
end
