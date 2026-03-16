# frozen_string_literal: true

module Api
  class ProtectedResourcesController < BaseController
    before_action :authenticate_api_client!

    # GET /api/protected
    def show
      render json: {
        message: "Authenticated as API client: #{current_api_client.name}",
        client_id: current_api_client.id,
        timestamp: Time.current.iso8601
      }
    end
  end
end
