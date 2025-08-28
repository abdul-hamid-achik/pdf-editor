import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    documentId: Number,
    zoom: { type: Number, default: 1 },
    currentPage: { type: Number, default: 1 },
    totalPages: { type: Number, default: 1 }
  }
  
  static targets = [
    "pageContainer", 
    "pageInput", 
    "zoomSelect",
    "prevButton",
    "nextButton",
    "loadingOverlay"
  ]

  connect() {
    this.updateNavigationButtons()
    this.setupKeyboardShortcuts()
    this.setupFullscreenDetection()
  }

  disconnect() {
    document.removeEventListener('keydown', this.handleKeyDown)
    document.removeEventListener('fullscreenchange', this.handleFullscreenChange)
  }

  setupKeyboardShortcuts() {
    document.addEventListener('keydown', this.handleKeyDown.bind(this))
  }

  setupFullscreenDetection() {
    document.addEventListener('fullscreenchange', this.handleFullscreenChange.bind(this))
  }

  // Page Navigation
  selectPage(event) {
    const pageNumber = parseInt(event.params.page)
    this.goToPageNumber(pageNumber)
  }

  previousPage() {
    if (this.currentPageValue > 1) {
      this.currentPageValue -= 1
      this.goToPageNumber(this.currentPageValue)
    }
  }

  nextPage() {
    if (this.currentPageValue < this.totalPagesValue) {
      this.currentPageValue += 1
      this.goToPageNumber(this.currentPageValue)
    }
  }

  goToPage(event) {
    const pageNumber = parseInt(event.target.value)
    if (pageNumber >= 1 && pageNumber <= this.totalPagesValue) {
      this.currentPageValue = pageNumber
      this.goToPageNumber(pageNumber)
    } else {
      // Reset to current page if invalid
      event.target.value = this.currentPageValue
    }
  }

  goToPageNumber(pageNumber) {
    // Hide all pages
    const pages = this.pageContainerTarget.querySelectorAll('.page-container')
    pages.forEach(page => page.classList.add('hidden'))
    
    // Show selected page
    const targetPage = this.pageContainerTarget.querySelector(`[data-page="${pageNumber}"]`)
    if (targetPage) {
      targetPage.classList.remove('hidden')
      targetPage.scrollIntoView({ behavior: 'smooth', block: 'center' })
    }
    
    // Update input
    if (this.hasPageInputTarget) {
      this.pageInputTarget.value = pageNumber
    }
    
    this.currentPageValue = pageNumber
    this.updateNavigationButtons()
  }

  updateNavigationButtons() {
    if (this.hasPrevButtonTarget) {
      this.prevButtonTarget.disabled = this.currentPageValue <= 1
      if (this.currentPageValue <= 1) {
        this.prevButtonTarget.classList.add('text-gray-600')
        this.prevButtonTarget.classList.remove('text-white')
      } else {
        this.prevButtonTarget.classList.remove('text-gray-600')
        this.prevButtonTarget.classList.add('text-white')
      }
    }
    
    if (this.hasNextButtonTarget) {
      this.nextButtonTarget.disabled = this.currentPageValue >= this.totalPagesValue
      if (this.currentPageValue >= this.totalPagesValue) {
        this.nextButtonTarget.classList.add('text-gray-600')
        this.nextButtonTarget.classList.remove('text-white')
      } else {
        this.nextButtonTarget.classList.remove('text-gray-600')
        this.nextButtonTarget.classList.add('text-white')
      }
    }
  }

  // Zoom Controls
  zoomIn() {
    const currentZoom = this.zoomValue
    const newZoom = Math.min(currentZoom * 1.25, 3) // Max 300%
    this.setZoom(newZoom)
  }

  zoomOut() {
    const currentZoom = this.zoomValue
    const newZoom = Math.max(currentZoom / 1.25, 0.25) // Min 25%
    this.setZoom(newZoom)
  }

  changeZoom(event) {
    const zoomValue = event.target.value
    
    if (zoomValue === 'fit-width') {
      this.fitToWidth()
    } else if (zoomValue === 'fit-page') {
      this.fitToPage()
    } else {
      this.setZoom(parseFloat(zoomValue))
    }
  }

  setZoom(zoom) {
    this.zoomValue = zoom
    this.applyZoom()
    
    // Update zoom select if it's a standard value
    if (this.hasZoomSelectTarget) {
      const option = this.zoomSelectTarget.querySelector(`option[value="${zoom}"]`)
      if (option) {
        this.zoomSelectTarget.value = zoom
      } else {
        // Add custom zoom level
        const customOption = document.createElement('option')
        customOption.value = zoom
        customOption.textContent = `${Math.round(zoom * 100)}%`
        customOption.selected = true
        this.zoomSelectTarget.appendChild(customOption)
      }
    }
  }

  applyZoom() {
    const pages = this.pageContainerTarget.querySelectorAll('.page-container')
    pages.forEach(page => {
      page.style.transform = `scale(${this.zoomValue})`
      page.style.transformOrigin = 'top center'
      page.style.marginBottom = `${(this.zoomValue - 1) * page.offsetHeight + 32}px`
    })
  }

  fitToWidth() {
    const container = this.pageContainerTarget.parentElement
    const page = this.pageContainerTarget.querySelector('.page-container')
    
    if (page) {
      const containerWidth = container.offsetWidth - 64 // Account for padding
      const pageWidth = 612 // Standard page width
      const zoom = containerWidth / pageWidth
      this.setZoom(zoom)
    }
  }

  fitToPage() {
    const container = this.pageContainerTarget.parentElement
    const page = this.pageContainerTarget.querySelector('.page-container')
    
    if (page) {
      const containerWidth = container.offsetWidth - 64
      const containerHeight = container.offsetHeight - 100 // Account for toolbar
      const pageWidth = 612
      const pageHeight = 792
      
      const zoomX = containerWidth / pageWidth
      const zoomY = containerHeight / pageHeight
      const zoom = Math.min(zoomX, zoomY)
      
      this.setZoom(zoom)
    }
  }

  // Document Actions
  downloadPdf() {
    this.showLoading()
    
    fetch(`/pdf_documents/${this.documentIdValue}/download`, {
      method: 'GET',
      headers: {
        'Accept': 'application/pdf'
      }
    })
    .then(response => {
      if (response.ok) {
        return response.blob()
      } else {
        throw new Error('Download failed')
      }
    })
    .then(blob => {
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `document-${this.documentIdValue}.pdf`
      document.body.appendChild(a)
      a.click()
      document.body.removeChild(a)
      window.URL.revokeObjectURL(url)
      this.hideLoading()
    })
    .catch(error => {
      console.error('Error downloading PDF:', error)
      this.showNotification('Error downloading PDF', 'error')
      this.hideLoading()
    })
  }

  printPdf() {
    // For printing, we'll open the PDF in a new window
    const printWindow = window.open(`/pdf_documents/${this.documentIdValue}/print`, '_blank')
    
    if (printWindow) {
      printWindow.onload = () => {
        printWindow.print()
      }
    } else {
      this.showNotification('Please allow popups to print', 'warning')
    }
  }

  refreshPreview() {
    this.showLoading()
    
    fetch(`/pdf_documents/${this.documentIdValue}/preview_data`, {
      method: 'GET',
      headers: {
        'Accept': 'application/json'
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // Update preview content
        this.updatePreviewContent(data.preview_data)
        this.showNotification('Preview refreshed', 'success')
      } else {
        throw new Error(data.error || 'Refresh failed')
      }
      this.hideLoading()
    })
    .catch(error => {
      console.error('Error refreshing preview:', error)
      this.showNotification('Error refreshing preview', 'error')
      this.hideLoading()
    })
  }

  generatePreview() {
    this.showLoading()
    
    fetch(`/pdf_documents/${this.documentIdValue}/generate_preview`, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'application/json'
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        location.reload() // Reload to show the new preview
      } else {
        throw new Error(data.error || 'Preview generation failed')
      }
    })
    .catch(error => {
      console.error('Error generating preview:', error)
      this.showNotification('Error generating preview', 'error')
      this.hideLoading()
    })
  }

  updatePreviewContent(previewData) {
    // This would update the preview content dynamically
    // For now, we'll reload the page to get the updated content
    location.reload()
  }

  // Fullscreen
  toggleFullscreen() {
    if (document.fullscreenElement) {
      document.exitFullscreen()
    } else {
      this.element.requestFullscreen().catch(err => {
        console.error('Error attempting to enable fullscreen:', err)
        this.showNotification('Fullscreen not supported', 'warning')
      })
    }
  }

  handleFullscreenChange() {
    const isFullscreen = !!document.fullscreenElement
    const fullscreenBtn = this.element.querySelector('[data-action*="toggleFullscreen"]')
    
    if (fullscreenBtn) {
      fullscreenBtn.textContent = isFullscreen ? 'Exit Fullscreen' : 'Fullscreen'
    }
    
    // Adjust layout for fullscreen
    if (isFullscreen) {
      this.element.classList.add('fullscreen-mode')
    } else {
      this.element.classList.remove('fullscreen-mode')
    }
  }

  // Keyboard Shortcuts
  handleKeyDown(event) {
    // Only handle shortcuts when this preview is active
    if (!this.element.contains(document.activeElement) && 
        !this.element.matches(':focus-within')) {
      return
    }
    
    switch (event.key) {
      case 'ArrowLeft':
      case 'PageUp':
        event.preventDefault()
        this.previousPage()
        break
        
      case 'ArrowRight':
      case 'PageDown':
      case ' ': // Spacebar
        event.preventDefault()
        this.nextPage()
        break
        
      case 'Home':
        event.preventDefault()
        this.goToPageNumber(1)
        break
        
      case 'End':
        event.preventDefault()
        this.goToPageNumber(this.totalPagesValue)
        break
        
      case '+':
      case '=':
        if (event.ctrlKey || event.metaKey) {
          event.preventDefault()
          this.zoomIn()
        }
        break
        
      case '-':
        if (event.ctrlKey || event.metaKey) {
          event.preventDefault()
          this.zoomOut()
        }
        break
        
      case '0':
        if (event.ctrlKey || event.metaKey) {
          event.preventDefault()
          this.setZoom(1) // Reset to 100%
        }
        break
        
      case 'f':
        if (event.ctrlKey || event.metaKey) {
          event.preventDefault()
          this.fitToPage()
        }
        break
        
      case 'F11':
        event.preventDefault()
        this.toggleFullscreen()
        break
        
      case 'p':
        if (event.ctrlKey || event.metaKey) {
          event.preventDefault()
          this.printPdf()
        }
        break
        
      case 's':
        if (event.ctrlKey || event.metaKey) {
          event.preventDefault()
          this.downloadPdf()
        }
        break
    }
  }

  // Loading States
  showLoading() {
    if (this.hasLoadingOverlayTarget) {
      this.loadingOverlayTarget.classList.remove('hidden')
    }
  }

  hideLoading() {
    if (this.hasLoadingOverlayTarget) {
      this.loadingOverlayTarget.classList.add('hidden')
    }
  }

  // Notifications
  showNotification(message, type = 'info') {
    const notification = document.createElement('div')
    notification.className = `fixed top-4 right-4 p-4 rounded-lg text-white z-50 transition-all duration-300 ${
      type === 'success' ? 'bg-green-500' : 
      type === 'error' ? 'bg-red-500' : 
      type === 'warning' ? 'bg-yellow-500' : 'bg-blue-500'
    }`
    notification.textContent = message
    
    document.body.appendChild(notification)
    
    // Animate in
    setTimeout(() => {
      notification.style.transform = 'translateX(0)'
    }, 10)
    
    // Remove after delay
    setTimeout(() => {
      notification.style.transform = 'translateX(100%)'
      setTimeout(() => {
        if (notification.parentNode) {
          notification.remove()
        }
      }, 300)
    }, 3000)
  }
}