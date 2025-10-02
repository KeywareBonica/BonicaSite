/**
 * Location Service for Bonica Event Management System
 * Handles geocoding, distance calculations, and location-based matching
 */

class LocationService {
    constructor() {
        this.googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY'; // Replace with actual API key
        this.geocoder = null;
        this.distanceMatrixService = null;
        this.map = null;
        this.markers = [];
        this.directionsService = null;
        this.directionsRenderer = null;
    }

    /**
     * Initialize Google Maps services
     */
    async initialize() {
        if (typeof google === 'undefined') {
            await this.loadGoogleMapsAPI();
        }
        
        this.geocoder = new google.maps.Geocoder();
        this.distanceMatrixService = new google.maps.DistanceMatrixService();
        this.directionsService = new google.maps.DirectionsService();
        this.directionsRenderer = new google.maps.DirectionsRenderer();
    }

    /**
     * Load Google Maps API dynamically
     */
    loadGoogleMapsAPI() {
        return new Promise((resolve, reject) => {
            if (document.querySelector('script[src*="maps.googleapis.com"]')) {
                resolve();
                return;
            }

            const script = document.createElement('script');
            script.src = `https://maps.googleapis.com/maps/api/js?key=${this.googleMapsApiKey}&libraries=places`;
            script.async = true;
            script.defer = true;
            script.onload = resolve;
            script.onerror = reject;
            document.head.appendChild(script);
        });
    }

    /**
     * Geocode an address to get coordinates
     * @param {string} address - The address to geocode
     * @returns {Promise<Object>} - Object with lat, lng, and formatted address
     */
    async geocodeAddress(address) {
        if (!this.geocoder) {
            throw new Error('Geocoder not initialized. Call initialize() first.');
        }

        return new Promise((resolve, reject) => {
            this.geocoder.geocode({ address: address }, (results, status) => {
                if (status === 'OK' && results[0]) {
                    const location = results[0].geometry.location;
                    resolve({
                        lat: location.lat(),
                        lng: location.lng(),
                        address: results[0].formatted_address,
                        placeId: results[0].place_id
                    });
                } else {
                    reject(new Error(`Geocoding failed: ${status}`));
                }
            });
        });
    }

    /**
     * Calculate distance between two addresses
     * @param {string} origin - Origin address
     * @param {string} destination - Destination address
     * @returns {Promise<Object>} - Distance and duration information
     */
    async calculateDistance(origin, destination) {
        if (!this.distanceMatrixService) {
            throw new Error('Distance Matrix Service not initialized. Call initialize() first.');
        }

        return new Promise((resolve, reject) => {
            this.distanceMatrixService.getDistanceMatrix({
                origins: [origin],
                destinations: [destination],
                travelMode: google.maps.TravelMode.DRIVING,
                unitSystem: google.maps.UnitSystem.METRIC,
                avoidHighways: false,
                avoidTolls: false
            }, (response, status) => {
                if (status === 'OK') {
                    const result = response.rows[0].elements[0];
                    if (result.status === 'OK') {
                        resolve({
                            distance: result.distance.text,
                            distanceValue: result.distance.value, // in meters
                            duration: result.duration.text,
                            durationValue: result.duration.value // in seconds
                        });
                    } else {
                        reject(new Error(`Distance calculation failed: ${result.status}`));
                    }
                } else {
                    reject(new Error(`Distance Matrix API failed: ${status}`));
                }
            });
        });
    }

    /**
     * Find closest service providers to a client location
     * @param {string} clientLocation - Client's address
     * @param {Array} serviceProviders - Array of service provider objects
     * @param {number} maxDistance - Maximum distance in kilometers (optional)
     * @returns {Promise<Array>} - Sorted array of closest providers with distance info
     */
    async findClosestProviders(clientLocation, serviceProviders, maxDistance = 50) {
        try {
            const clientCoords = await this.geocodeAddress(clientLocation);
            const providerDistances = [];

            for (const provider of serviceProviders) {
                try {
                    const distance = await this.calculateDistance(clientLocation, provider.location);
                    if (distance.distanceValue <= maxDistance * 1000) { // Convert km to meters
                        providerDistances.push({
                            ...provider,
                            distance: distance.distance,
                            distanceValue: distance.distanceValue,
                            duration: distance.duration,
                            durationValue: distance.durationValue
                        });
                    }
                } catch (error) {
                    console.warn(`Could not calculate distance for provider ${provider.name}:`, error);
                }
            }

            // Sort by distance (closest first)
            return providerDistances.sort((a, b) => a.distanceValue - b.distanceValue);
        } catch (error) {
            throw new Error(`Error finding closest providers: ${error.message}`);
        }
    }

