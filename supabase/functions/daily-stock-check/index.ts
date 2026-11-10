import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

serve(async (req) => {
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

    // 1. Get all approved active pharmacies
    const { data: pharmacies, error: pharmError } = await supabase
      .from("pharmacies")
      .select("id, name")
      .eq("approval_status", "approved");

    if (pharmError || !pharmacies) {
      return new Response(JSON.stringify({ error: pharmError?.message }), { status: 500 });
    }

    const todayStr = new Date().toISOString().split("T")[0];
    let createdCount = 0;

    for (const pharmacy of pharmacies) {
      const pharmacyId = pharmacy.id;

      // Check Low Stock
      const { data: lowStockMeds } = await supabase
        .from("low_stock_medicines")
        .select("medicine_id, name, available_quantity, min_stock_level")
        .eq("pharmacy_id", pharmacyId);

      if (lowStockMeds) {
        for (const med of lowStockMeds) {
          // Check if notification already created today
          const { data: existing } = await supabase
            .from("notifications")
            .select("id")
            .eq("pharmacy_id", pharmacyId)
            .eq("medicine_id", med.medicine_id)
            .eq("type", "low_stock")
            .gte("created_at", `${todayStr}T00:00:00Z`)
            .maybeSingle();

          if (!existing) {
            await supabase.from("notifications").insert({
              pharmacy_id: pharmacyId,
              target_role: "admin",
              type: "low_stock",
              title: `Low Stock: ${med.name}`,
              message: `Available stock is ${med.available_quantity}, which is at or below the minimum alert level (${med.min_stock_level}).`,
              medicine_id: med.medicine_id,
            });
            await supabase.from("notifications").insert({
              pharmacy_id: pharmacyId,
              target_role: "storekeeper",
              type: "low_stock",
              title: `Low Stock: ${med.name}`,
              message: `Available stock is ${med.available_quantity}, which is at or below the minimum alert level (${med.min_stock_level}).`,
              medicine_id: med.medicine_id,
            });
            createdCount += 2;
          }
        }
      }

      // Check Expiring & Expired Batches
      const { data: expiringBatches } = await supabase
        .from("expiring_batches")
        .select("batch_id, medicine_id, medicine_name, batch_no, expiry_date, quantity, days_until_expiry, status")
        .eq("pharmacy_id", pharmacyId);

      if (expiringBatches) {
        for (const batch of expiringBatches) {
          const type = batch.status === "expired" ? "expired" : "expiring_soon";
          
          const { data: existing } = await supabase
            .from("notifications")
            .select("id")
            .eq("pharmacy_id", pharmacyId)
            .eq("batch_id", batch.batch_id)
            .eq("type", type)
            .gte("created_at", `${todayStr}T00:00:00Z`)
            .maybeSingle();

          if (!existing) {
            let title = "";
            let message = "";

            if (batch.status === "expired") {
              title = `Expired Stock: ${batch.medicine_name}`;
              message = `Batch ${batch.batch_no} (${batch.quantity} units) expired on ${batch.expiry_date}. Remove from active stock.`;
            } else if (batch.status === "expiring_30") {
              title = `Critical Expiry: ${batch.medicine_name}`;
              message = `Batch ${batch.batch_no} (${batch.quantity} units) expires in ${batch.days_until_expiry} days (${batch.expiry_date}).`;
            } else {
              title = `Upcoming Expiry: ${batch.medicine_name}`;
              message = `Batch ${batch.batch_no} (${batch.quantity} units) expires in ${batch.days_until_expiry} days.`;
            }

            // Insert for Admin
            await supabase.from("notifications").insert({
              pharmacy_id: pharmacyId,
              target_role: "admin",
              type,
              title,
              message,
              medicine_id: batch.medicine_id,
              batch_id: batch.batch_id,
            });

            // Insert for Storekeeper
            await supabase.from("notifications").insert({
              pharmacy_id: pharmacyId,
              target_role: "storekeeper",
              type,
              title,
              message,
              medicine_id: batch.medicine_id,
              batch_id: batch.batch_id,
            });

            createdCount += 2;
          }
        }
      }
    }

    return new Response(JSON.stringify({ success: true, notifications_created: createdCount }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
});

