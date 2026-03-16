# frozen_string_literal: true

class RegistrationsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    @user.password = params[:user][:password]

    if @user.save
      @user.send_email_confirmation
      redirect_to new_session_path, notice: "Account created. Check your email (see server logs) to confirm."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def confirm_email
    digest = Custos::TokenGenerator.digest(params[:token])
    user = User.find_by(email_confirmation_token_digest: digest)

    if user&.confirm_email!(params[:token])
      redirect_to new_session_path, notice: "Email confirmed. You can now sign in."
    else
      redirect_to new_session_path, alert: "Invalid or expired confirmation link."
    end
  end

  private

  def registration_params
    params.require(:user).permit(:email, :phone)
  end
end
