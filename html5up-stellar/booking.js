let currentStep = 1; // start at new Step 1
const totalSteps = 6; // steps 1-6 now include welcome step
let selectedQuotations = {};
let countdownInterval;

// Show current step and update progress bar
function showStep(step) {
  document.querySelectorAll('.step').forEach((s) => s.classList.remove('active'));
  document.getElementById(`step-${step}`).classList.add('active');

  document.getElementById('prevBtn').style.display = step === 1 ? 'none' : 'inline-block';
  document.getElementById('nextBtn').style.display = step >= totalSteps - 1 ? 'none' : 'inline-block';

  const progress = document.getElementById('progress');
  const progressPercent = ((step - 1) / (totalSteps - 1)) * 100;
  progress.style.width = progressPercent + '%';
}

// Step 1 buttons
function startBooking() {
  currentStep++;
  showStep(currentStep);
}

function cancelBooking() {
  alert("You chose not to make a booking. Redirecting to home...");
  window.location.href = "index.html";
}

// Navigation buttons
function nextStep() {
  if (!validateStep(currentStep)) return;

  currentStep++;
  if (currentStep === 4) startQuotationCountdown();
  if (currentStep === 5) generateSummary();

  showStep(currentStep);
}

function prevStep() {
  currentStep--;
  showStep(currentStep);
}

// Validation
function validateStep(step) {
  let valid = true;

  if (step === 2) {
    if (!document.getElementById('event-type').value) { document.getElementById('event-type-error').style.display = 'block'; valid = false; }
    else { document.getElementById('event-type-error').style.display = 'none'; }

    if (!document.getElementById('date').value) { document.getElementById('date-error').style.display = 'block'; valid = false; }
    else { document.getElementById('date-error').style.display = 'none'; }

    if (!document.getElementById('start-time').value) { document.getElementById('start-time-error').style.display = 'block'; valid = false; }
    else { document.getElementById('start-time-error').style.display = 'none'; }

    if (!document.getElementById('end-time').value) { document.getElementById('end-time-error').style.display = 'block'; valid = false; }
    else { document.getElementById('end-time-error').style.display = 'none'; }

    if (!document.getElementById('location').value) { document.getElementById('location-error').style.display = 'block'; valid = false; }
    else { document.getElementById('location-error').style.display = 'none'; }

    const minPrice = parseInt(document.getElementById('min-price').value) || 0;
    const maxPrice = parseInt(document.getElementById('max-price').value) || 0;
    if (minPrice < 0 || maxPrice < 0 || minPrice > maxPrice) { document.getElementById('price-error').style.display = 'block'; valid = false; }
    else { document.getElementById('price-error').style.display = 'none'; }
  }

  if (step === 3) {
    const services = document.querySelectorAll('input[name="services"]:checked');
    if (services.length === 0) { document.getElementById('services-error').style.display = 'block'; valid = false; }
    else { document.getElementById('services-error').style.display = 'none'; }
  }

  return valid;
}

// Quotation Countdown
function startQuotationCountdown() {
  const timerEl = document.getElementById('countdown-timer');
  const waitMessage = document.getElementById('quotation-wait-message');
  const container = document.getElementById('quotations-container');

  let timeLeft = 60;
  timerEl.textContent = formatTime(timeLeft);
  waitMessage.style.display = 'block';
  container.innerHTML = '';

  countdownInterval = setInterval(() => {
    timeLeft--;
    timerEl.textContent = formatTime(timeLeft);

    if (timeLeft <= 0) {
      clearInterval(countdownInterval);
      waitMessage.style.display = 'none';
      alert('Quotations are ready!');
      generateQuotations();
    }
  }, 1000);
}

function formatTime(seconds) {
  const mins = String(Math.floor(seconds / 60)).padStart(2, '0');
  const secs = String(seconds % 60).padStart(2, '0');
  return `${mins}:${secs}`;
}

// Generate quotations (filtered by budget)
function generateQuotations() {
  const container = document.getElementById('quotations-container');
  selectedQuotations = {};

  const services = Array.from(document.querySelectorAll('input[name="services"]:checked')).map(s => s.value);
  const minPrice = parseInt(document.getElementById('min-price').value) || 0;
  const maxPrice = parseInt(document.getElementById('max-price').value) || 100000;

  services.forEach(service => {
    const section = document.createElement('div');
    section.className = 'quotation-section';
    section.innerHTML = `<h3>${service} Quotations</h3>`;

    for (let i = 1; i <= 3; i++) {
      // Simulate prices within budget
      let price = Math.floor(Math.random() * (maxPrice - minPrice + 1)) + minPrice;
      const option = document.createElement('div');
      option.className = 'quotation-option';
      option.innerHTML = `<strong>${service} Provider ${i}</strong>
                          <p>Price: R${price.toLocaleString()}</p>
                          <button onclick="viewFullQuotation('${service} Provider ${i}', 'Package details for ${service} option ${i}'); event.stopPropagation()">View Full Quotation</button>`;

      option.onclick = () => {
        section.querySelectorAll('.quotation-option').forEach(opt => opt.classList.remove('selected'));
        option.classList.add('selected');
        selectedQuotations[service] = `Provider ${i}`;
      };

      section.appendChild(option);
    }

    container.appendChild(section);
  });
}

// Quotation modal
function viewFullQuotation(provider, details) {
  document.getElementById('modal-body').innerHTML = `<h3>${provider}</h3><p>${details}</p>`;
  document.getElementById('quotation-modal').style.display = 'block';
}

function closeModal() {
  document.getElementById('quotation-modal').style.display = 'none';
}

// Summary
function generateSummary() {
  const container = document.getElementById('summary-container');
  container.innerHTML = '';
  const eventType = document.getElementById('event-type').value;
  const location = document.getElementById('location').value;

  let total = 0;
  const services = Object.keys(selectedQuotations);

  let html = `<p><strong>Event Type:</strong> ${eventType}</p>`;
  html += `<p><strong>Location:</strong> ${location}</p>`;
  html += `<p><strong>Selected Services & Providers:</strong></p><ul>`;

  services.forEach((service, index) => {
    const price = (index + 1) * 5000;
    total += price;
    html += `<li>${service}: ${selectedQuotations[service]} - R${price.toLocaleString()}</li>`;
  });
  html += `</ul>`;
  html += `<p><strong>Total Price:</strong> R${total.toLocaleString()}</p>`;

  container.innerHTML = html;
}

// Confirm Booking
function confirmBooking() {
  const email = prompt('Enter your email for confirmation:');
  if (email) {
    window.location.href = `mailto:${email}?subject=Event Booking Confirmation&body=Your booking has been confirmed!`;
    currentStep++;
    showStep(currentStep);
  }
}

// Initialize
showStep(currentStep);
