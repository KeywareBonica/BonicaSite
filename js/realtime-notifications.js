// Real-time Notifications Component
class RealtimeNotifications {
    constructor() {
        this.notifications = [];
        this.unreadCount = 0;
        this.container = null;
        this.badge = null;
        this.isVisible = false;
        this.autoHideDelay = 5000;
        this.maxNotifications = 50;
    }

    // Initialize notifications
    initialize() {
        this.createNotificationContainer();
        this.setupEventListeners();
        this.startPolling();
    }

    // Create notification container
    createNotificationContainer() {
        // Create main container
        this.container = document.createElement('div');
        this.container.id = 'realtime-notifications';
        this.container.className = 'realtime-notifications';
        this.container.innerHTML = `
            <div class="notifications-header">
                <h6>Live Notifications</h6>
                <div class="notifications-controls">
                    <button id="mark-all-read" class="btn-sm btn-outline-secondary">Mark All Read</button>
                    <button id="clear-notifications" class="btn-sm btn-outline-danger">Clear</button>
                </div>
            </div>
            <div class="notifications-list" id="notifications-list">
                <div class="no-notifications">
                    <i class="fas fa-bell-slash"></i>
                    <p>No notifications yet</p>
                </div>
            </div>
        `;

        // Add styles
        const styles = `
            <style>
                .realtime-notifications {
                    position: fixed;
                    top: 80px;
                    right: 20px;
                    width: 350px;
                    max-height: 500px;
                    background: white;
                    border-radius: 12px;
                    box-shadow: 0 8px 32px rgba(0,0,0,0.1);
                    border: 1px solid #e5e7eb;
                    z-index: 1050;
                    display: none;
                    overflow: hidden;
                }
                
                .realtime-notifications.show {
                    display: block;
                    animation: slideIn 0.3s ease-out;
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
                
                .notifications-header {
                    padding: 1rem;
                    border-bottom: 1px solid #e5e7eb;
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    background: #f8f9fa;
                }
                
                .notifications-header h6 {
                    margin: 0;
                    font-weight: 600;
                    color: #374151;
                }
                
                .notifications-controls {
                    display: flex;
                    gap: 0.5rem;
                }
                
                .notifications-list {
                    max-height: 400px;
                    overflow-y: auto;
                }
                
                .notification-item {
                    padding: 1rem;
                    border-bottom: 1px solid #f3f4f6;
                    transition: all 0.2s ease;
                    cursor: pointer;
                    position: relative;
                }
                
                .notification-item:hover {
                    background: #f8f9fa;
                }
                
                .notification-item.unread {
                    background: #eff6ff;
                    border-left: 3px solid #3b82f6;
                }
                
                .notification-item.read {
                    opacity: 0.7;
                }
                
                .notification-header {
                    display: flex;
                    justify-content: space-between;
                    align-items: flex-start;
                    margin-bottom: 0.5rem;
                }
                
                .notification-title {
                    font-weight: 600;
                    color: #111827;
                    font-size: 0.9rem;
                }
                
                .notification-time {
                    font-size: 0.75rem;
                    color: #6b7280;
                }
                
                .notification-message {
                    font-size: 0.85rem;
                    color: #374151;
                    line-height: 1.4;
                }
                
                .notification-type {
                    display: inline-block;
                    padding: 0.2rem 0.5rem;
                    border-radius: 12px;
                    font-size: 0.7rem;
                    font-weight: 500;
                    text-transform: uppercase;
                    margin-bottom: 0.5rem;
                }
                
                .notification-type.new_quotation {
                    background: #dbeafe;
                    color: #1e40af;
                }
                
                .notification-type.quotation_accepted {
                    background: #dcfce7;
                    color: #166534;
                }
                
                .notification-type.quotation_rejected {
                    background: #fee2e2;
                    color: #991b1b;
                }
                
                .notification-type.new_booking {
                    background: #fef3c7;
                    color: #92400e;
                }
                
                .notification-type.booking_cancelled {
                    background: #fee2e2;
                    color: #991b1b;
                }
                
                .notification-type.payment_received {
                    background: #dcfce7;
                    color: #166534;
                }
                
                .notification-type.system_update {
                    background: #e0e7ff;
                    color: #3730a3;
                }
                
                .no-notifications {
                    text-align: center;
                    padding: 2rem;
                    color: #6b7280;
                }
                
                .no-notifications i {
                    font-size: 2rem;
                    margin-bottom: 0.5rem;
                    opacity: 0.5;
                }
                
                .notification-badge {
                    position: absolute;
                    top: -5px;
                    right: -5px;
                    background: #ef4444;
                    color: white;
                    border-radius: 50%;
                    width: 20px;
                    height: 20px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    font-size: 0.7rem;
                    font-weight: 600;
                }
                
                .notification-badge.hidden {
                    display: none;
                }
                
                .notification-toast {
                    position: fixed;
                    top: 20px;
                    right: 20px;
                    background: white;
                    border-radius: 8px;
                    box-shadow: 0 4px 12px rgba(0,0,0,0.15);
                    border-left: 4px solid #3b82f6;
                    padding: 1rem;
                    min-width: 300px;
                    z-index: 1060;
                    animation: slideInRight 0.3s ease-out;
                }
                
                @keyframes slideInRight {
                    from {
                        transform: translateX(100%);
                        opacity: 0;
                    }
                    to {
                        transform: translateX(0);
                        opacity: 1;
                    }
                }
                
                .notification-toast.success {
                    border-left-color: #10b981;
                }
                
                .notification-toast.warning {
                    border-left-color: #f59e0b;
                }
                
                .notification-toast.error {
                    border-left-color: #ef4444;
                }
                
                @media (max-width: 768px) {
                    .realtime-notifications {
                        width: calc(100vw - 40px);
                        right: 20px;
                        left: 20px;
                    }
                    
                    .notification-toast {
                        right: 10px;
                        left: 10px;
                        min-width: auto;
                    }
                }
            </style>
        `;
        
        document.head.insertAdjacentHTML('beforeend', styles);
        document.body.appendChild(this.container);
        
        // Find notification badge in navbar
        this.badge = document.querySelector('#notification-count, .notification-badge');
        if (!this.badge) {
            // Create badge if it doesn't exist
            this.badge = document.createElement('span');
            this.badge.className = 'notification-badge hidden';
            this.badge.id = 'notification-count';
            this.badge.textContent = '0';
            
            // Try to find notification icon in navbar
            const notificationIcon = document.querySelector('[data-bs-toggle="dropdown"]');
            if (notificationIcon) {
                notificationIcon.appendChild(this.badge);
            }
        }
    }

