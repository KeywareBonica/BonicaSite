/**
 * Simple Location Autocomplete for Bonica Event Management System
 * Works without external APIs - uses predefined South African locations
 */

class SimpleLocationAutocomplete {
    constructor() {
        this.locations = [
            // Johannesburg areas
            'Soweto', 'Sandton', 'Randburg', 'Roodepoort', 'Kempton Park', 'Edenvale', 'Germiston',
            'Boksburg', 'Benoni', 'Alberton', 'Vereeniging', 'Vanderbijlpark', 'Midrand', 'Centurion',
            'Fourways', 'Morningside', 'Rivonia', 'Melville', 'Parktown', 'Rosebank', 'Hyde Park',
            'Woodmead', 'Sunninghill', 'Waterfall', 'Dainfern', 'Bryanston', 'Linden', 'Greenside',
            
            // Pretoria areas
            'Pretoria Central', 'Hatfield', 'Arcadia', 'Brooklyn', 'Menlyn', 'Waterkloof', 'Garsfontein',
            'Lynnwood', 'Faerie Glen', 'Wapadrand', 'Erasmusrand', 'Silverton', 'Mamelodi', 'Atteridgeville',
            'Soshanguve', 'Akasia', 'Wonderboom', 'Cullinan', 'Bronkhorstspruit',
            
            // Cape Town areas
            'Cape Town CBD', 'Sea Point', 'Green Point', 'Claremont', 'Rondebosch', 'Newlands', 'Observatory',
            'Woodstock', 'Gardens', 'Vredehoek', 'Oranjezicht', 'Table View', 'Blouberg', 'Milnerton',
            'Goodwood', 'Parow', 'Bellville', 'Kuils River', 'Stellenbosch', 'Paarl', 'Somerset West',
            
            // Durban areas
            'Durban CBD', 'Umhlanga', 'Ballito', 'Westville', 'Pinetown', 'Hillcrest', 'Kloof', 'Gillitts',
            'Chatsworth', 'Phoenix', 'Newlands East', 'Glenwood', 'Morningside', 'Berea', 'Musgrave',
            
            // Other major cities
            'Bloemfontein', 'Port Elizabeth', 'East London', 'Nelspruit', 'Polokwane', 'Kimberley', 'Pietermaritzburg',
            'Rustenburg', 'Welkom', 'Potchefstroom', 'Klerksdorp', 'Mafikeng', 'Mmabatho', 'Vryburg',
            
            // Townships and suburbs
            'Alexandra', 'Tembisa', 'Katlehong', 'Thokoza', 'Daveyton', 'KwaThema', 'Springs', 'Nigel',
            'Heidelberg', 'Delmas', 'Bronkhorstspruit', 'Cullinan', 'Hammanskraal', 'Soshanguve', 'Winterveldt'
        ];
        
        this.filteredLocations = [];
        this.selectedIndex = -1;
    }

    init(inputElement) {
        this.inputElement = inputElement;
        this.createDropdown();
        this.attachEventListeners();
    }

    createDropdown() {
        this.dropdown = document.createElement('div');
        this.dropdown.className = 'location-dropdown';
        this.dropdown.style.cssText = `
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
        this.inputElement.parentElement.appendChild(this.dropdown);
    }

    attachEventListeners() {
        this.inputElement.addEventListener('input', (e) => {
            this.handleInput(e.target.value);
        });

        this.inputElement.addEventListener('keydown', (e) => {
            this.handleKeyDown(e);
        });

        this.inputElement.addEventListener('blur', () => {
            // Delay hiding to allow click events
            setTimeout(() => this.hideDropdown(), 150);
        });

        this.inputElement.addEventListener('focus', () => {
            if (this.inputElement.value.length > 1) {
                this.handleInput(this.inputElement.value);
            }
        });
    }

    handleInput(value) {
        const query = value.toLowerCase().trim();
        
        if (query.length < 2) {
            this.hideDropdown();
            return;
        }

        this.filteredLocations = this.locations.filter(location =>
            location.toLowerCase().includes(query)
        );

        this.selectedIndex = -1;
        this.displaySuggestions();
    }

    displaySuggestions() {
        if (this.filteredLocations.length === 0) {
            this.hideDropdown();
            return;
        }

        this.dropdown.innerHTML = '';
        
        this.filteredLocations.slice(0, 8).forEach((location, index) => {
            const item = document.createElement('div');
            item.className = 'location-item';
            item.style.cssText = `
                padding: 12px 16px;
                cursor: pointer;
                border-bottom: 1px solid #eee;
                transition: background-color 0.2s;
                font-size: 0.9rem;
            `;
            
            // Highlight matching text
            const query = this.inputElement.value.toLowerCase();
            const locationLower = location.toLowerCase();
            const matchIndex = locationLower.indexOf(query);
            
            if (matchIndex !== -1) {
                const beforeMatch = location.substring(0, matchIndex);
                const match = location.substring(matchIndex, matchIndex + query.length);
                const afterMatch = location.substring(matchIndex + query.length);
                
                item.innerHTML = `${beforeMatch}<strong>${match}</strong>${afterMatch}`;
            } else {
                item.textContent = location;
            }

            item.addEventListener('mouseenter', () => {
                this.selectedIndex = index;
                this.updateSelection();
            });

            item.addEventListener('click', () => {
                this.selectLocation(location);
            });

            this.dropdown.appendChild(item);
        });

        this.updateSelection();
        this.dropdown.style.display = 'block';
    }

    handleKeyDown(e) {
        if (!this.dropdown.style.display || this.dropdown.style.display === 'none') {
            return;
        }

        switch (e.key) {
            case 'ArrowDown':
                e.preventDefault();
                this.selectedIndex = Math.min(this.selectedIndex + 1, this.filteredLocations.length - 1);
                this.updateSelection();
                break;
            case 'ArrowUp':
                e.preventDefault();
                this.selectedIndex = Math.max(this.selectedIndex - 1, -1);
                this.updateSelection();
                break;
            case 'Enter':
                e.preventDefault();
                if (this.selectedIndex >= 0) {
                    this.selectLocation(this.filteredLocations[this.selectedIndex]);
                }
                break;
            case 'Escape':
                this.hideDropdown();
                break;
        }
    }

    updateSelection() {
        const items = this.dropdown.querySelectorAll('.location-item');
        items.forEach((item, index) => {
            if (index === this.selectedIndex) {
                item.style.backgroundColor = '#f5f5f5';
                item.style.color = '#333';
            } else {
                item.style.backgroundColor = 'transparent';
                item.style.color = '#333';
            }
        });
    }

    selectLocation(location) {
        this.inputElement.value = location;
        this.hideDropdown();
        this.inputElement.classList.remove('is-invalid');
        this.inputElement.classList.add('is-valid');
    }

    hideDropdown() {
        this.dropdown.style.display = 'none';
        this.selectedIndex = -1;
    }
}

// Auto-initialize location inputs
document.addEventListener('DOMContentLoaded', () => {
    const locationInputs = document.querySelectorAll('[data-location-input]');
    locationInputs.forEach(input => {
        const autocomplete = new SimpleLocationAutocomplete();
        autocomplete.init(input);
    });
});

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = SimpleLocationAutocomplete;
}
