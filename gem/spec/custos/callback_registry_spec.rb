# frozen_string_literal: true

RSpec.describe Custos::CallbackRegistry do
  describe '.fire' do
    it 'calls registered callbacks' do
      called_with = nil
      TestUser.custos_config.on(:test_event) { |arg| called_with = arg }

      described_class.fire(TestUser, :test_event, 'hello')
      expect(called_with).to eq('hello')
    end

    it 'does nothing for unregistered events' do
      expect { described_class.fire(TestUser, :unknown_event, 'data') }.not_to raise_error
    end

    it 'isolates callback errors and continues with :log strategy' do
      results = []
      TestUser.custos_config.on(:error_test) { raise 'boom' }
      TestUser.custos_config.on(:error_test) { results << :second_called }

      expect { described_class.fire(TestUser, :error_test) }.not_to raise_error
      expect(results).to eq([:second_called])
    end

    it 'raises callback errors with :raise strategy' do
      original = Custos.configuration.callback_error_strategy
      Custos.configuration.callback_error_strategy = :raise

      TestUser.custos_config.on(:raise_test) { raise 'boom' }

      expect { described_class.fire(TestUser, :raise_test) }.to raise_error(RuntimeError, 'boom')
    ensure
      Custos.configuration.callback_error_strategy = original
    end

    it 'returns nil when model has no config' do
      klass = Class.new(ActiveRecord::Base) do
        self.table_name = 'test_users'

        def self.custos_config
          nil
        end
      end

      expect(described_class.fire(klass, :some_event)).to be_nil
    end
  end

  describe '.fire_hooks' do
    it 'calls registered hooks' do
      called_with = nil
      TestUser.custos_config.hook(:internal_event) { |arg| called_with = arg }

      described_class.fire_hooks(TestUser, :internal_event, 'hook_data')
      expect(called_with).to eq('hook_data')
    end

    it 'does not rescue hook errors (hooks are internal)' do
      TestUser.custos_config.hook(:failing_hook) { raise 'internal_error' }

      expect { described_class.fire_hooks(TestUser, :failing_hook) }.to raise_error(RuntimeError, 'internal_error')
    end
  end
end
