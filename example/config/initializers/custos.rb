# frozen_string_literal: true

require_relative "../../lib/custos/plugins/audit_log"

Custos.configure do |config|
  config.session_expiry = 24 * 60 * 60           # 24 hours
  config.session_renewal_interval = 60 * 60       # 1 hour
  config.token_length = 32                        # bytes
  config.token_secret = Rails.application.secret_key_base
  config.mfa_encryption_key = Rails.application.credentials.custos_mfa_key || Rails.application.secret_key_base
  config.scope_map = { user: "User", api_client: "ApiClient" }
end
