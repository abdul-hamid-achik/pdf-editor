// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import { definitions } from "stimulus:./controllers"

const application = Application.start()
application.load(definitions)
