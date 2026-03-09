const StripePayment = {
  mounted() {
    this.clientSecret = this.el.dataset.clientSecret
    this.publishableKey = this.el.dataset.publishableKey

    if (!this.publishableKey || !this.clientSecret) return

    this.stripe = Stripe(this.publishableKey)
    this.elements = this.stripe.elements({
      clientSecret: this.clientSecret,
      appearance: {
        theme: "night",
        variables: {
          colorPrimary: "#ffffff",
          colorBackground: "#1a1a1a",
          colorText: "#ffffff",
          colorDanger: "#ef4444",
          fontFamily: "'Source Sans 3', system-ui, sans-serif",
          borderRadius: "0px",
        },
      },
    })

    this.paymentElement = this.elements.create("payment")
    this.paymentElement.mount(this.el.querySelector("[data-stripe-element]"))

    const form = this.el.querySelector("form")
    if (form) {
      form.addEventListener("submit", (e) => this.handleSubmit(e))
    }
  },

  async handleSubmit(e) {
    e.preventDefault()
    this.pushEvent("payment_processing", {})

    const { error, paymentIntent } = await this.stripe.confirmPayment({
      elements: this.elements,
      confirmParams: {},
      redirect: "if_required",
    })

    if (error) {
      this.pushEvent("payment_failed", { error: error.message })
    } else if (paymentIntent && paymentIntent.status === "succeeded") {
      this.pushEvent("payment_confirmed", {
        payment_intent_id: paymentIntent.id,
      })
    } else if (paymentIntent) {
      this.pushEvent("payment_failed", {
        error: "Payment was not completed. Status: " + paymentIntent.status,
      })
    }
  },

  destroyed() {
    if (this.paymentElement) {
      this.paymentElement.destroy()
    }
  },
}

export default StripePayment
