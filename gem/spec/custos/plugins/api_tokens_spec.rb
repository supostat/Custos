# frozen_string_literal: true

RSpec.describe Custos::Plugins::ApiTokens do
  let(:client) { TestApiClient.create!(name: 'Test Client') }

  describe '#generate_api_token' do
    it 'returns a plain token' do
      token = client.generate_api_token
      expect(token).to be_present
    end

    it 'creates an ApiToken record' do
      expect { client.generate_api_token }
        .to change(Custos::ApiToken, :count).by(1)
    end

    it 'sets expires_at when expires_in is provided' do
      client.generate_api_token(expires_in: 3600)
      api_token = client.custos_api_tokens.last

      expect(api_token.expires_at).to be_within(2.seconds).of(1.hour.from_now)
    end

    it 'creates token without expiration by default' do
      client.generate_api_token
      expect(client.custos_api_tokens.last.expires_at).to be_nil
    end
  end

  describe '.authenticate_api_token' do
    it 'returns client for valid token' do
      token = client.generate_api_token
      found = TestApiClient.authenticate_api_token(token)
      expect(found).to eq(client)
    end

    it 'returns nil for revoked token' do
      token = client.generate_api_token
      client.custos_api_tokens.last.revoke!

      expect(TestApiClient.authenticate_api_token(token)).to be_nil
    end

    it 'returns nil for expired token' do
      token = client.generate_api_token(expires_in: -1)

      expect(TestApiClient.authenticate_api_token(token)).to be_nil
    end

    it 'returns nil for invalid token' do
      expect(TestApiClient.authenticate_api_token('bogus')).to be_nil
    end

    it 'updates last_used_at' do
      token = client.generate_api_token
      TestApiClient.authenticate_api_token(token)

      expect(client.custos_api_tokens.last.last_used_at).to be_present
    end
  end

  describe 'ApiToken#expired?' do
    it 'returns false when expires_at is nil' do
      client.generate_api_token
      expect(client.custos_api_tokens.last.expired?).to be false
    end

    it 'returns true when expires_at is in the past' do
      client.generate_api_token(expires_in: -1)
      expect(client.custos_api_tokens.last.expired?).to be true
    end
  end
end
