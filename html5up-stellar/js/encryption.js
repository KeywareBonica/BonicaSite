/**
 * Simple Encryption Utility for Bonica Event Management System
 * Note: This is a basic encryption implementation. For production use,
 * consider using more robust encryption libraries like crypto-js
 */

class SimpleEncryption {
    constructor() {
        this.secretKey = 'bonica-secret-key-2025'; // In production, use environment variables
    }

    /**
     * Hash function for passwords using SHA-256
     * @param {string} password - The password to hash
     * @returns {string} - The hashed password
     */
    async hashPassword(password) {
        // Use Web Crypto API for secure hashing
        const encoder = new TextEncoder();
        const data = encoder.encode(password + this.secretKey);
        const hashBuffer = await crypto.subtle.digest('SHA-256', data);
        const hashArray = Array.from(new Uint8Array(hashBuffer));
        const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
        return hashHex;
    }

    /**
     * Simple hash function for passwords (legacy support)
     * @param {string} password - The password to hash
     * @returns {string} - The hashed password
     */
    hashPasswordSync(password) {
        // Simple hash implementation (for demo purposes)
        // In production, use bcrypt or similar
        let hash = 0;
        if (password.length === 0) return hash.toString();
        
        for (let i = 0; i < password.length; i++) {
            const char = password.charCodeAt(i);
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash; // Convert to 32-bit integer
        }
        
        // Add salt
        const salt = this.secretKey;
        const saltedPassword = password + salt;
        
        // Create a more complex hash
        let complexHash = 0;
        for (let i = 0; i < saltedPassword.length; i++) {
            complexHash = ((complexHash << 5) - complexHash + saltedPassword.charCodeAt(i)) & 0xffffffff;
        }
        
        return Math.abs(complexHash).toString(16) + Math.abs(hash).toString(16);
    }

    /**
     * Simple encryption for sensitive data
     * @param {string} text - The text to encrypt
     * @returns {string} - The encrypted text
     */
    encrypt(text) {
        if (!text) return '';
        
        const key = this.secretKey;
        let result = '';
        
        for (let i = 0; i < text.length; i++) {
            const textChar = text.charCodeAt(i);
            const keyChar = key.charCodeAt(i % key.length);
            result += String.fromCharCode(textChar ^ keyChar);
        }
        
        return btoa(result); // Base64 encode
    }

    /**
     * Simple decryption for sensitive data
     * @param {string} encryptedText - The encrypted text
     * @returns {string} - The decrypted text
     */
    decrypt(encryptedText) {
        if (!encryptedText) return '';
        
        try {
            const text = atob(encryptedText); // Base64 decode
            const key = this.secretKey;
            let result = '';
            
            for (let i = 0; i < text.length; i++) {
                const textChar = text.charCodeAt(i);
                const keyChar = key.charCodeAt(i % key.length);
                result += String.fromCharCode(textChar ^ keyChar);
            }
            
            return result;
        } catch (error) {
            console.error('Decryption error:', error);
            return '';
        }
    }

    /**
     * Hash sensitive data for storage
     * @param {string} data - The data to hash
     * @returns {string} - The hashed data
     */
    hashData(data) {
        if (!data) return '';
        
        const combined = data + this.secretKey;
        let hash = 0;
        
        for (let i = 0; i < combined.length; i++) {
            const char = combined.charCodeAt(i);
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash;
        }
        
        return Math.abs(hash).toString(16);
    }

    /**
     * Utility function to migrate plain text passwords to hashed format
     * This can be used to update the database with hashed passwords
     * @param {string} plainPassword - The plain text password
     * @returns {Promise<string>} - The hashed password
     */
    async migratePassword(plainPassword) {
        return await this.hashPassword(plainPassword);
    }
}

// Create global instance
window.encryption = new SimpleEncryption();

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = SimpleEncryption;
}
