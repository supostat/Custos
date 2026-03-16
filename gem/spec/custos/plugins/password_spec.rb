# frozen_string_literal: true

RSpec.describe Custos::Plugins::Password do
  let!(:user) { TestUser.create!(email: 'pwd@example.com', password: 'securepass1') }

  describe '#password=' do
    it 'sets password_digest' do
      expect(user.password_digest).to be_present
      expect(user.password_digest).not_to eq('securepass1')
    end
  end

  describe '#authenticate_password' do
    it 'returns true for correct password' do
      expect(user.authenticate_password('securepass1')).to be true
    end

    it 'returns false for incorrect password' do
      expect(user.authenticate_password('wrong')).to be false
    end

    it 'returns false when password_digest is blank' do
      user.update_column(:password_digest, nil)
      expect(user.authenticate_password('anything')).to be false
    end

    it 'fires after_authentication hook' do
      hook_args = []
      TestUser.custos_config.hook(:after_authentication) { |record, success| hook_args = [record, success] }

      user.authenticate_password('securepass1')
      expect(hook_args).to eq([user, true])
    end

    it 'returns false for corrupted password_digest' do
      user.update_column(:password_digest, 'not_a_valid_argon2_hash')
      expect(user.authenticate_password('securepass1')).to be false
    end
  end

  describe 'password cleanup after save' do
    it 'clears @password ivar after save' do
      new_user = TestUser.new(email: 'cleanup@example.com', password: 'securepass1')
      new_user.save!

      expect(new_user.password).to be_nil
    end
  end

  describe '.find_by_email_and_password' do
    it 'returns user with correct credentials' do
      found = TestUser.find_by_email_and_password(email: 'pwd@example.com', password: 'securepass1')
      expect(found).to eq(user)
    end

    it 'returns nil with wrong password' do
      found = TestUser.find_by_email_and_password(email: 'pwd@example.com', password: 'wrong')
      expect(found).to be_nil
    end

    it 'returns nil for nonexistent email' do
      found = TestUser.find_by_email_and_password(email: 'no@example.com', password: 'securepass1')
      expect(found).to be_nil
    end

    it 'performs dummy Argon2 verify for nonexistent email (timing protection)' do
      allow(Argon2::Password).to receive(:verify_password).and_call_original

      TestUser.find_by_email_and_password(email: 'no@example.com', password: 'securepass1')

      expect(Argon2::Password).to have_received(:verify_password)
        .with('securepass1', Custos::Plugins::Password::DUMMY_PASSWORD_DIGEST)
    end

    it 'returns nil for locked user' do
      user.update!(locked_at: Time.current)
      found = TestUser.find_by_email_and_password(email: 'pwd@example.com', password: 'securepass1')
      expect(found).to be_nil
    end
  end

  describe 'password complexity validation' do
    it 'rejects passwords shorter than minimum' do
      user = TestUser.new(email: 'short@example.com', password: 'short')
      expect(user).not_to be_valid
    end
  end
end
