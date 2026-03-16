# frozen_string_literal: true

class AuditLogsController < ApplicationController
  before_action :require_authentication

  def index
    @audit_logs = current_user.audit_logs.order(created_at: :desc).limit(50)
  end
end
