defmodule Haul.AI.EditClassifier do
  @moduledoc """
  Classifies chat messages as edit instructions for post-provisioning edits.
  Pure pattern matching — no LLM calls, no side effects.
  """

  @type edit_instruction ::
          {:direct, atom(), String.t()}
          | {:regenerate, atom(), String.t()}
          | {:remove_service, String.t()}
          | {:add_service, String.t()}
          | {:unknown, String.t()}

  @phone_pattern ~r/(?:phone|number|call).*?((?:\(?\d{3}\)?[\s.-]?)?\d{3}[\s.-]?\d{4})/i
  @email_pattern ~r/(?:email|e-mail).*?([\w.+-]+@[\w.-]+\.\w+)/i
  @business_name_pattern ~r/(?:business|company)\s+name.*?(?:is|to|should\s+be|be)\s+["']?(.+?)["']?\s*$/i
  @service_area_pattern ~r/(?:service\s+area|area|location|city).*?(?:is|to|should\s+be|be)\s+["']?(.+?)["']?\s*$/i
  @owner_name_pattern ~r/(?:owner|my)\s+name.*?(?:is|to|should\s+be|be)\s+["']?(.+?)["']?\s*$/i
  @remove_service_pattern ~r/remove\s+(?:the\s+)?["']?(.+?)["']?\s*(?:service)?\s*$/i
  @add_service_pattern ~r/add\s+(?:a\s+)?(?:the\s+)?["']?(.+?)["']?\s*(?:service)?\s*$/i
  @tagline_pattern ~r/(?:tagline|slogan|motto|headline)/i
  @description_pattern ~r/(?:description|describe|rewrite)/i

  @doc """
  Classifies a user message into an edit instruction.

  Returns one of:
  - `{:direct, field, value}` — update a field directly
  - `{:regenerate, target, hint}` — regenerate content with LLM
  - `{:remove_service, name}` — remove a service
  - `{:add_service, name}` — add a service
  - `{:unknown, message}` — could not classify
  """
  @spec classify(String.t()) :: edit_instruction()
  def classify(message) when is_binary(message) do
    message = String.trim(message)

    cond do
      match = Regex.run(@phone_pattern, message) ->
        {:direct, :phone, Enum.at(match, 1)}

      match = Regex.run(@email_pattern, message) ->
        {:direct, :email, Enum.at(match, 1)}

      match = Regex.run(@business_name_pattern, message) ->
        {:direct, :business_name, String.trim(Enum.at(match, 1))}

      match = Regex.run(@owner_name_pattern, message) ->
        {:direct, :owner_name, String.trim(Enum.at(match, 1))}

      match = Regex.run(@service_area_pattern, message) ->
        {:direct, :service_area, String.trim(Enum.at(match, 1))}

      match = Regex.run(@remove_service_pattern, message) ->
        {:remove_service, String.trim(Enum.at(match, 1))}

      match = Regex.run(@add_service_pattern, message) ->
        {:add_service, String.trim(Enum.at(match, 1))}

      Regex.match?(@tagline_pattern, message) ->
        {:regenerate, :tagline, message}

      Regex.match?(@description_pattern, message) ->
        {:regenerate, :descriptions, message}

      true ->
        {:unknown, message}
    end
  end
end
