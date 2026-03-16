# frozen_string_literal: true

require 'spec_helper'
require 'generators/custos/model/model_generator'

RSpec.describe Custos::Generators::ModelGenerator do
  let(:destination_root) { Dir.mktmpdir('custos_model') }

  after { FileUtils.rm_rf(destination_root) }

  def run_generator(args)
    generator = described_class.new(args, {}, destination_root: destination_root)
    generator.shell.mute { generator.invoke_all }
  end

  def migration_for(name)
    Dir.glob(File.join(destination_root, "db/migrate/*_#{name}.rb")).first
  end

  def all_migrations
    Dir.glob(File.join(destination_root, 'db/migrate/*.rb'))
  end

  context 'with password plugin' do
    before { run_generator(%w[User password]) }

    it 'creates column migration with password_digest' do
      content = File.read(migration_for('add_custos_to_users'))

      expect(content).to include('class AddCustosToUsers')
      expect(content).to include(':password_digest, :string')
    end
  end

  context 'with lockout plugin' do
    before { run_generator(%w[User lockout]) }

    it 'creates column migration with lockout columns' do
      content = File.read(migration_for('add_custos_to_users'))

      expect(content).to include(':failed_auth_count, :integer')
      expect(content).to include(':locked_at, :datetime')
      expect(content).to include(':failed_mfa_count, :integer')
      expect(content).to include(':mfa_locked_at, :datetime')
    end
  end

  context 'with email_confirmation plugin' do
    before { run_generator(%w[User email_confirmation]) }

    it 'creates column migration with confirmation columns' do
      content = File.read(migration_for('add_custos_to_users'))

      expect(content).to include(':email_confirmed_at, :datetime')
      expect(content).to include(':email_confirmation_token_digest, :string')
      expect(content).to include(':email_confirmation_sent_at, :datetime')
    end
  end

  context 'with magic_link plugin' do
    before { run_generator(%w[User magic_link]) }

    it 'creates magic links table migration' do
      content = File.read(migration_for('create_custos_magic_links'))

      expect(content).to include('create_table :custos_magic_links')
      expect(content).to include(':token_digest, null: false')
      expect(content).to include(':expires_at, null: false')
    end

    it 'does not create column migration' do
      expect(migration_for('add_custos_to_users')).to be_nil
    end
  end

  context 'with api_tokens plugin' do
    before { run_generator(%w[User api_tokens]) }

    it 'creates api tokens table migration' do
      content = File.read(migration_for('create_custos_api_tokens'))

      expect(content).to include('create_table :custos_api_tokens')
      expect(content).to include(':token_digest, null: false')
      expect(content).to include(':expires_at')
    end
  end

  context 'with mfa plugin' do
    before { run_generator(%w[User mfa]) }

    it 'creates mfa credentials table migration' do
      content = File.read(migration_for('create_custos_mfa_credentials'))

      expect(content).to include('create_table :custos_mfa_credentials')
      expect(content).to include(':secret_data, null: false')
      expect(content).to include(':method, null: false')
    end
  end

  context 'with remember_me plugin' do
    before { run_generator(%w[User remember_me]) }

    it 'creates remember tokens table migration' do
      content = File.read(migration_for('create_custos_remember_tokens'))

      expect(content).to include('create_table :custos_remember_tokens')
      expect(content).to include(':token_digest, null: false')
      expect(content).to include(':expires_at, null: false')
    end
  end

  context 'with all plugins' do
    before { run_generator(%w[User password lockout email_confirmation magic_link api_tokens mfa remember_me]) }

    it 'creates column migration and all table migrations' do
      expect(migration_for('add_custos_to_users')).not_to be_nil
      expect(migration_for('create_custos_magic_links')).not_to be_nil
      expect(migration_for('create_custos_api_tokens')).not_to be_nil
      expect(migration_for('create_custos_mfa_credentials')).not_to be_nil
      expect(migration_for('create_custos_remember_tokens')).not_to be_nil
    end
  end

  context 'with no plugins' do
    before { run_generator(%w[User]) }

    it 'creates no migrations' do
      expect(all_migrations).to be_empty
    end
  end

  context 'with custom model name' do
    before { run_generator(%w[AdminUser password]) }

    it 'uses correct table name in migration' do
      content = File.read(migration_for('add_custos_to_admin_users'))

      expect(content).to include('class AddCustosToAdminUsers')
      expect(content).to include(':admin_users')
    end
  end

  context 'with namespaced model' do
    before { run_generator(%w[Admin::User password]) }

    it 'converts namespace to underscored table name' do
      content = File.read(migration_for('add_custos_to_admin_users'))

      expect(content).to include('class AddCustosToAdminUsers')
      expect(content).to include(':admin_users')
    end
  end

  context 'with unknown plugin' do
    it 'raises an error listing available plugins' do
      expect { run_generator(%w[User pasword]) }.to raise_error(Thor::Error, /Unknown plugin.*pasword/)
    end
  end
end
