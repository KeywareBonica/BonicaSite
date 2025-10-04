// Lock UI Component for showing lock status and waiting states
class LockUI {
    constructor() {
        this.lockIndicators = new Map();
        this.waitingModals = new Map();
        this.lockOverlays = new Map();
    }

    // Initialize lock UI
    initialize() {
        this.createLockStyles();
        this.setupGlobalEventListeners();
    }

    // Create CSS styles for lock indicators
    createLockStyles() {
        const styles = `
            <style>
                /* Lock Indicator Styles */
                .lock-indicator {
                    position: relative;
                    display: inline-block;
                }
                
                .lock-overlay {
                    position: absolute;
                    top: 0;
                    left: 0;
                    right: 0;
                    bottom: 0;
                    background: rgba(0, 0, 0, 0.7);
                    border-radius: 8px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    z-index: 1000;
                    backdrop-filter: blur(2px);
                }
                
                .lock-overlay-content {
                    background: white;
                    padding: 1rem;
                    border-radius: 8px;
                    text-align: center;
                    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
                    max-width: 300px;
                    margin: 1rem;
                }
                
                .lock-icon {
                    font-size: 2rem;
                    color: #f59e0b;
                    margin-bottom: 0.5rem;
                    animation: pulse 2s infinite;
                }
                
                @keyframes pulse {
                    0%, 100% { opacity: 1; }
                    50% { opacity: 0.5; }
                }
                
                .lock-message {
                    font-weight: 600;
                    margin-bottom: 0.5rem;
                    color: #374151;
                }
                
                .lock-details {
                    font-size: 0.85rem;
                    color: #6b7280;
                    margin-bottom: 1rem;
                }
                
                .lock-actions {
                    display: flex;
                    gap: 0.5rem;
                    justify-content: center;
                }
                
                .lock-btn {
                    padding: 0.5rem 1rem;
                    border: none;
                    border-radius: 4px;
                    font-size: 0.85rem;
                    cursor: pointer;
                    transition: all 0.2s ease;
                }
                
                .lock-btn-primary {
                    background: #3b82f6;
                    color: white;
                }
                
                .lock-btn-primary:hover {
                    background: #2563eb;
                }
                
                .lock-btn-secondary {
                    background: #6b7280;
                    color: white;
                }
                
                .lock-btn-secondary:hover {
                    background: #4b5563;
                }
                
                .lock-btn-danger {
                    background: #ef4444;
                    color: white;
                }
                
                .lock-btn-danger:hover {
                    background: #dc2626;
                }
                
                /* Waiting Modal Styles */
                .waiting-modal {
                    position: fixed;
                    top: 0;
                    left: 0;
                    right: 0;
                    bottom: 0;
                    background: rgba(0, 0, 0, 0.8);
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    z-index: 2000;
                    backdrop-filter: blur(4px);
                }
                
                .waiting-modal-content {
                    background: white;
                    padding: 2rem;
                    border-radius: 12px;
                    text-align: center;
                    max-width: 400px;
                    margin: 1rem;
                    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
                }
                
                .waiting-spinner {
                    width: 40px;
                    height: 40px;
                    border: 4px solid #e5e7eb;
                    border-top: 4px solid #3b82f6;
                    border-radius: 50%;
                    animation: spin 1s linear infinite;
                    margin: 0 auto 1rem;
                }
                
                @keyframes spin {
                    0% { transform: rotate(0deg); }
                    100% { transform: rotate(360deg); }
                }
                
                .waiting-title {
                    font-size: 1.25rem;
                    font-weight: 600;
                    margin-bottom: 0.5rem;
                    color: #111827;
                }
                
                .waiting-message {
                    color: #6b7280;
                    margin-bottom: 1.5rem;
                    line-height: 1.5;
                }
                
                .waiting-progress {
                    width: 100%;
                    height: 8px;
                    background: #e5e7eb;
                    border-radius: 4px;
                    overflow: hidden;
                    margin-bottom: 1rem;
                }
                
                .waiting-progress-bar {
                    height: 100%;
                    background: linear-gradient(90deg, #3b82f6, #1d4ed8);
                    border-radius: 4px;
                    animation: progress 3s ease-in-out infinite;
                }
                
                @keyframes progress {
                    0% { width: 0%; }
                    50% { width: 70%; }
                    100% { width: 100%; }
                }
                
                .waiting-cancel-btn {
                    background: #6b7280;
                    color: white;
                    border: none;
                    padding: 0.75rem 1.5rem;
                    border-radius: 6px;
                    cursor: pointer;
                    font-weight: 500;
                    transition: all 0.2s ease;
                }
                
                .waiting-cancel-btn:hover {
                    background: #4b5563;
                }
                
                /* Lock Status Badge */
                .lock-status-badge {
                    display: inline-flex;
                    align-items: center;
                    gap: 0.25rem;
                    padding: 0.25rem 0.5rem;
                    border-radius: 12px;
                    font-size: 0.75rem;
                    font-weight: 500;
                    text-transform: uppercase;
                    letter-spacing: 0.05em;
                }
                
                .lock-status-badge.locked {
                    background: #fef3c7;
                    color: #92400e;
                }
                
                .lock-status-badge.own-lock {
                    background: #dbeafe;
                    color: #1e40af;
                }
                
                .lock-status-badge.available {
                    background: #dcfce7;
                    color: #166534;
                }
                
                /* Disabled State */
                .locked-disabled {
                    opacity: 0.6;
                    pointer-events: none;
                    position: relative;
                }
                
                .locked-disabled::after {
                    content: '';
                    position: absolute;
                    top: 0;
                    left: 0;
                    right: 0;
                    bottom: 0;
                    background: rgba(255, 255, 255, 0.8);
                    cursor: not-allowed;
                }
                
                /* Responsive Design */
                @media (max-width: 768px) {
                    .lock-overlay-content,
                    .waiting-modal-content {
                        margin: 0.5rem;
                        padding: 1rem;
                    }
                    
                    .lock-actions,
                    .waiting-modal-content {
                        flex-direction: column;
                    }
                }
            </style>
        `;
        
        document.head.insertAdjacentHTML('beforeend', styles);
    }