    // Setup event listeners
    setupEventListeners() {
        // Mark all as read
        document.getElementById('mark-all-read')?.addEventListener('click', () => {
            this.markAllAsRead();
        });

        // Clear notifications
        document.getElementById('clear-notifications')?.addEventListener('click', () => {
            this.clearNotifications();
        });

        // Close notifications when clicking outside
        document.addEventListener('click', (e) => {
            if (this.isVisible && !this.container.contains(e.target) && 
                !e.target.closest('[data-bs-toggle="dropdown"]')) {
                this.hide();
            }
        });
    }

    // Start polling for notifications
    startPolling() {
        // Poll every 30 seconds for new notifications
        setInterval(() => {
            this.fetchNotifications();
        }, 30000);
    }

    // Fetch notifications from database
    async fetchNotifications() {
        try {
            const userId = localStorage.getItem('clientId') || localStorage.getItem('serviceProviderId');
            const userType = localStorage.getItem('userType') || 'client';
            
            if (!userId) return;

            const { data, error } = await supabase
                .from('notification')
                .select('*')
                .eq('user_id', userId)
                .eq('user_type', userType)
                .order('created_at', { ascending: false })
                .limit(this.maxNotifications);

            if (error) throw error;

            this.updateNotifications(data || []);
        } catch (error) {
            console.error('Error fetching notifications:', error);
        }
    }

