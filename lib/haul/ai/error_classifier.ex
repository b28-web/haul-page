defmodule Haul.AI.ErrorClassifier do
  @moduledoc """
  Classifies AI API errors as transient (retriable) or permanent.

  Extracted from ContentGenerator and Extractor to eliminate duplication.
  """

  @doc """
  Returns true if the error is transient and the operation should be retried.

  Transient errors: timeout, rate limiting, connection refused, server errors (5xx).
  """
  @spec transient?({:error, term()}) :: boolean()
  def transient?({:error, :timeout}), do: true
  def transient?({:error, :rate_limited}), do: true
  def transient?({:error, :econnrefused}), do: true
  def transient?({:error, %{status: status}}) when status in [429, 500, 502, 503], do: true
  def transient?(_), do: false
end
