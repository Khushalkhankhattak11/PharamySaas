-- ============================================================================
-- 005_seed_data.sql
-- Seed Super Admin, Sample Approved Pharmacy, Staff & Medicine Data
-- Passwords for all seed accounts are: 'Password123!'
-- ============================================================================

DO $$
DECLARE
    v_super_admin_id UUID := '00000000-0000-0000-0000-000000000001'::uuid;
    v_admin_id UUID := '00000000-0000-0000-0000-000000000002'::uuid;
    v_storekeeper_id UUID := '00000000-0000-0000-0000-000000000003'::uuid;
    v_cashier_id UUID := '00000000-0000-0000-0000-000000000004'::uuid;
    
    v_pharmacy_id UUID := '11111111-1111-1111-1111-111111111111'::uuid;
    v_supplier_id UUID := '22222222-2222-2222-2222-222222222222'::uuid;
    v_purchase_id UUID := '33333333-3333-3333-3333-333333333333'::uuid;

    v_med_paracetamol UUID := '44444444-4444-4444-4444-444444444441'::uuid;
    v_med_amoxicillin UUID := '44444444-4444-4444-4444-444444444442'::uuid;
    v_med_ibuprofen UUID := '44444444-4444-4444-4444-444444444443'::uuid;
    v_med_omeprazole UUID := '44444444-4444-4444-4444-444444444444'::uuid;
    v_med_cetirizine UUID := '44444444-4444-4444-4444-444444444445'::uuid;

    v_hashed_pw TEXT := crypt('Password123!', gen_salt('bf'));
