# frozen_string_literal: true

RSpec.describe Custos::ModelConfig do
  subject(:config) { TestUser.custos_config }

  describe '#plugin_enabled?' do
    it 'returns true for loaded plugins' do
      expect(config.plugin_enabled?(:password)).to be true
    end

    it 'returns false for unloaded plugins' do
      expect(config.plugin_enabled?(:api_tokens)).to be false
    end
  end

  describe '#plugin_options' do
    it 'returns options for loaded plugin' do
      expect(config.plugin_options(:password)).to be_a(Hash)
    end

    it 'raises for unknown plugin' do
      expect { config.plugin_options(:nonexistent) }
        .to raise_error(Custos::UnknownPluginError, /nonexistent/)
    end
  end

  describe '#hooks' do
    it 'stores internal hooks separate from callbacks' do
      hook_called = false
      config.hook(:test_hook) { hook_called = true }

      expect(config.hooks[:test_hook].size).to be >= 1
      expect(config.callbacks[:test_hook]).to be_empty
    end
  end

  describe '#on' do
    it 'registers user callbacks' do
      config.on(:user_event) { 'callback' }
      expect(config.callbacks[:user_event].size).to be >= 1
    end
  end
end
