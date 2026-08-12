-- LecheControl — Esquema v2, parte 2 de 2: LIMPIEZA (destructiva)
--
-- ⚠️  NO CORRER TODAVÍA. Este archivo borra tablas y columnas que la app
--     instalada hoy todavía lee. Correrlo antes de tiempo rompe la app.
--
-- Orden correcto:
--   1. Correr `20260810120000_v2_pesa_semanal_y_finanzas.sql`  (aditiva)
--   2. Actualizar la app (Fases 2 a 5) y verificar que funciona
--   3. Recién ahí correr este archivo
--
-- Qué borra y por qué:
--   - config_alertas       -> el módulo de Alertas sale de la app
--   - costos_fijos         -> lo reemplaza gastos_semana
--   - parametros_periodo   -> el período pasa de mes a semana; el precio del
--                             litro ya no se digita (sale de dividir lo que
--                             pagó la planta entre los litros de la semana) y
--                             umbral_secado_litros se mudó a config_reporte
--   - animales.concentrado_kg_dia -> lo reemplaza pesas_leche.concentrado_kg
--
-- ============================================================================
-- 0. Antes de borrar: revisá si hay datos que perderías
-- ============================================================================
-- Corré esto SOLO (sin el resto del archivo) y mirá los números. Si todo da
-- 0, podés borrar tranquilo. Si no, pasá esos datos a mano a las tablas
-- nuevas (gastos_semana) antes de seguir.
--
--   SELECT 'config_alertas' AS tabla, count(*) FROM public.config_alertas
--   UNION ALL SELECT 'costos_fijos', count(*) FROM public.costos_fijos
--   UNION ALL SELECT 'parametros_periodo', count(*) FROM public.parametros_periodo
--   UNION ALL SELECT 'animales con concentrado', count(*)
--     FROM public.animales WHERE concentrado_kg_dia > 0;

-- ============================================================================
-- 1. Alertas
-- ============================================================================
DROP TABLE IF EXISTS public.config_alertas;

-- ============================================================================
-- 2. Gastos mensuales (costos_fijos depende de parametros_periodo: va primero)
-- ============================================================================
DROP TABLE IF EXISTS public.costos_fijos;
DROP TABLE IF EXISTS public.parametros_periodo;

-- ============================================================================
-- 3. Concentrado: se mide por pesa, no como un valor fijo en la ficha
-- ============================================================================
ALTER TABLE public.animales
  DROP COLUMN IF EXISTS concentrado_kg_dia;
