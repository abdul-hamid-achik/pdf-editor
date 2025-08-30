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
  tailwind.css
]

# Ensure proper MIME type handling for JavaScript modules
Rails.application.config.assets.configure do |env|
  env.export_concurrent = false if Rails.env.production?
end