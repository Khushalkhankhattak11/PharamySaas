# PharmaCare SaaS - Multi-Tenant Pharmacy Management System

A production-grade, multi-tenant Pharmacy Management SaaS built with Flutter (Android, iOS, Web) and Supabase. Features role-based access control, strict Row Level Security (RLS), approval workflows, FEFO (First-Expiry-First-Out) inventory & sales, POS billing, receipt & QR label printing, Supabase Edge Functions, daily pg_cron stock alerts, and Firebase Cloud Messaging (FCM).

---

## 🌟 Key Features

1. **Multi-Tenant Architecture**: Complete tenant isolation at both the database layer (PostgreSQL Row Level Security) and application routing layer (`go_router` guards).
2. **Four Distinct User Roles**:
   - **Super Admin**: Platform oversight, approve/reject/suspend pharmacies, aggregate analytics, subscription plans.
   - **Admin (Pharmacy Owner)**: Full pharmacy operations, staff management, inventory, purchases, POS, profit/loss reports, settings.
   - **Storekeeper**: Inventory, batch tracking, suppliers, purchases (stock-in), stock adjustments, QR label generation & printing, stock scanner. *Zero access to POS or purchase cost/profit data.*
   - **Cashier**: High-speed POS billing, QR/barcode scanning, receipt printing/reprinting, personal sales history. *Zero access to purchase costs, margins, or inventory edits.*
3. **Onboarding & Approval Lifecycle**:
   - Pharmacy owner signs up and submits pharmacy license details & documentation.
   - System places pharmacy in `pending` status. Staff and owners are restricted to the `Waiting for Approval` screen.
   - Super Admin reviews submitted license and approves/rejects with audit logging.
4. **FEFO Inventory & Sales Engine**:
   - Atomic database RPC (`create_sale`) automatically allocates items from batches with earliest expiry first.
   - Automatically prevents sales of expired or depleted batches.
   - Line items split transparently across batches if needed.
5. **Hardware & Printing Support**:
   - **Thermal Receipts**: 80mm roll format via direct PDF rendering or Bluetooth thermal printers (ESC/POS).
   - **QR Medicine & Batch Labels**: 50x30mm thermal label, 80mm roll, and A4 multi-label sheets.
   - **Barcode & QR Scanning**: Integrated camera scanner (mobile & web) + continuous USB/Bluetooth keyboard-wedge scanner support.
6. **Automated Alerts & Edge Functions**:
   - Daily automated batch expiry & low-stock checks scheduled via `pg_cron` invoking Supabase Edge Functions.
   - Secure staff creation and credential provisioning via Edge Functions using the Supabase Service Role key.

---

## 🏗️ Tech Stack

- **Frontend**: Flutter (3.24+ / Material 3), Riverpod (`flutter_riverpod`), `go_router`
- **Backend**: Supabase (PostgreSQL 15, Auth, Row Level Security, Storage, Edge Functions, pg_cron)
- **Printing**: `pdf`, `printing`, `print_bluetooth_thermal`, `esc_pos_utils_plus`
- **Scanning**: `mobile_scanner`, `qr_flutter`
- **Charts & Reporting**: `fl_chart`, `excel` (XLSX export)
- **Push Notifications**: `firebase_messaging`

---

