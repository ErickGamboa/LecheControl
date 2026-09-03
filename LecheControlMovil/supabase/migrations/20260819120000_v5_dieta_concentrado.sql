-- LecheControl — Esquema v5: dieta de concentrado.
--
-- Qué cambia:
--   `config_reporte.kg_leche_por_kg_concentrado`: cuántos kilos de leche
--   "pagan" un kilo de concentrado. Con 3 (el valor con el que arranca), una
--   vaca que da 18 L debería comer 6 kg. Es la regla de la finca y se edita
--   desde Ajuste de métricas.
--
-- Esta migración NO borra nada y la columna trae DEFAULT, así que se puede
-- correr antes de actualizar la app en los teléfonos: una versión vieja
-- simplemente no la usa.
--
-- Correr en: Supabase -> SQL Editor -> New query -> pegar y ejecutar.

ALTER TABLE public.config_reporte
  ADD COLUMN IF NOT EXISTS kg_leche_por_kg_concentrado numeric NOT NULL
  DEFAULT 3;

ALTER TABLE public.config_reporte
  DROP CONSTRAINT IF EXISTS config_reporte_kg_leche_por_kg_concentrado_check;

-- Mayor que cero, no "mayor o igual": con 0 la ración sería una división por
-- cero y no hay dieta que calcular.
ALTER TABLE public.config_reporte
  ADD CONSTRAINT config_reporte_kg_leche_por_kg_concentrado_check
  CHECK (kg_leche_por_kg_concentrado > 0);
