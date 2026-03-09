# Structure — T-002-01 Landing Page Markup

## Files modified

### `config/config.exs`
- Add `:operator` config key under `:haul` app
- Default operator map: `business_name`, `phone`, `email`, `tagline`, `service_area`, `services` list
- Each service: `%{title, description, icon}` — icon is heroicon name string

### `config/runtime.exs`
- Add env var overrides for operator config fields:
  - `OPERATOR_BUSINESS_NAME`, `OPERATOR_PHONE`, `OPERATOR_EMAIL`
  - `OPERATOR_TAGLINE`, `OPERATOR_SERVICE_AREA`
- Services list stays as config default (not env-var configurable — too complex for env vars)

### `lib/haul_web/controllers/page_controller.ex`
- Read operator config from `Application.get_env(:haul, :operator)`
- Pass operator fields as assigns: `business_name`, `phone`, `email`, `tagline`, `service_area`, `services`
- Set `put_layout(conn, false)` to skip `Layouts.app`

### `lib/haul_web/controllers/page_html/home.html.heex`
- Complete replacement of Phoenix boilerplate with landing page markup
- Four sections: Hero, ServicesGrid, WhyUs, FooterCTA
- All content reads from assigns (operator config)
- Responsive Tailwind classes, mobile-first
- Print-specific classes using `print:` variant and `hidden`/`print:flex`

### `assets/css/app.css`
- Add `@media print` block at end:
  - White background, black text
  - Hide screen-only elements (`.no-print`)
  - Tear-off strip styling (vertical text, dashed borders)
  - Page margins and sizing

## Module boundaries

```
PageController.home/2
  ├── reads Application.get_env(:haul, :operator)
  ├── assigns operator fields to conn
  └── renders :home template (no app layout)

PageHTML
  └── home.html.heex
      ├── Section 1: Hero (eyebrow, h1, subtitle, tagline, phone, contact row)
      ├── Section 2: Services Grid (iterates @services)
      ├── Section 3: Why Hire Us (static list)
      └── Section 4: Footer CTA (phone button, print button, tear-off strip)
```

## Template structure (home.html.heex)

```
<main>                              ← full page wrapper, centered
  <section#hero>                    ← py-16 md:py-24, text-center
    <p.eyebrow>                     ← tracking-[0.4em] uppercase text-xs
    <h1>                            ← text-6xl md:text-8xl lg:text-9xl
    <p.subtitle>                    ← text-3xl md:text-4xl text-muted-foreground
    <p.tagline>                     ← text-lg md:text-xl max-w-lg mx-auto
    <div.phone-block>               ← label + tel: link
    <div.contact-row>               ← email + location icons

  <section#services>                ← py-12 md:py-16
    <h2>                            ← text-3xl md:text-4xl
    <div.grid>                      ← grid-cols-2 md:grid-cols-3 gap-6
      <%= for service <- @services %>
        <div.service-card>          ← icon + title + description

  <section#why-us>                  ← py-12 md:py-16
    <h2>
    <div.grid>                      ← grid-cols-1 sm:grid-cols-2
      <p>                           ← "— " prefix per item

  <footer#cta>                      ← py-16 md:py-24, text-center
    <h2>
    <p>
    <a.phone-button>                ← tel: link styled as button
    <button.print-button>           ← onclick=window.print(), hidden without JS, print:hidden
    <div.tear-off>                  ← hidden print:flex, 8 vertical tabs
</main>
```

## Config structure

```elixir
config :haul, :operator,
  business_name: "Junk & Handy",
  phone: "(555) 123-4567",
  email: "hello@junkandhandy.com",
  tagline: "Fast, honest, affordable junk removal and handyman services for homes and businesses.",
  service_area: "Your Area",
  coupon_text: "10% OFF",
  services: [
    %{title: "Junk Removal", description: "Furniture, appliances, debris — hauled away same day.", icon: "hero-truck"},
    %{title: "Cleanouts", description: "Garages, basements, storage units cleared out completely.", icon: "hero-trash"},
    %{title: "Yard Waste", description: "Branches, clippings, dirt — gone before you know it.", icon: "hero-sparkles"},
    %{title: "Repairs", description: "Small fixes, patching, and maintenance around the house.", icon: "hero-wrench"},
    %{title: "Assembly", description: "Furniture, equipment, shelving — built and placed right.", icon: "hero-wrench-screwdriver"},
    %{title: "Moving Help", description: "Loading, unloading, rearranging — extra hands when you need them.", icon: "hero-cube"}
  ]

## No files created from scratch (besides this artifact)

All changes are modifications to existing files. No new modules or directories needed.
```