BEGIN
    -- 1. Create Super Admin in auth.users
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        v_super_admin_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'superadmin@pharmacare.com', v_hashed_pw, now(),
        '{"provider":"email","providers":["email"]}', '{"full_name":"Super Admin"}', now(), now()
    ) ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.profiles (id, pharmacy_id, role, full_name, phone, is_active)
    VALUES (v_super_admin_id, NULL, 'super_admin', 'System Platform Owner', '+18005550199', true)
    ON CONFLICT (id) DO UPDATE SET role = 'super_admin';

    -- 2. Create Sample Approved Pharmacy
    INSERT INTO public.pharmacies (
        id, name, address, city, phone, license_no, currency, receipt_header, receipt_footer,
        approval_status, approved_by, approved_at, plan, plan_expires_at
    ) VALUES (
        v_pharmacy_id,
        'City Central Pharmacy',
        '45 Medical Plaza, Health District',
        'Metropolis',
        '+1 555-0143',
        'LIC-2024-8841',
        'USD',
        'City Central Pharmacy\nThank you for choosing quality healthcare',
        'Please retain your receipt for warranty\nMedicines once sold cannot be returned',
        'approved',
        v_super_admin_id,
        now(),
        'Enterprise Plan',
        now() + INTERVAL '365 days'
    ) ON CONFLICT (id) DO NOTHING;

    -- Counter
    INSERT INTO public.pharmacy_invoice_counters (pharmacy_id, last_invoice_no)
    VALUES (v_pharmacy_id, 1005)
    ON CONFLICT (pharmacy_id) DO NOTHING;

    -- 3. Create Admin User
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        v_admin_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'admin@citycentral.com', v_hashed_pw, now(),
        '{"provider":"email","providers":["email"]}', '{"full_name":"Dr. Alice Smith"}', now(), now()
    ) ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.profiles (id, pharmacy_id, role, full_name, phone, is_active)
    VALUES (v_admin_id, v_pharmacy_id, 'admin', 'Dr. Alice Smith (Owner)', '+1 555-0144', true)
    ON CONFLICT (id) DO UPDATE SET pharmacy_id = v_pharmacy_id, role = 'admin';

    -- 4. Create Storekeeper User
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        v_storekeeper_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'storekeeper@citycentral.com', v_hashed_pw, now(),
        '{"provider":"email","providers":["email"]}', '{"full_name":"Bob Storekeeper"}', now(), now()
    ) ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.profiles (id, pharmacy_id, role, full_name, phone, is_active)
    VALUES (v_storekeeper_id, v_pharmacy_id, 'storekeeper', 'Bob Miller', '+1 555-0145', true)
    ON CONFLICT (id) DO UPDATE SET pharmacy_id = v_pharmacy_id, role = 'storekeeper';

    -- 5. Create Cashier User
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        v_cashier_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'cashier@citycentral.com', v_hashed_pw, now(),
        '{"provider":"email","providers":["email"]}', '{"full_name":"Charlie Cashier"}', now(), now()
    ) ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.profiles (id, pharmacy_id, role, full_name, phone, is_active)
    VALUES (v_cashier_id, v_pharmacy_id, 'cashier', 'Charlie Davis', '+1 555-0146', true)
    ON CONFLICT (id) DO UPDATE SET pharmacy_id = v_pharmacy_id, role = 'cashier';

    -- 6. Supplier
    INSERT INTO public.suppliers (id, pharmacy_id, name, phone, address)
    VALUES (v_supplier_id, v_pharmacy_id, 'Apex Pharma Distributors', '+1 800-444-2222', '12 Logistics Park, North City')
    ON CONFLICT (id) DO NOTHING;

    -- 7. Purchase
    INSERT INTO public.purchases (id, pharmacy_id, supplier_id, invoice_no, total, created_by)
    VALUES (v_purchase_id, v_pharmacy_id, v_supplier_id, 'PUR-2024-001', 3450.00, v_admin_id)
    ON CONFLICT (id) DO NOTHING;

    -- 8. Sample Medicines
    INSERT INTO public.medicines (id, pharmacy_id, name, generic_name, category, manufacturer, barcode, qr_code, unit, sale_price, min_stock_level, is_active, created_by)
    VALUES
        (v_med_paracetamol, v_pharmacy_id, 'Panadol 500mg', 'Paracetamol', 'Analgesic', 'GSK', '8901234567890', 'MED-PAN500', 'Strip', 2.50, 20, true, v_admin_id),
        (v_med_amoxicillin, v_pharmacy_id, 'Amoxil 500mg', 'Amoxicillin', 'Antibiotic', 'Glaxo', '8901234567891', 'MED-AMX500', 'Strip', 6.00, 15, true, v_admin_id),
        (v_med_ibuprofen, v_pharmacy_id, 'Brufen 400mg', 'Ibuprofen', 'NSAID', 'Abbott', '8901234567892', 'MED-BRU400', 'Strip', 3.20, 25, true, v_admin_id),
        (v_med_omeprazole, v_pharmacy_id, 'Losec 20mg', 'Omeprazole', 'Antacid', 'AstraZeneca', '8901234567893', 'MED-LOS020', 'Box', 12.00, 10, true, v_admin_id),
        (v_med_cetirizine, v_pharmacy_id, 'Zyrtec 10mg', 'Cetirizine', 'Antihistamine', 'Johnson & Johnson', '8901234567894', 'MED-ZYR010', 'Strip', 4.50, 15, true, v_admin_id)
    ON CONFLICT (id) DO NOTHING;

    -- 9. Sample Batches (FEFO testing: varying expiry dates)
    INSERT INTO public.batches (pharmacy_id, medicine_id, purchase_id, batch_no, qr_code, expiry_date, quantity, purchase_price)
    VALUES
        -- Paracetamol: Earliest expiry (FEFO priority 1)
        (v_pharmacy_id, v_med_paracetamol, v_purchase_id, 'PAN-B01', 'BAT-PAN-B01', CURRENT_DATE + INTERVAL '45 days', 30, 1.20),
        -- Paracetamol: Later expiry (FEFO priority 2)
        (v_pharmacy_id, v_med_paracetamol, v_purchase_id, 'PAN-B02', 'BAT-PAN-B02', CURRENT_DATE + INTERVAL '300 days', 100, 1.30),
        -- Amoxicillin: Expiring within 20 days (Expiring soon test)
        (v_pharmacy_id, v_med_amoxicillin, v_purchase_id, 'AMX-B01', 'BAT-AMX-B01', CURRENT_DATE + INTERVAL '20 days', 18, 3.50),
        -- Ibuprofen: Fresh batch
        (v_pharmacy_id, v_med_ibuprofen, v_purchase_id, 'BRU-B01', 'BAT-BRU-B01', CURRENT_DATE + INTERVAL '450 days', 60, 1.80),
        -- Omeprazole: Expired batch (should be skipped by FEFO)
        (v_pharmacy_id, v_med_omeprazole, v_purchase_id, 'LOS-EXP', 'BAT-LOS-EXP', CURRENT_DATE - INTERVAL '10 days', 5, 7.00),
        -- Omeprazole: Fresh batch
        (v_pharmacy_id, v_med_omeprazole, v_purchase_id, 'LOS-B02', 'BAT-LOS-B02', CURRENT_DATE + INTERVAL '360 days', 25, 7.50),
        -- Cetirizine: Low stock test
        (v_pharmacy_id, v_med_cetirizine, v_purchase_id, 'ZYR-B01', 'BAT-ZYR-B01', CURRENT_DATE + INTERVAL '180 days', 8, 2.20)
    ON CONFLICT DO NOTHING;

    -- 10. Sample Past Sales
    INSERT INTO public.sales (id, pharmacy_id, invoice_no, cashier_id, subtotal, discount, total, payment_method, customer_name, created_at)
    VALUES
        ('55555555-5555-5555-5555-555555555551'::uuid, v_pharmacy_id, 1001, v_cashier_id, 15.00, 0, 15.00, 'Cash', 'John Doe', now() - INTERVAL '2 days'),
        ('55555555-5555-5555-5555-555555555552'::uuid, v_pharmacy_id, 1002, v_cashier_id, 24.00, 2.00, 22.00, 'Credit Card', 'Sarah Jenkins', now() - INTERVAL '1 day'),
        ('55555555-5555-5555-5555-555555555553'::uuid, v_pharmacy_id, 1003, v_cashier_id, 9.70, 0, 9.70, 'Cash', 'Walk-in Customer', now() - INTERVAL '5 hours')
    ON CONFLICT (id) DO NOTHING;

END $$;

