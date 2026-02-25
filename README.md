# Meesho Mock App 🛍️

A full-featured Flutter e-commerce app inspired by Meesho, with AI-powered features, Stripe payments, and a Node.js backend.

---

## Features

- 🛒 **Shopping & Cart** — product search, detail pages, cart, checkout
- 💜 **Meesho-themed UI** — Material 3 with purple color scheme
- 💳 **Stripe Payments** — real payment processing in INR (₹)
- 🤖 **AI Support Agent** — intelligent customer support chat
- 🎙️ **Voice Agent** — voice-powered shopping assistant
- 🧠 **Smart Cart Optimizer** — AI-powered cart suggestions
- 👛 **Wallet System** — in-app wallet with transaction history
- 📦 **Order Management** — past orders, order detail, returns & refunds
- ❤️ **Wishlist** — save products for later
- 🔔 **Push Notifications** — in-app notification system
- 📍 **Address Management** — multiple saved addresses

---

## Architecture

```
Flutter App  →  Node.js Backend (port 3000)  →  Stripe API
                       ↕
               Provider State Management
```

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart), Material 3 |
| State Management | Provider |
| Payments | Stripe (via Node.js backend) |
| Backend | Node.js + Express |
| Theme | Purple `#9C27B0`, white AppBar |

---

## Project Structure

```
lib/
├── provider/
│   ├── auth_provider.dart
│   ├── cart_provider.dart
│   ├── order_provider.dart
│   ├── wallet_provider.dart
│   ├── wishlist_provider.dart
│   ├── search_provider.dart
│   ├── profile_provider.dart
│   ├── address_provider.dart
│   ├── notification_provider.dart
│   ├── return_refund_provider.dart
│   ├── support_agent_provider.dart
│   ├── smart_cart_optimizer_provider.dart
│   └── voice_agent_provider.dart        # 🎙️ Voice Agent
├── screens/
│   ├── auth_screen.dart                 # Login / Register
│   ├── product_search_screen.dart       # Shopping home
│   ├── product_detail_screen.dart       # Product page
│   ├── cart_screen.dart
│   ├── checkout_screen.dart
│   ├── order_success_screen.dart
│   ├── past_order_screen.dart
│   ├── enhanced_order_detail_screen.dart
│   ├── return_request_screen.dart
│   ├── return_status_screen.dart
│   ├── wallet_screen_with_shopping.dart
│   ├── history_screen.dart
│   ├── transaction_api_screen.dart
│   ├── profile_screen.dart
│   ├── address_management_screen.dart
│   ├── wishlist_screen.dart
│   ├── notifications_screen.dart
│   ├── ai_support_screen.dart           # 🤖 AI Support
│   ├── smart_cart_optimizer_screen.dart # 🧠 Cart AI
│   └── voice_agent_screen.dart          # 🎙️ Voice Agent
└── main.dart

backend/
├── server.js       # Express + Stripe payment backend
├── .env            # STRIPE_SECRET_KEY (never commit this)
└── package.json
```

---

## App Routes

| Route | Screen |
|-------|--------|
| `/login` | Auth / Login |
| `/shopping` | Product Search |
| `/cart` | Cart |
| `/checkout` | Checkout |
| `/wallet` | Wallet |
| `/history` | Transaction History |
| `/transactionsApi` | Transaction API |
| `/profile` | User Profile |
| `/addresses` | Address Management |
| `/wishlist` | Wishlist |
| `/notifications` | Notifications |
| `/pastOrders` | Past Orders |
| `/support` | AI Support Chat |
| `/cartOptimizer` | Smart Cart Optimizer |
| `/voiceAgent` | Voice Agent |
| `/productDetail` | Product Detail (with args) |
| `/orderSuccess` | Order Success (with orderId) |
| `/orderDetail` | Order Detail (with order) |
| `/returnRequest` | Return Request (with args) |
| `/returnStatus` | Return Status (with returnId) |

---

## Backend API

### `GET /`
Health check.
```json
{ "status": "Backend running successfully 🚀" }
```

### `POST /create-payment-intent`
Create a Stripe payment intent for checkout.

**Request:**
```json
{ "amount": 499.00 }
```

**Response:**
```json
{ "clientSecret": "pi_xxx_secret_xxx" }
```

Amount is in **INR (₹)** — the backend converts to paise automatically.

---

## Getting Started

### Prerequisites

- Flutter SDK 3.x+
- Node.js 18+
- Stripe account (free) → https://stripe.com

### 1. Backend Setup

```bash
cd backend
npm install
```

Create a `.env` file:
```env
STRIPE_SECRET_KEY=sk_test_your_key_here
```

Start the server:
```bash
node server.js
```

Server runs on **http://0.0.0.0:3000**

### 2. Flutter Setup

```bash
flutter pub get
flutter run
```

Make sure your Flutter app points to your backend IP:
```dart
// Use your machine's local IP, not localhost, for physical devices
const String backendUrl = 'http://192.168.x.x:3000';
```

---

## Security

- ✅ Stripe secret key stored in `.env`, never hardcoded
- ✅ `.env` must be added to `.gitignore`
- ✅ Payment intent created server-side — client never touches the secret key
- ⚠️ Switch from `sk_test_` to `sk_live_` only when going to production

---

## Providers (State Management)

| Provider | Responsibility |
|----------|---------------|
| `AuthProvider` | Login, register, session |
| `CartProvider` | Cart items, quantities |
| `OrderProvider` | Order placement, history |
| `WalletProvider` | Balance, top-up |
| `WishlistProvider` | Saved products |
| `SearchProvider` | Product search & filters |
| `ProfileProvider` | User profile data |
| `AddressProvider` | Saved addresses |
| `NotificationProvider` | In-app notifications |
| `ReturnRefundProvider` | Returns & refunds |
| `SupportAgentProvider` | AI support chat |
| `SmartCartOptimizerProvider` | AI cart suggestions |
| `VoiceAgentProvider` | Voice commands |

---

## License

MIT
