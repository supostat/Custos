# frozen_string_literal: true

module Custos
  class Configuration
    attr_accessor :session_expiry,
                  :session_renewal_interval,
                  :token_length,
                  :scope_map,
                  :token_secret,
                  :mfa_encryption_key,
                  :callback_error_strategy

    def initialize
      @session_expiry = 24 * 60 * 60 # 24 hours in seconds
      @session_renewal_interval = 60 * 60       # 1 hour in seconds
      @token_length = 32                        # bytes
      @scope_map = {}                           # e.g. { user: "User", api_client: "ApiClient" }
      @token_secret = nil                       # HMAC secret; falls back to Rails.application.secret_key_base
      @mfa_encryption_key = nil                 # AES-256-GCM key for MFA secrets; nil = plaintext
      @callback_error_strategy = :log           # :log or :raise
    end

    VALID_CLASS_NAME = /\A[A-Z][A-Za-z0-9]*(::[A-Z][A-Za-z0-9]*)*\z/

    def model_class_for_scope(scope)
      class_name = @scope_map[scope.to_sym]
      return nil unless class_name
      return nil unless class_name.match?(VALID_CLASS_NAME)

      class_name.constantize
    rescue NameError
      nil
    end
  end
end
