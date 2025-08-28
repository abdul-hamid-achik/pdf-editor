class CreatePdfDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :pdf_documents do |t|
      t.references :user, null: false, foreign_key: true
      t.references :pdf_template, foreign_key: true
      t.string :title
      t.text :description
      t.jsonb :metadata, default: {}
      t.jsonb :content_data, default: {}
      t.string :status, default: 'draft'
      t.datetime :generated_at

      t.timestamps
    end
    
    add_index :pdf_documents, :status
  end
end
