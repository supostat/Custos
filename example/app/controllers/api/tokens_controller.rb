# frozen_string_literal: true

module Api
  class TokensController < Api::BaseController
    before_action :authenticate_api_client!

    # POST /api/token — generate a new API token for the authenticated client
    def create
      token = current_api_client.generate_api_token
      render json: { token: token, client_name: current_api_client.name }, status: :created
    end

    # DELETE /api/token — revoke an API token
    def destroy
      token_value = params[:token]
      digest = Custos::TokenGenerator.digest(token_value)
      api_token = current_api_client.custos_api_tokens.find_by(token_digest: digest)

      if api_token
        api_token.revoke!
        render json: { message: "Token revoked" }
      else
        render json: { error: "Token not found" }, status: :not_found
      end
    end
  end
end
