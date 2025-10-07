/**
 * Comprehensive Security System
 * Handles OTP, 2FA, account lockout, CAPTCHA, and security logging
 */

window.SecuritySystem = {
    // Configuration
    config: {
        otpExpiryMinutes: 10,
        maxLoginAttempts: 3,
        lockoutDurationMinutes: 15,
        maxOtpAttempts: 3,
        supabaseUrl: "https://spudtrptbyvwyhvistdf.supabase.co",
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNwdWR0cnB0Ynl2d3lodmlzdGRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU2OTk4NjgsImV4cCI6MjA3MTI3NTg2OH0.GBo-RtgbRZCmhSAZi0c5oXynMiJNeyrs0nLsk3CaV8A"
    },

    // Initialize Supabase client
    init() {
        if (typeof supabase === 'undefined') {
            console.error('Supabase not loaded. Please include Supabase script first.');
            return false;
        }
        return true;
    },

    /**
     * Generate a 6-digit OTP code
     */
    generateOTP() {
        return Math.floor(100000 + Math.random() * 900000).toString();
    },

    /**
     * Generate CAPTCHA question and answer
     */
    generateCAPTCHA() {
        const operations = [
            { type: 'addition', symbol: '+' },
            { type: 'subtraction', symbol: '-' },
            { type: 'multiplication', symbol: '×' }
        ];
        
        const operation = operations[Math.floor(Math.random() * operations.length)];
        let num1, num2, answer, question;
        
        switch (operation.type) {
            case 'addition':
                num1 = Math.floor(Math.random() * 20) + 1;
                num2 = Math.floor(Math.random() * 20) + 1;
                answer = num1 + num2;
                question = `${num1} + ${num2} = ?`;
                break;
            case 'subtraction':
                num1 = Math.floor(Math.random() * 20) + 10;
                num2 = Math.floor(Math.random() * num1);
                answer = num1 - num2;
                question = `${num1} - ${num2} = ?`;
                break;
            case 'multiplication':
                num1 = Math.floor(Math.random() * 12) + 1;
                num2 = Math.floor(Math.random() * 12) + 1;
                answer = num1 * num2;
                question = `${num1} × ${num2} = ?`;
                break;
        }
        
        return { question, answer };
    },

    /**
     * Verify CAPTCHA answer
     */
    verifyCAPTCHA(userAnswer, correctAnswer) {
        return parseInt(userAnswer) === correctAnswer;
    },

    /**
     * Send OTP via email (simulated)
     */
    async sendOTPEmail(email, otp, type = 'verification') {
        try {
            if (!this.init()) return { success: false, error: 'Supabase not initialized' };

            // Store OTP in database
            const { data, error } = await supabase
                .from('otp_codes')
                .insert({
                    email: email,
                    otp_code: otp,
                    otp_type: type,
                    expires_at: new Date(Date.now() + this.config.otpExpiryMinutes * 60 * 1000).toISOString()
                });

            if (error) {
                console.error('Error storing OTP:', error);
                return { success: false, error: error.message };
            }

            // Simulate email sending (in production, integrate with email service)
            console.log(`OTP ${otp} sent to ${email} for ${type}`);
            
            // Show success message to user
            this.showMessage(`Verification code sent to ${email}`, 'success');
            
            return { success: true };
        } catch (error) {
            console.error('Error sending OTP:', error);
            return { success: false, error: error.message };
        }
    },

    /**
     * Verify OTP code
     */
    async verifyOTP(email, otp, type = 'verification') {
        try {
            if (!this.init()) return false;

            const { data, error } = await supabase
                .from('otp_codes')
                .select('*')
                .eq('email', email)
                .eq('otp_code', otp)
                .eq('otp_type', type)
                .is('used_at', null)
                .gte('expires_at', new Date().toISOString())
                .order('created_at', { ascending: false })
                .limit(1)
                .single();

            if (error || !data) {
                return false;
            }

            // Mark OTP as used
            await supabase
                .from('otp_codes')
                .update({ used_at: new Date().toISOString() })
                .eq('id', data.id);

            return true;
        } catch (error) {
            console.error('Error verifying OTP:', error);
            return false;
        }
    },

    /**
     * Check account lockout status
     */
    async checkAccountLock(email) {
        try {
            if (!this.init()) return { locked: false };

            const { data, error } = await supabase
                .from('login_attempts')
                .select('*')
                .eq('email', email)
                .eq('success', false)
                .gte('attempt_time', new Date(Date.now() - this.config.lockoutDurationMinutes * 60 * 1000).toISOString())
                .order('attempt_time', { ascending: false });

            if (error) {
                console.error('Error checking account lock:', error);
                return { locked: false };
            }

            const failedAttempts = data.length;
            
            if (failedAttempts >= this.config.maxLoginAttempts) {
                const oldestAttempt = data[data.length - 1];
                const lockoutExpiry = new Date(oldestAttempt.attempt_time.getTime() + this.config.lockoutDurationMinutes * 60 * 1000);
                const now = new Date();
                
                if (now < lockoutExpiry) {
                    const remainingMinutes = Math.ceil((lockoutExpiry - now) / (1000 * 60));
                    return {
                        locked: true,
                        message: `Account locked due to multiple failed login attempts. Try again in ${remainingMinutes} minutes.`,
                        remainingTime: remainingMinutes
                    };
                }
            }

            return { locked: false };
        } catch (error) {
            console.error('Error checking account lock:', error);
            return { locked: false };
        }
    },

    /**
     * Track login attempt
     */
    async trackLoginAttempt(email, success) {
        try {
            if (!this.init()) return;

            await supabase
                .from('login_attempts')
                .insert({
                    email: email,
                    ip_address: await this.getClientIP(),
                    user_agent: navigator.userAgent,
                    success: success,
                    attempt_time: new Date().toISOString()
                });

            // If successful login, log notification
            if (success) {
                await this.logLoginNotification(email);
            }
        } catch (error) {
            console.error('Error tracking login attempt:', error);
        }
    },

    /**
     * Log login notification
     */
    async logLoginNotification(email) {
        try {
            if (!this.init()) return;

            const location = await this.getLocationFromIP();
            
            await supabase
                .from('login_notifications')
                .insert({
                    email: email,
                    ip_address: await this.getClientIP(),
                    user_agent: navigator.userAgent,
                    location: location,
                    device_info: this.getDeviceInfo(),
                    login_time: new Date().toISOString()
                });
        } catch (error) {
            console.error('Error logging login notification:', error);
        }
    },

    /**
     * Log security events
     */
    async logSecurityEvent(userId, userType, action, details = {}) {
        try {
            if (!this.init()) return;

            await supabase
                .from('security_logs')
                .insert({
                    user_id: userId,
                    user_type: userType,
                    action: action,
                    ip_address: await this.getClientIP(),
                    user_agent: navigator.userAgent,
                    details: details,
                    created_at: new Date().toISOString()
                });
        } catch (error) {
            console.error('Error logging security event:', error);
        }
    },

    /**
     * Setup 2FA for user
     */
    async setup2FA(userId, userType) {
        try {
            if (!this.init()) return { success: false };

            // Generate TOTP secret (simplified - in production use proper TOTP library)
            const secret = this.generateSecretKey();
            const backupCodes = this.generateBackupCodes();

            const { data, error } = await supabase
                .from('two_factor_auth')
                .insert({
                    user_id: userId,
                    user_type: userType,
                    secret_key: secret,
                    backup_codes: backupCodes,
                    is_enabled: false
                });

            if (error) {
                console.error('Error setting up 2FA:', error);
                return { success: false, error: error.message };
            }

            return {
                success: true,
                secret: secret,
                backupCodes: backupCodes,
                qrCodeUrl: this.generateQRCodeUrl(secret, userId)
            };
        } catch (error) {
            console.error('Error setting up 2FA:', error);
            return { success: false, error: error.message };
        }
    },

    /**
     * Verify 2FA code
     */
    async verify2FA(userId, code) {
        try {
            if (!this.init()) return false;

            const { data, error } = await supabase
                .from('two_factor_auth')
                .select('*')
                .eq('user_id', userId)
                .eq('is_enabled', true)
                .single();

            if (error || !data) {
                return false;
            }

            // Verify TOTP code (simplified - in production use proper TOTP library)
            const isValid = this.verifyTOTPCode(data.secret_key, code);
            
            if (isValid) {
                // Update last used time
                await supabase
                    .from('two_factor_auth')
                    .update({ last_used: new Date().toISOString() })
                    .eq('id', data.id);
            }

            return isValid;
        } catch (error) {
            console.error('Error verifying 2FA:', error);
            return false;
        }
    },

    /**
     * Enable 2FA for user
     */
    async enable2FA(userId, verificationCode) {
        try {
            if (!this.init()) return { success: false };

            const { data, error } = await supabase
                .from('two_factor_auth')
                .update({ is_enabled: true })
                .eq('user_id', userId)
                .eq('is_enabled', false)
                .select()
                .single();

            if (error) {
                console.error('Error enabling 2FA:', error);
                return { success: false, error: error.message };
            }

            return { success: true };
        } catch (error) {
            console.error('Error enabling 2FA:', error);
            return { success: false, error: error.message };
        }
    },

    /**
     * Utility functions
     */
    generateSecretKey() {
        const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
        let result = '';
        for (let i = 0; i < 32; i++) {
            result += chars.charAt(Math.floor(Math.random() * chars.length));
        }
        return result;
    },

    generateBackupCodes() {
        const codes = [];
        for (let i = 0; i < 10; i++) {
            codes.push(Math.random().toString(36).substr(2, 8).toUpperCase());
        }
        return codes;
    },

    generateQRCodeUrl(secret, userId) {
        const issuer = 'EventHub';
        const accountName = userId;
        return `https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=otpauth://totp/${issuer}:${accountName}?secret=${secret}&issuer=${issuer}`;
    },

    verifyTOTPCode(secret, code) {
        // Simplified TOTP verification - in production use proper TOTP library
        const timestamp = Math.floor(Date.now() / 1000 / 30);
        const expectedCode = this.generateTOTPCode(secret, timestamp);
        return code === expectedCode;
    },

    generateTOTPCode(secret, timestamp) {
        // Simplified TOTP generation - in production use proper TOTP library
        const hash = this.hmacSHA1(secret, timestamp.toString());
        const offset = hash[hash.length - 1] & 0xf;
        const code = ((hash[offset] & 0x7f) << 24) |
                    ((hash[offset + 1] & 0xff) << 16) |
                    ((hash[offset + 2] & 0xff) << 8) |
                    (hash[offset + 3] & 0xff);
        return (code % 1000000).toString().padStart(6, '0');
    },

    hmacSHA1(key, message) {
        // Simplified HMAC-SHA1 - in production use proper crypto library
        return new Uint8Array(20); // Placeholder
    },

    async getClientIP() {
        try {
            const response = await fetch('https://api.ipify.org?format=json');
            const data = await response.json();
            return data.ip;
        } catch (error) {
            return 'unknown';
        }
    },

    async getLocationFromIP() {
        try {
            const ip = await this.getClientIP();
            if (ip === 'unknown') return 'unknown';
            
            const response = await fetch(`https://ipapi.co/${ip}/json/`);
            const data = await response.json();
            return `${data.city}, ${data.region}, ${data.country}`;
        } catch (error) {
            return 'unknown';
        }
    },

    getDeviceInfo() {
        const userAgent = navigator.userAgent;
        const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(userAgent);
        const browser = this.getBrowserName(userAgent);
        const os = this.getOSName(userAgent);
        
        return {
            browser: browser,
            os: os,
            isMobile: isMobile,
            screen: `${screen.width}x${screen.height}`
        };
    },

    getBrowserName(userAgent) {
        if (userAgent.includes('Chrome')) return 'Chrome';
        if (userAgent.includes('Firefox')) return 'Firefox';
        if (userAgent.includes('Safari')) return 'Safari';
        if (userAgent.includes('Edge')) return 'Edge';
        return 'Unknown';
    },

    getOSName(userAgent) {
        if (userAgent.includes('Windows')) return 'Windows';
        if (userAgent.includes('Mac')) return 'macOS';
        if (userAgent.includes('Linux')) return 'Linux';
        if (userAgent.includes('Android')) return 'Android';
        if (userAgent.includes('iOS')) return 'iOS';
        return 'Unknown';
    },

    /**
     * Show message to user
     */
    showMessage(message, type = 'info') {
        // Create toast notification
        const toast = document.createElement('div');
        toast.className = `toast-notification toast-${type}`;
        toast.innerHTML = `
            <div class="toast-content">
                <i class="fas fa-${this.getIconForType(type)}"></i>
                <span>${message}</span>
            </div>
            <button class="toast-close" onclick="this.parentElement.remove()">
                <i class="fas fa-times"></i>
            </button>
        `;
        
        // Add to page
        document.body.appendChild(toast);
        
        // Auto remove after 5 seconds
        setTimeout(() => {
            if (toast.parentElement) {
                toast.remove();
            }
        }, 5000);
    },

    getIconForType(type) {
        const icons = {
            success: 'check-circle',
            error: 'exclamation-circle',
            warning: 'exclamation-triangle',
            info: 'info-circle'
        };
        return icons[type] || 'info-circle';
    },

    /**
     * Clean up expired data
     */
    async cleanupExpiredData() {
        try {
            if (!this.init()) return;

            // Clean up expired OTP codes
            await supabase
                .from('otp_codes')
                .delete()
                .lt('expires_at', new Date().toISOString());

            // Clean up old login attempts (older than 24 hours)
            const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
            await supabase
                .from('login_attempts')
                .delete()
                .lt('attempt_time', oneDayAgo);

            // Clean up old security logs (older than 90 days)
            const ninetyDaysAgo = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString();
            await supabase
                .from('security_logs')
                .delete()
                .lt('created_at', ninetyDaysAgo);

            console.log('Security data cleanup completed');
        } catch (error) {
            console.error('Error cleaning up security data:', error);
        }
    }
};

