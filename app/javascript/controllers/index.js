// Import and register all your controllers manually
import { application } from "./application"

// Import all controllers
import HelloController from "./hello_controller"
import DocumentListController from "./document_list_controller"
import PdfEditorController from "./pdf_editor_controller"
import PdfPreviewController from "./pdf_preview_controller"
import ThemeToggleController from "./theme_toggle_controller"

// Register controllers
application.register("hello", HelloController)
application.register("document-list", DocumentListController)
application.register("pdf-editor", PdfEditorController)
application.register("pdf-preview", PdfPreviewController)
application.register("theme-toggle", ThemeToggleController)
