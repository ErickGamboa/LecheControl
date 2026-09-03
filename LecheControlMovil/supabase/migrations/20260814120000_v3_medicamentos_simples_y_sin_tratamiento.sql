-- LecheControl — Esquema v3: medicamentos simples y adiós al grupo
-- "en tratamiento".
--
-- Qué cambia:
--   1. El medicamento se registra con nombre, dosis (texto, como dice la
--      etiqueta del frasco) y ml del envase. Se van el costo por envase, el
--      tipo de dosis, las aplicaciones por envase, la dosis fija en ml y los
--      días de retiro: la app ya no calcula costos por aplicación ni pide ml
--      aplicados. La plata de los medicamentos se anota como gasto de la
--      semana (categoría "Medicamentos").
--   2. "En tratamiento" deja de ser un grupo del hato: aplicar un medicamento
--      no saca a la vaca de su grupo. Los animales que quedaron ahí vuelven a
--      En ordeño.
--
-- OJO: esta migración SÍ borra columnas. Correrla DESPUÉS de actualizar la
-- app en los teléfonos: una versión vieja seguiría mandando `costo_envase` y
-- `tipo_dosis` en cada subida y le fallaría el sync de medicamentos.
--
-- Correr en: Supabase -> SQL Editor -> New query -> pegar y ejecutar.

-- ============================================================================
-- 1. Medicamentos: nombre + dosis + ml del envase
-- ============================================================================
ALTER TABLE public.medicamentos
  ADD COLUMN IF NOT EXISTS dosis_aplicacion text;

-- Rescate de lo que ya estaba cargado: la dosis fija en ml pasa a leerse como
-- texto ("10 ml") para no perder el dato al borrar la columna.
UPDATE public.medicamentos
  SET dosis_aplicacion = CASE
        WHEN dosis_fija_ml = trunc(dosis_fija_ml)
          THEN trunc(dosis_fija_ml)::bigint::text
        ELSE dosis_fija_ml::text
      END || ' ml'
  WHERE dosis_aplicacion IS NULL
    AND dosis_fija_ml IS NOT NULL
    AND dosis_fija_ml > 0;

ALTER TABLE public.medicamentos
  DROP COLUMN IF EXISTS costo_envase,
  DROP COLUMN IF EXISTS tipo_dosis,
  DROP COLUMN IF EXISTS aplicaciones_envase,
  DROP COLUMN IF EXISTS dosis_fija_ml,
  DROP COLUMN IF EXISTS dias_retiro_leche;

ALTER TABLE public.medicamentos
  DROP CONSTRAINT IF EXISTS medicamentos_ml_envase_check;

ALTER TABLE public.medicamentos
  ADD CONSTRAINT medicamentos_ml_envase_check
  CHECK (ml_envase IS NULL OR ml_envase >= 0);

-- ============================================================================
-- 2. El grupo "en tratamiento" desaparece
-- ============================================================================
-- Primero se mueven los animales, después se ajusta el CHECK: al revés, el
-- ALTER fallaría por las filas que todavía tienen el valor viejo.
UPDATE public.animales
  SET grupo = 'en_ordeno'
  WHERE grupo = 'en_tratamiento';

ALTER TABLE public.animales
  DROP CONSTRAINT IF EXISTS animales_grupo_check;

ALTER TABLE public.animales
  ADD CONSTRAINT animales_grupo_check
  CHECK (grupo IN ('en_ordeno', 'secas', 'novillas', 'terneros'));

-- Nota: el estado "pronta" (a la vaca le falta poco para parir) NO se guarda.
-- Se deduce de `animales.fecha_probable_parto`, justamente para que la vaca no
-- tenga que salir de Secas para estar pronta.
