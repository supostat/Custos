# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "action_mailer/railtie"

Bundler.require(*Rails.groups)

module CustosExample
  class Application < Rails::Application
    config.load_defaults 7.1

    config.eager_load = false
    config.action_mailer.delivery_method = :logger
    config.active_record.encryption.primary_key = "test-primary-key-for-dev-only"
    config.active_record.encryption.deterministic_key = "test-deterministic-key-dev"
    config.active_record.encryption.key_derivation_salt = "test-key-derivation-salt-dev"
  end
end
