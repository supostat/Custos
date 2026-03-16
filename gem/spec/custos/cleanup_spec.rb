# frozen_string_literal: true

require 'spec_helper'
require 'rake'

RSpec.describe 'custos:cleanup' do # rubocop:disable RSpec/DescribeClass
  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    Rake.application = Rake::Application.new
    Rake.application.define_task(Rake::Task, :environment)
    load File.expand_path('../../lib/custos/tasks/cleanup.rake', __dir__)
  end

  before { Rake::Task['custos:cleanup'].reenable }

  let!(:user) { TestUser.create!(email: 'cleanup@test.com') }

  def invoke_cleanup
    Rake::Task['custos:cleanup'].invoke
  end

  describe 'expired sessions' do
    let!(:expired_session) do
      Custos::Session.create!(
        authenticatable: user,
        session_token_digest: SecureRandom.hex(32),
        created_at: 2.days.ago
      )
    end

    let!(:active_session) do
      Custos::Session.create!(
        authenticatable: user,
        session_token_digest: SecureRandom.hex(32),
        created_at: 1.hour.ago
      )
    end

    it 'deletes expired sessions and keeps active ones' do
      expect { invoke_cleanup }.to output(/Deleted 1 expired sessions/).to_stdout

      expect(Custos::Session.find_by(id: expired_session.id)).to be_nil
      expect(Custos::Session.find_by(id: active_session.id)).to be_present
    end
  end

  describe 'revoked sessions' do
    let!(:old_revoked) do
      Custos::Session.create!(
        authenticatable: user,
        session_token_digest: SecureRandom.hex(32),
        revoked_at: 31.days.ago
      )
    end

    let!(:recent_revoked) do
      Custos::Session.create!(
        authenticatable: user,
        session_token_digest: SecureRandom.hex(32),
        revoked_at: 1.day.ago
      )
    end

    it 'deletes old revoked sessions and keeps recent ones' do
      expect { invoke_cleanup }.to output(/Deleted 1 old revoked sessions/).to_stdout

      expect(Custos::Session.find_by(id: old_revoked.id)).to be_nil
      expect(Custos::Session.find_by(id: recent_revoked.id)).to be_present
    end
  end

  describe 'magic links' do
    let!(:used_link) do
      Custos::MagicLinkToken.create!(
        authenticatable: user,
        token_digest: SecureRandom.hex(32),
        expires_at: 1.hour.from_now,
        used_at: 1.hour.ago
      )
    end

    let!(:expired_link) do
      Custos::MagicLinkToken.create!(
        authenticatable: user,
        token_digest: SecureRandom.hex(32),
        expires_at: 1.hour.ago
      )
    end

    let!(:valid_link) do
      Custos::MagicLinkToken.create!(
        authenticatable: user,
        token_digest: SecureRandom.hex(32),
        expires_at: 1.hour.from_now
      )
    end

    it 'deletes used and expired magic links, keeps valid ones' do
      expect { invoke_cleanup }.to output(%r{Deleted 2 used/expired magic links}).to_stdout

      expect(Custos::MagicLinkToken.find_by(id: used_link.id)).to be_nil
      expect(Custos::MagicLinkToken.find_by(id: expired_link.id)).to be_nil
      expect(Custos::MagicLinkToken.find_by(id: valid_link.id)).to be_present
    end
  end

  describe 'remember tokens' do
    let!(:expired_token) do
      Custos::RememberToken.create!(
        authenticatable: user,
        token_digest: SecureRandom.hex(32),
        expires_at: 1.hour.ago
      )
    end

    let!(:valid_token) do
      Custos::RememberToken.create!(
        authenticatable: user,
        token_digest: SecureRandom.hex(32),
        expires_at: 1.day.from_now
      )
    end

    it 'deletes expired remember tokens and keeps valid ones' do
      expect { invoke_cleanup }.to output(/Deleted 1 expired remember tokens/).to_stdout

      expect(Custos::RememberToken.find_by(id: expired_token.id)).to be_nil
      expect(Custos::RememberToken.find_by(id: valid_token.id)).to be_present
    end
  end

  describe 'API tokens' do
    let!(:api_client) { TestApiClient.create!(name: 'cleanup-client') }

    let!(:expired_api_token) do
      Custos::ApiToken.create!(
        authenticatable: api_client,
        token_digest: SecureRandom.hex(32),
        expires_at: 1.hour.ago
      )
    end

    let!(:non_expiring_token) do
      Custos::ApiToken.create!(
        authenticatable: api_client,
        token_digest: SecureRandom.hex(32),
        expires_at: nil
      )
    end

    let!(:valid_api_token) do
      Custos::ApiToken.create!(
        authenticatable: api_client,
        token_digest: SecureRandom.hex(32),
        expires_at: 1.day.from_now
      )
    end

    it 'deletes expired API tokens, keeps non-expiring and valid ones' do
      expect { invoke_cleanup }.to output(/Deleted 1 expired API tokens/).to_stdout

      expect(Custos::ApiToken.find_by(id: expired_api_token.id)).to be_nil
      expect(Custos::ApiToken.find_by(id: non_expiring_token.id)).to be_present
      expect(Custos::ApiToken.find_by(id: valid_api_token.id)).to be_present
    end
  end
end
