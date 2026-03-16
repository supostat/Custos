# frozen_string_literal: true

RSpec.describe Custos::Plugin do
  describe '.register and .resolve' do
    it 'registers and resolves a plugin' do
      fake_plugin = Module.new
      described_class.register(:test_plugin, fake_plugin)
      expect(described_class.resolve(:test_plugin)).to eq(fake_plugin)
    end
  end

  describe '.resolve with unknown plugin' do
    it 'raises UnknownPluginError' do
      expect { described_class.resolve(:nonexistent) }
        .to raise_error(Custos::UnknownPluginError, /nonexistent/)
    end
  end

  describe '.registered?' do
    it 'returns true for registered plugins' do
      expect(described_class.registered?(:password)).to be true
    end

    it 'returns false for unregistered plugins' do
      expect(described_class.registered?(:unknown)).to be false
    end
  end

  describe '.registered_names' do
    it 'includes all built-in plugins' do
      names = described_class.registered_names
      expect(names).to include(:password, :magic_link, :api_tokens, :mfa,
                               :lockout, :email_confirmation, :remember_me)
    end
  end
end
