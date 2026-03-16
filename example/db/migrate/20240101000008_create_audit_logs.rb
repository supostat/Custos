# frozen_string_literal: true

class CreateAuditLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :audit_logs do |t|
      t.string :authenticatable_type, null: false
      t.bigint :authenticatable_id, null: false
      t.string :event, null: false
      t.text :metadata

      t.datetime :created_at, null: false
    end

    add_index :audit_logs, %i[authenticatable_type authenticatable_id], name: "index_audit_logs_on_authenticatable"
    add_index :audit_logs, :event
  end
end
