# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in Custos, please **do not** open a public GitHub issue.

Instead, please report it responsibly by emailing the maintainer directly. Include:

- A description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

You should receive an acknowledgment within 48 hours. We will work with you to understand and address the issue before any public disclosure.

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.1.x   | Yes       |

## Security Design

Custos is built with security as the top priority:

- **Argon2id** for password hashing
- **HMAC-SHA256** token digests (plain-text tokens never stored)
- **AES-256-GCM** encryption for MFA secrets
- **Timing-safe** comparisons for all token verification
- **Atomic** lockout via single SQL UPDATE (no race conditions)
