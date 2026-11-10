-- ============================================================================
-- 004_views_and_reports.sql
-- Views, Aggregates & Monthly Sales Report RPC
-- ============================================================================

-- 1. VIEW: MEDICINES POS VIEW (Cost fields omitted for Cashier safety)
CREATE OR REPLACE VIEW public.medicines_pos_view AS
SELECT 
    m.id,
    m.pharmacy_id,
    m.name,
    m.generic_name,
    m.category,
    m.manufacturer,
    m.barcode,
    m.qr_code,
    m.unit,
    m.sale_price,
    m.min_stock_level,
    m.is_active,
    COALESCE(SUM(CASE WHEN b.quantity > 0 AND b.expiry_date >= CURRENT_DATE THEN b.quantity ELSE 0 END), 0)::INT as available_stock,
    MIN(CASE WHEN b.quantity > 0 AND b.expiry_date >= CURRENT_DATE THEN b.expiry_date ELSE NULL END) as nearest_expiry
FROM public.medicines m
LEFT JOIN public.batches b ON b.medicine_id = m.id AND b.pharmacy_id = m.pharmacy_id
GROUP BY m.id;

-- 2. VIEW: MEDICINE STOCK SUMMARY
CREATE OR REPLACE VIEW public.medicine_stock AS
SELECT 
    m.id AS medicine_id,
    m.pharmacy_id,
    m.name,
    m.sale_price,
    m.min_stock_level,
    COALESCE(SUM(CASE WHEN b.expiry_date >= CURRENT_DATE THEN b.quantity ELSE 0 END), 0)::INT AS available_quantity,
    COALESCE(SUM(CASE WHEN b.expiry_date < CURRENT_DATE THEN b.quantity ELSE 0 END), 0)::INT AS expired_quantity,
    COALESCE(SUM(b.quantity), 0)::INT AS total_quantity,
    COUNT(b.id) FILTER (WHERE b.quantity > 0)::INT AS active_batches_count
FROM public.medicines m
LEFT JOIN public.batches b ON b.medicine_id = m.id
GROUP BY m.id;

-- 3. VIEW: LOW STOCK MEDICINES
CREATE OR REPLACE VIEW public.low_stock_medicines AS
SELECT 
    ms.*,
    (ms.available_quantity <= ms.min_stock_level) AS is_low_stock
FROM public.medicine_stock ms
WHERE ms.available_quantity <= ms.min_stock_level;

-- 4. VIEW: EXPIRING BATCHES
CREATE OR REPLACE VIEW public.expiring_batches AS
SELECT 
    b.id AS batch_id,
    b.pharmacy_id,
    b.medicine_id,
    m.name AS medicine_name,
    b.batch_no,
    b.qr_code,
    b.expiry_date,
    b.quantity,
    b.purchase_price,
    (b.expiry_date - CURRENT_DATE) AS days_until_expiry,
    CASE 
        WHEN b.expiry_date < CURRENT_DATE THEN 'expired'
        WHEN (b.expiry_date - CURRENT_DATE) <= 30 THEN 'expiring_30'
        WHEN (b.expiry_date - CURRENT_DATE) <= 60 THEN 'expiring_60'
        WHEN (b.expiry_date - CURRENT_DATE) <= 90 THEN 'expiring_90'
        ELSE 'fresh'
    END AS status
FROM public.batches b
JOIN public.medicines m ON m.id = b.medicine_id
WHERE b.quantity > 0 AND b.expiry_date <= (CURRENT_DATE + INTERVAL '90 days');

-- 5. VIEW: PLATFORM STATS (Super Admin aggregate view)
CREATE OR REPLACE VIEW public.platform_stats AS
SELECT 
    COUNT(*)::INT AS total_pharmacies,
    COUNT(*) FILTER (WHERE approval_status = 'pending')::INT AS pending_pharmacies,
    COUNT(*) FILTER (WHERE approval_status = 'approved')::INT AS approved_pharmacies,
    COUNT(*) FILTER (WHERE approval_status = 'rejected')::INT AS rejected_pharmacies,
    COUNT(*) FILTER (WHERE approval_status = 'suspended')::INT AS suspended_pharmacies,
    (SELECT COUNT(*)::INT FROM public.profiles WHERE is_active = true) AS active_users,
    (SELECT COALESCE(SUM(total), 0)::NUMERIC(14,2) FROM public.sales) AS total_platform_volume
FROM public.pharmacies;

-- Grant select on platform_stats to authenticated
GRANT SELECT ON public.platform_stats TO authenticated;