    /**
     * Initialize and display map with markers
     * @param {string} mapElementId - ID of the div element to contain the map
     * @param {Object} centerLocation - Object with lat, lng for map center
     * @param {Array} locations - Array of locations to mark on the map
     * @param {Object} options - Additional map options
     */
    async initializeMap(mapElementId, centerLocation, locations = [], options = {}) {
        const mapElement = document.getElementById(mapElementId);
        if (!mapElement) {
            throw new Error(`Map element with ID '${mapElementId}' not found.`);
        }

        const defaultOptions = {
            zoom: 12,
            center: centerLocation,
            mapTypeId: google.maps.MapTypeId.ROADMAP,
            styles: [
                {
                    featureType: 'poi',
                    elementType: 'labels',
                    stylers: [{ visibility: 'off' }]
                }
            ]
        };

        this.map = new google.maps.Map(mapElement, { ...defaultOptions, ...options });
        
        // Clear existing markers
        this.markers.forEach(marker => marker.setMap(null));
        this.markers = [];

        // Add markers for each location
        locations.forEach((location, index) => {
            const marker = new google.maps.Marker({
                position: { lat: location.lat, lng: location.lng },
                map: this.map,
                title: location.title || `Location ${index + 1}`,
                icon: location.icon || null
            });

            // Add info window if description provided
            if (location.description) {
                const infoWindow = new google.maps.InfoWindow({
                    content: `
                        <div style="padding: 10px;">
                            <h4>${location.title || 'Location'}</h4>
                            <p>${location.description}</p>
                            ${location.distance ? `<p><strong>Distance:</strong> ${location.distance}</p>` : ''}
                            ${location.duration ? `<p><strong>Travel Time:</strong> ${location.duration}</p>` : ''}
                        </div>
                    `
                });

                marker.addListener('click', () => {
                    infoWindow.open(this.map, marker);
                });
            }

            this.markers.push(marker);
        });

        return this.map;
    }

    /**
     * Display route between two locations
     * @param {Object} origin - Origin coordinates {lat, lng}
     * @param {Object} destination - Destination coordinates {lat, lng}
     * @param {Object} options - Route options
     */
    async displayRoute(origin, destination, options = {}) {
        if (!this.map || !this.directionsService || !this.directionsRenderer) {
            throw new Error('Map or directions services not initialized.');
        }

        const request = {
            origin: origin,
            destination: destination,
            travelMode: google.maps.TravelMode.DRIVING,
            ...options
        };

        return new Promise((resolve, reject) => {
            this.directionsService.route(request, (result, status) => {
                if (status === 'OK') {
                    this.directionsRenderer.setDirections(result);
                    this.directionsRenderer.setMap(this.map);
                    resolve(result);
                } else {
                    reject(new Error(`Directions request failed: ${status}`));
                }
            });
        });
    }

    /**
     * Get current user location using browser geolocation
     * @returns {Promise<Object>} - Object with lat, lng coordinates
     */
    getCurrentLocation() {
        return new Promise((resolve, reject) => {
            if (!navigator.geolocation) {
                reject(new Error('Geolocation is not supported by this browser.'));
                return;
            }

            navigator.geolocation.getCurrentPosition(
                (position) => {
                    resolve({
                        lat: position.coords.latitude,
                        lng: position.coords.longitude
                    });
                },
                (error) => {
                    reject(new Error(`Geolocation error: ${error.message}`));
                },
                {
                    enableHighAccuracy: true,
                    timeout: 10000,
                    maximumAge: 300000 // 5 minutes
                }
            );
        });
    }

    /**
     * Validate address format
     * @param {string} address - Address to validate
     * @returns {boolean} - True if address appears valid
     */
    isValidAddress(address) {
        if (!address || typeof address !== 'string') {
            return false;
        }

        const trimmedAddress = address.trim();
        
        // Basic validation - should have at least a street and city
        const parts = trimmedAddress.split(',').map(part => part.trim());
        
        if (parts.length < 2) {
            return false;
        }

        // Should contain some numbers (house number) and letters
        return /\d/.test(trimmedAddress) && /[a-zA-Z]/.test(trimmedAddress);
    }

    /**
     * Format address for display
     * @param {string} address - Raw address string
     * @returns {string} - Formatted address
     */
    formatAddress(address) {
        if (!address) return '';
        
        return address
            .split(',')
            .map(part => part.trim())
            .filter(part => part.length > 0)
            .join(', ');
    }
}

// Create global instance
window.locationService = new LocationService();

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = LocationService;
}
