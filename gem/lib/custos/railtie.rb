# frozen_string_literal: true

module Custos
  class Railtie < Rails::Railtie
    initializer 'custos.controller_helpers' do
      ActiveSupport.on_load(:action_controller) do
        include Custos::ControllerHelpers
      end
    end

    rake_tasks do
      load 'custos/tasks/cleanup.rake'
    end
  end
end