-- 6. RPC: MONTHLY SALES & PROFIT REPORT (Admin only)
CREATE OR REPLACE FUNCTION public.monthly_sales_report(
    p_month INT,
    p_year INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_pharmacy_id UUID := public.current_pharmacy_id();
    v_role user_role := public.current_role();
    
    v_start_date TIMESTAMPTZ;
    v_end_date TIMESTAMPTZ;
    v_prev_start TIMESTAMPTZ;
    v_prev_end TIMESTAMPTZ;

    v_total_sales NUMERIC(12, 2) := 0;
    v_total_discount NUMERIC(12, 2) := 0;
    v_total_cost NUMERIC(12, 2) := 0;
    v_total_profit NUMERIC(12, 2) := 0;
    v_invoice_count INT := 0;
    v_avg_sale NUMERIC(12, 2) := 0;

    v_prev_total_sales NUMERIC(12, 2) := 0;
    v_growth_pct NUMERIC(6, 2) := 0;

    v_daily_sales JSONB := '[]'::jsonb;
    v_top_medicines JSONB := '[]'::jsonb;
    v_cashier_sales JSONB := '[]'::jsonb;
    v_payment_methods JSONB := '[]'::jsonb;
BEGIN
    IF v_pharmacy_id IS NULL OR v_role != 'admin' OR NOT public.pharmacy_is_approved() THEN
        RAISE EXCEPTION 'Access denied: only Pharmacy Admin can access financial reports';
    END IF;

    -- Define month range
    v_start_date := make_timestamptz(p_year, p_month, 1, 0, 0, 0);
    v_end_date := (v_start_date + INTERVAL '1 month');

    -- Previous month range for comparison
    v_prev_start := (v_start_date - INTERVAL '1 month');
    v_prev_end := v_start_date;

    -- Summary for selected month
    SELECT 
        COALESCE(SUM(s.total), 0),
        COALESCE(SUM(s.discount), 0),
        COUNT(s.id)
    INTO v_total_sales, v_total_discount, v_invoice_count
    FROM public.sales s
    WHERE s.pharmacy_id = v_pharmacy_id
      AND s.created_at >= v_start_date 
      AND s.created_at < v_end_date;

    -- Cost price from sale_items
    SELECT COALESCE(SUM(si.quantity * si.cost_price), 0)
    INTO v_total_cost
    FROM public.sale_items si
    JOIN public.sales s ON s.id = si.sale_id
    WHERE s.pharmacy_id = v_pharmacy_id
      AND s.created_at >= v_start_date 
      AND s.created_at < v_end_date;

    v_total_profit := v_total_sales - v_total_cost;
    IF v_invoice_count > 0 THEN
        v_avg_sale := ROUND(v_total_sales / v_invoice_count, 2);
    END IF;

    -- Previous month total for % change
    SELECT COALESCE(SUM(s.total), 0)
    INTO v_prev_total_sales
    FROM public.sales s
    WHERE s.pharmacy_id = v_pharmacy_id
      AND s.created_at >= v_prev_start 
      AND s.created_at < v_prev_end;

    IF v_prev_total_sales > 0 THEN
        v_growth_pct := ROUND(((v_total_sales - v_prev_total_sales) / v_prev_total_sales) * 100, 2);
    END IF;

    -- 1. Daily breakdown
    SELECT jsonb_agg(d) INTO v_daily_sales
    FROM (
        SELECT 
            EXTRACT(DAY FROM s.created_at)::INT AS day,
            COALESCE(SUM(s.total), 0)::NUMERIC(12,2) AS total,
            COUNT(s.id)::INT AS count
        FROM public.sales s
        WHERE s.pharmacy_id = v_pharmacy_id
          AND s.created_at >= v_start_date 
          AND s.created_at < v_end_date
        GROUP BY day
        ORDER BY day
    ) d;

    -- 2. Top 10 medicines sold
    SELECT jsonb_agg(tm) INTO v_top_medicines
    FROM (
        SELECT 
            m.name AS medicine_name,
            SUM(si.quantity)::INT AS total_quantity,
            SUM(si.quantity * si.unit_price)::NUMERIC(12,2) AS revenue,
            SUM(si.quantity * (si.unit_price - si.cost_price))::NUMERIC(12,2) AS profit
        FROM public.sale_items si
        JOIN public.medicines m ON m.id = si.medicine_id
        JOIN public.sales s ON s.id = si.sale_id
        WHERE s.pharmacy_id = v_pharmacy_id
          AND s.created_at >= v_start_date 
          AND s.created_at < v_end_date
        GROUP BY m.id, m.name
        ORDER BY revenue DESC
        LIMIT 10
    ) tm;

    -- 3. Sales per cashier
    SELECT jsonb_agg(cs) INTO v_cashier_sales
    FROM (
        SELECT 
            COALESCE(p.full_name, 'Unknown') AS cashier_name,
            COUNT(s.id)::INT AS invoice_count,
            COALESCE(SUM(s.total), 0)::NUMERIC(12,2) AS total_sales
        FROM public.sales s
        LEFT JOIN public.profiles p ON p.id = s.cashier_id
        WHERE s.pharmacy_id = v_pharmacy_id
          AND s.created_at >= v_start_date 
          AND s.created_at < v_end_date
        GROUP BY s.cashier_id, p.full_name
        ORDER BY total_sales DESC
    ) cs;

    -- 4. Payment method split
    SELECT jsonb_agg(pm) INTO v_payment_methods
    FROM (
        SELECT 
            s.payment_method,
            COUNT(s.id)::INT AS count,
            COALESCE(SUM(s.total), 0)::NUMERIC(12,2) AS total_amount
        FROM public.sales s
        WHERE s.pharmacy_id = v_pharmacy_id
          AND s.created_at >= v_start_date 
          AND s.created_at < v_end_date
        GROUP BY s.payment_method
    ) pm;

    RETURN jsonb_build_object(
        'month', p_month,
        'year', p_year,
        'total_sales', v_total_sales,
        'total_cost', v_total_cost,
        'total_profit', v_total_profit,
        'total_discount', v_total_discount,
        'invoice_count', v_invoice_count,
        'avg_sale', v_avg_sale,
        'prev_month_sales', v_prev_total_sales,
        'growth_pct', v_growth_pct,
        'daily_sales', COALESCE(v_daily_sales, '[]'::jsonb),
        'top_medicines', COALESCE(v_top_medicines, '[]'::jsonb),
        'cashier_sales', COALESCE(v_cashier_sales, '[]'::jsonb),
        'payment_methods', COALESCE(v_payment_methods, '[]'::jsonb)
    );
END;
$$;

