-- LecheControl — Esquema v6: calidad de la leche entregada.
--
-- Qué cambia:
--   Entra `calidad_leche`: lo que la planta reporta cada semana de la leche
--   que se le entregó —sólidos totales (%), células somáticas (cél./mL) y
--   conteo bacterial (UFC/mL)—. Son datos que llegan de afuera: la app solo
--   los guarda, los grafica y dice en qué escalón cayó cada uno.
--
--   La semana es la misma de las finanzas (`semanas`, lunes a domingo), así
--   que la calidad cuelga de `semana_id` y no lleva su propio calendario.
--
-- Los tres análisis son opcionales por separado: la planta no siempre manda
-- los tres el mismo día, y media semana cargada sirve más que ninguna. Lo que
-- no puede haber son dos lecturas para la misma semana — de ahí el índice
-- único: si llega otra, se corrige la que está.
--
-- Esta migración SOLO agrega una tabla. No borra nada ni toca lo que ya está,
-- así que se puede correr antes de actualizar la app en los teléfonos: una
-- versión vieja simplemente no la usa.
--
-- Correr en: Supabase -> SQL Editor -> New query -> pegar y ejecutar.

CREATE TABLE IF NOT EXISTS public.calidad_leche (
  id uuid PRIMARY KEY,
  lecheria_id uuid NOT NULL REFERENCES public.lecherias (id),
  semana_id uuid NOT NULL REFERENCES public.semanas (id),
  solidos_totales_pct numeric
    CHECK (solidos_totales_pct IS NULL
           OR (solidos_totales_pct >= 0 AND solidos_totales_pct <= 100)),
  celulas_somaticas numeric
    CHECK (celulas_somaticas IS NULL OR celulas_somaticas >= 0),
  conteo_bacterial numeric
    CHECK (conteo_bacterial IS NULL OR conteo_bacterial >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

COMMENT ON TABLE public.calidad_leche IS
  'Análisis de calidad que reporta la planta, uno por semana de la finca.';
COMMENT ON COLUMN public.calidad_leche.solidos_totales_pct IS
  'Grasa + proteína + lactosa y minerales, en % del peso.';
COMMENT ON COLUMN public.calidad_leche.celulas_somaticas IS
  'Recuento de células somáticas, en células por mL.';
COMMENT ON COLUMN public.calidad_leche.conteo_bacterial IS
  'Recuento bacterial, en UFC por mL. Es el que define el grado de pago.';

-- Una sola lectura por semana: si llega otra se corrige la que hay, no se
-- guardan dos verdades para la misma semana.
CREATE UNIQUE INDEX IF NOT EXISTS idx_calidad_leche_lecheria_semana
  ON public.calidad_leche (lecheria_id, semana_id)
  WHERE deleted_at IS NULL;

ALTER TABLE public.calidad_leche ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS calidad_leche_select ON public.calidad_leche;
CREATE POLICY calidad_leche_select ON public.calidad_leche
  FOR SELECT USING (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DROP POLICY IF EXISTS calidad_leche_insert ON public.calidad_leche;
CREATE POLICY calidad_leche_insert ON public.calidad_leche
  FOR INSERT WITH CHECK (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DROP POLICY IF EXISTS calidad_leche_update ON public.calidad_leche;
CREATE POLICY calidad_leche_update ON public.calidad_leche
  FOR UPDATE USING (private.es_miembro_lecheria(lecheria_id, auth.uid()))
  WITH CHECK (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_calidad_leche_updated_at'
  ) THEN
    CREATE TRIGGER trg_calidad_leche_updated_at
      BEFORE UPDATE ON public.calidad_leche
      FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;
