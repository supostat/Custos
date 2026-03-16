# frozen_string_literal: true

class CreateCustosMfaCredentials < ActiveRecord::Migration[7.1]
  def change
    create_table :custos_mfa_credentials do |t|
      t.string :authenticatable_type, null: false
      t.bigint :authenticatable_id, null: false
      t.string :method, null: false
      t.text :secret_data, null: false
      t.datetime :enabled_at

      t.timestamps
    end

    add_index :custos_mfa_credentials,
              %i[authenticatable_type authenticatable_id method],
              unique: true,
              name: "index_custos_mfa_credentials_unique"
  end
end
