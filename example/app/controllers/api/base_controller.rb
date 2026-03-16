# frozen_string_literal: true

module Api
  class BaseController < ActionController::Base
    protect_from_forgery with: :null_session

    rescue_from Custos::NotAuthenticatedError do
      render json: { error: "Authentication required" }, status: :unauthorized
    end

    private

    def authenticate_api_client!
      token = request.headers["Authorization"]&.delete_prefix("Bearer ")
      @current_api_client = ApiClient.authenticate_api_token(token) if token
      return if @current_api_client

      raise Custos::NotAuthenticatedError
    end

    def current_api_client
      @current_api_client
    end
  end
end
