# Content System Design

How we handle structured content, rich text, images, and operator-editable data. Designed to match the ergonomics of Astro's content collections while staying inside the Ash/Phoenix stack.

## Astro → Ash mapping

| Astro concept | Ash equivalent | Notes |
|---------------|---------------|-------|
| `defineCollection({ schema })` | Ash resource definition | Stronger — compile-time validated, not runtime Zod |
| `z.object({ title: z.string() })` | `attribute :title, :string, allow_nil?: false` | Ash attributes + validations |
| `reference('authors')` | `belongs_to :author, Author` | First-class relationships with policies |
| `getCollection('blog')` | `Ash.read!(BlogPost)` | Returns typed structs, not untyped maps |
| `getCollection('blog', filter)` | `Ash.read!(BlogPost, filter: [...])` | Ash.Query with compile-time checked filters |
| `getEntry('blog', id)` | `Ash.get!(BlogPost, id)` | Raises on missing, or `Ash.get` for nil |
| `entry.render()` | `MDEx.to_html!(entry.body)` | Or `to_heex/2` for LiveView component injection |
| `glob('src/content/blog/*.md')` | `priv/content/blog/*.md` → seed task | Files seed into DB; DB is the runtime source of truth |
| `content.config.ts` | `lib/haul/content.ex` (Ash domain) | Single file declaring all content resources |
| Zod → TypeScript types | Ash resource → typed Elixir structs | Pattern matching on structs, dialyzer checks |
| `.astro/collections/*.schema.json` | Ash introspection API | Resources are introspectable at compile and runtime |

### Where Ash is stronger than Astro

- **Authorization built in.** Every content query passes through `Ash.Policy.Authorizer`. Crew can't see pricing config. Operators can't see other operators' content. This is free — no middleware to write.
- **Mutations are first-class.** Astro content collections are read-only. Ash resources have named create/update/destroy actions with validations, policies, and side effects (notifications via AshOban).
- **Audit trail.** AshPaperTrail tracks every content mutation. Who changed the tagline, when, what it was before. Free with one extension line.
- **Real-time.** Content changes broadcast via `Ash.Notifier` → PubSub → LiveView. Update a gallery item in the admin, it appears on the scan page immediately. No rebuild, no cache invalidation.

### Where Astro is stronger (and how we close the gap)

- **File-based authoring.** Astro content lives as markdown files, version-controlled and PR-reviewable. We close this with a seed workflow — `priv/content/` files seed into DB for dev/staging.
- **Markdown-first.** Astro renders `.md`/`.mdx` files natively. We use MDEx with `to_heex/2` for the same capability — markdown content can embed Phoenix components.
- **Zero-config image optimization.** Astro's `image()` helper validates and optimizes at build time. We handle this at upload time — resize/compress on write to Tigris, serve variants via URL params.

---

## Content domain

```elixir
defmodule Haul.Content do
  use Ash.Domain

  resources do
    resource Haul.Content.SiteConfig
    resource Haul.Content.Service
    resource Haul.Content.GalleryItem
    resource Haul.Content.Endorsement
    resource Haul.Content.Page
  end
end
```

### SiteConfig (singleton per tenant)

The equivalent of Astro's `site` config + operator identity. One record per tenant.

```elixir
defmodule Haul.Content.SiteConfig do
  use Ash.Resource,
    domain: Haul.Content,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshPaperTrail.Resource]

  attributes do
    uuid_v7_primary_key :id
    attribute :business_name, :string, allow_nil?: false
    attribute :phone, :string, allow_nil?: false
    attribute :email, :string
    attribute :tagline, :string
    attribute :service_area, :string
    attribute :address, :string
    attribute :coupon_text, :string, default: "10% OFF"
    attribute :meta_description, :string       # SEO
    attribute :primary_color, :string, default: "#0f0f0f"
    attribute :logo_url, :string               # S3 key
  end

  actions do
    defaults [:read]

    update :edit do
      accept [
        :business_name, :phone, :email, :tagline,
        :service_area, :address, :coupon_text,
        :meta_description, :primary_color, :logo_url
      ]
    end
  end

  # Singleton pattern — one per tenant
  code_interface do
    define :current, action: :read  # always returns one record
    define :edit, action: :edit
  end
end
```

