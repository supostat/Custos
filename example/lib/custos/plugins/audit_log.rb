# frozen_string_literal: true

module Custos
  module Plugins
    module AuditLog
      def self.apply(model_class, **_options)
        model_class.has_many :audit_logs, as: :authenticatable, dependent: :destroy
        model_class.include(InstanceMethods)

        model_class.custos_config.hook(:after_authentication) do |record, success|
          record.record_audit_event(success ? :login_success : :login_failure)
        end

        model_class.custos_config.hook(:after_mfa_verification) do |record, success|
          record.record_audit_event(success ? :mfa_success : :mfa_failure)
        end
      end

      module InstanceMethods
        def record_audit_event(event, metadata: {})
          audit_logs.create(event: event.to_s, metadata: metadata.to_json)
        end
      end
    end
  end
end

Custos::Plugin.register(:audit_log, Custos::Plugins::AuditLog)
