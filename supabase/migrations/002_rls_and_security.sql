-- ============================================================================
-- 002_rls_and_security.sql
-- Security Definer Helpers & Row Level Security (RLS)
-- ============================================================================

-- 1. SECURITY DEFINER HELPER FUNCTIONS

CREATE OR REPLACE FUNCTION public.current_pharmacy_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT pharmacy_id FROM public.profiles WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.current_role()
RETURNS user_role
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid()
          AND role = 'super_admin'
          AND is_active = true
    );
$$;

CREATE OR REPLACE FUNCTION public.pharmacy_is_approved()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 
        FROM public.profiles pr
        JOIN public.pharmacies ph ON ph.id = pr.pharmacy_id
        WHERE pr.id = auth.uid()
          AND pr.is_active = true
          AND ph.approval_status = 'approved'
          AND (ph.plan_expires_at IS NULL OR ph.plan_expires_at > now())
    );
$$;

-- 2. ENABLE ROW LEVEL SECURITY ON ALL TABLES

ALTER TABLE public.pharmacies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.approval_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medicines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_adjustments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pharmacy_invoice_counters ENABLE ROW LEVEL SECURITY;

-- 3. POLICIES: PHARMACIES
CREATE POLICY "super_admin_all_pharmacies"
    ON public.pharmacies FOR ALL
    TO authenticated
    USING (public.is_super_admin());

CREATE POLICY "users_read_own_pharmacy"
    ON public.pharmacies FOR SELECT
    TO authenticated
    USING (id = public.current_pharmacy_id());

CREATE POLICY "admin_update_own_pharmacy"
    ON public.pharmacies FOR UPDATE
    TO authenticated
    USING (
        id = public.current_pharmacy_id() 
        AND public.current_role() = 'admin' 
        AND public.pharmacy_is_approved()
    )
    WITH CHECK (
        id = public.current_pharmacy_id() 
        AND public.current_role() = 'admin'
    );

-- 4. POLICIES: PROFILES
CREATE POLICY "super_admin_all_profiles"
    ON public.profiles FOR ALL
    TO authenticated
    USING (public.is_super_admin());

CREATE POLICY "users_read_own_profile"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (id = auth.uid());

CREATE POLICY "users_update_own_profile"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

CREATE POLICY "admin_read_pharmacy_staff"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (
        pharmacy_id = public.current_pharmacy_id()
        AND public.current_role() = 'admin'
    );

CREATE POLICY "admin_update_pharmacy_staff"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING (
        pharmacy_id = public.current_pharmacy_id()
        AND public.current_role() = 'admin'
    );

-- 5. POLICIES: APPROVAL LOGS
CREATE POLICY "super_admin_approval_logs"
    ON public.approval_logs FOR ALL
    TO authenticated
    USING (public.is_super_admin());

CREATE POLICY "pharmacy_read_own_approval_logs"
    ON public.approval_logs FOR SELECT
    TO authenticated
    USING (pharmacy_id = public.current_pharmacy_id());

-- 6. POLICIES: MEDICINES
CREATE POLICY "read_medicines"
    ON public.medicines FOR SELECT
    TO authenticated
    USING (
        pharmacy_id = public.current_pharmacy_id()
        AND public.pharmacy_is_approved()
    );

CREATE POLICY "modify_medicines"
    ON public.medicines FOR ALL
    TO authenticated
    USING (
        pharmacy_id = public.current_pharmacy_id()
        AND public.pharmacy_is_approved()
        AND public.current_role() IN ('admin', 'storekeeper')
    )
    WITH CHECK (
        pharmacy_id = public.current_pharmacy_id()
        AND public.pharmacy_is_approved()
        AND public.current_role() IN ('admin', 'storekeeper')
    );

-- 7. POLICIES: SUPPLIERS
CREATE POLICY "manage_suppliers"
    ON public.suppliers FOR ALL
    TO authenticated
    USING (
        pharmacy_id = public.current_pharmacy_id()
        AND public.pharmacy_is_approved()
        AND public.current_role() IN ('admin', 'storekeeper')
    )
    WITH CHECK (
        pharmacy_id = public.current_pharmacy_id()
        AND public.pharmacy_is_approved()
        AND public.current_role() IN ('admin', 'storekeeper')
    );

-- 8. POLICIES: PURCHASES
CREATE POLICY "manage_purchases"
    ON public.purchases FOR ALL
    TO authenticated
    USING (
        pharmacy_id = public.current_pharmacy_id()
        AND public.pharmacy_is_approved()
        AND public.current_role() IN ('admin', 'storekeeper')
    )
    WITH CHECK (
        pharmacy_id = public.current_pharmacy_id()
        AND public.pharmacy_is_approved()
        AND public.current_role() IN ('admin', 'storekeeper')
    );

