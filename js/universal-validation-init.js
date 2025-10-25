/**
 * Universal Form Validation Initialization Script
 * This script automatically initializes validation for all forms across the system
 */

// Initialize universal validation when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    // Wait for FormValidator to be loaded
    if (typeof window.UniversalFormValidator === 'undefined') {
        console.warn('UniversalFormValidator not loaded yet, retrying...');
        setTimeout(initializeUniversalValidation, 100);
        return;
    }
    
    initializeUniversalValidation();
});

function initializeUniversalValidation() {
    // Initialize Supabase client
    const SUPABASE_URL = "https://spudtrptbyvwyhvistdf.supabase.co";
    const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNwdWR0cnB0Ynl2d3lodmlzdGRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU2OTk4NjgsImV4cCI6MjA3MTI3NTg2OH0.GBo-RtgbRZCmhSAZi0c5oXynMiJNeyrs0nLsk3CaV8A";
    
    let supabaseClient = null;
    try {
        if (typeof window.supabase !== 'undefined') {
            const { createClient } = window.supabase;
            supabaseClient = createClient(SUPABASE_URL, SUPABASE_KEY);
        }
    } catch (error) {
        console.warn('Supabase client initialization failed:', error);
    }
    
    // Initialize universal validator
    const universalValidator = new window.UniversalFormValidator();
    
    // Auto-detect and initialize forms based on their IDs and content
    initializeFormsByDetection(universalValidator, supabaseClient);
    
    console.log('✅ Universal form validation initialized');
}

function initializeFormsByDetection(validator, supabaseClient) {
    // Registration form
    if (document.getElementById('registrationForm')) {
        console.log('🔍 Initializing registration form validation');
        validator.initializeFormValidation('registrationForm', 'registration', supabaseClient);
        
        // Handle validated submission
        document.getElementById('registrationForm').addEventListener('validatedSubmit', function(e) {
            handleRegistrationSubmission(e.detail.formData, e.detail.validationResult);
        });
    }
    
    // Client profile update form
    if (document.getElementById('profile-form')) {
        console.log('🔍 Initializing client profile update form validation');
        validator.initializeFormValidation('profile-form', 'profile_update', supabaseClient);
        
        // Handle validated submission
        document.getElementById('profile-form').addEventListener('validatedSubmit', function(e) {
            handleProfileUpdateSubmission(e.detail.formData, e.detail.validationResult);
        });
    }
    
    // Service provider profile form
    if (document.getElementById('profile-form') && document.querySelector('input[id="first-name"]')) {
        console.log('🔍 Initializing service provider profile form validation');
        validator.initializeFormValidation('profile-form', 'profile_update', supabaseClient);
        
        // Handle validated submission
        document.getElementById('profile-form').addEventListener('validatedSubmit', function(e) {
            handleServiceProviderProfileSubmission(e.detail.formData, e.detail.validationResult);
        });
    }
    
    // Booking forms (detect by presence of booking-related fields)
    const bookingForms = document.querySelectorAll('form');
    bookingForms.forEach(form => {
        if (form.querySelector('input[id*="Location"], input[id*="location"]') || 
            form.querySelector('textarea[id*="Special"], textarea[id*="special"]')) {
            console.log('🔍 Initializing booking form validation');
            validator.initializeFormValidation(form.id, 'booking', supabaseClient);
            
            // Handle validated submission
            form.addEventListener('validatedSubmit', function(e) {
                handleBookingSubmission(e.detail.formData, e.detail.validationResult);
            });
        }
    });
    
    // Quotation forms
    if (document.querySelector('input[id*="quotationPrice"], input[id*="price"]')) {
        console.log('🔍 Initializing quotation form validation');
        const quotationForm = document.querySelector('form');
        if (quotationForm) {
            validator.initializeFormValidation(quotationForm.id, 'quotation', supabaseClient);
            
            // Handle validated submission
            quotationForm.addEventListener('validatedSubmit', function(e) {
                handleQuotationSubmission(e.detail.formData, e.detail.validationResult);
            });
        }
    }
    
    // Admin forms
    if (document.querySelector('input[id*="admin"], input[id*="Admin"]')) {
        console.log('🔍 Initializing admin form validation');
        const adminForm = document.querySelector('form');
        if (adminForm) {
            validator.initializeFormValidation(adminForm.id, 'admin', supabaseClient);
            
            // Handle validated submission
            adminForm.addEventListener('validatedSubmit', function(e) {
                handleAdminSubmission(e.detail.formData, e.detail.validationResult);
            });
        }
    }
}

// Form submission handlers (these will be called when forms pass validation)
function handleRegistrationSubmission(formData, validationResult) {
    console.log('✅ Registration form validated successfully:', formData);
    // The existing registration logic will handle this
    // This is just a placeholder for the validated submission
}

function handleProfileUpdateSubmission(formData, validationResult) {
    console.log('✅ Profile update form validated successfully:', formData);
    // Trigger the existing profile update logic with validated data
    if (typeof window.updateClientProfile === 'function') {
        window.updateClientProfile(formData);
    }
}

function handleServiceProviderProfileSubmission(formData, validationResult) {
    console.log('✅ Service provider profile form validated successfully:', formData);
    // Trigger the existing service provider profile update logic
    if (typeof window.updateServiceProviderProfile === 'function') {
        window.updateServiceProviderProfile(formData);
    }
}

function handleBookingSubmission(formData, validationResult) {
    console.log('✅ Booking form validated successfully:', formData);
    // Trigger the existing booking logic with validated data
    if (typeof window.submitBooking === 'function') {
        window.submitBooking(formData);
    }
}

function handleQuotationSubmission(formData, validationResult) {
    console.log('✅ Quotation form validated successfully:', formData);
    // Trigger the existing quotation logic with validated data
    if (typeof window.submitQuotation === 'function') {
        window.submitQuotation(formData);
    }
}

function handleAdminSubmission(formData, validationResult) {
    console.log('✅ Admin form validated successfully:', formData);
    // Trigger the existing admin logic with validated data
    if (typeof window.submitAdminAction === 'function') {
        window.submitAdminAction(formData);
    }
}

// Utility function to manually initialize validation for specific forms
window.initializeFormValidation = function(formId, formType, supabaseClient) {
    if (typeof window.UniversalFormValidator === 'undefined') {
        console.error('UniversalFormValidator not loaded');
        return;
    }
    
    const validator = new window.UniversalFormValidator();
    validator.initializeFormValidation(formId, formType, supabaseClient);
    console.log(`✅ Manual validation initialized for form: ${formId} (${formType})`);
};

// Export for global access
window.UniversalValidation = {
    initialize: initializeUniversalValidation,
    initializeForm: window.initializeFormValidation
};
