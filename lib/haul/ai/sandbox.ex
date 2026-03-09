defmodule Haul.AI.Sandbox do
  @moduledoc """
  Sandbox AI adapter for dev/test. Returns fixture responses without calling any LLM.

  Supports per-process fixture overrides via `set_response/2` for test isolation.
  """

  @behaviour Haul.AI

  @doc """
  Override the response for a given function name in the current test process.
  The override is automatically cleaned up when the process exits.
  """
  def set_response(function_name, response) do
    Process.put({__MODULE__, function_name}, response)
    :ok
  end

  @impl true
  def call_function(function_name, args) do
    case Process.get({__MODULE__, function_name}) do
      nil -> default_response(function_name, args)
      response -> response
    end
  end

  defp default_response("ExtractName", _args) do
    {:ok, %{"first_name" => "John", "last_name" => "Doe"}}
  end

  defp default_response("ExtractOperatorProfile", _args) do
    {:ok,
     %{
       "business_name" => "Junk & Handy",
       "owner_name" => "Mike Johnson",
       "phone" => "(555) 123-4567",
       "email" => "mike@junkandhandy.com",
       "service_area" => "Portland Metro Area",
       "tagline" => "We haul it all!",
       "years_in_business" => 8,
       "services" => [
         %{
           "name" => "Junk Removal",
           "description" => "Full-service junk removal for homes and businesses",
           "category" => "JUNK_REMOVAL"
         },
         %{
           "name" => "Yard Waste",
           "description" => "Branches, leaves, and green waste hauling",
           "category" => "YARD_WASTE"
         },
         %{
           "name" => "Garage Cleanouts",
           "description" => "Complete garage and storage cleanout services",
           "category" => "CLEANOUTS"
         }
       ],
       "differentiators" => [
         "Same-day service available",
         "Eco-friendly disposal — we recycle 80% of what we haul",
         "Licensed and insured"
       ]
     }}
  end

  defp default_response("GenerateServiceDescriptions", args) do
    names = args["service_names"] || ["Junk Removal", "Yard Waste", "Garage Cleanouts"]

    descriptions =
      Enum.map(names, fn name ->
        %{
          "service_name" => name,
          "description" =>
            "Professional #{String.downcase(name)} services for homes and businesses in your area. " <>
              "Our experienced team handles jobs of all sizes with care and efficiency. " <>
              "Contact us today for a free estimate."
        }
      end)

    {:ok, descriptions}
  end

  defp default_response("GenerateTagline", _args) do
    {:ok,
     %{
       "options" => [
         "We Haul It All",
         "Clear your space, reclaim your peace of mind",
         "Professional junk removal you can count on"
       ]
     }}
  end

  defp default_response("GenerateWhyHireUs", _args) do
    {:ok,
     %{
       "bullets" => [
         "Same-day and next-day service available for urgent cleanups",
         "Fully licensed and insured for your complete peace of mind",
         "Eco-friendly disposal with 80% of materials recycled or donated",
         "Upfront pricing with no hidden fees or surprise charges",
         "Locally owned and operated with deep community roots",
         "Professional crew that respects your property and time"
       ]
     }}
  end

  defp default_response("GenerateMetaDescription", args) do
    name = args["business_name"] || "Your Hauling Co"
    area = args["service_area"] || "your area"

    {:ok,
     %{
       "description" =>
         "#{name} offers professional junk removal and hauling services in #{area}. Fast, reliable, eco-friendly. Get a free quote today!"
     }}
  end

  defp default_response(_function_name, _args) do
    {:ok, %{"result" => "sandbox"}}
  end
end
