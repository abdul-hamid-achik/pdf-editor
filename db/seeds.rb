# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Starting to seed the database..."

# ============================================================================
# USERS
# ============================================================================
puts "👤 Creating users..."

admin_user = User.find_or_create_by!(email: "admin@pdfeditor.com") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
  user.name = "Admin User"
  user.first_name = "Admin"
  user.last_name = "User"
end

demo_user = User.find_or_create_by!(email: "demo@example.com") do |user|
  user.password = "demo123"
  user.password_confirmation = "demo123"
  user.name = "Demo User"
  user.first_name = "Demo"
  user.last_name = "User"
end

business_user = User.find_or_create_by!(email: "john.doe@business.com") do |user|
  user.password = "business123"
  user.password_confirmation = "business123"
  user.name = "John Doe"
  user.first_name = "John"
  user.last_name = "Doe"
end

puts "✅ Created #{User.count} users"

# ============================================================================
# PDF TEMPLATES
# ============================================================================
puts "📄 Creating PDF templates..."

# Business Letter Template
business_letter = PdfTemplate.find_or_create_by!(name: "Professional Business Letter") do |template|
  template.description = "A clean, professional business letter template"
  template.category = "business"
  template.usage_count = 25
  template.user = nil # Global template
  template.structure = {
    "pages" => 1,
    "layout" => "portrait",
    "margins" => { "top" => 72, "bottom" => 72, "left" => 72, "right" => 72 },
    "elements" => [
      { "type" => "header", "position" => "top" },
      { "type" => "body", "position" => "center" },
      { "type" => "signature", "position" => "bottom" }
    ]
  }
  template.default_data = {
    "company_name" => "[Company Name]",
    "company_address" => "[Company Address]",
    "recipient_name" => "[Recipient Name]",
    "date" => Date.current.strftime("%B %d, %Y"),
    "subject" => "[Letter Subject]",
    "body_text" => "Dear [Recipient Name],\n\n[Your message here]\n\nBest regards,\n[Your Name]"
  }
end

# Invoice Template
invoice_template = PdfTemplate.find_or_create_by!(name: "Professional Invoice") do |template|
  template.description = "Modern invoice template for businesses"
  template.category = "business"
  template.usage_count = 45
  template.user = nil
  template.structure = {
    "pages" => 1,
    "layout" => "portrait",
    "margins" => { "top" => 50, "bottom" => 50, "left" => 50, "right" => 50 },
    "elements" => [
      { "type" => "header", "position" => "top" },
      { "type" => "table", "position" => "center" },
      { "type" => "footer", "position" => "bottom" }
    ]
  }
  template.default_data = {
    "invoice_number" => "INV-2024-001",
    "date" => Date.current.strftime("%m/%d/%Y"),
    "due_date" => (Date.current + 30.days).strftime("%m/%d/%Y"),
    "company_name" => "[Your Company]",
    "client_name" => "[Client Name]",
    "total_amount" => "$0.00"
  }
end

# Certificate Template
certificate_template = PdfTemplate.find_or_create_by!(name: "Achievement Certificate") do |template|
  template.description = "Elegant certificate template for achievements and awards"
  template.category = "certificate"
  template.usage_count = 15
  template.user = nil
  template.structure = {
    "pages" => 1,
    "layout" => "landscape",
    "margins" => { "top" => 100, "bottom" => 100, "left" => 100, "right" => 100 },
    "elements" => [
      { "type" => "image", "position" => "background" },
      { "type" => "text", "position" => "center" },
      { "type" => "signature", "position" => "bottom" }
    ]
  }
  template.default_data = {
    "recipient_name" => "[Recipient Name]",
    "achievement" => "[Achievement Description]",
    "date" => Date.current.strftime("%B %Y"),
    "organization" => "[Organization Name]"
  }
end

# Business Card Template
business_card = PdfTemplate.find_or_create_by!(name: "Modern Business Card") do |template|
  template.description = "Sleek and modern business card design"
  template.category = "marketing"
  template.usage_count = 20
  template.user = nil
  template.structure = {
    "pages" => 1,
    "layout" => "custom",
    "dimensions" => { "width" => 252, "height" => 144 }, # 3.5" x 2" in points
    "margins" => { "top" => 18, "bottom" => 18, "left" => 18, "right" => 18 },
    "elements" => [
      { "type" => "text", "position" => "center" },
      { "type" => "image", "position" => "corner" }
    ]
  }
  template.default_data = {
    "name" => "[Your Name]",
    "title" => "[Your Title]",
    "company" => "[Company Name]",
    "phone" => "[Phone Number]",
    "email" => "[Email Address]",
    "website" => "[Website URL]"
  }
