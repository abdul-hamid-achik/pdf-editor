import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="theme-toggle"
export default class extends Controller {
    static targets = ["icon"]

    connect() {
        // Check for saved theme preference or default to light
        const savedTheme = localStorage.getItem('theme')
        const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches

        if (savedTheme === 'dark' || (!savedTheme && prefersDark)) {
            this.enableDarkMode()
        } else {
            this.enableLightMode()
        }

        // Update icon on connect
        this.updateIcon()
    }

    toggle() {
        if (document.documentElement.classList.contains('dark')) {
            this.enableLightMode()
        } else {
            this.enableDarkMode()
        }
        this.updateIcon()
    }

    enableDarkMode() {
        document.documentElement.classList.add('dark')
        localStorage.setItem('theme', 'dark')
    }

    enableLightMode() {
        document.documentElement.classList.remove('dark')
        localStorage.setItem('theme', 'light')
    }

    updateIcon() {
        const isDark = document.documentElement.classList.contains('dark')

        if (this.hasIconTarget) {
            // Update the icon based on current theme
            if (isDark) {
                // Show sun icon (for switching to light)
                this.iconTarget.innerHTML = `
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                  d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"/>
          </svg>
        `
            } else {
                // Show moon icon (for switching to dark)
                this.iconTarget.innerHTML = `
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                  d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"/>
          </svg>
        `
            }
        }
    }
}
