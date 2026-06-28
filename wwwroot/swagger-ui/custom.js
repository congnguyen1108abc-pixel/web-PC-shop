// ============================================================
// SWAGGER UI - DARK MODE TOGGLE
// ============================================================

(function() {
    'use strict';

    // Wait for DOM to be ready
    function initThemeToggle() {
        // Check if button already exists
        if (document.querySelector('.theme-toggle')) {
            return;
        }

        // Wait for topbar to be ready
        const topbar = document.querySelector('.swagger-ui .topbar');
        if (!topbar) {
            setTimeout(initThemeToggle, 100);
            return;
        }

        // Create toggle button
        const toggleButton = document.createElement('button');
        toggleButton.className = 'theme-toggle';
        toggleButton.setAttribute('aria-label', 'Toggle dark mode');
        toggleButton.setAttribute('title', 'Chuyển đổi chế độ sáng/tối (Ctrl+Shift+D)');
        
        // Set initial icon
        const isDarkMode = localStorage.getItem('swagger-theme') === 'dark';
        toggleButton.innerHTML = isDarkMode ? '🌙' : '☀️';
        
        // Apply saved theme
        if (isDarkMode) {
            document.body.classList.add('dark-mode');
        }

        // Add click handler
        toggleButton.addEventListener('click', function() {
            const body = document.body;
            const isDark = body.classList.toggle('dark-mode');
            
            // Update icon
            this.innerHTML = isDark ? '🌙' : '☀️';
            
            // Save preference
            localStorage.setItem('swagger-theme', isDark ? 'dark' : 'light');
            
            // Add animation
            this.style.transform = 'scale(1.3)';
            setTimeout(() => {
                this.style.transform = 'scale(1)';
            }, 200);
        });

        // Add to topbar (right side, kế bên PC_Store API v1)
        topbar.appendChild(toggleButton);
    }

    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initThemeToggle);
    } else {
        initThemeToggle();
    }

    // Re-initialize if Swagger UI reloads content
    const observer = new MutationObserver(function(mutations) {
        mutations.forEach(function(mutation) {
            if (mutation.addedNodes.length) {
                initThemeToggle();
            }
        });
    });

    // Start observing
    if (document.body) {
        observer.observe(document.body, {
            childList: true,
            subtree: true
        });
    }

    // Keyboard shortcut: Ctrl+Shift+D to toggle dark mode
    document.addEventListener('keydown', function(e) {
        if (e.ctrlKey && e.shiftKey && e.key === 'D') {
            e.preventDefault();
            const button = document.querySelector('.theme-toggle');
            if (button) {
                button.click();
            }
        }
    });

    console.log('✅ Swagger Dark Mode Toggle initialized');
    console.log('💡 Tip: Press Ctrl+Shift+D to toggle dark mode');
})();
