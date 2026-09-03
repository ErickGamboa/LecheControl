-- LecheControl — Borrar el contenido de la finca para arrancar de cero
--
-- ⚠️  DESTRUCTIVO Y SIN VUELTA ATRÁS. Borra de verdad (DELETE, no borrado
--     suave): animales, eventos, pesas, medicamentos y lo que haya de gastos.
--
-- QUÉ SE MANTIENE:
--   - La cuenta, el usuario y el plan  -> seguís entrando con el mismo login.
--   - La lechería y su membresía       -> no hay que crearla de nuevo.
--   - La curva de referencia, los umbrales del reporte y las categorías de
--     gasto -> ya quedaron sembradas por la migración v2.
--
-- QUÉ SE BORRA:
--   - animales, eventos_animal, pesas_sesiones, pesas_leche
--   - medicamentos
--   - parametros_periodo, costos_fijos (el esquema viejo, mensual)
--   - semanas, ingresos_semana, gastos_semana, calidad_leche (por si ya se
--     probó algo)
--
-- Esto NO es una migración: no cambia el esquema, sólo vacía tablas. Por eso
-- vive en scripts/ y no en migrations/.
--
-- ============================================================================
-- IMPORTANTE — antes de correr esto, borrá los datos del teléfono/emulador
-- ============================================================================
-- La app guarda todo primero en el dispositivo y marca las filas nuevas como
-- `pendiente` hasta subirlas. Si borrás sólo el servidor, la próxima
-- sincronización vuelve a subir lo que quedó en el dispositivo y los datos
-- reaparecen.
--
-- Andá a Ajustes -> Aplicaciones -> LecheControl -> Almacenamiento ->
-- **Borrar datos** (o desinstalá y reinstalá la app). Hacelo en TODOS los
-- dispositivos donde se usó. Después corré este script.
--
-- ============================================================================
-- Antes de borrar: mirá qué te vas a llevar por delante
-- ============================================================================
-- Corré sólo esto primero, para no borrar a ciegas:
--
--   SELECT 'animales' AS tabla, count(*) FROM public.animales
--   UNION ALL SELECT 'eventos_animal', count(*) FROM public.eventos_animal
--   UNION ALL SELECT 'pesas_sesiones', count(*) FROM public.pesas_sesiones
--   UNION ALL SELECT 'pesas_leche', count(*) FROM public.pesas_leche
--   UNION ALL SELECT 'medicamentos', count(*) FROM public.medicamentos
--   UNION ALL SELECT 'parametros_periodo', count(*) FROM public.parametros_periodo
--   UNION ALL SELECT 'costos_fijos', count(*) FROM public.costos_fijos;

BEGIN;

-- El orden respeta las llaves foráneas: primero lo que apunta a otras tablas.
DELETE FROM public.pesas_leche;
DELETE FROM public.pesas_sesiones;

DELETE FROM public.calidad_leche;
DELETE FROM public.ingresos_semana;
DELETE FROM public.gastos_semana;
DELETE FROM public.semanas;

DELETE FROM public.costos_fijos;
DELETE FROM public.parametros_periodo;

-- eventos_animal apunta a animales (animal_id y cria_animal_id) y a
-- medicamentos: se va antes que los dos.
DELETE FROM public.eventos_animal;

-- animales se referencia a sí misma por madre_id. Se corta el vínculo antes
-- de borrar para que el DELETE no dependa del orden de las filas.
UPDATE public.animales SET madre_id = NULL;
DELETE FROM public.animales;

DELETE FROM public.medicamentos;

COMMIT;

-- Comprobación: todo esto debería dar 0.
SELECT 'animales' AS tabla, count(*) FROM public.animales
UNION ALL SELECT 'eventos_animal', count(*) FROM public.eventos_animal
UNION ALL SELECT 'pesas_sesiones', count(*) FROM public.pesas_sesiones
UNION ALL SELECT 'pesas_leche', count(*) FROM public.pesas_leche
UNION ALL SELECT 'medicamentos', count(*) FROM public.medicamentos;

-- Y esto debería seguir teniendo tus filas (lo que NO se borró):
SELECT 'lecherias' AS tabla, count(*) FROM public.lecherias
UNION ALL SELECT 'lecheria_miembros', count(*) FROM public.lecheria_miembros
UNION ALL SELECT 'curva_referencia', count(*) FROM public.curva_referencia
UNION ALL SELECT 'config_reporte', count(*) FROM public.config_reporte
UNION ALL SELECT 'categorias_gasto', count(*) FROM public.categorias_gasto;
