# frozen_string_literal: true

class AddActivestorageDelayed < ActiveRecord::Migration[6.1]
  def change
    create_table :activestorage_delayed_uploads do |t|
      t.references :uploadable, polymorphic: true, null: false
      t.string :attr_name, null: false
      t.string :deleted_ids, default: ''
      t.boolean :clean_before, default: false
      t.text :files

      t.timestamps
    end
  end
end