    // Setup global event listeners
    setupGlobalEventListeners() {
        // Listen for lock events from LockManager
        if (window.LockManager) {
            window.LockManager.addEventListener('lock-acquired', (data) => {
                this.showLockAcquired(data.resourceId);
            });
            
            window.LockManager.addEventListener('lock-released', (data) => {
                this.hideLockIndicator(data.resourceId);
            });
            
            window.LockManager.addEventListener('lock-blocked', (data) => {
                this.showLockBlocked(data);
            });
        }
    }

    // Show lock overlay on element
    showLockOverlay(elementId, lockInfo) {
        const element = document.getElementById(elementId) || document.querySelector(`[data-resource-id="${elementId}"]`);
        if (!element) return;

        // Create lock overlay
        const overlay = document.createElement('div');
        overlay.className = 'lock-overlay';
        overlay.id = `lock-overlay-${elementId}`;
        overlay.innerHTML = `
            <div class="lock-overlay-content">
                <div class="lock-icon">
                    <i class="fas fa-lock"></i>
                </div>
                <div class="lock-message">Resource Locked</div>
                <div class="lock-details">
                    Being edited by: <strong>${lockInfo.lockedBy}</strong><br>
                    Since: ${this.formatTime(lockInfo.lockedAt)}<br>
                    Expires: ${this.formatTime(lockInfo.expiresAt)}
                </div>
                <div class="lock-actions">
                    <button class="lock-btn lock-btn-primary" onclick="lockUI.waitForLock('${elementId}')">
                        <i class="fas fa-clock"></i> Wait
                    </button>
                    <button class="lock-btn lock-btn-secondary" onclick="lockUI.hideLockOverlay('${elementId}')">
                        Close
                    </button>
                </div>
            </div>
        `;

        element.style.position = 'relative';
        element.appendChild(overlay);
        this.lockOverlays.set(elementId, overlay);
    }

    // Hide lock overlay
    hideLockOverlay(elementId) {
        const overlay = this.lockOverlays.get(elementId);
        if (overlay) {
            overlay.remove();
            this.lockOverlays.delete(elementId);
        }
    }

    // Show waiting modal
    showWaitingModal(resourceId, lockInfo, onCancel) {
        const modalId = `waiting-modal-${resourceId}`;
        
        // Remove existing modal if any
        this.hideWaitingModal(resourceId);
        
        const modal = document.createElement('div');
        modal.className = 'waiting-modal';
        modal.id = modalId;
        modal.innerHTML = `
            <div class="waiting-modal-content">
                <div class="waiting-spinner"></div>
                <div class="waiting-title">Waiting for Resource</div>
                <div class="waiting-message">
                    The resource is currently being edited by <strong>${lockInfo.lockedBy}</strong>.
                    Please wait while we try to acquire access...
                </div>
                <div class="waiting-progress">
                    <div class="waiting-progress-bar"></div>
                </div>
                <button class="waiting-cancel-btn" onclick="lockUI.cancelWaiting('${resourceId}')">
                    Cancel & Try Later
                </button>
            </div>
        `;

        document.body.appendChild(modal);
        this.waitingModals.set(resourceId, { modal, onCancel });
        
        // Auto-hide after 60 seconds
        setTimeout(() => {
            this.hideWaitingModal(resourceId);
        }, 60000);
    }

