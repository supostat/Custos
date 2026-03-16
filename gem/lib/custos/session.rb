# frozen_string_literal: true

module Custos
  class Session < ActiveRecord::Base
    self.table_name = 'custos_sessions'

    belongs_to :authenticatable, polymorphic: true

    scope :active, lambda {
      where(revoked_at: nil)
        .where('last_active_at > ?', Custos.configuration.session_expiry.seconds.ago)
    }

    scope :revoked, -> { where.not(revoked_at: nil) }
  end
end
