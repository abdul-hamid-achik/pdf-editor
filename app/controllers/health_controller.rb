class HealthController < ApplicationController
  # Skip all filters for health checks
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!, if: :defined_authenticate_user?

  def check
    # Minimal health check - just return OK
    render json: {
      status: "ok",
      timestamp: Time.current.iso8601,
      environment: Rails.env
    }, status: 200
  end

  private

  def defined_authenticate_user?
    respond_to?(:authenticate_user!, true)
  end
end
