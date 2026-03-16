# frozen_string_literal: true

require 'spec_helper'
require 'generators/custos/install/install_generator'

RSpec.describe Custos::Generators::InstallGenerator do
  let(:destination_root) { Dir.mktmpdir('custos_install') }

  after { FileUtils.rm_rf(destination_root) }

  def run_generator
    generator = described_class.new([], {}, destination_root: destination_root)
    generator.shell.mute { generator.invoke_all }
  end

  def file_at(path)
    File.join(destination_root, path)
  end

  def migration_for(name)
    Dir.glob(File.join(destination_root, "db/migrate/*_#{name}.rb")).first
  end

  before { run_generator }

  describe 'initializer' do
    it 'creates custos.rb with configuration options' do
      content = File.read(file_at('config/initializers/custos.rb'))

      expect(content).to include('Custos.configure do |config|')
      expect(content).to include('config.session_expiry')
      expect(content).to include('config.session_renewal_interval')
      expect(content).to include('config.token_length')
    end
  end

  describe 'sessions migration' do
    it 'creates sessions table with required columns' do
      content = File.read(migration_for('create_custos_sessions'))

      expect(content).to include('create_table :custos_sessions')
      expect(content).to include(':session_token_digest, null: false')
      expect(content).to include(':authenticatable_type, null: false')
    end

    it 'adds indexes on sessions table' do
      content = File.read(migration_for('create_custos_sessions'))

      expect(content).to include('add_index :custos_sessions, :session_token_digest, unique: true')
      expect(content).to include('index_custos_sessions_on_authenticatable')
    end
  end
end
