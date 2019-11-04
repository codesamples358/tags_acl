class CreateTagPermissionRules < ActiveRecord::Migration[5.2]
  def change
    create_table :tag_permission_rules do |t|
      t.string :name
      t.integer :role_id

      t.string :tag

      t.boolean :role_not
      t.boolean :tag_not
    end

    add_index :tag_permission_rules, :role_id
  end
end
