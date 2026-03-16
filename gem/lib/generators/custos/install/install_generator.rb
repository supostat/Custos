# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/active_record'

module Custos
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path('templates', __dir__)

      def create_initializer
        template 'custos_initializer.rb.tt', 'config/initializers/custos.rb'
      end

      def create_sessions_migration
        migration_template 'create_custos_sessions.rb.tt',
                           'db/migrate/create_custos_sessions.rb'
      end
    end
  end
end
