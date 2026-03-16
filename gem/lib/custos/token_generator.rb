# frozen_string_literal: true

require 'openssl'
require 'securerandom'
require 'active_support/security_utils'

module Custos
  class TokenGenerator
    def self.generate(byte_length: nil)
      length = byte_length || Custos.configuration.token_length
      SecureRandom.urlsafe_base64(length)
    end

    def self.digest(token)
      secret = resolve_token_secret
      OpenSSL::HMAC.hexdigest('SHA256', secret, token)
    end

    def self.secure_compare(value_a, value_b)
      ActiveSupport::SecurityUtils.secure_compare(value_a, value_b)
    end

    def self.resolve_token_secret
      secret = Custos.configuration.token_secret
      return secret if secret

      if defined?(Rails) && Rails.respond_to?(:application) && Rails.application
        base = Rails.application.secret_key_base
        return base if base.present?
      end

      raise Custos::Error, 'Custos.configuration.token_secret must be configured'
    end

    private_class_method :resolve_token_secret
  end
end
