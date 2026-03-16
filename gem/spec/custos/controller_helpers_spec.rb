# frozen_string_literal: true

RSpec.describe Custos::ControllerHelpers do
  let(:user) { TestUser.create!(email: 'ctrl@example.com', password: 'securepass1') }
  let(:request) do
    instance_double(ActionDispatch::Request, remote_ip: '127.0.0.1', user_agent: 'RSpec')
  end

  let(:controller) do
    Class.new do
      include Custos::ControllerHelpers

      attr_reader :cookies, :request

      def initialize(cookies:, request:)
        @cookies = cookies
        @request = request
      end
    end
  end

  let(:cookies) { {} }
  let(:signed_cookies) { {} }
  let(:cookie_jar) do
    double('CookieJar', signed: signed_cookies).tap do |jar|
      allow(jar).to receive(:[]).and_return(nil)
    end
  end
  let(:headers) { {} }
  let(:ctrl_request) do
    instance_double(ActionDispatch::Request, headers: headers)
  end
  let(:instance) { controller.new(cookies: cookie_jar, request: ctrl_request) }

  describe '#custos_session' do
    it 'returns session for valid cookie token' do
      _session, token = Custos::SessionManager.create(user, request: request)
      signed_cookies[:custos_session_token] = token

      result = instance.custos_session
      expect(result).to be_a(Custos::Session)
      expect(result.authenticatable).to eq(user)
    end

    it 'returns session for valid bearer token' do
      _session, token = Custos::SessionManager.create(user, request: request)
      signed_cookies[:custos_session_token] = nil
      headers['Authorization'] = "Bearer #{token}"

      result = instance.custos_session
      expect(result.authenticatable).to eq(user)
    end

    it 'returns nil when no token present' do
      signed_cookies[:custos_session_token] = nil
      expect(instance.custos_session).to be_nil
    end

    it 'returns nil for invalid token' do
      signed_cookies[:custos_session_token] = 'bogus-token'
      expect(instance.custos_session).to be_nil
    end
  end

  describe '#custos_authenticated?' do
    before do
      Custos.configure do |c|
        c.scope_map = { user: 'TestUser' }
      end
    end

    after do
      Custos.configure do |c|
        c.scope_map = {}
        c.token_secret = 'test-secret-key-for-custos-specs'
      end
    end

    it 'returns true when session exists for scope' do
      _session, token = Custos::SessionManager.create(user, request: request)
      signed_cookies[:custos_session_token] = token

      expect(instance.custos_authenticated?(scope: :user)).to be true
    end

    it 'returns false when no session' do
      signed_cookies[:custos_session_token] = nil
      expect(instance.custos_authenticated?(scope: :user)).to be false
    end
  end

  describe '#custos_authenticate!' do
    before do
      Custos.configure do |c|
        c.scope_map = { user: 'TestUser' }
      end
    end

    after do
      Custos.configure do |c|
        c.scope_map = {}
        c.token_secret = 'test-secret-key-for-custos-specs'
      end
    end

    it 'raises NotAuthenticatedError when not authenticated' do
      signed_cookies[:custos_session_token] = nil
      expect { instance.custos_authenticate!(scope: :user) }
        .to raise_error(Custos::NotAuthenticatedError)
    end

    it 'does not raise when authenticated' do
      _session, token = Custos::SessionManager.create(user, request: request)
      signed_cookies[:custos_session_token] = token

      expect { instance.custos_authenticate!(scope: :user) }.not_to raise_error
    end
  end
end
