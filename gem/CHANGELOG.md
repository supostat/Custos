# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/).

## [0.1.0] - Unreleased

### Added

- Core authentication framework with `Custos::Authenticatable` concern
- Plugin system with per-model configuration DSL
- Session management with HMAC-SHA256 token digests and scope filtering
- Controller helpers: `custos_authenticate!`, `custos_current`, `custos_session`
- Token extraction from signed cookies and Authorization header
- Callback system with configurable error strategy (`:log` / `:raise`)
- Install and model generators

#### Plugins

- **Password** — Argon2id hashing, configurable complexity rules, timing-safe dummy verify
- **Magic Link** — Passwordless email authentication with cooldown and expiry
- **API Tokens** — Bearer token authentication with optional expiration
- **MFA** — TOTP, backup codes (48-bit entropy), SMS verification
- **Lockout** — Atomic SQL-based account lockout after failed attempts
- **Email Confirmation** — Token-based email verification with configurable expiry
- **Remember Me** — Persistent session tokens with rotation on use

#### Security

- HMAC-SHA256 token digests (plain-text tokens never persisted)
- AES-256-GCM encryption for MFA secrets via `Custos::MfaEncryptor`
- Timing-safe comparisons for all token verification
- Atomic lockout updates (single SQL statement, no race conditions)
- MFA rate limiting via Lockout plugin integration
- Cleanup rake task for expired sessions and tokens
