# Mobile Shop EMI Manager — Backend Architecture Document

## 1. Executive Summary & Application Overview

The **Mobile Shop EMI Manager** is a specialized retail micro-finance and store management application designed for mobile handset retailers. It allows store owners to sell smartphones on store-managed EMI plans, manage customer profiles, process down payments and monthly installments, track overdue accounts, and view store analytics. Additionally, it supports a Multi-Store / Multi-Tenant architecture governed by a `SUPER_ADMIN`.

### Core Features Discovered from Flutter Application Code:
1. **Multi-Tenant Authentication & Store Customization**:
   - Secure login via Mobile Number & Password.
   - Role-Based Access Control (`STORE_OWNER`, `SUPER_ADMIN`).
   - Store Branding & Dynamic Color Themes (`primaryColor`, `secondaryColor`, `accentColor`, `logoUrl`).
2. **Shop Dashboard & Performance Metrics**:
   - High-level KPIs: Total Customers, Active Customers, Active EMIs, Total Financed Amount, Total Collection, Pending Amount, Overdue Count, Monthly Collection.
3. **Customer Directory & Lifecycle Management**:
   - Customer onboarding with personal contact info, location details, Aadhaar/KYC verification.
   - Categorized customer filtering (`All`, `Active EMIs`, `Overdue`, `Paid Off`).
   - Customer search across Name, Mobile Number, Device Name, and IMEI.
   - Customer profile detail view including Trust Score (0–100), total purchase value, total recovered amount, active loan details, and complete payment history ledger.
4. **Handset & EMI Financing Management**:
   - Handset specifications: Brand, Model, Storage/Color Variant, MRP, Selling Price, IMEI number, Serial Number, Warranty details.
   - Flexible EMI loan calculation: Selling Price - Down Payment = Financed Balance.
   - EMI tenure terms (3, 6, 9, 12, or custom months), automatic monthly installment calculation, and due date tracking.
   - EMI status tracking (`onTrack`, `dueToday`, `overdue`, `cleared`).
5. **Payment Processing & Ledger**:
   - Payment recording supporting multiple modes: Counter Cash, UPI Paid / AutoPay Mandate, POS Card Swipe.
   - Automatic installment tracking (e.g., EMI #1, EMI #2, Down Payment).
   - Receipt reference generation (e.g., `REC-9821`, `Store Receipt`).
   - Paginated payment history log.
6. **Analytics & Financial Reports**:
   - Executive financial summary (Total Revenue, Monthly Revenue, Collection Rate %, Overdue Amount).
   - Monthly Collection vs Pending trend analysis.
   - Weekly collection breakdowns.
   - Financed Smartphone brand distribution analysis.
7. **Super Admin Platform Oversight**:
   - Multi-store listing, store creation, account activation/suspension, password reset, and tenant custom branding.

---

## 2. Backend Technology Stack

The backend is built with **Node.js** and **MongoDB**, following a layered MVC architecture using **Express.js** as the HTTP framework and **Mongoose** as the ODM (Object Document Mapper).

### Core Technologies
| Layer | Technology | Version |
|-------|-----------|--------|
| Runtime | Node.js | >= 18.x LTS |
| Framework | Express.js | ^4.x |
| Database | MongoDB | >= 6.x |
| ODM | Mongoose | ^7.x |
| Authentication | `jsonwebtoken` | ^9.x |
| Password Hashing | `bcryptjs` | ^2.x |
| Validation | `express-validator` | ^7.x |
| Environment Config | `dotenv` | ^16.x |
| CORS | `cors` | ^2.x |
| Logging | `morgan` | ^1.x |

### Project Folder Structure
```
backend/
├── src/
│   ├── config/
│   │   └── db.js               # MongoDB connection (Mongoose)
│   ├── models/
│   │   ├── Store.model.js
│   │   ├── User.model.js
│   │   ├── Customer.model.js
│   │   ├── EmiPlan.model.js
│   │   └── Payment.model.js
│   ├── routes/
│   │   ├── auth.routes.js
│   │   ├── dashboard.routes.js
│   │   ├── customer.routes.js
│   │   ├── emiPlan.routes.js
│   │   ├── payment.routes.js
│   │   ├── report.routes.js
│   │   └── admin.routes.js
│   ├── controllers/
│   │   ├── auth.controller.js
│   │   ├── dashboard.controller.js
│   │   ├── customer.controller.js
│   │   ├── emiPlan.controller.js
│   │   ├── payment.controller.js
│   │   ├── report.controller.js
│   │   └── admin.controller.js
│   ├── middleware/
│   │   ├── auth.middleware.js   # JWT verification & role guard
│   │   └── error.middleware.js  # Global error handler
│   ├── utils/
│   │   └── responseHelper.js   # Standard success/error response builders
│   └── app.js                  # Express app setup
├── server.js                   # Entry point
├── .env
└── package.json
```

### Environment Variables (`.env`)
```env
PORT=5000
MONGO_URI=mongodb://localhost:27017/emi_manager
JWT_SECRET=your_super_secret_key
JWT_EXPIRES_IN=7d
NODE_ENV=development
```

### MongoDB Connection (`src/config/db.js`)
```js
const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGO_URI);
    console.log(`MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`DB Connection Error: ${error.message}`);
    process.exit(1);
  }
};

