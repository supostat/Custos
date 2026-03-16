# frozen_string_literal: true

require 'active_support/concern'

module Custos
  module ControllerHelpers
    extend ActiveSupport::Concern

    def custos_authenticate!(scope: :user)
      return if custos_authenticated?(scope: scope)

      raise Custos::NotAuthenticatedError, 'Authentication required'
    end

    def custos_authenticated?(scope: :user)
      custos_current(scope: scope).present?
    end

    def custos_current(scope: :user)
      ivar = "@custos_current_#{scope}"
      return instance_variable_get(ivar) if instance_variable_defined?(ivar)

      session = resolve_custos_session(scope)
      instance_variable_set(ivar, session&.authenticatable)
    end

    def custos_session
      token = extract_custos_token
      @custos_session ||= Custos::SessionManager.find_by_token(token) if token
    end

    private

    def resolve_custos_session(scope)
      token = extract_custos_token
      return nil unless token

      model_class = Custos.configuration.model_class_for_scope(scope)
      Custos::SessionManager.find_by_token(token, authenticatable_type: model_class&.name)
    end

    def extract_custos_token
      cookies.signed[:custos_session_token] ||
        request.headers['Authorization']&.delete_prefix('Bearer ')
    end
  end
end
