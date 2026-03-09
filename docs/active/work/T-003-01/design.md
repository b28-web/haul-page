# T-003-01 Design: Job Resource

## Decision 1: Domain placement

**Chosen:** `Haul.Operations` domain at `lib/haul/operations.ex`.

The spec defines `lib/haul/operations/` as the home for Job, Quote, QuoteLineItem, Truck. Job is the first resource in this domain. Creating the domain now establishes the namespace for future tickets (T-003-02 quote, T-003-03 booking form).

**Rejected:** Putting Job in `Haul.Accounts` — wrong bounded context. Jobs are operational, not account management.

## Decision 2: State machine states

**Chosen:** Define the full state list up front but only implement `:lead` transitions.

States: `:lead`, `:quoted`, `:scheduled`, `:en_route`, `:in_progress`, `:completed`, `:invoiced`, `:paid`, `:cancelled`.

Only `:lead` is an `initial_state`. Other states exist in the `state_machine` block so AshStateMachine knows the valid state space, but no transitions are defined yet (per acceptance criteria: "other states defined but transitions not yet implemented beyond :lead").

**Rejected:** Only defining `:lead` — would require schema migrations when adding states later. AshStateMachine stores state as a string column, so defining all states now has no migration cost.

## Decision 3: `preferred_dates` type

**Chosen:** `{:array, :date}` — a list of dates.

The booking form asks for "preferred dates" (plural). A list of Date values is the simplest representation. The customer picks 1-3 preferred dates, stored as a Postgres date array.

**Rejected alternatives:**
- Single `:date` — doesn't capture multiple preferences
- JSON/map with date ranges — over-engineered for "pick some dates"
- `:string` free text — loses type safety, can't sort/filter

## Decision 4: Multi-tenancy

**Chosen:** Tenant-scoped via `:context` strategy, same as User.

Job belongs to a company's operational context. Schema isolation ensures one operator never sees another's jobs. Migration goes to `priv/repo/tenant_migrations/`.

No alternative considered — this is the established pattern.

## Decision 5: Action design

**Chosen:** Single create action `:create_from_online_booking`.

Accepts: customer_name, customer_phone, customer_email, address, item_description, preferred_dates. State is set automatically to `:lead` by AshStateMachine's `default_initial_state`.

No read/update/destroy actions beyond defaults needed for T-003-01. The `:read` default is useful for IEx verification. Future tickets add transition actions (`:send_quote`, `:schedule_job`, etc.).

## Decision 6: Policies

**Chosen:** No policies for T-003-01.

The acceptance criteria only require the resource to compile and the action to be callable from IEx. Policy enforcement (who can create/read jobs) belongs to a later ticket when the operator app exists. Adding authorize?: false in domain config or skipping policies keeps this simple.

**Rejected:** Adding owner/crew policies now — no auth integration exists yet for the operator app, and the booking form will need a public-facing action anyway.

## Decision 7: customer_email optionality

**Chosen:** `allow_nil? true` for customer_email, `allow_nil? false` for customer_name and customer_phone.

Walk-up customers or phone leads may not provide email. Name and phone are the minimum needed to contact a lead. Address and item_description are required for operational value.

## Decision 8: Notes field

**Chosen:** Add an optional `notes` text field.

Not in the acceptance criteria but trivially useful — the booking form or operator may want to attach free-text notes. Zero cost to add now, avoids a migration later.

**This is the only addition beyond acceptance criteria.** Everything else is minimal.
