class CreateApprovalItems < ActiveRecord::Migration
  def self.up
    create_table :approval_items do |t|
      t.column :user_id, :integer
      t.column :issue_id, :integer
      t.column :approved, :bool
      t.column :approved_on, :datetime
      t.column :created_on, :datetime
    end
  end

  def self.down
    drop_table :approval_items
  end
end
