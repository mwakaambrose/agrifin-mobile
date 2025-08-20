
**You are to build a Flutter mobile application that connects to a Laravel 12 backend powered by the Devdojo Wave starter kit.**
The app is for managing Village Savings and Loan Associations (VSLA), and will interact entirely with APIs exposed by the Laravel backend. The app must be intuitive, performant, and offline-friendly where possible.

---

### 🔗 API Backend Context

* Backend is Laravel 12 using `devdojo.com/wave` starter kit.
* Auth is powered via **Laravel Sanctum** with `mobile_api` guard.
* Backend has **two UI roles**:

  * **Admin/Staff:** Management UI via Wave dashboard.
  * **Mobile User:** Interacts only via API from mobile app.

---

### 📱 Target App Overview (VSLA Mobile App)

#### 📋 Modules:

* **Authentication:**

  * Register, login (phone & password), logout.
  * Password reset, 2FA (if enabled), token-based auth (Laravel Sanctum).

* **User Profile:**

  * View/update user info.
  * Update PIN (used for sensitive actions).
  * Profile photo upload.

* **Member Management:**

  * Add members (with optional phone/email).
  * Approve/reject new member requests (by group admins).
  * View member savings/loan status.

* **Savings Module:**

  * Contribute weekly/monthly savings.
  * View savings balance.
  * Savings history.
  * Save for specific goals.
  * Withdraw savings (approval required).

* **Loan Management:**

  * Apply for a loan (select amount, purpose, term).
  * Approvals (multi-role: Treasurer/Chairperson).
  * Loan disbursement.
  * Repayment schedule.
  * View outstanding and paid loans.

* **Fines and Fees:**

  * View applicable fines.
  * Pay fines via wallet or group balance.
  * Track fine history.

* **Social Fund Contributions:**

  * Periodic contributions.
  * Request funds from social fund.
  * Track social fund usage.

* **Meeting Management:**

  * Create/view upcoming meetings.
  * Attendance register.
  * Minutes of meetings.
  * Agendas and resolutions.

* **Notifications & Alerts:**

  * In-app and push notifications.
  * Notifications for approvals, disbursements, repayments due, etc.

* **Reports:**

  * View savings/loans/fines/social fund balances per group & per member.
  * Member-level performance summary.

---

### 💸 Fee Logic and Definitions (Backend Enforced, Consumed by App)

All fees below are configured via the backend and returned by API. The app consumes and enforces validation rules returned via config endpoints.

* **Savings Fee:**

  * Fixed amount saved weekly or monthly.
  * Editable by group admins.

* **Loan Interest Rate:**

  * Either flat or reducing balance (configured per group).
  * Based on loan amount and duration.

* **Late Repayment Fee:**

  * Applies if payment is past due date.
  * Flat rate or daily penalty.

* **Withdrawal Fee:**

  * Charged when a member withdraws savings.
  * Percentage or fixed.

* **Social Fund Contribution Fee:**

  * Periodic contribution (weekly or monthly).
  * Configurable per group.

* **Card Issuance Fee (Optional NFC Feature):**

  * Charged when issuing digital ID card.
  * One-time fee.

**Note:** All fees have logical relationships. Example:

* Loan interest is applied on `loan_amount × interest_rate × term`.
* Late fees are triggered by missed repayment dates.
* Wallet top-ups must be ≥ total payable amount including fees.

---

### 🔒 Authentication + API Integration

* Use **Sanctum token** stored securely.
* Include token in each request header:
  `Authorization: Bearer <token>`
* Protect all routes with `auth:sanctum` middleware on Laravel.
* Use `api.php` routes for mobile.

---

### 🧩 Technical Requirements

* State management (Riverpod, Provider, or Bloc).
* Local storage for offline caching (Hive, Isar, or SharedPreferences).
* Push Notifications (Firebase Cloud Messaging).
* Form validation with real-time feedback.
* Responsive UI for all device sizes.
* Robust error handling with retry logic for network calls.
* Use RESTful API principles with proper pagination and filtering.

