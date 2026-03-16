# frozen_string_literal: true

class User < ApplicationRecord
  include Custos::Authenticatable

  custos do
    plugin :password
    plugin :magic_link
    plugin :mfa
    plugin :lockout
    plugin :email_confirmation
    plugin :remember_me

    on(:magic_link_created) do |record, token|
      AuthMailer.magic_link(record, token).deliver_later
    end

    on(:email_confirmation_requested) do |record, token|
      AuthMailer.email_confirmation(record, token).deliver_later
    end

    on(:sms_code_created) do |record, code|
      Rails.logger.info "[SMS STUB] To: #{record.phone} | Code: #{code}"
    end
  end

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
