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

## Setup

```bash
cd example
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server
```

Open http://localhost:3000

## Seed Data

| Model     | Email             | Password      |
|-----------|-------------------|---------------|
| User      | demo@example.com  | password123   |
| ApiClient | api@example.com   | (see seed output for token) |

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
