# frozen_string_literal: true

RSpec.describe Custos::TokenGenerator do
  describe '.generate' do
    it 'returns a url-safe string' do
      token = described_class.generate
      expect(token).to match(/\A[A-Za-z0-9_-]+={0,2}\z/)
    end

    it 'generates unique tokens' do
      tokens = Array.new(100) { described_class.generate }
      expect(tokens.uniq.size).to eq(100)
    end

    it 'respects custom byte_length' do
      short = described_class.generate(byte_length: 8)
      long = described_class.generate(byte_length: 64)
      expect(long.length).to be > short.length
    end
  end

  describe '.digest' do
    it 'returns an HMAC-SHA256 hex digest' do
      digest = described_class.digest('test_token')
      expect(digest).to match(/\A[a-f0-9]{64}\z/)
    end

    it 'is deterministic' do
      expect(described_class.digest('abc')).to eq(described_class.digest('abc'))
    end

    it 'produces different digests with different secrets' do
      digest_a = described_class.digest('token')

      original_secret = Custos.configuration.token_secret
      Custos.configuration.token_secret = 'different-secret'
      digest_b = described_class.digest('token')
      Custos.configuration.token_secret = original_secret

      expect(digest_a).not_to eq(digest_b)
    end

    it 'raises when no token_secret is configured' do
      original_secret = Custos.configuration.token_secret
      Custos.configuration.token_secret = nil

      expect { described_class.digest('token') }.to raise_error(Custos::Error, /token_secret/)
    ensure
      Custos.configuration.token_secret = original_secret
    end
  end

  describe '.secure_compare' do
    it 'returns true for equal strings' do
      expect(described_class.secure_compare('abc', 'abc')).to be true
    end

    it 'returns false for different strings' do
      expect(described_class.secure_compare('abc', 'def')).to be false
    end
  end
end
