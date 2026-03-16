# frozen_string_literal: true

Custos.configure do |config|
  config.session_expiry = 24 * 60 * 60           # 24 hours
  config.session_renewal_interval = 60 * 60       # 1 hour
  config.token_length = 32                        # bytes
  config.scope_map = { user: "User", api_client: "ApiClient" }
end
