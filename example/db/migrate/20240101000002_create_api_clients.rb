# frozen_string_literal: true

class CreateApiClients < ActiveRecord::Migration[7.1]
  def change
    create_table :api_clients do |t|
      t.string :name, null: false
      t.string :email, null: false

      t.timestamps
    end

    add_index :api_clients, :email, unique: true
  end
end
