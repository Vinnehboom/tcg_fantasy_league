import { Controller } from "@hotwired/stimulus"

// The admin import-triggers endpoint (Admin::ExternalImportsController#create) is headless —
// no view, no flash, no redirect to land on — so triggering it needs a client-side fetch
// handler instead of a plain Rails form.
export default class extends Controller {
  static values = { url: String, gameId: String, successText: String, failureText: String }
  static targets = ["status"]

  trigger({ params: { kind } }) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    fetch(this.urlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken
      },
      body: JSON.stringify({ game_id: this.gameIdValue, kind })
    }).then((response) => {
      this.statusTarget.textContent = response.ok ? this.successTextValue : this.failureTextValue
    })
  }
}
