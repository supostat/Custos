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
          options = self.class.custos_config.plugin_options(:lockout)
          max = options.fetch(:max_attempts, DEFAULT_MAX_ATTEMPTS)
          duration = options.fetch(:lockout_duration, DEFAULT_LOCKOUT_DURATION)
          now = Time.current

          self.class.where(id: id).update_all(
            [
              'failed_auth_count = CASE WHEN locked_at IS NOT NULL AND locked_at <= ? THEN 1 ' \
              'ELSE failed_auth_count + 1 END, ' \
              'locked_at = CASE WHEN locked_at IS NOT NULL AND locked_at <= ? THEN NULL ' \
              'WHEN (CASE WHEN locked_at IS NOT NULL AND locked_at <= ? THEN 1 ' \
              'ELSE failed_auth_count + 1 END) >= ? THEN ? ELSE locked_at END',
              duration.seconds.ago, duration.seconds.ago, duration.seconds.ago, max, now
            ]
          )
          reload
        end

        def record_failed_mfa_attempt!
          return unless respond_to?(:failed_mfa_count)

          options = self.class.custos_config.plugin_options(:lockout)
          max = options.fetch(:max_mfa_attempts, DEFAULT_MAX_MFA_ATTEMPTS)
          duration = options.fetch(:mfa_lockout_duration,
                                   options.fetch(:lockout_duration, DEFAULT_LOCKOUT_DURATION))
          now = Time.current

          self.class.where(id: id).update_all(
            [
              'failed_mfa_count = CASE WHEN mfa_locked_at IS NOT NULL AND mfa_locked_at <= ? THEN 1 ' \
              'ELSE failed_mfa_count + 1 END, ' \
              'mfa_locked_at = CASE WHEN mfa_locked_at IS NOT NULL AND mfa_locked_at <= ? THEN NULL ' \
              'WHEN (CASE WHEN mfa_locked_at IS NOT NULL AND mfa_locked_at <= ? THEN 1 ' \
              'ELSE failed_mfa_count + 1 END) >= ? THEN ? ELSE mfa_locked_at END',
              duration.seconds.ago, duration.seconds.ago, duration.seconds.ago, max, now
            ]
          )
          reload
        end

        def reset_failed_attempts!
          return unless failed_auth_count.positive? || locked_at.present?

          update!(failed_auth_count: 0, locked_at: nil)
        end

        def reset_failed_mfa_attempts!
          return unless respond_to?(:failed_mfa_count)
          return unless failed_mfa_count.positive? || mfa_locked_at.present?

          update!(failed_mfa_count: 0, mfa_locked_at: nil)
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
