# frozen_string_literal: true

class SessionsController < ApplicationController
  def new
    redirect_to session_management_index_path if current_user
  end

  def create
    user = User.find_by_email_and_password(
      email: params[:email],
      password: params[:password]
    )

    if user.nil?
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
      return
    end

    if user.mfa_enabled?
      reset_session
      session[:pending_mfa_user_id] = user.id
      session[:pending_mfa_at] = Time.current.to_i
      session[:pending_mfa_nonce] = SecureRandom.hex(16)
      session[:remember_me] = params[:remember_me]
      redirect_to mfa_verify_path
      return
    end

    complete_sign_in(user, remember: params[:remember_me] == "1")
  end

  def destroy
    custos_session_record = custos_session
    Custos::SessionManager.revoke(custos_session_record) if custos_session_record
    clear_session_cookie
    cookies.delete(:custos_remember_token)
    reset_session
    redirect_to new_session_path, notice: "Signed out."
  end

  def magic_link_form
  end

  def send_magic_link
    User.generate_magic_link(params[:email])
    redirect_to new_session_path, notice: "If that email exists, a magic link was sent."
  end

  def verify_magic_link
    user = User.authenticate_magic_link(params[:token])

    if user.nil?
      redirect_to new_session_path, alert: "Invalid or expired magic link."
    elsif user.respond_to?(:locked?) && user.locked?
      redirect_to new_session_path, alert: "Account is locked. Try again later."
    elsif user.respond_to?(:email_confirmed?) && !user.email_confirmed?
      redirect_to new_session_path, alert: "Please confirm your email first."
    else
      complete_sign_in(user)
    end
  end

  private

  def complete_sign_in(user, remember: false)
    reset_session
    _custos_session, token = Custos::SessionManager.create(user, request: request)
    set_session_cookie(token, remember: remember)

    if user.respond_to?(:record_audit_event)
      user.record_audit_event(:session_created, metadata: {
        ip: request.remote_ip,
        user_agent: request.user_agent
      })
    end

    if remember && user.respond_to?(:generate_remember_token)
      remember_token = user.generate_remember_token
      cookies.signed[:custos_remember_token] = {
        value: remember_token,
        expires: 30.days.from_now,
        httponly: true,
        same_site: :lax,
        secure: Rails.env.production?
      }
    end

    redirect_to session_management_index_path, notice: "Signed in."
  end
end
