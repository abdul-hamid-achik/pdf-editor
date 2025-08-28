import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "documentsContainer", 
    "searchInput", 
    "sortSelect",
    "loading",
    "gridViewBtn",
    "listViewBtn",
    "dropdown"
  ]

  connect() {
    this.currentView = 'grid'
    this.documents = []
    this.filteredDocuments = []
    this.currentSort = 'updated_at_desc'
    
    this.loadDocuments()
    this.setupEventListeners()
  }

  disconnect() {
    this.removeEventListeners()
  }

  setupEventListeners() {
    // Close dropdowns when clicking outside
    document.addEventListener('click', this.closeDropdowns.bind(this))
  }

  removeEventListeners() {
    document.removeEventListener('click', this.closeDropdowns)
  }

  // Document Loading
  loadDocuments() {
    const documentCards = this.documentsContainerTarget.querySelectorAll('.document-card')
    
    this.documents = Array.from(documentCards).map(card => ({
      id: parseInt(card.dataset.documentId),
      title: card.dataset.documentTitle,
      status: card.dataset.documentStatus,
      updatedAt: new Date(card.dataset.documentUpdated),
      element: card
    }))
    
    this.filteredDocuments = [...this.documents]
  }

  // Search and Filter
  filterDocuments(event) {
    const query = event.target.value.toLowerCase().trim()
    
    if (query === '') {
      this.filteredDocuments = [...this.documents]
    } else {
      this.filteredDocuments = this.documents.filter(doc => 
        doc.title.toLowerCase().includes(query) ||
        doc.status.toLowerCase().includes(query)
      )
    }
    
    this.updateDisplay()
  }

  sortDocuments(event) {
    const sortBy = event.target.value
    this.currentSort = sortBy
    
    this.filteredDocuments.sort((a, b) => {
      switch (sortBy) {
        case 'updated_at_desc':
          return b.updatedAt - a.updatedAt
        case 'updated_at_asc':
          return a.updatedAt - b.updatedAt
        case 'title_asc':
          return a.title.localeCompare(b.title)
        case 'title_desc':
          return b.title.localeCompare(a.title)
        case 'status':
          return a.status.localeCompare(b.status)
        default:
          return 0
      }
    })
    
    this.updateDisplay()
  }

  updateDisplay() {
    // Hide all documents first
    this.documents.forEach(doc => {
      doc.element.style.display = 'none'
    })
    
    // Show filtered documents in order
    this.filteredDocuments.forEach((doc, index) => {
      doc.element.style.display = 'block'
      doc.element.style.order = index
    })
    
    // Show/hide empty state
    this.updateEmptyState()
  }

  updateEmptyState() {
    const hasDocuments = this.filteredDocuments.length > 0
    const emptyState = this.documentsContainerTarget.querySelector('.text-center.py-12')
    
    if (emptyState) {
      emptyState.style.display = hasDocuments ? 'none' : 'block'
    }
  }

  // View Toggle
  toggleView(event) {
    const view = event.params.view
    this.currentView = view
    
    // Update button states
    this.gridViewBtnTarget.classList.toggle('bg-white', view === 'grid')
    this.gridViewBtnTarget.classList.toggle('shadow-sm', view === 'grid')
    this.listViewBtnTarget.classList.toggle('bg-white', view === 'list')
    this.listViewBtnTarget.classList.toggle('shadow-sm', view === 'list')
    
    // Update container classes
    const container = this.documentsContainerTarget.querySelector('.grid')
    if (container) {
      if (view === 'list') {
        container.classList.remove('grid-cols-1', 'md:grid-cols-2', 'lg:grid-cols-3', 'xl:grid-cols-4')
        container.classList.add('grid-cols-1', 'gap-2')
        
        // Update card styles for list view
        this.documents.forEach(doc => {
          const card = doc.element
          card.classList.add('flex', 'items-center', 'p-4')
          card.classList.remove('p-6')
          
          // Rearrange card content for list view
          this.updateCardForListView(card)
        })
      } else {
        container.classList.remove('grid-cols-1', 'gap-2')
        container.classList.add('grid-cols-1', 'md:grid-cols-2', 'lg:grid-cols-3', 'xl:grid-cols-4', 'gap-6')
        
        // Update card styles for grid view
        this.documents.forEach(doc => {
          const card = doc.element
          card.classList.remove('flex', 'items-center', 'p-4')
          card.classList.add('p-6')
          
          // Restore card content for grid view
          this.updateCardForGridView(card)
        })
      }
    }
  }

  updateCardForListView(card) {
    // This would rearrange the card layout for list view
    // For now, just add a class to indicate list mode
    card.classList.add('list-mode')
  }

  updateCardForGridView(card) {
    // Restore grid layout
    card.classList.remove('list-mode')
  }

  // Document Selection
  selectDocument(event) {
    // Don't navigate if clicking on action buttons
    if (event.target.closest('button, a')) {
      return
    }
    
    const documentId = event.currentTarget.dataset.documentId
    window.location.href = `/pdf_documents/${documentId}`
  }

  // Dropdown Management
  toggleDropdown(event) {
    event.stopPropagation()
    const documentId = event.params.document
    const dropdown = this.documentsContainerTarget.querySelector(`[data-document-id="${documentId}"]`)
    
    // Close all other dropdowns first
    this.closeAllDropdowns()
    
    if (dropdown) {
      dropdown.classList.toggle('hidden')
    }
  }

  closeDropdowns(event) {
    // Close all dropdowns if clicking outside
    if (!event.target.closest('[data-action*="toggleDropdown"]')) {
      this.closeAllDropdowns()
    }
  }

  closeAllDropdowns() {
    const dropdowns = this.documentsContainerTarget.querySelectorAll('[data-document-list-target="dropdown"]')
    dropdowns.forEach(dropdown => dropdown.classList.add('hidden'))
  }

  // Document Actions
  deleteDocument(event) {
    event.stopPropagation()
    const documentId = event.params.document
    
    if (!confirm('Are you sure you want to delete this document? This action cannot be undone.')) {
      return
    }
    
    this.showLoading()
    
    fetch(`/pdf_documents/${documentId}`, {
      method: 'DELETE',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'application/json'
      }
    })
    .then(response => {
      if (response.ok) {
        return response.json()
      } else {
        throw new Error('Delete failed')
      }
    })
    .then(data => {
      if (data.success) {
        // Remove document from UI
        this.removeDocumentFromUI(documentId)
        this.showNotification('Document deleted successfully', 'success')
      } else {
        throw new Error(data.error || 'Delete failed')
      }
      this.hideLoading()
    })
    .catch(error => {
      console.error('Error deleting document:', error)
      this.showNotification('Error deleting document', 'error')
      this.hideLoading()
    })
  }

  removeDocumentFromUI(documentId) {
    // Remove from documents array
    this.documents = this.documents.filter(doc => doc.id !== parseInt(documentId))
    this.filteredDocuments = this.filteredDocuments.filter(doc => doc.id !== parseInt(documentId))
    
    // Remove from DOM
    const documentCard = this.documentsContainerTarget.querySelector(`[data-document-id="${documentId}"]`)
    if (documentCard) {
      documentCard.remove()
    }
    
    this.updateEmptyState()
  }

  duplicateDocument(event) {
    event.stopPropagation()
    const documentId = event.params.document
    
    this.showLoading()
    
    fetch(`/pdf_documents/${documentId}/duplicate`, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'application/json'
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        this.showNotification('Document duplicated successfully', 'success')
        // Optionally refresh the page or add the new document to the UI
        location.reload()
      } else {
        throw new Error(data.error || 'Duplication failed')
      }
      this.hideLoading()
    })
    .catch(error => {
      console.error('Error duplicating document:', error)
      this.showNotification('Error duplicating document', 'error')
      this.hideLoading()
    })
  }

  exportDocument(event) {
    event.stopPropagation()
    const documentId = event.params.document
    
    // This would typically open an export dialog or start a download
    window.open(`/pdf_documents/${documentId}/export`, '_blank')
  }

  // Loading States
  showLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove('hidden')
    }
    
    // Disable action buttons during loading
    const actionButtons = this.documentsContainerTarget.querySelectorAll('button, a')
    actionButtons.forEach(button => button.disabled = true)
  }

  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add('hidden')
    }
    
    // Re-enable action buttons
    const actionButtons = this.documentsContainerTarget.querySelectorAll('button, a')
    actionButtons.forEach(button => button.disabled = false)
  }

  // Bulk Actions
  selectAllDocuments() {
    const checkboxes = this.documentsContainerTarget.querySelectorAll('input[type="checkbox"]')
    const allChecked = Array.from(checkboxes).every(cb => cb.checked)
    
    checkboxes.forEach(checkbox => {
      checkbox.checked = !allChecked
    })
    
    this.updateBulkActions()
  }

  updateBulkActions() {
    const selectedCount = this.documentsContainerTarget.querySelectorAll('input[type="checkbox"]:checked').length
    const bulkActions = document.querySelector('.bulk-actions')
    
    if (bulkActions) {
      if (selectedCount > 0) {
        bulkActions.classList.remove('hidden')
        bulkActions.querySelector('.selected-count').textContent = selectedCount
      } else {
        bulkActions.classList.add('hidden')
      }
    }
  }

  bulkDelete() {
    const selectedCheckboxes = this.documentsContainerTarget.querySelectorAll('input[type="checkbox"]:checked')
    const selectedIds = Array.from(selectedCheckboxes).map(cb => cb.value)
    
    if (selectedIds.length === 0) return
    
    if (!confirm(`Are you sure you want to delete ${selectedIds.length} documents? This action cannot be undone.`)) {
      return
    }
    
    this.showLoading()
    
    Promise.all(selectedIds.map(id => 
      fetch(`/pdf_documents/${id}`, {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      })
    ))
    .then(() => {
      this.showNotification(`${selectedIds.length} documents deleted successfully`, 'success')
      selectedIds.forEach(id => this.removeDocumentFromUI(id))
      this.hideLoading()
    })
    .catch(error => {
      console.error('Error deleting documents:', error)
      this.showNotification('Error deleting some documents', 'error')
      this.hideLoading()
    })
  }

  // Notifications
  showNotification(message, type = 'info') {
    const notification = document.createElement('div')
    notification.className = `fixed top-4 right-4 p-4 rounded-lg text-white z-50 transition-all duration-300 ${
      type === 'success' ? 'bg-green-500' : 
      type === 'error' ? 'bg-red-500' : 
      type === 'warning' ? 'bg-yellow-500' : 'bg-blue-500'
    }`
    notification.innerHTML = `
      <div class="flex items-center space-x-2">
        <span>${message}</span>
        <button onclick="this.parentElement.parentElement.remove()" class="text-white hover:text-gray-200">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
          </svg>
        </button>
      </div>
    `
    
    document.body.appendChild(notification)
    
    // Auto remove after delay
    setTimeout(() => {
      if (notification.parentNode) {
        notification.style.transform = 'translateX(100%)'
        setTimeout(() => notification.remove(), 300)
      }
    }, 5000)
  }
}