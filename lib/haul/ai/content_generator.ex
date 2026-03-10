defmodule Haul.AI.ContentGenerator do
  @moduledoc """
  Generates professional website content from an extracted operator profile.

  Wraps BAML generation functions (GenerateServiceDescriptions, GenerateTagline,
  GenerateWhyHireUs, GenerateMetaDescription) with parsing and error handling.
  Uses Claude Haiku for cost efficiency.
  """

  alias Haul.AI.OperatorProfile

  require Logger

  @doc """
  Generates 2-3 sentence descriptions for each service in the profile.

  Returns `{:ok, [%{service_name: String.t(), description: String.t()}]}` on success.
  """
  @spec generate_service_descriptions(OperatorProfile.t()) ::
          {:ok, [%{service_name: String.t(), description: String.t()}]} | {:error, term()}
  def generate_service_descriptions(%OperatorProfile{} = profile) do
    args = %{
      "service_names" => Enum.map(profile.services, & &1.name),
      "business_name" => profile.business_name || "Our Company",
      "service_area" => profile.service_area || "your area",
      "differentiators" => profile.differentiators
    }

    with {:ok, result} <- call_with_retry("GenerateServiceDescriptions", args) do
      descriptions =
        result
        |> List.wrap()
        |> Enum.map(fn desc ->
          %{
            service_name: desc["service_name"],
            description: desc["description"]
          }
        end)

      log_completion("GenerateServiceDescriptions", profile)
      {:ok, descriptions}
    end
  end

  @doc """
  Generates 3 tagline options: short/punchy, benefit-focused, professional.

  Returns `{:ok, [String.t()]}` with exactly 3 options on success.
  """
  @spec generate_taglines(OperatorProfile.t()) :: {:ok, [String.t()]} | {:error, term()}
  def generate_taglines(%OperatorProfile{} = profile) do
    args = %{
      "business_name" => profile.business_name || "Our Company",
      "service_area" => profile.service_area || "your area",
      "services" => Enum.map(profile.services, & &1.name),
      "differentiators" => profile.differentiators
    }

    with {:ok, %{"options" => options}} <- call_with_retry("GenerateTagline", args) do
      log_completion("GenerateTagline", profile)
      {:ok, options}
    end
  end

  @doc """
  Generates 6 "Why hire us" bullet points for the landing page.

  Returns `{:ok, [String.t()]}` with exactly 6 bullets on success.
  """
  @spec generate_why_hire_us(OperatorProfile.t()) :: {:ok, [String.t()]} | {:error, term()}
  def generate_why_hire_us(%OperatorProfile{} = profile) do
    args = %{
      "business_name" => profile.business_name || "Our Company",
      "differentiators" => profile.differentiators,
      "years_in_business" => to_string(profile.years_in_business || "not specified"),
      "service_area" => profile.service_area || "your area"
    }

    with {:ok, %{"bullets" => bullets}} <- call_with_retry("GenerateWhyHireUs", args) do
      log_completion("GenerateWhyHireUs", profile)
      {:ok, bullets}
    end
  end

  @doc """
  Generates an SEO meta description (≤160 characters).

  Returns `{:ok, String.t()}` on success. Truncates to 160 chars if needed.
  """
  @spec generate_meta_description(OperatorProfile.t()) :: {:ok, String.t()} | {:error, term()}
  def generate_meta_description(%OperatorProfile{} = profile) do
    args = %{
      "business_name" => profile.business_name || "Our Company",
      "service_area" => profile.service_area || "your area",
      "services" => Enum.map(profile.services, & &1.name)
    }

    with {:ok, %{"description" => description}} <-
           call_with_retry("GenerateMetaDescription", args) do
      truncated =
        if String.length(description) > 160 do
          String.slice(description, 0, 157) <> "..."
        else
          description
        end

      log_completion("GenerateMetaDescription", profile)
      {:ok, truncated}
    end
  end

  @doc """
  Generates all content at once: service descriptions, taglines, why-hire-us bullets,
  and meta description.

  Returns `{:ok, map}` with keys `:service_descriptions`, `:taglines`, `:why_hire_us`,
  `:meta_description`. Fails fast on the first error.
  """
  @spec generate_all(OperatorProfile.t()) :: {:ok, map()} | {:error, term()}
  def generate_all(%OperatorProfile{} = profile) do
    with {:ok, descriptions} <- generate_service_descriptions(profile),
         {:ok, taglines} <- generate_taglines(profile),
         {:ok, bullets} <- generate_why_hire_us(profile),
         {:ok, meta} <- generate_meta_description(profile) do
      {:ok,
       %{
         service_descriptions: descriptions,
         taglines: taglines,
         why_hire_us: bullets,
         meta_description: meta
       }}
    end
  end

  # --- Private ---

  defp call_with_retry(function_name, args) do
    case Haul.AI.call_function(function_name, args) do
      {:ok, _result} = success ->
        success

      {:error, _reason} = error ->
        if Haul.AI.ErrorClassifier.transient?(error) do
          Haul.AI.call_function(function_name, args)
        else
          error
        end
    end
  end

  defp log_completion(function_name, profile) do
    Logger.info(
      "[ContentGenerator] #{function_name} completed (profile: #{inspect(profile.business_name)})"
    )
  end
end
