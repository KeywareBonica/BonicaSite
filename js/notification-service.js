// Notification Service for Bonica Event Management System
// Handles client, service provider, and system notifications

class NotificationService {
    constructor(supabase) {
        this.supabase = supabase;
        this.notificationTypes = {
            QUOTATION_RECEIVED: 'quotation_received',
            QUOTATION_ACCEPTED: 'quotation_accepted',
            QUOTATION_REJECTED: 'quotation_rejected',
            BOOKING_CONFIRMED: 'booking_confirmed',
            BOOKING_CANCELLED: 'booking_cancelled',
            PAYMENT_RECEIVED: 'payment_received',
            PAYMENT_VERIFIED: 'payment_verified',
            PAYMENT_REJECTED: 'payment_rejected',
            EVENT_REMINDER: 'event_reminder',
            SYSTEM_UPDATE: 'system_update'
        };
    }

    // Send notification to a specific user
    async sendNotification(userId, userType, title, message, type = 'info') {
        try {
            const { data, error } = await this.supabase
                .from('notification')
                .insert([{
                    user_id: userId,
                    user_type: userType,
                    title: title,
                    message: message,
                    type: type,
                    is_read: false,
                    created_at: new Date().toISOString()
                }])
                .select();

            if (error) {
                console.error('❌ Error sending notification:', error);
                return false;
            }

            console.log('✅ Notification sent:', data[0]);
            return true;
        } catch (error) {
            console.error('❌ Notification service error:', error);
            return false;
        }
    }

    // Send notification to multiple users
    async sendBulkNotification(userIds, userType, title, message, type = 'info') {
        const notifications = userIds.map(userId => ({
            user_id: userId,
            user_type: userType,
            title: title,
            message: message,
            type: type,
            is_read: false,
            created_at: new Date().toISOString()
        }));

        try {
            const { data, error } = await this.supabase
                .from('notification')
                .insert(notifications)
                .select();

            if (error) {
                console.error('❌ Error sending bulk notifications:', error);
                return false;
            }

            console.log(`✅ ${data.length} notifications sent`);
            return true;
        } catch (error) {
            console.error('❌ Bulk notification service error:', error);
            return false;
        }
    }

    // Get notifications for a user
    async getUserNotifications(userId, userType, limit = 50) {
        try {
            const { data, error } = await this.supabase
                .from('notification')
                .select('*')
                .eq('user_id', userId)
                .eq('user_type', userType)
                .order('created_at', { ascending: false })
                .limit(limit);

            if (error) {
                console.error('❌ Error fetching notifications:', error);
                return [];
            }

            return data || [];
        } catch (error) {
            console.error('❌ Get notifications error:', error);
            return [];
        }
    }

    // Mark notification as read
    async markAsRead(notificationId) {
        try {
            const { error } = await this.supabase
                .from('notification')
                .update({ 
                    is_read: true, 
                    read_at: new Date().toISOString() 
                })
                .eq('notification_id', notificationId);

            if (error) {
                console.error('❌ Error marking notification as read:', error);
                return false;
            }

            return true;
        } catch (error) {
            console.error('❌ Mark as read error:', error);
            return false;
        }
    }

    // Mark all notifications as read for a user
    async markAllAsRead(userId, userType) {
        try {
            const { error } = await this.supabase
                .from('notification')
                .update({ 
                    is_read: true, 
                    read_at: new Date().toISOString() 
                })
                .eq('user_id', userId)
                .eq('user_type', userType)
                .eq('is_read', false);

            if (error) {
                console.error('❌ Error marking all notifications as read:', error);
                return false;
            }

            return true;
        } catch (error) {
            console.error('❌ Mark all as read error:', error);
            return false;
        }
    }

    // Get unread notification count
    async getUnreadCount(userId, userType) {
        try {
            const { count, error } = await this.supabase
                .from('notification')
                .select('*', { count: 'exact', head: true })
                .eq('user_id', userId)
                .eq('user_type', userType)
                .eq('is_read', false);

            if (error) {
                console.error('❌ Error getting unread count:', error);
                return 0;
            }

            return count || 0;
        } catch (error) {
            console.error('❌ Get unread count error:', error);
            return 0;
        }
    }

    // Specific notification methods for different events

