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

// Load available job carts (from client services)
async function loadJobCarts() {
  try {
    const { data: jobCarts, error } = await supabase
      .from("job_cart")
      .select("job_cart_id, job_details, event_id")
      .eq("job_status", "Pending");

    if (error) throw error;

    jobCarts.forEach(cart => {
      const option = document.createElement("option");
      option.value = cart.job_cart_id;
      option.textContent = `Job #${cart.job_cart_id} – ${cart.job_details}`;
      jobCartSelect.appendChild(option);
    });
  } catch (err) {
    console.error(err);
    message.textContent = "Error loading job carts";
    message.style.color = "red";
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