// Professional Navigation JavaScript
// Handles mobile menu toggle and navigation functionality

// Toggle mobile menu
function toggleMobileMenu() {
    const navLinks = document.getElementById('navLinks');
    const mobileToggle = document.querySelector('.mobile-menu-toggle');
    
    if (navLinks && mobileToggle) {
        navLinks.classList.toggle('active');
        
        // Update toggle button icon
        const icon = mobileToggle.querySelector('i');
        if (navLinks.classList.contains('active')) {
            icon.classList.remove('fa-bars');
            icon.classList.add('fa-times');
        } else {
            icon.classList.remove('fa-times');
            icon.classList.add('fa-bars');
        }
    }
}

// Close mobile menu when clicking outside
document.addEventListener('click', function(event) {
    const navLinks = document.getElementById('navLinks');
    const mobileToggle = document.querySelector('.mobile-menu-toggle');
    const navContainer = document.querySelector('.nav-container');
    
    if (navLinks && navLinks.classList.contains('active')) {
        // Check if click is outside the navigation
        if (!navContainer.contains(event.target)) {
            navLinks.classList.remove('active');
            
            // Reset toggle button icon
            if (mobileToggle) {
                const icon = mobileToggle.querySelector('i');
                icon.classList.remove('fa-times');
                icon.classList.add('fa-bars');
            }
        }
    }
});

// Set active navigation link based on current page
function setActiveNavLink() {
    const currentPage = window.location.pathname.split('/').pop() || 'index.html';
    const navLinks = document.querySelectorAll('.nav-links a');
    
    navLinks.forEach(link => {
        link.classList.remove('active');
        
        // Get the href attribute and extract the page name
        const linkPage = link.getAttribute('href').split('/').pop() || 'index.html';
        
        // Set active class if this link matches the current page
        if (linkPage === currentPage) {
            link.classList.add('active');
        }
    });
}

// Initialize navigation when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    setActiveNavLink();
    
    // Add smooth scrolling for anchor links
    const anchorLinks = document.querySelectorAll('a[href^="#"]');
    anchorLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            const href = this.getAttribute('href');
            if (href !== '#') {
                e.preventDefault();
                const target = document.querySelector(href);
                if (target) {
                    target.scrollIntoView({
                        behavior: 'smooth',
                        block: 'start'
                    });
                }
            }
        });
    });
});

// Handle job cart dropdown toggle
function toggleCartDropdown() {
    const cartDropdown = document.getElementById('cart-dropdown');
    if (cartDropdown) {
        cartDropdown.style.display = cartDropdown.style.display === 'none' ? 'block' : 'none';
    }
}

// Close cart dropdown when clicking outside
document.addEventListener('click', function(event) {
    const cartDropdown = document.getElementById('cart-dropdown');
    const jobCart = document.querySelector('.job-cart');
    
    if (cartDropdown && cartDropdown.style.display === 'block') {
        if (!jobCart.contains(event.target)) {
            cartDropdown.style.display = 'none';
        }
    }
});

// Update cart count (if cart functionality exists)
function updateCartCount(count) {
    const cartCountElement = document.getElementById('cart-count');
    if (cartCountElement) {
        cartCountElement.textContent = count;
    }
}

// Make functions globally available
window.toggleMobileMenu = toggleMobileMenu;
window.toggleCartDropdown = toggleCartDropdown;
window.updateCartCount = updateCartCount;
