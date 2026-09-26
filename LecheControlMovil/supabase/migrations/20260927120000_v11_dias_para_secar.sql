-- v11: a cuántos días del parto secar, por finca.
--
-- Hasta ahora eran 70 días fijos en el código de la app. Pasan a ser 65 y,
-- sobre todo, pasan a ser configurables: el período seco no es igual con toda
-- raza ni con todo manejo, y el ganadero lo ajusta en Ajuste de métricas junto
-- al tope de kg y la dieta.
--
-- ⚠️ HAY CLIENTES USANDO LA APP. Esta migración:
--   - agrega UNA columna con valor por defecto; no borra ni cambia nada;
--   - no toca animales, eventos, pesas ni finanzas;
--   - es idempotente: correrla dos veces da lo mismo.
--
-- Lo único que van a notar las fincas que ya existen es que «Vacas por secar»
-- avisa cinco días más tarde que antes (65 en vez de 70). Ninguna vaca se
-- pierde: la que ya estaba en la lista y le faltan menos de 65 sigue ahí.

BEGIN;

ALTER TABLE public.config_reporte
  ADD COLUMN IF NOT EXISTS dias_para_secar integer NOT NULL DEFAULT 65;

-- Mismo rango que valida la app. Sirve de red por si algún día algo escribe
-- por fuera: por debajo de 30 el período seco no alcanza para nada, y por
-- encima de 120 la lista se llena de vacas que todavía no hay que tocar.
DO $$
BEGIN
  ALTER TABLE public.config_reporte
    ADD CONSTRAINT config_reporte_dias_para_secar_check
    CHECK (dias_para_secar BETWEEN 30 AND 120);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- El `updated_at` sí hay que moverlo: el teléfono baja por el cursor
-- (updated_at, id) y si la fila se ve igual de vieja que siempre, nunca se la
-- vuelve a bajar y el número nuevo no llega. Pasó con los topes de fincas.
UPDATE public.config_reporte SET updated_at = now() WHERE deleted_at IS NULL;

COMMIT;

-- ---------------------------------------------------------------------------
-- Comprobación
-- ---------------------------------------------------------------------------

-- Una fila por finca, todas en 65 y con el `updated_at` de hoy.
SELECT l.nombre AS finca,
       c.dias_para_secar,
       c.updated_at
  FROM public.config_reporte c
  JOIN public.lecherias l ON l.id = c.lecheria_id
 WHERE c.deleted_at IS NULL
 ORDER BY l.nombre;
