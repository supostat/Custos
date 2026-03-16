# frozen_string_literal: true

module Custos
  class MfaCredential < ActiveRecord::Base
    self.table_name = 'custos_mfa_credentials'

    belongs_to :authenticatable, polymorphic: true

    scope :enabled, -> { where.not(enabled_at: nil) }
    scope :by_method, ->(method_name) { where(method: method_name) }

    def secret_data
      Custos::MfaEncryptor.decrypt(super)
    end

    def secret_data=(value)
      super(Custos::MfaEncryptor.encrypt(value))
    end
  end
end