module.exports = connectDB;
```

---

## 3. Standard API Architecture Contracts

All backend endpoints strictly follow modern RESTful conventions, returning JSON responses wrapped in standard response formats.

### Base URL & Versioning
- **Development**: `http://localhost:5000/api/v1`
- **Staging**: `https://staging-api.example.com/api/v1`
- **Production**: `https://api.example.com/api/v1`

### Standard Headers
| Header Name | Required | Description |
|-------------|----------|-------------|
| `Authorization` | Yes (except `/auth/login`) | `Bearer <JWT_ACCESS_TOKEN>` |
| `Content-Type` | Yes (for POST/PUT) | `application/json` |

---

### Universal API Response Wrappers

#### 1. Standard Success Response
```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": {}
}
```

#### 2. Standard Error Response
```json
{
  "success": false,
  "message": "Invalid credentials or request payload",
  "error": {
    "code": "AUTHENTICATION_FAILED",
    "details": [
      {
        "field": "mobileNumber",
        "message": "Mobile number must be a valid 10-digit number"
      }
    ]
  }
}
```

#### 3. Standard Paginated Response Structure
Endpoints returning lists support pagination query parameters (`page`, `limit`, `search`, `sort`, `filters`).

```json
{
  "success": true,
  "message": "Items retrieved successfully",
  "data": {
    "items": [],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalCount": 86,
      "hasMore": true
    }
  }
}
```

---

## 4. Comprehensive API Specifications

---

### 4.1 Authentication API (`/auth`)

#### 1. Login (`POST /auth/login`)
Authenticates a user (`STORE_OWNER` or `SUPER_ADMIN`) and issues a JWT access token.

- **Request Body**:
```json
{
  "mobileNumber": "1234567890",
  "password": "12345"
}
```

