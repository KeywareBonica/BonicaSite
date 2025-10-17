# ✅ CORRECT Quotation Flow - How It Really Works

## 🔄 Complete Booking to Payment Flow

### Step 1: Customer Books Services
1. **Customer** logs in and creates an event (e.g., Wedding on Feb 15, 2025)
2. **Customer** selects services they need (e.g., Photography, Catering, Decoration)
3. **JOB CART** is created for each service
   - Each job cart has:
     - `service_id` (which service)
     - `event_id` (which event)
     - `client_id` (who requested it)
     - `job_cart_min_price` and `job_cart_max_price` (budget range)
     - `job_cart_status = 'pending'`

---

### Step 2: Service Providers See Job Carts
1. **Service providers** log into their dashboard
2. They see **available job carts** that match their service type
3. Example: A photographer sees all job carts for "Photography" service

---

### Step 3: Timer Starts (1 Minute)
1. Customer clicks "Next" after selecting services
2. **1-minute timer** appears on customer's screen
3. Message: "Quotations are being uploaded, please wait..."
4. This gives providers time to upload their quotations in **real-time**

---

### Step 4: Service Providers Upload Quotations
**While timer is running:**

1. **Service provider** selects a job cart
2. **Service provider** fills in quotation form:
   - Price (must be within client's budget range)
   - Details (description of what they'll provide)
   - Optional: Upload PDF quotation
3. **Service provider** submits quotation
4. **Quotation is saved** to database:
   - `quotation_status = 'pending'`  ← IMPORTANT!
   - `service_provider_id` (who submitted it)
   - `job_cart_id` (which request it's for)
   - `quotation_price`, `quotation_details`, etc.

**Multiple providers can upload for the same job cart!**
- Photographer 1 uploads → quotation 1 (pending)
- Photographer 2 uploads → quotation 2 (pending)
- Photographer 3 uploads → quotation 3 (pending)

**Limit: Maximum 3 quotations per job cart**

---

### Step 5: Client Views PENDING Quotations
**After timer or when quotations are available:**

1. Customer is taken to **quotation.html** page
2. **JavaScript query** fetches:
   ```javascript
   SELECT * FROM quotation 
   WHERE service_id IN (selected_services)
   AND quotation_status = 'pending'  ← Shows PENDING quotations
   LIMIT 3 per service
   ```

3. **Customer sees** all pending quotations grouped by service:

   ```
   📸 Photography Service
   ├─ Quotation 1: Mike's Photos - R3,500 [Select]
   ├─ Quotation 2: Perfect Shots - R4,000 [Select]
   └─ Quotation 3: Wedding Pics - R3,200 [Select]
   
   🍽️ Catering Service
   ├─ Quotation 1: Sarah's Catering - R2,500 [Select]
   └─ Quotation 2: Delicious Events - R2,800 [Select]
   ```

---

### Step 6: Client Accepts ONE Quotation Per Service
1. **Customer reviews** all quotations
2. **Customer selects** their preferred quotation for each service
3. **Customer clicks** "Select This Quote" button
4. **System updates database:**
   ```sql
   -- Selected quotation
   UPDATE quotation 
   SET quotation_status = 'confirmed' 
   WHERE quotation_id = [selected_one];
   
   -- Other quotations for same job cart
   UPDATE quotation 
   SET quotation_status = 'rejected' 
   WHERE job_cart_id = [same_cart] 
   AND quotation_id != [selected_one];
   ```

---

### Step 7: Customer Proceeds to Payment
1. **Customer** clicks "Continue to Payment"
2. System calculates total:
   - Subtotal = Sum of all confirmed quotation prices
   - Service Fee = 15% of subtotal
   - Grand Total = Subtotal + Service Fee
3. **Customer** goes to **payment.html**
4. **Customer** uploads proof of payment (image/PDF)

---

### Step 8: Admin Verifies Payment (NOT Quotations!)
1. **Admin** logs into admin dashboard
2. **Admin** sees pending payments
3. **Admin** views proof of payment
4. **Admin** approves or rejects payment
5. **Payment status** updated:
   - `payment_status = 'verified'` (if approved)
   - `payment_status = 'rejected'` (if rejected)

**Admin does NOT confirm quotations!**  
**Admin ONLY confirms proof of payment!**

---

## 📊 Database Status Flow

### Quotation Status States:
| Status | When | Who Controls | Description |
|--------|------|--------------|-------------|
| `pending` | When provider uploads | Service Provider | Awaiting client selection |
| `confirmed` | When client accepts | **Client** | Selected by client |
| `rejected` | When client picks another | **System (auto)** | Not selected |

### Payment Status States:
| Status | When | Who Controls | Description |
|--------|------|--------------|-------------|
| `pending` | When client uploads proof | Client | Awaiting admin verification |
| `verified` | When admin approves | **Admin** | Payment confirmed |
| `rejected` | When admin rejects | **Admin** | Payment rejected |

---

## 🐛 Bug That Was Fixed

### Before (WRONG):
```javascript
// customer-quotation.js line 138
.eq('quotation_status', 'confirmed')  // ❌ WRONG! Client can't see anything
```

```sql
-- SQL script
quotation_status = 'confirmed'  -- ❌ WRONG! Client confirms, not us
```

### After (CORRECT):
```javascript
// customer-quotation.js line 138
.eq('quotation_status', 'pending')  // ✅ CORRECT! Client sees pending quotations
```

```sql
-- SQL script  
quotation_status = 'pending'  -- ✅ CORRECT! Simulates provider uploads
```

---

## 🧪 What the Test Data Does

When you run `use_existing_data_booking_flow.sql`:

1. ✅ Creates **job carts** for existing client/event
2. ✅ Creates **3 quotations per job cart** from different providers
3. ✅ Sets `quotation_status = 'pending'` (so client can see them)
4. ✅ Prices are within the client's budget range
5. ✅ Simulates what would happen if 3 providers uploaded in real-time

Then you test:
- ✅ Can client see pending quotations?
- ✅ Can client select one quotation per service?
- ✅ Does status change to 'confirmed'?
- ✅ Can client proceed to payment?
- ✅ Can admin verify payment?

---

## 🎯 Key Takeaways

1. **Job cart** = Service request from client
2. **Pending quotations** = Provider offers waiting for client selection
3. **Client confirms** quotations (by accepting them)
4. **Admin confirms** payments (not quotations!)
5. **Limit**: 3 quotations per job cart maximum
6. **Real-time**: Providers upload while timer runs

---

**Now the system is correct!** 🎉

