# frozen_string_literal: true

module Custos
  class RememberToken < ActiveRecord::Base
    self.table_name = 'custos_remember_tokens'

    belongs_to :authenticatable, polymorphic: true

    scope :not_expired, -> { where('expires_at > ?', Time.current) }
  end
end
