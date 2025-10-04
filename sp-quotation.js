import { createClient } from "@supabase/supabase-js";

// 🔑 Replace with your Supabase project credentials
const supabaseUrl = "https://spudtrptbyvwyhvistdf.supabase.co";
const supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNwdWR0cnB0Ynl2d3lodmlzdGRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU2OTk4NjgsImV4cCI6MjA3MTI3NTg2OH0.GBo-RtgbRZCmhSAZi0c5oXynMiJNeyrs0nLsk3CaV8A";
const supabase = createClient(supabaseUrl, supabaseAnonKey);

const form = document.getElementById("quotationForm");
const confirmBtn = document.getElementById("confirmBtn");
const message = document.getElementById("message");
const jobCartSelect = document.getElementById("job_cart_select");

let lastQuotationId = null;

// Load available job carts (only accepted ones for this service provider)
async function loadJobCarts() {
  try {
    // Get current service provider ID
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error("You must be logged in!");

    const { data: provider, error: providerError } = await supabase
      .from("service_provider")
      .select("service_provider_id")
      .eq("user_id", user.id)
      .single();

    if (providerError || !provider) throw new Error("Not a valid service provider!");

    const serviceProviderId = provider.service_provider_id;

    // Get accepted job carts for this service provider
    const { data: acceptedJobs, error } = await supabase
      .from("job_cart_acceptance")
      .select(`
        job_cart:job_cart_id (
          job_cart_id,
          job_cart_item,
          job_cart_details,
          event:event_id (
            event_name,
            event_date,
            event_location
          )
        )
      `)
      .eq("service_provider_id", serviceProviderId)
      .eq("acceptance_status", "accepted");

    if (error) throw error;

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
    acceptedJobs.forEach(job => {
      const option = document.createElement("option");
      option.value = job.job_cart.job_cart_id;
      option.textContent = `${job.job_cart.job_cart_item} - ${job.job_cart.event?.event_name || 'N/A'}`;
      jobCartSelect.appendChild(option);
    });

    if (acceptedJobs.length === 0) {
      message.textContent = "No accepted job carts available. Please accept a job cart first from your dashboard.";
      message.style.color = "orange";
      document.querySelector('button[type="submit"]').disabled = true;
    }
  } catch (err) {
    console.error(err);
    message.textContent = err.message || "Error loading job carts";
    message.style.color = "red";
    document.querySelector('button[type="submit"]').disabled = true;
  }
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



// Form submit handler
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

  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error("You must be logged in!");

    const { data: provider, error: providerError } = await supabase
      .from("service_provider")
      .select("service_provider_id")
      .eq("user_id", user.id)
      .single();

    if (providerError || !provider) throw new Error("Not a valid service provider!");

    const serviceProviderId = provider.service_provider_id;

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

    const { data: quotation, error: insertError } = await supabase
      .from("quotation")
      .insert([{
        service_provider_id: serviceProviderId,
        job_cart_id: jobCartId,
        quotation_price: price,
        quotation_details: details,
        quotation_file_path: filePath,
        quotation_file_name: file.name,
        quotation_submission_date: new Date().toISOString().split("T")[0],
        quotation_submission_time: new Date().toLocaleTimeString(),
        quotation_status: "Pending",
      }])
      .select("quotation_id");

    if (insertError) throw insertError;

    lastQuotationId = quotation[0].quotation_id;
    message.textContent = "Quotation uploaded successfully!";
    message.style.color = "green";
    confirmBtn.disabled = false;

  } catch (err) {
    console.error(err);
    message.textContent = err.message;
    message.style.color = "red";
  }
});

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