    // Update notifications
    updateNotifications(notifications) {
        const oldCount = this.unreadCount;
        this.notifications = notifications;
        this.unreadCount = notifications.filter(n => !n.read).length;
        
        this.renderNotifications();
        this.updateBadge();
        
        // Show toast for new notifications
        if (this.unreadCount > oldCount) {
            const newNotifications = notifications.slice(0, this.unreadCount - oldCount);
            newNotifications.forEach(notification => {
                this.showToast(notification);
            });
        }
    }

    // Render notifications
    renderNotifications() {
        const list = document.getElementById('notifications-list');
        
        if (this.notifications.length === 0) {
            list.innerHTML = `
                <div class="no-notifications">
                    <i class="fas fa-bell-slash"></i>
                    <p>No notifications yet</p>
                </div>
            `;
            return;
        }

        list.innerHTML = this.notifications.map(notification => `
            <div class="notification-item ${notification.read ? 'read' : 'unread'}" 
                 data-id="${notification.id}" 
                 onclick="realtimeNotifications.markAsRead('${notification.id}')">
                <div class="notification-type ${notification.notification_type}">
                    ${this.getTypeLabel(notification.notification_type)}
                </div>
                <div class="notification-header">
                    <div class="notification-title">${this.getTitle(notification)}</div>
                    <div class="notification-time">${this.formatTime(notification.created_at)}</div>
                </div>
                <div class="notification-message">${notification.message}</div>
            </div>
        `).join('');
    }

    // Update notification badge
    updateBadge() {
        if (this.badge) {
            if (this.unreadCount > 0) {
                this.badge.textContent = this.unreadCount > 99 ? '99+' : this.unreadCount;
                this.badge.classList.remove('hidden');
            } else {
                this.badge.classList.add('hidden');
            }
        }
    }

    // Show notification toast
    showToast(notification) {
        const toast = document.createElement('div');
        toast.className = `notification-toast ${this.getToastType(notification.notification_type)}`;
        toast.innerHTML = `
            <div style="display: flex; align-items: flex-start; gap: 0.5rem;">
                <i class="${this.getIcon(notification.notification_type)}" style="color: ${this.getColor(notification.notification_type)};"></i>
                <div style="flex: 1;">
                    <div style="font-weight: 600; margin-bottom: 0.25rem;">${this.getTitle(notification)}</div>
                    <div style="font-size: 0.85rem; color: #6b7280;">${notification.message}</div>
                </div>
                <button onclick="this.parentElement.parentElement.remove()" style="background: none; border: none; color: #9ca3af; cursor: pointer;">
                    <i class="fas fa-times"></i>
                </button>
            </div>
        `;
        
        document.body.appendChild(toast);
        
        // Auto remove after delay
        setTimeout(() => {
            if (toast.parentElement) {
                toast.remove();
            }
        }, this.autoHideDelay);
    }

    // Add new notification
    addNotification(notification) {
        this.notifications.unshift(notification);
        if (this.notifications.length > this.maxNotifications) {
            this.notifications = this.notifications.slice(0, this.maxNotifications);
        }
        
        this.renderNotifications();
        this.updateBadge();
        this.showToast(notification);
    }

    // Mark notification as read
    async markAsRead(notificationId) {
        try {
            const { error } = await supabase
                .from('notification')
                .update({ read: true })
                .eq('id', notificationId);

            if (error) throw error;

            // Update local state
            const notification = this.notifications.find(n => n.id === notificationId);
            if (notification) {
                notification.read = true;
                this.unreadCount = Math.max(0, this.unreadCount - 1);
                this.renderNotifications();
                this.updateBadge();
            }
        } catch (error) {
            console.error('Error marking notification as read:', error);
        }
    }

