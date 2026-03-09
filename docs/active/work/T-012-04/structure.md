# T-012-04 Structure: Tenant Isolation Tests

## Files

### Created
- `test/haul/tenant_isolation_test.exs` — main test module

### Modified
- None. No production code changes needed.

## Module Layout

```
Haul.TenantIsolationTest
  use Haul.DataCase, async: false

  # Aliases
  alias Haul.Accounts.{Company, User, Changes.ProvisionTenant}
  alias Haul.Operations.Job
  alias Haul.Content.{SiteConfig, Service, GalleryItem, Endorsement}

  # Private helpers
  defp create_tenant(name)        # creates company + returns {company, tenant}
  defp register_owner(tenant)     # registers user with owner role
  defp create_job(tenant, attrs)  # creates job via online booking action
  defp create_site_config(tenant) # creates site config
  defp create_service(tenant, t)  # creates service
  defp create_gallery_item(tenant)# creates gallery item
  defp create_endorsement(tenant) # creates endorsement

  setup do
    # Provision tenants A and B
    # Seed data in each
    # on_exit cleanup
    # Return context map
  end

  describe "job isolation" do
    test "query jobs as tenant A returns only A's jobs"
    test "query jobs as tenant B returns only B's jobs"
    test "job created in tenant A is not visible in tenant B"
  end

  describe "content isolation" do
    test "SiteConfig is scoped to tenant"
    test "Services are scoped to tenant"
    test "GalleryItems are scoped to tenant"
    test "Endorsements are scoped to tenant"
  end

  describe "authentication boundary" do
    test "user in tenant A cannot authenticate into tenant B"
  end

  describe "missing tenant context" do
    test "action without tenant context is rejected"
  end

  describe "defense in depth" do
    test "direct Ecto query with wrong schema prefix returns empty"
  end
```

## Dependencies
- No new deps. Uses existing test support infrastructure.
- Depends on T-012-02 (tenant hook) being done — already satisfied per DAG.
