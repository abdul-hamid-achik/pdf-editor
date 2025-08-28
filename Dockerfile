# Development Dockerfile
FROM ruby:3.3.8-slim

# Install dependencies
RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  postgresql-client \
  nodejs \
  npm \
  git \
  curl \
  vim \
  imagemagick \
  libvips42 \
  libssl-dev \
  libyaml-dev \
  less \
  htop \
  net-tools \
  && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN gem install bundler && \
    bundle config set --local development 'true' && \
    bundle config set --local without 'production' && \
    bundle install --jobs 4 --retry 3

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p tmp/pids tmp/cache tmp/sockets log storage

# Add a script to handle database setup
COPY <<-"SCRIPT" /usr/bin/docker-entrypoint.sh
#!/bin/bash
set -e

# Remove old server pid if exists
rm -f /app/tmp/pids/server.pid

# Setup database if needed
if [ "$1" = "rails" ] && [ "$2" = "server" ]; then
  echo "Checking database..."
  bundle exec rails db:prepare
fi

# Execute the command
exec "$@"
SCRIPT

RUN chmod +x /usr/bin/docker-entrypoint.sh

# Expose ports
EXPOSE 3000 3035

# Set entrypoint
ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]

# Default command
CMD ["rails", "server", "-b", "0.0.0.0"]