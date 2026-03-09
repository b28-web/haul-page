# Structure — T-003-02 Booking LiveView

## Files to create

### `lib/haul_web/live/booking_live.ex`
Module: `HaulWeb.BookingLive`

```
use HaulWeb, :live_view

mount/3
  - Read operator config (slug, phone, business_name)
  - Derive tenant: "tenant_#{slug}"
  - Build AshPhoenix.Form for Job :create_from_online_booking with tenant
  - Assign: form, submitted (false), phone, business_name

handle_event("validate", %{"form" => params}, socket)
  - AshPhoenix.Form.validate(socket.assigns.form, params)
  - Update form assign

handle_event("submit", %{"form" => params}, socket)
  - AshPhoenix.Form.submit(socket.assigns.form, params: params)
  - Success → assign submitted: true
  - Error → update form assign with errors

render/1 — two states:
  1. submitted == false: booking form
  2. submitted == true: confirmation panel
```

Form layout (when not submitted):
```
<main> min-h-screen bg-background text-foreground
  <section> px-4 py-16 md:py-24 max-w-2xl mx-auto
    heading: "Book a Pickup"
    subheading: "Fill out the form and we'll get back to you"
    <.form for={@form} phx-change="validate" phx-submit="submit">
      <.input field={@form[:customer_name]} label="Your Name" required />
      <.input field={@form[:customer_phone]} type="tel" label="Phone Number" required />
      <.input field={@form[:customer_email]} type="email" label="Email (optional)" />
      <.input field={@form[:address]} label="Pickup Address" required />
      <.input field={@form[:item_description]} type="textarea" label="What do you need picked up?" required />
      3× <.input type="date" /> for preferred_dates[0], [1], [2]
      <button type="submit"> Submit Booking Request
    </.form>
  </section>
</main>
```

Confirmation panel (when submitted):
```
<main> same container
  <section> same padding
    hero-check-circle icon
    "Thank You!" heading
    "We'll contact you shortly..." message
    Operator phone CTA link
    "Submit Another" button (resets form)
  </section>
</main>
```

### `test/haul_web/live/booking_live_test.exs`
Module: `HaulWeb.BookingLiveTest`

```
use HaulWeb.ConnCase, async: false
import Phoenix.LiveViewTest

setup:
  - Create Company via Ash (provisions tenant)
  - Add slug to operator config or ensure it matches
  - Cleanup tenant schemas on_exit

Tests:
  - GET /book renders the booking form
  - Form shows required field labels
  - phx-change validates and shows errors for missing required fields
  - Successful submission shows confirmation message
  - Confirmation shows operator phone
  - "Submit another" resets to form
  - Mobile input types: tel for phone, email for email, date for dates
```

## Files to modify

### `lib/haul_web/router.ex`
Add inside the `scope "/", HaulWeb` block:
```elixir
live "/book", BookingLive
```

### `config/config.exs`
Add `slug` to operator config:
```elixir
config :haul, :operator,
  slug: "junk-and-handy",
  business_name: "Junk & Handy",
  ...
```

### `priv/repo/seeds.exs`
Add Company creation seeding to ensure the tenant exists:
```elixir
alias Haul.Accounts.Company

case Ash.read(Company) do
  {:ok, []} ->
    Company
    |> Ash.Changeset.for_create(:create_company, %{name: operator[:business_name]})
    |> Ash.create!()
    IO.puts("Created default company: #{operator[:business_name]}")
  {:ok, _companies} ->
    IO.puts("Company already exists, skipping seed.")
end
```

## Module boundaries

- `HaulWeb.BookingLive` depends on: `Haul.Operations.Job` (via AshPhoenix.Form), `Haul.Accounts.Changes.ProvisionTenant` (for `tenant_schema/1`)
- No new Ash resources or domain changes
- No changes to Job resource
- Core components (`<.input>`, `<.icon>`) used as-is

## Ordering

1. Config change (add slug) — no deps
2. Seeds update — depends on config
3. Router change — no deps
4. BookingLive module — depends on config + router
5. Tests — depends on all above
