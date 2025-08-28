class CreatePdfElements < ActiveRecord::Migration[8.0]
  def change
    create_table :pdf_elements do |t|
      t.references :pdf_document, null: false, foreign_key: true
      t.string :element_type
      t.jsonb :properties, default: {}
      t.integer :page_number, default: 1
      t.float :x_position
      t.float :y_position
      t.float :width
      t.float :height
      t.integer :z_index, default: 0

      t.timestamps
    end
    
    add_index :pdf_elements, [:pdf_document_id, :page_number]
  end
end
