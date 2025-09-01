// payment.js

// 1. Supabase setup
  const supabaseUrl = "https://spudtrptbyvwyhvistdf.supabase.co";
  const supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNwdWR0cnB0Ynl2d3lodmlzdGRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU2OTk4NjgsImV4cCI6MjA3MTI3NTg2OH0.GBo-RtgbRZCmhSAZi0c5oXynMiJNeyrs0nLsk3CaV8A";
  const supabaseClient = window.supabase.createClient(supabaseUrl, supabaseAnonKey);

const proofForm = document.getElementById("proof-form");
const proofFile = document.getElementById("proof-file");
const message = document.getElementById("message");

const subtotalEl = document.getElementById("subtotal");
const serviceFeeEl = document.getElementById("service-fee");
const totalEl = document.getElementById("total-to-pay");

// Fetch + calculate payment
async function calculatePaymentAmount(clientId) {
  // 1️ Get cart items
  const { data: cartItems, error: cartError } = await supabaseClient
    .from("job_cart")
    .select("job_cart_item")
    .eq("client_id", clientId);

  if (cartError) throw cartError;
  if (!cartItems || cartItems.length === 0) return { subtotal: 0, fee: 0, total: 0 };

  const quotationIds = cartItems.map(item => item.job_cart_item);

  // 2️ Get quotations
  const { data: quotations, error: quotationError } = await supabaseClient
    .from("quotation")
    .select("quotation_id, quotation_price")
    .in("quotation_id", quotationIds);

  if (quotationError) throw quotationError;

  // 3️ Calculate amounts
  const subtotal = quotations.reduce((sum, q) => sum + q.quotation_price, 0);
  const serviceFee = subtotal * 0.15;
  const total = subtotal + serviceFee;

  //console.log("Quotations:", quotations);
  //console.log("Subtotal:", subtotal, "Service fee:", serviceFee, "Total:", total);

  return { subtotal, fee: serviceFee, total };
}

// Load summary on page load
document.addEventListener("DOMContentLoaded", async () => {
  const { data: { user } } = await supabaseClient.auth.getUser();
  if (!user) {
    subtotalEl.textContent = "Login required";
    return;
  }

  try {
    const { subtotal, fee, total } = await calculatePaymentAmount(user.id);

    subtotalEl.textContent = `R${subtotal.toFixed(2)}`;
    serviceFeeEl.textContent = `R${fee.toFixed(2)}`;
    totalEl.textContent = `R${total.toFixed(2)}`;
  } catch (err) {
    console.error(err);
    message.textContent = "Error loading payment summary.";
  }
});

const continueBtn = document.getElementById("continueBtn");
//continueBtn.disabled = true; // make sure it starts disabled

// Handle proof upload
proofForm.addEventListener("submit", async (e) => {
  e.preventDefault();

  const file = proofFile.files[0];
  if (!file) {
    message.textContent = "⚠️ Please select a file first.";
    return;
  }

  try {
    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) {
      message.textContent = "⚠️ You must be logged in.";
      return;
    }

    // Get latest booking for this user
    const { data: bookings, error: bookingError } = await supabaseClient
      .from("booking")
      .select("booking_id")
      .eq("client_id", user.id)
      .order("created_at", { ascending: false })
      .limit(1);

    if (bookingError || !bookings || bookings.length === 0) {
      message.textContent = "⚠️ No booking found for this account.";
      return;
    }

    const bookingId = bookings[0].booking_id;

    // Calculate total again
    const { total } = await calculatePaymentAmount(user.id);

    if (total === 0) {
      message.textContent = "⚠️ No items in your cart.";
      return;
    }

    // Upload proof
    const fileName = `proofs/${Date.now()}_${file.name}`;
    const { error: storageError } = await supabaseClient
      .storage
      .from("payment")
      .upload(fileName, file);

    if (storageError) throw storageError;

    const { data: publicUrlData } = supabaseClient
      .storage
      .from("payment")
      .getPublicUrl(fileName);

    const proofUrl = publicUrlData.publicUrl;

    // Insert payment record
    const { error: paymentError } = await supabaseClient
      .from("payment")
      .insert([
        {
          booking_id: bookingId,
          payment_amount: total,   // store total (subtotal + service fee)
          payment_proof: proofUrl,
          payment_status: "pending" // until admin confirms
        }
      ]);

    if (paymentError) throw paymentError;

    message.textContent = `✅ Payment of R${total.toFixed(2)} uploaded successfully!`;
    proofForm.reset();

    // Enable continue button
    continueBtn.disabled = false;

  } catch (err) {
    console.error("Payment error:", err.message);
    message.textContent = "❌ " + err.message;
  }
});

// Handle Continue button
continueBtn.addEventListener("click", () => {
  window.location.href = "confirmation.html";
});
