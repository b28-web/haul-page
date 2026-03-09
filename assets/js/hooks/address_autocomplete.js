const AddressAutocomplete = {
  mounted() {
    this.input = this.el
    this.debounceTimer = null
    this.abortController = null
    this.highlightedIndex = -1
    this.suggestions = []
    this.mouseDownOnDropdown = false

    // ARIA combobox attributes
    this.input.setAttribute("role", "combobox")
    this.input.setAttribute("aria-autocomplete", "list")
    this.input.setAttribute("aria-expanded", "false")
    this.input.setAttribute("aria-controls", `${this.el.id}-listbox`)

    this.onInput = this.onInput.bind(this)
    this.onKeyDown = this.onKeyDown.bind(this)
    this.onBlur = this.onBlur.bind(this)

    this.input.addEventListener("input", this.onInput)
    this.input.addEventListener("keydown", this.onKeyDown)
    this.input.addEventListener("blur", this.onBlur)
  },

  onInput(_event) {
    const query = this.input.value.trim()

    clearTimeout(this.debounceTimer)

    if (query.length < 3) {
      this.hideDropdown()
      return
    }

    this.debounceTimer = setTimeout(() => this.fetchSuggestions(query), 300)
  },

  async fetchSuggestions(query) {
    // Abort any in-flight request
    if (this.abortController) {
      this.abortController.abort()
    }
    this.abortController = new AbortController()

    try {
      const response = await fetch(
        `/api/places/autocomplete?input=${encodeURIComponent(query)}`,
        { signal: this.abortController.signal }
      )

      if (!response.ok) {
        this.hideDropdown()
        return
      }

      const data = await response.json()
      this.suggestions = data.suggestions || []

      if (this.suggestions.length > 0) {
        this.renderDropdown()
      } else {
        this.hideDropdown()
      }
    } catch (err) {
      if (err.name !== "AbortError") {
        this.hideDropdown()
      }
    }
  },

  renderDropdown() {
    this.removeDropdown()
    this.highlightedIndex = -1

    const listbox = document.createElement("ul")
    listbox.id = `${this.el.id}-listbox`
    listbox.setAttribute("role", "listbox")
    listbox.className = [
      "absolute z-50 left-0 right-0 mt-1",
      "bg-base-200 border border-base-300 rounded shadow-lg",
      "max-h-60 overflow-y-auto",
    ].join(" ")

    this.suggestions.forEach((suggestion, index) => {
      const option = document.createElement("li")
      option.id = `${this.el.id}-option-${index}`
      option.setAttribute("role", "option")
      option.setAttribute("aria-selected", "false")
      option.className =
        "px-3 py-2 cursor-pointer hover:bg-base-300 transition-colors"

      const fmt = suggestion.structured_formatting || {}
      const main = document.createElement("span")
      main.className = "font-semibold text-foreground"
      main.textContent = fmt.main_text || suggestion.description

      option.appendChild(main)

      if (fmt.secondary_text) {
        const secondary = document.createElement("span")
        secondary.className = "text-sm text-muted-foreground ml-1"
        secondary.textContent = fmt.secondary_text
        option.appendChild(secondary)
      }

      option.addEventListener("mousedown", (e) => {
        e.preventDefault() // prevent blur
        this.selectSuggestion(suggestion)
      })

      listbox.appendChild(option)
    })

    // Insert listbox as sibling after the input's parent wrapper
    const wrapper = this.input.closest(".relative")
    if (wrapper) {
      wrapper.appendChild(listbox)
    } else {
      this.input.parentElement.appendChild(listbox)
    }

    this.listbox = listbox
    this.input.setAttribute("aria-expanded", "true")
  },

  hideDropdown() {
    this.removeDropdown()
    this.suggestions = []
    this.highlightedIndex = -1
    this.input.setAttribute("aria-expanded", "false")
    this.input.removeAttribute("aria-activedescendant")
  },

  removeDropdown() {
    if (this.listbox) {
      this.listbox.remove()
      this.listbox = null
    }
  },

  highlightIndex(index) {
    if (!this.listbox) return

    const options = this.listbox.querySelectorAll('[role="option"]')

    // Remove previous highlight
    options.forEach((opt) => {
      opt.classList.remove("bg-base-300")
      opt.setAttribute("aria-selected", "false")
    })

    if (index >= 0 && index < options.length) {
      this.highlightedIndex = index
      const option = options[index]
      option.classList.add("bg-base-300")
      option.setAttribute("aria-selected", "true")
      option.scrollIntoView({ block: "nearest" })
      this.input.setAttribute("aria-activedescendant", option.id)
    } else {
      this.highlightedIndex = -1
      this.input.removeAttribute("aria-activedescendant")
    }
  },

  onKeyDown(event) {
    if (!this.listbox) return

    const count = this.suggestions.length

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.highlightIndex(
          this.highlightedIndex < count - 1
            ? this.highlightedIndex + 1
            : 0
        )
        break

      case "ArrowUp":
        event.preventDefault()
        this.highlightIndex(
          this.highlightedIndex > 0
            ? this.highlightedIndex - 1
            : count - 1
        )
        break

      case "Enter":
        if (this.highlightedIndex >= 0) {
          event.preventDefault()
          this.selectSuggestion(this.suggestions[this.highlightedIndex])
        }
        break

      case "Escape":
        event.preventDefault()
        this.hideDropdown()
        break

      case "Tab":
        this.hideDropdown()
        break

      case "Home":
        if (this.listbox) {
          event.preventDefault()
          this.highlightIndex(0)
        }
        break

      case "End":
        if (this.listbox) {
          event.preventDefault()
          this.highlightIndex(count - 1)
        }
        break
    }
  },

  selectSuggestion(suggestion) {
    this.input.value = suggestion.description
    this.hideDropdown()

    // Trigger LiveView change detection
    this.input.dispatchEvent(new Event("input", { bubbles: true }))
  },

  onBlur(_event) {
    // Delay to allow mousedown on dropdown items to fire first
    setTimeout(() => this.hideDropdown(), 200)
  },

  destroyed() {
    clearTimeout(this.debounceTimer)
    if (this.abortController) {
      this.abortController.abort()
    }
    this.removeDropdown()
    this.input.removeEventListener("input", this.onInput)
    this.input.removeEventListener("keydown", this.onKeyDown)
    this.input.removeEventListener("blur", this.onBlur)
  },
}

export default AddressAutocomplete