    // Mark all notifications as read
    async markAllAsRead() {
        try {
            const userId = localStorage.getItem('clientId') || localStorage.getItem('serviceProviderId');
            const userType = localStorage.getItem('userType') || 'client';
            
            if (!userId) return;

            const { error } = await supabase
                .from('notification')
                .update({ read: true })
                .eq('user_id', userId)
                .eq('user_type', userType)
                .eq('read', false);

            if (error) throw error;

            // Update local state
            this.notifications.forEach(n => n.read = true);
            this.unreadCount = 0;
            this.renderNotifications();
            this.updateBadge();
        } catch (error) {
            console.error('Error marking all notifications as read:', error);
        }
    }

    // Clear all notifications
    async clearNotifications() {
        try {
            const userId = localStorage.getItem('clientId') || localStorage.getItem('serviceProviderId');
            const userType = localStorage.getItem('userType') || 'client';
            
            if (!userId) return;

            const { error } = await supabase
                .from('notification')
                .delete()
                .eq('user_id', userId)
                .eq('user_type', userType);

            if (error) throw error;

            // Update local state
            this.notifications = [];
            this.unreadCount = 0;
            this.renderNotifications();
            this.updateBadge();
        } catch (error) {
            console.error('Error clearing notifications:', error);
        }
    }

    // Show notifications
    show() {
        this.container.classList.add('show');
        this.isVisible = true;
    }

    // Hide notifications
    hide() {
        this.container.classList.remove('show');
        this.isVisible = false;
    }

    // Toggle notifications
    toggle() {
        if (this.isVisible) {
            this.hide();
        } else {
            this.show();
        }
    }

    // Helper methods
    getTypeLabel(type) {
        const labels = {
            'new_quotation': 'New Quote',
            'quotation_accepted': 'Quote Accepted',
            'quotation_rejected': 'Quote Rejected',
            'new_booking': 'New Booking',
            'booking_cancelled': 'Booking Cancelled',
            'payment_received': 'Payment Received',
            'system_update': 'System Update',
            'general': 'General'
        };
        return labels[type] || 'Notification';
    }

    getTitle(notification) {
        const titles = {
            'new_quotation': 'New Quotation Received',
            'quotation_accepted': 'Quotation Accepted',
            'quotation_rejected': 'Quotation Rejected',
            'new_booking': 'New Booking Created',
            'booking_cancelled': 'Booking Cancelled',
            'payment_received': 'Payment Received',
            'system_update': 'System Update',
            'general': 'Notification'
        };
        return titles[notification.notification_type] || 'Notification';
    }

    getIcon(type) {
        const icons = {
            'new_quotation': 'fas fa-file-invoice',
            'quotation_accepted': 'fas fa-check-circle',
            'quotation_rejected': 'fas fa-times-circle',
            'new_booking': 'fas fa-calendar-plus',
            'booking_cancelled': 'fas fa-calendar-times',
            'payment_received': 'fas fa-credit-card',
            'system_update': 'fas fa-cog',
            'general': 'fas fa-bell'
        };
        return icons[type] || 'fas fa-bell';
    }

    getColor(type) {
        const colors = {
            'new_quotation': '#3b82f6',
            'quotation_accepted': '#10b981',
            'quotation_rejected': '#ef4444',
            'new_booking': '#f59e0b',
            'booking_cancelled': '#ef4444',
            'payment_received': '#10b981',
            'system_update': '#6366f1',
            'general': '#6b7280'
        };
        return colors[type] || '#6b7280';
    }

    getToastType(type) {
        const types = {
            'quotation_accepted': 'success',
            'payment_received': 'success',
            'quotation_rejected': 'error',
            'booking_cancelled': 'error',
            'new_quotation': 'info',
            'new_booking': 'warning',
            'system_update': 'info',
            'general': 'info'
        };
        return types[type] || 'info';
    }

    formatTime(dateString) {
        const date = new Date(dateString);
        const now = new Date();
        const diff = now - date;
        
        if (diff < 60000) return 'Just now';
        if (diff < 3600000) return `${Math.floor(diff / 60000)}m ago`;
        if (diff < 86400000) return `${Math.floor(diff / 3600000)}h ago`;
        return date.toLocaleDateString();
    }
}

// Create global instance
window.RealtimeNotifications = new RealtimeNotifications();
