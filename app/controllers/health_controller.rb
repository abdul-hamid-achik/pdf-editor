class HealthController < ApplicationController
  # Skip authentication for health checks (class level)
  skip_before_action :authenticate_user!, if: -> { respond_to?(:authenticate_user!, true) }

  def check
    health_data = {
      status: "ok",
      timestamp: Time.current.iso8601,
      version: Rails.application.class.module_parent_name.downcase,
      environment: Rails.env,
      checks: {}
    }

    # Database health check
    begin
      ActiveRecord::Base.connection.execute("SELECT 1")
      health_data[:checks][:database] = "ok"
    rescue => e
      health_data[:checks][:database] = "error: #{e.message}"
      health_data[:status] = "error"
    end

    # Redis health check (if configured)
    if defined?(Redis) && ENV["REDIS_URL"].present?
      begin
        redis = Redis.new(url: ENV["REDIS_URL"])
        redis.ping
        health_data[:checks][:redis] = "ok"
      rescue => e
        health_data[:checks][:redis] = "error: #{e.message}"
        health_data[:status] = "error" unless health_data[:status] == "error"
      end
    end

    # Storage health check
    begin
      # Test if we can connect to storage
      if Rails.application.config.active_storage.service == :amazon
        # Quick S3/MinIO connectivity test
        bucket = ActiveStorage::Blob.service.bucket
        health_data[:checks][:storage] = "ok"
      else
        health_data[:checks][:storage] = "local"
      end
    rescue => e
      health_data[:checks][:storage] = "error: #{e.message}"
      health_data[:status] = "error"
    end

    status_code = health_data[:status] == "ok" ? 200 : 503
    render json: health_data, status: status_code
  end


end
