-- LecheControl — Esquema v2, parte 1 de 2: ADITIVA (segura de correr)
--
-- Reorienta la app a las tres partes del negocio:
--   1. Inventario de ganado y eventos  (sin cambios de esquema aquí)
--   2. Pesa de leche semanal + reporte de producción
--   3. Ingresos y gastos semanales -> utilidad semanal
--
-- Esta migración SOLO agrega y afloja restricciones. No borra nada ni rompe
-- la app que está instalada hoy: las columnas y tablas viejas siguen ahí.
-- Los borrados van en la parte 2 (`..._v2_limpieza.sql`), que se corre
-- DESPUÉS de actualizar la app.
--
-- Correr en: Supabase -> SQL Editor -> New query -> pegar y ejecutar.
--
-- Convenciones heredadas de v1 (no cambian):
--   - id uuid generado en el cliente antes de insertar.
--   - updated_at SIEMPRE lo fija el servidor (default now() + trigger).
--   - deleted_at: borrado suave, nada se borra de verdad.
--   - Aislamiento por lechería vía private.es_miembro_lecheria().

-- ============================================================================
-- 1. Pesa de leche: mañana + tarde + concentrado, y vacas manuales
-- ============================================================================
-- Antes se guardaba un solo valor `litros` por vaca por sesión. El reporte de
-- producción necesita el desglose por ordeño y los kg de concentrado que come
-- cada vaca (se capturan en la misma pesa).
--
-- `litros` se conserva y pasa a ser el TOTAL del día (mañana + tarde). Lo
-- sigue escribiendo el cliente para no romper el motor de sync. Las filas
-- viejas quedan con litros_manana/litros_tarde en NULL: el reporte las
-- muestra como "sin desglose" en vez de inventar un reparto falso.

ALTER TABLE public.pesas_leche
  ADD COLUMN IF NOT EXISTS litros_manana numeric
    CHECK (litros_manana IS NULL OR litros_manana >= 0),
  ADD COLUMN IF NOT EXISTS litros_tarde numeric
    CHECK (litros_tarde IS NULL OR litros_tarde >= 0),
  ADD COLUMN IF NOT EXISTS concentrado_kg numeric
    CHECK (concentrado_kg IS NULL OR concentrado_kg >= 0);

COMMENT ON COLUMN public.pesas_leche.litros IS
  'Total del día = litros_manana + litros_tarde. Lo calcula y escribe el cliente.';
COMMENT ON COLUMN public.pesas_leche.concentrado_kg IS
  'Kg de concentrado que comió la vaca ese día. Reemplaza a animales.concentrado_kg_dia.';

-- ---------------------------------------------------------------- vacas manuales
-- En el reporte del cliente hay vacas que se pesan pero no están en el
-- inventario (aparecen como "2023*", "8890*", sin días de lactancia). Se
-- registran con un identificador suelto y sin ficha de animal.
ALTER TABLE public.pesas_leche
  ALTER COLUMN animal_id DROP NOT NULL;

ALTER TABLE public.pesas_leche
  ADD COLUMN IF NOT EXISTS identificador_manual text;

-- Exactamente uno de los dos: o es una vaca del inventario, o es manual.
ALTER TABLE public.pesas_leche
  DROP CONSTRAINT IF EXISTS pesas_leche_animal_o_manual;
ALTER TABLE public.pesas_leche
  ADD CONSTRAINT pesas_leche_animal_o_manual CHECK (
    (animal_id IS NOT NULL AND identificador_manual IS NULL)
    OR (animal_id IS NULL AND identificador_manual IS NOT NULL)
  );

COMMENT ON COLUMN public.pesas_leche.identificador_manual IS
  'Vaca pesada que no está en inventario (sin ficha ni días de lactancia).';

-- La política de INSERT/UPDATE de pesas_leche valida por join con
-- pesas_sesiones, que no cambia: sigue funcionando con animal_id NULL.

-- ============================================================================
-- 2. Días de lactancia (DLac)
-- ============================================================================
-- El reporte entero se apoya en cuántos días lleva la vaca desde su último
-- parto. Se deriva del evento `parto`, pero las vacas que ya están en la
-- finca no tienen ese evento registrado: hay que poder cargarles la fecha a
-- mano una sola vez. La mantiene al día el evento de parto.
ALTER TABLE public.animales
  ADD COLUMN IF NOT EXISTS fecha_ultimo_parto timestamptz;

