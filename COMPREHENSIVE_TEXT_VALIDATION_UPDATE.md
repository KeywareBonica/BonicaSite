# Comprehensive Text Field Validation System - Updated

## Overview
The validation system has been updated to ensure that **special character restrictions apply to ALL text input fields** except passwords and emails, as requested. This provides consistent validation across the entire registration form.

## Updated Validation Rules

### ✅ **Fields with Special Character Restrictions** (Letters, spaces, and hyphens only)

#### Customer Fields:
- **Name** - First name and surname
- **Province** - Province/state name
- **City** - City name  
- **Town** - Town/suburb name
- **Street Name** - Street name

#### Service Provider Fields:
- **Name** - First name and surname
- **Location** - Business location/address
- **Caption** - Service tagline (max 100 chars)
- **Description** - Service description (max 500 chars)
- **Custom Service Name** - When "Other/Custom Service" is selected

### ✅ **Fields with Modified Rules** (Allow specific characters)

#### House Number:
- **Allowed**: Letters, numbers, spaces, hyphens (-), forward slashes (/)
- **Examples**: "123", "45A", "12-14", "123/125"
- **Rejected**: Special characters like @, #, $, etc.

#### Postal Code:
- **Allowed**: Letters and numbers only
- **Examples**: "1234", "ABC123", "1234AB"
- **Length**: 3-10 characters
- **Rejected**: Special characters, spaces

### ✅ **Fields with NO Special Character Restrictions** (Exceptions)

#### Passwords:
- **Required**: Uppercase, lowercase, numbers, special characters
- **Special Characters Allowed**: !@#$%^&*(),.?":{}|<>
- **Minimum**: 8 characters

#### Emails:
- **Required**: @ symbol and valid domain
- **Valid Domains**: .com, .org, .net, .co.za, .co, .za, .gov.za, .ac.za
- **Special Characters Allowed**: . _ - @

## Implementation Details

### Client-Side Validation (`js/form-validation.js`)

#### New Validation Methods:
- `validateAddressField()` - For province, city, town, street name, location
- `validateHouseNumber()` - For house numbers with specific character rules
- `validatePostalCode()` - For postal codes (letters and numbers only)
- `validateCustomServiceName()` - For custom service names

#### Character Restrictions:
```javascript
// For most text fields (names, addresses, descriptions)
invalidChars: /[#@$%^&*()_+=\[\]{};':"\\|,.<>\/?~`0-9]/

// For house numbers (more permissive)
pattern: /^[a-zA-Z0-9\s\-\/]+$/

// For postal codes (letters and numbers only)
pattern: /^[a-zA-Z0-9]+$/
```

### Server-Side Validation (`supabase/migrations/20250101000004_add_server_side_validation.sql`)

#### New Database Functions:
- `validate_address_field()` - Validates address fields
- `validate_house_number()` - Validates house numbers
- `validate_postal_code()` - Validates postal codes
- `validate_custom_service_name()` - Validates custom service names

#### Database Triggers:
- Updated `validate_client_data()` trigger includes all address fields
- Updated `validate_service_provider_data()` trigger includes location field

### Real-Time Validation (`Registration.html`)

#### Added Validation For:
- Province, City, Town, Street Name fields
- House Number field (with auto-formatting)
- Postal Code field (with auto-formatting)
- Service Provider Location field
- Custom Service Name field

## Validation Examples

### ✅ **Valid Input Examples:**

#### Names:
- "John Smith"
- "Mary-Jane O'Connor"
- "Jean-Pierre"

#### Address Fields:
- "Western Cape"
- "Cape Town"
- "Sea Point"
- "Main Street"

#### House Numbers:
- "123"
- "45A"
- "12-14"
- "123/125"

#### Postal Codes:
- "8001"
- "ABC123"
- "1234AB"

#### Service Descriptions:
- "Professional DJ Services"
- "Wedding Photography - Premium Package"
- "Event Planning & Coordination"

### ❌ **Invalid Input Examples:**

#### Names (rejected):
- "John123" (contains numbers)
- "Mary@Smith" (contains special characters)
- "John#1" (contains hashtag)

#### Address Fields (rejected):
- "Cape Town 123" (contains numbers)
- "Sea@Point" (contains special characters)
- "Main#Street" (contains hashtag)

#### House Numbers (rejected):
- "123@" (contains special characters)
- "45#A" (contains hashtag)

#### Postal Codes (rejected):
- "123 456" (contains spaces)
- "ABC-123" (contains hyphens)

#### Service Descriptions (rejected):
- "DJ #1 Services" (contains hashtag and numbers)
- "Photography@2024" (contains special characters)
- "Service 123" (contains numbers)

## Error Messages

### User-Friendly Messages:
- "Name must contain only letters and spaces (2-50 characters)"
- "Province must contain only letters, spaces, and hyphens (max 100 characters), no numbers or special characters allowed"
- "House number can only contain letters, numbers, spaces, hyphens, and forward slashes"
- "Postal code can only contain letters and numbers (3-10 characters)"
- "Location must contain only letters, spaces, and hyphens (max 100 characters), no numbers or special characters allowed"

## Benefits of Updated System

### 1. **Consistency**
- All text fields follow the same validation rules
- Clear distinction between text fields and special fields (passwords/emails)
- Uniform user experience across all form fields

### 2. **Data Quality**
- Prevents invalid characters from entering the database
- Ensures clean, readable data in all text fields
- Maintains professional appearance of stored data

### 3. **User Experience**
- Real-time feedback on all fields
- Clear error messages explaining what's allowed
- Auto-formatting for fields that allow specific characters

### 4. **Security**
- Prevents injection attacks through text fields
- Validates data at both client and server levels
- Consistent validation rules prevent data corruption

## Testing Scenarios

### Test Cases to Verify:
1. **Name Fields**: Try entering "John123", "Mary@Smith", "Jean-Pierre"
2. **Address Fields**: Try entering "Cape Town 123", "Sea@Point", "Main Street"
3. **House Numbers**: Try entering "123", "45A", "12-14", "123@"
4. **Postal Codes**: Try entering "8001", "ABC123", "123 456"
5. **Service Descriptions**: Try entering "DJ Services", "Photography@2024", "Service #1"

### Expected Results:
- Invalid inputs should show error messages immediately
- Form submission should be blocked until all fields are valid
- Database should reject invalid data even if client-side validation is bypassed

## Conclusion

The updated validation system now ensures that **special character restrictions apply to ALL text input fields** except passwords and emails, providing:

- **Comprehensive coverage** of all form fields
- **Consistent validation rules** across the application
- **Professional data quality** in the database
- **Enhanced user experience** with clear feedback
- **Robust security** with dual-layer validation

The system successfully prevents invalid data from being stored while maintaining the flexibility needed for passwords and emails, which require special characters for proper functionality.
