// supabase/functions/create-user/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// --- KONFIGURASI CORS ---
// Penting agar Flutter (Mobile) dan Web bisa mengakses function ini tanpa diblokir
const corsHeaders = {
     "Access-Control-Allow-Origin": "*",
     "Access-Control-Allow-Headers":
          "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
     // 1. Handle Preflight Request (OPTIONS)
     // Ini standar web request, browser/HP akan tanya "Boleh gak saya kirim data?"
     if (req.method === "OPTIONS") {
          return new Response("ok", { headers: corsHeaders });
     }

     try {
          // 2. Setup Client untuk VERIFIKASI PEMANGGIL
          // Kita pakai Anon Key + Token User untuk bertindak sebagai user yang sedang login
          const authHeader = req.headers.get("Authorization");
          if (!authHeader) {
               throw new Error("Missing Authorization header"); // Token tidak ada
          }

          const supabaseClient = createClient(
               Deno.env.get("SUPABASE_URL") ?? "",
               Deno.env.get("SUPABASE_ANON_KEY") ?? "",
               { global: { headers: { Authorization: authHeader } } },
          );

          // 3. Cek Identitas Pemanggil (Who are you?)
          const {
               data: { user },
               error: userError,
          } = await supabaseClient.auth.getUser();
          if (userError || !user) {
               throw new Error("User tidak valid atau sesi habis.");
          }

          // 4. Cek Jabatan Pemanggil di Database (Are you Admin/Manager?)
          const { data: callerProfile, error: profileError } =
               await supabaseClient
                    .from("profiles")
                    .select("role")
                    .eq("id", user.id)
                    .single();

          if (profileError || !callerProfile) {
               throw new Error("Profil pengguna tidak ditemukan.");
          }

          // --- SECURITY GATE 1: Hanya Admin & Manager yang boleh lewat ---
          if (
               callerProfile.role !== "admin" &&
               callerProfile.role !== "manager"
          ) {
               return new Response(
                    JSON.stringify({
                         error: "UNAUTHORIZED: Anda tidak memiliki izin untuk membuat user.",
                    }),
                    {
                         status: 403,
                         headers: {
                              ...corsHeaders,
                              "Content-Type": "application/json",
                         },
                    },
               );
          }

          // 5. Ambil Data dari Body Request (Flutter)
          const { email, password, nama, role, no_telp } = await req.json();

          // Validasi input dasar
          if (!email || !password || !nama || !role) {
               throw new Error(
                    "Data tidak lengkap (Email, Password, Nama, Role wajib diisi).",
               );
          }

          // Normalisasi Role (paksa huruf kecil agar sesuai constraint database)
          const targetRole = role.toLowerCase();

          // --- SECURITY GATE 2: Validasi Hierarki Jabatan ---
          // Manager TIDAK BOLEH membuat Admin atau sesama Manager.
          // Manager hanya boleh membuat Driver, Partner, Penjahit.
          if (callerProfile.role === "manager") {
               if (targetRole === "admin" || targetRole === "manager") {
                    return new Response(
                         JSON.stringify({
                              error: "FORBIDDEN: Manager hanya boleh membuat akun operasional (Driver/Partner).",
                         }),
                         {
                              status: 403,
                              headers: {
                                   ...corsHeaders,
                                   "Content-Type": "application/json",
                              },
                         },
                    );
               }
          }

          // 6. Setup Client "DEWA" (Service Role)
          // Client ini punya full akses untuk bypass RLS dan membuat user baru
          const supabaseAdmin = createClient(
               Deno.env.get("SUPABASE_URL") ?? "",
               Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
          );

          // 7. EKSEKUSI PEMBUATAN USER
          // Metadata ini PENTING karena akan ditangkap oleh Trigger Database
          // untuk mengisi tabel 'profiles' otomatis.
          const { data, error: createError } =
               await supabaseAdmin.auth.admin.createUser({
                    email: email,
                    password: password,
                    email_confirm: true, // Auto-confirm (user langsung bisa login)
                    user_metadata: {
                         nama: nama,
                         role: targetRole,
                         no_telp: no_telp,
                    },
               });

          if (createError) throw createError;

          // 8. Sukses! Kembalikan data user baru ke Flutter
          return new Response(
               JSON.stringify({
                    message: "User berhasil dibuat",
                    user: data.user,
               }),
               {
                    headers: {
                         ...corsHeaders,
                         "Content-Type": "application/json",
                    },
               },
          );
     } catch (error) {
          // Handle semua error (baik dari Supabase atau logic kita)
          return new Response(JSON.stringify({ error: error.message }), {
               status: 400,
               headers: { ...corsHeaders, "Content-Type": "application/json" },
          });
     }
});
