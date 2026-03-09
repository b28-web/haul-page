# T-020-02 Progress: Auto-Provision Pipeline

## Completed

### Step 1: Conversation status values + actions
- Added `:provisioning` and `:failed` to status enum in `Conversation`
- Added `:mark_provisioning` and `:mark_failed` update actions

### Step 2: Provisioner module
- Created `lib/haul/ai/provisioner.ex` with `from_profile/2`
- Steps: validate → load conversation → mark provisioning → generate content → onboard → apply content → link conversation
- Error handling: short-circuit, marks conversation as failed
- Timing tracked via `System.monotonic_time`

### Step 3: ProvisionSite Oban worker
- Created `lib/haul/workers/provision_site.ex`
- `enqueue/3` — creates job with serialized profile
- `perform/1` — deserializes, delegates to Provisioner, broadcasts via PubSub
- Profile serialization/deserialization handles structs ↔ string-keyed maps

### Step 4: Provisioner tests
- 7 tests covering: full pipeline, conversation linking, site config updates, service descriptions, validation, failure marking, idempotency

### Step 5: Worker tests
- 3 tests covering: job enqueue, successful perform + PubSub broadcast, failure broadcast

### Step 6: ChatLive integration
- Added `provisioning?` and `provisioned_url` assigns
- PubSub subscription on mount for `"provisioning:#{session_id}"`
- `provision_site` event handler with guards
- `provisioning_complete` and `provisioning_failed` PubSub handlers
- Updated profile panel CTA: "Build my site" button → spinner during provisioning → "View your site" link after success
- Fixed existing test expectation ("Create my site" → "Build my site")

### Step 7: Full test suite
- 634 tests, 0 failures after fixing the CTA text change

## Deviations from Plan
- None significant. Implementation followed the plan closely.
