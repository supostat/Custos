# frozen_string_literal: true

class ApiClient < ApplicationRecord
  include Custos::Authenticatable

  custos do
    plugin :api_tokens
  end

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
end
