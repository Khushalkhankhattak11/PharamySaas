-- ============================================================================
-- 003_business_logic_rpcs.sql
-- Auto QR Generation, Registration, Review, FEFO Sale & Code Lookup
-- ============================================================================

-- 1. HELPER: GENERATE RANDOM SHORT CODE
CREATE OR REPLACE FUNCTION public.generate_unique_code(prefix TEXT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    result TEXT := prefix || '-';
    i INT;
BEGIN
    FOR i IN 1..8 LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
    END LOOP;
    RETURN result;
END;
$$;

-- 2. TRIGGER: AUTO-GENERATE QR CODES FOR MEDICINES & BATCHES
CREATE OR REPLACE FUNCTION public.trg_generate_medicine_qr()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.qr_code IS NULL OR trim(NEW.qr_code) = '' THEN
        NEW.qr_code := public.generate_unique_code('MED');
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_medicine_qr ON public.medicines;
CREATE TRIGGER trg_medicine_qr
BEFORE INSERT ON public.medicines
FOR EACH ROW
EXECUTE FUNCTION public.trg_generate_medicine_qr();

CREATE OR REPLACE FUNCTION public.trg_generate_batch_qr()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.qr_code IS NULL OR trim(NEW.qr_code) = '' THEN
        NEW.qr_code := public.generate_unique_code('BAT');
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_batch_qr ON public.batches;
CREATE TRIGGER trg_batch_qr
BEFORE INSERT ON public.batches
FOR EACH ROW
EXECUTE FUNCTION public.trg_generate_batch_qr();

-- 3. RPC: REGISTER PHARMACY (Atomic transaction)
CREATE OR REPLACE FUNCTION public.register_pharmacy(
    p_name TEXT,
    p_address TEXT,
    p_city TEXT,
    p_phone TEXT,
    p_license_no TEXT,
    p_license_doc_url TEXT DEFAULT NULL,
    p_logo_url TEXT DEFAULT NULL,
    p_currency VARCHAR DEFAULT 'USD'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_pharmacy_id UUID;
    v_user_id UUID := auth.uid();
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Create pharmacy record
    INSERT INTO public.pharmacies (
        name,
        address,
        city,
        phone,
        license_no,
        license_doc_url,
        logo_url,
        currency,
        approval_status
    ) VALUES (
        p_name,
        p_address,
        p_city,
        p_phone,
        p_license_no,
        p_license_doc_url,
        p_logo_url,
        p_currency,
        'pending'
    ) RETURNING id INTO v_pharmacy_id;

    -- Initialize invoice counter
    INSERT INTO public.pharmacy_invoice_counters (pharmacy_id, last_invoice_no)
    VALUES (v_pharmacy_id, 1000)
    ON CONFLICT (pharmacy_id) DO NOTHING;

    -- Link caller profile as admin
    UPDATE public.profiles
    SET pharmacy_id = v_pharmacy_id,
        role = 'admin',
        is_active = true
    WHERE id = v_user_id;

    -- Create in-app notification for Super Admin
    INSERT INTO public.notifications (
        pharmacy_id,
        target_role,
        type,
        title,
        message
    ) VALUES (
        NULL,
        'super_admin',
        'new_pharmacy',
        'New Pharmacy Registration Pending',
        'Pharmacy "' || p_name || '" (License: ' || p_license_no || ') has registered and awaits verification.'
    );

    RETURN v_pharmacy_id;
END;
$$;

-- 4. RPC: REVIEW PHARMACY (Super Admin only)
CREATE OR REPLACE FUNCTION public.review_pharmacy(
    p_pharmacy_id UUID,
    p_action TEXT, -- 'approved', 'rejected', 'suspended', 'reactivated'
    p_reason TEXT DEFAULT NULL,
    p_plan TEXT DEFAULT 'Standard',
    p_extend_days INT DEFAULT 365
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_status pharmacy_approval_status;
    v_admin_id UUID;
    v_pharmacy_name TEXT;
    v_notif_type notification_type;
    v_title TEXT;
    v_message TEXT;
    v_expires_at TIMESTAMPTZ;
BEGIN
    IF NOT public.is_super_admin() THEN
        RAISE EXCEPTION 'Unauthorized: only Super Admin can review pharmacies';
    END IF;

    SELECT name INTO v_pharmacy_name FROM public.pharmacies WHERE id = p_pharmacy_id;
    IF v_pharmacy_name IS NULL THEN
        RAISE EXCEPTION 'Pharmacy not found';
    END IF;

    -- Determine new status
    IF p_action = 'approved' OR p_action = 'reactivated' THEN
        v_status := 'approved';
        v_notif_type := 'pharmacy_approved';
        v_title := 'Pharmacy Account Approved!';
        v_message := 'Your pharmacy "' || v_pharmacy_name || '" has been approved. You now have full access to PharmaCare.';
        v_expires_at := now() + (p_extend_days || ' days')::interval;
    ELSIF p_action = 'rejected' THEN
        v_status := 'rejected';
        v_notif_type := 'pharmacy_rejected';
        v_title := 'Pharmacy Registration Rejected';
        v_message := 'Your pharmacy registration was rejected. Reason: ' || COALESCE(p_reason, 'Verification requirements not met.');
    ELSIF p_action = 'suspended' THEN
        v_status := 'suspended';
        v_notif_type := 'pharmacy_suspended';
        v_title := 'Pharmacy Account Suspended';
        v_message := 'Your pharmacy account has been suspended. Reason: ' || COALESCE(p_reason, 'Policy compliance review.');
    ELSE
        RAISE EXCEPTION 'Invalid review action: %', p_action;
    END IF;

    -- Update pharmacy
    UPDATE public.pharmacies
    SET approval_status = v_status,
        rejection_reason = p_reason,
        approved_by = auth.uid(),
        approved_at = CASE WHEN v_status = 'approved' THEN now() ELSE approved_at END,
        plan = COALESCE(p_plan, plan),
        plan_expires_at = COALESCE(v_expires_at, plan_expires_at)
    WHERE id = p_pharmacy_id;

    -- Log action
    INSERT INTO public.approval_logs (pharmacy_id, action, reason, acted_by)
    VALUES (p_pharmacy_id, p_action, p_reason, auth.uid());

    -- Find Admin user of this pharmacy to notify
    SELECT id INTO v_admin_id 
    FROM public.profiles 
    WHERE pharmacy_id = p_pharmacy_id AND role = 'admin' 
    LIMIT 1;

    -- Create notification
    INSERT INTO public.notifications (
        pharmacy_id,
        target_user_id,
        target_role,
        type,
        title,
        message
    ) VALUES (
        p_pharmacy_id,
        v_admin_id,
        'admin',
        v_notif_type,
        v_title,
        v_message
    );
END;
$$;

-- 5. RPC: CODE LOOKUP (QR code or manufacturer barcode)
CREATE OR REPLACE FUNCTION public.lookup_by_code(p_code TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_pharmacy_id UUID := public.current_pharmacy_id();
    v_role user_role := public.current_role();
    v_medicine RECORD;
    v_batch RECORD;
    v_total_stock INT := 0;
    v_nearest_expiry DATE := NULL;
    v_result JSONB;
BEGIN
    IF v_pharmacy_id IS NULL OR NOT public.pharmacy_is_approved() THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    -- 1. Try finding direct batch by batch QR
    SELECT b.*, m.name as medicine_name, m.generic_name, m.sale_price, m.unit
    INTO v_batch
    FROM public.batches b
    JOIN public.medicines m ON m.id = b.medicine_id
    WHERE b.pharmacy_id = v_pharmacy_id
      AND b.qr_code = trim(p_code)
    LIMIT 1;

    IF v_batch.id IS NOT NULL THEN
        -- Calculate total available stock and nearest expiry for this medicine
        SELECT COALESCE(SUM(quantity), 0), MIN(expiry_date)
        INTO v_total_stock, v_nearest_expiry
        FROM public.batches
        WHERE medicine_id = v_batch.medicine_id
          AND quantity > 0
          AND expiry_date >= CURRENT_DATE;

        v_result := jsonb_build_object(
            'found', true,
            'match_type', 'batch',
            'medicine_id', v_batch.medicine_id,
            'medicine_name', v_batch.medicine_name,
            'generic_name', v_batch.generic_name,
            'unit', v_batch.unit,
            'sale_price', v_batch.sale_price,
            'available_stock', v_total_stock,
            'nearest_expiry', v_nearest_expiry,
            'batch', jsonb_build_object(
                'id', v_batch.id,
                'batch_no', v_batch.batch_no,
                'expiry_date', v_batch.expiry_date,
                'quantity', v_batch.quantity,
                'purchase_price', CASE WHEN v_role IN ('admin', 'storekeeper') THEN v_batch.purchase_price ELSE NULL END
            )
        );
        RETURN v_result;
    END IF;

    -- 2. Try finding medicine by system QR or manufacturer barcode
    SELECT * INTO v_medicine
    FROM public.medicines
    WHERE pharmacy_id = v_pharmacy_id
      AND is_active = true
      AND (qr_code = trim(p_code) OR barcode = trim(p_code))
    LIMIT 1;

    IF v_medicine.id IS NOT NULL THEN
        -- Calculate available unexpired stock
        SELECT COALESCE(SUM(quantity), 0), MIN(expiry_date)
        INTO v_total_stock, v_nearest_expiry
        FROM public.batches
        WHERE medicine_id = v_medicine.id
          AND quantity > 0
          AND expiry_date >= CURRENT_DATE;

        v_result := jsonb_build_object(
            'found', true,
            'match_type', 'medicine',
            'medicine_id', v_medicine.id,
            'medicine_name', v_medicine.name,
            'generic_name', v_medicine.generic_name,
            'unit', v_medicine.unit,
            'sale_price', v_medicine.sale_price,
            'available_stock', v_total_stock,
            'nearest_expiry', v_nearest_expiry,
            'batch', NULL
        );
        RETURN v_result;
    END IF;

    -- Not found
    RETURN jsonb_build_object('found', false, 'code', p_code);
END;
$$;

-- 6. RPC: CREATE SALE WITH FEFO BATCH ALLOCATION
-- Picks batches by earliest expiry date first (skipping expired and zero stock).
-- Splits line across multiple batches if necessary.
-- Atomically decrements quantity, records cost price, and creates sale & sale items.
CREATE OR REPLACE FUNCTION public.create_sale(
    p_items JSONB, -- Array of [{medicine_id: UUID, quantity: INT}]
    p_discount NUMERIC DEFAULT 0,
    p_payment_method VARCHAR DEFAULT 'Cash',
    p_customer_name TEXT DEFAULT 'Walk-in Customer'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_pharmacy_id UUID := public.current_pharmacy_id();
    v_cashier_id UUID := auth.uid();
    v_next_invoice_no BIGINT;
    v_sale_id UUID;
    v_subtotal NUMERIC(12, 2) := 0;
    v_total NUMERIC(12, 2) := 0;
    
    v_item JSONB;
    v_med_id UUID;
    v_req_qty INT;
    v_med_price NUMERIC(12, 2);
    v_med_name TEXT;
    
    v_avail_total INT;
    v_needed INT;
    v_batch RECORD;
    v_deduct INT;
    
    v_created_items JSONB := '[]'::jsonb;
BEGIN
    IF v_pharmacy_id IS NULL OR NOT public.pharmacy_is_approved() THEN
        RAISE EXCEPTION 'Access denied: unapproved pharmacy or invalid session';
    END IF;

    IF jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'Sale cannot be empty';
    END IF;

    -- Allocate next auto-incrementing invoice number for this pharmacy
    UPDATE public.pharmacy_invoice_counters
    SET last_invoice_no = last_invoice_no + 1
    WHERE pharmacy_id = v_pharmacy_id
    RETURNING last_invoice_no INTO v_next_invoice_no;

    IF v_next_invoice_no IS NULL THEN
        INSERT INTO public.pharmacy_invoice_counters (pharmacy_id, last_invoice_no)
        VALUES (v_pharmacy_id, 1001)
        RETURNING last_invoice_no INTO v_next_invoice_no;
    END IF;

    -- Create the initial sale record
    INSERT INTO public.sales (
        pharmacy_id,
        invoice_no,
        cashier_id,
        subtotal,
        discount,
        total,
        payment_method,
        customer_name
    ) VALUES (
        v_pharmacy_id,
        v_next_invoice_no,
        v_cashier_id,
        0,
        COALESCE(p_discount, 0),
        0,
        p_payment_method,
        COALESCE(p_customer_name, 'Walk-in Customer')
    ) RETURNING id INTO v_sale_id;

    -- Process each item requested
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_med_id := (v_item->>'medicine_id')::UUID;
        v_req_qty := (v_item->>'quantity')::INT;

        IF v_req_qty <= 0 THEN
            RAISE EXCEPTION 'Invalid quantity % for medicine %', v_req_qty, v_med_id;
        END IF;

        -- Get medicine info
        SELECT sale_price, name INTO v_med_price, v_med_name
        FROM public.medicines
        WHERE id = v_med_id AND pharmacy_id = v_pharmacy_id AND is_active = true;

        IF v_med_price IS NULL THEN
            RAISE EXCEPTION 'Medicine % not found or inactive', v_med_id;
        END IF;

        -- Check total available unexpired stock
        SELECT COALESCE(SUM(quantity), 0) INTO v_avail_total
        FROM public.batches
        WHERE pharmacy_id = v_pharmacy_id
          AND medicine_id = v_med_id
          AND expiry_date >= CURRENT_DATE
          AND quantity > 0;

        IF v_avail_total < v_req_qty THEN
            RAISE EXCEPTION 'Insufficient stock for "%". Required: %, Available: %',
                v_med_name, v_req_qty, v_avail_total;
        END IF;

        -- FEFO: Allocate batches sorted by expiry_date ASC
        v_needed := v_req_qty;
        FOR v_batch IN
            SELECT id, batch_no, quantity, purchase_price, expiry_date
            FROM public.batches
            WHERE pharmacy_id = v_pharmacy_id
              AND medicine_id = v_med_id
              AND expiry_date >= CURRENT_DATE
              AND quantity > 0
            ORDER BY expiry_date ASC, created_at ASC
            FOR UPDATE -- lock batch row
        LOOP
            IF v_needed <= 0 THEN
                EXIT;
            END IF;

            v_deduct := LEAST(v_batch.quantity, v_needed);

            -- Decrement batch quantity
            UPDATE public.batches
            SET quantity = quantity - v_deduct
            WHERE id = v_batch.id;

            -- Insert into sale_items
            INSERT INTO public.sale_items (
                sale_id,
                pharmacy_id,
                medicine_id,
                batch_id,
                quantity,
                unit_price,
                cost_price
            ) VALUES (
                v_sale_id,
                v_pharmacy_id,
                v_med_id,
                v_batch.id,
                v_deduct,
                v_med_price,
                v_batch.purchase_price
            );

            v_subtotal := v_subtotal + (v_deduct * v_med_price);
            v_needed := v_needed - v_deduct;

            -- Append to item response
            v_created_items := v_created_items || jsonb_build_object(
                'medicine_name', v_med_name,
                'batch_no', v_batch.batch_no,
                'quantity', v_deduct,
                'unit_price', v_med_price,
                'total', v_deduct * v_med_price
            );
        END LOOP;

        IF v_needed > 0 THEN
            RAISE EXCEPTION 'Stock allocation failure for "%"', v_med_name;
        END IF;
    END LOOP;

    -- Calculate total
    v_total := GREATEST(0, v_subtotal - COALESCE(p_discount, 0));

    -- Update final sale totals
    UPDATE public.sales
    SET subtotal = v_subtotal,
        total = v_total
    WHERE id = v_sale_id;

    -- Return comprehensive sale data for receipt printing
    RETURN jsonb_build_object(
        'sale_id', v_sale_id,
        'invoice_no', v_next_invoice_no,
        'created_at', now(),
        'subtotal', v_subtotal,
        'discount', COALESCE(p_discount, 0),
        'total', v_total,
        'payment_method', p_payment_method,
        'customer_name', p_customer_name,
        'items', v_created_items
    );
END;
$$;

