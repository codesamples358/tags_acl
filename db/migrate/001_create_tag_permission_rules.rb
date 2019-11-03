class CreateTagPermissionRules < ActiveRecord::Migration[5.2]
  def change
    create_table :tag_permission_rules do |t|
      t.string :name
      t.references :role, foreign_key: true

      t.string :tag

      t.boolean :role_not
      t.boolean :tag_not
    end
  end
end
