# frozen_string_literal: true

module Custos
  module Plugins
    module EmailConfirmation
      DEFAULT_CONFIRMATION_EXPIRY = 24 * 60 * 60 # 24 hours in seconds

      def self.apply(model_class, **_options)
        model_class.include(InstanceMethods)
      end

      module InstanceMethods
        def send_email_confirmation
          token = Custos::TokenGenerator.generate
          update!(
            email_confirmation_token_digest: Custos::TokenGenerator.digest(token),
            email_confirmation_sent_at: Time.current
          )

          Custos::CallbackRegistry.fire(self.class, :email_confirmation_requested, self, token)
          token
        end

        def confirm_email!(token)
          return false if email_confirmation_token_digest.blank?
          return false if confirmation_token_expired?

          digest = Custos::TokenGenerator.digest(token)
          return false unless Custos::TokenGenerator.secure_compare(email_confirmation_token_digest, digest)

          update!(
            email_confirmed_at: Time.current,
            email_confirmation_token_digest: nil
          )
          true
        end

        def email_confirmed?
          email_confirmed_at.present?
        end

        private

        def confirmation_token_expired?
          return true if email_confirmation_sent_at.nil?

          options = self.class.custos_config.plugin_options(:email_confirmation)
          expiry = options.fetch(:confirmation_expiry, DEFAULT_CONFIRMATION_EXPIRY)
          email_confirmation_sent_at < expiry.seconds.ago
        end
      end
    end
  end
end

Custos::Plugin.register(:email_confirmation, Custos::Plugins::EmailConfirmation)
