# frozen_string_literal: true

module Custos
  module Plugins
    module RememberMe
      DEFAULT_REMEMBER_DURATION = 30 * 24 * 60 * 60 # 30 days in seconds

      def self.apply(model_class, **_options)
        model_class.has_many :custos_remember_tokens,
                             class_name: 'Custos::RememberToken',
                             as: :authenticatable,
                             dependent: :destroy

        model_class.include(InstanceMethods)
        model_class.extend(ClassMethods)
      end

      module InstanceMethods
        def generate_remember_token
          options = self.class.custos_config.plugin_options(:remember_me)
          duration = options.fetch(:remember_duration, DEFAULT_REMEMBER_DURATION)
          token = Custos::TokenGenerator.generate

          custos_remember_tokens.create!(
            token_digest: Custos::TokenGenerator.digest(token),
            expires_at: Time.current + duration
          )

          token
        end

        def forget_me!(token = nil)
          if token
            digest = Custos::TokenGenerator.digest(token)
            custos_remember_tokens.where(token_digest: digest).destroy_all
          else
            custos_remember_tokens.destroy_all
          end
        end
      end

      module ClassMethods
        def authenticate_remember_token(token)
          digest = Custos::TokenGenerator.digest(token)
          remember = Custos::RememberToken.not_expired.find_by(
            token_digest: digest,
            authenticatable_type: name
          )
          remember&.authenticatable
        end
      end
    end
  end
end

Custos::Plugin.register(:remember_me, Custos::Plugins::RememberMe)
