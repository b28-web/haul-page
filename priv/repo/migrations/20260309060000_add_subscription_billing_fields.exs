defmodule Haul.Repo.Migrations.AddSubscriptionBillingFields do
  use Ecto.Migration

  def up do
    # Add stripe_subscription_id column
    alter table(:companies) do
      add :stripe_subscription_id, :text
    end

    # Migrate existing :free plan values to :starter
    execute "UPDATE companies SET subscription_plan = 'starter' WHERE subscription_plan = 'free'"

    # Update default from 'free' to 'starter'
    alter table(:companies) do
      modify :subscription_plan, :text, default: "starter"
    end
  end

  def down do
    # Revert default
    alter table(:companies) do
      modify :subscription_plan, :text, default: "free"
    end

    # Migrate :starter back to :free
    execute "UPDATE companies SET subscription_plan = 'free' WHERE subscription_plan = 'starter'"

    # Remove stripe_subscription_id
    alter table(:companies) do
      remove :stripe_subscription_id
    end
  end
end
