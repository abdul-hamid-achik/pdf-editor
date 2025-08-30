require 'rails_helper'

RSpec.describe "PDF Document Management", type: :system do
  let(:user) { create(:user) }

  before do
    driven_by(:selenium_chrome_headless)
    # Mock authentication
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
  end

  describe "Document listing" do
    let!(:documents) { create_list(:pdf_document, 3, user: user) }

    it "displays user's documents" do
      visit pdf_documents_path
      
      documents.each do |doc|
        expect(page).to have_content(doc.title)
      end
    end

    it "filters documents by status" do
      completed_doc = create(:pdf_document, :completed, user: user, title: "Completed Doc")
      draft_doc = create(:pdf_document, status: "draft", user: user, title: "Draft Doc")

      visit pdf_documents_path(status: "completed")
      
      expect(page).to have_content("Completed Doc")
      expect(page).not_to have_content("Draft Doc")
    end

    it "allows navigation to document details" do
      document = documents.first
      visit pdf_documents_path
      
      click_link document.title
      
      expect(current_path).to eq(pdf_document_path(document))
      expect(page).to have_content(document.title)
    end
  end

  describe "Creating a new document" do
    it "creates document with basic information" do
      visit new_pdf_document_path
      
      fill_in "Title", with: "Test Document"
      fill_in "Description", with: "This is a test document"
      
      click_button "Create Document"
      
      expect(page).to have_content("PDF document created successfully")
      expect(current_path).to eq(edit_pdf_document_path(PdfDocument.last))
      expect(PdfDocument.last.title).to eq("Test Document")
    end

    context "with template" do
      let!(:template) { create(:pdf_template, :global, name: "Invoice Template") }

      it "applies selected template" do
        visit new_pdf_document_path
        
        select "Invoice Template", from: "Template"
        fill_in "Title", with: "Invoice Document"
        
        click_button "Create Document"
        
        document = PdfDocument.last
        expect(document.pdf_template).to eq(template)
      end
    end
  end

  describe "Editing a document" do
    let(:document) { create(:pdf_document, user: user) }

    it "updates document information" do
      visit edit_pdf_document_path(document)
      
      fill_in "Title", with: "Updated Title"
      fill_in "Description", with: "Updated description"
      
      click_button "Save Document"
      
      expect(page).to have_content("Document updated successfully")
      document.reload
      expect(document.title).to eq("Updated Title")
      expect(document.description).to eq("Updated description")
    end

    it "allows adding elements via UI" do
      visit edit_pdf_document_path(document)
      
      click_button "Add Text Element"
      
      within(".element-form") do
        fill_in "Content", with: "Sample text content"
        fill_in "X Position", with: "100"
        fill_in "Y Position", with: "200"
        click_button "Add Element"
      end
      
      expect(page).to have_content("Element added successfully")
      expect(document.pdf_elements.count).to eq(1)
    end
  end

  describe "Document preview" do
    let(:document) { create(:pdf_document, :with_elements, user: user) }

    it "displays preview of document" do
      visit pdf_document_path(document)
      
      click_link "Preview"
      
      within(".pdf-preview") do
        expect(page).to have_css(".pdf-page")
        expect(page).to have_css(".pdf-element")
      end
    end

    it "allows page navigation in preview" do
      document.pdf_elements.create!(element_type: "text", page_number: 2, properties: { content: "Page 2 content" })
      
      visit pdf_document_path(document)
      click_link "Preview"
      
      click_button "Next Page"
      
      expect(page).to have_content("Page 2")
    end
  end

  describe "PDF generation" do
    let(:document) { create(:pdf_document, user: user) }

    it "initiates PDF generation" do
      visit pdf_document_path(document)
      
      click_button "Generate PDF"
      
      expect(page).to have_content("PDF generation started")
      expect(document.reload.status).to eq("processing")
    end

    it "downloads generated PDF" do
      document.generated_file.attach(
        io: StringIO.new("PDF content"),
        filename: "document.pdf",
        content_type: "application/pdf"
      )
      document.update!(status: "completed")
      
      visit pdf_document_path(document)
      
      expect(page).to have_link("Download PDF")
      click_link "Download PDF"
      
      # Browser should initiate download
    end
  end

  describe "Document duplication" do
    let(:document) { create(:pdf_document, :with_elements, user: user, title: "Original") }

    it "creates a copy of the document" do
      visit pdf_document_path(document)
      
      click_button "Duplicate"
      
      expect(page).to have_content("Document duplicated successfully")
      expect(current_path).to eq(edit_pdf_document_path(PdfDocument.last))
      
      duplicate = PdfDocument.last
      expect(duplicate.title).to eq("Original (Copy)")
      expect(duplicate.pdf_elements.count).to eq(document.pdf_elements.count)
    end
  end

  describe "Document deletion" do
    let!(:document) { create(:pdf_document, user: user) }

    it "deletes the document" do
      visit pdf_document_path(document)
      
      accept_confirm do
        click_button "Delete"
      end
      
      expect(page).to have_content("Document deleted successfully")
      expect(current_path).to eq(pdf_documents_path)
      expect(PdfDocument.exists?(document.id)).to be false
    end
  end

  describe "Turbo Stream updates" do
    let(:document) { create(:pdf_document, user: user) }

    it "updates document status without page reload", js: true do
      visit pdf_document_path(document)
      
      document.update!(status: "completed")
      
      # Turbo Stream should update status display
      expect(page).to have_css(".status-completed", wait: 5)
      expect(page).not_to have_css(".status-draft")
    end

    it "auto-saves document changes", js: true do
      visit edit_pdf_document_path(document)
      
      fill_in "Title", with: "Auto-saved title"
      
      # Wait for auto-save
      sleep 2
      
      document.reload
      expect(document.title).to eq("Auto-saved title")
    end
  end
end