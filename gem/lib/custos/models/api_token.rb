# frozen_string_literal: true

module Custos
  class ApiToken < ActiveRecord::Base
    self.table_name = 'custos_api_tokens'

    belongs_to :authenticatable, polymorphic: true

    scope :active, -> { where(revoked_at: nil).where('expires_at IS NULL OR expires_at > ?', Time.current) }

    def revoke!
      update!(revoked_at: Time.current)
    end

    def revoked?
      revoked_at.present?
    end

    def expired?
      expires_at.present? && expires_at <= Time.current
    end
  end
end
