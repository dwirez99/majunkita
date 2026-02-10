// Supabase Edge Function to create a new user
// This function is called by admins/managers to create new users
//
// Profiles Table Structure:
// - id (uuid, primary key, foreign key to auth.users)
// - role (character varying, not null) - Allowed: 'admin', 'manager', 'driver', 'partner_pabrik', 'penjahit'
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

interface CreateUserRequest {
  email: string;
  password: string;
  username?: string;
  name: string;
  role: 'admin' | 'manager' | 'driver' | 'partner_pabrik' | 'penjahit';
  no_telp?: string;
  address?: string;
}

interface ProfileData {
  id: string;
  role: string;
  no_telp: string | null;
  username: string | null;
  name: string | null;
  updated_at?: string;
  email: string | null;
  address: string | null;
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
          error: "Forbidden - Only admins and managers can create users",
        }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Parse request body
    const requestData: CreateUserRequest = await req.json();
    const { email, password, username, name, role, no_telp, address } =
      requestData;

    // Validate required fields
    if (!email || !password || !name || !role) {
      return new Response(
        JSON.stringify({
          error: "Missing required fields: email, password, name, role",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Validate role
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

    // Create the new user using Supabase Admin API
    const { data: newUser, error: createError } =
      await supabaseAdmin.auth.admin.createUser({
        email: email,
        password: password,
        email_confirm: true, // Auto-confirm email
        user_metadata: {
          username: username || email.split("@")[0],
          name: name,
          role: role,
          no_telp: no_telp || null,
          address: address || null,
        },
      });

    if (createError) {
      console.error("Error creating user:", createError);
      return new Response(
        JSON.stringify({
          error: "Database error creating new user",
          details: createError.message,
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // The trigger should automatically create the profile
    // Let's verify it was created
    const { data: profile, error: profileCheckError } = await supabaseAdmin
      .from("profiles")
      .select("*")
      .eq("id", newUser.user.id)
      .single();

    if (profileCheckError) {
      console.error("Profile not created by trigger:", profileCheckError);
      // Try to create profile manually as fallback
      const profileData: ProfileData = {
        id: newUser.user.id,
        role: role,
        no_telp: no_telp || null,
        username: username || null,
        name: name || null,
        email: email || null,
        address: address || null,
      };

      const { error: manualProfileError } = await supabaseAdmin
        .from("profiles")
        .insert(profileData);

      if (manualProfileError) {
        console.error("Failed to create profile manually:", manualProfileError);
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "User created successfully",
        user: {
          id: newUser.user.id,
          email: newUser.user.email,
          role: role,
        },
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
