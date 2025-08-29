class CreatePdfVersions < ActiveRecord::Migration[8.0]
  def change
    create_table :pdf_versions do |t|
      t.references :pdf_document, null: false, foreign_key: true
      t.integer :version_number, null: false
      t.json :version_changes, default: {}
      t.references :user, foreign_key: true

      t.timestamps
    end

    add_index :pdf_versions, [ :pdf_document_id, :version_number ], unique: true
  end
end
