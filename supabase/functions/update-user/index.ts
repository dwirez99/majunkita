// Supabase Edge Function to update a user
// This function is called by admins/managers to update user information
//
// Profiles Table Structure:
// - id (uuid, primary key, foreign key to auth.users)
// - role (character varying, not null)
// - no_telp (character varying, nullable)
// - username (text, nullable, unique)
// - name (text, nullable)
// - email (text, nullable)
// - address (text, nullable)
// - updated_at (timestamp with time zone, auto-updated)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface UpdateUserRequest {
  user_id: string;
  email?: string;
  password?: string;
  username?: string;
  name?: string;
  no_telp?: string;
  role?: string;
  address?: string;
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
          error: "Forbidden - Only admins and managers can update users",
        }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Parse request body
    const requestData: UpdateUserRequest = await req.json();
    const { user_id, email, password, username, name, no_telp, role, address } =
      requestData;

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

    // Validate role if provided
    if (role) {
      const validRoles = [
        "admin",
        "manager",
        "driver",
        "partner_pabrik",
        "penjahit",
      ];
      if (!validRoles.includes(role)) {
        return new Response(
          JSON.stringify({
            error: `Invalid role. Must be one of: ${validRoles.join(", ")}`,
          }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }
    }

    // Update user in auth.users if email or password is provided
    if (email || password) {
      const updateAuthData: any = {};
      if (email) updateAuthData.email = email;
      if (password) updateAuthData.password = password;

      const { error: updateAuthError } =
        await supabaseAdmin.auth.admin.updateUserById(user_id, updateAuthData);

      if (updateAuthError) {
        console.error("Error updating auth user:", updateAuthError);
        return new Response(
          JSON.stringify({
            error: "Failed to update user authentication",
            details: updateAuthError.message,
          }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }
    }

    // Update user metadata if provided
    if (username || name || no_telp || role || address) {
      const userMetadata: any = {};
      if (username) userMetadata.username = username;
      if (name) {
        userMetadata.nama = name;
        userMetadata.name = name;
      }
      if (no_telp) userMetadata.no_telp = no_telp;
      if (role) userMetadata.role = role;
      if (address) userMetadata.address = address;

      const { error: metadataError } =
        await supabaseAdmin.auth.admin.updateUserById(user_id, {
          user_metadata: userMetadata,
        });

      if (metadataError) {
        console.error("Error updating user metadata:", metadataError);
      }
    }

    // Update profile in profiles table
    const profileUpdateData: any = {};
    if (username !== undefined) profileUpdateData.username = username;
    if (name !== undefined) profileUpdateData.name = name;
    if (email !== undefined) profileUpdateData.email = email;
    if (no_telp !== undefined) profileUpdateData.no_telp = no_telp;
    if (role !== undefined) profileUpdateData.role = role;
    if (address !== undefined) profileUpdateData.address = address;

    if (Object.keys(profileUpdateData).length > 0) {
      const { error: profileUpdateError } = await supabaseAdmin
        .from("profiles")
        .update(profileUpdateData)
        .eq("id", user_id);

      if (profileUpdateError) {
        console.error("Error updating profile:", profileUpdateError);
        return new Response(
          JSON.stringify({
            error: "Failed to update user profile",
            details: profileUpdateError.message,
          }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "User updated successfully",
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
