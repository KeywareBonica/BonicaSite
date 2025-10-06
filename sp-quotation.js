import { createClient } from "@supabase/supabase-js";

// 🔑 Replace with your Supabase project credentials
const supabaseUrl = "https://spudtrptbyvwyhvistdf.supabase.co";
const supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNwdWR0cnB0Ynl2d3lodmlzdGRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU2OTk4NjgsImV4cCI6MjA3MTI3NTg2OH0.GBo-RtgbRZCmhSAZi0c5oXynMiJNeyrs0nLsk3CaV8A";
const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Global variables for enhanced functionality
let currentServiceProvider = null;
let providerExperience = 'new'; // 'new' or 'experienced'
let providerStats = null;

const form = document.getElementById("quotationForm");
const confirmBtn = document.getElementById("confirmBtn");
const message = document.getElementById("message");
const jobCartSelect = document.getElementById("job_cart_select");

let lastQuotationId = null;

// Initialize service provider data and determine experience level
async function initializeServiceProvider() {
  try {
    // Get current service provider ID
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      console.log("No user logged in, using demo mode");
      return "demo-provider-id";
    }

    const { data: provider, error: providerError } = await supabase
      .from("service_provider")
      .select(`
        service_provider_id,
        service_provider_name,
        service_provider_surname,
        service_provider_rating,
        created_at
      `)
      .eq("service_provider_email", user.email)
      .single();

    if (providerError || !provider) {
      console.log("Not a valid service provider, using demo mode");
      return "demo-provider-id";
    }

    currentServiceProvider = provider;
    
    // Determine if provider is new or experienced based on:
    // 1. Account age (less than 30 days = new)
    // 2. Number of quotations submitted
    // 3. Rating (if any)
    
    const accountAge = new Date() - new Date(provider.created_at);
    const daysSinceRegistration = Math.floor(accountAge / (1000 * 60 * 60 * 24));
    
    // Get provider statistics
    const { data: quotations, error: quoteError } = await supabase
      .from("quotation")
      .select("quotation_id")
      .eq("service_provider_id", provider.service_provider_id);
    
    if (quoteError) {
      console.log("Error getting quotations, using demo stats");
      providerStats = {
        totalQuotations: 0,
        accountAge: daysSinceRegistration,
        rating: provider.service_provider_rating || 0
      };
    } else {
      providerStats = {
        totalQuotations: quotations?.length || 0,
        accountAge: daysSinceRegistration,
        rating: provider.service_provider_rating || 0
      };
    }
    
    // Determine experience level
    if (daysSinceRegistration < 30 && providerStats.totalQuotations < 5) {
      providerExperience = 'new';
    } else {
      providerExperience = 'experienced';
    }
    
    console.log(`Provider Experience: ${providerExperience}`, providerStats);
    
    // Update UI based on experience level
    updateUIForExperience();
    
    return provider.service_provider_id;
    
  } catch (error) {
    console.error("Error initializing service provider, using demo mode:", error);
    return "demo-provider-id";
  }
}

// Update UI based on provider experience level
function updateUIForExperience() {
  const container = document.querySelector('.quotation-container');
  const title = document.querySelector('h2');
  
  if (providerExperience === 'new') {
    // Add new provider guidance
    title.innerHTML = 'Upload Quotation <span class="new-provider-badge">New Provider</span>';
    
    // Add guidance section for new providers
    const guidanceSection = document.createElement('div');
    guidanceSection.className = 'provider-guidance new-provider';
    guidanceSection.innerHTML = `
      <div class="guidance-header">
        <i class="fas fa-lightbulb"></i>
        <h3>Welcome to Bonica!</h3>
      </div>
      <div class="guidance-content">
        <p>As a new service provider, here are some tips for creating great quotations:</p>
        <ul>
          <li><strong>Be competitive:</strong> Start with competitive pricing to build your reputation</li>
          <li><strong>Detail your services:</strong> Clearly explain what you'll provide</li>
          <li><strong>Include your availability:</strong> Mention your schedule and flexibility</li>
          <li><strong>Upload supporting documents:</strong> Portfolio images, certificates, or references</li>
        </ul>
      </div>
    `;
    
    container.insertBefore(guidanceSection, form);
    
  } else {
    // Add experienced provider features
    title.innerHTML = 'Upload Quotation <span class="experienced-provider-badge">Experienced Provider</span>';
    
    // Add stats section for experienced providers
    const statsSection = document.createElement('div');
    statsSection.className = 'provider-stats experienced-provider';
    statsSection.innerHTML = `
      <div class="stats-header">
        <i class="fas fa-chart-line"></i>
        <h3>Your Performance</h3>
      </div>
      <div class="stats-content">
        <div class="stat-item">
          <span class="stat-number">${providerStats.totalQuotations}</span>
          <span class="stat-label">Quotations Submitted</span>
        </div>
        <div class="stat-item">
          <span class="stat-number">${providerStats.rating}</span>
          <span class="stat-label">Average Rating</span>
        </div>
        <div class="stat-item">
          <span class="stat-number">${providerStats.accountAge}</span>
          <span class="stat-label">Days Active</span>
        </div>
      </div>
    `;
    
    container.insertBefore(statsSection, form);
  }
}

