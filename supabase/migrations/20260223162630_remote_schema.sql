drop extension if exists "pg_net";

drop policy "Admin and Manager can delete profiles" on "public"."profiles";

drop policy "Admin and Manager can insert profiles" on "public"."profiles";

drop policy "Admin and Manager can update profiles" on "public"."profiles";

alter table "public"."profiles" drop constraint "profiles_role_check";


  create table "public"."percas_plans" (
    "id" uuid not null default gen_random_uuid(),
    "id_factory" uuid not null,
    "planned_date" date not null,
    "status" character varying not null default 'PENDING'::character varying,
    "notes" text,
    "created_by" uuid not null,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."percas_plans" enable row level security;

alter table "public"."majun_stock" add column "staff_id" uuid default auth.uid();

alter table "public"."perca_transactions" add column "staff_id" uuid;

alter table "public"."percas_stock" add column "id_plan" uuid;

CREATE INDEX idx_percas_plans_created_by ON public.percas_plans USING btree (created_by);

CREATE INDEX idx_percas_plans_id_factory ON public.percas_plans USING btree (id_factory);

CREATE INDEX idx_percas_plans_planned_date ON public.percas_plans USING btree (planned_date);

CREATE INDEX idx_percas_plans_status ON public.percas_plans USING btree (status);

CREATE INDEX idx_percas_stock_id_plan ON public.percas_stock USING btree (id_plan);

CREATE UNIQUE INDEX percas_plans_pkey ON public.percas_plans USING btree (id);

alter table "public"."percas_plans" add constraint "percas_plans_pkey" PRIMARY KEY using index "percas_plans_pkey";

alter table "public"."majun_stock" add constraint "majun_stock_staff_id_fkey" FOREIGN KEY (staff_id) REFERENCES public.profiles(id) not valid;

alter table "public"."majun_stock" validate constraint "majun_stock_staff_id_fkey";

alter table "public"."perca_transactions" add constraint "perca_transactions_staff_id_fkey" FOREIGN KEY (staff_id) REFERENCES public.profiles(id) ON DELETE SET NULL not valid;

alter table "public"."perca_transactions" validate constraint "perca_transactions_staff_id_fkey";

alter table "public"."percas_plans" add constraint "percas_plans_created_by_fkey" FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE SET NULL not valid;

alter table "public"."percas_plans" validate constraint "percas_plans_created_by_fkey";

alter table "public"."percas_plans" add constraint "percas_plans_id_factory_fkey" FOREIGN KEY (id_factory) REFERENCES public.factories(id) ON DELETE CASCADE not valid;

alter table "public"."percas_plans" validate constraint "percas_plans_id_factory_fkey";

alter table "public"."percas_plans" add constraint "percas_plans_status_check" CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'APPROVED'::character varying, 'REJECTED'::character varying, 'COMPLETED'::character varying])::text[]))) not valid;

alter table "public"."percas_plans" validate constraint "percas_plans_status_check";

alter table "public"."percas_stock" add constraint "percas_stock_id_plan_fkey" FOREIGN KEY (id_plan) REFERENCES public.percas_plans(id) ON DELETE SET NULL not valid;

alter table "public"."percas_stock" validate constraint "percas_stock_id_plan_fkey";

alter table "public"."profiles" add constraint "profiles_role_check" CHECK (((role)::text = ANY ((ARRAY['admin'::character varying, 'manager'::character varying, 'driver'::character varying, 'partner_pabrik'::character varying, 'penjahit'::character varying])::text[]))) not valid;

alter table "public"."profiles" validate constraint "profiles_role_check";

grant delete on table "public"."percas_plans" to "anon";

grant insert on table "public"."percas_plans" to "anon";

grant references on table "public"."percas_plans" to "anon";

grant select on table "public"."percas_plans" to "anon";

grant trigger on table "public"."percas_plans" to "anon";

grant truncate on table "public"."percas_plans" to "anon";

grant update on table "public"."percas_plans" to "anon";

grant delete on table "public"."percas_plans" to "authenticated";

grant insert on table "public"."percas_plans" to "authenticated";

grant references on table "public"."percas_plans" to "authenticated";

grant select on table "public"."percas_plans" to "authenticated";

