require('dotenv').config();
const express = require("express");
const cors = require("cors");
const Stripe = require("stripe");

const app = express();

// ================= CONFIG =================
const PORT = 3000;

// 🔐 NEVER hardcode secret in production
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

// ================= MIDDLEWARE =================
app.use(cors());
app.use(express.json());

// ================= HEALTH CHECK =================
app.get("/", (req, res) => {
  res.json({ status: "Backend running successfully 🚀" });
});

// ================= CREATE PAYMENT INTENT =================
app.post("/create-payment-intent", async (req, res) => {
  try {
    const { amount } = req.body;

    // Validation
    if (!amount || isNaN(amount) || amount <= 0) {
      return res.status(400).json({ error: "Invalid amount" });
    }

    console.log("Creating payment intent for:", amount);

    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // convert ₹ to paise
      currency: "inr",
      automatic_payment_methods: { enabled: true },
    });

    res.json({
      clientSecret: paymentIntent.client_secret,
    });

  } catch (error) {
    console.error("Stripe Error:", error.message);
    res.status(500).json({ error: error.message });
  }
});

// ================= START SERVER =================
app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on http://0.0.0.0:${PORT}`);
});