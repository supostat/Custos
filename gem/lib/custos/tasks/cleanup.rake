# frozen_string_literal: true

namespace :custos do
  desc 'Remove expired sessions, used magic links, and expired tokens'
  task cleanup: :environment do
    deleted = Custos::Session.where(created_at: ..Custos.configuration.session_expiry.seconds.ago).delete_all
    puts "Deleted #{deleted} expired sessions"

    deleted = Custos::Session.revoked.where(revoked_at: ..30.days.ago).delete_all
    puts "Deleted #{deleted} old revoked sessions"

    if defined?(Custos::MagicLinkToken)
      deleted = Custos::MagicLinkToken.where.not(used_at: nil).delete_all
      deleted += Custos::MagicLinkToken.where(expires_at: ..Time.current).delete_all
      puts "Deleted #{deleted} used/expired magic links"
    end

    if defined?(Custos::RememberToken)
      deleted = Custos::RememberToken.where(expires_at: ..Time.current).delete_all
      puts "Deleted #{deleted} expired remember tokens"
    end

    if defined?(Custos::ApiToken)
      deleted = Custos::ApiToken.where.not(expires_at: nil).where(expires_at: ..Time.current).delete_all
      puts "Deleted #{deleted} expired API tokens"
    end
  end
end
