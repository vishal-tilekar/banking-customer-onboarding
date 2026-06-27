# 🏦 Banking Customer Onboarding System (BCOS)

A complete **Banking Customer Onboarding System** built using **Oracle PL/SQL** and **Oracle APEX**, designed to demonstrate enterprise-level database development skills.

---

## 🚀 Features

| Feature | Description |
|---|---|
| 👤 Customer Registration | Full registration form with validation |
| 🔍 Duplicate Check | Auto-detect duplicate PAN / Aadhar / Mobile / Email |
| ✅ KYC Verification | Multi-type KYC with status tracking |
| 📁 Document Upload | BLOB-based document management |
| 🆔 UCIC Generation | Auto-generate Unique Customer ID Code |
| 🔄 Approval Workflow | Multi-stage Approve / Reject / Hold workflow |
| 📊 Dashboard | Real-time stats and charts |
| 📋 Reports | Interactive Reports with filters and export |
| 🔎 Audit Trail | Complete system activity log |
| 🔐 Authorization | Role-based access (Admin / Reviewer / Viewer) |

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Database** | Oracle 21c |
| **Frontend** | Oracle APEX 24.x |
| **Backend** | PL/SQL Packages, Triggers |
| **API** | Oracle REST Data Services (ORDS) |
| **Cloud** | apex.oracle.com (Free Workspace) |

---

## 📁 Project Structure

```
banking_onboarding/
│
├── 01_schema/
│   └── 01_create_tables.sql         # Tables, Sequences, Indexes
│
├── 02_packages/
│   └── 02_bcos_package.sql          # PL/SQL Package (Spec + Body)
│
├── 03_triggers/
│   └── 03_bcos_triggers.sql         # All Triggers
│
├── 04_rest_api/
│   └── 04_bcos_rest_api.sql         # ORDS REST API definitions
│
├── 05_apex_export/
│   └── 05_apex_setup_guide.sql      # APEX pages & setup instructions
│
├── 06_sample_data/
│   └── 06_sample_data.sql           # Sample / Seed data
│
└── README.md
```

---

## ⚙️ Installation Steps

### Step 1: Database Setup
```sql
-- Run in order:
@01_schema/01_create_tables.sql
@02_packages/02_bcos_package.sql
@03_triggers/03_bcos_triggers.sql
@04_rest_api/04_bcos_rest_api.sql
@06_sample_data/06_sample_data.sql
```

### Step 2: APEX Setup (apex.oracle.com)
1. Login to [apex.oracle.com](https://apex.oracle.com)
2. Create a new **Free Workspace**
3. Run all SQL scripts in **SQL Workshop → SQL Commands**
4. Create a new **APEX Application**
5. Follow `05_apex_export/05_apex_setup_guide.sql` for page-by-page setup

### Step 3: Enable REST APIs
```sql
-- Update schema name and run:
@04_rest_api/04_bcos_rest_api.sql
```

---

## 📐 Database Schema

```
BCOS_CUSTOMERS          → Master customer table
BCOS_KYC_DETAILS        → KYC verification records
BCOS_DOCUMENTS          → Document uploads (BLOB)
BCOS_UCIC_LOG           → UCIC generation history
BCOS_DUPLICATE_CHECK    → Duplicate detection log
BCOS_APPROVAL_WORKFLOW  → Multi-stage workflow
BCOS_AUDIT_TRAIL        → Complete audit log
BCOS_LOOKUP             → Master/lookup data
```

---

## 🔗 REST API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| POST | `/bcos/api/customer/register` | Register new customer |
| GET | `/bcos/api/customer/:id` | Get customer by ID |
| GET | `/bcos/api/customer/list` | List all customers |
| PUT | `/bcos/api/customer/workflow/:id` | Approve/Reject/Hold |
| GET | `/bcos/api/dashboard` | Dashboard summary |

---

## 💡 PL/SQL Concepts Demonstrated

- ✅ **Packages** — `bcos_pkg` with Spec + Body
- ✅ **Triggers** — Audit, Duplicate Check, KYC auto-update
- ✅ **Exception Handling** — WHEN OTHERS, DUP_VAL_ON_INDEX, NO_DATA_FOUND
- ✅ **Cursors** — SYS_REFCURSOR in dashboard function
- ✅ **Autonomous Transaction** — In audit log procedure
- ✅ **Sequences** — UCIC number generation
- ✅ **REST APIs** — ORDS-based REST endpoints

---

## 🌐 APEX Concepts Demonstrated

- ✅ **Interactive Reports** — Customer list with filters, export
- ✅ **Interactive Grids** — Editable KYC/document grid
- ✅ **Dynamic Actions** — Approve/Reject buttons, real-time refresh
- ✅ **Authorization Schemes** — Role-based (Admin/Reviewer/Viewer)
- ✅ **File Upload (BLOB)** — Document management
- ✅ **REST Data Source** — Dashboard integration
- ✅ **Universal Theme** — Responsive design

---

## 👨‍💻 Author

**Vishal** — Senior Oracle Developer (PL/SQL & APEX)  
Stockholding Corporation of India Ltd., Mumbai  

---

## 📄 License

This project is for portfolio and demonstration purposes.
```
