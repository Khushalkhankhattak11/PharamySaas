-- ============================================================================
-- 001_initial_schema.sql
-- PharmaCare Multi-tenant SaaS Database Schema
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Custom ENUM types
DO $$ BEGIN
    CREATE TYPE pharmacy_approval_status AS ENUM ('pending', 'approved', 'rejected', 'suspended');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('super_admin', 'admin', 'cashier', 'storekeeper');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE notification_type AS ENUM (
        'low_stock',
        'expiring_soon',
        'expired',
        'new_pharmacy',
        'pharmacy_approved',
        'pharmacy_rejected',
        'pharmacy_suspended'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- 1. Pharmacies Table
CREATE TABLE IF NOT EXISTS public.pharmacies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    address TEXT,
    city TEXT,
    phone TEXT,
    license_no TEXT,
    license_doc_url TEXT,
    logo_url TEXT,
    currency VARCHAR(10) NOT NULL DEFAULT 'USD',
    receipt_header TEXT,
    receipt_footer TEXT,
    approval_status pharmacy_approval_status NOT NULL DEFAULT 'pending',
    rejection_reason TEXT,
    approved_by UUID,
    approved_at TIMESTAMPTZ,
    plan TEXT DEFAULT 'Standard',
    plan_expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 2. Profiles Table (extends auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    pharmacy_id UUID REFERENCES public.pharmacies(id) ON DELETE SET NULL,
    role user_role NOT NULL DEFAULT 'cashier',
    full_name TEXT NOT NULL,
    phone TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 3. Approval Logs
CREATE TABLE IF NOT EXISTS public.approval_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pharmacy_id UUID NOT NULL REFERENCES public.pharmacies(id) ON DELETE CASCADE,
    action TEXT NOT NULL, -- 'approved', 'rejected', 'suspended', 'reactivated'
    reason TEXT,
    acted_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 4. Medicines
CREATE TABLE IF NOT EXISTS public.medicines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pharmacy_id UUID NOT NULL REFERENCES public.pharmacies(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    generic_name TEXT,
    category TEXT,
    manufacturer TEXT,
    barcode TEXT, -- Manufacturer barcode (optional)
    qr_code TEXT NOT NULL, -- System generated unique QR code
    unit VARCHAR(50) NOT NULL DEFAULT 'Strip', -- 'Strip', 'Tablet', 'Bottle', 'Box', etc.
    sale_price NUMERIC(12, 2) NOT NULL CHECK (sale_price >= 0),
    min_stock_level INT NOT NULL DEFAULT 10 CHECK (min_stock_level >= 0),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_medicine_qr UNIQUE (pharmacy_id, qr_code)
);

-- 5. Suppliers
CREATE TABLE IF NOT EXISTS public.suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pharmacy_id UUID NOT NULL REFERENCES public.pharmacies(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT,
    address TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 6. Purchases (Stock-In)
CREATE TABLE IF NOT EXISTS public.purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pharmacy_id UUID NOT NULL REFERENCES public.pharmacies(id) ON DELETE CASCADE,
    supplier_id UUID REFERENCES public.suppliers(id) ON DELETE SET NULL,
    invoice_no TEXT,
    total NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (total >= 0),
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 7. Batches (Inventory items with Expiry)
CREATE TABLE IF NOT EXISTS public.batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pharmacy_id UUID NOT NULL REFERENCES public.pharmacies(id) ON DELETE CASCADE,
    medicine_id UUID NOT NULL REFERENCES public.medicines(id) ON DELETE CASCADE,
    purchase_id UUID REFERENCES public.purchases(id) ON DELETE SET NULL,
    batch_no TEXT NOT NULL,
    qr_code TEXT NOT NULL, -- Batch unique QR
    expiry_date DATE NOT NULL,
    quantity INT NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    purchase_price NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (purchase_price >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_batch_qr UNIQUE (pharmacy_id, qr_code)
);

-- 8. Sales
CREATE TABLE IF NOT EXISTS public.sales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pharmacy_id UUID NOT NULL REFERENCES public.pharmacies(id) ON DELETE CASCADE,
    invoice_no BIGINT NOT NULL,
    cashier_id UUID REFERENCES auth.users(id),
    subtotal NUMERIC(12, 2) NOT NULL CHECK (subtotal >= 0),
    discount NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (discount >= 0),
    total NUMERIC(12, 2) NOT NULL CHECK (total >= 0),
    payment_method VARCHAR(50) NOT NULL DEFAULT 'Cash',
    customer_name TEXT DEFAULT 'Walk-in Customer',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_pharmacy_invoice UNIQUE (pharmacy_id, invoice_no)
);

-- Auto-incrementing invoice number sequence helper table
CREATE TABLE IF NOT EXISTS public.pharmacy_invoice_counters (
    pharmacy_id UUID PRIMARY KEY REFERENCES public.pharmacies(id) ON DELETE CASCADE,
    last_invoice_no BIGINT NOT NULL DEFAULT 1000
);

-- 9. Sale Items
CREATE TABLE IF NOT EXISTS public.sale_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_id UUID NOT NULL REFERENCES public.sales(id) ON DELETE CASCADE,
    pharmacy_id UUID NOT NULL REFERENCES public.pharmacies(id) ON DELETE CASCADE,
    medicine_id UUID NOT NULL REFERENCES public.medicines(id),
    batch_id UUID NOT NULL REFERENCES public.batches(id),
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12, 2) NOT NULL CHECK (unit_price >= 0),
    cost_price NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (cost_price >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 10. Notifications
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pharmacy_id UUID REFERENCES public.pharmacies(id) ON DELETE CASCADE,
    target_role user_role, -- e.g. notify all 'admin' or 'storekeeper'
    target_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    type notification_type NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    medicine_id UUID REFERENCES public.medicines(id) ON DELETE SET NULL,
    batch_id UUID REFERENCES public.batches(id) ON DELETE SET NULL,
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 11. Device Tokens (FCM)
CREATE TABLE IF NOT EXISTS public.device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    pharmacy_id UUID REFERENCES public.pharmacies(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    platform VARCHAR(50) NOT NULL, -- 'android', 'ios', 'web'
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_user_device UNIQUE (user_id, fcm_token)
);

-- 12. Stock Adjustments (Damage, Expired write-off, Correction)
CREATE TABLE IF NOT EXISTS public.stock_adjustments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pharmacy_id UUID NOT NULL REFERENCES public.pharmacies(id) ON DELETE CASCADE,
    batch_id UUID NOT NULL REFERENCES public.batches(id) ON DELETE CASCADE,
    quantity_change INT NOT NULL, -- can be negative (damage/expired) or positive (count correction)
    reason TEXT NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_pharmacies_approval_status ON public.pharmacies(approval_status);
CREATE INDEX IF NOT EXISTS idx_profiles_pharmacy_id ON public.profiles(pharmacy_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

CREATE INDEX IF NOT EXISTS idx_medicines_pharmacy_id ON public.medicines(pharmacy_id);
CREATE INDEX IF NOT EXISTS idx_medicines_qr_code ON public.medicines(pharmacy_id, qr_code);
CREATE INDEX IF NOT EXISTS idx_medicines_barcode ON public.medicines(pharmacy_id, barcode);
CREATE INDEX IF NOT EXISTS idx_medicines_is_active ON public.medicines(pharmacy_id, is_active);

CREATE INDEX IF NOT EXISTS idx_batches_pharmacy_id ON public.batches(pharmacy_id);
CREATE INDEX IF NOT EXISTS idx_batches_medicine_id ON public.batches(medicine_id);
CREATE INDEX IF NOT EXISTS idx_batches_expiry_date ON public.batches(expiry_date);
CREATE INDEX IF NOT EXISTS idx_batches_qr_code ON public.batches(pharmacy_id, qr_code);

CREATE INDEX IF NOT EXISTS idx_sales_pharmacy_id ON public.sales(pharmacy_id);
CREATE INDEX IF NOT EXISTS idx_sales_created_at ON public.sales(pharmacy_id, created_at);
CREATE INDEX IF NOT EXISTS idx_sales_invoice_no ON public.sales(pharmacy_id, invoice_no);

CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id ON public.sale_items(sale_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_medicine_id ON public.sale_items(medicine_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_pharmacy_id ON public.sale_items(pharmacy_id);

CREATE INDEX IF NOT EXISTS idx_notifications_pharmacy_id ON public.notifications(pharmacy_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(target_user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at);

CREATE INDEX IF NOT EXISTS idx_device_tokens_user_id ON public.device_tokens(user_id);

