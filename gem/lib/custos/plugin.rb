# frozen_string_literal: true

module Custos
  module Plugin
    @registry = {}

    class << self
      def register(name, mod)
        @registry[name.to_sym] = mod
      end

      def resolve(name)
        @registry.fetch(name.to_sym) do
          raise Custos::UnknownPluginError, "Unknown plugin: #{name}"
        end
      end

      def registered?(name)
        @registry.key?(name.to_sym)
      end

      def registered_names
        @registry.keys
      end
    end
  end
end
