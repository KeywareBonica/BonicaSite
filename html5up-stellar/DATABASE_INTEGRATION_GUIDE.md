# Database Integration Guide

## Overview

This system has been updated to ensure that **ALL user data** (except admin) is fetched, stored, and edited through the database. The admin is the only user with hardcoded credentials to access their dashboard.

## Key Components

### 1. Admin Authentication (`js/admin-auth.js`)
- **Hardcoded admin credentials**: `admin@bonica.com` / `Admin123!`
- Only admin has hardcoded login credentials
- All other users must register through the system
- Manages admin session and access control

### 2. Database Service (`js/database-service.js`)
- Comprehensive service for all database operations
- Handles clients, service providers, events, bookings, quotations, payments, reviews, and notifications
- Provides unified interface for all CRUD operations
- Includes caching and error handling

### 3. User Data Manager (`js/user-data-manager.js`)
- Automatically replaces all hardcoded data with database data
- Skips admin data (intentionally hardcoded)
- Updates UI elements, form fields, and data containers
- Runs automatically on page load

### 4. Service Provider Service (`js/service-provider-service.js`)
- Specialized service for service provider operations
- Handles profile management, statistics, and job cart operations
- Ensures all service provider data comes from database

## User Types and Data Sources

### Admin User
- **Authentication**: Hardcoded credentials in `js/admin-auth.js`
- **Data Source**: Database (through Database Service)
- **Access**: Admin dashboard with full system access

### Client Users
- **Authentication**: Supabase Auth + Client table
- **Data Source**: Database (client table and related tables)
- **Access**: Customer dashboard with client-specific data

### Service Provider Users
- **Authentication**: Supabase Auth + Service Provider table
- **Data Source**: Database (service_provider table and related tables)
- **Access**: Service provider dashboard with provider-specific data

## Implementation Details

### Login Process
1. User enters credentials
2. System checks for admin credentials first
3. If not admin, authenticates through Supabase
4. User data is fetched from appropriate database table
5. Session is established with user type and ID

### Data Replacement Process
1. Page loads with User Data Manager
2. Manager identifies current user type
3. Skips data replacement if user is admin
4. Fetches real data from database
5. Replaces all hardcoded UI elements with database data

### Database Tables Used
- `client` - Client user information
- `service_provider` - Service provider information
- `event` - Event details
- `booking` - Booking information
- `job_cart` - Job cart items
- `quotation` - Quotation details
- `payment` - Payment records
- `review` - Review data
- `notification` - Notification system

## Files Updated

### Core System Files
- `js/admin-auth.js` - New admin authentication system
- `js/database-service.js` - Comprehensive database service
- `js/user-data-manager.js` - Automatic data replacement
- `js/service-provider-service.js` - Service provider operations

### Page Updates
- `Login.html` - Updated with admin authentication
- `dashboard.html` - Customer dashboard with database integration
- `service-provider-dashboard.html` - Service provider dashboard with database integration
- `admin-dashboard.html` - Admin dashboard with access control

### JavaScript Updates
- `js/admin-dashboard.js` - Admin dashboard with database service
- All pages now use database-driven data instead of hardcoded values

## Benefits

1. **Data Consistency**: All user data comes from single source (database)
2. **Security**: Admin access is controlled with hardcoded credentials
3. **Scalability**: Easy to add new users through registration
4. **Maintainability**: Centralized data management
5. **Real-time Updates**: Data changes reflect immediately across system

## Admin Access

### Admin Credentials
- **Email**: `admin@bonica.com`
- **Password**: `Admin123!`

### Admin Features
- Full system access
- View all clients, service providers, bookings, quotations
- System statistics and reports
- User management capabilities

## Testing

### Admin Login
1. Go to Login page
2. Enter admin credentials: `admin@bonica.com` / `Admin123!`
3. Should redirect to admin dashboard
4. All data should be fetched from database

### Regular User Login
1. Register as client or service provider
2. Login with registered credentials
3. Should redirect to appropriate dashboard
4. All data should be fetched from database (no hardcoded values)

### Data Verification
1. Check that user names, emails, contact info come from database
2. Verify bookings, quotations, events are database-driven
3. Confirm admin is only user with hardcoded access

## Security Notes

- Admin credentials are the only hardcoded authentication
- All other users must register through the system
- User data is validated and sanitized through database service
- Session management prevents unauthorized access
- Admin sessions expire after 24 hours

## Troubleshooting

### Common Issues
1. **Admin can't login**: Check admin credentials in `js/admin-auth.js`
2. **User data not loading**: Verify database service is initialized
3. **Hardcoded data still showing**: Check User Data Manager is loaded
4. **Database errors**: Verify Supabase connection and table structure

### Debug Steps
1. Check browser console for errors
2. Verify all required JavaScript files are loaded
3. Confirm database service initialization
4. Check user authentication status
5. Verify database table structure matches service expectations
