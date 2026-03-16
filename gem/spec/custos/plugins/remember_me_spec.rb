# frozen_string_literal: true

RSpec.describe Custos::Plugins::RememberMe do
  let(:user) { TestUser.create!(email: 'remember@example.com', password: 'securepass1') }

  describe '#generate_remember_token' do
    it 'returns a plain token' do
      token = user.generate_remember_token
      expect(token).to be_present
    end

    it 'creates a RememberToken record' do
      expect { user.generate_remember_token }
        .to change(Custos::RememberToken, :count).by(1)
    end

    it 'sets expires_at based on configured duration' do
      user.generate_remember_token
      remember = user.custos_remember_tokens.last
      expect(remember.expires_at).to be > 29.days.from_now
    end
  end

  describe '.authenticate_remember_token' do
    it 'returns user for valid token' do
      token = user.generate_remember_token
      found = TestUser.authenticate_remember_token(token)
      expect(found).to eq(user)
    end

    it 'returns nil for expired token' do
      token = user.generate_remember_token
      Custos::RememberToken.update_all(expires_at: 1.day.ago)

      expect(TestUser.authenticate_remember_token(token)).to be_nil
    end

    it 'returns nil for invalid token' do
      expect(TestUser.authenticate_remember_token('bogus')).to be_nil
    end
  end

  describe '#forget_me!' do
    it 'destroys all remember tokens when called without argument' do
      user.generate_remember_token
      user.generate_remember_token
      user.forget_me!

      expect(user.custos_remember_tokens).to be_empty
    end

    it 'destroys only the specified token when called with token' do
      token1 = user.generate_remember_token
      user.generate_remember_token

      user.forget_me!(token1)
      expect(user.custos_remember_tokens.count).to eq(1)
    end
  end
end
