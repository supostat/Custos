# frozen_string_literal: true

RSpec.describe Custos::Plugins::MagicLink do
  let!(:user) { TestUser.create!(email: 'magic@example.com', password: 'securepass1') }

  describe '.generate_magic_link' do
    it 'returns a token for existing email' do
      token = TestUser.generate_magic_link('magic@example.com')
      expect(token).to be_present
    end

    it 'returns nil for nonexistent email' do
      expect(TestUser.generate_magic_link('no@example.com')).to be_nil
    end

    it 'creates a MagicLinkToken record' do
      expect { TestUser.generate_magic_link('magic@example.com') }
        .to change(Custos::MagicLinkToken, :count).by(1)
    end

    it 'fires magic_link_created callback' do
      callback_args = nil
      TestUser.custos_config.on(:magic_link_created) { |*args| callback_args = args }

      TestUser.generate_magic_link('magic@example.com')
      expect(callback_args).not_to be_nil
      expect(callback_args.first).to eq(user)
    end
  end

  describe '.authenticate_magic_link' do
    it 'returns user for valid token' do
      token = TestUser.generate_magic_link('magic@example.com')
      found = TestUser.authenticate_magic_link(token)
      expect(found).to eq(user)
    end

    it 'marks token as used' do
      token = TestUser.generate_magic_link('magic@example.com')
      TestUser.authenticate_magic_link(token)

      expect(TestUser.authenticate_magic_link(token)).to be_nil
    end

    it 'returns nil for expired token' do
      token = TestUser.generate_magic_link('magic@example.com')
      Custos::MagicLinkToken.update_all(expires_at: 1.hour.ago)

      expect(TestUser.authenticate_magic_link(token)).to be_nil
    end

    it 'returns nil for invalid token' do
      expect(TestUser.authenticate_magic_link('bogus')).to be_nil
    end
  end
end