Runtime config (env vars) seeds this on first boot. After that, operator edits via admin UI write to this resource. The landing page reads from it.

### Service (collection)

```elixir
defmodule Haul.Content.Service do
  use Ash.Resource,
    domain: Haul.Content,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_v7_primary_key :id
    attribute :title, :string, allow_nil?: false
    attribute :description, :string, allow_nil?: false
    attribute :icon, :string, allow_nil?: false  # icon name: "truck", "wrench", etc.
    attribute :sort_order, :integer, default: 0
    attribute :active, :boolean, default: true
  end

  actions do
    defaults [:read, :destroy]
    create :add, accept: [:title, :description, :icon, :sort_order]
    update :edit, accept: [:title, :description, :icon, :sort_order, :active]
  end

  preparations do
    prepare build(sort: :sort_order)
    prepare build(filter: expr(active == true)), on: :read
  end
end
```

Equivalent to Astro's `getCollection('services')` → `Ash.read!(Service)`. Pre-sorted, pre-filtered to active-only on read.

### GalleryItem (collection with images)

```elixir
defmodule Haul.Content.GalleryItem do
  use Ash.Resource,
    domain: Haul.Content,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_v7_primary_key :id
    attribute :before_image_url, :string, allow_nil?: false   # S3 key
    attribute :after_image_url, :string, allow_nil?: false    # S3 key
    attribute :caption, :string
    attribute :alt_text, :string                               # accessibility
    attribute :sort_order, :integer, default: 0
    attribute :featured, :boolean, default: false              # shown on scan page hero
    attribute :active, :boolean, default: true
  end

  actions do
    defaults [:read, :destroy]
    create :add, accept: [:before_image_url, :after_image_url, :caption, :alt_text, :sort_order, :featured]
    update :edit, accept: [:caption, :alt_text, :sort_order, :featured, :active]
  end
end
```

### Endorsement (collection with references)

```elixir
defmodule Haul.Content.Endorsement do
  use Ash.Resource,
    domain: Haul.Content,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_v7_primary_key :id
    attribute :customer_name, :string, allow_nil?: false
    attribute :quote_text, :string, allow_nil?: false         # plain text or markdown
    attribute :star_rating, :integer, constraints: [min: 1, max: 5]
    attribute :source, :atom, constraints: [one_of: [:google, :yelp, :direct, :facebook]]
    attribute :date, :date
    attribute :featured, :boolean, default: false
    attribute :active, :boolean, default: true
  end

  # Optional: link to the Job that generated this review
  relationships do
    belongs_to :job, Haul.Operations.Job do
      allow_nil? true
    end
  end
end
```

The `belongs_to :job` is the Ash equivalent of Astro's `reference('jobs')` — a typed, validated cross-collection link. When an endorsement came from a completed job, you can trace it back.

### Page (rich content — the markdown collection)

This is the Astro-equivalent "blog post" or "rich page" pattern — structured frontmatter + markdown body.

```elixir
defmodule Haul.Content.Page do
  use Ash.Resource,
    domain: Haul.Content,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshPaperTrail.Resource]

  attributes do
    uuid_v7_primary_key :id
    attribute :slug, :string, allow_nil?: false    # URL path segment
    attribute :title, :string, allow_nil?: false
    attribute :body, :string, allow_nil?: false     # markdown source
    attribute :body_html, :string                   # cached rendered HTML
    attribute :meta_description, :string
    attribute :published, :boolean, default: false
    attribute :published_at, :utc_datetime_usec
  end

  identities do
    identity :unique_slug, [:slug]
  end

  actions do
    defaults [:read, :destroy]

    create :draft do
      accept [:slug, :title, :body, :meta_description]
      change set_attribute(:published, false)
    end

    update :edit do
      accept [:title, :body, :meta_description]
      # Re-render markdown to HTML on every edit
      change fn changeset, _context ->
        case Ash.Changeset.get_attribute(changeset, :body) do
          nil -> changeset
          body ->
            {:ok, html} = MDEx.to_html(body, extension: [table: true, footnotes: true, strikethrough: true])
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
```