    // Hide waiting modal
    hideWaitingModal(resourceId) {
        const modalData = this.waitingModals.get(resourceId);
        if (modalData) {
            modalData.modal.remove();
            this.waitingModals.delete(resourceId);
        }
    }

    // Cancel waiting
    cancelWaiting(resourceId) {
        const modalData = this.waitingModals.get(resourceId);
        if (modalData && modalData.onCancel) {
            modalData.onCancel();
        }
        this.hideWaitingModal(resourceId);
    }

    // Wait for lock to be released
    async waitForLock(resourceId) {
        this.hideLockOverlay(resourceId);
        
        const modal = this.waitingModals.get(resourceId);
        if (modal) return; // Already waiting
        
        const waitResult = await window.LockManager.waitForLock(resourceId, 60000);
        
        if (waitResult.success) {
            this.hideWaitingModal(resourceId);
            this.showNotification('success', 'Lock Released', 'The resource is now available for editing.');
        } else {
            this.hideWaitingModal(resourceId);
            this.showNotification('warning', 'Timeout', waitResult.message);
        }
    }

    // Show lock status badge
    showLockStatusBadge(elementId, status) {
        let badge = document.getElementById(`lock-badge-${elementId}`);
        
        if (!badge) {
            badge = document.createElement('span');
            badge.id = `lock-badge-${elementId}`;
            badge.className = 'lock-status-badge';
            
            // Insert badge at the beginning of the element
            const element = document.getElementById(elementId);
            if (element) {
                element.insertBefore(badge, element.firstChild);
            }
        }
        
        badge.className = `lock-status-badge ${status.type}`;
        badge.innerHTML = `
            <i class="${this.getLockIcon(status.type)}"></i>
            ${status.text}
        `;
        
        this.lockIndicators.set(elementId, badge);
    }

    // Hide lock status badge
    hideLockStatusBadge(elementId) {
        const badge = this.lockIndicators.get(elementId);
        if (badge) {
            badge.remove();
            this.lockIndicators.delete(elementId);
        }
    }

    // Show lock acquired notification
    showLockAcquired(resourceId) {
        this.showLockStatusBadge(resourceId, {
            type: 'own-lock',
            text: 'You are editing'
        });
    }

    // Show lock blocked notification
    showLockBlocked(lockResult) {
        this.showNotification('warning', 'Resource Locked', lockResult.message);
    }

    // Show lock error notification
    showLockError(error) {
        this.showNotification('error', 'Lock Error', error.message);
    }

    // Show notification
    showNotification(type, title, message) {
        // Use existing notification system or create simple alert
        if (window.RealtimeNotifications) {
            window.RealtimeNotifications.addNotification({
                id: Date.now().toString(),
                notification_type: 'system_update',
                message: `${title}: ${message}`,
                read: false,
                created_at: new Date().toISOString()
            });
        } else {
            // Create simple toast notification
            const toast = document.createElement('div');
            toast.className = `notification-toast ${type}`;
            toast.innerHTML = `
                <div style="display: flex; align-items: center; gap: 0.5rem;">
                    <i class="${this.getNotificationIcon(type)}"></i>
                    <div>
                        <div style="font-weight: 600;">${title}</div>
                        <div style="font-size: 0.85rem;">${message}</div>
                    </div>
                </div>
            `;
            
            document.body.appendChild(toast);
            
            setTimeout(() => {
                if (toast.parentElement) {
                    toast.remove();
                }
            }, 5000);
        }
    }

    // Helper methods
    getLockIcon(type) {
        const icons = {
            'locked': 'fas fa-lock',
            'own-lock': 'fas fa-edit',
            'available': 'fas fa-check-circle'
        };
        return icons[type] || 'fas fa-question-circle';
    }

    getNotificationIcon(type) {
        const icons = {
            'success': 'fas fa-check-circle',
            'warning': 'fas fa-exclamation-triangle',
            'error': 'fas fa-times-circle',
            'info': 'fas fa-info-circle'
        };
        return icons[type] || 'fas fa-bell';
    }

    formatTime(dateString) {
        const date = new Date(dateString);
        return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    }

    // Cleanup all indicators
    cleanup() {
        this.lockIndicators.forEach(badge => badge.remove());
        this.lockOverlays.forEach(overlay => overlay.remove());
        this.waitingModals.forEach(modalData => modalData.modal.remove());
        
        this.lockIndicators.clear();
        this.lockOverlays.clear();
        this.waitingModals.clear();
    }
}

// Create global instance
window.LockUI = new LockUI();
