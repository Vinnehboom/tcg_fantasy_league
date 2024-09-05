import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['input', 'form']
  connect() {
    let form = $(this.formTarget)
    let input = $(this.inputTarget)
    input.on('input',
        debounce(
            function () {
              form.find('input[type=submit]').click()
            }, 500)
    )
  }
}

function debounce(func, delay) {
    let timeoutId;
    return function(...args) {
        clearTimeout(timeoutId);
        timeoutId = setTimeout(() => {
            func.apply(this, args);
        }, delay);
    };
}