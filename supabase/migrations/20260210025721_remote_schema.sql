


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."get_admin_dashboard_summary"() RETURNS json
    LANGUAGE "sql"
    AS $$SELECT json_build_object(
    -- 1. Data Ringkasan Perca
    'perca', (
      SELECT json_build_object(
        'stock_saat_ini', COALESCE(SUM(weight), 0)
      )
      FROM public.percas_stock
    ),
    -- 2. Data Ringkasan Stok di Penjahit (Perca yang sudah diberikan)
    'stok_di_penjahit', (
      SELECT COALESCE(SUM(weight), 0)
      FROM public.perca_transactions
    ),
    -- 3. Data Ringkasan Majun
    'majun', (
      SELECT json_build_object(
        'stock_saat_ini', COALESCE(SUM(weight), 0)
      )
      FROM public.majun_stock
    ),
    -- 4. Data Ringkasan Penjahit
    'penjahit', (
      SELECT json_build_object(
        'jumlah_aktif', (SELECT COUNT(*) FROM public.tailors),
        'upah_belum_dibayar', COALESCE(SUM(balance), 0)
      )
      FROM public.salary
    )
  );$$;


ALTER FUNCTION "public"."get_admin_dashboard_summary"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_email_by_username"("_username" "text") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
    _email TEXT; -- 2. Renamed local variable
BEGIN
    SELECT p.email INTO _email
    FROM public.profiles p
    -- 3. Fixed logic: Compare Table Column (left) vs Input Parameter (right)
    WHERE LOWER(p.username) = LOWER(_username)
    LIMIT 1;

    RETURN _email;
END;
$$;


ALTER FUNCTION "public"."get_email_by_username"("_username" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$BEGIN
    -- Insert new profile with data from user_metadata
    INSERT INTO public.profiles (id, username, name, email, role, no_telp)
    VALUES (
        NEW.id,
        COALESCE(
            NEW.raw_user_meta_data->>'username',
            split_part(NEW.email, '@', 1)
        ),
        COALESCE(
            NEW.raw_user_meta_data->>'name',
            NEW.email
        ),
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'role'),
        COALESCE(NEW.raw_user_meta_data->>'no_telp', '')
    )
    ON CONFLICT (id) DO UPDATE
    SET
        username = COALESCE(EXCLUDED.username, profiles.username),
        name = COALESCE(EXCLUDED.nama_lengkap, profiles.name),
        email = COALESCE(EXCLUDED.email, profiles.email),
        role = COALESCE(EXCLUDED.role, profiles.role),
        no_telp = COALESCE(EXCLUDED.no_telp, profiles.no_telp),
        updated_at = NOW();

    RETURN NEW;
END;$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rls_auto_enable"() RETURNS "event_trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."rls_auto_enable"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."expeditions" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "id_partner" "uuid" NOT NULL,
    "expedition_date" "date" DEFAULT CURRENT_DATE NOT NULL,
    "destination" character varying NOT NULL,
    "sack_number" integer NOT NULL,
    "total_weight" integer NOT NULL,
    "proof_of_delivery" character varying NOT NULL
);


ALTER TABLE "public"."expeditions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."factories" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "factory_name" character varying NOT NULL,
    "address" character varying,
    "no_telp" character varying
);


ALTER TABLE "public"."factories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."majun_stock" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "id_tailor" "uuid" NOT NULL,
    "date_entry" "date" DEFAULT CURRENT_DATE NOT NULL,
    "weight" numeric(10,2) NOT NULL
);


ALTER TABLE "public"."majun_stock" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."perca_transactions" (
    "id_stock_perca" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "id_tailors" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "date_entry" "date" NOT NULL,
    "percas_type" character varying NOT NULL,
    "weight" numeric(10,2) NOT NULL,
    "delivery_proof" character varying NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL
);


ALTER TABLE "public"."perca_transactions" OWNER TO "postgres";


COMMENT ON TABLE "public"."perca_transactions" IS 'tabel ini digunakan untuk kelola perca yang diambil oleh penjahit';



CREATE TABLE IF NOT EXISTS "public"."percas_stock" (
    "id_factory" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "date_entry" "date" NOT NULL,
    "perca_type" character varying NOT NULL,
    "weight" numeric(10,2) NOT NULL,
    "delivery_proof" character varying NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL
);


ALTER TABLE "public"."percas_stock" OWNER TO "postgres";


COMMENT ON TABLE "public"."percas_stock" IS 'tabel ini digunakan untuk kelola masuk dan keluar stok perca';



CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "role" character varying NOT NULL,
    "no_telp" character varying,
    "username" "text",
    "name" "text",
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "email" "text",
    "address" "text",
    CONSTRAINT "profiles_role_check" CHECK ((("role")::"text" = ANY ((ARRAY['admin'::character varying, 'manager'::character varying, 'driver'::character varying, 'partner_pabrik'::character varying, 'penjahit'::character varying])::"text"[])))
);

ALTER TABLE ONLY "public"."profiles" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."salary" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "id_tailor" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "balance" numeric NOT NULL,
    "date_entry" "date" NOT NULL
);


ALTER TABLE "public"."salary" OWNER TO "postgres";


COMMENT ON TABLE "public"."salary" IS 'table yang akan mengelola upah yang akan didapat penjahit';



CREATE TABLE IF NOT EXISTS "public"."tailors" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" character varying NOT NULL,
    "no_telp" character varying NOT NULL,
    "address" character varying NOT NULL,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tailor_images" character varying
);


ALTER TABLE "public"."tailors" OWNER TO "postgres";


