# frozen_string_literal: true

require_relative 'lib/custos/version'

Gem::Specification.new do |spec|
  spec.name = 'custos'
  spec.version = Custos::VERSION
  spec.authors = ['Ingvar']
  spec.summary = 'Plugin-based authentication for Rails'
  spec.description = 'Modern, modular authentication for Rails applications. ' \
                     'Supports password, magic link, API tokens, MFA, and more — all as composable plugins.'
  spec.homepage = 'https://github.com/supostat/Custos'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.files = Dir.chdir(__dir__) do
    Dir['{lib}/**/*', 'LICENSE.txt', 'CHANGELOG.md', 'README.md']
  end

  spec.require_paths = ['lib']

  spec.add_dependency 'argon2', '~> 2.0'
  spec.add_dependency 'rails', '>= 7.0'
  spec.add_dependency 'rotp', '~> 6.0'
end
