# T-019-04 Structure: Onboarding Agent Prompt

## Files to create

### 1. `priv/prompts/onboarding_agent.md`
The system prompt file. Loaded at runtime. Contains:
- YAML frontmatter with version tag
- System prompt sections: role, conversation flow, field requirements, edge cases, completion rules

### 2. `lib/haul/ai/prompt.ex`
Prompt loader module.

```
defmodule Haul.AI.Prompt do
  @doc "Load a prompt file from priv/prompts/"
  def load(name) :: {:ok, String.t()} | {:error, term()}

  @doc "Extract version from prompt frontmatter"
  def version(name) :: {:ok, String.t()} | {:error, term()}
end
```

- Uses `Application.app_dir(:haul, "priv/prompts")` for release compatibility
- Reads file, strips frontmatter for `load/1`, parses frontmatter for `version/1`
- No caching — file reads are cheap, and runtime reloading is a feature

### 3. `test/haul/ai/prompt_test.exs`
Tests for the prompt loader:
- `load/1` returns prompt content without frontmatter
- `version/1` returns version string
- `load/1` returns error for missing prompt
- Prompt content contains required sections (field names, conversation flow markers)

### 4. `test/haul/ai/onboarding_prompt_test.exs`
Tests specific to the onboarding agent prompt content:
- Prompt mentions all required fields (business_name, phone, email)
- Prompt mentions service categories
- Prompt contains persona instructions
- Prompt version is "v1"
- Prompt contains redirect/focus instructions

## Files unchanged
- `lib/haul/ai.ex` — no changes needed. Prompt loading is independent of the AI adapter.
- `baml/main.baml` — prompt is for chat agent, not BAML function.
- `lib/haul/onboarding.ex` — integration happens in T-019-01/02, not here.

## Module boundaries
- `Haul.AI.Prompt` is a pure file loader. No AI calls, no business logic.
- The prompt file itself contains all conversation design. No code-level conversation orchestration in this ticket.
- Prompt is consumed by the chat LiveView (T-019-01) which passes it as system prompt to Claude API calls.

## Ordering
1. Create `priv/prompts/` directory
2. Write the system prompt file
3. Write the prompt loader module
4. Write tests
