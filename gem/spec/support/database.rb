# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table :test_users, force: true do |t|
    t.string :type
    t.string :email, null: false
    t.string :phone
    t.string :password_digest
    t.integer :failed_auth_count, default: 0, null: false
    t.datetime :locked_at
    t.integer :failed_mfa_count, default: 0, null: false
    t.datetime :mfa_locked_at
    t.datetime :email_confirmed_at
    t.string :email_confirmation_token_digest
    t.datetime :email_confirmation_sent_at
    t.timestamps
  end

  create_table :test_api_clients, force: true do |t|
    t.string :name, null: false
    t.timestamps
  end

  create_table :custos_sessions, force: true do |t|
    t.string :authenticatable_type, null: false
    t.bigint :authenticatable_id, null: false
    t.string :session_token_digest, null: false
    t.string :ip_address
    t.string :user_agent
    t.datetime :last_active_at
    t.datetime :revoked_at
    t.timestamps
  end

  add_index :custos_sessions, :session_token_digest, unique: true

  create_table :custos_magic_links, force: true do |t|
    t.string :authenticatable_type, null: false
    t.bigint :authenticatable_id, null: false
    t.string :token_digest, null: false
    t.datetime :expires_at, null: false
    t.datetime :used_at
    t.datetime :created_at, null: false
  end

  add_index :custos_magic_links, :token_digest, unique: true

  create_table :custos_api_tokens, force: true do |t|
    t.string :authenticatable_type, null: false
    t.bigint :authenticatable_id, null: false
    t.string :token_digest, null: false
    t.datetime :last_used_at
    t.datetime :revoked_at
    t.datetime :expires_at
    t.timestamps
  end

  add_index :custos_api_tokens, :token_digest, unique: true

  create_table :custos_mfa_credentials, force: true do |t|
    t.string :authenticatable_type, null: false
    t.bigint :authenticatable_id, null: false
    t.string :method, null: false
    t.text :secret_data, null: false
    t.datetime :enabled_at
    t.timestamps
  end

  create_table :custos_remember_tokens, force: true do |t|
    t.string :authenticatable_type, null: false
    t.bigint :authenticatable_id, null: false
    t.string :token_digest, null: false
    t.datetime :expires_at, null: false
    t.datetime :created_at, null: false
  end

  add_index :custos_remember_tokens, :token_digest, unique: true
end
