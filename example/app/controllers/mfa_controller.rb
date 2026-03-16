# frozen_string_literal: true

class MfaController < ApplicationController
  before_action :require_authentication, only: %i[setup confirm_totp generate_backup_codes]
  before_action :require_pending_mfa_user, only: %i[verify_form verify verify_sms]

  # GET /mfa/setup — shows TOTP provisioning URI and backup codes form
  def setup
    @provisioning_uri = current_user.setup_totp(issuer: "CustosExample")
  end

  # POST /mfa/confirm_totp — confirm TOTP setup with a code from authenticator app
  def confirm_totp
    if current_user.confirm_totp!(params[:code])
      @backup_codes = current_user.generate_backup_codes
      flash.now[:notice] = "TOTP enabled. Save your backup codes."
      render :backup_codes
    else
      flash.now[:alert] = "Invalid TOTP code. Try again."
      @provisioning_uri = current_user.setup_totp(issuer: "CustosExample")
      render :setup, status: :unprocessable_entity
    end
  end

  # POST /mfa/backup_codes — regenerate backup codes
  def generate_backup_codes
    @backup_codes = current_user.generate_backup_codes
    render :backup_codes
  end

  # POST /mfa/send_sms — send SMS verification code (works for both authenticated and pending MFA)
  def send_sms
    user = resolve_mfa_user
    return redirect_to new_session_path, alert: "Please sign in first." unless user

    if user.phone.blank?
      target = current_user ? mfa_setup_path : mfa_verify_path
      redirect_to target, alert: "Phone number not configured."
      return
    end

    user.send_sms_code

    if current_user
      redirect_to mfa_setup_path, notice: "SMS code sent (see server logs)."
    else
      redirect_to mfa_verify_path, notice: "SMS code sent (see server logs)."
    end
  end

  # GET /mfa/verify — form for entering MFA code during login
  def verify_form
  end

  # POST /mfa/verify — verify MFA code (TOTP or backup code)
  def verify
    user = User.find(session[:pending_mfa_user_id])

    if user.respond_to?(:mfa_locked?) && user.mfa_locked?
      redirect_to new_session_path, alert: "Too many failed attempts. Try again later."
      return
    end

    verified = user.verify_totp(params[:code]) || user.verify_backup_code(params[:code])

    if verified
      complete_mfa_sign_in(user)
    else
      flash.now[:alert] = "Invalid code."
      render :verify_form, status: :unprocessable_entity
    end
  end

  # POST /mfa/verify_sms — verify SMS code during login
  def verify_sms
    user = User.find(session[:pending_mfa_user_id])

    if user.respond_to?(:mfa_locked?) && user.mfa_locked?
      redirect_to new_session_path, alert: "Too many failed attempts. Try again later."
      return
    end

    if user.verify_sms_code(params[:code])
      complete_mfa_sign_in(user)
    else
      flash.now[:alert] = "Invalid or expired SMS code."
      render :verify_form, status: :unprocessable_entity
    end
  end

  private

  def require_pending_mfa_user
    unless session[:pending_mfa_user_id].present? && mfa_session_fresh?
      session.delete(:pending_mfa_user_id)
      session.delete(:pending_mfa_at)
      session.delete(:remember_me)
      redirect_to new_session_path, alert: "Please sign in first."
    end
  end

  def mfa_session_fresh?
    pending_at = session[:pending_mfa_at]
    pending_at.present? && Time.current.to_i - pending_at.to_i < 300
  end

  def resolve_mfa_user
    current_user || (User.find_by(id: session[:pending_mfa_user_id]) if session[:pending_mfa_user_id])
  end

  def complete_mfa_sign_in(user)
    remember = session[:remember_me] == "1"
    reset_session
    _custos_session, token = Custos::SessionManager.create(user, request: request)
    set_session_cookie(token, remember: remember)
    redirect_to session_management_index_path, notice: "Signed in with MFA."
  end
end
