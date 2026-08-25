import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, successText: String, failureText: String }
  static targets = ["input", "status"]

  submit() {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken
      },
      body: JSON.stringify({ results_source_id: this.inputTarget.value })
    }).then((response) => {
      this.statusTarget.textContent = response.ok ? this.successTextValue : this.failureTextValue
    }).catch(() => {
      this.statusTarget.textContent = this.failureTextValue
    })
  }
}
