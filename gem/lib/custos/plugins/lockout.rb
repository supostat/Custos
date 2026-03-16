# frozen_string_literal: true

module Custos
  module Plugins
    module Lockout
      DEFAULT_MAX_ATTEMPTS = 3
      DEFAULT_LOCKOUT_DURATION = 30 * 60 # 30 minutes in seconds
      DEFAULT_MAX_MFA_ATTEMPTS = 5

      def self.apply(model_class, **_options)
        model_class.include(InstanceMethods)

        model_class.custos_config.hook(:after_authentication) do |record, success|
          if success
            record.reset_failed_attempts!
          else
            record.record_failed_attempt!
          end
        end

        model_class.custos_config.hook(:after_mfa_verification) do |record, success|
          if success
            record.reset_failed_mfa_attempts!
          else
            record.record_failed_mfa_attempt!
          end
        end
      end

      module InstanceMethods
        def locked?
          return false if locked_at.nil?

          options = self.class.custos_config.plugin_options(:lockout)
          duration = options.fetch(:lockout_duration, DEFAULT_LOCKOUT_DURATION)
          locked_at > duration.seconds.ago
        end

        def mfa_locked?
          return false unless respond_to?(:mfa_locked_at)
          return false if mfa_locked_at.nil?

          options = self.class.custos_config.plugin_options(:lockout)
          duration = options.fetch(:mfa_lockout_duration,
                                   options.fetch(:lockout_duration, DEFAULT_LOCKOUT_DURATION))
          mfa_locked_at > duration.seconds.ago
        end

        def record_failed_attempt!
          max = self.class.custos_config.plugin_options(:lockout).fetch(:max_attempts, DEFAULT_MAX_ATTEMPTS)

          self.class.where(id: id).update_all(
            [
              'failed_auth_count = failed_auth_count + 1, ' \
              'locked_at = CASE WHEN failed_auth_count + 1 >= ? THEN ? ELSE locked_at END',
              max, Time.current
            ]
          )
          reload
        end

        def record_failed_mfa_attempt!
          return unless respond_to?(:failed_mfa_count)

          max = self.class.custos_config.plugin_options(:lockout).fetch(:max_mfa_attempts, DEFAULT_MAX_MFA_ATTEMPTS)

          self.class.where(id: id).update_all(
            [
              'failed_mfa_count = failed_mfa_count + 1, ' \
              'mfa_locked_at = CASE WHEN failed_mfa_count + 1 >= ? THEN ? ELSE mfa_locked_at END',
              max, Time.current
            ]
          )
          reload
        end

        def reset_failed_attempts!
          update!(failed_auth_count: 0, locked_at: nil) if failed_auth_count.positive?
        end

        def reset_failed_mfa_attempts!
          return unless respond_to?(:failed_mfa_count)

          update!(failed_mfa_count: 0, mfa_locked_at: nil) if failed_mfa_count.positive?
        end

        def unlock!
          attrs = { failed_auth_count: 0, locked_at: nil }
          if respond_to?(:failed_mfa_count)
            attrs[:failed_mfa_count] = 0
            attrs[:mfa_locked_at] = nil
          end
          update!(attrs)
        end
      end
    end
  end
end

Custos::Plugin.register(:lockout, Custos::Plugins::Lockout)
