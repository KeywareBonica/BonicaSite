/**
 * Location Input Component for Bonica Event Management System
 * Provides autocomplete location input with validation
 */

class LocationInput {
    constructor(inputElement, options = {}) {
        try {
            if (!inputElement) {
                console.warn('LocationInput: Input element is null or undefined');
                return;
            }
            
            this.inputElement = inputElement;
            this.options = {
                placeholder: 'Enter your address...',
                validation: true,
                autocomplete: true,
                geocodeOnChange: false,
                onLocationSelect: null,
                onValidationChange: null,
                ...options
            };
            
            this.autocompleteService = null;
            this.placesService = null;
            this.autocomplete = null;
            this.isValid = false;
            this.selectedPlace = null;
            
            this.init();
        } catch (error) {
            console.warn('LocationInput constructor error:', error);
        }
    }

    async init() {
        try {
            if (!this.inputElement) {
                console.warn('LocationInput: Input element is required');
                return;
            }

        // Set up input attributes
        this.setupInputElement();
        
        // Initialize Google Places services if available
        if (typeof google !== 'undefined' && google.maps) {
            await this.initializeGoogleServices();
        }

            // Set up event listeners
            this.setupEventListeners();
        } catch (error) {
            console.warn('LocationInput init error:', error);
        }
    }

    setupInputElement() {
        this.inputElement.setAttribute('placeholder', this.options.placeholder);
        this.inputElement.setAttribute('autocomplete', 'off');
        this.inputElement.setAttribute('spellcheck', 'false');
        this.inputElement.setAttribute('autocorrect', 'off');
        this.inputElement.setAttribute('autocapitalize', 'off');
        
        // Add validation classes
        this.inputElement.classList.add('location-input');
    }

    async initializeGoogleServices() {
        try {
            this.autocompleteService = new google.maps.places.AutocompleteService();
            this.placesService = new google.maps.places.PlacesService(document.createElement('div'));
            
            if (this.options.autocomplete) {
                this.setupAutocomplete();
            }
            console.log('✅ Google Places services initialized successfully');
        } catch (error) {
            console.warn('⚠️ Google Places services not available:', error);
            console.log('📍 Using fallback validation - any address with 3+ characters will be accepted');
        }
    }

    setupAutocomplete() {
        if (!this.autocompleteService) return;

        // Create autocomplete suggestions dropdown
        this.createSuggestionsDropdown();

        // Set up input event listener for suggestions
        if (this.inputElement) {
            this.inputElement.addEventListener('input', (e) => {
                const query = e.target.value.trim();
                if (query.length > 2) {
                    this.getPlaceSuggestions(query);
                } else {
                    this.hideSuggestions();
                }
            });
        }
    }

    createSuggestionsDropdown() {
        this.suggestionsContainer = document.createElement('div');
        this.suggestionsContainer.className = 'location-suggestions';
        this.suggestionsContainer.style.cssText = `
            position: absolute;
            top: 100%;
            left: 0;
            right: 0;
            background: white;
            border: 1px solid #ddd;
            border-top: none;
            border-radius: 0 0 4px 4px;
            max-height: 200px;
            overflow-y: auto;
            z-index: 1000;
            display: none;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        `;

        // Position the input element relatively
        this.inputElement.parentElement.style.position = 'relative';
        this.inputElement.parentElement.appendChild(this.suggestionsContainer);
    }

    async getPlaceSuggestions(query) {
        if (!this.autocompleteService) return;

        try {
            this.autocompleteService.getPlacePredictions({
                input: query,
                types: ['address'],
                componentRestrictions: { country: 'za' } // Restrict to South Africa
            }, (predictions, status) => {
                if (status === google.maps.places.PlacesServiceStatus.OK && predictions) {
                    this.displaySuggestions(predictions);
                } else {
                    this.hideSuggestions();
                }
            });
        } catch (error) {
            console.warn('Error getting place suggestions:', error);
            this.hideSuggestions();
        }
    }

    displaySuggestions(predictions) {
        this.suggestionsContainer.innerHTML = '';
        
        predictions.slice(0, 5).forEach((prediction, index) => {
            const suggestion = document.createElement('div');
            suggestion.className = 'suggestion-item';
            suggestion.style.cssText = `
                padding: 12px 16px;
                cursor: pointer;
                border-bottom: 1px solid #eee;
                transition: background-color 0.2s;
            `;
            suggestion.innerHTML = `
                <div style="font-weight: 500; color: #333;">${prediction.structured_formatting.main_text}</div>
                <div style="font-size: 0.9em; color: #666;">${prediction.structured_formatting.secondary_text}</div>
            `;

            suggestion.addEventListener('mouseenter', () => {
                suggestion.style.backgroundColor = '#f5f5f5';
            });

            suggestion.addEventListener('mouseleave', () => {
                suggestion.style.backgroundColor = 'transparent';
            });

            suggestion.addEventListener('click', () => {
                this.selectPlace(prediction);
            });

            this.suggestionsContainer.appendChild(suggestion);
        });

        this.suggestionsContainer.style.display = 'block';
    }

    hideSuggestions() {
        if (this.suggestionsContainer) {
            this.suggestionsContainer.style.display = 'none';
        }
    }

