# frozen_string_literal: true

RSpec.describe Custos::Session do
  let(:user) { TestUser.create!(email: 'session-model@example.com', password: 'securepass1') }

  def create_session(revoked: false, created_at: Time.current)
    session = described_class.create!(
      authenticatable: user,
      session_token_digest: Custos::TokenGenerator.digest(SecureRandom.hex),
      ip_address: '127.0.0.1',
      user_agent: 'RSpec',
      last_active_at: Time.current,
      created_at: created_at
    )
    session.update!(revoked_at: Time.current) if revoked
    session
  end

  describe '.active' do
    it 'excludes revoked sessions' do
      create_session(revoked: true)
      active = create_session

      expect(described_class.active).to eq([active])
    end

    it 'excludes expired sessions' do
      create_session(created_at: 25.hours.ago)
      active = create_session

      expect(described_class.active).to eq([active])
    end
  end

  describe '.revoked' do
    it 'includes only revoked sessions' do
      revoked = create_session(revoked: true)
      create_session

      expect(described_class.revoked).to eq([revoked])
    end
  end

  describe 'associations' do
    it 'belongs_to authenticatable' do
      session = create_session
      expect(session.authenticatable).to eq(user)
    end
  end
end
