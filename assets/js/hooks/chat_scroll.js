/**
 * ChatScroll hook — auto-scrolls chat container to bottom on new messages.
 *
 * Usage: <div id="chat-messages" phx-hook="ChatScroll">
 */
const ChatScroll = {
  mounted() {
    this.scrollToBottom()

    this.handleEvent("scroll_to_bottom", () => {
      this.scrollToBottom()
    })
  },

  updated() {
    // Auto-scroll if user is near the bottom (within 100px)
    if (this.isNearBottom()) {
      this.scrollToBottom()
    }
  },

  isNearBottom() {
    const threshold = 100
    const el = this.el
    return el.scrollHeight - el.scrollTop - el.clientHeight < threshold
  },

  scrollToBottom() {
    requestAnimationFrame(() => {
      this.el.scrollTop = this.el.scrollHeight
    })
  }
}

export default ChatScroll
