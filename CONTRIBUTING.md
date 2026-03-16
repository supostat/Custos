# Contributing to Custos

Thank you for considering contributing to Custos!

## Development Setup

```bash
cd gem
bundle install
```

## Running Tests

```bash
bundle exec rspec
```

All tests use an in-memory SQLite database. No external services required.

## Code Style

This project uses RuboCop. Check your changes before submitting:

```bash
bundle exec rubocop
```

## Submitting Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b my-feature`)
3. Make your changes with tests
4. Ensure all tests pass and RuboCop reports no offenses
5. Commit your changes
6. Push to your fork and open a pull request

## Reporting Issues

Open an issue on [GitHub](https://github.com/supostat/Custos/issues) with:

- A clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Ruby and Rails versions

## Security Vulnerabilities

If you discover a security vulnerability, please **do not** open a public issue. Instead, email the maintainer directly.
