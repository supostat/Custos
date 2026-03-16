# frozen_string_literal: true

require 'active_support'
require 'active_record'

require 'custos/version'
require 'custos/configuration'
require 'custos/plugin'
require 'custos/callback_registry'
require 'custos/token_generator'
require 'custos/authenticatable'
require 'custos/model_config'
require 'custos/session'
require 'custos/session_manager'
require 'custos/controller_helpers'
require 'custos/mfa_encryptor'

require 'custos/models/magic_link_token'
require 'custos/models/api_token'
require 'custos/models/mfa_credential'
require 'custos/models/remember_token'

require 'custos/plugins/password'
require 'custos/plugins/magic_link'
require 'custos/plugins/api_tokens'
require 'custos/plugins/mfa'
require 'custos/plugins/lockout'
require 'custos/plugins/email_confirmation'
require 'custos/plugins/remember_me'

require 'custos/railtie' if defined?(Rails::Railtie)

module Custos
  class Error < StandardError; end
  class UnknownPluginError < Error; end
  class NotAuthenticatedError < Error; end
  class DecryptionError < Error; end

  @mutex = Mutex.new

  class << self
    def configure
      yield configuration
    end

    def configuration
      @mutex.synchronize { @configuration ||= Configuration.new }
    end

    def reset_configuration!
      @mutex.synchronize { @configuration = Configuration.new }
    end
  end
end
