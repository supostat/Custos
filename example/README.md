# Custos Example App

Minimal Rails application demonstrating all Custos features:

- Password authentication
- Magic link (passwordless)
- MFA: TOTP, backup codes, SMS
- Account lockout
- Email confirmation
- Remember me
- Session management (list, revoke, revoke all)
- API token authentication
- **Custom plugin: audit_log** (defined in the app, not the gem)
- **STI: Admin < User** with stricter security config

## Setup

```bash
cd example
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server
```

Open http://localhost:3000

## Seed Data

| Model     | Email             | Password        | Notes                                      |
|-----------|-------------------|-----------------|--------------------------------------------|
| User      | demo@example.com  | password123     | All plugins enabled                        |
| Admin     | admin@example.com | AdminSecure123  | Stricter password, tighter lockout, no magic link |
| ApiClient | api@example.com   | (see seed output for token) |                              |

## Custom Plugin: audit_log

Defined in `lib/custos/plugins/audit_log.rb`, this plugin demonstrates how to extend
Custos within your application:

- Listens to `:after_authentication` and `:after_mfa_verification` hooks
- Records events to an `audit_logs` table
- Exposes `record_audit_event` for controllers to log custom events (e.g., session creation with IP/UA)
- View events at `/audit_logs`

## STI: Admin

`Admin < User` inherits the User table via Single Table Inheritance. It defines its own
`custos` block with stricter settings:

- Password: min 12 chars, requires uppercase and digit
- Lockout: 3 attempts, 1 hour duration (vs User defaults)
- No magic_link or remember_me plugins
- Has audit_log plugin

Login with the admin account works through the same login form — Rails STI handles class
resolution automatically.

## API Usage

Generate a token:

```bash
curl -X POST http://localhost:3000/api/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "email=api@example.com"
```

Access protected endpoint:

```bash
curl http://localhost:3000/api/protected \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Mailer

Custos does not include a mailer. This app uses `ActionMailer` with `:logger` delivery
method. All emails are printed to the Rails server log, including magic links and
email confirmation URLs.

## Notes

- SQLite for simplicity.
- All encryption keys in `config/application.rb` are for development only.
- `secret_key_base` is hardcoded for development. Do not use in production.
