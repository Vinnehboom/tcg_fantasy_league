import { Controller } from "@hotwired/stimulus"

// attach() has no caller on this branch - the score modifier's own page only
// detaches. The stacked player-page PR adds the attach form that uses it.
export default class extends Controller {
  static values = { url: String, confirm: String, genericError: String }
  static targets = ["error"]

  attach(event) {
    event.preventDefault()

    this.submit(this.urlValue, "POST", new FormData(this.element))
  }

  detach(event) {
    event.preventDefault()

    if (this.hasConfirmValue && this.confirmValue && !window.confirm(this.confirmValue)) {
      return
    }

    this.submit(this.urlValue, "DELETE")
  }

  submit(url, method, body) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    const options = {
      method,
      headers: {
        Accept: "application/json",
        "X-CSRF-Token": csrfToken
      }
    }
    if (body) {
      options.body = body
    }

    this.hideError()

    fetch(url, options)
      .then((response) => response.json().then((data) => ({ ok: response.ok, data })))
      .then(({ ok, data }) => {
        if (ok) {
          window.location.reload()
        } else {
          this.showError(data.error)
        }
      })
      .catch(() => this.showError(this.genericErrorValue))
  }

  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message
      this.errorTarget.hidden = false
    }
  }

  hideError() {
    if (this.hasErrorTarget) {
      this.errorTarget.hidden = true
    }
  }
}
