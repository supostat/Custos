# frozen_string_literal: true

class ApplicationController < ActionController::Base
  rescue_from Custos::NotAuthenticatedError, with: :handle_not_authenticated

  private

  def require_authentication
    custos_authenticate!
  end

  def current_user
    custos_current(scope: :user)
  end
  helper_method :current_user

  def handle_not_authenticated
    respond_to do |format|
      format.html { redirect_to new_session_path, alert: "Please sign in." }
      format.json { render json: { error: "Authentication required" }, status: :unauthorized }
    end
  end

  def set_session_cookie(token, remember: false)
    cookie_options = { httponly: true, same_site: :lax, secure: Rails.env.production? }
    cookie_options[:expires] = 30.days.from_now if remember
    cookies.signed[:custos_session_token] = cookie_options.merge(value: token)
  end

  def clear_session_cookie
    cookies.delete(:custos_session_token)
  end
end
