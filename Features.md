### 🏘️ **Group Profile**

* Group Name
* Region, District
* GPS Coordinates (for mapping/geo-validation)

---

### 🔁 **Cycle Management**

* Each group operates in cycles (e.g., 12 months)
* A cycle has its own:

  * Members
  * Constitution
  * Transactions
  * Reports

---

### 📜 **Group Constitution**

* Configurable group rules per cycle:

  * Savings amount per member
  * Loan interest rate
  * Social fund amount
  * Guarantor requirements
  * Meeting frequency
* Versioning of constitutions per cycle

---

### 📅 **Meeting Management**

* Meetings scoped within a specific cycle
* Start/End meeting flow with session locking
* Schedule upcoming meetings
* Record minutes and agenda outcomes
* Track attendance per meeting
* Perform group operations only within active meetings:

  * Savings
  * Loan disbursement
  * Repayments
  * Fines

---

### 💳 **Accounts**

* **Main Account** – Group-wide savings and loan funds
* **Welfare/Social Fund** – Member emergencies, community needs
* **Fines & Fees Account** – Tracks penalties and admin fees

---

### 👥 **Member Management**

* Register members with profile data (name, contact, ID info)
* Assign and manage member roles (Chairperson, Treasurer, etc.)
* View individual financial history across cycles

---

### 💰 **Savings & Contributions**

* Record periodic member savings
* Support for variable vs. fixed saving amounts
* Total savings summary per cycle
* Goal setting & progress tracking
* Auto-reminders for savings days

---

### 📄 **Loan Management**

* Apply for loans during meetings
* Approval workflow with role-based access
* Loan ledger per member
* Interest settings (flat or reducing balance)
* Guarantor selection
* Automatic penalty & interest computation
* Repayment schedule generation

---

### ❤️ **Welfare/Social Fund Tracking**

* Member contributions to social fund
* Disbursement tracking for emergencies
* Balance and usage report per cycle

---

### ⚖️ **Fines & Penalties**

* Assign fines for:

  * Late attendance
  * Absenteeism
  * Missed savings
* Custom fine types and rules
* Auto-calculate and deduct from contributions
* Fine ledger per member

---

### 📊 **Financial Reports**

* Cycle-based reports:

  * Group profit & loss
  * Total savings, fines, loans
  * Welfare fund balance
  * Individual member statements
* Export to PDF/Excel

---

### 🔗 **Logical Relationships Between Fees, Fines, and Accounts**

---

#### **1. Account Types and Their Purpose**

| Account                  | Purpose                                                               | Funded By                                                      | Used For                                            |
| ------------------------ | --------------------------------------------------------------------- | -------------------------------------------------------------- | --------------------------------------------------- |
| **Main Account**         | Primary account holding group funds (savings + interest + repayments) | Member savings, loan repayments, interest, penalties (partial) | Loan disbursement, end-of-cycle payout              |
| **Welfare/Social Fund**  | Social/emergency support fund                                         | Member contributions (fixed per meeting)                       | Emergency payouts, agreed community uses            |
| **Fines & Fees Account** | Tracks penalties and administrative fees                              | Member fines and missed obligations                            | Internal group expenses or rolled into Main Account |

---

#### **2. Fee & Fine Relationships**

##### 🔸 **Savings Contribution**

* Fixed or variable amount defined in the **Constitution**
* Directly credited to **Main Account**
* Required in each scheduled meeting
* **Missed savings** → triggers a **fine** (credited to Fines & Fees Account)

##### 🔸 **Loan Interest**

* Defined in the Constitution (flat or reducing balance)
* Paid along with loan principal repayments
* Interest portion credited to the **Main Account**

##### 🔸 **Loan Guarantor**

* Constitution may require at least 1–2 guarantors for a loan
* If borrower defaults:

  * Guarantors may be fined or required to repay
  * Recovery amount credited to **Main Account**

##### 🔸 **Social Fund Contribution**

* Fixed amount per meeting as per Constitution
* Credited to **Welfare/Social Fund Account**
* Not refundable at end of cycle (unless specified)

##### 🔸 **Fines**

* Defined per type in the Constitution (e.g., UGX 1,000 for latecoming)
* Collected during the meeting and credited to **Fines & Fees Account**
* May be optionally transferred to **Main Account** at cycle-end

##### 🔸 **Administrative Fees**

* Can be collected during onboarding or specific operations (e.g., loan application fee)
* Credited to **Fines & Fees Account**
* Spent at discretion of the group, often by executive decision

---

#### **3. Special Relationships & Rules**

* **No cross-account borrowing** — loans must be disbursed strictly from the **Main Account**
* **Social Fund disbursement** requires member or executive approval, with purpose logged in meeting notes
* **Fines & Fees Account** can be:

  * Kept separate for transparency, or
  * Consolidated into Main Account at cycle-end, as per Constitution
* **At end-of-cycle payout**:

  * Social Fund balance may be rolled over to next cycle or zeroed
  * Main Account is liquidated to members based on shareholding
  * Fines & Fees Account handling is configurable

---

### 🧾 Example: Fee Flow Summary

* Member comes late → UGX 1,000 fine → Credited to **Fines & Fees**
* Member contributes UGX 5,000 savings → Credited to **Main Account**
* Member contributes UGX 2,000 social fund → Credited to **Welfare Fund**
* Member misses meeting → UGX 2,000 absentee fine → **Fines & Fees**