COMMENT ON COLUMN public.animales.fecha_ultimo_parto IS
  'Base para los días de lactancia (DLac). La fija el evento parto; editable '
  'a mano para cargar las vacas que ya estaban en la finca.';

-- ============================================================================
-- 3. Curva de referencia: litros esperados según días de lactancia
-- ============================================================================
-- Siete tramos editables por lechería. Para una vaca concreta el valor
-- esperado NO es el escalón del tramo: la app interpola entre el punto
-- central de cada tramo, para que la curva suba y baje suave y una vaca no
-- salte de "Excelente" a "Muy Bajo" por cumplir un día más.
--
-- Punto central que usa la app: (dia_desde + dia_hasta) / 2. Para el último
-- tramo (dia_hasta NULL, "más de 305 días") usa dia_desde + 25.
CREATE TABLE IF NOT EXISTS public.curva_referencia (
  id uuid PRIMARY KEY,
  lecheria_id uuid NOT NULL REFERENCES public.lecherias (id),
  orden integer NOT NULL,
  dia_desde integer NOT NULL CHECK (dia_desde >= 0),
  dia_hasta integer CHECK (dia_hasta IS NULL OR dia_hasta > dia_desde),
  litros_esperados numeric NOT NULL CHECK (litros_esperados >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_curva_referencia_lecheria_tramo
  ON public.curva_referencia (lecheria_id, dia_desde)
  WHERE deleted_at IS NULL;

ALTER TABLE public.curva_referencia ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS curva_referencia_select ON public.curva_referencia;
CREATE POLICY curva_referencia_select ON public.curva_referencia
  FOR SELECT USING (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DROP POLICY IF EXISTS curva_referencia_insert ON public.curva_referencia;
CREATE POLICY curva_referencia_insert ON public.curva_referencia
  FOR INSERT WITH CHECK (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DROP POLICY IF EXISTS curva_referencia_update ON public.curva_referencia;
CREATE POLICY curva_referencia_update ON public.curva_referencia
  FOR UPDATE USING (private.es_miembro_lecheria(lecheria_id, auth.uid()))
  WITH CHECK (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_curva_referencia_updated_at'
  ) THEN
    CREATE TRIGGER trg_curva_referencia_updated_at
      BEFORE UPDATE ON public.curva_referencia
      FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

-- Valores iniciales para las lecherías que ya existen. Son los del reporte
-- que trajo el cliente: un punto de partida, no una verdad. Se editan desde
-- la app y se pueden recalibrar con el promedio real del hato.
-- (La app siembra estos mismos siete tramos al abrir una lechería nueva.)
INSERT INTO public.curva_referencia
  (id, lecheria_id, orden, dia_desde, dia_hasta, litros_esperados)
SELECT gen_random_uuid(), l.id, t.orden, t.dia_desde, t.dia_hasta, t.litros
FROM public.lecherias l
CROSS JOIN (VALUES
  (1,   0,   30,  18.8),
  (2,  31,   70,  26.0),
  (3,  71,  120,  24.0),
  (4, 121,  180,  21.0),
  (5, 181,  240,  18.0),
  (6, 241,  305,  14.0),
  (7, 306, NULL,  10.0)
) AS t(orden, dia_desde, dia_hasta, litros)
WHERE l.deleted_at IS NULL
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 4. Umbrales del reporte de producción
-- ============================================================================
-- Cómo se etiqueta una vaca según (lo que dio ÷ lo que se esperaba). Una
-- fila por lechería. `umbral_secado_litros` se muda acá desde
-- parametros_periodo, que desaparece en la parte 2.
CREATE TABLE IF NOT EXISTS public.config_reporte (
  id uuid PRIMARY KEY,
  lecheria_id uuid NOT NULL REFERENCES public.lecherias (id),
  pct_excelente numeric NOT NULL DEFAULT 100 CHECK (pct_excelente >= 0),
  pct_bueno numeric NOT NULL DEFAULT 85 CHECK (pct_bueno >= 0),
  pct_vigilar numeric NOT NULL DEFAULT 70 CHECK (pct_vigilar >= 0),
  pct_bajo numeric NOT NULL DEFAULT 60 CHECK (pct_bajo >= 0),
  umbral_secado_litros numeric NOT NULL DEFAULT 8 CHECK (umbral_secado_litros >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_config_reporte_lecheria
  ON public.config_reporte (lecheria_id)
  WHERE deleted_at IS NULL;

ALTER TABLE public.config_reporte ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS config_reporte_select ON public.config_reporte;
CREATE POLICY config_reporte_select ON public.config_reporte
  FOR SELECT USING (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DROP POLICY IF EXISTS config_reporte_insert ON public.config_reporte;
CREATE POLICY config_reporte_insert ON public.config_reporte
  FOR INSERT WITH CHECK (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DROP POLICY IF EXISTS config_reporte_update ON public.config_reporte;
CREATE POLICY config_reporte_update ON public.config_reporte
  FOR UPDATE USING (private.es_miembro_lecheria(lecheria_id, auth.uid()))
  WITH CHECK (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_config_reporte_updated_at'
  ) THEN
    CREATE TRIGGER trg_config_reporte_updated_at
      BEFORE UPDATE ON public.config_reporte
      FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

INSERT INTO public.config_reporte (id, lecheria_id)
SELECT gen_random_uuid(), l.id
FROM public.lecherias l
WHERE l.deleted_at IS NULL
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 5. Finanzas semanales
-- ============================================================================
-- El período pasa de mes calendario a SEMANA (lunes a domingo). Cada semana
-- se registran los ingresos que entraron y los gastos que salieron, y la
-- utilidad es la resta. Los ingresos ya no se calculan (litros × precio):
-- se digita la plata que efectivamente entró.

CREATE TABLE IF NOT EXISTS public.semanas (
  id uuid PRIMARY KEY,
  lecheria_id uuid NOT NULL REFERENCES public.lecherias (id),
  fecha_inicio date NOT NULL,
  fecha_fin date NOT NULL CHECK (fecha_fin > fecha_inicio),
  cerrada boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_semanas_lecheria_inicio
  ON public.semanas (lecheria_id, fecha_inicio)
  WHERE deleted_at IS NULL;

COMMENT ON COLUMN public.semanas.fecha_inicio IS
  'Lunes de la semana. fecha_fin es el domingo siguiente.';

ALTER TABLE public.semanas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS semanas_select ON public.semanas;
CREATE POLICY semanas_select ON public.semanas
  FOR SELECT USING (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DROP POLICY IF EXISTS semanas_insert ON public.semanas;
CREATE POLICY semanas_insert ON public.semanas
  FOR INSERT WITH CHECK (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DROP POLICY IF EXISTS semanas_update ON public.semanas;
CREATE POLICY semanas_update ON public.semanas
  FOR UPDATE USING (private.es_miembro_lecheria(lecheria_id, auth.uid()))
  WITH CHECK (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_semanas_updated_at'
  ) THEN
    CREATE TRIGGER trg_semanas_updated_at
      BEFORE UPDATE ON public.semanas
      FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

-- ---------------------------------------------------------------- ingresos
CREATE TABLE IF NOT EXISTS public.ingresos_semana (
  id uuid PRIMARY KEY,
  lecheria_id uuid NOT NULL REFERENCES public.lecherias (id),
  semana_id uuid NOT NULL REFERENCES public.semanas (id),
  tipo text NOT NULL CHECK (tipo IN ('leche', 'venta_ganado', 'otro')),
  monto numeric NOT NULL CHECK (monto >= 0),
  litros numeric CHECK (litros IS NULL OR litros >= 0),
  animal_id uuid REFERENCES public.animales (id),
  detalle text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_ingresos_semana_semana
  ON public.ingresos_semana (semana_id)
  WHERE deleted_at IS NULL;

COMMENT ON COLUMN public.ingresos_semana.litros IS
  'Solo para tipo=leche: litros que la planta pagó. monto ÷ litros da el '
  'precio real por litro de esa semana, que es lo que usa la rentabilidad '
  'por vaca (plata real, no un precio estimado).';
COMMENT ON COLUMN public.ingresos_semana.animal_id IS
  'Solo para tipo=venta_ganado: qué animal se vendió, para su hoja de vida.';

ALTER TABLE public.ingresos_semana ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS ingresos_semana_select ON public.ingresos_semana;
CREATE POLICY ingresos_semana_select ON public.ingresos_semana
  FOR SELECT USING (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DROP POLICY IF EXISTS ingresos_semana_insert ON public.ingresos_semana;
CREATE POLICY ingresos_semana_insert ON public.ingresos_semana
  FOR INSERT WITH CHECK (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DROP POLICY IF EXISTS ingresos_semana_update ON public.ingresos_semana;
CREATE POLICY ingresos_semana_update ON public.ingresos_semana
  FOR UPDATE USING (private.es_miembro_lecheria(lecheria_id, auth.uid()))
  WITH CHECK (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_ingresos_semana_updated_at'
  ) THEN
    CREATE TRIGGER trg_ingresos_semana_updated_at
      BEFORE UPDATE ON public.ingresos_semana
      FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

-- ---------------------------------------------------------------- gastos
CREATE TABLE IF NOT EXISTS public.gastos_semana (
  id uuid PRIMARY KEY,
  lecheria_id uuid NOT NULL REFERENCES public.lecherias (id),
  semana_id uuid NOT NULL REFERENCES public.semanas (id),
  categoria text NOT NULL,
  monto numeric NOT NULL CHECK (monto >= 0),
  detalle text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_gastos_semana_semana
  ON public.gastos_semana (semana_id)
  WHERE deleted_at IS NULL;

ALTER TABLE public.gastos_semana ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS gastos_semana_select ON public.gastos_semana;
CREATE POLICY gastos_semana_select ON public.gastos_semana
  FOR SELECT USING (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DROP POLICY IF EXISTS gastos_semana_insert ON public.gastos_semana;
CREATE POLICY gastos_semana_insert ON public.gastos_semana
  FOR INSERT WITH CHECK (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DROP POLICY IF EXISTS gastos_semana_update ON public.gastos_semana;
CREATE POLICY gastos_semana_update ON public.gastos_semana
  FOR UPDATE USING (private.es_miembro_lecheria(lecheria_id, auth.uid()))
  WITH CHECK (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_gastos_semana_updated_at'
  ) THEN
    CREATE TRIGGER trg_gastos_semana_updated_at
      BEFORE UPDATE ON public.gastos_semana
      FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

-- ---------------------------------------------------------------- categorías
-- Para que meter un gasto sea tocar y no escribir. El usuario puede agregar
-- las suyas; estas son las que mencionó el cliente.
CREATE TABLE IF NOT EXISTS public.categorias_gasto (
  id uuid PRIMARY KEY,
  lecheria_id uuid NOT NULL REFERENCES public.lecherias (id),
  nombre text NOT NULL,
  orden integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_categorias_gasto_lecheria_nombre
  ON public.categorias_gasto (lecheria_id, nombre)
  WHERE deleted_at IS NULL;

ALTER TABLE public.categorias_gasto ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS categorias_gasto_select ON public.categorias_gasto;
CREATE POLICY categorias_gasto_select ON public.categorias_gasto
  FOR SELECT USING (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DROP POLICY IF EXISTS categorias_gasto_insert ON public.categorias_gasto;
CREATE POLICY categorias_gasto_insert ON public.categorias_gasto
  FOR INSERT WITH CHECK (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DROP POLICY IF EXISTS categorias_gasto_update ON public.categorias_gasto;
CREATE POLICY categorias_gasto_update ON public.categorias_gasto
  FOR UPDATE USING (private.es_miembro_lecheria(lecheria_id, auth.uid()))
  WITH CHECK (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_categorias_gasto_updated_at'
  ) THEN
    CREATE TRIGGER trg_categorias_gasto_updated_at
      BEFORE UPDATE ON public.categorias_gasto
      FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

INSERT INTO public.categorias_gasto (id, lecheria_id, nombre, orden)
SELECT gen_random_uuid(), l.id, c.nombre, c.orden
FROM public.lecherias l
CROSS JOIN (VALUES
  ('Salario del peón', 1),
  ('Concentrado', 2),
  ('Medicamentos', 3),
  ('Cerca', 4),
  ('Combustible', 5),
  ('Transporte de leche', 6),
  ('Otros', 7)
) AS c(nombre, orden)
WHERE l.deleted_at IS NULL
ON CONFLICT DO NOTHING;
