-- LecheControl — Esquema v1 completo (bootstrap RLS + todas las tablas de dominio)
-- Ejecutar una sola vez en un proyecto de Supabase nuevo y vacío
-- (Supabase → SQL Editor → New query → pegar y correr).
--
-- Espejo exacto de lib/data/local/database.dart (columnas snake_case) y de
-- los mapas remotos de lib/data/sync/sync_service.dart. Las tablas
-- SyncCursores, SyncEstados y SesionesLocales son SOLO LOCALES (viven en
-- SQLite) y no tienen equivalente aquí.
--
-- Convenciones:
--   - id uuid: generado en el cliente (Uuid().v4()) antes de insertar.
--   - created_at: fijado por el cliente al crear (no cambia con el sync).
--   - updated_at: SIEMPRE lo fija el servidor (default now() + trigger en
--     cada UPDATE); el cliente nunca lo manda. "Gana el último que escribe".
--   - deleted_at: borrado suave (D-08 del spec: nada se borra de verdad).
--   - Todo dato de una lechería queda aislado por RLS: solo sus miembros
--     (lecheria_miembros) pueden leerlo/escribirlo.

-- ============================================================================
-- 1. Esquema privado + función de trigger updated_at
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS private;

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- ============================================================================
-- 2. Tablas de licenciamiento (planes, cuentas, usuarios) — solo lectura
--    desde el cliente (SyncService las declara pull-only). Las crea/edita el
--    administrador (vía SQL Editor o un panel interno, fuera de esta app).
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.planes (
  codigo text PRIMARY KEY CHECK (codigo IN ('invitado', 'light', 'medium', 'pro')),
  nombre text NOT NULL,
  limite_lecherias integer NOT NULL CHECK (limite_lecherias > 0),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.planes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS planes_select ON public.planes;
CREATE POLICY planes_select ON public.planes
  FOR SELECT USING (auth.uid() IS NOT NULL);

INSERT INTO public.planes (codigo, nombre, limite_lecherias)
VALUES
  ('invitado', 'Invitado (prueba gratis)', 1),
  ('light', 'Light', 1),
  ('medium', 'Medium', 1),
  ('pro', 'Pro', 5)
ON CONFLICT (codigo) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.cuentas (
  id uuid PRIMARY KEY,
  nombre text NOT NULL,
  dueno_id uuid NOT NULL REFERENCES auth.users (id),
  plan text NOT NULL DEFAULT 'invitado' REFERENCES public.planes (codigo),
  estado text NOT NULL DEFAULT 'activa' CHECK (estado IN ('activa', 'suspendida')),
  prueba_termina timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_cuentas_dueno ON public.cuentas (dueno_id);

ALTER TABLE public.cuentas ENABLE ROW LEVEL SECURITY;

-- Políticas de SELECT de cuentas se crean DESPUÉS de public.usuarios
-- (más abajo) porque referencian esa tabla.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_cuentas_updated_at'
  ) THEN
    CREATE TRIGGER trg_cuentas_updated_at
      BEFORE UPDATE ON public.cuentas
      FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

-- Perfil de cada usuario autenticado. id = auth.uid(). Se crea junto con la
-- cuenta cuando el administrador da de alta al ganadero.
CREATE TABLE IF NOT EXISTS public.usuarios (
  id uuid PRIMARY KEY REFERENCES auth.users (id),
  nombre text,
  email text,
  cuenta_id uuid REFERENCES public.cuentas (id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_usuarios_cuenta ON public.usuarios (cuenta_id);

ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;

-- Política de SELECT de usuarios se crea DESPUÉS de lecheria_miembros
-- (más abajo) porque la referencia.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_usuarios_updated_at'
  ) THEN
    CREATE TRIGGER trg_usuarios_updated_at
      BEFORE UPDATE ON public.usuarios
      FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

-- ============================================================================
-- 3. Helpers de RLS por lechería (deben crearse DESPUÉS de lecheria_miembros,
--    pero los declaramos ya arriba con SECURITY DEFINER para poder usarlos en
--    las políticas de la propia tabla lecheria_miembros más abajo).
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.lecherias (
  id uuid PRIMARY KEY,
  nombre text NOT NULL,
  creada_por uuid NOT NULL REFERENCES auth.users (id),
  cuenta_id uuid REFERENCES public.cuentas (id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_lecherias_cuenta ON public.lecherias (cuenta_id);

CREATE TABLE IF NOT EXISTS public.lecheria_miembros (
  id uuid PRIMARY KEY,
  lecheria_id uuid NOT NULL REFERENCES public.lecherias (id),
  usuario_id uuid NOT NULL REFERENCES auth.users (id),
  rol text NOT NULL DEFAULT 'operario' CHECK (rol IN ('admin', 'operario')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_lecheria_miembros_activos
  ON public.lecheria_miembros (lecheria_id, usuario_id)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_lecheria_miembros_usuario
  ON public.lecheria_miembros (usuario_id)
  WHERE deleted_at IS NULL;

-- True si p_user_id es miembro activo (cualquier rol) de la lechería.
CREATE OR REPLACE FUNCTION private.es_miembro_lecheria(p_lecheria_id uuid, p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, private
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.lecheria_miembros lm
    WHERE lm.lecheria_id = p_lecheria_id
      AND lm.usuario_id = p_user_id
      AND lm.deleted_at IS NULL
  );
$$;

-- True si p_user_id es miembro admin activo de la lechería.
CREATE OR REPLACE FUNCTION private.es_admin_lecheria(p_lecheria_id uuid, p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, private
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.lecheria_miembros lm
    WHERE lm.lecheria_id = p_lecheria_id
      AND lm.usuario_id = p_user_id
      AND lm.rol = 'admin'
      AND lm.deleted_at IS NULL
  );
$$;

REVOKE ALL ON SCHEMA private FROM PUBLIC;
GRANT USAGE ON SCHEMA private TO postgres, authenticated, service_role;

REVOKE ALL ON FUNCTION private.es_miembro_lecheria(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.es_miembro_lecheria(uuid, uuid) TO authenticated, service_role;

REVOKE ALL ON FUNCTION private.es_admin_lecheria(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.es_admin_lecheria(uuid, uuid) TO authenticated, service_role;

-- ---------------------------------------------------------------- lecherias RLS
ALTER TABLE public.lecherias ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS lecherias_select ON public.lecherias;
CREATE POLICY lecherias_select ON public.lecherias
  FOR SELECT USING (
    private.es_miembro_lecheria(id, auth.uid())
    OR creada_por = auth.uid()
  );

-- El alta ocurre en la misma transacción local que la membresía (Módulo 0):
-- se permite crear si el usuario se declara como creador; la membresía como
-- admin se sube justo después.
DROP POLICY IF EXISTS lecherias_insert ON public.lecherias;
CREATE POLICY lecherias_insert ON public.lecherias
  FOR INSERT WITH CHECK (creada_por = auth.uid());

DROP POLICY IF EXISTS lecherias_update ON public.lecherias;
CREATE POLICY lecherias_update ON public.lecherias
  FOR UPDATE USING (private.es_miembro_lecheria(id, auth.uid()))
  WITH CHECK (private.es_miembro_lecheria(id, auth.uid()));

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_lecherias_updated_at'
  ) THEN
    CREATE TRIGGER trg_lecherias_updated_at
      BEFORE UPDATE ON public.lecherias
      FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

-- ---------------------------------------------------------------- lecheria_miembros RLS
ALTER TABLE public.lecheria_miembros ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS lecheria_miembros_select ON public.lecheria_miembros;
CREATE POLICY lecheria_miembros_select ON public.lecheria_miembros
  FOR SELECT USING (
    private.es_miembro_lecheria(lecheria_id, auth.uid())
    OR usuario_id = auth.uid()
  );

-- Se permite agregarse a sí mismo (alta de lechería nueva, Módulo 0) o que
-- un admin agregue a otro miembro (invitar operarios).
DROP POLICY IF EXISTS lecheria_miembros_insert ON public.lecheria_miembros;
CREATE POLICY lecheria_miembros_insert ON public.lecheria_miembros
  FOR INSERT WITH CHECK (
    usuario_id = auth.uid()
    OR private.es_admin_lecheria(lecheria_id, auth.uid())
  );

DROP POLICY IF EXISTS lecheria_miembros_update ON public.lecheria_miembros;
CREATE POLICY lecheria_miembros_update ON public.lecheria_miembros
  FOR UPDATE USING (private.es_admin_lecheria(lecheria_id, auth.uid()))
  WITH CHECK (private.es_admin_lecheria(lecheria_id, auth.uid()));

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_lecheria_miembros_updated_at'
  ) THEN
    CREATE TRIGGER trg_lecheria_miembros_updated_at
      BEFORE UPDATE ON public.lecheria_miembros
      FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

-- Políticas diferidas (dependían de tablas creadas más arriba).
DROP POLICY IF EXISTS cuentas_select ON public.cuentas;
CREATE POLICY cuentas_select ON public.cuentas
  FOR SELECT USING (
    dueno_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid() AND u.cuenta_id = cuentas.id
    )
  );

DROP POLICY IF EXISTS usuarios_select ON public.usuarios;
CREATE POLICY usuarios_select ON public.usuarios
  FOR SELECT USING (
    id = auth.uid()
    OR EXISTS (
      SELECT 1
      FROM public.lecheria_miembros lm1
      JOIN public.lecheria_miembros lm2 ON lm2.lecheria_id = lm1.lecheria_id
      WHERE lm1.usuario_id = auth.uid()
        AND lm1.deleted_at IS NULL
        AND lm2.usuario_id = usuarios.id
        AND lm2.deleted_at IS NULL
    )
  );

-- ============================================================================
-- 4. Animales (Módulo 1 y 2)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.animales (
  id uuid PRIMARY KEY,
  lecheria_id uuid NOT NULL REFERENCES public.lecherias (id),
  identificador text NOT NULL,
  sexo text NOT NULL CHECK (sexo IN ('hembra', 'macho')),
  grupo text NOT NULL CHECK (grupo IN ('en_ordeno', 'secas', 'novillas', 'terneros', 'en_tratamiento')),
  estado text NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo', 'vendido', 'muerto', 'descartado')),
  estado_reproductivo text NOT NULL DEFAULT 'desconocido' CHECK (estado_reproductivo IN ('vacia', 'preñada', 'desconocido')),
  origen text NOT NULL CHECK (origen IN ('comprado', 'nacido')),
  precio_compra numeric CHECK (precio_compra IS NULL OR precio_compra >= 0),
  fecha_compra timestamptz,
  madre_id uuid REFERENCES public.animales (id),
  concentrado_kg_dia numeric NOT NULL DEFAULT 0 CHECK (concentrado_kg_dia >= 0),
  fecha_probable_parto timestamptz,
  retiro_leche_hasta timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_animales_lecheria_identificador_activos
  ON public.animales (lecheria_id, identificador)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_animales_lecheria ON public.animales (lecheria_id)
  WHERE deleted_at IS NULL;

ALTER TABLE public.animales ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS animales_select ON public.animales;
CREATE POLICY animales_select ON public.animales
  FOR SELECT USING (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DROP POLICY IF EXISTS animales_insert ON public.animales;
CREATE POLICY animales_insert ON public.animales
  FOR INSERT WITH CHECK (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DROP POLICY IF EXISTS animales_update ON public.animales;
CREATE POLICY animales_update ON public.animales
  FOR UPDATE USING (private.es_miembro_lecheria(lecheria_id, auth.uid()))
  WITH CHECK (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_animales_updated_at'
  ) THEN
    CREATE TRIGGER trg_animales_updated_at
      BEFORE UPDATE ON public.animales
      FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

-- ============================================================================
-- 5. Eventos del animal / hoja de vida (Módulo 1 y 6)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.eventos_animal (
  id uuid PRIMARY KEY,
  animal_id uuid NOT NULL REFERENCES public.animales (id),
  lecheria_id uuid NOT NULL REFERENCES public.lecherias (id),
  tipo text NOT NULL CHECK (tipo IN (
    'sanidad', 'celo', 'monta', 'inseminacion', 'palpacion',
    'secado', 'parto', 'cambio_grupo', 'baja', 'concentrado'
  )),
  fecha timestamptz NOT NULL,
  detalle text,
  medicamento_id uuid,
  dosis text,
  dias_retiro integer,
  costo numeric CHECK (costo IS NULL OR costo >= 0),
  resultado text,
  toro_pajilla text,
  sexo_cria text,
  grupo_anterior text,
  grupo_nuevo text,
  motivo_baja text,
  precio_venta numeric,
  cria_animal_id uuid REFERENCES public.animales (id),
  registrado_por uuid REFERENCES auth.users (id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_eventos_animal_animal ON public.eventos_animal (animal_id)
  WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_eventos_animal_lecheria ON public.eventos_animal (lecheria_id)
  WHERE deleted_at IS NULL;

ALTER TABLE public.eventos_animal ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS eventos_animal_select ON public.eventos_animal;
CREATE POLICY eventos_animal_select ON public.eventos_animal
  FOR SELECT USING (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DROP POLICY IF EXISTS eventos_animal_insert ON public.eventos_animal;
CREATE POLICY eventos_animal_insert ON public.eventos_animal
  FOR INSERT WITH CHECK (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DROP POLICY IF EXISTS eventos_animal_update ON public.eventos_animal;
CREATE POLICY eventos_animal_update ON public.eventos_animal
  FOR UPDATE USING (private.es_miembro_lecheria(lecheria_id, auth.uid()))
  WITH CHECK (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_eventos_animal_updated_at'
  ) THEN
    CREATE TRIGGER trg_eventos_animal_updated_at
      BEFORE UPDATE ON public.eventos_animal
      FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

-- ============================================================================
-- 6. Pesa de leche (Módulo 3)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.pesas_sesiones (
  id uuid PRIMARY KEY,
  lecheria_id uuid NOT NULL REFERENCES public.lecherias (id),
  fecha timestamptz NOT NULL,
  cerrada boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_pesas_sesiones_lecheria ON public.pesas_sesiones (lecheria_id)
  WHERE deleted_at IS NULL;

ALTER TABLE public.pesas_sesiones ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS pesas_sesiones_select ON public.pesas_sesiones;
CREATE POLICY pesas_sesiones_select ON public.pesas_sesiones
  FOR SELECT USING (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DROP POLICY IF EXISTS pesas_sesiones_insert ON public.pesas_sesiones;
CREATE POLICY pesas_sesiones_insert ON public.pesas_sesiones
  FOR INSERT WITH CHECK (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DROP POLICY IF EXISTS pesas_sesiones_update ON public.pesas_sesiones;
CREATE POLICY pesas_sesiones_update ON public.pesas_sesiones
  FOR UPDATE USING (private.es_miembro_lecheria(lecheria_id, auth.uid()))
  WITH CHECK (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_pesas_sesiones_updated_at'
  ) THEN
    CREATE TRIGGER trg_pesas_sesiones_updated_at
      BEFORE UPDATE ON public.pesas_sesiones
      FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

-- pesas_leche no tiene lecheria_id propio (ver database.dart): la membresía
-- se valida por join con pesas_sesiones, igual que movimientos_lote en
-- HatoControl se valida por join con animales.
CREATE TABLE IF NOT EXISTS public.pesas_leche (
  id uuid PRIMARY KEY,
  sesion_id uuid NOT NULL REFERENCES public.pesas_sesiones (id),
  animal_id uuid NOT NULL REFERENCES public.animales (id),
  litros numeric NOT NULL CHECK (litros >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_pesas_leche_sesion ON public.pesas_leche (sesion_id)
  WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_pesas_leche_animal ON public.pesas_leche (animal_id)
  WHERE deleted_at IS NULL;

ALTER TABLE public.pesas_leche ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS pesas_leche_select ON public.pesas_leche;
CREATE POLICY pesas_leche_select ON public.pesas_leche
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.pesas_sesiones s
      WHERE s.id = pesas_leche.sesion_id
        AND private.es_miembro_lecheria(s.lecheria_id, auth.uid())
    )
  );

DROP POLICY IF EXISTS pesas_leche_insert ON public.pesas_leche;
CREATE POLICY pesas_leche_insert ON public.pesas_leche
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.pesas_sesiones s
      WHERE s.id = pesas_leche.sesion_id
        AND private.es_miembro_lecheria(s.lecheria_id, auth.uid())
    )
  );

DROP POLICY IF EXISTS pesas_leche_update ON public.pesas_leche;
CREATE POLICY pesas_leche_update ON public.pesas_leche
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.pesas_sesiones s
      WHERE s.id = pesas_leche.sesion_id
        AND private.es_miembro_lecheria(s.lecheria_id, auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.pesas_sesiones s
      WHERE s.id = pesas_leche.sesion_id
        AND private.es_miembro_lecheria(s.lecheria_id, auth.uid())
    )
  );

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_pesas_leche_updated_at'
  ) THEN
    CREATE TRIGGER trg_pesas_leche_updated_at
      BEFORE UPDATE ON public.pesas_leche
      FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

-- ============================================================================
-- 7. Gastos: parámetros de período y costos fijos (Módulo 4)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.parametros_periodo (
  id uuid PRIMARY KEY,
  lecheria_id uuid NOT NULL REFERENCES public.lecherias (id),
  anio integer NOT NULL,
  mes integer NOT NULL CHECK (mes BETWEEN 1 AND 12),
  precio_litro numeric NOT NULL CHECK (precio_litro >= 0),
  precio_concentrado_kg numeric NOT NULL CHECK (precio_concentrado_kg >= 0),
  umbral_secado_litros numeric NOT NULL DEFAULT 8 CHECK (umbral_secado_litros >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_parametros_periodo_lecheria_anio_mes
  ON public.parametros_periodo (lecheria_id, anio, mes)
  WHERE deleted_at IS NULL;

ALTER TABLE public.parametros_periodo ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS parametros_periodo_select ON public.parametros_periodo;
CREATE POLICY parametros_periodo_select ON public.parametros_periodo
  FOR SELECT USING (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DROP POLICY IF EXISTS parametros_periodo_insert ON public.parametros_periodo;
CREATE POLICY parametros_periodo_insert ON public.parametros_periodo
  FOR INSERT WITH CHECK (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DROP POLICY IF EXISTS parametros_periodo_update ON public.parametros_periodo;
CREATE POLICY parametros_periodo_update ON public.parametros_periodo
  FOR UPDATE USING (private.es_miembro_lecheria(lecheria_id, auth.uid()))
  WITH CHECK (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_parametros_periodo_updated_at'
  ) THEN
    CREATE TRIGGER trg_parametros_periodo_updated_at
      BEFORE UPDATE ON public.parametros_periodo
      FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.costos_fijos (
  id uuid PRIMARY KEY,
  lecheria_id uuid NOT NULL REFERENCES public.lecherias (id),
  periodo_id uuid NOT NULL REFERENCES public.parametros_periodo (id),
  categoria text NOT NULL,
  monto numeric NOT NULL CHECK (monto >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_costos_fijos_periodo ON public.costos_fijos (periodo_id)
  WHERE deleted_at IS NULL;

ALTER TABLE public.costos_fijos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS costos_fijos_select ON public.costos_fijos;
CREATE POLICY costos_fijos_select ON public.costos_fijos
  FOR SELECT USING (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DROP POLICY IF EXISTS costos_fijos_insert ON public.costos_fijos;
CREATE POLICY costos_fijos_insert ON public.costos_fijos
  FOR INSERT WITH CHECK (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DROP POLICY IF EXISTS costos_fijos_update ON public.costos_fijos;
CREATE POLICY costos_fijos_update ON public.costos_fijos
  FOR UPDATE USING (private.es_miembro_lecheria(lecheria_id, auth.uid()))
  WITH CHECK (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_costos_fijos_updated_at'
  ) THEN
    CREATE TRIGGER trg_costos_fijos_updated_at
      BEFORE UPDATE ON public.costos_fijos
      FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

-- ============================================================================
-- 8. Catálogo de medicamentos (Módulo 7)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.medicamentos (
  id uuid PRIMARY KEY,
  lecheria_id uuid NOT NULL REFERENCES public.lecherias (id),
  nombre text NOT NULL,
  costo_envase numeric NOT NULL CHECK (costo_envase >= 0),
  tipo_dosis text NOT NULL CHECK (tipo_dosis IN ('fija', 'por_aplicacion')),
  ml_envase numeric,
  aplicaciones_envase numeric,
  dosis_fija_ml numeric,
  dias_retiro_leche integer NOT NULL DEFAULT 0 CHECK (dias_retiro_leche >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_medicamentos_lecheria ON public.medicamentos (lecheria_id)
  WHERE deleted_at IS NULL;

ALTER TABLE public.medicamentos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS medicamentos_select ON public.medicamentos;
CREATE POLICY medicamentos_select ON public.medicamentos
  FOR SELECT USING (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DROP POLICY IF EXISTS medicamentos_insert ON public.medicamentos;
CREATE POLICY medicamentos_insert ON public.medicamentos
  FOR INSERT WITH CHECK (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DROP POLICY IF EXISTS medicamentos_update ON public.medicamentos;
CREATE POLICY medicamentos_update ON public.medicamentos
  FOR UPDATE USING (private.es_miembro_lecheria(lecheria_id, auth.uid()))
  WITH CHECK (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_medicamentos_updated_at'
  ) THEN
    CREATE TRIGGER trg_medicamentos_updated_at
      BEFORE UPDATE ON public.medicamentos
      FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

-- Ahora que medicamentos existe, agregamos la FK opcional desde eventos_animal.
ALTER TABLE public.eventos_animal
  ADD CONSTRAINT eventos_animal_medicamento_id_fkey
  FOREIGN KEY (medicamento_id) REFERENCES public.medicamentos (id);

-- ============================================================================
-- 9. Umbrales de alertas (Módulo 9)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.config_alertas (
  id uuid PRIMARY KEY,
  lecheria_id uuid NOT NULL REFERENCES public.lecherias (id),
  dias_celo_esperado integer NOT NULL DEFAULT 21,
  dias_confirmar_preniez integer NOT NULL DEFAULT 45,
  dias_vacios_altos integer NOT NULL DEFAULT 150,
  dias_antes_secar integer NOT NULL DEFAULT 60,
  dias_antes_parto integer NOT NULL DEFAULT 14,
  dias_aviso_fin_retiro integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_config_alertas_lecheria
  ON public.config_alertas (lecheria_id)
  WHERE deleted_at IS NULL;

ALTER TABLE public.config_alertas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS config_alertas_select ON public.config_alertas;
CREATE POLICY config_alertas_select ON public.config_alertas
  FOR SELECT USING (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DROP POLICY IF EXISTS config_alertas_insert ON public.config_alertas;
CREATE POLICY config_alertas_insert ON public.config_alertas
  FOR INSERT WITH CHECK (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DROP POLICY IF EXISTS config_alertas_update ON public.config_alertas;
CREATE POLICY config_alertas_update ON public.config_alertas
  FOR UPDATE USING (private.es_miembro_lecheria(lecheria_id, auth.uid()))
  WITH CHECK (private.es_miembro_lecheria(lecheria_id, auth.uid()));

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_config_alertas_updated_at'
  ) THEN
    CREATE TRIGGER trg_config_alertas_updated_at
      BEFORE UPDATE ON public.config_alertas
      FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
  END IF;
END $$;

-- ============================================================================
-- 10. Alta de cuenta nueva (uso manual del administrador, fuera de la app)
-- ============================================================================
-- Ejemplo para dar de alta un ganadero nuevo a mano desde el SQL Editor,
-- después de crear su usuario en Authentication → Users:
--
-- INSERT INTO public.cuentas (id, nombre, dueno_id, plan, estado)
-- VALUES (gen_random_uuid(), 'Finca Los Robles', '<uuid-del-usuario>', 'invitado', 'activa');
--
-- INSERT INTO public.usuarios (id, nombre, email, cuenta_id)
-- VALUES ('<uuid-del-usuario>', 'Don Carlos', 'carlos@correo.com',
--         (SELECT id FROM public.cuentas WHERE dueno_id = '<uuid-del-usuario>'));
