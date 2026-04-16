-- ============================================================
-- MIGRATION: Add WA queue trigger for salary withdrawals
-- Date: 2026-04-15
--
-- Adds:
--   - AFTER INSERT trigger on public.salary_withdrawals
--   - Enqueues WhatsApp confirmation notification to tailor
-- ============================================================

CREATE OR REPLACE FUNCTION public.trg_enqueue_wa_salary_withdrawal()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tailor_name TEXT;
  v_tailor_phone TEXT;
  v_current_balance NUMERIC;
BEGIN
  SELECT t.name, t.no_telp, COALESCE(t.balance, 0)
  INTO v_tailor_name, v_tailor_phone, v_current_balance
  FROM public.tailors t
  WHERE t.id = NEW.id_tailor;

  PERFORM public.enqueue_wa_notification(
    'penarikan_upah',
    'salary_withdrawals',
    NEW.id_tailor,
    'penjahit',
    v_tailor_phone,
    format(
      'Konfirmasi Penarikan Upah #%s. Penjahit: %s. Nominal: Rp%s. Estimasi sisa saldo: Rp%s.',
      NEW.id::text,
      COALESCE(v_tailor_name, '-'),
      NEW.amount::text,
      GREATEST(v_current_balance - COALESCE(NEW.amount, 0), 0)::text
    ),
    NULL
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enqueue_wa_salary_withdrawal ON public.salary_withdrawals;
CREATE TRIGGER trg_enqueue_wa_salary_withdrawal
  AFTER INSERT ON public.salary_withdrawals
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_enqueue_wa_salary_withdrawal();
