# frozen_string_literal: true

class AuthMailer < ApplicationMailer
  def magic_link(user, token)
    @user = user
    @url = verify_magic_link_url(token: token)

    Rails.logger.info <<~LOG
      [MAILER STUB] Magic Link
        To: #{@user.email}
        URL: #{@url}
    LOG

    mail(to: @user.email, subject: "Your magic link")
  end

  def email_confirmation(user, token)
    @user = user
    @url = confirm_email_url(token: token)

    Rails.logger.info <<~LOG
      [MAILER STUB] Email Confirmation
        To: #{@user.email}
        URL: #{@url}
    LOG

    mail(to: @user.email, subject: "Confirm your email")
  end
end
