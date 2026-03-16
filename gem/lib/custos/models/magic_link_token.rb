# frozen_string_literal: true

module Custos
  class MagicLinkToken < ActiveRecord::Base
    self.table_name = 'custos_magic_links'

    belongs_to :authenticatable, polymorphic: true

    scope :unused, -> { where(used_at: nil) }
    scope :not_expired, -> { where('expires_at > ?', Time.current) }
    scope :valid_tokens, -> { unused.not_expired }
  end
end
