# frozen_string_literal: true

module Custos
  module Plugin
    @registry = {}
    @mutex = Mutex.new

    class << self
      def register(name, mod)
        @mutex.synchronize { @registry[name.to_sym] = mod }
      end

      def resolve(name)
        @mutex.synchronize do
          @registry.fetch(name.to_sym) do
            raise Custos::UnknownPluginError, "Unknown plugin: #{name}"
          end
        end
      end

      def registered?(name)
        @mutex.synchronize { @registry.key?(name.to_sym) }
      end

      def registered_names
        @mutex.synchronize { @registry.keys }
      end
    end
  end
end
