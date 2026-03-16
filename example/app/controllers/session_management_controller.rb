# frozen_string_literal: true

class SessionManagementController < ApplicationController
  before_action :require_authentication

  # GET /session_management — list all active sessions
  def index
    @sessions = Custos::SessionManager.active_for(current_user)
    @current_session = custos_session
  end

  # DELETE /session_management/:id — revoke a specific session
  def destroy
    target_session = current_user.custos_sessions.find_by(id: params[:id])

    if target_session
      Custos::SessionManager.revoke(target_session)
      redirect_to session_management_index_path, notice: "Session revoked."
    else
      redirect_to session_management_index_path, alert: "Session not found."
    end
  end

  # DELETE /session_management/revoke_all — revoke all sessions
  def revoke_all
    Custos::SessionManager.revoke_all(current_user)
    clear_session_cookie
    redirect_to new_session_path, notice: "All sessions revoked."
  end
end