// Load available job carts (with fallback to sample data)
async function loadJobCarts() {
  try {
    // Try to load from database first
    const serviceProviderId = await initializeServiceProvider();

    // Get accepted job carts for this service provider
    const { data: acceptedJobs, error } = await supabase
      .from("job_cart_acceptance")
      .select(`
        job_cart:job_cart_id (
          job_cart_id,
          job_cart_item,
          job_cart_details,
          job_cart_status,
          job_cart_created_date,
          event:event_id (
            event_id,
            event_name,
            event_date,
            event_location,
            event_start_time,
            event_end_time,
            client:client_id (
              client_name,
              client_surname
            )
          )
        )
      `)
      .eq("service_provider_id", serviceProviderId)
      .eq("acceptance_status", "accepted")
      .order("accepted_at", { ascending: false });

    if (error) {
      console.log("Database error, using sample job carts:", error);
      loadSampleJobCarts();
      return;
    }

    // Check if job cart ID is provided in URL
    const urlParams = new URLSearchParams(window.location.search);
    const jobCartIdFromUrl = urlParams.get('job_cart_id');

    if (jobCartIdFromUrl) {
      // Pre-select the job cart from URL if it's accepted
      const selectedJob = acceptedJobs.find(job => job.job_cart.job_cart_id === jobCartIdFromUrl);
      if (selectedJob) {
        const option = document.createElement("option");
        option.value = selectedJob.job_cart.job_cart_id;
        option.textContent = `${selectedJob.job_cart.job_cart_item} - ${selectedJob.job_cart.event?.event_name || 'N/A'}`;
        option.selected = true;
        jobCartSelect.appendChild(option);
        
        // Disable the select since it's pre-selected
        jobCartSelect.disabled = true;
        return;
      }
    }

    // Populate dropdown with all accepted job carts
    if (acceptedJobs && acceptedJobs.length > 0) {
      acceptedJobs.forEach(job => {
        const option = document.createElement("option");
        option.value = job.job_cart.job_cart_id;
        
        // Enhanced display for job cart options
        const eventDate = new Date(job.job_cart.event?.event_date).toLocaleDateString();
        const clientName = job.job_cart.event?.client ? 
          `${job.job_cart.event.client.client_name} ${job.job_cart.event.client.client_surname}` : 'N/A';
        
        option.textContent = `${job.job_cart.job_cart_item} - ${job.job_cart.event?.event_name || 'N/A'} (${eventDate}) - ${clientName}`;
        option.dataset.jobDetails = JSON.stringify({
          eventName: job.job_cart.event?.event_name,
          eventDate: job.job_cart.event?.event_date,
          eventLocation: job.job_cart.event?.event_location,
          clientName: clientName,
          jobDetails: job.job_cart.job_cart_details
        });
        
        jobCartSelect.appendChild(option);
      });
    } else {
      // No accepted jobs from database, use sample data
      console.log("No accepted jobs found, using sample data");
      loadSampleJobCarts();
    }

    // Add job cart selection change handler to show details
    jobCartSelect.addEventListener('change', function() {
      const selectedOption = this.options[this.selectedIndex];
      if (selectedOption.value) {
        const jobDetails = JSON.parse(selectedOption.dataset.jobDetails);
        showJobCartDetails(jobDetails);
      } else {
        hideJobCartDetails();
      }
    });

    // Show first job cart details by default
    if (jobCartSelect.options.length > 1) {
      const firstOption = jobCartSelect.options[1]; // Skip the default "-- Select Job Cart --" option
      if (firstOption) {
        const jobDetails = JSON.parse(firstOption.dataset.jobDetails);
        showJobCartDetails(jobDetails);
      }
    }

  } catch (err) {
    console.error("Error loading job carts, using sample data:", err);
    loadSampleJobCarts();
  }
}

