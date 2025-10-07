# Testing the 3 Quotation Upload System

## 🎯 **Testing Strategy Overview**

The system should work as follows:
1. **Client Side**: Creates job cart with event details
2. **Service Provider Side**: Accepts job cart → Uploads quotation
3. **Multiple Service Providers**: Each uploads their own quotation for the same job cart
4. **Client Side**: Sees 3+ quotations to choose from

## 🧪 **Test Scenarios**

### **Scenario 1: Single Service Provider Testing**
1. **Setup**: Register 3 different service providers for the same service type (e.g., "Makeup Artist")
2. **Client Flow**: 
   - Go to `bookings.html`
   - Fill out event details (Step 2)
   - Select "Makeup Artist" service (Step 3)
   - Wait for quotations (Step 4)
3. **Service Provider Flow**:
   - Login as Service Provider 1 → Accept job cart → Upload quotation
   - Login as Service Provider 2 → Accept job cart → Upload quotation  
   - Login as Service Provider 3 → Accept job cart → Upload quotation
4. **Expected Result**: Client sees 3 different quotations to choose from

### **Scenario 2: Real-time Testing**
1. **Setup**: Open two browser tabs/windows
   - Tab 1: Client booking process (`bookings.html`)
   - Tab 2: Service provider dashboard (`service-provider-dashboard.html`)
2. **Test Flow**:
   - Tab 1: Create job cart
   - Tab 2: Should immediately see new job cart (no refresh needed)
   - Tab 2: Accept and upload quotation
   - Tab 1: Should see quotation appear in real-time

### **Scenario 3: Multiple Service Types**
1. **Setup**: Create job cart with multiple services (e.g., Makeup + Photography)
2. **Expected**: Each service should get separate job carts
3. **Test**: Different service providers upload quotations for their specific service

## 🔧 **Testing Tools**

### **1. Database Verification**
```sql
-- Check job carts
SELECT job_cart_id, service_id, client_id, event_id, job_cart_status 
FROM job_cart 
ORDER BY created_at DESC;

-- Check quotations linked to job carts
SELECT q.quotation_id, q.job_cart_id, q.quotation_price, q.quotation_status,
       jc.service_id, s.service_name
FROM quotation q
JOIN job_cart jc ON q.job_cart_id = jc.job_cart_id
JOIN service s ON jc.service_id = s.service_id
ORDER BY q.created_at DESC;
```

### **2. Console Monitoring**
- Monitor console for real-time subscription messages
- Check for 400 errors during data fetching
- Verify job cart creation and quotation upload logs

### **3. Manual Testing Steps**
1. **Create Test Data**:
   - Register 3 service providers for same service type
   - Create a test client account
   - Create a test event

2. **Test Upload Flow**:
   - Accept job cart → Upload quotation → Verify database
   - Repeat for 3 different service providers
   - Check client side shows 3 quotations

## 🚀 **Quick Test Setup**

### **Step 1: Create Test Service Providers**
```sql
-- Insert 3 test service providers for Makeup Artist
INSERT INTO service_provider (
    service_provider_name, service_provider_surname, service_provider_email,
    service_provider_contactno, service_provider_service_type, service_provider_verification
) VALUES 
('Alice', 'Johnson', 'alice@test.com', '1234567890', 'Makeup Artist', true),
('Bob', 'Smith', 'bob@test.com', '1234567891', 'Makeup Artist', true),
('Carol', 'Davis', 'carol@test.com', '1234567892', 'Makeup Artist', true);
```

### **Step 2: Test Upload Function**
1. Login as Alice → Accept job cart → Upload quotation (Price: 2500, Details: "Premium makeup package")
2. Login as Bob → Accept job cart → Upload quotation (Price: 1800, Details: "Standard makeup package")  
3. Login as Carol → Accept job cart → Upload quotation (Price: 3200, Details: "Luxury makeup package")

### **Step 3: Verify Client Side**
1. Go back to client booking process
2. Check Step 5 (Quotation Selection) shows 3 different quotations
3. Verify each quotation shows correct price, details, and service provider info

## 🐛 **Common Issues to Watch For**

1. **Job Cart Not Appearing**: Check real-time subscriptions and event_id linking
2. **400 Bad Request**: Verify event data fetching with proper error handling
3. **Quotation Not Showing**: Check quotation table inserts and foreign key relationships
4. **Real-time Not Working**: Verify Supabase real-time channels and callbacks

## ✅ **Success Criteria**

- [ ] Job carts appear on service provider dashboard without page refresh
- [ ] Service providers can accept job carts and upload quotations
- [ ] Multiple quotations appear for the same job cart
- [ ] Client can see and select from multiple quotations
- [ ] No 400 Bad Request errors in console
- [ ] All event details (location, time, date) display correctly
- [ ] Real-time updates work across multiple browser tabs