end

puts "✅ Created #{PdfTemplate.count} templates"

# ============================================================================
# PDF SNIPPETS
# ============================================================================
puts "🧩 Creating PDF snippets..."

# Header Snippets
company_header = PdfSnippet.find_or_create_by!(name: "Company Header") do |snippet|
  snippet.snippet_type = "header"
  snippet.global = true
  snippet.user = nil
  snippet.content = "Professional Company Header"
  snippet.properties = {
    "style" => "professional",
    "font_size" => 18,
    "font_weight" => "bold",
    "color" => "#2C3E50",
    "alignment" => "center",
    "padding" => 20
  }
end

# Footer Snippets
contact_footer = PdfSnippet.find_or_create_by!(name: "Contact Information Footer") do |snippet|
  snippet.snippet_type = "footer"
  snippet.global = true
  snippet.user = nil
  snippet.content = "123 Business Ave | City, State 12345 | (555) 123-4567 | contact@company.com"
  snippet.properties = {
    "font_size" => 10,
    "color" => "#7F8C8D",
    "alignment" => "center",
    "padding" => 15
  }
end

# Signature Snippets
digital_signature = PdfSnippet.find_or_create_by!(name: "Digital Signature Block") do |snippet|
  snippet.snippet_type = "signature"
  snippet.global = false
  snippet.user = business_user
  snippet.content = "John Doe\nCEO & Founder\nBusiness Solutions Inc."
  snippet.properties = {
    "font_size" => 12,
    "color" => "#2C3E50",
    "alignment" => "left",
    "signature_line" => true,
    "date_field" => true
  }
end

# Table Snippets
invoice_table = PdfSnippet.find_or_create_by!(name: "Invoice Items Table") do |snippet|
  snippet.snippet_type = "table"
  snippet.global = true
  snippet.user = nil
  snippet.content = "Invoice Items"
  snippet.properties = {
    "columns" => [ "Description", "Quantity", "Rate", "Amount" ],
    "header_style" => {
      "font_weight" => "bold",
      "background_color" => "#3498DB",
      "text_color" => "white"
    },
    "row_style" => {
      "alternating" => true,
      "colors" => [ "#FFFFFF", "#F8F9FA" ]
    },
    "border" => true
  }
end

# Image Snippets
company_logo = PdfSnippet.find_or_create_by!(name: "Company Logo Placeholder") do |snippet|
  snippet.snippet_type = "image"
  snippet.global = true
  snippet.user = nil
  snippet.content = "Logo placeholder"
  snippet.properties = {
    "width" => 120,
    "height" => 60,
    "alignment" => "left",
    "border" => false,
    "placeholder_text" => "[Your Logo Here]"
  }
end

puts "✅ Created #{PdfSnippet.count} snippets"

# ============================================================================
# SAMPLE PDF DOCUMENTS
# ============================================================================
puts "📋 Creating sample PDF documents..."

# Sample Invoice Document
invoice_doc = PdfDocument.find_or_create_by!(
  title: "Sample Invoice - Acme Corp"
) do |doc|
  doc.user = demo_user
  doc.pdf_template = invoice_template
  doc.description = "Sample invoice document for demonstration"
  doc.status = "completed"
  doc.generated_at = 2.days.ago
  doc.metadata = {
    "created_for" => "demo",
    "template_version" => "1.0"
  }
  doc.content_data = {
    "invoice_number" => "INV-2024-001",
    "date" => Date.current.strftime("%m/%d/%Y"),
    "due_date" => (Date.current + 30.days).strftime("%m/%d/%Y"),
    "company_name" => "Demo Company LLC",
    "client_name" => "Acme Corporation",
    "total_amount" => "$2,450.00"
  }
end