- **Response Body (200 OK)**:
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJtb2NrLXVzZXItMDAxIiwicm9sZSI6IlNUT1JFX09XTkVSIiwiaWF0IjoxNTE2MjM5MDIyfQ.sample_signature",
    "user": {
      "id": "64f1a2b3c4d5e6f7a8b9c0d1",
      "name": "Demo Store Owner",
      "mobileNumber": "1234567890",
      "role": "STORE_OWNER",
      "storeId": "64f1a2b3c4d5e6f7a8b9c0d2",
      "storeName": "Demo Mobile Shop",
      "profileImageUrl": null,
      "theme": {
        "primaryColor": "#6C5CE7",
        "secondaryColor": "#111827",
        "accentColor": "#F59E0B",
        "backgroundColor": "#F8FAFC",
        "logoUrl": "https://example.com/logo.png"
      }
    }
  }
}
```

- **Error Response (401 Unauthorized)**:
```json
{
  "success": false,
  "message": "Invalid mobile number or password",
  "error": {
    "code": "INVALID_CREDENTIALS"
  }
}
```

---

#### 2. Get Current Authenticated User (`GET /auth/me`)
Fetches the active user's profile and store details from the Bearer token.

- **Request Body**: None
- **Response Body (200 OK)**:
```json
{
  "success": true,
  "message": "User profile fetched",
  "data": {
    "id": "64f1a2b3c4d5e6f7a8b9c0d1",
    "name": "Demo Store Owner",
    "mobileNumber": "1234567890",
    "role": "STORE_OWNER",
    "storeId": "64f1a2b3c4d5e6f7a8b9c0d2",
    "storeName": "Demo Mobile Shop",
    "profileImageUrl": null,
    "theme": {
      "primaryColor": "#6C5CE7",
      "secondaryColor": "#111827",
      "accentColor": "#F59E0B",
      "backgroundColor": "#F8FAFC",
      "logoUrl": null
    }
  }
}
```

---

#### 3. Logout (`POST /auth/logout`)
Invalidates the current session token on the server side.

- **Request Body**: None
- **Response Body (200 OK)**:
```json
{
  "success": true,
  "message": "Successfully logged out",
  "data": null
}
```

---

### 4.2 Dashboard API (`/dashboard`)

#### 1. Fetch Store Dashboard Summary (`GET /dashboard`)
Returns aggregated metrics for the store linked to the authenticated `STORE_OWNER`. Uses MongoDB aggregation pipelines to compute KPIs.

- **Request Body**: None
- **Response Body (200 OK)**:
```json
{
  "success": true,
  "message": "Dashboard metrics retrieved",
  "data": {
    "totalCustomers": 142,
    "newCustomersThisMonth": 8,
    "activeCustomers": 86,
    "activeEmis": 86,
    "activeLoanAmount": 1840000.0,
    "totalCollection": 184500.0,
    "pendingAmount": 32000.0,
    "overdueCount": 2,
    "monthlyCollection": 184500.0,
    "storeName": "Shree Ganesh Mobiles",
    "storeLocation": "Ganesh Nagar, Pune",
    "ownerName": "Rajesh Ji"
  }
}
```

---

### 4.3 Customer Management API (`/customers`)

#### 1. List / Search / Filter Customers (`GET /customers`)
Fetches paginated list of customers with search and category filtering. Uses MongoDB `$regex` for text search and `$lookup` aggregation for EMI plan join.

- **Query Parameters**:
  - `page` (integer, default: 1)
  - `limit` (integer, default: 20)
  - `search` (string, optional - searches name, phone, device model, IMEI)
  - `category` (string, optional: `All`, `Active EMIs`, `Overdue`, `Paid Off`)

- **Response Body (200 OK)**:
```json
{
  "success": true,
  "message": "Customers retrieved successfully",
  "data": {
    "items": [
      {
        "id": "64f1a2b3c4d5e6f7a8b9c0d3",
        "name": "Amit Verma",
        "mobileNumber": "+91 98231 44521",
        "initials": "AV",
        "status": "overdue",
        "statusDetail": "OVERDUE (12 Days)",
        "deviceName": "Samsung Galaxy S23 5G",
        "imei": "358921094821034",
        "currentEmiNumber": 4,
        "totalEmiMonths": 12,
        "installmentLabel": "Monthly Installment",
        "installmentAmount": 3250.0,
        "outstandingLabel": "Outstanding Balance",
        "outstandingAmount": 26000.0,
        "paidAmount": 13000.0,
        "email": "amit.verma@example.com",
        "address": "Kothrud, Pune"
      },
      {
        "id": "64f1a2b3c4d5e6f7a8b9c0d4",
        "name": "Priya Sharma",
        "mobileNumber": "+91 97652 11094",
        "initials": "PS",
        "status": "dueToday",
        "statusDetail": "DUE TODAY",
        "deviceName": "OnePlus Nord CE 3",
        "imei": "861049281729104",
        "currentEmiNumber": 2,
        "totalEmiMonths": 6,
        "installmentLabel": "Today's EMI",
        "installmentAmount": 2100.0,
        "outstandingLabel": "Pending Outstanding",
        "outstandingAmount": 8400.0,
        "paidAmount": 4200.0,
        "email": null,
        "address": "MG Road, Pune"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 1,
      "totalCount": 2,
      "hasMore": false
    }
  }
}
```

---

#### 2. Create Customer & Financed Device (`POST /customers`)
Registers a new customer, their purchased handset, and sets up their initial EMI contract. Creates documents across `Customer` and `EmiPlan` collections in a single atomic operation.

- **Request Body**:
```json
{
  "customer": {
    "fullName": "Rahul Sharma",
    "mobileNumber": "+91 98230 44192",
    "email": "rahul.sharma@example.com",
    "address": "Shop 4, MG Road, Pune, Maharashtra 411001",
    "aadhaarNumber": "4821-XXXX-XXXX"
  },
  "device": {
    "brand": "Samsung",
    "modelName": "Samsung Galaxy S24 5G",
    "variant": "128GB / Onyx Black",
    "imei": "359281102938491",
    "serialNumber": "RSCW10X99M",
    "notes": "Brand new sealed pack"
  },
  "emiTerms": {
    "sellingPrice": 45000.0,
    "downPayment": 10000.0,
    "loanAmount": 35000.0,
    "tenureMonths": 9,
    "monthlyInstallment": 3250.0,
    "firstEmiDueDate": "2026-11-10T00:00:00.000Z"
  }
}
```

- **Response Body (201 Created)**:
```json
{
  "success": true,
  "message": "Customer and EMI plan created successfully",
  "data": {
    "customerId": "64f1a2b3c4d5e6f7a8b9c0d5",
    "emiPlanId": "64f1a2b3c4d5e6f7a8b9c0d6",
    "createdAt": "2026-10-02T20:30:00.000Z"
  }
}
```

---

#### 3. Get Customer Detailed Profile (`GET /customers/:id`)
Fetches full details for a customer, including trust score, active loan information, and complete payment history. Uses MongoDB `$lookup` aggregation to join EMI plan and payment data.

- **Path Parameters**: `id` (MongoDB ObjectId)
- **Response Body (200 OK)**:
```json
{
  "success": true,
  "message": "Customer profile fetched",
  "data": {
    "id": "64f1a2b3c4d5e6f7a8b9c0d3",
    "name": "Amit Verma",
    "initials": "AV",
    "phone": "+91 98231 44521",
    "address": "Kothrud, Pune",
    "memberSince": "Oct 2023",
    "isActive": true,
    "trustScore": 82,
    "totalPurchases": 74999.0,
    "deviceCount": 2,
    "totalRecovered": 13000.0,
    "recoveryMethod": "Via UPI & Cash",
    "overdueAmount": 26000.0,
    "overdueDays": 12,
    "upcomingInstallment": 3250.0,
    "upcomingDate": "10 Oct 2026",
    "activeLoan": {
      "brand": "Samsung",
      "model": "Galaxy S23 5G",
      "storage": "256GB",
      "color": "Phantom Black",
      "imei": "358921094831034",
      "principal": 39000.0,
      "monthlyEmi": 3250.0,
      "emiPaid": 4,
      "emiTotal": 12,
      "isDefaulted": true
    },
    "paymentHistory": [
      {
        "label": "EMI #3",
        "method": "UPI Paid",
        "date": "10 Sep 2026",
        "ref": "REC-9821",
        "amount": 3250.0,
        "status": "paid"
      },
      {
        "label": "EMI #2",
        "method": "Counter Cash",
        "date": "10 Aug 2026",
        "ref": "Store Receipt",
        "amount": 3250.0,
        "status": "paid"
      },
      {
        "label": "EMI #1",
        "method": "UPI AutoPay",
        "date": "10 Jul 2026",
        "ref": "Mandate",
        "amount": 3250.0,
        "status": "paid"
      },
      {
        "label": "Initial Down Payment",
        "method": "POS Swipe",
        "date": "18 Jun 2026",
        "ref": "POS Swipe",
        "amount": 14999.0,
        "status": "settled"
      }
    ]
  }
}
```

---

#### 4. Update Customer Details (`PUT /customers/:id`)
Updates customer contact information or address.

- **Request Body**:
```json
{
  "name": "Amit Kumar Verma",
  "mobileNumber": "+91 98231 44521",
  "email": "amit.verma.updated@example.com",
  "address": "Flat 402, Kothrud Heights, Pune"
}
```

- **Response Body (200 OK)**:
```json
{
  "success": true,
  "message": "Customer updated successfully",
  "data": {
    "id": "64f1a2b3c4d5e6f7a8b9c0d3",
    "updatedAt": "2026-10-02T20:35:00.000Z"
  }
}
```

---

### 4.4 EMI Plan Management API (`/emi-plans`)

#### 1. Get EMI Plan Details (`GET /emi-plans/:id`)
Returns the complete structure of a specific EMI loan contract.

- **Path Parameters**: `id` (MongoDB ObjectId)
- **Response Body (200 OK)**:
```json
{
  "success": true,
  "message": "EMI Plan details retrieved",
  "data": {
    "id": "64f1a2b3c4d5e6f7a8b9c0d6",
    "customerId": "64f1a2b3c4d5e6f7a8b9c0d3",
    "customerName": "Amit Verma",
    "handsetModel": "Samsung Galaxy S23 5G",
    "totalAmount": 39000.0,
    "emiAmount": 3250.0,
    "totalInstallments": 12,
    "paidInstallments": 4,
    "remainingInstallments": 8,
    "status": "OVERDUE",
    "startDate": "2026-06-18T00:00:00.000Z",
    "nextDueDate": "2026-10-10T00:00:00.000Z"
  }
}
```

---

#### 2. Update EMI Plan Status (`PUT /emi-plans/:id`)
Updates EMI status (e.g. marking as CLEARED upon completion, issuing NOC, or changing status).

- **Request Body**:
```json
{
  "status": "CLEARED",
  "notes": "All 12 EMIs paid in full. NOC document issued."
}
```

- **Response Body (200 OK)**:
```json
{
  "success": true,
  "message": "EMI plan status updated to CLEARED",
  "data": {
    "id": "64f1a2b3c4d5e6f7a8b9c0d6",
    "status": "CLEARED",
    "updatedAt": "2026-10-02T20:36:00.000Z"
  }
}
```

---

### 4.5 Payment Processing API (`/payments`)

#### 1. Record New Payment (`POST /payments`)
Records a payment for an EMI installment or down payment. After saving, automatically updates `paidInstallments` on the `EmiPlan` document using `$inc` and sets status to `CLEARED` if all installments are paid.

- **Request Body**:
```json
{
  "customerId": "64f1a2b3c4d5e6f7a8b9c0d3",
  "emiPlanId": "64f1a2b3c4d5e6f7a8b9c0d6",
  "amount": 3250.0,
  "paymentMethod": "UPI",
  "installmentNumber": 5,
  "paymentDate": "2026-10-02T20:30:00.000Z",
  "transactionReference": "UPI/390192810928/PAY",
  "notes": "Collected at counter"
}
```

- **Response Body (201 Created)**:
```json
{
  "success": true,
  "message": "Payment recorded successfully",
  "data": {
    "id": "64f1a2b3c4d5e6f7a8b9c0d7",
    "customerId": "64f1a2b3c4d5e6f7a8b9c0d3",
    "customerName": "Amit Verma",
    "emiPlanId": "64f1a2b3c4d5e6f7a8b9c0d6",
    "amount": 3250.0,
    "method": "UPI",
    "installmentNumber": 5,
    "paymentDate": "2026-10-02T20:30:00.000Z",
    "status": "PAID",
    "receiptUrl": "https://api.example.com/receipts/64f1a2b3c4d5e6f7a8b9c0d7.pdf"
  }
}
```

---

#### 2. Get Payment History Ledger (`GET /payments`)
Fetches all recorded payment transactions for the store with pagination.

- **Query Parameters**:
  - `page` (integer, default: 1)
  - `limit` (integer, default: 20)
  - `search` (string, optional)
  - `emiPlanId` (string, optional)
  - `customerId` (string, optional)

- **Response Body (200 OK)**:
```json
{
  "success": true,
  "message": "Payment history retrieved",
  "data": {
    "items": [
      {
        "id": "64f1a2b3c4d5e6f7a8b9c0d7",
        "customerId": "64f1a2b3c4d5e6f7a8b9c0d3",
        "customerName": "Amit Verma",
        "emiPlanId": "64f1a2b3c4d5e6f7a8b9c0d6",
        "amount": 3250.0,
        "method": "UPI",
        "installmentNumber": 5,
        "paymentDate": "2026-10-02T20:30:00.000Z",
        "status": "PAID"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 1,
      "totalCount": 1,
      "hasMore": false
    }
  }
}
```

---

#### 3. Get Payment Receipt Details (`GET /payments/:id`)
Fetches details and receipt breakdown for a single payment.

- **Path Parameters**: `id` (MongoDB ObjectId)
- **Response Body (200 OK)**:
```json
{
  "success": true,
  "message": "Payment details retrieved",
  "data": {
    "id": "64f1a2b3c4d5e6f7a8b9c0d7",
    "transactionRef": "REC-9821",
    "customer": {
      "id": "64f1a2b3c4d5e6f7a8b9c0d3",
      "name": "Amit Verma",
      "phone": "+91 98231 44521"
    },
    "device": {
      "model": "Samsung Galaxy S23 5G",
      "imei": "358921094831034"
    },
    "installmentLabel": "EMI #4",
    "amountPaid": 3250.0,
    "paymentMethod": "UPI Paid",
    "paymentDate": "2026-10-02T20:30:00.000Z",
    "remainingOutstanding": 22750.0
  }
}
```

---

### 4.6 Analytics & Reports API (`/reports`)

#### 1. Get Reports Summary Metrics (`GET /reports/summary`)
Returns aggregated store analytics using MongoDB aggregation pipelines.

- **Request Body**: None
- **Response Body (200 OK)**:
```json
{
  "success": true,
  "message": "Reports summary fetched",
  "data": {
    "totalRevenue": 2485000.0,
    "monthlyRevenue": 184500.0,
    "totalCustomers": 142,
    "activeEmiPlans": 86,
    "collectionRate": 94.2,
    "overdueAmount": 32000.0
  }
}
```

---

#### 2. Get Monthly Collection vs Pending Trend (`GET /reports/monthly-trend`)
Provides monthly breakdown using MongoDB `$group` and `$project` aggregation stages.

- **Query Parameters**:
  - `year` (integer, optional e.g. 2026)

- **Response Body (200 OK)**:
```json
{
  "success": true,
  "message": "Monthly trend retrieved",
  "data": [
    { "month": "May", "collected": 150000.0, "pending": 20000.0 },
    { "month": "Jun", "collected": 165000.0, "pending": 18000.0 },
    { "month": "Jul", "collected": 172000.0, "pending": 22000.0 },
    { "month": "Aug", "collected": 180000.0, "pending": 25000.0 },
    { "month": "Sep", "collected": 184500.0, "pending": 32000.0 }
  ]
}
```

---

#### 3. Get Weekly Collection Analytics (`GET /reports/weekly-collection`)

- **Response Body (200 OK)**:
```json
{
  "success": true,
  "message": "Weekly collection retrieved",
  "data": [
    { "week": "Week 1", "amount": 42000.0 },
    { "week": "Week 2", "amount": 48500.0 },
    { "week": "Week 3", "amount": 45000.0 },
    { "week": "Week 4", "amount": 49000.0 }
  ]
}
```

---

#### 4. Get Smartphone Brand Breakdown (`GET /reports/smartphones`)
Returns volume and total monetary value of smartphones sold on EMI grouped by brand, using MongoDB `$group` aggregation.

- **Response Body (200 OK)**:
```json
{
  "success": true,
  "message": "Smartphone breakdown retrieved",
  "data": [
    { "brand": "Samsung", "count": 48, "totalValue": 1240000.0 },
    { "brand": "Apple", "count": 22, "totalValue": 1870000.0 },
    { "brand": "OnePlus", "count": 30, "totalValue": 900000.0 },
    { "brand": "Xiaomi/Redmi", "count": 26, "totalValue": 390000.0 },
    { "brand": "Vivo/Oppo", "count": 16, "totalValue": 320000.0 }
  ]
}
```

---

### 4.7 Super Admin & Store Management API (`/admin`)

*Note: All `/admin/*` endpoints require the authenticated user's role to be `SUPER_ADMIN`.*

#### 1. Platform Super Admin Dashboard (`GET /admin/dashboard`)

- **Response Body (200 OK)**:
```json
{
  "success": true,
  "message": "Admin dashboard metrics retrieved",
  "data": {
    "totalStores": 24,
    "activeStores": 22,
    "suspendedStores": 2,
    "totalPlatformCustomers": 3410,
    "totalPlatformCollection": 42800000.0
  }
}
```

---

#### 2. List Registered Stores (`GET /admin/stores`)

- **Query Parameters**: `page`, `limit`, `search`
- **Response Body (200 OK)**:
```json
{
  "success": true,
  "message": "Stores retrieved",
  "data": {
    "items": [
      {
        "id": "64f1a2b3c4d5e6f7a8b9c0d2",
        "name": "Shree Ganesh Mobiles",
        "ownerName": "Rajesh Ji",
        "mobileNumber": "9823011223",
        "status": "ACTIVE",
        "email": "ganesh.mobiles@example.com",
        "address": "Ganesh Nagar, Pune",
        "totalCustomers": 142,
        "totalCollection": 184500.0
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 1,
      "totalCount": 1,
      "hasMore": false
    }
  }
}
```

---

#### 3. Register New Store Account (`POST /admin/stores`)

- **Request Body**:
```json
{
  "storeName": "Sai Mobile Hub",
  "ownerName": "Suresh Patel",
  "mobileNumber": "9876543210",
  "password": "InitialPassword123!",
  "email": "saimobiles@example.com",
  "address": "FC Road, Pune"
}
```

- **Response Body (201 Created)**:
```json
{
  "success": true,
  "message": "Store created successfully",
  "data": {
    "storeId": "64f1a2b3c4d5e6f7a8b9c0d8",
    "ownerUserId": "64f1a2b3c4d5e6f7a8b9c0d9",
    "createdAt": "2026-10-02T20:30:00.000Z"
  }
}
```

---

#### 4. Update Store Account Status (`PUT /admin/stores/:id/status`)
Activates or suspends a store tenant.

- **Request Body**:
```json
{
  "status": "SUSPENDED",
  "reason": "Payment overdue for platform subscription"
}
```

- **Response Body (200 OK)**:
```json
{
  "success": true,
  "message": "Store status updated to SUSPENDED",
  "data": {
    "storeId": "64f1a2b3c4d5e6f7a8b9c0d2",
    "status": "SUSPENDED"
  }
}
```

---

#### 5. Reset Store Owner Password (`PUT /admin/stores/:id/password`)

- **Request Body**:
```json
{
  "newPassword": "NewSecurePassword123!"
}
```

- **Response Body (200 OK)**:
```json
{
  "success": true,
  "message": "Store password reset successfully",
  "data": null
}
```

---

#### 6. Update Store Theme & Custom Branding (`PUT /admin/stores/:id/theme`)

- **Request Body**:
```json
{
  "primaryColor": "#6C5CE7",
  "secondaryColor": "#111827",
  "accentColor": "#F59E0B",
  "backgroundColor": "#F8FAFC",
  "logoUrl": "https://cdn.example.com/stores/64f1a2b3c4d5e6f7a8b9c0d2/logo.png"
}
```

- **Response Body (200 OK)**:
```json
{
  "success": true,
  "message": "Store theme updated successfully",
  "data": {
    "primaryColor": "#6C5CE7",
    "secondaryColor": "#111827",
    "accentColor": "#F59E0B",
    "backgroundColor": "#F8FAFC",
    "logoUrl": "https://cdn.example.com/stores/64f1a2b3c4d5e6f7a8b9c0d2/logo.png"
  }
}
```

---

## 5. MongoDB Database Schema (Mongoose Models)

The backend uses **5 MongoDB collections** modeled with Mongoose. All documents include auto-generated `_id` (ObjectId) by MongoDB. Multi-tenancy is enforced by a `storeId` field present in `Customer`, `EmiPlan`, and `Payment` collections.

---

### 5.1 `stores` Collection — `Store.model.js`

```js
const mongoose = require('mongoose');

const themeSchema = new mongoose.Schema({
  primaryColor:    { type: String, default: '#6C5CE7' },
  secondaryColor:  { type: String, default: '#111827' },
  accentColor:     { type: String, default: '#F59E0B' },
  backgroundColor: { type: String, default: '#F8FAFC' },
  logoUrl:         { type: String, default: null },
}, { _id: false });

const storeSchema = new mongoose.Schema({
  name:         { type: String, required: true, trim: true },
  address:      { type: String, required: true },
  email:        { type: String, default: null },
  mobileNumber: { type: String, required: true, unique: true },
  status:       { type: String, enum: ['ACTIVE', 'SUSPENDED'], default: 'ACTIVE' },
  theme:        { type: themeSchema, default: () => ({}) },
}, { timestamps: true });

module.exports = mongoose.model('Store', storeSchema);
```

---

### 5.2 `users` Collection — `User.model.js`

```js
const mongoose = require('mongoose');
const bcrypt   = require('bcryptjs');

const userSchema = new mongoose.Schema({
  storeId:         { type: mongoose.Schema.Types.ObjectId, ref: 'Store', required: true },
  name:            { type: String, required: true, trim: true },
  mobileNumber:    { type: String, required: true, unique: true },
  password:        { type: String, required: true },
  role:            { type: String, enum: ['STORE_OWNER', 'SUPER_ADMIN'], default: 'STORE_OWNER' },
  profileImageUrl: { type: String, default: null },
  isActive:        { type: Boolean, default: true },
}, { timestamps: true });

// Hash password before saving
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 10);
  next();
});

// Instance method to compare passwords
userSchema.methods.comparePassword = function (plain) {
  return bcrypt.compare(plain, this.password);
};

module.exports = mongoose.model('User', userSchema);
```

---

### 5.3 `customers` Collection — `Customer.model.js`

```js
const mongoose = require('mongoose');

const customerSchema = new mongoose.Schema({
  storeId:       { type: mongoose.Schema.Types.ObjectId, ref: 'Store', required: true, index: true },
  fullName:      { type: String, required: true, trim: true },
  mobileNumber:  { type: String, required: true },
  email:         { type: String, default: null },
  address:       { type: String, required: true },
  aadhaarNumber: { type: String, default: null },
  trustScore:    { type: Number, default: 50, min: 0, max: 100 },
  isActive:      { type: Boolean, default: true },
}, { timestamps: true });

// Compound index for multi-tenant search
customerSchema.index({ storeId: 1, mobileNumber: 1 });
customerSchema.index({ storeId: 1, fullName: 'text', mobileNumber: 'text' });

module.exports = mongoose.model('Customer', customerSchema);
```

---

### 5.4 `emiplans` Collection — `EmiPlan.model.js`

```js
const mongoose = require('mongoose');

const emiPlanSchema = new mongoose.Schema({
  storeId:    { type: mongoose.Schema.Types.ObjectId, ref: 'Store',    required: true, index: true },
  customerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Customer', required: true, index: true },

  // Device Info
  handsetBrand:  { type: String, required: true },
  handsetModel:  { type: String, required: true },
  variant:       { type: String, default: null },
  imei:          { type: String, required: true, unique: true },
  serialNumber:  { type: String, default: null },
  notes:         { type: String, default: null },

  // Financial Terms
  sellingPrice:       { type: Number, required: true },
  downPayment:        { type: Number, required: true },
  loanAmount:         { type: Number, required: true },
  tenureMonths:       { type: Number, required: true },
  monthlyInstallment: { type: Number, required: true },
  firstEmiDueDate:    { type: Date,   required: true },

  // Tracking
  paidInstallments: { type: Number, default: 0 },
  status: {
    type: String,
    enum: ['ON_TRACK', 'DUE_TODAY', 'OVERDUE', 'CLEARED'],
    default: 'ON_TRACK',
  },
  isDefaulted:  { type: Boolean, default: false },
  notes_admin:  { type: String, default: null },
}, { timestamps: true });

module.exports = mongoose.model('EmiPlan', emiPlanSchema);
```

---

### 5.5 `payments` Collection — `Payment.model.js`

```js
const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
  storeId:    { type: mongoose.Schema.Types.ObjectId, ref: 'Store',    required: true, index: true },
  customerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Customer', required: true },
  emiPlanId:  { type: mongoose.Schema.Types.ObjectId, ref: 'EmiPlan',  required: true },

  amount:               { type: Number, required: true },
  paymentMethod: {
    type: String,
    enum: ['CASH', 'UPI', 'UPI_AUTOPAY', 'POS_CARD'],
    required: true,
  },
  installmentNumber:    { type: Number, required: true }, // 0 = Down Payment
  paymentDate:          { type: Date,   required: true },
  transactionReference: { type: String, default: null },
  receiptId:            { type: String, default: null },
  notes:                { type: String, default: null },
  status: {
    type: String,
    enum: ['PAID', 'SETTLED', 'PENDING'],
    default: 'PAID',
  },
}, { timestamps: true });

paymentSchema.index({ storeId: 1, customerId: 1 });
paymentSchema.index({ storeId: 1, emiPlanId: 1 });

module.exports = mongoose.model('Payment', paymentSchema);
```

---

### 5.6 Collection Relationship Diagram

```
┌─────────────────────┐        ┌──────────────────────┐
│       stores        │ 1───N  │        users          │
├─────────────────────┤        ├──────────────────────┤
│ _id (ObjectId)      │        │ _id (ObjectId)       │
│ name                │        │ storeId (ObjectId→)  │
│ address             │        │ name                 │
│ mobileNumber        │        │ mobileNumber         │
│ status (ENUM)       │        │ password (hashed)    │
│ theme (embedded doc)│        │ role (ENUM)          │
└─────────────────────┘        └──────────────────────┘
          │ 1
          │
          │ N
┌─────────┴───────────┐
│      customers      │
├─────────────────────┤
│ _id (ObjectId)      │
│ storeId (ObjectId→) │
│ fullName            │
│ mobileNumber        │
│ address             │
│ trustScore (0-100)  │
│ isActive            │
└─────────┬───────────┘
          │ 1
          │
          │ N
┌─────────┴───────────┐
│      emiplans       │
├─────────────────────┤
│ _id (ObjectId)      │
│ storeId (ObjectId→) │
│ customerId (Obj→)   │
│ handsetBrand        │
│ handsetModel        │
│ imei (unique)       │
│ loanAmount          │
│ tenureMonths        │
│ monthlyInstallment  │
│ paidInstallments    │
│ status (ENUM)       │
└─────────┬───────────┘
          │ 1
          │
          │ N
┌─────────┴───────────┐
│      payments       │
├─────────────────────┤
│ _id (ObjectId)      │
│ storeId (ObjectId→) │
│ customerId (Obj→)   │
│ emiPlanId (Obj→)    │
│ amount              │
│ paymentMethod (ENUM)│
│ installmentNumber   │
│ paymentDate         │
│ transactionReference│
│ status (ENUM)       │
└─────────────────────┘
```

---

## 6. Security & Multi-Tenancy Rules

1. **Store Tenant Isolation**:
   - All MongoDB queries for `customers`, `emiplans`, and `payments` **MUST** include a `storeId` filter extracted from the authenticated user's decoded JWT payload.
   - The middleware attaches `storeId` to `req.user.storeId`. Controllers always query with `{ storeId: req.user.storeId }` unless role is `SUPER_ADMIN`.
2. **JWT Authentication Middleware** (`auth.middleware.js`):
   ```js
   const jwt = require('jsonwebtoken');

   const protect = (req, res, next) => {
     const token = req.headers.authorization?.split(' ')[1];
     if (!token) return res.status(401).json({ success: false, message: 'Unauthorized' });
     try {
       const decoded = jwt.verify(token, process.env.JWT_SECRET);
       req.user = decoded; // { userId, storeId, role }
       next();
     } catch {
       res.status(401).json({ success: false, message: 'Invalid or expired token' });
     }
   };

   const authorizeRole = (...roles) => (req, res, next) => {
     if (!roles.includes(req.user.role))
       return res.status(403).json({ success: false, message: 'Access forbidden' });
     next();
   };

   module.exports = { protect, authorizeRole };
   ```
3. **Password Security**:
   - Passwords are hashed using `bcryptjs` with a salt round of **10** before persistence, handled in the `User` model `pre('save')` hook.
4. **Data Integrity on Payment**:
   - After recording a payment, the controller **atomically** increments `paidInstallments` using `$inc` and sets status to `CLEARED` if all installments are paid:
   ```js
   await EmiPlan.findByIdAndUpdate(emiPlanId, {
     $inc: { paidInstallments: 1 },
     ...(newPaidCount === tenureMonths && { status: 'CLEARED' }),
   });
   ```
5. **MongoDB Indexes**:
   - All `storeId` fields are indexed for fast multi-tenant query scoping.
   - Compound indexes on `{ storeId, mobileNumber }` and `{ storeId, emiPlanId }` ensure efficient lookups.
   - A text index on `{ fullName, mobileNumber }` in `customers` enables full-text search.