grant trigger on table "public"."percas_plans" to "authenticated";

grant truncate on table "public"."percas_plans" to "authenticated";

grant update on table "public"."percas_plans" to "authenticated";

grant delete on table "public"."percas_plans" to "service_role";

grant insert on table "public"."percas_plans" to "service_role";

grant references on table "public"."percas_plans" to "service_role";

grant select on table "public"."percas_plans" to "service_role";

grant trigger on table "public"."percas_plans" to "service_role";

grant truncate on table "public"."percas_plans" to "service_role";

grant update on table "public"."percas_plans" to "service_role";


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



  create policy "CRUD factories role as admin and manager"
  on "public"."factories"
  as permissive
  for all
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND ((profiles.role)::text = ANY (ARRAY[('admin'::character varying)::text, ('driver'::character varying)::text]))))));



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



  create policy "Admin Full Access Transaksi"
  on "public"."perca_transactions"
  as permissive
  for all
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND ((profiles.role)::text = 'admin'::text)))));



  create policy "Manager Monitor Transaksi"
  on "public"."perca_transactions"
  as permissive
  for select
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND ((profiles.role)::text = 'manager'::text)))));



  create policy "Admin dan Manager dapat update percas_plans"
  on "public"."percas_plans"
  as permissive
  for update
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND ((profiles.role)::text = ANY (ARRAY[('admin'::character varying)::text, ('manager'::character varying)::text, ('driver'::character varying)::text]))))))
with check ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND ((profiles.role)::text = ANY (ARRAY[('admin'::character varying)::text, ('manager'::character varying)::text, ('driver'::character varying)::text]))))));



  create policy "Admin dapat delete percas_plans"
  on "public"."percas_plans"
  as permissive
  for delete
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND ((profiles.role)::text = 'admin'::text)))));



  create policy "Admin dapat membuat percas_plans"
  on "public"."percas_plans"
  as permissive
  for insert
  to authenticated
with check ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND ((profiles.role)::text = 'admin'::text)))));



  create policy "semua role dapat melihat semua percas_plans"
  on "public"."percas_plans"
  as permissive
  for select
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND ((profiles.role)::text = ANY (ARRAY[('admin'::character varying)::text, ('manager'::character varying)::text, ('driver'::character varying)::text]))))));



  create policy "Admin dan Driver bisa tambah stok"
  on "public"."percas_stock"
  as permissive
  for insert
  to authenticated
with check ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND ((profiles.role)::text = ANY ((ARRAY['admin'::character varying, 'driver'::character varying])::text[]))))));



  create policy "Hanya Manager bisa update (approval)"
  on "public"."percas_stock"
  as permissive
  for update
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND ((profiles.role)::text = 'manager'::text)))))
with check ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND ((profiles.role)::text = 'manager'::text)))));



  create policy "Semua role internal bisa melihat stok"
  on "public"."percas_stock"
  as permissive
  for select
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND ((profiles.role)::text = ANY ((ARRAY['admin'::character varying, 'driver'::character varying, 'manager'::character varying])::text[]))))));



  create policy "Admin Kelola Gaji Sepenuhnya"
  on "public"."salary"
  as permissive
  for all
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND ((profiles.role)::text = 'admin'::text)))));



  create policy "Manager Monitor Keuangan"
  on "public"."salary"
  as permissive
  for select
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND ((profiles.role)::text = 'manager'::text)))));



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



  create policy "anon_delete_majunkita"
  on "storage"."objects"
  as permissive
  for delete
  to public
using ((bucket_id = 'majunkita'::text));



  create policy "anon_insert_majunkita"
  on "storage"."objects"
  as permissive
  for insert
  to public
with check ((bucket_id = 'majunkita'::text));



  create policy "anon_select_majunkita"
  on "storage"."objects"
  as permissive
  for select
  to public
using ((bucket_id = 'majunkita'::text));


-- CREATE TRIGGER protect_buckets_delete BEFORE DELETE ON storage.buckets FOR EACH STATEMENT EXECUTE FUNCTION storage.protect_delete();

-- CREATE TRIGGER protect_objects_delete BEFORE DELETE ON storage.objects FOR EACH STATEMENT EXECUTE FUNCTION storage.protect_delete();


