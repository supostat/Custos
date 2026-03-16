# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/active_record'

module Custos
  module Generators
    class ModelGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      KNOWN_PLUGINS = %w[password magic_link api_tokens mfa lockout email_confirmation remember_me].freeze

      source_root File.expand_path('templates', __dir__)

      argument :model_name, type: :string, desc: 'Model name (e.g. User)'
      argument :plugins, type: :array, default: [], banner: 'plugin1 plugin2'

      def validate_plugins
        unknown = plugins.map(&:to_s) - KNOWN_PLUGINS
        return if unknown.empty?

        raise Thor::Error, "Unknown plugin(s): #{unknown.join(', ')}. " \
                           "Available: #{KNOWN_PLUGINS.join(', ')}"
      end

      def create_column_migration
        columns = column_plugins & plugins.map(&:to_s)
        return if columns.empty?

        migration_template 'add_custos_columns.rb.tt',
                           "db/migrate/add_custos_to_#{table_name}.rb"
      end

      def create_magic_links_migration
        return unless plugins.include?('magic_link')

        migration_template 'create_custos_magic_links.rb.tt',
                           'db/migrate/create_custos_magic_links.rb'
      end

      def create_api_tokens_migration
        return unless plugins.include?('api_tokens')

        migration_template 'create_custos_api_tokens.rb.tt',
                           'db/migrate/create_custos_api_tokens.rb'
      end

      def create_mfa_credentials_migration
        return unless plugins.include?('mfa')

        migration_template 'create_custos_mfa_credentials.rb.tt',
                           'db/migrate/create_custos_mfa_credentials.rb'
      end

      def create_remember_tokens_migration
        return unless plugins.include?('remember_me')

        migration_template 'create_custos_remember_tokens.rb.tt',
                           'db/migrate/create_custos_remember_tokens.rb'
      end

      private

      def table_name
        model_name.underscore.tr('/', '_').pluralize
      end

      def migration_class_suffix
        model_name.camelize.delete(':').pluralize
      end

      def column_plugins
        %w[password lockout email_confirmation]
      end

      def has_password?
        plugins.include?('password')
      end

      def has_lockout?
        plugins.include?('lockout')
      end

      def has_email_confirmation?
        plugins.include?('email_confirmation')
      end
    end
  end
end
