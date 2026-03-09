defmodule Haul.AI.Extractor do
  @moduledoc """
  Extracts a typed OperatorProfile from a conversation transcript using BAML.

  Wraps `Haul.AI.call_function/2` with parsing, error handling, and retry logic.
  """

  alias Haul.AI.OperatorProfile
  alias Haul.AI.ProfileMapper

  @doc """
  Extracts an OperatorProfile from a conversation transcript string.

  Returns `{:ok, %OperatorProfile{}}` on success or `{:error, reason}` on failure.
  Retries once on transient errors (timeout, rate limit, server errors).
  """
  @spec extract_profile(String.t()) :: {:ok, OperatorProfile.t()} | {:error, term()}
  def extract_profile(transcript) when is_binary(transcript) do
    case do_extract(transcript) do
      {:ok, _profile} = success ->
        success

      {:error, _reason} = error ->
        if transient?(error) do
          do_extract(transcript)
        else
          error
        end
    end
  end

  @doc """
  Returns a list of fields still needed for a complete operator profile.

  Checks required fields (business_name, phone, email, service_area) and
  whether at least one service is defined. Used to drive "we still need..."
  UI feedback during onboarding.
  """
  @spec validate_completeness(OperatorProfile.t()) :: [atom()]
  def validate_completeness(%OperatorProfile{} = profile) do
    missing = ProfileMapper.missing_fields(profile)
    missing = if is_nil(profile.service_area), do: [:service_area | missing], else: missing
    missing = if profile.services == [], do: [:services | missing], else: missing
    missing
  end

  @email_pattern ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/

  @doc """
  Checks whether the given string looks like a valid email address.
  Returns `false` for nil.
  """
  @spec valid_email?(String.t() | nil) :: boolean()
  def valid_email?(nil), do: false
  def valid_email?(email) when is_binary(email), do: Regex.match?(@email_pattern, email)

  defp do_extract(transcript) do
    case Haul.AI.call_function("ExtractOperatorProfile", %{"transcript" => transcript}) do
      {:ok, result} when is_map(result) ->
        {:ok, OperatorProfile.from_baml(result)}

      {:error, _reason} = error ->
        error
    end
  end

  defp transient?({:error, :timeout}), do: true
  defp transient?({:error, :rate_limited}), do: true
  defp transient?({:error, :econnrefused}), do: true
  defp transient?({:error, %{status: status}}) when status in [429, 500, 502, 503], do: true
  defp transient?(_), do: false
end