# Sample Business Letter
letter_doc = PdfDocument.find_or_create_by!(
  title: "Welcome Letter - New Client"
) do |doc|
  doc.user = business_user
  doc.pdf_template = business_letter
  doc.description = "Professional welcome letter for new clients"
  doc.status = "completed"
  doc.generated_at = 1.day.ago
  doc.metadata = {
    "recipient_type" => "client",
    "priority" => "high"
  }
  doc.content_data = {
    "company_name" => "Business Solutions Inc.",
    "company_address" => "123 Innovation Drive\nTech City, TC 12345",
    "recipient_name" => "Sarah Johnson",
    "date" => Date.current.strftime("%B %d, %Y"),
    "subject" => "Welcome to Business Solutions Inc.",
    "body_text" => "Dear Sarah Johnson,\n\nWelcome to Business Solutions Inc.! We're excited to begin working with you.\n\nBest regards,\nJohn Doe"
  }
end

# Sample Certificate
certificate_doc = PdfDocument.find_or_create_by!(
  title: "Employee of the Month Certificate"
) do |doc|
  doc.user = admin_user
  doc.pdf_template = certificate_template
  doc.description = "Monthly achievement certificate"
  doc.status = "completed"
  doc.generated_at = 3.days.ago
  doc.metadata = {
    "certificate_type" => "achievement",
    "month" => Date.current.strftime("%B %Y")
  }
  doc.content_data = {
    "recipient_name" => "Alex Thompson",
    "achievement" => "Outstanding Performance and Dedication",
    "date" => Date.current.strftime("%B %Y"),
    "organization" => "Demo Company LLC"
  }
end

# Draft Document
draft_doc = PdfDocument.find_or_create_by!(
  title: "Q4 Performance Report (Draft)"
) do |doc|
  doc.user = business_user
  doc.pdf_template = business_letter
  doc.description = "Quarterly performance analysis - work in progress"
  doc.status = "draft"
  doc.metadata = {
    "version" => "draft",
    "last_edited" => Time.current
  }
  doc.content_data = {
    "report_title" => "Q4 2024 Performance Analysis",
    "period" => "October - December 2024",
    "author" => "John Doe",
    "summary" => "Comprehensive analysis of Q4 performance metrics."
  }
end

puts "✅ Created #{PdfDocument.count} documents"

# ============================================================================
# PDF ELEMENTS FOR SAMPLE DOCUMENTS
# ============================================================================
puts "🎨 Creating PDF elements..."

# Elements for Invoice Document
if invoice_doc.persisted?
  # Header element
  PdfElement.find_or_create_by!(
    pdf_document: invoice_doc,
    element_type: "text",
    page_number: 1,
    x_position: 50,
    y_position: 750
  ) do |element|
    element.width = 500
    element.height = 50
    element.z_index = 1
    element.properties = {
      "content" => {
        "text" => "INVOICE"
      },
      "styles" => {
        "font_size" => 24,
        "font_weight" => "bold",
        "color" => "#2C3E50",
        "alignment" => "center"
      }
    }
  end

  # Company info
  PdfElement.find_or_create_by!(
    pdf_document: invoice_doc,
    element_type: "text",
    page_number: 1,
    x_position: 50,
    y_position: 680
  ) do |element|
    element.width = 200
    element.height = 80
    element.z_index = 1
    element.properties = {
      "content" => {
        "text" => "Demo Company LLC\n123 Business Ave\nDemo City, DC 12345\n(555) 123-4567"
      },
      "styles" => {
        "font_size" => 10,
        "color" => "#2C3E50"
      }
    }
  end
end

puts "✅ Created #{PdfElement.count} PDF elements"

# ============================================================================
# SUMMARY
# ============================================================================
puts "\n🎉 Database seeding completed successfully!"
puts "=" * 50
puts "📊 Summary:"
puts "  • Users: #{User.count}"
puts "  • PDF Templates: #{PdfTemplate.count}"
puts "  • PDF Snippets: #{PdfSnippet.count}"
puts "  • PDF Documents: #{PdfDocument.count}"
puts "  • PDF Elements: #{PdfElement.count}"
puts "=" * 50
puts "\n🔑 Test Accounts:"
puts "  • Admin: admin@pdfeditor.com / password123"
puts "  • Demo: demo@example.com / demo123"
puts "  • Business: john.doe@business.com / business123"
puts "\n✨ Your PDF Editor application is now ready to use!"