The `body` field stores markdown. The `body_html` field caches the rendered HTML, re-generated on every `:edit` action. This is the key pattern: **markdown is the authoring format, HTML is the delivery format, and the rendering happens at write time — not read time.**

For LiveView pages that need component injection (e.g., embedding a booking CTA inside a content page), use `MDEx.to_heex/2` at render time instead of the cached HTML.

---

## Markdown rendering pipeline

### Write-time rendering (default)

```
Author writes markdown
  → :edit action fires
  → Change function calls MDEx.to_html/2
  → body_html column updated
  → Template reads body_html (fast, no parsing at request time)
```

Good for: static content pages, endorsement quotes, service descriptions. Rendering happens once on save, served from cache on every read.

### Read-time rendering (LiveView component injection)

```
Template calls MDEx.to_heex/2 on body
  → MDEx parses markdown + embeds Phoenix components
  → LiveView renders the result with component lifecycle
```

Good for: pages that embed interactive components (booking CTAs, live gallery, forms). Uses MDEx's `phoenix_heex` extension:

```elixir
# In a LiveView template
<%= MDEx.to_heex(@page.body,
  extension: [phoenix_heex: true],
  plugins: [MDEx.GFM]
) %>
```

This lets content authors write:

```markdown
## Ready to book?

We're available for same-day pickups in the greater Seattle area.

<.booking_cta phone={@site_config.phone} />
```

And the `<.booking_cta>` component renders as a real Phoenix function component inside the markdown output. This is the MDX equivalent.

### Which path to use

| Content type | Rendering | Why |
|-------------|-----------|-----|
| Service descriptions | Write-time (`body_html`) | Static text, no components |
| Endorsement quotes | Write-time | Plain text, no markdown needed |
| Content pages | Write-time with fallback | Mostly static; use read-time only if components are embedded |
| Scan page body | Read-time (`to_heex`) | May embed booking CTA, gallery component |

---

## Image pipeline

### Upload flow

```
Operator uploads image via admin UI
  → LiveView allow_upload validates type + size
  → On save: upload to Tigris (S3-compatible)
  → Store S3 key + metadata on the resource
  → Optional: generate thumbnail variant on upload (via Image/Vix library)
```

### Image metadata type

```elixir
defmodule Haul.Content.ImageMeta do
  use Ash.Type.NewType, subtype_of: :map, constraints: [
    fields: [
      url: [type: :string, allow_nil?: false],
      alt: [type: :string],
      width: [type: :integer],
      height: [type: :integer],
      thumb_url: [type: :string]
    ]
  ]
end
```

This is the equivalent of Astro's `image()` schema helper — a structured type that validates image metadata at the resource level.

### Serving

Images served directly from Tigris CDN URL. No Phoenix proxy. For galleries with many images, the scan page lazy-loads below the fold with `loading="lazy"` on `<img>` tags.

---

## Seed-from-files workflow

The bridge between "developer authors in files" and "operator edits via admin UI."

### Seed directory structure

```
priv/content/
├── site_config.yml           # singleton operator config
├── services/
│   ├── junk-removal.yml
│   ├── cleanouts.yml
│   └── yard-waste.yml
├── gallery/
│   ├── job-1.yml             # references images in priv/static/images/
│   └── job-2.yml
├── endorsements/
│   ├── review-1.yml
│   └── review-2.yml
└── pages/
    ├── about.md              # frontmatter + markdown body
    └── faq.md
```

### File format (structured collections)

```yaml
# priv/content/services/junk-removal.yml
title: "Junk Removal"
description: "Furniture, appliances, debris — hauled away same day."
icon: "truck"
sort_order: 1
```

### File format (rich content pages)

```markdown
---
slug: about
title: About Us
meta_description: Learn about our junk removal services
published: true
---

We started hauling junk in 2019 with one truck and a lot of hustle.

## Our promise

Every job gets the same treatment: show up on time, do the work right,
clean up before we leave.

<.booking_cta />
```

Frontmatter is YAML (parsed by `YamlElixir`). Body is everything after the `---` delimiter. This is identical to Astro's content file format.

### Seed task