// Load sample job carts for demo purposes
function loadSampleJobCarts() {
  console.log("Loading sample job carts for demo");
  
  // Clear existing options except the first one
  while (jobCartSelect.options.length > 1) {
    jobCartSelect.removeChild(jobCartSelect.lastChild);
  }
  
  // Sample job carts are already in HTML, just add event listener
  jobCartSelect.addEventListener('change', function() {
    const selectedOption = this.options[this.selectedIndex];
    if (selectedOption.value) {
      const jobDetails = JSON.parse(selectedOption.dataset.jobDetails);
      showJobCartDetails(jobDetails);
    } else {
      hideJobCartDetails();
    }
  });
  
  // Show first job cart details by default
  if (jobCartSelect.options.length > 1) {
    const firstOption = jobCartSelect.options[1];
    if (firstOption) {
      const jobDetails = JSON.parse(firstOption.dataset.jobDetails);
      showJobCartDetails(jobDetails);
    }
  }
}

// Show job cart details when selected
function showJobCartDetails(jobDetails) {
  // Remove existing details section if any
  const existingDetails = document.getElementById('job-cart-details');
  if (existingDetails) {
    existingDetails.remove();
  }
  
  // Create job cart details section
  const detailsSection = document.createElement('div');
  detailsSection.id = 'job-cart-details';
  detailsSection.className = 'job-cart-details-section';
  detailsSection.innerHTML = `
    <div class="job-cart-info">
      <h3><i class="fas fa-info-circle"></i> Job Details</h3>
      <div class="job-details-grid">
        <div class="detail-item">
          <label>Event:</label>
          <span>${jobDetails.eventName}</span>
        </div>
        <div class="detail-item">
          <label>Date:</label>
          <span>${new Date(jobDetails.eventDate).toLocaleDateString()}</span>
        </div>
        <div class="detail-item">
          <label>Location:</label>
          <span>${jobDetails.eventLocation}</span>
        </div>
        <div class="detail-item">
          <label>Client:</label>
          <span>${jobDetails.clientName}</span>
        </div>
        <div class="detail-item full-width">
          <label>Requirements:</label>
          <span>${jobDetails.jobDetails}</span>
        </div>
      </div>
    </div>
  `;
  
  // Insert after the job cart select dropdown
  const formGroup = jobCartSelect.closest('.form-group');
  formGroup.parentNode.insertBefore(detailsSection, formGroup.nextSibling);
}

// Hide job cart details
function hideJobCartDetails() {
  const existingDetails = document.getElementById('job-cart-details');
  if (existingDetails) {
    existingDetails.remove();
  }
}

// Show message when no accepted jobs available
function showNoAcceptedJobs() {
  const noJobsSection = document.createElement('div');
  noJobsSection.className = 'no-accepted-jobs';
  noJobsSection.innerHTML = `
    <div class="no-jobs-content">
      <i class="fas fa-inbox fa-3x"></i>
      <h3>No Accepted Job Carts</h3>
      <p>You haven't accepted any job carts yet. Visit your dashboard to browse and accept available jobs.</p>
      <a href="service-provider-dashboard.html" class="btn-dashboard">Go to Dashboard</a>
    </div>
  `;
  
  form.style.display = 'none';
  message.textContent = "No accepted job carts available. Please accept a job cart first from your dashboard.";
  message.style.color = "orange";
  message.parentNode.insertBefore(noJobsSection, message);
}

document.addEventListener("DOMContentLoaded", loadJobCarts);

// 1️ Auto-format price while typing
const priceInput = document.getElementById("quotation_price");
priceInput.addEventListener("input", () => {
  let value = priceInput.value.replace(/[^\d]/g, ""); // only numbers
  if (value) {
    priceInput.value = "R " + parseInt(value, 10).toLocaleString();
  } else {
    priceInput.value = "R 0.00";
  }
});



