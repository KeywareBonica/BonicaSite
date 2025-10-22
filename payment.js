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
const bankingDetailsBtn = document.getElementById("bankingDetailsBtn");
const continueBtn = document.getElementById("continueBtn");

// Fetch + calculate payment
async function calculatePaymentAmount(clientId) {
  // 1 Get cart items
  const { data: cartItems, error: cartError } = await supabaseClient
    .from("job_cart")
    .select("job_cart_item")
    .eq("client_id", clientId);

  if (cartError) throw cartError;
  if (!cartItems || cartItems.length === 0) return { subtotal: 0, fee: 0, total: 0 };

  const quotationIds = cartItems.map(item => item.job_cart_item);

  // 2 Get quotations
  const { data: quotations, error: quotationError } = await supabaseClient
    .from("quotation")
    .select("quotation_id, quotation_price")
    .in("quotation_id", quotationIds);

  if (quotationError) throw quotationError;

  // 3 Calculate amounts
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

// 3. Show Banking Details PDF
// -------------------------
bankingDetailsBtn.addEventListener("click", async () => {
  try {
    // Get banking details from DB
    const { data: bankingDetails, error } = await supabaseClient
      .from("bankingdetails")
      .select("bankingdetails_id, acc_no, acc_name, branch_details, reference")
      .limit(1); // assume only one account

    if (error || !bankingDetails || bankingDetails.length === 0) {
      alert("Banking details not found.");
      return;
    }

    const details = bankingDetails[0];

    // Generate PDF on the fly
    const doc = new window.jspdf.jsPDF();
    doc.text("Banking Details", 10, 10);
    doc.text(`Account Name: ${details.acc_name}`, 10, 20);
    doc.text(`Account No: ${details.acc_no}`, 10, 30);
    doc.text(`Branch: ${details.branch_details}`, 10, 40);
    doc.text(`Reference: ${details.reference}`, 10, 50);
    doc.save("BankingDetails.pdf");
  } catch (err) {
    console.error(err);
    alert("Error fetching banking details.");
  }
});


//const continueBtn = document.getElementById("continueBtn");
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

    // Upload file to supabase storage
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

    // Insert payment record with file metadata
    const { error: paymentError } = await supabaseClient
      .from("payment")
      .insert([
        {
          booking_id: bookingId,
          payment_amount: total,   // store total (subtotal + service fee)
          payment_method: "EFT",   // required by use case
          payment_proof: proofUrl, // Keep for backward compatibility
          proof_of_payment_file_path: fileName, // New file path
          proof_of_payment_file_name: file.name, // Original file name
          proof_of_payment_file_size: file.size, // File size
          proof_of_payment_file_type: file.type, // MIME type
          proof_of_payment_file_validated: true, // File uploaded successfully
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
