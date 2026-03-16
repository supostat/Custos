# Custos

[![Gem Version](https://img.shields.io/gem/v/custos)](https://rubygems.org/gems/custos)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.2-red)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/rails-%3E%3D%207.0-red)](https://rubyonrails.org/)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE.txt)

Plugin-based authentication for Ruby on Rails. Modern, modular authentication that supports password, magic link, API tokens, MFA, and more — all as composable plugins.

**No magic controllers.** Custos provides services and helpers, not generated controllers and routes. You stay in control. Email delivery, SMS, and other side effects are handled through callbacks — use Action Mailer, Postmark, or anything else.

## Quick Start

Add to your Gemfile:

```ruby
gem "custos"
```

Run the install generator:

```bash
bundle install
rails generate custos:install
rails db:migrate
```

Generate model authentication (pick the plugins you need):

```bash
rails generate custos:model User password magic_link lockout email_confirmation
rails db:migrate
```

Configure your model:

```ruby
class User < ApplicationRecord
  include Custos::Authenticatable

  custos do
    plugin :password, min_length: 10, require_digit: true
    plugin :magic_link
    plugin :lockout, max_attempts: 5
    plugin :email_confirmation

    on(:magic_link_created) do |record, token|
      AuthMailer.magic_link(record, token).deliver_later
    end

    on(:email_confirmation_requested) do |record, token|
      AuthMailer.confirm_email(record, token).deliver_later
    end
  end
end
```

Authenticate in controllers:

```ruby
class DashboardController < ApplicationController
  before_action :custos_authenticate!

  def show
    @user = custos_current
  end
end
```

## Plugins

| Plugin | Description |
|--------|-------------|
| Password | Email + password authentication with Argon2 hashing |
| Magic Link | Passwordless authentication via email links |
| API Tokens | Bearer token authentication for APIs |
| MFA | TOTP, backup codes, and SMS verification |
| Lockout | Account lockout after failed attempts |
| Email Confirmation | Email verification on sign-up |
| Remember Me | Long-lived sessions via persistent tokens |

Each plugin is standalone. Use password authentication for users and API tokens for service accounts — on the same app, with per-model configuration.

## Security

- **Argon2id** password hashing (resistant to GPU/ASIC attacks)
- **HMAC-SHA256** token digests — plain-text tokens are never persisted
- **AES-256-GCM** encrypted MFA secrets
- **Timing-safe** comparisons for all token verification
- **Atomic lockout** — race-condition-free via single SQL UPDATE
- **256-bit entropy** session tokens

## Configuration

```ruby
# config/initializers/custos.rb
Custos.configure do |config|
  config.session_expiry = 24 * 60 * 60     # 24 hours
  config.token_length = 32                  # bytes
  config.token_secret = Rails.application.secret_key_base
  config.mfa_encryption_key = ENV["CUSTOS_MFA_KEY"]  # optional, enables MFA secret encryption
  config.callback_error_strategy = :log     # :log or :raise
end
```

## Documentation

Full documentation is available at **[github.com/supostat/Custos](https://github.com/supostat/Custos)**.

## Requirements

- Ruby 3.2+
- Rails 7.0+

## License

Released under the [MIT License](LICENSE.txt).
