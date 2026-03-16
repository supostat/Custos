# frozen_string_literal: true

class TestUser < ActiveRecord::Base
  include Custos::Authenticatable

  custos do
    plugin :password
    plugin :magic_link
    plugin :mfa
    plugin :lockout
    plugin :email_confirmation
    plugin :remember_me
  end
end

class TestAdmin < TestUser
end

class TestApiClient < ActiveRecord::Base
  include Custos::Authenticatable

  custos do
    plugin :api_tokens
  end
end
