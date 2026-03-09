defmodule Haul.Content do
  @moduledoc false
  use Ash.Domain

  resources do
    resource Haul.Content.SiteConfig
    resource Haul.Content.SiteConfig.Version
    resource Haul.Content.Service
    resource Haul.Content.Service.Version
    resource Haul.Content.GalleryItem
    resource Haul.Content.GalleryItem.Version
    resource Haul.Content.Endorsement
    resource Haul.Content.Endorsement.Version
    resource Haul.Content.Page
    resource Haul.Content.Page.Version
  end
end