## 🚀 Step-by-Step Setup Guide

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed (version 3.24.0 or newer).
- [Supabase CLI](https://supabase.com/docs/guides/cli) installed (`brew install supabase/tap/supabase` or `npm install -g supabase`).
- A [Supabase](https://supabase.com) project or local Supabase instance.
- A [Firebase](https://console.firebase.google.com) project for push notifications.

---

### 2. Database Migrations

Apply the migration scripts located in `supabase/migrations/` in ascending sequence. You can run them via the Supabase Dashboard SQL Editor or via the Supabase CLI (`supabase db push` / `supabase migration up`).

1. `supabase/migrations/001_initial_schema.sql`
   - Creates enums (`user_role`, `approval_status`, `notification_type`).
   - Creates all 12 core tables: `pharmacies`, `profiles`, `approval_logs`, `medicines`, `suppliers`, `purchases`, `batches`, `sales`, `sale_items`, `notifications`, `device_tokens`, `stock_adjustments`.
   - Creates composite indexes for tenant queries, barcodes, QR codes, and expiry tracking.

2. `supabase/migrations/002_rls_and_security.sql`
   - Enables Row Level Security (RLS) on all tables.
   - Implements `SECURITY DEFINER` context functions:
     - `current_pharmacy_id()`
     - `current_role()`
     - `pharmacy_is_approved()`
     - `is_super_admin()`
   - Creates storage buckets (`pharmacy-docs`, `pharmacy-logos`) with tenant policies.

3. `supabase/migrations/003_business_logic_rpcs.sql`
   - Triggers for automatic unique QR code generation (`PH-<timestamp>-<hash>`).
   - Atomic RPC functions:
     - `register_pharmacy(...)`
     - `review_pharmacy(...)`
     - `lookup_by_code(...)` (scans QR or barcode with role-based cost masking)
     - `create_sale(...)` (atomic FEFO stock allocation and deduction)

4. `supabase/migrations/004_views_and_reports.sql`
   - `medicines_pos_view` (cost-masked view for cashiers)
   - `medicine_stock` view
   - `low_stock_medicines` view
   - `expiring_batches` view
   - `platform_stats` view (Super Admin platform aggregates)
   - `monthly_sales_report(month, year)` RPC

5. `supabase/migrations/005_seed_data.sql`
   - Seeds Super Admin account.
   - Seeds a pre-approved pharmacy ("City Central Pharmacy").
   - Seeds Admin, Storekeeper, and Cashier accounts.
   - Seeds sample medicines, batches, suppliers, and past sales.

---

### 3. Super Admin & Pre-Seeded Accounts

The database seed (`005_seed_data.sql`) pre-provisions standard testing accounts. All accounts share the password: `Password123!`

| Role | Email | Scope |
| :--- | :--- | :--- |
| **Super Admin** | `superadmin@pharmacare.com` | Platform Owner (Approvals, Plans, Platform Stats) |
| **Admin (Owner)** | `admin@citycentral.com` | City Central Pharmacy (Full Control) |
| **Storekeeper** | `storekeeper@citycentral.com` | City Central Pharmacy (Inventory & Purchases) |
| **Cashier** | `cashier@citycentral.com` | City Central Pharmacy (POS & Receipts) |

#### Creating a Super Admin Manually (Production)
Super Admins cannot sign up through public registration. In production:
1. Create a user via Supabase Dashboard -> **Authentication** -> **Users** -> **Add user**.
2. Run this SQL in the Supabase SQL Editor:
```sql
UPDATE public.profiles
SET role = 'super_admin',
    pharmacy_id = NULL,
    is_active = TRUE
WHERE id = '<USER_AUTH_UUID>';
```

---

### 4. Deploying Supabase Edge Functions

The `supabase/functions/` directory contains serverless TypeScript functions executed with the `SUPABASE_SERVICE_ROLE_KEY`:

- `create-staff`: Validates caller is an approved pharmacy Admin, provisions user in Supabase Auth, and creates profile.
- `update-staff`: Updates staff phone, full name, or active status.
- `deactivate-staff`: Toggles `is_active = false`.
- `reset-staff-password`: Resets a staff member's password securely.
- `daily-stock-check`: Scans for expiring batches (<= 30 days) and low stock, writing in-app notifications and sending push alerts.

To deploy all functions to your Supabase project:
```bash
supabase login
supabase link --project-ref <YOUR_PROJECT_REF>

supabase functions deploy create-staff
supabase functions deploy update-staff
supabase functions deploy deactivate-staff
supabase functions deploy reset-staff-password
supabase functions deploy daily-stock-check
```

---

### 5. Automated Daily Stock Alerts (`pg_cron`)

Enable the `pg_cron` and `pg_net` extensions in your Supabase project under **Database** -> **Extensions**.

Then schedule the daily check to run every morning at 08:00 UTC by executing:
```sql
SELECT cron.schedule(
  'daily-pharmacy-stock-check',
  '0 8 * * *',
  $$
  SELECT net.http_post(
    url := 'https://<YOUR_PROJECT_REF>.supabase.co/functions/v1/daily-stock-check',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer <YOUR_SERVICE_ROLE_KEY>'
    ),
    body := '{}'::jsonb
  );
  $$
);
```

---

### 6. Firebase Cloud Messaging (Push Notifications)

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com).
2. **Android**: Download `google-services.json` and place it in `android/app/`.
3. **iOS**: Download `GoogleService-Info.plist` and place it in `ios/Runner/`.
4. **Web**:
   - Generate a Web Push Certificate (VAPID Key) in Firebase Console under **Project Settings** -> **Cloud Messaging** -> **Web configuration**.
   - Update `web/firebase-messaging-sw.js` with your Firebase project config keys.
   - Put your VAPID key in `.env` as `FIREBASE_VAPID_KEY`.

---

### 7. Environment Configuration (`.env`)

Copy the example configuration file:
```bash
cp .env.example .env
```

Fill in the required values:
```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
FIREBASE_VAPID_KEY=your-firebase-web-push-vapid-key
SUPPORT_EMAIL=support@pharmacare.com
```

---

## 💻 Running the Application

### Fetch Dependencies & Verify
```bash
flutter pub get
flutter analyze
flutter test
```

### Run on Web
```bash
flutter run -d chrome
```

### Run on macOS Desktop
```bash
flutter run -d macos
```

### Run on Android Device / Emulator
```bash
flutter run -d android
```

### Run on iOS Simulator
```bash
flutter run -d ios
```

---

## 🧪 Test Suite

The project includes unit and widget test coverage for core business invariants:
- **`test/fefo_selection_test.dart`**: Validates earliest-expiry batch sorting, zero-quantity exclusion, and multi-batch quantity splitting.
- **`test/report_calculations_test.dart`**: Validates profit/margin arithmetic, month-over-month growth rates, and average transaction size calculations.
- **`test/route_guards_test.dart`**: Tests role-based and approval status redirects (Unauthenticated -> `/login`, Pending/Rejected -> `/approval-status`, Cashier blocked from `/inventory`, Super Admin locked to `/super-admin`).
- **`test/qr_lookup_test.dart`**: Validates QR and barcode lookup matching and cashier purchase cost masking.
- **`test/pos_widget_test.dart`**: Widget test validating the POS UI components, product grid, search bar, and empty cart state.

To execute all tests:
```bash
flutter test
```

---

## 🔒 Security Best Practices Implemented

1. **No Service Role Key in App**: The client application only possesses the public `SUPABASE_ANON_KEY`. Privileged actions (staff creation, password resets) run isolated inside Supabase Edge Functions.
2. **Cost-Price Masking**: Cashiers query `medicines_pos_view`, which physically omits purchase cost columns. Table-level column security prevents cashier accounts from viewing pharmacy profit margins.
3. **Approval Status Enforcement**: A user cannot query tenant business data if their pharmacy is not in `approved` status, enforced at both SQL RLS (`pharmacy_is_approved()`) and GoRouter navigation guards.
4. **Multi-Tenant Scoping**: All business table reads and writes are forced through `pharmacy_id = current_pharmacy_id()`. No tenant can read or write another tenant's data.
5. **Numeric Precision**: Monetary and financial fields utilize `NUMERIC(12, 2)` in Postgres to prevent IEEE-754 floating-point rounding inaccuracies.
# PharamySaas