```elixir
defmodule Mix.Tasks.Haul.SeedContent do
  use Mix.Task

  def run(_args) do
    Mix.Task.run("app.start")

    # Structured collections: read YAML, upsert via Ash actions
    seed_collection("services", Haul.Content.Service, :add)
    seed_collection("endorsements", Haul.Content.Endorsement, :add)
    seed_collection("gallery", Haul.Content.GalleryItem, :add)

    # Rich pages: parse frontmatter + body, upsert
    seed_pages()

    # Singleton: merge with env var defaults
    seed_site_config()
  end
end
```

`mix haul.seed_content` is idempotent — upserts by slug/title. Run in dev seeds, CI fixtures, and first-deploy setup. After first deploy, the DB is the source of truth and the operator edits via admin UI.

---

## Admin UI approach

Content editing lives at `/app/content` behind operator auth. Each collection gets a list + edit view built with `AshPhoenix.Form`.

```
/app/content                    # Dashboard — all collections
/app/content/site               # Edit SiteConfig (singleton form)
/app/content/services           # List + reorder services
/app/content/services/:id/edit  # Edit one service
/app/content/gallery            # Grid of before/after pairs
/app/content/gallery/new        # Upload new pair
/app/content/endorsements       # List endorsements
/app/content/pages              # List pages
/app/content/pages/:id/edit     # Markdown editor for page body
```

The markdown editor for Pages is a `<textarea>` with live preview — not a WYSIWYG. Content authors write markdown, see rendered output in a split pane. This matches the Astro philosophy: markdown is the format, not a hidden implementation detail.

### AshPhoenix.Form integration

```elixir
# In a LiveView
def mount(%{"id" => id}, _session, socket) do
  service = Ash.get!(Haul.Content.Service, id)
  form = AshPhoenix.Form.for_update(service, :edit)
  {:ok, assign(socket, form: form)}
end
```

AshPhoenix.Form generates form fields from the Ash resource definition — validations, types, constraints all carry through. This is the payoff of schema-driven content: the admin form validates the same rules as the seed files and the API.

---

## Query patterns (the API surface)

Templates and LiveViews query content through Ash's standard interface. These are the equivalents of Astro's `getCollection()` and `getEntry()`.

```elixir
# Landing page controller — equivalent to getCollection('services')
services = Ash.read!(Haul.Content.Service)
# Returns sorted, active-only (via preparations on the resource)

# Scan page LiveView — equivalent to getCollection('gallery', featured)
gallery = Ash.read!(Haul.Content.GalleryItem,
  filter: [featured: true],
  sort: :sort_order
)

# Endorsements with star ratings
endorsements = Ash.read!(Haul.Content.Endorsement,
  filter: [active: true, star_rating: [greater_than: 3]],
  sort: [star_rating: :desc]
)

# Single page by slug — equivalent to getEntry('pages', 'about')
page = Ash.get!(Haul.Content.Page, slug: "about")

# SiteConfig singleton
config = Ash.read_one!(Haul.Content.SiteConfig)
```

### In templates

```heex
<%# Landing page — services grid %>
<section>
  <h2>What We Do</h2>
  <div class="grid grid-cols-2 md:grid-cols-3 gap-6">
    <%= for service <- @services do %>
      <.service_card
        title={service.title}
        description={service.description}
        icon={service.icon}
      />
    <% end %>
  </div>
</section>

<%# Rich page — rendered markdown %>
<article>
  <h1><%= @page.title %></h1>
  <%= raw(@page.body_html) %>
</article>
```

---

## Migration path

### Phase 1 (now): Seed files + env vars
- Content defined in `priv/content/*.yml` and `priv/content/pages/*.md`
- SiteConfig seeded from env vars on first boot
- No admin UI — developer edits files, redeploys
- Templates read from Ash resources (DB), seeded from files

### Phase 2 (with operator app): Admin UI
- Add LiveView forms at `/app/content`
- Operator can edit all content via browser
- Seed files become dev/test fixtures only
- DB is sole source of truth in production

### Phase 3 (optional): Content API
- AshJsonApi or AshGraphql exposes content read-only
- Enables future headless use cases (native app, external widget)
- Content still authored via admin UI or Ash actions

This is the same trajectory as Astro's evolution from file-based to Astro DB — start with files, graduate to a database, keep the same query API throughout. The difference is we're database-backed from day one (Ash resources), with files as a seeding mechanism rather than the runtime source.
