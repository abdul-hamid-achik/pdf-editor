class CreatePdfSnippets < ActiveRecord::Migration[8.0]
  def change
    create_table :pdf_snippets do |t|
      t.string :name, null: false
      t.string :snippet_type
      t.json :properties, default: {}
      t.text :content
      t.boolean :global, default: false
      t.references :user, foreign_key: true

      t.timestamps
    end

    add_index :pdf_snippets, :snippet_type
    add_index :pdf_snippets, :global
  end
end
