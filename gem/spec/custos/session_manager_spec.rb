# frozen_string_literal: true

RSpec.describe Custos::SessionManager do
  let(:user) { TestUser.create!(email: 'session@example.com', password: 'securepass1') }
  let(:request) do
    instance_double(ActionDispatch::Request, remote_ip: '127.0.0.1', user_agent: 'RSpec')
  end

  describe '.create' do
    it 'creates a session and returns token' do
      session, token = described_class.create(user, request: request)

      expect(session).to be_persisted
      expect(session.authenticatable).to eq(user)
      expect(session.ip_address).to eq('127.0.0.1')
      expect(token).to be_present
    end

    it 'stores token as digest' do
      session, token = described_class.create(user, request: request)
      expected_digest = Custos::TokenGenerator.digest(token)
      expect(session.session_token_digest).to eq(expected_digest)
    end
  end

  describe '.find_by_token' do
    it 'finds active session by plain token' do
      _session, token = described_class.create(user, request: request)
      found = described_class.find_by_token(token)

      expect(found.authenticatable).to eq(user)
    end

    it 'returns nil for revoked session' do
      session, token = described_class.create(user, request: request)
      described_class.revoke(session)

      expect(described_class.find_by_token(token)).to be_nil
    end

    it 'returns nil for blank token' do
      expect(described_class.find_by_token(nil)).to be_nil
      expect(described_class.find_by_token('')).to be_nil
    end

    it 'filters by authenticatable_type when provided' do
      _session, token = described_class.create(user, request: request)

      expect(described_class.find_by_token(token, authenticatable_type: 'TestUser')).to be_present
      expect(described_class.find_by_token(token, authenticatable_type: 'TestApiClient')).to be_nil
    end
  end

  describe '.revoke' do
    it 'sets revoked_at' do
      session, _token = described_class.create(user, request: request)
      described_class.revoke(session)

      expect(session.reload.revoked_at).to be_present
    end
  end

  describe '.revoke_all' do
    it 'revokes all active sessions for authenticatable' do
      described_class.create(user, request: request)
      described_class.create(user, request: request)

      described_class.revoke_all(user)
      expect(user.custos_sessions.active).to be_empty
    end
  end

  describe '.active_for' do
    it 'returns active sessions ordered by last_active_at desc' do
      described_class.create(user, request: request)
      described_class.create(user, request: request)

      sessions = described_class.active_for(user)
      expect(sessions.size).to eq(2)
    end
  end
end
