# frozen_string_literal: true

module Custos
  module Plugins
    module ApiTokens
      def self.apply(model_class, **_options)
        model_class.has_many :custos_api_tokens,
                             class_name: 'Custos::ApiToken',
                             as: :authenticatable,
                             dependent: :destroy

        model_class.include(InstanceMethods)
        model_class.extend(ClassMethods)
      end

      module InstanceMethods
        def generate_api_token(expires_in: nil)
          token = Custos::TokenGenerator.generate

          default_expiry = self.class.custos_config.plugin_options(:api_tokens).fetch(:default_expiry, nil)
          expiry = expires_in || default_expiry

          custos_api_tokens.create!(
            token_digest: Custos::TokenGenerator.digest(token),
            expires_at: expiry ? Time.current + expiry : nil
          )
          token
        end
      end

      module ClassMethods
        def authenticate_api_token(token)
          digest = Custos::TokenGenerator.digest(token)
          api_token = Custos::ApiToken.active.find_by(
            token_digest: digest,
            authenticatable_type: name
          )
          return nil unless api_token

          api_token.update_column(:last_used_at, Time.current)
          api_token.authenticatable
        end
      end
    end
  end
end

Custos::Plugin.register(:api_tokens, Custos::Plugins::ApiTokens)
