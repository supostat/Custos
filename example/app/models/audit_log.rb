# frozen_string_literal: true

class AuditLog < ApplicationRecord
  belongs_to :authenticatable, polymorphic: true
end
