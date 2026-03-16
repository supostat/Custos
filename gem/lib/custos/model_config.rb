# frozen_string_literal: true

module Custos
  class ModelConfig
    attr_reader :model_class, :loaded_plugins, :callbacks, :hooks

    def initialize(model_class)
      @model_class = model_class
      @loaded_plugins = {}
      @callbacks = Hash.new { |hash, key| hash[key] = [] }
      @hooks = Hash.new { |hash, key| hash[key] = [] }
    end

    def plugin(name, **options)
      mod = Custos::Plugin.resolve(name)
      mod.apply(@model_class, **options)
      @loaded_plugins[name.to_sym] = options
    end

    def on(event_name, &block)
      @callbacks[event_name.to_sym] << block
    end

    def hook(event_name, &block)
      @hooks[event_name.to_sym] << block
    end

    def plugin_enabled?(name)
      @loaded_plugins.key?(name.to_sym)
    end

    def plugin_options(name)
      @loaded_plugins.fetch(name.to_sym) { raise Custos::UnknownPluginError, "Plugin #{name} is not loaded" }
    end
  end
end
