import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    documentId: Number,
    zoom: { type: Number, default: 1 },
    currentPage: { type: Number, default: 1 }
  }

  static targets = [
    "canvas",
    "propertiesPanel",
    "elementProperties",
    "documentProperties",
    "selectionLayer",
    "pageSelect",
    "zoomSelect",
    "elementCount"
  ]

  connect() {
    this.selectedElement = null
    this.selectedTool = 'select'
    this.isDragging = false
    this.isResizing = false
    this.dragStartPos = { x: 0, y: 0 }
    this.elementStartPos = { x: 0, y: 0 }
    this.undoStack = []
    this.redoStack = []

    this.setupEventListeners()
    this.updateElementCount()
  }

  disconnect() {
    this.removeEventListeners()
  }

  setupEventListeners() {
    // Global mouse events for dragging
    document.addEventListener('mousemove', this.handleMouseMove.bind(this))
    document.addEventListener('mouseup', this.handleMouseUp.bind(this))

    // Keyboard shortcuts
    document.addEventListener('keydown', this.handleKeyDown.bind(this))

    // Prevent context menu on canvas
    this.canvasTarget.addEventListener('contextmenu', (e) => e.preventDefault())
  }

  removeEventListeners() {
    document.removeEventListener('mousemove', this.handleMouseMove)
    document.removeEventListener('mouseup', this.handleMouseUp)
    document.removeEventListener('keydown', this.handleKeyDown)
  }

  // Tool Selection
  selectTool(event) {
    const tool = event.params.tool
    this.selectedTool = tool

    // Update tool buttons visual state
    const toolButtons = this.element.querySelectorAll('[data-pdf-editor-tool-param]')
    toolButtons.forEach(btn => btn.classList.remove('bg-blue-100', 'text-blue-700'))
    event.target.closest('button').classList.add('bg-blue-100', 'text-blue-700')

    // Clear selection if not select tool
    if (tool !== 'select') {
      this.clearSelection()
    }

    // Change cursor based on tool
    this.updateCanvasCursor(tool)
  }

  updateCanvasCursor(tool) {
    const cursorMap = {
      select: 'default',
      text: 'text',
      image: 'copy',
      shape: 'crosshair',
      line: 'crosshair',
      table: 'cell',
      signature: 'pointer'
    }

    this.canvasTarget.style.cursor = cursorMap[tool] || 'default'
  }

  // Canvas Interaction
  canvasClick(event) {
    if (event.target === this.canvasTarget) {
      const rect = this.canvasTarget.getBoundingClientRect()
      const x = (event.clientX - rect.left) / this.zoomValue
      const y = (event.clientY - rect.top) / this.zoomValue

      if (this.selectedTool !== 'select') {
        this.createNewElement(this.selectedTool, x, y)
      } else {
        this.clearSelection()
      }
    }
  }

  canvasContextMenu(event) {
    event.preventDefault()
    // Could show context menu here
  }

  // Element Selection
  selectElement(event) {
    event.stopPropagation()
    const elementDiv = event.target.closest('.pdf-element')

    if (this.selectedElement) {
      this.clearSelection()
    }

    this.selectedElement = elementDiv
    this.showElementHandles(elementDiv)
    this.showElementProperties(elementDiv)

    elementDiv.classList.add('selected')
  }

  clearSelection() {
    if (this.selectedElement) {
      this.selectedElement.classList.remove('selected')
      this.hideElementHandles(this.selectedElement)
      this.selectedElement = null
    }

    this.hideElementProperties()
  }

  showElementHandles(element) {
    const handles = element.querySelector('.element-handles')
    if (handles) {
      handles.classList.remove('hidden')
    }
  }

  hideElementHandles(element) {
    const handles = element.querySelector('.element-handles')
    if (handles) {
      handles.classList.add('hidden')
    }
  }

  // Element Creation
  createNewElement(type, x, y) {
    const elementData = this.getDefaultElementData(type, x, y)

    fetch(`/pdf_documents/${this.documentIdValue}/pdf_elements`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ pdf_element: elementData })
    })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          this.addElementToCanvas(data.element)
          this.updateElementCount()
          this.pushToUndoStack()
        }
      })
      .catch(error => console.error('Error creating element:', error))
  }

  getDefaultElementData(type, x, y) {
    const defaults = {
      text: {
        element_type: 'text',
        page_number: this.currentPageValue || 1,
        x_position: x,
        y_position: y,
        width: 200,
        height: 30,
        z_index: 1,
        content: { text: 'New text' },
        styles: { font_size: 12, font_family: 'Arial', color: '#000000' }
      },
      image: {
        element_type: 'image',
        page_number: this.currentPageValue || 1,
        x_position: x,
        y_position: y,
        width: 150,
        height: 100,
        z_index: 1,
        content: { image_url: '', alt_text: 'Image' },
        styles: {}
      },
      shape: {
        element_type: 'shape',
        page_number: this.currentPageValue || 1,
        x_position: x,
        y_position: y,
        width: 100,
        height: 100,
        z_index: 1,
        content: { shape_type: 'rectangle' },
        styles: { fill_color: '#3B82F6', border_color: '#1E40AF', border_width: 1 }
      },
      line: {
        element_type: 'line',
        page_number: this.currentPageValue || 1,
        x_position: x,
        y_position: y,
        width: 200,
        height: 20,
        z_index: 1,
        content: {},
        styles: { color: '#000000', line_width: 1, line_style: 'solid' }
      },
      table: {
        element_type: 'table',
        page_number: this.currentPageValue || 1,
        x_position: x,
        y_position: y,
        width: 300,
        height: 150,
        z_index: 1,
        content: { rows: 3, columns: 3, table_data: [] },
        styles: {}
      },
      signature: {
        element_type: 'signature',
        page_number: this.currentPageValue || 1,
        x_position: x,
        y_position: y,
        width: 200,
        height: 80,
        z_index: 1,
        content: { signature_type: 'text', show_labels: true, show_date: false },
        styles: { font_size: 18 }
      }
    }

    return defaults[type] || defaults.text
  }

  addElementToCanvas(elementData) {
    // Create element HTML dynamically if provided
    if (elementData.html) {
      this.canvasTarget.insertAdjacentHTML('beforeend', elementData.html)
    } else {
      // Fallback: reload the page
      location.reload()
    }
  }

  // Element Dragging
  startDrag(event) {
    if (this.selectedTool !== 'select') return

    event.preventDefault()
    const elementDiv = event.target.closest('.pdf-element')

    if (event.target.closest('.resize-handle')) {
      this.startResize(event, elementDiv)
      return
    }

    this.isDragging = true
    this.selectedElement = elementDiv

    const rect = this.canvasTarget.getBoundingClientRect()
    this.dragStartPos = {
      x: event.clientX - rect.left,
      y: event.clientY - rect.top
    }

    const elementRect = elementDiv.getBoundingClientRect()
    const canvasRect = this.canvasTarget.getBoundingClientRect()
    this.elementStartPos = {
      x: elementRect.left - canvasRect.left,
      y: elementRect.top - canvasRect.top
    }

    elementDiv.style.zIndex = '1000'
  }

  startResize(event, elementDiv) {
    event.stopPropagation()
    this.isResizing = true
    this.selectedElement = elementDiv
    this.resizeHandle = event.target

    const rect = this.canvasTarget.getBoundingClientRect()
    this.dragStartPos = {
      x: event.clientX - rect.left,
      y: event.clientY - rect.top
    }

    const elementRect = elementDiv.getBoundingClientRect()
    const canvasRect = this.canvasTarget.getBoundingClientRect()
    this.elementStartPos = {
      x: elementRect.left - canvasRect.left,
      y: elementRect.top - canvasRect.top,
      width: elementRect.width,
      height: elementRect.height
    }
  }

  handleMouseMove(event) {
    if (this.isDragging && this.selectedElement) {
      const rect = this.canvasTarget.getBoundingClientRect()
      const currentPos = {
        x: event.clientX - rect.left,
        y: event.clientY - rect.top
      }

      const deltaX = currentPos.x - this.dragStartPos.x
      const deltaY = currentPos.y - this.dragStartPos.y

      const newX = this.elementStartPos.x + deltaX
      const newY = this.elementStartPos.y + deltaY

      this.selectedElement.style.left = `${newX}px`
      this.selectedElement.style.top = `${newY}px`

    } else if (this.isResizing && this.selectedElement) {
      const rect = this.canvasTarget.getBoundingClientRect()
      const currentPos = {
        x: event.clientX - rect.left,
        y: event.clientY - rect.top
      }

      const deltaX = currentPos.x - this.dragStartPos.x
      const deltaY = currentPos.y - this.dragStartPos.y

      this.handleElementResize(deltaX, deltaY)
    }
  }

  handleElementResize(deltaX, deltaY) {
    const element = this.selectedElement
    const handle = this.resizeHandle

    if (handle.classList.contains('se-resize')) {
      const newWidth = this.elementStartPos.width + deltaX
      const newHeight = this.elementStartPos.height + deltaY
      element.style.width = `${Math.max(20, newWidth)}px`
      element.style.height = `${Math.max(20, newHeight)}px`
    } else if (handle.classList.contains('nw-resize')) {
      const newWidth = this.elementStartPos.width - deltaX
      const newHeight = this.elementStartPos.height - deltaY
      const newX = this.elementStartPos.x + deltaX
      const newY = this.elementStartPos.y + deltaY

      if (newWidth > 20 && newHeight > 20) {
        element.style.width = `${newWidth}px`
        element.style.height = `${newHeight}px`
        element.style.left = `${newX}px`
        element.style.top = `${newY}px`
      }
    }
    // Add more resize handle logic as needed
  }

  handleMouseUp(event) {
    if (this.isDragging && this.selectedElement) {
      this.isDragging = false
      this.selectedElement.style.zIndex = ''
      this.updateElementPosition()
      this.pushToUndoStack()

    } else if (this.isResizing && this.selectedElement) {
      this.isResizing = false
      this.updateElementSize()
      this.pushToUndoStack()
    }
  }

  updateElementPosition() {
    if (!this.selectedElement) return

    const elementId = this.selectedElement.dataset.elementId
    const rect = this.selectedElement.getBoundingClientRect()
    const canvasRect = this.canvasTarget.getBoundingClientRect()

    const data = {
      x_position: (rect.left - canvasRect.left) / this.zoomValue,
      y_position: (rect.top - canvasRect.top) / this.zoomValue,
      width: rect.width / this.zoomValue,
      height: rect.height / this.zoomValue
    }

    this.updateElementData(elementId, data)
  }

  updateElementSize() {
    this.updateElementPosition() // Same logic for now
  }

  updateElementData(elementId, data) {
    fetch(`/pdf_documents/${this.documentIdValue}/pdf_elements/${elementId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ pdf_element: data })
    })
      .catch(error => console.error('Error updating element:', error))
  }

  // Properties Panel
  showElementProperties(element) {
    this.elementPropertiesTarget.classList.remove('hidden')
    this.documentPropertiesTarget.classList.add('hidden')

    // Load element-specific properties form
    const elementId = element.dataset.elementId
    const elementType = element.dataset.elementType

    // This would typically load a properties form via Turbo
    this.loadElementPropertiesForm(elementId, elementType)
  }

  updateElementProperty(event) {
    if (!this.selectedElement) return

    const elementId = this.selectedElement.dataset.elementId
    const property = event.target.dataset.property
    const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value

    // Create nested property object
    const data = this.createNestedProperty(property, value)

    this.updateElementData(elementId, data)
  }

  createNestedProperty(path, value) {
    const keys = path.split('.')
    const result = {}

    let current = result
    for (let i = 0; i < keys.length - 1; i++) {
      current[keys[i]] = {}
      current = current[keys[i]]
    }

    current[keys[keys.length - 1]] = value
    return result
  }

  hideElementProperties() {
    this.elementPropertiesTarget.classList.add('hidden')
    this.documentPropertiesTarget.classList.remove('hidden')
  }

  loadElementPropertiesForm(elementId, elementType) {
    fetch(`/pdf_documents/${this.documentIdValue}/pdf_elements/${elementId}/edit`)
      .then(response => response.text())
      .then(html => {
        this.elementPropertiesTarget.innerHTML = html
      })
      .catch(error => console.error('Error loading properties:', error))
  }

  // Document Operations
  updateDocumentProperty(event) {
    const property = event.target.dataset.property
    const value = event.target.value

    const data = {}
    data[property] = value

    fetch(`/pdf_documents/${this.documentIdValue}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ pdf_document: data })
    })
      .catch(error => console.error('Error updating document:', error))
  }

  saveDocument() {
    fetch(`/pdf_documents/${this.documentIdValue}/generate`, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          this.showNotification('Document saved successfully', 'success')
        } else {
          this.showNotification('Error saving document', 'error')
        }
      })
      .catch(error => {
        console.error('Error saving document:', error)
        this.showNotification('Error saving document', 'error')
      })
  }

  previewDocument() {
    window.open(`/pdf_documents/${this.documentIdValue}/preview`, '_blank')
  }

  // Page Management
  changePage(event) {
    this.currentPageValue = parseInt(event.target.value)
    // Implement page switching logic
  }

  // Zoom Controls
  changeZoom(event) {
    this.zoomValue = parseFloat(event.target.value)
    this.applyZoom()
  }

  applyZoom() {
    this.canvasTarget.style.transform = `scale(${this.zoomValue})`
    this.canvasTarget.style.transformOrigin = 'top left'
  }

  // Undo/Redo
  undo() {
    if (this.undoStack.length > 0) {
      const state = this.undoStack.pop()
      this.redoStack.push(this.getCurrentState())
      this.restoreState(state)
    }
  }

  redo() {
    if (this.redoStack.length > 0) {
      const state = this.redoStack.pop()
      this.undoStack.push(this.getCurrentState())
      this.restoreState(state)
    }
  }

  pushToUndoStack() {
    const state = this.getCurrentState()
    this.undoStack.push(state)
    this.redoStack = [] // Clear redo stack

    // Limit undo stack size
    if (this.undoStack.length > 50) {
      this.undoStack.shift()
    }
  }

  getCurrentState() {
    // Return serializable state of the document
    return {
      timestamp: Date.now(),
      elements: Array.from(this.canvasTarget.querySelectorAll('.pdf-element')).map(el => ({
        id: el.dataset.elementId,
        position: {
          x: parseInt(el.style.left) || 0,
          y: parseInt(el.style.top) || 0,
          width: parseInt(el.style.width) || 0,
          height: parseInt(el.style.height) || 0
        }
      }))
    }
  }

  restoreState(state) {
    // Restore elements to previous state
    state.elements.forEach(elementState => {
      const element = this.canvasTarget.querySelector(`[data-element-id="${elementState.id}"]`)
      if (element) {
        element.style.left = `${elementState.position.x}px`
        element.style.top = `${elementState.position.y}px`
        element.style.width = `${elementState.position.width}px`
        element.style.height = `${elementState.position.height}px`
      }
    })
  }

  // Keyboard Shortcuts
  handleKeyDown(event) {
    if (event.ctrlKey || event.metaKey) {
      switch (event.key) {
        case 'z':
          event.preventDefault()
          if (event.shiftKey) {
            this.redo()
          } else {
            this.undo()
          }
          break
        case 's':
          event.preventDefault()
          this.saveDocument()
          break
      }
    }

    // Delete selected element
    if (event.key === 'Delete' && this.selectedElement) {
      this.deleteSelectedElement()
    }
  }

  deleteSelectedElement() {
    if (!this.selectedElement) return

    const elementId = this.selectedElement.dataset.elementId

    fetch(`/pdf_documents/${this.documentIdValue}/pdf_elements/${elementId}`, {
      method: 'DELETE',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })
      .then(response => {
        if (response.ok) {
          this.selectedElement.remove()
          this.selectedElement = null
          this.updateElementCount()
          this.pushToUndoStack()
        }
      })
      .catch(error => console.error('Error deleting element:', error))
  }

  duplicateElement() {
    if (!this.selectedElement) return

    const elementId = this.selectedElement.dataset.elementId

    // First get the element data
    fetch(`/pdf_documents/${this.documentIdValue}/pdf_elements/${elementId}`)
      .then(response => response.json())
      .then(elementData => {
        // Create a copy with slight offset
        const duplicateData = {
          ...elementData,
          x_position: elementData.x_position + 20,
          y_position: elementData.y_position + 20
        }
        delete duplicateData.id // Remove ID so a new one is created

        // Create the duplicate
        return fetch(`/pdf_documents/${this.documentIdValue}/pdf_elements`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
          },
          body: JSON.stringify({ pdf_element: duplicateData })
        })
      })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          this.addElementToCanvas(data)
          this.updateElementCount()
          this.pushToUndoStack()
        }
      })
      .catch(error => console.error('Error duplicating element:', error))
  }

  // Helper Methods
  updateElementCount() {
    if (this.hasElementCountTarget) {
      const count = this.canvasTarget.querySelectorAll('.pdf-element').length
      this.elementCountTarget.textContent = count
    }
  }

  showNotification(message, type = 'info') {
    // Simple notification system
    const notification = document.createElement('div')
    notification.className = `fixed top-4 right-4 p-4 rounded-lg text-white z-50 ${type === 'success' ? 'bg-green-500' :
      type === 'error' ? 'bg-red-500' : 'bg-blue-500'
      }`
    notification.textContent = message

    document.body.appendChild(notification)

    setTimeout(() => {
      notification.remove()
    }, 3000)
  }
}