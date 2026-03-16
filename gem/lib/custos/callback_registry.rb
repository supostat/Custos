# frozen_string_literal: true

module Custos
  class CallbackRegistry
    def self.fire(model_class, event_name, *args)
      config = model_class.custos_config
      return unless config

      config.callbacks[event_name].each do |callback|
        callback.call(*args)
      rescue StandardError => e
        handle_callback_error(event_name, e)
      end
    end

    def self.fire_hooks(model_class, event_name, *args)
      config = model_class.custos_config
      return unless config

      config.hooks[event_name].each { |hook| hook.call(*args) }
    end

    def self.handle_callback_error(event_name, error)
      strategy = Custos.configuration.callback_error_strategy

      raise error if strategy == :raise

      if defined?(Rails.logger)
        Rails.logger.error "[Custos] Callback error on #{event_name}: #{error.message}"
      else
        warn "[Custos] Callback error on #{event_name}: #{error.message}"
      end
    end

    private_class_method :handle_callback_error
  end
end
