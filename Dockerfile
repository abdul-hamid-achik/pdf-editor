# Multi-stage Dockerfile for both development and production
FROM ruby:3.3.8-slim as base

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

# Install Node.js LTS
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs

# Rails app lives here
WORKDIR /app

# Copy dependency files
COPY Gemfile Gemfile.lock ./

# Development stage
FROM base as development

ENV RAILS_ENV=development

# Install development tools
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    vim \
    less \
    htop \
    net-tools \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install all gems including development
RUN gem install bundler && \
    bundle config set --local development 'true' && \
    bundle config set --local without 'production' && \
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
FROM base as production

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

# Install production gems only
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy package.json if it exists
COPY package*.json ./

# Install npm packages if package.json exists
RUN if [ -f package.json ]; then npm ci --only=production && npm cache clean --force; fi

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

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

# Default command for production - minimal test
ENTRYPOINT []
CMD bundle exec puma -C config/puma.rb