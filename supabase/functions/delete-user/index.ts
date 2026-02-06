// Supabase Edge Function to delete a user
// This function is called by admins/managers to delete users

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface DeleteUserRequest {
  user_id: string;
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Create Supabase Admin Client
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      }
    );

    // Get the authorization header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Verify the user making the request
    const token = authHeader.replace("Bearer ", "");
    const {
      data: { user: requestingUser },
      error: authError,
    } = await supabaseAdmin.auth.getUser(token);

    if (authError || !requestingUser) {
      return new Response(
        JSON.stringify({ error: "Unauthorized - Invalid token" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Check if requesting user is admin or manager
    const { data: requestingProfile, error: profileError } =
      await supabaseAdmin
        .from("profiles")
        .select("role")
        .eq("id", requestingUser.id)
        .single();

    if (
      profileError ||
      !requestingProfile ||
      !["admin", "manager"].includes(requestingProfile.role)
    ) {
      return new Response(
        JSON.stringify({
          error: "Forbidden - Only admins and managers can delete users",
        }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Parse request body
    const requestData: DeleteUserRequest = await req.json();
    const { user_id } = requestData;

    // Validate required fields
    if (!user_id) {
      return new Response(
        JSON.stringify({
          error: "Missing required field: user_id",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Prevent self-deletion
    if (user_id === requestingUser.id) {
      return new Response(
        JSON.stringify({
          error: "Cannot delete your own account",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Delete the user using Supabase Admin API
    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(
      user_id
    );

    if (deleteError) {
      console.error("Error deleting user:", deleteError);
      return new Response(
        JSON.stringify({
          error: "Failed to delete user",
          details: deleteError.message,
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Profile should be automatically deleted via CASCADE constraint
    return new Response(
      JSON.stringify({
        success: true,
        message: "User deleted successfully",
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Unexpected error:", error);
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        details: error.message,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