// Initialize cleanup on page load
document.addEventListener('DOMContentLoaded', function() {
    // Run cleanup every hour
    setInterval(() => {
        window.SecuritySystem.cleanupExpiredData();
    }, 60 * 60 * 1000);
});

// Add CSS for toast notifications
const style = document.createElement('style');
style.textContent = `
    .toast-notification {
        position: fixed;
        top: 20px;
        right: 20px;
        background: white;
        border-radius: 8px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        padding: 16px;
        display: flex;
        align-items: center;
        gap: 12px;
        z-index: 10000;
        min-width: 300px;
        animation: slideIn 0.3s ease-out;
    }
    
    .toast-success { border-left: 4px solid #10b981; }
    .toast-error { border-left: 4px solid #ef4444; }
    .toast-warning { border-left: 4px solid #f59e0b; }
    .toast-info { border-left: 4px solid #3b82f6; }
    
    .toast-content {
        display: flex;
        align-items: center;
        gap: 8px;
        flex: 1;
    }
    
    .toast-content i {
        font-size: 16px;
    }
    
    .toast-success .toast-content i { color: #10b981; }
    .toast-error .toast-content i { color: #ef4444; }
    .toast-warning .toast-content i { color: #f59e0b; }
    .toast-info .toast-content i { color: #3b82f6; }
    
    .toast-close {
        background: none;
        border: none;
        cursor: pointer;
        padding: 4px;
        border-radius: 4px;
        color: #6b7280;
    }
    
    .toast-close:hover {
        background: #f3f4f6;
    }
    
    @keyframes slideIn {
        from {
            transform: translateX(100%);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }
`;
document.head.appendChild(style);