# frozen_string_literal: true

RSpec.describe Custos::Configuration do
  subject(:config) { described_class.new }

  it 'has default session_expiry of 24 hours' do
    expect(config.session_expiry).to eq(24 * 60 * 60)
  end

  it 'has default session_renewal_interval of 1 hour' do
    expect(config.session_renewal_interval).to eq(60 * 60)
  end

  it 'has default token_length of 32' do
    expect(config.token_length).to eq(32)
  end

  it 'has default empty scope_map' do
    expect(config.scope_map).to eq({})
  end

  it 'has default nil token_secret' do
    expect(config.token_secret).to be_nil
  end

  it 'has default nil mfa_encryption_key' do
    expect(config.mfa_encryption_key).to be_nil
  end

  it 'has default :log callback_error_strategy' do
    expect(config.callback_error_strategy).to eq(:log)
  end

  it 'allows overriding values' do
    config.session_expiry = 3600
    config.token_length = 64
    expect(config.session_expiry).to eq(3600)
    expect(config.token_length).to eq(64)
  end

  describe '#model_class_for_scope' do
    it 'resolves from scope_map when configured' do
      config.scope_map = { user: 'TestUser' }
      expect(config.model_class_for_scope(:user)).to eq(TestUser)
    end

    it 'returns nil when scope not in scope_map' do
      expect(config.model_class_for_scope(:test_user)).to be_nil
    end

    it 'returns nil for unknown class in scope_map' do
      config.scope_map = { bad: 'NonexistentModel' }
      expect(config.model_class_for_scope(:bad)).to be_nil
    end

    it 'rejects invalid class names to prevent code injection' do
      config.scope_map = { evil: 'system("whoami")' }
      expect(config.model_class_for_scope(:evil)).to be_nil
    end

    it 'accepts namespaced class names like A::B' do
      config.scope_map = { admin: 'TestUser' }
      expect(config.model_class_for_scope(:admin)).to eq(TestUser)
    end
  end
end

RSpec.describe Custos do
  after do
    described_class.reset_configuration!
    described_class.configuration.token_secret = 'test-secret-key-for-custos-specs'
  end

  describe '.configure' do
    it 'yields configuration' do
      described_class.configure do |config|
        config.session_expiry = 7200
      end

      expect(described_class.configuration.session_expiry).to eq(7200)
    end
  end

  describe '.reset_configuration!' do
    it 'restores defaults' do
      described_class.configure { |c| c.token_length = 64 }
      described_class.reset_configuration!
      expect(described_class.configuration.token_length).to eq(32)
    end
  end
end