    // Notify client when quotation is received
    async notifyClientQuotationReceived(clientId, serviceProviderName, serviceName, quotationPrice) {
        return await this.sendNotification(
            clientId,
            'client',
            'New Quotation Received',
            `You have received a quotation from ${serviceProviderName} for ${serviceName} at R${quotationPrice}. Please review and respond.`,
            'info'
        );
    }

    // Notify service provider when quotation is accepted
    async notifyProviderQuotationAccepted(providerId, clientName, serviceName, quotationPrice) {
        return await this.sendNotification(
            providerId,
            'service_provider',
            'Quotation Accepted!',
            `Great news! ${clientName} has accepted your quotation for ${serviceName} at R${quotationPrice}. Please prepare for the event.`,
            'success'
        );
    }

    // Notify service provider when quotation is rejected
    async notifyProviderQuotationRejected(providerId, clientName, serviceName) {
        return await this.sendNotification(
            providerId,
            'service_provider',
            'Quotation Not Selected',
            `${clientName} has selected a different service provider for ${serviceName}. Keep trying with other opportunities!`,
            'warning'
        );
    }

    // Notify client when booking is confirmed
    async notifyClientBookingConfirmed(clientId, eventType, eventDate, totalAmount) {
        return await this.sendNotification(
            clientId,
            'client',
            'Booking Confirmed',
            `Your ${eventType} event on ${eventDate} has been confirmed! Total amount: R${totalAmount}. Please proceed with payment.`,
            'success'
        );
    }

    // Notify when payment is received
    async notifyPaymentReceived(clientId, providerId, amount) {
        const clientNotification = await this.sendNotification(
            clientId,
            'client',
            'Payment Received',
            `Your payment of R${amount} has been received and is being processed.`,
            'success'
        );

        const providerNotification = await this.sendNotification(
            providerId,
            'service_provider',
            'Payment Received',
            `Payment of R${amount} has been received from your client and is being verified.`,
            'info'
        );

        return clientNotification && providerNotification;
    }

    // Notify when payment is verified
    async notifyPaymentVerified(clientId, providerId, amount) {
        const clientNotification = await this.sendNotification(
            clientId,
            'client',
            'Payment Verified',
            `Your payment of R${amount} has been verified and confirmed.`,
            'success'
        );

        const providerNotification = await this.sendNotification(
            providerId,
            'service_provider',
            'Payment Verified',
            `Payment of R${amount} has been verified and confirmed. You will receive your payment soon.`,
            'success'
        );

        return clientNotification && providerNotification;
    }

    // Notify when booking is cancelled
    async notifyBookingCancelled(clientId, providerId, eventType, eventDate, reason) {
        const clientNotification = await this.sendNotification(
            clientId,
            'client',
            'Booking Cancelled',
            `Your ${eventType} event on ${eventDate} has been cancelled. Reason: ${reason}`,
            'warning'
        );

        const providerNotification = await this.sendNotification(
            providerId,
            'service_provider',
            'Booking Cancelled',
            `The ${eventType} event on ${eventDate} has been cancelled. Reason: ${reason}`,
            'warning'
        );

        return clientNotification && providerNotification;
    }

    // Send event reminder
    async sendEventReminder(clientId, providerId, eventType, eventDate, eventTime) {
        const clientNotification = await this.sendNotification(
            clientId,
            'client',
            'Event Reminder',
            `Reminder: Your ${eventType} event is tomorrow at ${eventTime}. Please ensure everything is ready.`,
            'info'
        );

        const providerNotification = await this.sendNotification(
            providerId,
            'service_provider',
            'Event Reminder',
            `Reminder: You have a ${eventType} event tomorrow at ${eventTime}. Please prepare accordingly.`,
            'info'
        );

        return clientNotification && providerNotification;
    }

    // Send system-wide notifications
    async sendSystemNotification(title, message, userType = null) {
        try {
            let query = this.supabase.from('client').select('client_id');
            if (userType === 'service_provider') {
                query = this.supabase.from('service_provider').select('service_provider_id');
            }

            const { data: users, error } = await query;
            
            if (error) {
                console.error('❌ Error fetching users for system notification:', error);
                return false;
            }

            const userIds = users.map(user => 
                userType === 'service_provider' ? user.service_provider_id : user.client_id
            );

            return await this.sendBulkNotification(
                userIds,
                userType || 'client',
                title,
                message,
                'info'
            );
        } catch (error) {
            console.error('❌ System notification error:', error);
            return false;
        }
    }
}

// Make it globally available
window.NotificationService = NotificationService;
