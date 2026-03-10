defmodule Haul.Content.Page do
  @moduledoc false
  use Ash.Resource,
    domain: Haul.Content,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshPaperTrail.Resource]

  paper_trail do
    change_tracking_mode :changes_only
  end

  postgres do
    table "pages"
    repo Haul.Repo

    multitenancy do
      strategy :context
    end
  end

  multitenancy do
    strategy :context
  end

  attributes do
    uuid_primary_key :id

    attribute :slug, :string do
      allow_nil? false
      public? true
    end

    attribute :title, :string do
      allow_nil? false
      public? true
    end

    attribute :body, :string do
      allow_nil? false
      public? true
    end

    attribute :body_html, :string do
      allow_nil? true
      public? true
    end

    attribute :meta_description, :string do
      allow_nil? true
      public? true
    end

    attribute :published, :boolean do
      allow_nil? false
      default false
      public? true
    end

    attribute :published_at, :utc_datetime_usec do
      allow_nil? true
      public? true
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  identities do
    identity :unique_slug, [:slug]
  end

  actions do
    defaults [:read, :destroy]

    create :draft do
      accept [:slug, :title, :body, :meta_description]

      change set_attribute(:published, false)

      change fn changeset, _context ->
        case Ash.Changeset.get_attribute(changeset, :body) do
          nil ->
            changeset

          body ->
            html = Haul.Content.Markdown.render_html(body)
            Ash.Changeset.force_change_attribute(changeset, :body_html, html)
        end
      end
    end

    update :edit do
      require_atomic? false
      accept [:title, :body, :meta_description]

      change fn changeset, _context ->
        case Ash.Changeset.get_attribute(changeset, :body) do
          nil ->
            changeset

          body ->
            html = Haul.Content.Markdown.render_html(body)
            Ash.Changeset.force_change_attribute(changeset, :body_html, html)
        end
      end
    end

    update :publish do
      change set_attribute(:published, true)
      change set_attribute(:published_at, &DateTime.utc_now/0)
    end

    update :unpublish do
      change set_attribute(:published, false)
    end
  end
end
