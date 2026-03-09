# T-020-02 Plan: Auto-Provision Pipeline

## Step 1: Add Conversation status values + actions

Modify `lib/haul/ai/conversation.ex`:
- Add `:provisioning` and `:failed` to status attribute's constraints
- Add `:mark_provisioning` update action (sets status to :provisioning)
- Add `:mark_failed` update action (sets status to :failed)

Verify: existing tests still pass.

## Step 2: Create Provisioner module

Create `lib/haul/ai/provisioner.ex` with:
- `from_profile/2` — main orchestration function
- `validate_profile/1` — check business_name, phone, email present
- `generate_content/1` — delegate to ContentGenerator.generate_all/1
- `onboard_from_profile/1` — map profile to Onboarding.run args
- `apply_generated_content/3` — update SiteConfig + Services with generated content
- `link_conversation/2` — link conversation to company via Ash action

Steps in from_profile/2:
1. Load conversation by ID
2. Validate profile
3. Mark conversation as :provisioning
4. Generate content
5. Run onboarding
6. Apply generated content to tenant
7. Link conversation to company
8. Return {:ok, result} with timing

Error handling: short-circuit on first error, log step + reason.

## Step 3: Create ProvisionSite Oban worker

Create `lib/haul/workers/provision_site.ex`:
- `enqueue/2` — creates job with conversation_id + serialized profile
- `perform/1` — deserializes profile, calls Provisioner, broadcasts result
- PubSub broadcast on success: `{:provisioning_complete, result}`
- PubSub broadcast on failure: `{:provisioning_failed, reason}`
- Topic: `"provisioning:#{session_id}"`

## Step 4: Write Provisioner tests

Create `test/haul/ai/provisioner_test.exs`:
- Test: validates missing required fields
- Test: full pipeline succeeds with sandbox adapter
- Test: returns company, site_url, tenant in result
- Test: conversation linked to company on success
- Test: conversation marked failed on error
- Test: idempotent — running twice doesn't crash

Setup: create conversation with extracted_profile, use sandbox AI adapter.

## Step 5: Write ProvisionSite worker tests

Create `test/haul/workers/provision_site_test.exs`:
- Test: enqueue creates Oban job with correct args
- Test: perform calls Provisioner and broadcasts success
- Test: perform broadcasts failure on error
- Test: PubSub message received by subscriber

## Step 6: Integrate ChatLive

Modify `lib/haul_web/live/chat_live.ex`:
- Add `provisioning?` assign (default false)
- Subscribe to PubSub topic on mount
- Handle "provision_site" event:
  - Guard: profile_complete? and not provisioning?
  - Set provisioning? = true
  - Enqueue ProvisionSite worker
  - Add system message "Building your site..."
- Handle {:provisioning_complete, result}:
  - Add success message with site URL
  - Set provisioning? = false
- Handle {:provisioning_failed, reason}:
  - Add error message
  - Set provisioning? = false
- Update profile panel CTA button

## Step 7: Run full test suite

Run `mix test` to verify no regressions.
Fix any failures.

## Testing Strategy

| Component | Test Type | Key Assertions |
|-----------|-----------|----------------|
| Provisioner.from_profile/2 | Unit | Returns {:ok, result} with company + URL |
| Provisioner validation | Unit | Rejects incomplete profiles |
| Provisioner content overlay | Unit | SiteConfig + Services updated |
| ProvisionSite worker | Unit | Enqueue + perform + PubSub |
| ChatLive provisioning | LiveView | Event → assign changes + messages |
| Conversation status | Unit | New statuses work in transitions |
