# frozen_string_literal: true

class Admin < User
  custos do
    plugin :password, min_length: 12, require_uppercase: true, require_digit: true
    plugin :mfa
    plugin :lockout, max_attempts: 3, lockout_duration: 60 * 60
    plugin :email_confirmation
    plugin :audit_log

    on(:email_confirmation_requested) do |record, token|
      AuthMailer.email_confirmation(record, token).deliver_later
    end
  end
end
