export const PreviewReload = {
  mounted() {
    this.handleEvent("reload_preview", () => {
      const iframe = this.el.querySelector("iframe")
      if (iframe) {
        iframe.src = iframe.src
      }
    })
  }
}
