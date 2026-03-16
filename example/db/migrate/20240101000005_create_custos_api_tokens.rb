# frozen_string_literal: true

class CreateCustosApiTokens < ActiveRecord::Migration[7.1]
  def change
    create_table :custos_api_tokens do |t|
      t.string :authenticatable_type, null: false
      t.bigint :authenticatable_id, null: false
      t.string :token_digest, null: false
      t.datetime :last_used_at
      t.datetime :expires_at
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :custos_api_tokens, :token_digest, unique: true
    add_index :custos_api_tokens, %i[authenticatable_type authenticatable_id],
              name: "index_custos_api_tokens_on_authenticatable"
  end
end
