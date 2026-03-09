// BAML source — compiled by baml_elixir NIF at runtime.
// See https://docs.boundaryml.com for BAML language reference.

client<llm> Anthropic {
  provider anthropic
  options {
    model "claude-sonnet-4-20250514"
    api_key env.ANTHROPIC_API_KEY
  }
}

class PersonName {
  first_name string
  last_name string
}

// Operator profile types — used by AI onboarding pipeline (S-018)

enum ServiceCategory {
  JUNK_REMOVAL
  CLEANOUTS
  YARD_WASTE
  REPAIRS
  ASSEMBLY
  MOVING_HELP
  OTHER
}

class ServiceOffering {
  name string
  description string?
  category ServiceCategory
}

class OperatorProfile {
  business_name string
  owner_name string
  phone string
  email string
  service_area string
  tagline string?
  years_in_business int?
  services ServiceOffering[]
  differentiators string[]
}

function ExtractName(text: string) -> PersonName {
  client Anthropic
  prompt #"
    Extract the person's first and last name from the following text.
    Return JSON with first_name and last_name fields.

    Text: {{ text }}

    {{ ctx.output_format }}
  "#
}

function ExtractOperatorProfile(transcript: string) -> OperatorProfile {
  client Anthropic
  prompt #"
    You are extracting business profile information from a junk removal operator's
    onboarding conversation. The transcript may contain multiple messages, small talk,
    or irrelevant content — focus only on business-relevant information.

    Extract all available business details. For each field:
    - business_name: The company or business name
    - owner_name: The owner's full name
    - phone: Phone number in any format
    - email: Email address
    - service_area: Geographic area they serve (city, county, metro area)
    - tagline: A short marketing tagline or slogan, if mentioned
    - years_in_business: How long they've been operating, as an integer
    - services: List of services offered. For each service, infer the best matching
      ServiceCategory from the description:
      - JUNK_REMOVAL: general junk/trash/debris removal
      - CLEANOUTS: garage, attic, estate, storage unit cleanouts
      - YARD_WASTE: branches, leaves, landscaping debris
      - REPAIRS: handyman, fix-it, minor repair services
      - ASSEMBLY: furniture or equipment assembly
      - MOVING_HELP: moving assistance, loading/unloading
      - OTHER: anything that doesn't fit the above
    - differentiators: Unique selling points, what sets them apart from competitors

    If a field is not mentioned or cannot be determined, use null.
    If services are described but not explicitly named, create a reasonable service
    name and description based on what was said.

    Transcript:
    {{ transcript }}

    {{ ctx.output_format }}
  "#
}

// --- Content generation (S-020) ---
// Uses Haiku for cost efficiency — generation is simpler than extraction.

client<llm> AnthropicHaiku {
  provider anthropic
  options {
    model "claude-haiku-4-5-20251001"
    api_key env.ANTHROPIC_API_KEY
  }
}

class ServiceDescription {
  service_name string
  description string
}

class TaglineOptions {
  options string[]
}

class WhyHireUsBullets {
  bullets string[]
}

class MetaDescriptionResult {
  description string
}

function GenerateServiceDescriptions(
  service_names: string[],
  business_name: string,
  service_area: string,
  differentiators: string[]
) -> ServiceDescription[] {
  client AnthropicHaiku
  prompt #"
    Write professional service descriptions for a junk removal / hauling company's website.

    Business: {{ business_name }}
    Service area: {{ service_area }}
    What sets them apart: {{ differentiators }}

    Write a 2-3 sentence description for each of these services:
    {{ service_names }}

    Each description should:
    - Sound professional and confident
    - Mention the service area naturally if relevant
    - Highlight the business's strengths where appropriate
    - Be written for a customer visiting the website

    {{ ctx.output_format }}
  "#
}

function GenerateTagline(
  business_name: string,
  service_area: string,
  services: string[],
  differentiators: string[]
) -> TaglineOptions {
  client AnthropicHaiku
  prompt #"
    Write 3 tagline options for a junk removal / hauling company's website.

    Business: {{ business_name }}
    Service area: {{ service_area }}
    Services offered: {{ services }}
    What sets them apart: {{ differentiators }}

    Create exactly 3 taglines:
    1. Short and punchy (under 8 words)
    2. Benefit-focused (what the customer gets)
    3. Professional and trustworthy

    Each tagline should be memorable and work as a website headline.
    Do not use quotation marks around the taglines.

    {{ ctx.output_format }}
  "#
}

function GenerateWhyHireUs(
  business_name: string,
  differentiators: string[],
  years_in_business: string,
  service_area: string
) -> WhyHireUsBullets {
  client AnthropicHaiku
  prompt #"
    Write 6 "Why hire us" bullet points for a junk removal / hauling company's website.

    Business: {{ business_name }}
    Service area: {{ service_area }}
    Years in business: {{ years_in_business }}
    What sets them apart: {{ differentiators }}

    Create exactly 6 short bullet points (one sentence each) that would convince a
    homeowner to hire this company. Each bullet should:
    - Start with a strong action word or benefit
    - Be specific, not generic
    - Sound confident without being boastful

    Use the differentiators as inspiration but expand and professionalize them.
    If there aren't enough differentiators, create reasonable ones for a hauling business.

    {{ ctx.output_format }}
  "#
}

function GenerateMetaDescription(
  business_name: string,
  service_area: string,
  services: string[]
) -> MetaDescriptionResult {
  client AnthropicHaiku
  prompt #"
    Write an SEO meta description for a junk removal / hauling company's website.

    Business: {{ business_name }}
    Service area: {{ service_area }}
    Services: {{ services }}

    Requirements:
    - Maximum 155 characters (strict limit)
    - Include the business name
    - Mention the service area
    - Include a call to action
    - Sound professional

    Write exactly one meta description.

    {{ ctx.output_format }}
  "#
}
