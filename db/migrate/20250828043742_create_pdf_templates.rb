class CreatePdfTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :pdf_templates do |t|
      t.string :name, null: false
      t.text :description
      t.string :category
      t.jsonb :structure, default: {}
      t.jsonb :default_data, default: {}
      t.string :thumbnail_url
      t.integer :usage_count, default: 0
      t.references :user, foreign_key: true

      t.timestamps
    end
    
    add_index :pdf_templates, :category
    add_index :pdf_templates, :usage_count
  end
end
