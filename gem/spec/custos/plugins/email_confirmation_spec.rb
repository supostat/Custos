# frozen_string_literal: true

RSpec.describe Custos::Plugins::EmailConfirmation do
  let(:user) { TestUser.create!(email: 'confirm@example.com', password: 'securepass1') }

  describe '#send_email_confirmation' do
    it 'sets confirmation token digest and sent_at' do
      user.send_email_confirmation

      expect(user.email_confirmation_token_digest).to be_present
      expect(user.email_confirmation_sent_at).to be_present
    end

    it 'fires email_confirmation_requested callback' do
      callback_args = nil
      TestUser.custos_config.on(:email_confirmation_requested) { |*args| callback_args = args }

      user.send_email_confirmation
      expect(callback_args).not_to be_nil
      expect(callback_args.first).to eq(user)
    end

    it 'returns the plain token' do
      token = user.send_email_confirmation
      expect(token).to be_present
    end
  end

  describe '#confirm_email!' do
    it 'confirms with valid token' do
      token = user.send_email_confirmation
      expect(user.confirm_email!(token)).to be true
      expect(user.email_confirmed?).to be true
    end

    it 'rejects invalid token' do
      user.send_email_confirmation
      expect(user.confirm_email!('bogus')).to be false
    end

    it 'clears confirmation token after confirmation' do
      token = user.send_email_confirmation
      user.confirm_email!(token)
      expect(user.email_confirmation_token_digest).to be_nil
    end

    it 'rejects expired token' do
      token = user.send_email_confirmation
      user.update_column(:email_confirmation_sent_at, 25.hours.ago)

      expect(user.confirm_email!(token)).to be false
    end
  end

  describe '#email_confirmed?' do
    it 'returns false by default' do
      expect(user.email_confirmed?).to be false
    end
  end
end
