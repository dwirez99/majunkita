-- Fix existing rows that were incorrectly set to 'terambil'
-- Update them to the correct status 'diambil_penjahit'
UPDATE public.percas_stock
SET status = 'diambil_penjahit'
WHERE status = 'terambil';
