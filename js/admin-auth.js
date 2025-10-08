/**
 * Admin Authentication System
 * Handles hardcoded admin credentials for dashboard access
 * Only admin has hardcoded login - all other users must register
 */

class AdminAuth {
    constructor() {
        // Hardcoded admin credentials (only admin has this)
        this.adminCredentials = {
            email: 'adminbonica@gmail.com',
            password: 'Admin123!',
            name: 'System Administrator',
            role: 'admin'
        };
        
        this.isAdminLoggedIn = false;
        this.adminSession = null;
    }

    /**
     * Authenticate admin with hardcoded credentials
     * @param {string} email - Admin email
     * @param {string} password - Admin password
     * @returns {Object} Authentication result
     */
    authenticateAdmin(email, password) {
        try {
            // Check if credentials match hardcoded admin credentials
            if (email === this.adminCredentials.email && password === this.adminCredentials.password) {
                // Create admin session
                this.adminSession = {
                    adminId: 'admin-001',
                    email: this.adminCredentials.email,
                    name: this.adminCredentials.name,
                    role: this.adminCredentials.role,
                    loginTime: new Date().toISOString(),
                    sessionId: this.generateSessionId()
                };

                // Store in localStorage
                localStorage.setItem('adminSession', JSON.stringify(this.adminSession));
                localStorage.setItem('userType', 'admin');
                
                this.isAdminLoggedIn = true;
                
                console.log('✅ Admin authenticated successfully');
                
                return {
                    success: true,
                    message: 'Admin login successful',
                    admin: this.adminSession
                };
            } else {
                return {
                    success: false,
                    message: 'Invalid admin credentials'
                };
            }
        } catch (error) {
            console.error('Error authenticating admin:', error);
            return {
                success: false,
                message: 'Authentication error'
            };
        }
    }

    /**
     * Check if admin is currently logged in
     * @returns {boolean} True if admin is logged in
     */
    isAdminAuthenticated() {
        try {
            const storedSession = localStorage.getItem('adminSession');
            if (storedSession) {
                this.adminSession = JSON.parse(storedSession);
                this.isAdminLoggedIn = true;
                return true;
            }
            return false;
        } catch (error) {
            console.error('Error checking admin authentication:', error);
            return false;
        }
    }

    /**
     * Get current admin session
     * @returns {Object|null} Admin session or null
     */
    getCurrentAdmin() {
        if (this.isAdminAuthenticated()) {
            return this.adminSession;
        }
        return null;
    }

    /**
     * Logout admin
     */
    logoutAdmin() {
        try {
            this.adminSession = null;
            this.isAdminLoggedIn = false;
            localStorage.removeItem('adminSession');
            localStorage.removeItem('userType');
            
            console.log('✅ Admin logged out successfully');
        } catch (error) {
            console.error('Error logging out admin:', error);
        }
    }

    /**
     * Generate session ID
     * @returns {string} Session ID
     */
    generateSessionId() {
        return 'admin_' + Math.random().toString(36).substr(2, 9) + '_' + Date.now();
    }

    /**
     * Validate admin session
     * @returns {boolean} True if session is valid
     */
    validateSession() {
        if (!this.adminSession) return false;
        
        // Check if session is not too old (24 hours)
        const loginTime = new Date(this.adminSession.loginTime);
        const now = new Date();
        const hoursDiff = (now - loginTime) / (1000 * 60 * 60);
        
        if (hoursDiff > 24) {
            this.logoutAdmin();
            return false;
        }
        
        return true;
    }

    /**
     * Redirect to admin dashboard if authenticated
     */
    redirectToAdminDashboard() {
        if (this.isAdminAuthenticated() && this.validateSession()) {
            window.location.href = 'admin-dashboard.html';
        }
    }

    /**
     * Check admin access and redirect if not authorized
     */
    checkAdminAccess() {
        const userType = localStorage.getItem('userType');
        
        if (userType !== 'admin') {
            alert('Access denied. Admin privileges required.');
            window.location.href = 'Login.html';
            return false;
        }
        
        if (!this.isAdminAuthenticated() || !this.validateSession()) {
            alert('Admin session expired. Please login again.');
            window.location.href = 'Login.html';
            return false;
        }
        
        return true;
    }
}

// Create global admin auth instance
window.AdminAuth = new AdminAuth();
