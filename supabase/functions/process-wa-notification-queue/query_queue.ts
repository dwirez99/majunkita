import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL") ?? "",
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  { auth: { autoRefreshToken: false, persistSession: false } }
);

async function check() {
  const { data, error } = await supabase
    .from('wa_notification_queue')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(10);
  console.log("Error:", error);
  console.log("Data:", data);
}
check();
