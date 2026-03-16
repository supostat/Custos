# frozen_string_literal: true

RSpec.describe Custos::Plugins::Lockout do
  let(:user) { TestUser.create!(email: 'lock@example.com', password: 'securepass1') }

  describe '#locked?' do
    it 'returns false by default' do
      expect(user.locked?).to be false
    end

    it 'returns true when locked_at is recent' do
      user.update!(locked_at: Time.current)
      expect(user.locked?).to be true
    end

    it 'returns false when lockout duration has passed' do
      user.update!(locked_at: 31.minutes.ago)
      expect(user.locked?).to be false
    end
  end

  describe '#record_failed_attempt!' do
    it 'increments failed_auth_count' do
      expect { user.record_failed_attempt! }
        .to change { user.reload.failed_auth_count }.by(1)
    end

    it 'locks account after max attempts atomically' do
      3.times { user.record_failed_attempt! }
      expect(user.reload.locked?).to be true
    end

    it 'does not lock before reaching max attempts' do
      2.times { user.record_failed_attempt! }
      expect(user.reload.locked?).to be false
    end
  end

  describe '#reset_failed_attempts!' do
    it 'resets counter and locked_at' do
      3.times { user.record_failed_attempt! }
      user.reset_failed_attempts!

      expect(user.reload.failed_auth_count).to eq(0)
      expect(user.locked_at).to be_nil
    end
  end

  describe '#unlock!' do
    it 'unlocks the account and resets MFA lockout' do
      user.update!(locked_at: Time.current, failed_auth_count: 3,
                   mfa_locked_at: Time.current, failed_mfa_count: 5)
      user.unlock!

      user.reload
      expect(user.locked?).to be false
      expect(user.failed_auth_count).to eq(0)
      expect(user.mfa_locked?).to be false
      expect(user.failed_mfa_count).to eq(0)
    end
  end

  describe 'MFA lockout' do
    describe '#mfa_locked?' do
      it 'returns false by default' do
        expect(user.mfa_locked?).to be false
      end

      it 'returns true when mfa_locked_at is recent' do
        user.update!(mfa_locked_at: Time.current)
        expect(user.mfa_locked?).to be true
      end

      it 'returns false when MFA lockout duration has passed' do
        user.update!(mfa_locked_at: 31.minutes.ago)
        expect(user.mfa_locked?).to be false
      end
    end

    describe '#record_failed_mfa_attempt!' do
      it 'increments failed_mfa_count' do
        expect { user.record_failed_mfa_attempt! }
          .to change { user.reload.failed_mfa_count }.by(1)
      end

      it 'locks MFA after max attempts atomically' do
        5.times { user.record_failed_mfa_attempt! }
        expect(user.reload.mfa_locked?).to be true
      end

      it 'does not lock MFA before reaching max attempts' do
        4.times { user.record_failed_mfa_attempt! }
        expect(user.reload.mfa_locked?).to be false
      end
    end

    describe '#reset_failed_mfa_attempts!' do
      it 'resets MFA counter and mfa_locked_at' do
        5.times { user.record_failed_mfa_attempt! }
        user.reset_failed_mfa_attempts!

        expect(user.reload.failed_mfa_count).to eq(0)
        expect(user.mfa_locked_at).to be_nil
      end
    end
  end

  describe 'integration with password' do
    it 'records failed attempt on wrong password' do
      user.authenticate_password('wrong')
      expect(user.reload.failed_auth_count).to eq(1)
    end

    it 'resets counter on correct password' do
      user.update!(failed_auth_count: 2)
      user.authenticate_password('securepass1')
      expect(user.reload.failed_auth_count).to eq(0)
    end
  end
end
