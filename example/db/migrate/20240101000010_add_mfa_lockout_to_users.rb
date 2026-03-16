# frozen_string_literal: true

class AddMfaLockoutToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :failed_mfa_count, :integer, default: 0, null: false
    add_column :users, :mfa_locked_at, :datetime
  end
end