    selectPlace(prediction) {
        this.inputElement.value = prediction.description;
        this.selectedPlace = prediction;
        this.hideSuggestions();
        
        // Validate the selection
        this.validateInput();
        
        // Call callback if provided
        if (this.options.onLocationSelect) {
            this.options.onLocationSelect(prediction);
        }
    }

    setupEventListeners() {
        // Hide suggestions when clicking outside
        document.addEventListener('click', (e) => {
            try {
                if (this.inputElement && this.suggestionsContainer &&
                    typeof this.inputElement.contains === 'function' &&
                    typeof this.suggestionsContainer.contains === 'function' &&
                    !this.inputElement.contains(e.target) && 
                    !this.suggestionsContainer.contains(e.target)) {
                    this.hideSuggestions();
                }
            } catch (error) {
                console.warn('Location input click handler error:', error);
            }
        });

        // Validate input on blur
        if (this.inputElement) {
            this.inputElement.addEventListener('blur', () => {
                setTimeout(() => this.validateInput(), 100);
            });
        }

        // Validate input on change if option enabled
        if (this.options.geocodeOnChange && this.inputElement) {
            this.inputElement.addEventListener('input', () => {
                clearTimeout(this.validationTimeout);
                this.validationTimeout = setTimeout(() => this.validateInput(), 500);
            });
        }
    }

    async validateInput() {
        const value = this.inputElement.value.trim();
        let isValid = false;
        let validationMessage = '';

        console.log('🔍 Validating address:', value, 'Google Places available:', !!this.autocompleteService);

        if (!value) {
            validationMessage = 'Address is required';
        } else if (!this.isValidAddressFormat(value)) {
            validationMessage = 'Please enter a valid address (at least 3 characters)';
        } else {
            isValid = true;
            validationMessage = '';
        }

        // If Google Places is not available, be more lenient with validation
        if (!this.autocompleteService && value.length > 0) {
            isValid = true;
            validationMessage = '';
            console.log('📍 Google Places not available - accepting any address with content');
        }

        this.isValid = isValid;
        this.updateValidationUI(validationMessage);

        // Call validation callback if provided
        if (this.options.onValidationChange) {
            this.options.onValidationChange(isValid, validationMessage);
        }

        console.log('✅ Validation result:', isValid ? 'VALID' : 'INVALID', validationMessage);
        return isValid;
    }

    isValidAddressFormat(address) {
        // If this is a Google Places selection, it's automatically valid
        if (this.selectedPlace) {
            return true;
        }
        
        // Basic format validation for manual input
        const trimmedAddress = address.trim();
        
        // Must have some content
        if (trimmedAddress.length < 3) return false;
        
        // Should contain letters (at least some text)
        if (!/[a-zA-Z]/.test(trimmedAddress)) return false;
        
        // More flexible validation - just check it's not empty and has some text
        return trimmedAddress.length > 0;
    }

    updateValidationUI(message) {
        // Remove existing validation classes
        this.inputElement.classList.remove('is-valid', 'is-invalid');
        
        // Remove existing validation message
        const existingMessage = this.inputElement.parentElement.querySelector('.validation-message');
        if (existingMessage) {
            existingMessage.remove();
        }

        if (message) {
            this.inputElement.classList.add('is-invalid');
            
            const messageElement = document.createElement('div');
            messageElement.className = 'validation-message text-danger';
            messageElement.style.cssText = 'font-size: 0.875rem; margin-top: 0.25rem;';
            messageElement.textContent = message;
            
            this.inputElement.parentElement.appendChild(messageElement);
        } else if (this.inputElement.value.trim()) {
            this.inputElement.classList.add('is-valid');
        }
    }

    /**
     * Get the current value of the input
     * @returns {string} - The input value
     */
    getValue() {
        return this.inputElement.value.trim();
    }

    /**
     * Set the value of the input
     * @param {string} value - The value to set
     */
    setValue(value) {
        this.inputElement.value = value;
        this.validateInput();
    }

    /**
     * Clear the input
     */
    clear() {
        this.inputElement.value = '';
        this.selectedPlace = null;
        this.isValid = false;
        this.hideSuggestions();
        this.updateValidationUI('');
    }

    /**
     * Get validation status
     * @returns {boolean} - True if input is valid
     */
    isValidInput() {
        return this.isValid;
    }

    /**
     * Get selected place object (if using Google Places)
     * @returns {Object|null} - The selected place object
     */
    getSelectedPlace() {
        return this.selectedPlace;
    }
}

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = LocationInput;
}

// Auto-initialize location inputs with data-location-input attribute
document.addEventListener('DOMContentLoaded', () => {
    const locationInputs = document.querySelectorAll('[data-location-input]');
    locationInputs.forEach(input => {
        const options = {
            placeholder: input.getAttribute('data-placeholder') || 'Enter your address...',
            validation: input.getAttribute('data-validation') !== 'false',
            autocomplete: input.getAttribute('data-autocomplete') !== 'false',
            geocodeOnChange: input.getAttribute('data-geocode-on-change') === 'true'
        };
        
        new LocationInput(input, options);
    });
});
