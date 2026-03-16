# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :phone

      # Password plugin
      t.string :password_digest

      # Lockout plugin
      t.integer :failed_auth_count, null: false, default: 0
      t.datetime :locked_at

      # Email Confirmation plugin
      t.datetime :email_confirmed_at
      t.string :email_confirmation_token_digest
      t.datetime :email_confirmation_sent_at

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
