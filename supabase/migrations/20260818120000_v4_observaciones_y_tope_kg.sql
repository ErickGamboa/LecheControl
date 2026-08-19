-- LecheControl — Esquema v4: observaciones libres y tope de kilos por semana.
--
-- Qué cambia:
--   1. `eventos_animal.tipo` acepta `observacion`: una nota libre que el
--      ganadero escribe sobre la vaca desde la pantalla de Trabajo. El texto
--      va en `detalle`, que ya existía; no se agrega ninguna columna.
--   2. `config_reporte.tope_kg_leche`: cuántos kilos de leche espera entregar
--      la finca en una semana. Queda en NULL mientras no se configure, y sin
--      tope la app no muestra ninguna alerta.
--
-- Esta migración NO borra nada, así que se puede correr antes de actualizar
-- la app en los teléfonos: una versión vieja simplemente no usa lo nuevo.
--
-- Correr en: Supabase -> SQL Editor -> New query -> pegar y ejecutar.

-- 1. El evento de observación -------------------------------------------------

ALTER TABLE public.eventos_animal
  DROP CONSTRAINT IF EXISTS eventos_animal_tipo_check;

ALTER TABLE public.eventos_animal
  ADD CONSTRAINT eventos_animal_tipo_check
  CHECK (tipo IN (
    'sanidad', 'celo', 'monta', 'inseminacion', 'palpacion',
    'secado', 'parto', 'cambio_grupo', 'baja', 'concentrado',
    'observacion'
  ));

-- 2. El tope de kilos de leche ------------------------------------------------

ALTER TABLE public.config_reporte
  ADD COLUMN IF NOT EXISTS tope_kg_leche numeric;

ALTER TABLE public.config_reporte
  DROP CONSTRAINT IF EXISTS config_reporte_tope_kg_leche_check;

ALTER TABLE public.config_reporte
  ADD CONSTRAINT config_reporte_tope_kg_leche_check
  CHECK (tope_kg_leche IS NULL OR tope_kg_leche >= 0);
