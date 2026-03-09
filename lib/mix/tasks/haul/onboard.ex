defmodule Mix.Tasks.Haul.Onboard do
  @shortdoc "Provision a new operator tenant"
  @moduledoc """
  Provisions a new operator tenant on the shared multi-tenant instance.

  Creates company, provisions tenant schema, seeds default content,
  and creates an owner user.

  ## Interactive mode

      mix haul.onboard

  Prompts for: business name, phone, email, service area.

  ## Non-interactive mode

      mix haul.onboard --name "Joe's Hauling" --phone 555-1234 --email joe@ex.com --area "Seattle, WA"

  ## Idempotent

  Re-running for an existing slug updates content instead of duplicating.
  """
  use Mix.Task

  @requirements ["app.start"]

  @impl Mix.Task
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [name: :string, phone: :string, email: :string, area: :string]
      )

    params =
      if opts[:name] do
        non_interactive(opts)
      else
        interactive(opts)
      end

    case Haul.Onboarding.run(params) do
      {:ok, result} ->
        print_success(result)

      {:error, step, reason} ->
        Mix.shell().error("Onboarding failed at #{step}: #{inspect(reason)}")
        exit({:shutdown, 1})
    end
  end

  defp non_interactive(opts) do
    unless opts[:name], do: Mix.raise("--name is required")
    unless opts[:email], do: Mix.raise("--email is required")

    %{
      name: opts[:name],
      phone: opts[:phone] || "",
      email: opts[:email],
      area: opts[:area] || ""
    }
  end

  defp interactive(opts) do
    shell = Mix.shell()

    name = opts[:name] || prompt_required(shell, "Business name")
    phone = opts[:phone] || shell.prompt("Phone number:") |> String.trim()
    email = opts[:email] || prompt_required(shell, "Email")
    area = opts[:area] || shell.prompt("Service area:") |> String.trim()

    %{name: name, phone: phone, email: email, area: area}
  end

  defp prompt_required(shell, label) do
    value = shell.prompt("#{label}:") |> String.trim()

    if value == "" do
      shell.error("#{label} is required.")
      prompt_required(shell, label)
    else
      value
    end
  end

  defp print_success(result) do
    shell = Mix.shell()
    company = result.company
    verb = if result.existing_company, do: "updated", else: "created"

    shell.info("Company #{verb}: \"#{company.name}\" (#{company.slug})")
    shell.info("Tenant schema: #{result.tenant}")

    content = result.content
    services = length(content.services)
    gallery = length(content.gallery_items)
    endorsements = length(content.endorsements)
    pages = length(content.pages)

    shell.info(
      "Content seeded: #{services} services, #{gallery} gallery items, #{endorsements} endorsements, #{pages} pages"
    )

    shell.info("Owner user: #{result.user.email}")
    shell.info("")
    shell.info("Site live at #{Haul.Onboarding.site_url(company.slug)}")
  end
end
