drop policy "Admin and Driver can create expedition plans" on "public"."expeditions";

drop policy "Internal staff can view expeditions" on "public"."expeditions";

drop policy "Admin dan Driver bisa input majun jadi" on "public"."majun_stock";

drop policy "Enable read access for all users" on "public"."majun_stock";

drop policy "Admin dan Driver bisa tambah stok" on "public"."percas_stock";

drop policy "Semua role internal bisa melihat stok" on "public"."percas_stock";

drop policy "Admin and Manager can delete profiles" on "public"."profiles";

drop policy "Admin and Manager can insert profiles" on "public"."profiles";

drop policy "Admin and Manager can update profiles" on "public"."profiles";

alter table "public"."profiles" drop constraint "profiles_role_check";

alter table "public"."perca_transactions" drop column "delivery_proof";

alter table "public"."profiles" add constraint "profiles_role_check" CHECK (((role)::text = ANY ((ARRAY['admin'::character varying, 'manager'::character varying, 'driver'::character varying, 'partner_pabrik'::character varying, 'penjahit'::character varying])::text[]))) not valid;

alter table "public"."profiles" validate constraint "profiles_role_check";


  create policy "Admin and Driver can create expedition plans"
  on "public"."expeditions"
  as permissive
  for insert
  to authenticated
with check ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND ((profiles.role)::text = ANY ((ARRAY['admin'::character varying, 'driver'::character varying])::text[]))))));



  create policy "Internal staff can view expeditions"
  on "public"."expeditions"
  as permissive
  for select
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND ((profiles.role)::text = ANY ((ARRAY['admin'::character varying, 'driver'::character varying, 'manager'::character varying])::text[]))))));



  create policy "Admin dan Driver bisa input majun jadi"
  on "public"."majun_stock"
  as permissive
  for insert
  to public
with check ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND ((profiles.role)::text = ANY ((ARRAY['admin'::character varying, 'driver'::character varying])::text[]))))));



  create policy "Enable read access for all users"
  on "public"."majun_stock"
  as permissive
  for select
  to public
using ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND ((profiles.role)::text = ANY ((ARRAY['admin'::character varying, 'driver'::character varying, 'manager'::character varying])::text[]))))));



  create policy "Admin dan Driver bisa tambah stok"
  on "public"."percas_stock"
  as permissive
  for insert
  to authenticated
with check ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND ((profiles.role)::text = ANY ((ARRAY['admin'::character varying, 'driver'::character varying])::text[]))))));



  create policy "Semua role internal bisa melihat stok"
  on "public"."percas_stock"
  as permissive
  for select
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND ((profiles.role)::text = ANY ((ARRAY['admin'::character varying, 'driver'::character varying, 'manager'::character varying])::text[]))))));



  create policy "Admin and Manager can delete profiles"
  on "public"."profiles"
  as permissive
  for delete
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.profiles profiles_1
  WHERE ((profiles_1.id = auth.uid()) AND ((profiles_1.role)::text = ANY ((ARRAY['admin'::character varying, 'manager'::character varying])::text[]))))));



  create policy "Admin and Manager can insert profiles"
  on "public"."profiles"
  as permissive
  for insert
  to authenticated
with check ((EXISTS ( SELECT 1
   FROM public.profiles profiles_1
  WHERE ((profiles_1.id = auth.uid()) AND ((profiles_1.role)::text = ANY ((ARRAY['admin'::character varying, 'manager'::character varying])::text[]))))));



  create policy "Admin and Manager can update profiles"
  on "public"."profiles"
  as permissive
  for update
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.profiles profiles_1
  WHERE ((profiles_1.id = auth.uid()) AND ((profiles_1.role)::text = ANY ((ARRAY['admin'::character varying, 'manager'::character varying])::text[]))))));


-- NOTE: Removed storage.protect_delete() triggers — these are Supabase-internal
-- and not available in the local Docker image. They are managed automatically
-- on the hosted platform.
