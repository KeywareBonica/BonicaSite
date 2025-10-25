/**
 * Universal Form Validation System
 * Prevents invalid data from being stored in the database
 * Provides real-time validation with user-friendly error messages
 * Works across all forms in the system (registration, booking, quotation, admin, etc.)
 */

class UniversalFormValidator {
  constructor() {
    this.validationRules = {
      name: {
        pattern: /^[a-zA-Z\s]+$/,
        minLength: 2,
        maxLength: 50,
        message: 'Name must contain only letters and spaces (2-50 characters)',
        invalidChars: /[^a-zA-Z\s]/,
        invalidCharsMessage: 'Names cannot contain numbers or special characters'
      },
      email: {
        pattern: /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/,
        validDomains: ['.com', '.org', '.net', '.co.za', '.co', '.za', '.gov.za', '.ac.za'],
        message: 'Email must have a valid domain (e.g., .com, .co.za)',
        invalidChars: /[^a-zA-Z0-9._@-]/,
        invalidCharsMessage: 'Email contains invalid characters'
      },
      phone: {
        pattern: /^0[0-9]{9}$/,
        length: 10,
        message: 'Phone number must be 10 digits starting with 0',
        formatMessage: 'Enter format: 0XXXXXXXXX'
      },
      password: {
        minLength: 8,
        requireUppercase: true,
        requireLowercase: true,
        requireNumbers: true,
        requireSpecialChars: true,
        specialChars: /[!@#$%^&*(),.?":{}|<>]/,
        message: 'Password must be at least 8 characters with uppercase, lowercase, numbers, and special characters'
      },
      text: {
        pattern: /^[a-zA-Z\s\-–—]+$/,
        maxLength: 500,
        message: 'Text must contain only letters, spaces, and hyphens',
        invalidChars: /[#@$%^&*()_+=\[\]{};':"\\|,.<>\/?~`0-9]/,
        invalidCharsMessage: 'Text cannot contain numbers, hashtags, or special characters'
      },
      numeric: {
        pattern: /^[0-9]+(\.[0-9]{1,2})?$/,
        min: 1,
        max: 999999,
        message: 'Must be a valid positive number (R1 - R999,999)'
      }
    };
    
    this.errorMessages = {
      required: 'This field is required',
      invalid: 'Invalid format',
      tooShort: 'Too short',
      tooLong: 'Too long',
      alreadyExists: 'Already exists in system',
      passwordsNotMatch: 'Passwords do not match'
    };
  }

  /**
   * Validate name field (first name, surname)
   */
  validateName(value, fieldName = 'Name') {
    const errors = [];
    const trimmedValue = value.trim();

    if (!trimmedValue) {
      errors.push(`${fieldName} is required`);
      return { isValid: false, errors, cleanValue: '' };
    }

    // Check for invalid characters
    if (this.validationRules.name.invalidChars.test(trimmedValue)) {
      errors.push(this.validationRules.name.invalidCharsMessage);
    }

    // Check length
    if (trimmedValue.length < this.validationRules.name.minLength) {
      errors.push(`${fieldName} must be at least ${this.validationRules.name.minLength} characters`);
    }

    if (trimmedValue.length > this.validationRules.name.maxLength) {
      errors.push(`${fieldName} must be no more than ${this.validationRules.name.maxLength} characters`);
    }

    // Check for numbers
    if (/\d/.test(trimmedValue)) {
      errors.push(`${fieldName} cannot contain numbers`);
    }

    // Check for special characters (excluding spaces)
    if (/[^a-zA-Z\s]/.test(trimmedValue)) {
      errors.push(`${fieldName} cannot contain special characters`);
    }

    return {
      isValid: errors.length === 0,
      errors,
      cleanValue: trimmedValue
    };
  }

  /**
   * Validate email field
   */
  validateEmail(value) {
    const errors = [];
    const trimmedValue = value.trim().toLowerCase();

    if (!trimmedValue) {
      errors.push('Email is required');
      return { isValid: false, errors, cleanValue: '' };
    }

    // Check for invalid characters
    if (this.validationRules.email.invalidChars.test(trimmedValue)) {
      errors.push(this.validationRules.email.invalidCharsMessage);
    }

    // Check basic email format
    if (!this.validationRules.email.pattern.test(trimmedValue)) {
      errors.push('Invalid email format');
    }

    // Check for @ symbol
    if (!trimmedValue.includes('@')) {
      errors.push('Email must contain @ symbol');
    }

    // Check domain format
    const domainPart = trimmedValue.split('@')[1];
    if (!domainPart || !domainPart.includes('.')) {
      errors.push('Email must have a valid domain with extension');
    }

    // Check TLD length
    const tld = domainPart.split('.').pop();
    if (tld && tld.length < 2) {
      errors.push('Email domain extension must be at least 2 characters');
    }

    // Check for valid domain extensions
    const hasValidDomain = this.validationRules.email.validDomains.some(domain => 
      trimmedValue.endsWith(domain)
    );
    
    if (!hasValidDomain) {
      errors.push('Email must have a valid domain extension (.com, .co.za, .org, etc.)');
    }

    return {
      isValid: errors.length === 0,
      errors,
      cleanValue: trimmedValue
    };
  }

  /**
   * Validate phone number (South African format)
   */
  validatePhone(value) {
    const errors = [];
    const cleanValue = value.replace(/\D/g, ''); // Remove non-digits

    if (!cleanValue) {
      errors.push('Phone number is required');
      return { isValid: false, errors, cleanValue: '' };
    }

    // Check length
    if (cleanValue.length !== this.validationRules.phone.length) {
      errors.push(`Phone number must be exactly ${this.validationRules.phone.length} digits`);
    }

    // Check format (must start with 0)
    if (!cleanValue.startsWith('0')) {
      errors.push('Phone number must start with 0');
    }

    // Check pattern
    if (!this.validationRules.phone.pattern.test(cleanValue)) {
      errors.push(this.validationRules.phone.message);
    }

    return {
      isValid: errors.length === 0,
      errors,
      cleanValue
    };
  }

  /**
   * Validate password strength
   */
  validatePassword(value) {
    const errors = [];
    const rules = this.validationRules.password;

    if (!value) {
      errors.push('Password is required');
      return { isValid: false, errors, cleanValue: '' };
    }

    // Check minimum length
    if (value.length < rules.minLength) {
      errors.push(`Password must be at least ${rules.minLength} characters`);
    }

    // Check for uppercase letter
    if (rules.requireUppercase && !/[A-Z]/.test(value)) {
      errors.push('Password must contain at least one uppercase letter');
    }

    // Check for lowercase letter
    if (rules.requireLowercase && !/[a-z]/.test(value)) {
      errors.push('Password must contain at least one lowercase letter');
    }

    // Check for numbers
    if (rules.requireNumbers && !/\d/.test(value)) {
      errors.push('Password must contain at least one number');
    }

    // Check for special characters
    if (rules.requireSpecialChars && !rules.specialChars.test(value)) {
      errors.push('Password must contain at least one special character (!@#$%^&*(),.?":{}|<>)');
    }

    return {
      isValid: errors.length === 0,
      errors,
      cleanValue: value
    };
  }

  /**
   * Validate password confirmation
   */
  validatePasswordConfirmation(password, confirmPassword) {
    const errors = [];

    if (!confirmPassword) {
      errors.push('Please confirm your password');
      return { isValid: false, errors };
    }

    if (password !== confirmPassword) {
      errors.push('Passwords do not match');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  /**
   * Validate text fields (caption, description, location, etc.)
   */
  validateText(value, fieldName = 'Text', maxLength = 500) {
    const errors = [];
    const trimmedValue = value.trim();

    if (!trimmedValue) {
      errors.push(`${fieldName} is required`);
      return { isValid: false, errors, cleanValue: '' };
    }

    // Check for invalid characters
    if (this.validationRules.text.invalidChars.test(trimmedValue)) {
      errors.push(this.validationRules.text.invalidCharsMessage);
    }

    // Check length
    if (trimmedValue.length > maxLength) {
      errors.push(`${fieldName} must be no more than ${maxLength} characters`);
    }

    return {
      isValid: errors.length === 0,
      errors,
      cleanValue: trimmedValue
    };
  }

  /**
   * Validate address fields (province, city, town, street name)
   */
  validateAddressField(value, fieldName = 'Address Field') {
    const errors = [];
    const trimmedValue = value.trim();

    if (!trimmedValue) {
      errors.push(`${fieldName} is required`);
      return { isValid: false, errors, cleanValue: '' };
    }

    // Check for invalid characters (same as text fields)
    if (this.validationRules.text.invalidChars.test(trimmedValue)) {
      errors.push(this.validationRules.text.invalidCharsMessage);
    }

    // Check length (reasonable limit for address fields)
    if (trimmedValue.length > 100) {
      errors.push(`${fieldName} must be no more than 100 characters`);
    }

    return {
      isValid: errors.length === 0,
      errors,
      cleanValue: trimmedValue
    };
  }

  /**
   * Validate house number (allows numbers and letters, some special chars)
   */
  validateHouseNumber(value) {
    const errors = [];
    const trimmedValue = value.trim();

    if (!trimmedValue) {
      errors.push('House number is required');
      return { isValid: false, errors, cleanValue: '' };
    }

    // Allow letters, numbers, spaces, hyphens, and forward slashes for house numbers
    // Examples: "123", "45A", "12-14", "123/125"
    if (!/^[a-zA-Z0-9\s\-\/]+$/.test(trimmedValue)) {
      errors.push('House number can only contain letters, numbers, spaces, hyphens, and forward slashes');
    }

    // Check length
    if (trimmedValue.length > 20) {
      errors.push('House number must be no more than 20 characters');
    }

    return {
      isValid: errors.length === 0,
      errors,
      cleanValue: trimmedValue
    };
  }

  /**
   * Validate postal code (allows numbers and letters)
   */
  validatePostalCode(value) {
    const errors = [];
    const trimmedValue = value.trim();

    if (!trimmedValue) {
      errors.push('Postal code is required');
      return { isValid: false, errors, cleanValue: '' };
    }

    // Allow letters and numbers for postal codes
    // Examples: "1234", "ABC123", "1234AB"
    if (!/^[a-zA-Z0-9]+$/.test(trimmedValue)) {
      errors.push('Postal code can only contain letters and numbers');
    }

    // Check length (typical postal code length)
    if (trimmedValue.length < 3 || trimmedValue.length > 10) {
      errors.push('Postal code must be between 3 and 10 characters');
    }

    return {
      isValid: errors.length === 0,
      errors,
      cleanValue: trimmedValue
    };
  }

  /**
   * Validate custom service name
   */
  validateCustomServiceName(value) {
    const errors = [];
    const trimmedValue = value.trim();

    if (!trimmedValue) {
      errors.push('Custom service name is required');
      return { isValid: false, errors, cleanValue: '' };
    }

    // Check for invalid characters (same as text fields)
    if (this.validationRules.text.invalidChars.test(trimmedValue)) {
      errors.push(this.validationRules.text.invalidCharsMessage);
    }

    // Check length
    if (trimmedValue.length > 50) {
      errors.push('Custom service name must be no more than 50 characters');
    }

    return {
      isValid: errors.length === 0,
      errors,
      cleanValue: trimmedValue
    };
  }

  /**
   * Validate numeric fields (prices, rates)
   */
  validateNumeric(value, fieldName = 'Number') {
    const errors = [];
    const cleanValue = value.replace(/[^0-9.]/g, '');

    if (!cleanValue) {
      errors.push(`${fieldName} is required`);
      return { isValid: false, errors, cleanValue: '' };
    }

    const numValue = parseFloat(cleanValue);

    if (isNaN(numValue)) {
      errors.push(`${fieldName} must be a valid number`);
    }

    if (numValue < this.validationRules.numeric.min) {
      errors.push(`${fieldName} must be at least ${this.validationRules.numeric.min}`);
    }

    if (numValue > this.validationRules.numeric.max) {
      errors.push(`${fieldName} cannot exceed ${this.validationRules.numeric.max}`);
    }

    return {
      isValid: errors.length === 0,
      errors,
      cleanValue: cleanValue
    };
  }

  /**
   * Check if email already exists in database
   */
  async checkEmailExists(email, userType, supabaseClient) {
    try {
      if (!supabaseClient) return false;

      const tableName = userType === 'customer' ? 'client' : 'service_provider';
      const emailField = userType === 'customer' ? 'client_email' : 'service_provider_email';
      
      const { data, error } = await supabaseClient
        .from(tableName)
        .select(emailField)
        .eq(emailField, email.toLowerCase())
        .single();
      
      return !error && data;
    } catch (error) {
      console.warn('Email check failed:', error);
      return false;
    }
  }

  /**
   * Check if phone number already exists in database
   */
  async checkPhoneExists(phone, userType, supabaseClient) {
    try {
      if (!supabaseClient) return false;

      const tableName = userType === 'customer' ? 'client' : 'service_provider';
      const phoneField = userType === 'customer' ? 'client_contact' : 'service_provider_contact';
      
      const { data, error } = await supabaseClient
        .from(tableName)
        .select(phoneField)
        .eq(phoneField, phone)
        .single();
      
      return !error && data;
    } catch (error) {
      console.warn('Phone check failed:', error);
      return false;
    }
  }

  /**
   * Display validation errors in the UI
   */
  displayErrors(fieldId, errors) {
    const errorElement = document.getElementById(fieldId + 'Error');
    const field = document.getElementById(fieldId);

    if (errorElement && errors.length > 0) {
      errorElement.textContent = errors[0]; // Show first error
      errorElement.style.color = '#dc3545';
      errorElement.style.fontSize = '0.875rem';
      errorElement.style.marginTop = '0.25rem';
      errorElement.style.display = 'block';
    }

    if (field) {
      field.classList.add('is-invalid');
      field.classList.remove('is-valid');
    }
  }

  /**
   * Clear validation errors from the UI
   */
  clearErrors(fieldId) {
    const errorElement = document.getElementById(fieldId + 'Error');
    const field = document.getElementById(fieldId);

    if (errorElement) {
      errorElement.textContent = '';
      errorElement.style.display = 'none';
    }

    if (field) {
      field.classList.remove('is-invalid');
      field.classList.add('is-valid');
    }
  }

  /**
   * Universal form validation - works for any form type
   */
  async validateUniversalForm(formData, formType, supabaseClient) {
    const validationResults = {
      isValid: true,
      errors: {},
      cleanData: {}
    };

    // Get validation rules based on form type
    const rules = this.getValidationRulesForFormType(formType);
    
    // Validate each field based on its type
    for (const [fieldName, fieldValue] of Object.entries(formData)) {
      const fieldRule = rules[fieldName];
      if (!fieldRule) continue;

      const result = await this.validateFieldByType(fieldValue, fieldRule, fieldName, supabaseClient);
      
      if (!result.isValid) {
        validationResults.isValid = false;
        validationResults.errors[fieldName] = result.errors;
      } else {
        validationResults.cleanData[fieldName] = result.cleanValue;
      }
    }

    return validationResults;
  }

  /**
   * Get validation rules for specific form types
   */
  getValidationRulesForFormType(formType) {
    const rules = {
      // Registration form rules
      registration: {
        name: { type: 'name', required: true },
        surname: { type: 'name', required: true },
        spName: { type: 'name', required: true },
        spSurname: { type: 'name', required: true },
        email: { type: 'email', required: true },
        spEmail: { type: 'email', required: true },
        contact: { type: 'phone', required: true },
        spContact: { type: 'phone', required: true },
        password: { type: 'password', required: true },
        spPassword: { type: 'password', required: true },
        confirmPassword: { type: 'password_confirm', required: true },
        spConfirmPassword: { type: 'password_confirm', required: true },
        province: { type: 'address', required: true },
        city: { type: 'address', required: true },
        town: { type: 'address', required: true },
        streetName: { type: 'address', required: true },
        houseNumber: { type: 'house_number', required: true },
        postalCode: { type: 'postal_code', required: true },
        spLocation: { type: 'address', required: true },
        spCaption: { type: 'text', maxLength: 100, required: true },
        spDescription: { type: 'text', maxLength: 500, required: true },
        spBasePrice: { type: 'numeric', required: true },
        spOvertimeRate: { type: 'numeric', required: true },
        customServiceName: { type: 'text', maxLength: 50, required: false }
      },
      
      // Profile update form rules
      profile_update: {
        clientName: { type: 'name', required: true },
        clientSurname: { type: 'name', required: true },
        clientEmail: { type: 'email', required: true },
        clientContact: { type: 'phone', required: true },
        clientCity: { type: 'address', required: false },
        clientTown: { type: 'address', required: false },
        clientStreetName: { type: 'address', required: false },
        clientHouseNumber: { type: 'house_number', required: false },
        clientPostalCode: { type: 'postal_code', required: false },
        currentPassword: { type: 'password', required: true },
        newPassword: { type: 'password', required: true },
        confirmPassword: { type: 'password_confirm', required: true },
        'first-name': { type: 'name', required: true },
        'last-name': { type: 'name', required: true },
        email: { type: 'email', required: true },
        contact: { type: 'phone', required: true },
        location: { type: 'address', required: false }
      },
      
      // Booking form rules
      booking: {
        eventName: { type: 'text', maxLength: 100, required: true },
        eventLocation: { type: 'address', required: true },
        updateLocation: { type: 'address', required: true },
        specialRequests: { type: 'text', maxLength: 500, required: false },
        updateSpecialRequests: { type: 'text', maxLength: 500, required: false },
        eventDescription: { type: 'text', maxLength: 1000, required: false }
      },
      
      // Quotation form rules
      quotation: {
        quotationPrice: { type: 'numeric', required: true },
        quotationDetails: { type: 'text', maxLength: 1000, required: true },
        quotationFileName: { type: 'filename', required: false }
      },
      
      // Admin form rules
      admin: {
        adminName: { type: 'name', required: true },
        adminEmail: { type: 'email', required: true },
        adminPassword: { type: 'password', required: true }
      }
    };

    return rules[formType] || {};
  }

  /**
   * Validate field based on its type
   */
  async validateFieldByType(value, rule, fieldName, supabaseClient) {
    if (rule.required && (!value || value.trim() === '')) {
      return {
        isValid: false,
        errors: [`${fieldName} is required`],
        cleanValue: ''
      };
    }

    if (!value || value.trim() === '') {
      return {
        isValid: true,
        errors: [],
        cleanValue: ''
      };
    }

    switch (rule.type) {
      case 'name':
        return this.validateName(value, fieldName);
      
      case 'email':
        const emailResult = this.validateEmail(value);
        if (emailResult.isValid) {
          // Check if email exists (only for registration and profile updates)
          const emailExists = await this.checkEmailExists(value, 'any', supabaseClient);
          if (emailExists) {
            return {
              isValid: false,
              errors: ['This email is already registered'],
              cleanValue: emailResult.cleanValue
            };
          }
        }
        return emailResult;
      
      case 'phone':
        const phoneResult = this.validatePhone(value);
        if (phoneResult.isValid) {
          // Check if phone exists (only for registration and profile updates)
          const phoneExists = await this.checkPhoneExists(phoneResult.cleanValue, 'any', supabaseClient);
          if (phoneExists) {
            return {
              isValid: false,
              errors: ['This phone number is already registered'],
              cleanValue: phoneResult.cleanValue
            };
          }
        }
        return phoneResult;
      
      case 'password':
        return this.validatePassword(value);
      
      case 'password_confirm':
        // This needs to be handled by the calling function with the original password
        return { isValid: true, errors: [], cleanValue: value };
      
      case 'address':
        return this.validateAddressField(value, fieldName);
      
      case 'house_number':
        return this.validateHouseNumber(value);
      
      case 'postal_code':
        return this.validatePostalCode(value);
      
      case 'text':
        return this.validateText(value, fieldName, rule.maxLength || 500);
      
      case 'numeric':
        return this.validateNumeric(value, fieldName);
      
      case 'filename':
        return this.validateFileName(value);
      
      default:
        return {
          isValid: true,
          errors: [],
          cleanValue: value
        };
    }
  }

  /**
   * Validate file names (for quotations)
   */
  validateFileName(value) {
    const errors = [];
    const trimmedValue = value.trim();

    if (!trimmedValue) {
      return { isValid: true, errors: [], cleanValue: '' };
    }

    // Check for invalid characters in file names
    if (/[<>:"/\\|?*]/.test(trimmedValue)) {
      errors.push('File name contains invalid characters');
    }

    // Check length
    if (trimmedValue.length > 255) {
      errors.push('File name is too long (max 255 characters)');
    }

    return {
      isValid: errors.length === 0,
      errors,
      cleanValue: trimmedValue
    };
  }

  /**
   * Initialize validation for any form
   */
  initializeFormValidation(formId, formType, supabaseClient) {
    const form = document.getElementById(formId);
    if (!form) return;

    const rules = this.getValidationRulesForFormType(formType);
    
    // Add validation to all form fields
    Object.keys(rules).forEach(fieldName => {
      const field = document.getElementById(fieldName);
      if (!field) return;

      const rule = rules[fieldName];
      
      // Add real-time validation
      field.addEventListener('input', async () => {
        await this.validateFieldRealTime(field, rule, fieldName, supabaseClient);
      });
      
      field.addEventListener('blur', async () => {
        await this.validateFieldRealTime(field, rule, fieldName, supabaseClient);
      });
    });

    // Add form submission validation
    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      
      const formData = this.collectFormData(form, rules);
      const validationResult = await this.validateUniversalForm(formData, formType, supabaseClient);
      
      if (!validationResult.isValid) {
        this.displayFormErrors(validationResult.errors);
        return false;
      }
      
      // Clear errors and proceed with form submission
      this.clearFormErrors(form);
      
      // Trigger custom form submission handler
      const submitEvent = new CustomEvent('validatedSubmit', {
        detail: { formData: validationResult.cleanData, validationResult }
      });
      form.dispatchEvent(submitEvent);
    });
  }

  /**
   * Collect form data based on rules
   */
  collectFormData(form, rules) {
    const formData = {};
    
    Object.keys(rules).forEach(fieldName => {
      const field = document.getElementById(fieldName);
      if (field) {
        formData[fieldName] = field.value;
      }
    });
    
    return formData;
  }

  /**
   * Validate field in real-time
   */
  async validateFieldRealTime(field, rule, fieldName, supabaseClient) {
    const result = await this.validateFieldByType(field.value, rule, fieldName, supabaseClient);
    
    if (result.isValid) {
      this.clearErrors(fieldName);
      if (result.cleanValue !== field.value) {
        field.value = result.cleanValue;
      }
    } else {
      this.displayErrors(fieldName, result.errors);
    }
  }

  /**
   * Display form errors
   */
  displayFormErrors(errors) {
    Object.keys(errors).forEach(fieldName => {
      this.displayErrors(fieldName, errors[fieldName]);
    });
  }

  /**
   * Clear all form errors
   */
  clearFormErrors(form) {
    const errorElements = form.querySelectorAll('.error, .invalid-feedback');
    errorElements.forEach(element => {
      element.textContent = '';
      element.style.display = 'none';
    });
    
    const invalidFields = form.querySelectorAll('.is-invalid');
    invalidFields.forEach(field => {
      field.classList.remove('is-invalid');
      field.classList.add('is-valid');
    });
  }

  /**
   * Validate entire form before submission (legacy method for backward compatibility)
   */
  async validateForm(formData, userType, supabaseClient) {
    const validationResults = {
      isValid: true,
      errors: {},
      cleanData: {}
    };

    // Validate names
    if (userType === 'customer') {
      const nameResult = this.validateName(formData.name, 'Name');
      const surnameResult = this.validateName(formData.surname, 'Surname');
      
      if (!nameResult.isValid) {
        validationResults.isValid = false;
        validationResults.errors.name = nameResult.errors;
      } else {
        validationResults.cleanData.name = nameResult.cleanValue;
      }

      if (!surnameResult.isValid) {
        validationResults.isValid = false;
        validationResults.errors.surname = surnameResult.errors;
      } else {
        validationResults.cleanData.surname = surnameResult.cleanValue;
      }
    } else {
      const spNameResult = this.validateName(formData.spName, 'Name');
      const spSurnameResult = this.validateName(formData.spSurname, 'Surname');
      
      if (!spNameResult.isValid) {
        validationResults.isValid = false;
        validationResults.errors.spName = spNameResult.errors;
      } else {
        validationResults.cleanData.spName = spNameResult.cleanValue;
      }

      if (!spSurnameResult.isValid) {
        validationResults.isValid = false;
        validationResults.errors.spSurname = spSurnameResult.errors;
      } else {
        validationResults.cleanData.spSurname = spSurnameResult.cleanValue;
      }
    }

    // Validate email
    const emailField = userType === 'customer' ? 'email' : 'spEmail';
    const emailResult = this.validateEmail(formData[emailField]);
    
    if (!emailResult.isValid) {
      validationResults.isValid = false;
      validationResults.errors[emailField] = emailResult.errors;
    } else {
      validationResults.cleanData[emailField] = emailResult.cleanValue;
      
      // Check if email exists
      const emailExists = await this.checkEmailExists(emailResult.cleanValue, userType, supabaseClient);
      if (emailExists) {
        validationResults.isValid = false;
        validationResults.errors[emailField] = ['This email is already registered'];
      }
    }

    // Validate phone
    const phoneField = userType === 'customer' ? 'contact' : 'spContact';
    const phoneResult = this.validatePhone(formData[phoneField]);
    
    if (!phoneResult.isValid) {
      validationResults.isValid = false;
      validationResults.errors[phoneField] = phoneResult.errors;
    } else {
      validationResults.cleanData[phoneField] = phoneResult.cleanValue;
      
      // Check if phone exists
      const phoneExists = await this.checkPhoneExists(phoneResult.cleanValue, userType, supabaseClient);
      if (phoneExists) {
        validationResults.isValid = false;
        validationResults.errors[phoneField] = ['This phone number is already registered'];
      }
    }

    // Validate passwords
    const passwordField = userType === 'customer' ? 'password' : 'spPassword';
    const confirmPasswordField = userType === 'customer' ? 'confirmPassword' : 'spConfirmPassword';
    
    const passwordResult = this.validatePassword(formData[passwordField]);
    const confirmPasswordResult = this.validatePasswordConfirmation(formData[passwordField], formData[confirmPasswordField]);
    
    if (!passwordResult.isValid) {
      validationResults.isValid = false;
      validationResults.errors[passwordField] = passwordResult.errors;
    }

    if (!confirmPasswordResult.isValid) {
      validationResults.isValid = false;
      validationResults.errors[confirmPasswordField] = confirmPasswordResult.errors;
    }

    // Validate customer address fields
    if (userType === 'customer') {
      const provinceResult = this.validateAddressField(formData.province, 'Province');
      const cityResult = this.validateAddressField(formData.city, 'City');
      const townResult = this.validateAddressField(formData.town, 'Town');
      const streetNameResult = this.validateAddressField(formData.streetName, 'Street Name');
      const houseNumberResult = this.validateHouseNumber(formData.houseNumber);
      const postalCodeResult = this.validatePostalCode(formData.postalCode);
      
      if (!provinceResult.isValid) {
        validationResults.isValid = false;
        validationResults.errors.province = provinceResult.errors;
      } else {
        validationResults.cleanData.province = provinceResult.cleanValue;
      }

      if (!cityResult.isValid) {
        validationResults.isValid = false;
        validationResults.errors.city = cityResult.errors;
      } else {
        validationResults.cleanData.city = cityResult.cleanValue;
      }

      if (!townResult.isValid) {
        validationResults.isValid = false;
        validationResults.errors.town = townResult.errors;
      } else {
        validationResults.cleanData.town = townResult.cleanValue;
      }

      if (!streetNameResult.isValid) {
        validationResults.isValid = false;
        validationResults.errors.streetName = streetNameResult.errors;
      } else {
        validationResults.cleanData.streetName = streetNameResult.cleanValue;
      }

      if (!houseNumberResult.isValid) {
        validationResults.isValid = false;
        validationResults.errors.houseNumber = houseNumberResult.errors;
      } else {
        validationResults.cleanData.houseNumber = houseNumberResult.cleanValue;
      }

      if (!postalCodeResult.isValid) {
        validationResults.isValid = false;
        validationResults.errors.postalCode = postalCodeResult.errors;
      } else {
        validationResults.cleanData.postalCode = postalCodeResult.cleanValue;
      }
    }

    // Validate service provider specific fields
    if (userType === 'service_provider') {
      // Validate location field
      const locationResult = this.validateAddressField(formData.spLocation, 'Location');
      if (!locationResult.isValid) {
        validationResults.isValid = false;
        validationResults.errors.spLocation = locationResult.errors;
      } else {
        validationResults.cleanData.spLocation = locationResult.cleanValue;
      }

      // Validate text fields
      const captionResult = this.validateText(formData.spCaption, 'Caption', 100);
      const descriptionResult = this.validateText(formData.spDescription, 'Description', 500);
      
      if (!captionResult.isValid) {
        validationResults.isValid = false;
        validationResults.errors.spCaption = captionResult.errors;
      } else {
        validationResults.cleanData.spCaption = captionResult.cleanValue;
      }

      if (!descriptionResult.isValid) {
        validationResults.isValid = false;
        validationResults.errors.spDescription = descriptionResult.errors;
      } else {
        validationResults.cleanData.spDescription = descriptionResult.cleanValue;
      }

      // Validate custom service name if custom service is selected
      if (formData.spService === 'custom') {
        const customServiceResult = this.validateCustomServiceName(formData.customServiceName);
        if (!customServiceResult.isValid) {
          validationResults.isValid = false;
          validationResults.errors.customServiceName = customServiceResult.errors;
        } else {
          validationResults.cleanData.customServiceName = customServiceResult.cleanValue;
        }
      }

      // Validate numeric fields
      const basePriceResult = this.validateNumeric(formData.spBasePrice, 'Base Price');
      const overtimeRateResult = this.validateNumeric(formData.spOvertimeRate, 'Overtime Rate');
      
      if (!basePriceResult.isValid) {
        validationResults.isValid = false;
        validationResults.errors.spBasePrice = basePriceResult.errors;
      } else {
        validationResults.cleanData.spBasePrice = parseFloat(basePriceResult.cleanValue);
      }

      if (!overtimeRateResult.isValid) {
        validationResults.isValid = false;
        validationResults.errors.spOvertimeRate = overtimeRateResult.errors;
      } else {
        validationResults.cleanData.spOvertimeRate = parseFloat(overtimeRateResult.cleanValue);
      }

      // Validate operating days
      const operatingDays = formData.spOperatingDays || [];
      if (operatingDays.length === 0) {
        validationResults.isValid = false;
        validationResults.errors.spOperatingDays = ['Please select at least one operating day'];
      }
    }

    return validationResults;
  }
}

// Export for use in other files
window.FormValidator = UniversalFormValidator;
window.UniversalFormValidator = UniversalFormValidator;
