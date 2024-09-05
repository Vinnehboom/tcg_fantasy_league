// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import * as bootstrap from "bootstrap"

window.bootstrap = bootstrap

import "./controllers"

import jquery from "jquery"
window.jQuery = jquery
window.$ = jquery