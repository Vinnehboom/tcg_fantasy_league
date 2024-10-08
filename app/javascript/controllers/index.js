// This file is auto-generated by ./bin/rails stimulus:manifest:update
// Run that command whenever you add a new controller or create them with
// ./bin/rails generate stimulus controllerName

import { application } from "./application"

import HelloController from "./hello_controller"
application.register("hello", HelloController)

import RemovalsController from "./removals_controller"
application.register("removals", RemovalsController)

import TableFiltersController from "./table_filters_controller"
application.register("table-filters", TableFiltersController)
