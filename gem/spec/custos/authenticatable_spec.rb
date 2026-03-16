# frozen_string_literal: true

RSpec.describe Custos::Authenticatable do
  describe 'custos_config' do
    it 'is available on the model class' do
      expect(TestUser.custos_config).to be_a(Custos::ModelConfig)
    end

    it 'tracks loaded plugins' do
      expect(TestUser.custos_config.plugin_enabled?(:password)).to be true
      expect(TestUser.custos_config.plugin_enabled?(:api_tokens)).to be false
    end

    it 'is inherited by STI subclasses' do
      expect(TestAdmin.custos_config).to eq(TestUser.custos_config)
    end
  end

  describe 'custos_sessions association' do
    it 'is defined' do
      user = TestUser.create!(email: 'test@example.com', password: 'securepass1')
      expect(user).to respond_to(:custos_sessions)
    end
  end
end
