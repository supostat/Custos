# frozen_string_literal: true

module Custos
  module Plugins
    module MagicLink
      DEFAULT_EXPIRY = 15 * 60 # 15 minutes in seconds
      DEFAULT_COOLDOWN = 60 # 1 minute between requests

      def self.apply(model_class, **_options)
        model_class.has_many :custos_magic_link_tokens,
                             class_name: 'Custos::MagicLinkToken',
                             as: :authenticatable,
                             dependent: :destroy

        model_class.extend(ClassMethods)
      end

      module ClassMethods
        def generate_magic_link(email)
          record = find_by(email: email)
          return nil unless record

          options = custos_config.plugin_options(:magic_link)
          cooldown = options.fetch(:cooldown, DEFAULT_COOLDOWN)
          if cooldown.positive?
            last_token = record.custos_magic_link_tokens.order(created_at: :desc).first
            return nil if last_token && last_token.created_at > cooldown.seconds.ago
          end

          record.custos_magic_link_tokens.valid_tokens.update_all(used_at: Time.current)

          token = Custos::TokenGenerator.generate
          expiry = options.fetch(:expiry, DEFAULT_EXPIRY)

          record.custos_magic_link_tokens.create!(
            token_digest: Custos::TokenGenerator.digest(token),
            expires_at: Time.current + expiry
          )

          Custos::CallbackRegistry.fire(self, :magic_link_created, record, token)
          token
        end

        def authenticate_magic_link(token)
          digest = Custos::TokenGenerator.digest(token)
          magic_link = Custos::MagicLinkToken.valid_tokens.find_by(
            token_digest: digest,
            authenticatable_type: name
          )
          return nil unless magic_link

          magic_link.update!(used_at: Time.current)
          magic_link.authenticatable
        end
      end
    end
  end
end

Custos::Plugin.register(:magic_link, Custos::Plugins::MagicLink)
