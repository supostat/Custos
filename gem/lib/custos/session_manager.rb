# frozen_string_literal: true

module Custos
  class SessionManager
    class << self
      def create(authenticatable, request:)
        token = TokenGenerator.generate
        session = Custos::Session.create!(
          authenticatable: authenticatable,
          session_token_digest: TokenGenerator.digest(token),
          ip_address: request.remote_ip,
          user_agent: request.user_agent,
          last_active_at: Time.current
        )
        [session, token]
      end

      def find_by_token(token, authenticatable_type: nil)
        return nil if token.blank?

        digest = TokenGenerator.digest(token)
        scope = Custos::Session.active.where(session_token_digest: digest)
        scope = scope.where(authenticatable_type: authenticatable_type) if authenticatable_type
        session = scope.first
        touch_session(session) if session
        session
      end

      def revoke(session)
        session.update!(revoked_at: Time.current)
      end

      def revoke_all(authenticatable)
        authenticatable.custos_sessions.active.update_all(revoked_at: Time.current)
      end

      def active_for(authenticatable)
        authenticatable.custos_sessions.active.order(last_active_at: :desc)
      end

      private

      def touch_session(session)
        renewal = Custos.configuration.session_renewal_interval
        return if session.last_active_at > renewal.seconds.ago

        session.update_column(:last_active_at, Time.current)
      end
    end
  end
end
