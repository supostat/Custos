# frozen_string_literal: true

class CreateCustosRememberTokens < ActiveRecord::Migration[7.1]
  def change
    create_table :custos_remember_tokens do |t|
      t.string :authenticatable_type, null: false
      t.bigint :authenticatable_id, null: false
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false

      t.datetime :created_at, null: false
    end

    add_index :custos_remember_tokens, :token_digest, unique: true
    add_index :custos_remember_tokens, %i[authenticatable_type authenticatable_id],
              name: "index_custos_remember_tokens_on_authenticatable"
  end
end
