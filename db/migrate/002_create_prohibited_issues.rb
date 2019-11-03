class CreateProhibitedIssues < ActiveRecord::Migration[5.2]
  def change
    create_table :prohibited_issues do |t|
      t.integer :issue_id #, foreign_key: true
      t.integer :user_id #, foreign_key: true
      t.integer :tag_permission_rule_id #, foreign_key: true
    end

    add_index :prohibited_issues, :issue_id
    add_index :prohibited_issues, :user_id
    add_index :prohibited_issues, :tag_permission_rule_id
  end
end
