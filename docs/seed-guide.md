# Database Seed Guide — `supabase/seed.sql`

This guide explains how to use the `supabase/seed.sql` script to reset the MajunKita database to a clean state and populate it with realistic Indonesian dummy data for development and testing purposes.

---

## ⚠️ Warning

> **DO NOT run this script on a production database.**
> The script truncates **all** application tables before inserting fresh data.
> Back up any important data before running.

---

## Table of Contents

1. [What the Script Does](#what-the-script-does)
2. [Prerequisites](#prerequisites)
3. [How to Run](#how-to-run)
   - [Option A — Supabase SQL Editor (easiest)](#option-a--supabase-sql-editor-easiest)
   - [Option B — psql CLI](#option-b--psql-cli)
   - [Option C — Supabase CLI](#option-c--supabase-cli)
4. [Seeded Data Summary](#seeded-data-summary)
5. [Verify the Seed](#verify-the-seed)
6. [Limitations & Notes](#limitations--notes)
7. [Customizing the Seed](#customizing-the-seed)

---

## What the Script Does

`supabase/seed.sql` runs inside a single transaction (`BEGIN` / `COMMIT`) and performs the following steps in order:

| Step | Action |
|------|--------|
| 1 | `TRUNCATE` all public app tables with `RESTART IDENTITY CASCADE` (clears all rows and resets sequences) |
| 2 | Insert `app_settings` — sets `majun_price_per_kg = 3000` (required by the majun trigger) |
| 3 | Insert **3** `expedition_partners` (JNE, TIKI, SiCepat) |
| 4 | Insert **5** `factories` (pabrik) with real Indonesian addresses |
| 5 | Insert **22** `tailors` (penjahit) with realistic Indonesian names and phone numbers |
| 6 | Generate **15 months** of time-series data (January 2025 – March 2026): perca stock, perca distribution, majun returns, limbah returns, salary records, salary withdrawals, and majun warehouse stock |
| 7 | Truncate the WA notification queue tables that were auto-populated by database triggers during seeding |

---

## Prerequisites

- Access to your Supabase project (SQL Editor or connection string)
- All database migrations applied (`supabase db push` or Supabase Dashboard → Migrations)
- **Development / staging project only** — never a production project

---

## How to Run

### Option A — Supabase SQL Editor (easiest)

1. Open your project at [https://app.supabase.com](https://app.supabase.com).
2. Navigate to **SQL Editor** in the left sidebar.
3. Click **New query**.
4. Open `supabase/seed.sql` in a text editor, select all, and paste it into the SQL Editor.
5. Click **Run** (or press `Ctrl + Enter` / `Cmd + Enter`).
6. Wait for the "Success" message — the script typically completes in under 10 seconds.

---

### Option B — psql CLI

Find your connection string in Supabase Dashboard → **Project Settings → Database → Connection string (URI mode)**.

```bash
psql "postgresql://postgres:<password>@<host>:5432/<database>" \
  -f supabase/seed.sql
```

Or using individual flags:

```bash
psql \
  -h <host> \
  -p 5432 \
  -U postgres \
  -d postgres \
  -f supabase/seed.sql
```

You will be prompted for the database password.

---

### Option C — Supabase CLI

If you have the [Supabase CLI](https://supabase.com/docs/guides/cli) installed and linked to your project:

```bash
supabase db reset --local
```

For a linked remote project (staging), run:

```bash
supabase db reset --linked
```

> **Note:** `supabase db reset` re-applies migrations and then runs `supabase/seed.sql` automatically (based on `[db.seed]` in `supabase/config.toml`).
>
> ```bash
> supabase db reset --local
> ```

> **CLI compatibility note:** on some Supabase CLI versions (including `v2.76.9`), `supabase seed --local/--linked` may only show help text instead of executing SQL seed files. If that happens, use `supabase db reset --local` or `supabase db reset --linked`.

---

## Seeded Data Summary

After a successful run the database will contain:

| Table | Rows | Details |
|-------|------|---------|
| `factories` | 5 | PT/CV/UD with addresses across Java and Sumatra |
| `tailors` | 22 | Indonesian names, cities across Java/Sumatra/Sulawesi/Makassar |
| `expedition_partners` | 3 | JNE Express, TIKI, SiCepat Ekspres |
| `percas_stock` | 45 | 3 shipments/month × 15 months — **5,145 KG total** |
| `perca_transactions` | 330 | All 22 tailors receive perca every month |
| `majun_transactions` | 286 | Returns start month 3; `earned_wage` auto-calculated by trigger |
| `limbah_transactions` | 264 | Returns start month 4 |
| `salary` | 176 | Payroll entries every 2 months |
| `salary_withdrawals` | ~161 | Staggered withdrawals from month 5 onward |
| `majun_stock` | ~215 | Warehouse majun stock entries from month 3 onward |

**Date range:** 1 January 2025 – 31 March 2026 (15 months)

---

## Verify the Seed

Run this query in the Supabase SQL Editor immediately after seeding to confirm row counts and totals:

```sql
SELECT 'factories'              AS tabel, COUNT(*)::text  AS nilai FROM public.factories
UNION ALL
SELECT 'tailors',                          COUNT(*)::text          FROM public.tailors
UNION ALL
SELECT 'expedition_partners',              COUNT(*)::text          FROM public.expedition_partners
UNION ALL
SELECT 'percas_stock (rows)',              COUNT(*)::text          FROM public.percas_stock
UNION ALL
SELECT 'percas_stock total KG',            SUM(weight)::text       FROM public.percas_stock
UNION ALL
SELECT 'perca_transactions',               COUNT(*)::text          FROM public.perca_transactions
UNION ALL
SELECT 'majun_transactions',               COUNT(*)::text          FROM public.majun_transactions
UNION ALL
SELECT 'limbah_transactions',              COUNT(*)::text          FROM public.limbah_transactions
UNION ALL
SELECT 'salary',                           COUNT(*)::text          FROM public.salary
UNION ALL
SELECT 'salary_withdrawals',               COUNT(*)::text          FROM public.salary_withdrawals
UNION ALL
SELECT 'majun_stock',                      COUNT(*)::text          FROM public.majun_stock;
```

Check tailor stock and accumulated balance:

```sql
SELECT name, total_stock, balance
FROM public.tailors
ORDER BY name;
```

All `total_stock` values should be positive (each tailor retains 88–99 KG of unreturned perca).

---

## Limitations & Notes

| Item | Detail |
|------|--------|
| `profiles` not seeded | Depends on Supabase Auth (`auth.users`). Create users via the app or Supabase Dashboard → Authentication |
| `expeditions` not seeded | Requires `id_partner` pointing to a real `profiles.id` (auth user) |
| WA notification queue cleared | The `wa_notification_queue` and `wa_notification_logs` tables are truncated at the end of the script so dev seeding noise is removed |
| Deterministic output | The script uses integer arithmetic — no `random()`. Running it twice produces identical data |
| Safe for repeated runs | Fully idempotent — each run wipes and reseeds from scratch |

---

## Customizing the Seed

The seed is designed to be easy to extend:

### Add more tailors

Append rows to the `INSERT INTO public.tailors` block in **Langkah 5** and add the corresponding UUID to the `v_tailor_ids` array at the top of the `DO $$` block. The time-series loop will automatically include them.

### Change the date range

Adjust the loop bounds in the `DO $$` block. The loop variable `v_month_num IN 0..14` controls the 15-month span starting from `DATE '2025-01-01'`. Change `14` to extend the range (e.g. `23` for 24 months) or adjust the start date.

### Change the perca weight per shipment

Modify the formula on this line inside the `percas_stock` loop:

```sql
v_weight := 100 + ((v_month_num * 7 + v_shipment_num * 13) % 30);
```

The current formula produces values between 100 and 129 KG per shipment. Increase the base (`100`) or the modulus (`30`) to raise totals.

### Change the majun price

The `majun_price_per_kg` value inserted into `app_settings` controls the wage per kilogram calculated by the trigger. Change `'3000'` to any integer string (Rupiah per KG):

```sql
INSERT INTO public.app_settings (key, value, description)
VALUES ('majun_price_per_kg', '3500', 'Harga standar majun per kilogram (Rupiah)');
```
