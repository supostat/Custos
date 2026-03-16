# frozen_string_literal: true

require 'active_support/concern'

module Custos
  module Authenticatable
    extend ActiveSupport::Concern

    included do
      has_many :custos_sessions,
               class_name: 'Custos::Session',
               as: :authenticatable,
               dependent: :destroy
    end

    class_methods do
      def custos(&block)
        @custos_config = Custos::ModelConfig.new(self)
        @custos_config.instance_eval(&block)
        @custos_config
      end

      def custos_config
        return @custos_config if instance_variable_defined?(:@custos_config)

        superclass.custos_config if superclass.respond_to?(:custos_config)
      end
    end
  end
end