-- 9. POLICIES: BATCHES
CREATE POLICY "read_batches_staff"
    ON public.batches FOR SELECT
    TO authenticated
    USING (
        pharmacy_id = public.current_pharmacy_id()
        AND public.pharmacy_is_approved()
        AND public.current_role() IN ('admin', 'storekeeper')
    );

CREATE POLICY "modify_batches_staff"
    ON public.batches FOR ALL
    TO authenticated
    USING (
        pharmacy_id = public.current_pharmacy_id()
        AND public.pharmacy_is_approved()
        AND public.current_role() IN ('admin', 'storekeeper')
    )
    WITH CHECK (
        pharmacy_id = public.current_pharmacy_id()
        AND public.pharmacy_is_approved()
        AND public.current_role() IN ('admin', 'storekeeper')
    );

-- 10. POLICIES: SALES
CREATE POLICY "admin_all_sales"
    ON public.sales FOR ALL
    TO authenticated
    USING (
        pharmacy_id = public.current_pharmacy_id()
        AND public.pharmacy_is_approved()
        AND public.current_role() = 'admin'
    );

CREATE POLICY "cashier_read_own_sales"
    ON public.sales FOR SELECT
    TO authenticated
    USING (
        pharmacy_id = public.current_pharmacy_id()
        AND public.pharmacy_is_approved()
        AND cashier_id = auth.uid()
    );

-- 11. POLICIES: SALE ITEMS
CREATE POLICY "admin_all_sale_items"
    ON public.sale_items FOR ALL
    TO authenticated
    USING (
        pharmacy_id = public.current_pharmacy_id()
        AND public.pharmacy_is_approved()
        AND public.current_role() = 'admin'
    );

CREATE POLICY "cashier_read_own_sale_items"
    ON public.sale_items FOR SELECT
    TO authenticated
    USING (
        pharmacy_id = public.current_pharmacy_id()
        AND public.pharmacy_is_approved()
        AND EXISTS (
            SELECT 1 FROM public.sales s
            WHERE s.id = sale_items.sale_id
              AND s.cashier_id = auth.uid()
        )
    );

-- 12. POLICIES: STOCK ADJUSTMENTS
CREATE POLICY "manage_stock_adjustments"
    ON public.stock_adjustments FOR ALL
    TO authenticated
    USING (
        pharmacy_id = public.current_pharmacy_id()
        AND public.pharmacy_is_approved()
        AND public.current_role() IN ('admin', 'storekeeper')
    )
    WITH CHECK (
        pharmacy_id = public.current_pharmacy_id()
        AND public.pharmacy_is_approved()
        AND public.current_role() IN ('admin', 'storekeeper')
    );

-- 13. POLICIES: NOTIFICATIONS
CREATE POLICY "view_notifications"
    ON public.notifications FOR SELECT
    TO authenticated
    USING (
        (public.is_super_admin() AND pharmacy_id IS NULL)
        OR target_user_id = auth.uid()
        OR (
            pharmacy_id = public.current_pharmacy_id()
            AND (target_role IS NULL OR target_role = public.current_role())
        )
    );

CREATE POLICY "update_notifications"
    ON public.notifications FOR UPDATE
    TO authenticated
    USING (
        (public.is_super_admin() AND pharmacy_id IS NULL)
        OR target_user_id = auth.uid()
        OR (
            pharmacy_id = public.current_pharmacy_id()
            AND (target_role IS NULL OR target_role = public.current_role())
        )
    );

-- 14. POLICIES: DEVICE TOKENS
CREATE POLICY "manage_own_device_tokens"
    ON public.device_tokens FOR ALL
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- 15. STORAGE BUCKETS SETUP
INSERT INTO storage.buckets (id, name, public) 
VALUES 
    ('pharmacy-docs', 'pharmacy-docs', false),
    ('pharmacy-logos', 'pharmacy-logos', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies:
CREATE POLICY "authenticated_upload_docs"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id IN ('pharmacy-docs', 'pharmacy-logos'));

CREATE POLICY "public_read_logos"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'pharmacy-logos');

CREATE POLICY "authorized_read_docs"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'pharmacy-docs' 
        AND (
            public.is_super_admin() 
            OR (storage.foldername(name))[1] = public.current_pharmacy_id()::text
            OR (storage.foldername(name))[1] = 'licenses'
        )
    );

