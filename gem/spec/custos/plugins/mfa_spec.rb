# frozen_string_literal: true

RSpec.describe Custos::Plugins::Mfa do
  let(:user) { TestUser.create!(email: 'mfa@example.com', password: 'securepass1') }

  describe 'TOTP' do
    it 'setup_totp returns a provisioning URI' do
      uri = user.setup_totp
      expect(uri).to include('otpauth://totp/')
    end

    it 'confirm_totp! enables TOTP with valid code' do
      user.setup_totp
      credential = user.custos_mfa_credentials.by_method('totp').first
      totp = ROTP::TOTP.new(credential.secret_data)
      code = totp.now

      expect(user.confirm_totp!(code)).to be true
      expect(user.totp_enabled?).to be true
    end

    it 'verify_totp returns true for valid code' do
      user.setup_totp
      credential = user.custos_mfa_credentials.by_method('totp').first
      totp = ROTP::TOTP.new(credential.secret_data)
      credential.update!(enabled_at: Time.current)

      expect(user.verify_totp(totp.now)).to be true
    end

    it 'verify_totp returns false for invalid code' do
      user.setup_totp
      user.custos_mfa_credentials.by_method('totp').first.update!(enabled_at: Time.current)

      expect(user.verify_totp('000000')).to be false
    end

    it 'verify_totp returns false when MFA locked' do
      user.setup_totp
      credential = user.custos_mfa_credentials.by_method('totp').first
      credential.update!(enabled_at: Time.current)
      user.update!(mfa_locked_at: Time.current)

      totp = ROTP::TOTP.new(credential.secret_data)
      expect(user.verify_totp(totp.now)).to be false
    end

    it 'fires after_mfa_verification hook on verify_totp' do
      user.setup_totp
      credential = user.custos_mfa_credentials.by_method('totp').first
      credential.update!(enabled_at: Time.current)

      hook_args = []
      TestUser.custos_config.hook(:after_mfa_verification) { |record, success| hook_args = [record, success] }

      user.verify_totp('000000')
      expect(hook_args).to eq([user, false])
    end
  end

  describe 'Backup Codes' do
    it 'generate_backup_codes returns array of codes' do
      codes = user.generate_backup_codes(count: 5)
      expect(codes.size).to eq(5)
    end

    it 'generates codes with sufficient entropy (12 hex chars = 48 bits)' do
      codes = user.generate_backup_codes(count: 1)
      expect(codes.first).to match(/\A[a-f0-9]{12}\z/)
    end

    it 'verify_backup_code consumes a valid code' do
      codes = user.generate_backup_codes(count: 3)
      expect(user.verify_backup_code(codes.first)).to be true
      expect(user.verify_backup_code(codes.first)).to be false
    end

    it 'verify_backup_code rejects invalid code' do
      user.generate_backup_codes(count: 3)
      expect(user.verify_backup_code('invalid')).to be false
    end

    it 'verify_backup_code returns false when MFA locked' do
      codes = user.generate_backup_codes(count: 3)
      user.update!(mfa_locked_at: Time.current)

      expect(user.verify_backup_code(codes.first)).to be false
    end

    it 'handles corrupted JSON gracefully' do
      codes = user.generate_backup_codes(count: 1)
      user.custos_mfa_credentials.by_method('backup_codes').first.update_column(:secret_data, 'not_json')
      expect(user.verify_backup_code(codes.first)).to be false
    end
  end

  describe 'SMS' do
    it 'send_sms_code fires callback' do
      callback_args = nil
      TestUser.custos_config.on(:sms_code_created) { |*args| callback_args = args }

      user.send_sms_code
      expect(callback_args).not_to be_nil
      expect(callback_args.last).to match(/\A\d{6}\z/)
    end

    it 'verify_sms_code returns true for valid code' do
      sent_code = nil
      TestUser.custos_config.on(:sms_code_created) { |_record, code| sent_code = code }

      user.send_sms_code
      expect(user.verify_sms_code(sent_code)).to be true
    end

    it 'verify_sms_code returns false for expired code' do
      sent_code = nil
      TestUser.custos_config.on(:sms_code_created) { |_record, code| sent_code = code }

      user.send_sms_code
      credential = user.custos_mfa_credentials.by_method('sms').first
      data = JSON.parse(credential.secret_data)
      data['expires_at'] = 1.hour.ago.iso8601
      credential.update!(secret_data: JSON.generate(data))

      expect(user.verify_sms_code(sent_code)).to be false
    end

    it 'invalidates SMS credential after successful verification' do
      sent_code = nil
      TestUser.custos_config.on(:sms_code_created) { |_record, code| sent_code = code }

      user.send_sms_code
      user.verify_sms_code(sent_code)

      expect(user.verify_sms_code(sent_code)).to be false
    end

    it 'verify_sms_code returns false when MFA locked' do
      sent_code = nil
      TestUser.custos_config.on(:sms_code_created) { |_record, code| sent_code = code }

      user.send_sms_code
      user.update!(mfa_locked_at: Time.current)

      expect(user.verify_sms_code(sent_code)).to be false
    end

    it 'handles corrupted JSON gracefully' do
      user.send_sms_code
      user.custos_mfa_credentials.by_method('sms').first.update_column(:secret_data, 'not_json')

      expect(user.verify_sms_code('123456')).to be false
    end
  end

  describe '#mfa_enabled?' do
    it 'returns false when no MFA is set up' do
      expect(user.mfa_enabled?).to be false
    end

    it 'returns true when TOTP is enabled' do
      user.setup_totp
      user.custos_mfa_credentials.by_method('totp').first.update!(enabled_at: Time.current)
      expect(user.mfa_enabled?).to be true
    end
  end
end