// Form submit handler with enhanced features
form.addEventListener("submit", async (e) => {
  e.preventDefault();

  const jobCartId = jobCartSelect.value;
  let priceFormatted = document.getElementById("quotation_price").value;
  let price = parseInt(priceFormatted.replace(/[^\d]/g, ""), 10); // keep only numbers
  const details = document.getElementById("quotation_details").value;
  const file = document.getElementById("quotation_file").files[0];

  if (!jobCartId || !price || !details || !file) {
    message.textContent = "Please complete all fields.";
    message.style.color = "red";
    return;
  }

  // Show loading state
  const submitBtn = document.querySelector('button[type="submit"]');
  const originalBtnText = submitBtn.textContent;
  submitBtn.textContent = "Uploading...";
  submitBtn.disabled = true;

  try {
    // Check if this is a demo job cart
    if (jobCartId.startsWith('demo-')) {
      // Handle demo job cart submission
      message.textContent = "Demo quotation submitted successfully! 🎉 This is a sample quotation for demonstration purposes.";
      message.style.color = "green";
      confirmBtn.disabled = false;
      
      // Reset form
      form.reset();
      return;
    }

    const serviceProviderId = currentServiceProvider.service_provider_id;

    // Verify that the service provider has accepted this job cart
    const { data: acceptance, error: acceptanceError } = await supabase
      .from("job_cart_acceptance")
      .select("acceptance_status")
      .eq("job_cart_id", jobCartId)
      .eq("service_provider_id", serviceProviderId)
      .single();

    if (acceptanceError || !acceptance) {
      message.textContent = "You must accept this job cart before uploading a quotation.";
      message.style.color = "red";
      return;
    }

    if (acceptance.acceptance_status !== "accepted") {
      message.textContent = "Job cart must be accepted before uploading quotation.";
      message.style.color = "red";
      return;
    }

    const filePath = `${serviceProviderId}/${Date.now()}-${file.name}`;
    const { error: uploadError } = await supabase.storage
      .from("quotations")
      .upload(filePath, file, { upsert: true });
    if (uploadError) throw uploadError;

    // Enhanced quotation data with experience-based features
    const quotationData = {
      service_provider_id: serviceProviderId,
      job_cart_id: jobCartId,
      quotation_price: price,
      quotation_details: details,
      quotation_file_path: filePath,
      quotation_file_name: file.name,
      quotation_submission_date: new Date().toISOString().split("T")[0],
      quotation_submission_time: new Date().toLocaleTimeString(),
      quotation_status: "pending",
      total_amount: price // For revenue tracking
    };

    // Add experience-based features for experienced providers
    if (providerExperience === 'experienced') {
      quotationData.quotation_notes = `Submitted by experienced provider (${providerStats.totalQuotations} previous quotations, ${providerStats.rating} avg rating)`;
    }

    const { data: quotation, error: insertError } = await supabase
      .from("quotation")
      .insert([quotationData])
      .select("quotation_id");

    if (insertError) throw insertError;

    lastQuotationId = quotation[0].quotation_id;
    
    // Show success message based on experience level
    if (providerExperience === 'new') {
      message.textContent = "Quotation uploaded successfully! 🎉 Welcome to Bonica - your quotation is now being reviewed by the client.";
    } else {
      message.textContent = `Quotation uploaded successfully! 📈 This is your ${providerStats.totalQuotations + 1}th quotation.`;
    }
    message.style.color = "green";
    confirmBtn.disabled = false;

    // Send real-time notification to client about new quotation
    await sendQuotationNotification(jobCartId, serviceProviderId, price);

    // Update provider stats
    providerStats.totalQuotations += 1;

  } catch (err) {
    console.error(err);
    message.textContent = err.message;
    message.style.color = "red";
  } finally {
    // Reset button state
    submitBtn.textContent = originalBtnText;
    submitBtn.disabled = false;
  }
});

// Send real-time notification to client about new quotation
async function sendQuotationNotification(jobCartId, serviceProviderId, price) {
  try {
    // Get job cart details to find the client
    const { data: jobCart, error: jobCartError } = await supabase
      .from("job_cart")
      .select(`
        event:event_id (
          client_id
        )
      `)
      .eq("job_cart_id", jobCartId)
      .single();

    if (jobCartError) throw jobCartError;

    // Get service provider details
    const { data: provider, error: providerError } = await supabase
      .from("service_provider")
      .select("service_provider_name, service_provider_surname")
      .eq("service_provider_id", serviceProviderId)
      .single();

    if (providerError) throw providerError;

    // Create notification for client
    const notification = {
      client_id: jobCart.event.client_id,
      notification_type: "new_quotation",
      notification_title: "New Quotation Received",
      notification_message: `You have received a new quotation from ${provider.service_provider_name} ${provider.service_provider_surname} for R${price.toLocaleString()}`,
      notification_data: {
        job_cart_id: jobCartId,
        service_provider_id: serviceProviderId,
        quotation_price: price,
        service_provider_name: `${provider.service_provider_name} ${provider.service_provider_surname}`
      },
      created_at: new Date().toISOString()
    };

    const { error: notificationError } = await supabase
      .from("notification")
      .insert(notification);

    if (notificationError) {
      console.warn("Failed to send notification:", notificationError);
    } else {
      console.log("✅ Notification sent to client about new quotation");
    }

  } catch (error) {
    console.error("Error sending quotation notification:", error);
  }
}

// Confirm quotation
confirmBtn.addEventListener("click", async () => {
  if (!lastQuotationId) {
    message.textContent = "No quotation to confirm!";
    message.style.color = "red";
    return;
  }

  try {
    const { error } = await supabase
      .from("quotation")
      .update({ quotation_status: "Confirmed" })
      .eq("quotation_id", lastQuotationId);

    if (error) throw error;

    message.textContent = "Quotation confirmed successfully!";
    message.style.color = "green";
    confirmBtn.disabled = true;
  } catch (err) {
    console.error(err);
    message.textContent = "Error confirming quotation!";
    message.style.color = "red";
  }
});