COMMENT ON TABLE "public"."tailors" IS 'tabel ini digunakan untuk kelola data penjahit yang berafilisasi';



ALTER TABLE "public"."salary" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."upah_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



ALTER TABLE ONLY "public"."expeditions"
    ADD CONSTRAINT "expedisi_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."factories"
    ADD CONSTRAINT "pabrik_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tailors"
    ADD CONSTRAINT "penjahit_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_username_key" UNIQUE ("username");



ALTER TABLE ONLY "public"."percas_stock"
    ADD CONSTRAINT "stok_majun_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."majun_stock"
    ADD CONSTRAINT "stok_majun_pkey1" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."perca_transactions"
    ADD CONSTRAINT "transaksi_perca_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."salary"
    ADD CONSTRAINT "upah_pkey" PRIMARY KEY ("id");



CREATE INDEX "profiles_username_idx" ON "public"."profiles" USING "btree" ("username");



CREATE OR REPLACE TRIGGER "on_profiles_updated" BEFORE UPDATE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."handle_updated_at"();



ALTER TABLE ONLY "public"."expeditions"
    ADD CONSTRAINT "expedisi_id_partner_fkey" FOREIGN KEY ("id_partner") REFERENCES "public"."profiles"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."majun_stock"
    ADD CONSTRAINT "stok_majun_id_penjahit_fkey" FOREIGN KEY ("id_tailor") REFERENCES "public"."tailors"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."percas_stock"
    ADD CONSTRAINT "stok_perca_id_pabrik_fkey" FOREIGN KEY ("id_factory") REFERENCES "public"."factories"("id");



ALTER TABLE ONLY "public"."perca_transactions"
    ADD CONSTRAINT "transaksi_perca_id_penjahit_fkey" FOREIGN KEY ("id_tailors") REFERENCES "public"."tailors"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."perca_transactions"
    ADD CONSTRAINT "transaksi_perca_id_stok_perca_fkey" FOREIGN KEY ("id_stock_perca") REFERENCES "public"."percas_stock"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."salary"
    ADD CONSTRAINT "upah_id_penjahit_fkey" FOREIGN KEY ("id_tailor") REFERENCES "public"."tailors"("id") ON UPDATE CASCADE ON DELETE RESTRICT;



CREATE POLICY "Admin and Manager can delete profiles" ON "public"."profiles" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "profiles_1"
  WHERE (("profiles_1"."id" = "auth"."uid"()) AND (("profiles_1"."role")::"text" = ANY ((ARRAY['admin'::character varying, 'manager'::character varying])::"text"[]))))));



CREATE POLICY "Admin and Manager can insert profiles" ON "public"."profiles" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "profiles_1"
  WHERE (("profiles_1"."id" = "auth"."uid"()) AND (("profiles_1"."role")::"text" = ANY ((ARRAY['admin'::character varying, 'manager'::character varying])::"text"[]))))));



CREATE POLICY "Admin and Manager can update profiles" ON "public"."profiles" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "profiles_1"
  WHERE (("profiles_1"."id" = "auth"."uid"()) AND (("profiles_1"."role")::"text" = ANY ((ARRAY['admin'::character varying, 'manager'::character varying])::"text"[]))))));



CREATE POLICY "Public profiles are viewable by everyone" ON "public"."profiles" FOR SELECT USING (true);



ALTER TABLE "public"."expeditions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."factories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."majun_stock" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."perca_transactions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."percas_stock" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."salary" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."tailors" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "user_bisa_lihat_profilnya_sendiri" ON "public"."profiles" FOR SELECT USING ((( SELECT "auth"."uid"() AS "uid") = "id"));





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

























































































































































GRANT ALL ON FUNCTION "public"."get_admin_dashboard_summary"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_admin_dashboard_summary"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_admin_dashboard_summary"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_email_by_username"("_username" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_email_by_username"("_username" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_email_by_username"("_username" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "anon";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "service_role";


















GRANT ALL ON TABLE "public"."expeditions" TO "anon";
GRANT ALL ON TABLE "public"."expeditions" TO "authenticated";
GRANT ALL ON TABLE "public"."expeditions" TO "service_role";



GRANT ALL ON TABLE "public"."factories" TO "anon";
GRANT ALL ON TABLE "public"."factories" TO "authenticated";
GRANT ALL ON TABLE "public"."factories" TO "service_role";



GRANT ALL ON TABLE "public"."majun_stock" TO "anon";
GRANT ALL ON TABLE "public"."majun_stock" TO "authenticated";
GRANT ALL ON TABLE "public"."majun_stock" TO "service_role";



GRANT ALL ON TABLE "public"."perca_transactions" TO "anon";
GRANT ALL ON TABLE "public"."perca_transactions" TO "authenticated";
GRANT ALL ON TABLE "public"."perca_transactions" TO "service_role";



GRANT ALL ON TABLE "public"."percas_stock" TO "anon";
GRANT ALL ON TABLE "public"."percas_stock" TO "authenticated";
GRANT ALL ON TABLE "public"."percas_stock" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."salary" TO "anon";
GRANT ALL ON TABLE "public"."salary" TO "authenticated";
GRANT ALL ON TABLE "public"."salary" TO "service_role";



GRANT ALL ON TABLE "public"."tailors" TO "anon";
GRANT ALL ON TABLE "public"."tailors" TO "authenticated";
GRANT ALL ON TABLE "public"."tailors" TO "service_role";



GRANT ALL ON SEQUENCE "public"."upah_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."upah_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."upah_id_seq" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";



































