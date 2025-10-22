/**
 * Email Notification Service
 * Handles sending email notifications for various system events
 * including profile creation, job cart updates, quotations, etc.
 */

class EmailNotificationService {
    constructor(supabase) {
        this.supabase = supabase;
        this.isConfigured = false;
        this.checkConfiguration();
    }

    /**
     * Check if email configuration is available
     */
    async checkConfiguration() {
        try {
            // Check if we have the necessary email configuration
            // This would typically check environment variables or config
            this.isConfigured = true; // For now, assume it's configured
            console.log('📧 Email notification service initialized');
        } catch (error) {
            console.warn('Email service not fully configured:', error);
            this.isConfigured = false;
        }
    }

    /**
     * Send welcome email after profile creation
     */
    async sendProfileCreatedEmail(userData) {
        try {
            if (!this.isConfigured) {
                console.warn('Email service not configured, skipping profile creation email');
                return { success: false, error: 'Email service not configured' };
            }

            const { userType, email, name, surname } = userData;
            
            const emailSubject = `Welcome to Bonica Event Management - ${name} ${surname}`;
            const emailBody = this.generateWelcomeEmailTemplate(userData);

            // Store email notification in database for tracking
            await this.storeEmailNotification({
                recipient_email: email,
                subject: emailSubject,
                body: emailBody,
                type: 'profile_created',
                user_id: userData.id,
                user_type: userType
            });

            // Try to send actual email (this would need backend integration or Supabase Edge Functions)
            const emailResult = await this.sendEmail({
                to: email,
                subject: emailSubject,
                html: emailBody,
                type: 'profile_created'
            });

            return emailResult;

        } catch (error) {
            console.error('Error sending profile creation email:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Send job cart notification to service providers
     */
    async sendJobCartNotification(serviceProviderData, jobCartData) {
        try {
            if (!this.isConfigured) return { success: false, error: 'Email service not configured' };

            const { service_provider_email, service_provider_name, service_provider_surname } = serviceProviderData;
            const { job_cart_item, event_type, event_date, client_name } = jobCartData;

            const emailSubject = `New Job Available - ${job_cart_item}`;
            const emailBody = this.generateJobCartEmailTemplate(serviceProviderData, jobCartData);

            // Store notification
            await this.storeEmailNotification({
                recipient_email: service_provider_email,
                subject: emailSubject,
                body: emailBody,
                type: 'new_job_cart',
                user_id: serviceProviderData.service_provider_id,
                user_type: 'service_provider'
            });

            const emailResult = await this.sendEmail({
                to: service_provider_email,
                subject: emailSubject,
                html: emailBody,
                type: 'new_job_cart'
            });

            return emailResult;

        } catch (error) {
            console.error('Error sending job cart notification email:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Send quotation notification to client
     */
    async sendQuotationNotification(clientData, quotationData) {
        try {
            if (!this.isConfigured) return { success: false, error: 'Email service not configured' };

            const { client_email, client_name, client_surname } = clientData;
            const { quotation_price, service_name, quotation_details } = quotationData;

            const emailSubject = `New Quotation Received - ${service_name}`;
            const emailBody = this.generateQuotationEmailTemplate(clientData, quotationData);

            // Store notification
            await this.storeEmailNotification({
                recipient_email: client_email,
                subject: emailSubject,
                body: emailBody,
                type: 'new_quotation',
                user_id: clientData.client_id,
                user_type: 'client'
            });

            const emailResult = await this.sendEmail({
                to: client_email,
                subject: emailSubject,
                html: emailBody,
                type: 'new_quotation'
            });

            return emailResult;

        } catch (error) {
            console.error('Error sending quotation notification email:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Send booking confirmation email
     */
    async sendBookingConfirmationEmail(userData, bookingData) {
        try {
            if (!this.isConfigured) return { success: false, error: 'Email service not configured' };

            const { email, name, surname } = userData;
            const { booking_id, total_amount, event_date } = bookingData;

            const emailSubject = `Booking Confirmed - ${booking_id}`;
            const emailBody = this.generateBookingConfirmationTemplate(userData, bookingData);

            // Store notification
            await this.storeEmailNotification({
                recipient_email: email,
                subject: emailSubject,
                body: emailBody,
                type: 'booking_confirmed',
                user_id: userData.id,
                user_type: userData.user_type
            });

            const emailResult = await this.sendEmail({
                to: email,
                subject: emailSubject,
                html: emailBody,
                type: 'booking_confirmed'
            });

            return emailResult;

        } catch (error) {
            console.error('Error sending booking confirmation email:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Store email notification in database for tracking
     */
    async storeEmailNotification(notificationData) {
        try {
            const { error } = await this.supabase
                .from('email_notification_log')
                .insert({
                    ...notificationData,
                    sent_at: new Date().toISOString(),
                    status: 'pending'
                });

            if (error) {
                console.warn('Could not store email notification:', error);
                // Create table if it doesn't exist
                await this.createEmailNotificationTable();
            }
        } catch (error) {
            console.warn('Error storing email notification:', error);
        }
    }

    /**
     * Create email notification log table if it doesn't exist
     */
    async createEmailNotificationTable() {
        try {
            // This would typically be handled by a database migration
            // For now, we'll just log that the table might need to be created
            console.log('Email notification log table may need to be created via migration');
        } catch (error) {
            console.warn('Could not create email notification table:', error);
        }
    }

    /**
     * Send actual email (would integrate with email service)
     */
    async sendEmail(emailData) {
        try {
            // For now, we'll simulate email sending
            // In production, this would integrate with:
            // - Supabase Edge Functions
            // - SendGrid API
            // - NodeMailer with SMTP
            // - AWS SES
            
            console.log('📧 Email would be sent:', {
                to: emailData.to,
                subject: emailData.subject,
                type: emailData.type
            });

            // Simulate email sending delay
            await new Promise(resolve => setTimeout(resolve, 1000));

            return { 
                success: true, 
                messageId: `email_${Date.now()}`,
                timestamp: new Date().toISOString()
            };

        } catch (error) {
            console.error('Error sending email:', error);
            return { success: false, error: error.message };
        }
    }

    /**
     * Generate welcome email template
     */
    generateWelcomeEmailTemplate(userData) {
        const { name, surname, userType } = userData;
        const isClient = userType === 'client' || userType === 'customer';
        const dashboardLink = isClient ? 'Dashboard.html' : 'service-provider-dashboard.html';
        
        return `
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <title>Welcome to Bonica</title>
                <style>
                    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                    .header { background: linear-gradient(135deg, #0d6efd, #0056b3); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
                    .content { background: #f8f9fa; padding: 30px; border-radius: 0 0 10px 10px; }
                    .button { display: inline-block; background: #0d6efd; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
                    .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>Welcome to Bonica Event Management!</h1>
                    </div>
                    <div class="content">
                        <h2>Hello ${name} ${surname}!</h2>
                        
                        <p>Welcome to Bonica Event Management System! Your ${userType} account has been successfully created.</p>
                        
                        ${isClient ? 
                            '<p>As a client, you can now:</p><ul><li>Create and manage your events</li><li>Request quotations from service providers</li><li>Track your bookings and payments</li></ul>' 
                            : 
                            '<p>As a service provider, you can now:</p><ul><li>View and respond to job requests</li><li>Submit quotations to clients</li><li>Manage your bookings and schedule</li></ul>'
                        }
                        
                        <p>We\'re excited to help you with your event management needs!</p>
                        
                        <a href="${window.location.origin}/${dashboardLink}" class="button">Access Your Dashboard</a>
                        
                        <p>If you have any questions, please don't hesitate to contact our support team.</p>
                    </div>
                    <div class="footer">
                        <p>Best regards,<br>The Bonica Team</p>
                        <p><small>This is an automated message. Please do not reply to this email.</small></p>
                    </div>
                </div>
            </body>
            </html>
        `;
    }

    /**
     * Generate job cart email template
     */
    generateJobCartEmailTemplate(serviceProviderData, jobCartData) {
        const { service_provider_name, service_provider_surname } = serviceProviderData;
        const { job_cart_item, event_type, event_date, client_name } = jobCartData;

        return `
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <title>New Job Available</title>
                <style>
                    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                    .header { background: #28a745; color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
                    .content { background: #f8f9fa; padding: 30px; border-radius: 0 0 10px 10px; }
                    .button { display: inline-block; background: #28a745; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
                    .job-details { background: white; padding: 20px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #28a745; }
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>New Job Opportunity!</h1>
                    </div>
                    <div class="content">
                        <h2>Hello ${service_provider_name} ${service_provider_surname}!</h2>
                        
                        <p>A new job request has been posted that matches your service type:</p>
                        
                        <div class="job-details">
                            <h3>${job_cart_item}</h3>
                            <p><strong>Event Type:</strong> ${event_type}</p>
                            <p><strong>Event Date:</strong> ${event_date}</p>
                            <p><strong>Client:</strong> ${client_name}</p>
                        </div>
                        
                        <p>Log into your dashboard to view full details and submit a quotation.</p>
                        
                        <a href="${window.location.origin}/service-provider-dashboard.html" class="button">View Job Details</a>
                        
                        <p>Don't wait too long - other service providers might respond first!</p>
                    </div>
                </div>
            </body>
            </html>
        `;
    }

    /**
     * Generate quotation email template
     */
    generateQuotationEmailTemplate(clientData, quotationData) {
        const { client_name, client_surname } = clientData;
        const { quotation_price, service_name, quotation_details } = quotationData;

        return `
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <title>New Quotation Received</title>
                <style>
                    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                    .header { background: #17a2b8; color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
                    .content { background: #f8f9fa; padding: 30px; border-radius: 0 0 10px 10px; }
                    .button { display: inline-block; background: #17a2b8; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
                    .quotation-details { background: white; padding: 20px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #17a2b8; }
                    .price { font-size: 24px; font-weight: bold; color: #17a2b8; }
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>New Quotation Received!</h1>
                    </div>
                    <div class="content">
                        <h2>Hello ${client_name} ${client_surname}!</h2>
                        
                        <p>You have received a new quotation for your event:</p>
                        
                        <div class="quotation-details">
                            <h3>${service_name}</h3>
                            <p class="price">R ${quotation_price}</p>
                            <p><strong>Details:</strong> ${quotation_details}</p>
                        </div>
                        
                        <p>Log into your dashboard to view all quotations and make your selection.</p>
                        
                        <a href="${window.location.origin}/quotation.html" class="button">View Quotation</a>
                        
                        <p>You can compare quotes and choose the best option for your event.</p>
                    </div>
                </div>
            </body>
            </html>
        `;
    }

    /**
     * Generate booking confirmation email template
     */
    generateBookingConfirmationTemplate(userData, bookingData) {
        const { name, surname } = userData;
        const { booking_id, total_amount, event_date } = bookingData;

        return `
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <title>Booking Confirmed</title>
                <style>
                    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                    .header { background: #6f42c1; color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
                    .content { background: #f8f9fa; padding: 30px; border-radius: 0 0 10px 10px; }
                    .booking-details { background: white; padding: 20px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #6f42c1; }
                    .amount { font-size: 24px; font-weight: bold; color: #6f42c1; }
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>Booking Confirmed!</h1>
                    </div>
                    <div class="content">
                        <h2>Hello ${name} ${surname}!</h2>
                        
                        <p>Great news! Your booking has been confirmed.</p>
                        
                        <div class="booking-details">
                            <h3>Booking #${booking_id}</h3>
                            <p><strong>Event Date:</strong> ${event_date}</p>
                            <p class="amount">Total Amount: R ${total_amount}</p>
                        </div>
                        
                        <p>Your service provider has been notified and will be in touch with you soon.</p>
                        
                        <p>You can track your booking progress in your dashboard.</p>
                    </div>
                </div>
            </body>
            </html>
        `;
    }
}

// Global instance
window.EmailNotificationService = EmailNotificationService;

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    if (window.supabase) {
        window.emailNotificationService = new EmailNotificationService(window.supabase);
    }
});


