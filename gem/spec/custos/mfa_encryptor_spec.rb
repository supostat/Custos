# frozen_string_literal: true

RSpec.describe Custos::MfaEncryptor do
  around do |example|
    original = Custos.configuration.mfa_encryption_key
    example.run
    Custos.configuration.mfa_encryption_key = original
  end

  describe 'without encryption key' do
    before { Custos.configuration.mfa_encryption_key = nil }

    it 'returns plaintext as-is on encrypt' do
      expect(described_class.encrypt('secret')).to eq('secret')
    end

    it 'returns ciphertext as-is on decrypt' do
      expect(described_class.decrypt('secret')).to eq('secret')
    end
  end

  describe 'with encryption key' do
    before { Custos.configuration.mfa_encryption_key = 'test-encryption-key' }

    it 'encrypts with enc: prefix' do
      encrypted = described_class.encrypt('totp-secret')
      expect(encrypted).to start_with('enc:')
      expect(encrypted).not_to include('totp-secret')
    end

    it 'decrypts back to original plaintext' do
      encrypted = described_class.encrypt('totp-secret')
      expect(described_class.decrypt(encrypted)).to eq('totp-secret')
    end

    it 'produces different ciphertext for same plaintext' do
      encrypted_a = described_class.encrypt('same')
      encrypted_b = described_class.encrypt('same')
      expect(encrypted_a).not_to eq(encrypted_b)
    end

    it 'returns plaintext as-is when no enc: prefix (backward compat)' do
      expect(described_class.decrypt('old-plaintext-secret')).to eq('old-plaintext-secret')
    end

    it 'returns corrupted ciphertext as-is on decryption failure' do
      expect(described_class.decrypt('enc:not-valid-base64!!!')).to eq('enc:not-valid-base64!!!')
    end

    it 'handles JSON data correctly' do
      json = JSON.generate({ digest: 'abc123', expires_at: '2024-01-01T00:00:00Z' })
      encrypted = described_class.encrypt(json)
      decrypted = described_class.decrypt(encrypted)

      expect(JSON.parse(decrypted)).to eq(JSON.parse(json))
    end
  end
end
