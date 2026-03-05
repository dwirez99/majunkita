-- ============================================================
-- MIGRATION: Add weight_per_sack to app_settings
-- Date: 2026-03-05
--
-- Adds the standard sack weight (kg) used for expedition
-- weight calculations.  Defaults to 50 kg per sack.
-- ============================================================

INSERT INTO public.app_settings (key, value, description)
VALUES (
  'weight_per_sack',
  '50',
  'Berat standar per karung untuk pengiriman expedisi (kilogram)'
)
ON CONFLICT (key) DO NOTHING;
