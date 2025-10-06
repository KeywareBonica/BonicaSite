/**
 * Simple Location Autocomplete for Bonica Event Management System
 * Works without external APIs - uses predefined South African locations
 */

class SimpleLocationAutocomplete {
    constructor() {
        this.locations = [
            // Major Cities
            'Johannesburg', 'Cape Town', 'Durban', 'Pretoria', 'Port Elizabeth', 'Bloemfontein', 'East London',
            'Nelspruit', 'Polokwane', 'Kimberley', 'Pietermaritzburg', 'Rustenburg', 'Welkom', 'Potchefstroom',
            'Klerksdorp', 'Mafikeng', 'Mmabatho', 'Vryburg', 'George', 'Mossel Bay', 'Knysna', 'Oudtshoorn',
            'Worcester', 'Paarl', 'Stellenbosch', 'Somerset West', 'Hermanus', 'Jeffreys Bay', 'Port Alfred',
            'Grahamstown', 'Queenstown', 'Uitenhage', 'Despatch', 'Jeffreys Bay', 'Plettenberg Bay',
            
            // Johannesburg Areas
            'Soweto', 'Sandton', 'Randburg', 'Roodepoort', 'Kempton Park', 'Edenvale', 'Germiston',
            'Boksburg', 'Benoni', 'Alberton', 'Vereeniging', 'Vanderbijlpark', 'Midrand', 'Centurion',
            'Fourways', 'Morningside', 'Rivonia', 'Melville', 'Parktown', 'Rosebank', 'Hyde Park',
            'Woodmead', 'Sunninghill', 'Waterfall', 'Dainfern', 'Bryanston', 'Linden', 'Greenside',
            'Alexandra', 'Tembisa', 'Katlehong', 'Thokoza', 'Daveyton', 'KwaThema', 'Springs', 'Nigel',
            'Heidelberg', 'Delmas', 'Bronkhorstspruit', 'Cullinan', 'Hammanskraal', 'Soshanguve', 'Winterveldt',
            
            // Pretoria Areas
            'Pretoria Central', 'Hatfield', 'Arcadia', 'Brooklyn', 'Menlyn', 'Waterkloof', 'Garsfontein',
            'Lynnwood', 'Faerie Glen', 'Wapadrand', 'Erasmusrand', 'Silverton', 'Mamelodi', 'Atteridgeville',
            'Akasia', 'Wonderboom', 'Cullinan', 'Bronkhorstspruit', 'Hammanskraal', 'Soshanguve',
            
            // Cape Town Areas
            'Cape Town CBD', 'Sea Point', 'Green Point', 'Claremont', 'Rondebosch', 'Newlands', 'Observatory',
            'Woodstock', 'Gardens', 'Vredehoek', 'Oranjezicht', 'Table View', 'Blouberg', 'Milnerton',
            'Goodwood', 'Parow', 'Bellville', 'Kuils River', 'Stellenbosch', 'Paarl', 'Somerset West',
            'Hout Bay', 'Constantia', 'Wynberg', 'Plumstead', 'Diep River', 'Tokai', 'Bergvliet',
            'Fish Hoek', 'Simon\'s Town', 'Kalk Bay', 'Muizenberg', 'Strand', 'Gordon\'s Bay',
            
            // Durban Areas
            'Durban CBD', 'Umhlanga', 'Ballito', 'Westville', 'Pinetown', 'Hillcrest', 'Kloof', 'Gillitts',
            'Chatsworth', 'Phoenix', 'Newlands East', 'Glenwood', 'Morningside', 'Berea', 'Musgrave',
            'Amanzimtoti', 'Umlazi', 'KwaMashu', 'Inanda', 'Ntuzuma', 'KwaDabeka', 'Clermont',
            'New Germany', 'Pinetown', 'Hillcrest', 'Kloof', 'Gillitts', 'Chatsworth', 'Phoenix',
            
            // Other Major Towns
            'Witbank', 'Secunda', 'Bethal', 'Standerton', 'Volksrust', 'Newcastle', 'Dundee', 'Ladysmith',
            'Richards Bay', 'Empangeni', 'Eshowe', 'Vryheid', 'Piet Retief', 'Amersfoort', 'Volksrust',
            'Bethlehem', 'Harrismith', 'Clarens', 'Ficksburg', 'Ladybrand', 'Zastron', 'Wepener',
            'Thaba Nchu', 'Botshabelo', 'Trompsburg', 'Jagersfontein', 'Fauresmith', 'Koffiefontein',
            
            // Western Cape Towns
            'Caledon', 'Hermanus', 'Gansbaai', 'Bredasdorp', 'Swellendam', 'Riversdale', 'Ladismith',
            'Langebaan', 'Saldanha', 'Vredenburg', 'Piketberg', 'Citrusdal', 'Clanwilliam', 'Lambert\'s Bay',
            'Malmesbury', 'Wellington', 'Tulbagh', 'Ceres', 'Robertson', 'Montagu', 'Barrydale',
            'Ladismith', 'Calitzdorp', 'Oudtshoorn', 'Prince Albert', 'Beaufort West', 'Laingsburg',
            
            // Eastern Cape Towns
            'Uitenhage', 'Despatch', 'Jeffreys Bay', 'Plettenberg Bay', 'Knysna', 'Sedgefield', 'Wilderness',
            'George', 'Mossel Bay', 'Oudtshoorn', 'Calitzdorp', 'Ladismith', 'Barrydale', 'Montagu',
            'Robertson', 'Worcester', 'Tulbagh', 'Ceres', 'Wellington', 'Paarl', 'Stellenbosch',
            'Somerset West', 'Hermanus', 'Gansbaai', 'Bredasdorp', 'Swellendam', 'Riversdale',
            
            // Northern Cape Towns
            'Upington', 'Kuruman', 'Kathu', 'Postmasburg', 'Prieska', 'Griekwastad', 'Carnarvon',
            'Williston', 'Calvinia', 'Nieuwoudtville', 'Loeriesfontein', 'Fraserburg', 'Sutherland',
            'Beaufort West', 'Laingsburg', 'Prince Albert', 'Oudtshoorn', 'Calitzdorp', 'Ladismith',
            
            // Free State Towns
            'Welkom', 'Virginia', 'Allanridge', 'Hennenman', 'Odendaalsrus', 'Bothaville', 'Kroonstad',
            'Parys', 'Vredefort', 'Viljoenskroon', 'Sasolburg', 'Vanderbijlpark', 'Vereeniging',
            'Heidelberg', 'Meyerton', 'Edenville', 'Frankfort', 'Villiers', 'Reitz', 'Petrus Steyn',
            'Lindley', 'Senekal', 'Ficksburg', 'Clocolan', 'Marquard', 'Excelsior', 'Hobhouse',
            
            // Limpopo Towns
            'Polokwane', 'Tzaneen', 'Lephalale', 'Mokopane', 'Modimolle', 'Bela-Bela', 'Thabazimbi',
            'Makhado', 'Musina', 'Thohoyandou', 'Giyani', 'Tzaneen', 'Hoedspruit', 'Phalaborwa',
            'Tzaneen', 'Lephalale', 'Mokopane', 'Modimolle', 'Bela-Bela', 'Thabazimbi', 'Makhado',
            
            // Mpumalanga Towns
            'Nelspruit', 'Witbank', 'Secunda', 'Bethal', 'Standerton', 'Volksrust', 'Ermelo',
            'Piet Retief', 'Amersfoort', 'Volksrust', 'Ermelo', 'Piet Retief', 'Amersfoort',
            'Volksrust', 'Ermelo', 'Piet Retief', 'Amersfoort', 'Volksrust', 'Ermelo', 'Piet Retief',
            
            // North West Towns
            'Rustenburg', 'Klerksdorp', 'Potchefstroom', 'Mafikeng', 'Mmabatho', 'Vryburg', 'Lichtenburg',
            'Zeerust', 'Ganyesa', 'Tosca', 'Bray', 'Huhudi', 'Setlagole', 'Madibogo', 'Bodibe',
            'Tshidilamolomo', 'Motswedi', 'Bodibe', 'Madibogo', 'Setlagole', 'Huhudi', 'Bray',
            
            // KwaZulu-Natal Towns
            'Durban', 'Pietermaritzburg', 'Newcastle', 'Dundee', 'Ladysmith', 'Richards Bay', 'Empangeni',
            'Eshowe', 'Vryheid', 'Piet Retief', 'Amersfoort', 'Volksrust', 'Ermelo', 'Piet Retief',
            'Amersfoort', 'Volksrust', 'Ermelo', 'Piet Retief', 'Amersfoort', 'Volksrust', 'Ermelo'
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
            setTimeout(() => {
                this.hideDropdown();
                // Validate on blur
                this.validateLocation(this.inputElement);
            }, 150);
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
        
        // Trigger validation event
        this.inputElement.dispatchEvent(new Event('change', { bubbles: true }));
    }
    
    validateLocation(input) {
        const value = input.value.trim();
        
        // Check for exact match first
        const exactMatch = this.locations.find(location => 
            location.toLowerCase() === value.toLowerCase()
        );
        
        if (exactMatch) {
            input.classList.remove('is-invalid');
            input.classList.add('is-valid');
            return true;
        }
        
        // Check for partial match (more flexible)
        const partialMatch = this.locations.find(location => 
            location.toLowerCase().includes(value.toLowerCase()) ||
            value.toLowerCase().includes(location.toLowerCase())
        );
        
        if (partialMatch && value.length >= 3) {
            input.classList.remove('is-invalid');
            input.classList.add('is-valid');
            return true;
        }
        
        // Show error if no valid match
        input.classList.remove('is-valid');
        input.classList.add('is-invalid');
        return false;
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
