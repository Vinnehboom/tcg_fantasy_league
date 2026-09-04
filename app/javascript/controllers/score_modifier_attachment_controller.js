import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, playerSeasonId: String, confirm: String, genericError: String }
  static targets = ["scoreModifierSelect", "error"]

  attach(event) {
    event.preventDefault()

    this.submit(this.urlValue, "POST", {
      player_season_modifier: {
        player_season_id: this.playerSeasonIdValue,
        score_modifier_id: this.scoreModifierSelectTarget.value
      }
    })
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
        "Content-Type": "application/json",
        Accept: "application/json",
        "X-CSRF-Token": csrfToken
      }
    }
    if (body) {
      options.body = JSON.stringify(body)
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
