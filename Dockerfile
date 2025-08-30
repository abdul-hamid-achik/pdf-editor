# Multi-stage Dockerfile for both development and production
FROM ruby:3.3.8-slim AS base

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    libpq-dev \
    postgresql-client \
    curl \
    git \
    imagemagick \
    libvips42 \
    libyaml-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Node.js not needed - Rails 8 uses importmap-rails for JavaScript

# Rails app lives here
WORKDIR /app

# Copy dependency files
COPY Gemfile Gemfile.lock ./

# Development stage
FROM base AS development

ENV RAILS_ENV=development
ENV BUNDLE_PATH=/usr/local/bundle
ENV BUNDLE_APP_CONFIG=/usr/local/bundle

# Install development tools
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    vim \
    less \
    htop \
    net-tools \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install all gems including development with consistent path
RUN gem install bundler && \
    bundle config set --global path '/usr/local/bundle' && \
    bundle config set --global without 'production' && \
    bundle install --jobs 4 --retry 3

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p tmp/pids tmp/cache tmp/sockets log storage

# Expose ports
EXPOSE 3000 3035

# Default command for development
CMD ["bash", "-c", "rm -f tmp/pids/server.pid && bundle exec rails db:prepare && bundle exec rails server -b '0.0.0.0'"]

# Production stage
FROM base AS production

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test:assets"

# Install production gems only (including webrick)
RUN bundle install --verbose && \
    bundle exec gem list webrick && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# package.json no longer needed - Rails 8 handles assets natively

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompile assets using Rails 8 native pipeline (importmap + tailwindcss-rails)
# This handles both JavaScript (via importmap) and CSS (via tailwindcss-rails gem)
RUN RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Create storage directory and set permissions
RUN mkdir -p storage tmp/cache tmp/pids tmp/sockets && \
    chmod -R 755 storage tmp

# Create non-root user for production
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp

USER rails:rails

# Expose port
EXPOSE 3000

# Default command for production with debugging
ENTRYPOINT []
CMD echo "Starting Rails application..." && \
    bundle exec gem list webrick && \
    bundle exec rails db:create db:migrate && \
    echo "Database setup complete, starting Puma..." && \
    bundle exec puma -C config/puma.rb