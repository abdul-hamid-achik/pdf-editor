# Rails 8 Propshaft Asset Configuration
# Be sure to restart your server when you modify this file.

# Add additional assets to the asset load path.
Rails.application.config.assets.paths << Rails.root.join("app", "assets", "builds")

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )

# Configure Propshaft to handle our assets properly
Rails.application.config.assets.precompile += %w[
  application.js
  application.css
  tailwind.css
  controllers/application.js
  controllers/document_list_controller.js
  controllers/hello_controller.js
  controllers/pdf_editor_controller.js
  controllers/pdf_preview_controller.js
  controllers/theme_toggle_controller.js
]

# Ensure proper MIME type handling for JavaScript modules
Rails.application.config.assets.configure do |env|
  env.export_concurrent = false if Rails.env.production?
end