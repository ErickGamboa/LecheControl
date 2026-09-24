-- LecheControl — Sembrar LecheriaErick con datos de prueba
--
-- ⚠️  SOLO para LecheriaErick (la finca de pruebas de erick.yosue@gmail.com).
--     Trae un freno de mano: si el id no corresponde a esa lechería, el script
--     se cae antes de tocar una sola fila. La finca del cliente no se toca.
--
-- QUÉ HACE
--   1. Borra (borrado suave, `deleted_at`) todo lo que hay hoy en la lechería.
--      Suave y no `DELETE` a propósito: así el teléfono se entera del borrado
--      al sincronizar y limpia su copia solo. Con un `DELETE` duro el teléfono
--      se quedaría con los datos viejos para siempre.
--   2. Siembra un hato completo, con eventos, pesas, finanzas y calidad, hecho
--      para que **todas** las pantallas de la app tengan algo que mostrar.
--
-- Todo se cuelga de `current_date`: corralo cuando sea y las edades, los días
-- de lactancia y las semanas salen bien.
--
-- Las fechas se guardan como medianoche de Costa Rica (06:00 UTC), que es
-- exactamente lo que escribe la app desde que se arregló el `.toUtc()`.
--
-- DESPUÉS DE CORRERLO: abrí la app y tocá **Sincronizar ahora**. Si algo se
-- ve viejo, **Volver a bajar todo**.

BEGIN;

-- ---------------------------------------------------------------------------
-- Parámetros y freno de mano
-- ---------------------------------------------------------------------------

CREATE TEMP TABLE p ON COMMIT DROP AS
SELECT
  'd70a8c89-f2ba-47ea-9044-5e2378f90f89'::uuid AS lecheria,
  '1924c185-a5de-4e88-8530-47fcc0bbf562'::uuid AS usuario,
  current_date                                 AS hoy,
  -- Prefijo de las llaves que genera este script. Los `id` salen de un md5
  -- de este prefijo más el nombre de la fila, así que todo lo que se
  -- referencia entre tablas —la madre, la cría, el toro, la sesión de pesa—
  -- casa solo.
  --
  -- Lleva la hora de la corrida **a propósito**: cada vez que se corre, las
  -- filas nuevas estrenan `id`. Sin eso, correrlo dos veces reventaría con
  -- llave duplicada, porque las de la corrida anterior siguen ahí (enterradas,
  -- pero ahí).
  'lc:' || to_char(clock_timestamp(), 'YYYYMMDDHH24MISS') || ':' AS k;

DO $$
DECLARE nombre_actual text;
BEGIN
  SELECT nombre INTO nombre_actual
    FROM public.lecherias
   WHERE id = 'd70a8c89-f2ba-47ea-9044-5e2378f90f89';

  IF nombre_actual IS DISTINCT FROM 'LecheriaErick' THEN
    RAISE EXCEPTION
      'Freno: ese id no es LecheriaErick (es %). No se tocó nada.',
      coalesce(nombre_actual, '«no existe»');
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Borrar lo que hay, solo de esta lechería
-- ---------------------------------------------------------------------------
--
-- Las lápidas se marcan **cinco minutos antes** que las filas nuevas, y eso no
-- es un adorno.
--
-- El teléfono baja por `(updated_at, id)` y aplica en ese orden. Si la baja de
-- la fila vieja y la nueva que ocupa su lugar llevan la misma marca de tiempo
-- —lo que pasa si las dos se tocan en la misma transacción—, desempata el
-- `id`, que es azar: a veces la nueva llega primero e insertarla choca contra
-- el índice único del teléfono, porque la vieja todavía está viva ahí.
--
-- Pasó de verdad: un teléfono se quedó con «Hay 16 cambios que no logran
-- subir… UNIQUE constraint failed: curva_referencia.lecheria_id,
-- curva_referencia.dia_desde» y el otro, contra el mismo servidor, lo aplicó
-- sin chistar. Y no se cura solo: el cursor no avanza sobre una fila que
-- reventó, así que vuelve a chocar con la misma en cada sincronización.
--
-- La app **no** se defiende de esto, así que el orden lo tiene que poner el
-- servidor: primero la lápida, después lo que ocupa su lugar. Solo pasa
-- insertando a mano en una finca que ya tiene datos, que es justamente lo que
-- hace este script y lo que nunca se le hace a la finca de un cliente.

UPDATE public.pesas_leche SET deleted_at = now(), updated_at = now() - interval '5 minutes'
 WHERE deleted_at IS NULL
   AND sesion_id IN (SELECT id FROM public.pesas_sesiones
                      WHERE lecheria_id = (SELECT lecheria FROM p));

UPDATE public.pesas_sesiones  SET deleted_at = now(), updated_at = now() - interval '5 minutes'
 WHERE deleted_at IS NULL AND lecheria_id = (SELECT lecheria FROM p);
UPDATE public.calidad_leche   SET deleted_at = now(), updated_at = now() - interval '5 minutes'
 WHERE deleted_at IS NULL AND lecheria_id = (SELECT lecheria FROM p);
UPDATE public.ingresos_semana SET deleted_at = now(), updated_at = now() - interval '5 minutes'
 WHERE deleted_at IS NULL AND lecheria_id = (SELECT lecheria FROM p);
UPDATE public.gastos_semana   SET deleted_at = now(), updated_at = now() - interval '5 minutes'
 WHERE deleted_at IS NULL AND lecheria_id = (SELECT lecheria FROM p);
UPDATE public.semanas         SET deleted_at = now(), updated_at = now() - interval '5 minutes'
 WHERE deleted_at IS NULL AND lecheria_id = (SELECT lecheria FROM p);
UPDATE public.eventos_animal  SET deleted_at = now(), updated_at = now() - interval '5 minutes'
 WHERE deleted_at IS NULL AND lecheria_id = (SELECT lecheria FROM p);
UPDATE public.animales        SET deleted_at = now(), updated_at = now() - interval '5 minutes'
 WHERE deleted_at IS NULL AND lecheria_id = (SELECT lecheria FROM p);
UPDATE public.medicamentos    SET deleted_at = now(), updated_at = now() - interval '5 minutes'
 WHERE deleted_at IS NULL AND lecheria_id = (SELECT lecheria FROM p);
UPDATE public.categorias_gasto SET deleted_at = now(), updated_at = now() - interval '5 minutes'
 WHERE deleted_at IS NULL AND lecheria_id = (SELECT lecheria FROM p);
UPDATE public.curva_referencia SET deleted_at = now(), updated_at = now() - interval '5 minutes'
 WHERE deleted_at IS NULL AND lecheria_id = (SELECT lecheria FROM p);
UPDATE public.config_reporte  SET deleted_at = now(), updated_at = now() - interval '5 minutes'
 WHERE deleted_at IS NULL AND lecheria_id = (SELECT lecheria FROM p);

-- ---------------------------------------------------------------------------
-- 2. Lo que la finca tiene configurado
-- ---------------------------------------------------------------------------

INSERT INTO public.config_reporte
  (id, lecheria_id, pct_excelente, pct_bueno, pct_vigilar, pct_bajo,
   umbral_secado_litros, tope_kg_leche, kg_leche_por_kg_concentrado,
   created_at, updated_at)
SELECT md5(p.k || 'config')::uuid, lecheria, 100, 85, 70, 60, 8, 30, 3, now(), now()
  FROM p;

-- La curva de referencia: cuántos litros se esperan según los días que lleva
-- la vaca de parida. Es contra esto que el reporte semanal la califica.
INSERT INTO public.curva_referencia
  (id, lecheria_id, orden, dia_desde, dia_hasta, litros_esperados,
   created_at, updated_at)
SELECT md5(p.k || 'curva:' || t.orden)::uuid, p.lecheria,
       t.orden, t.desde, t.hasta, t.litros, now(), now()
  FROM p, (VALUES
    (1,   0,   30, 18.8),
    (2,  31,   70, 26.0),
    (3,  71,  120, 24.0),
    (4, 121,  180, 21.0),
    (5, 181,  240, 18.0),
    (6, 241,  305, 14.0),
    (7, 306, NULL, 10.0)
  ) AS t(orden, desde, hasta, litros);

INSERT INTO public.categorias_gasto
  (id, lecheria_id, nombre, orden, created_at, updated_at)
SELECT md5(p.k || 'cat:' || t.nombre)::uuid, p.lecheria, t.nombre, t.orden,
       now(), now()
  FROM p, (VALUES
    ('Salarios', 1),
    ('Luz', 2),
    ('Concentrado', 3),
    ('Medicamentos', 4),
    ('Combustible', 5),
    ('Compras Dos Pinos', 6),
    ('Compra de ganado', 7),
    ('Transporte de leche', 8),
    ('Otros', 9)
  ) AS t(nombre, orden);

INSERT INTO public.medicamentos
  (id, lecheria_id, nombre, costo_envase, tipo_dosis, ml_envase,
   aplicaciones_envase, dosis_fija_ml, dias_retiro_leche, created_at, updated_at)
SELECT md5(p.k || 'med:' || t.nombre)::uuid, p.lecheria, t.nombre, t.costo,
       t.tipo, t.ml, t.aplic, t.fija, t.retiro, now(), now()
  FROM p, (VALUES
    ('Oxitetraciclina LA',    18500, 'fija',           250::numeric, NULL::numeric, 20::numeric, 4),
    ('Penicilina + Estrept.', 12800, 'fija',           100,          NULL,          15,          3),
    ('Ivermectina 1%',         9500, 'fija',           500,          NULL,          10,          0),
    ('Vitaminas AD3E',         7200, 'fija',           250,          NULL,          10,          0),
    ('Sellador de pezones',   22000, 'por_aplicacion', NULL,         120,           NULL,        0)
  ) AS t(nombre, costo, tipo, ml, aplic, fija, retiro);

-- ---------------------------------------------------------------------------
-- 3. El hato
-- ---------------------------------------------------------------------------
-- Cada fila está puesta a mano para que caiga en una situación distinta: la
-- recién parida, la que hay que palpar, la que hay que servir, la pronta, la
-- que se pasó de fecha, la novilla que ya tiene edad y la que todavía no.
--
--   del      días desde el último parto (NULL: nunca ha parido)
--   prob     días de hoy a la fecha probable de parto (NULL: no está preñada)
--   nac_m    edad en meses     |  nac_d  edad en días (para las crías)
--   seca     hace cuántos días se secó
--   factor   qué tan buena lechera es, contra la curva. Reparte los grados
--            del reporte: arriba de 1 produce más de lo esperado.

CREATE TEMP TABLE hato ON COMMIT DROP AS
SELECT * FROM (VALUES
  -- ident, sexo, grupo, estado, repro, origen, del, prob, nac_m, nac_d,
  -- precio_compra, baja_dias, motivo_baja, precio_venta, retiro_dias, seca,
  -- madre, padre_toro, padre_pajilla, factor
  ('9001','macho','toros','activo','desconocido','nacido',
     NULL::int, NULL::int, 48::int, NULL::int, NULL::numeric, NULL::int,
     NULL::text, NULL::numeric, NULL::int, NULL::int,
     NULL::text, NULL::text, NULL::text, NULL::numeric),
  ('9002','macho','toros','activo','desconocido','comprado',
     NULL,NULL,36,NULL, 850000, NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL),

  -- En ordeño.
  --
  -- `del` y `prob` no son dos números sueltos: la vaca queda preñada entre 55
  -- y 120 días después de parir y la gestación son 283 días, así que
  -- `del = 283 + días_al_servicio - prob`. Si se inventan por separado sale
  -- una vaca servida dos días después del parto, que no existe. Por eso las
  -- vacías son las de lactancia temprana y las preñadas las de lactancia
  -- avanzada: así es una finca de verdad.
  ('4101','hembra','en_ordeno','activo','vacia','nacido',
      12,NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL, 1.12),
  ('4102','hembra','en_ordeno','activo','vacia','nacido',
      25,NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL, 0.95),
  ('4103','hembra','en_ordeno','activo','vacia','nacido',
      38,NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL, 1.05),
  ('4104','hembra','en_ordeno','activo','vacia','nacido',
      52,NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL, 0.88),
  ('4105','hembra','en_ordeno','activo','vacia','nacido',
      67,NULL,NULL,NULL, NULL,NULL,NULL,NULL,   2,NULL, NULL,NULL,NULL, 1.15),
  ('4106','hembra','en_ordeno','activo','vacia','comprado',
      80,NULL,NULL,NULL, 620000,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL, 0.78),
  ('4108','hembra','en_ordeno','activo','vacia','nacido',
     110,NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL, 0.92),
  ('4111','hembra','en_ordeno','activo','vacia','nacido',
     160,NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL, 0.68),
  ('4117','hembra','en_ordeno','activo','vacia','nacido',
     290,NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL, 0.64),
  ('4107','hembra','en_ordeno','activo','preñada','nacido',
     163, 190,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL, 1.02),
  ('4109','hembra','en_ordeno','activo','preñada','nacido',
     188, 160,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL, 1.08),
  ('4110','hembra','en_ordeno','activo','preñada','nacido',
     223, 140,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL, 0.97),
  ('4112','hembra','en_ordeno','activo','preñada','nacido',
     253, 105,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL, 1.03),
  ('4113','hembra','en_ordeno','activo','preñada','comprado',
     293,  80,NULL,NULL, 580000,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL, 0.86),
  ('4114','hembra','en_ordeno','activo','preñada','nacido',
     313,  55,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL, 1.00),
  ('4115','hembra','en_ordeno','activo','preñada','nacido',
     348,  30,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL, 0.93),
  -- Estas dos están prontas y todavía se están ordeñando: es la vaca a la que
  -- se le pasó el secado. La app la marca Pronta para que salte a la vista.
  ('4116','hembra','en_ordeno','activo','preñada','nacido',
     355,  18,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL, 0.81),
  ('4118','hembra','en_ordeno','activo','preñada','nacido',
     371,  12,NULL,NULL, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL, 0.90),

  -- Secas
  ('4201','hembra','secas','activo','preñada','nacido',
     318,  45,NULL,NULL, NULL,NULL,NULL,NULL,NULL, 15, NULL,NULL,NULL, 1.06),
  ('4202','hembra','secas','activo','preñada','nacido',
     328,  30,NULL,NULL, NULL,NULL,NULL,NULL,NULL, 30, NULL,NULL,NULL, 0.99),
  ('4203','hembra','secas','activo','preñada','nacido',
     353,  20,NULL,NULL, NULL,NULL,NULL,NULL,NULL, 40, NULL,NULL,NULL, 1.11),
  ('4204','hembra','secas','activo','preñada','nacido',
     360,   8,NULL,NULL, NULL,NULL,NULL,NULL,NULL, 52, NULL,NULL,NULL, 0.94),
  -- Se pasó de la fecha probable y todavía no pare.
  ('4205','hembra','secas','activo','preñada','nacido',
     356,  -3,NULL,NULL, NULL,NULL,NULL,NULL,NULL, 63, NULL,NULL,NULL, 0.87),
  -- Seca y vacía: se secó por baja producción, no por preñez. Sale en Vacas
  -- por servir, que es lo que hay que hacer con ella.
  ('4206','hembra','secas','activo','vacia','nacido',
      95,NULL,NULL,NULL, NULL,NULL,NULL,NULL,NULL, 20, NULL,NULL,NULL, 0.72),

  -- Novillas
  ('4301','hembra','novillas','activo','vacia','nacido',
     NULL,NULL, 20,NULL, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL),
  ('4302','hembra','novillas','activo','vacia','nacido',
     NULL,NULL, 17,NULL, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL),
  ('4303','hembra','novillas','activo','vacia','nacido',
     NULL,NULL, 15,NULL, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL),
  ('4304','hembra','novillas','activo','vacia','nacido',
     NULL,NULL, 14,NULL, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL),
  ('4305','hembra','novillas','activo','vacia','nacido',
     NULL,NULL, 12,NULL, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL),
  ('4306','hembra','novillas','activo','preñada','nacido',
     NULL, 120, 18,NULL, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL),
  ('4307','hembra','novillas','activo','vacia','nacido',
     NULL,NULL, 16,NULL, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL),
  -- Sin fecha de nacimiento: es la que NO aparece en Vacas por servir, y en su
  -- ficha sale el aviso naranja que dice por qué.
  ('4308','hembra','novillas','activo','vacia','comprado',
     NULL,NULL,NULL,NULL, 390000,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL),

  -- Terneros
  ('4401','hembra','terneros','activo','desconocido','nacido',
     NULL,NULL,NULL,  12, NULL,NULL,NULL,NULL,NULL,NULL, '4101','9001',NULL,NULL),
  ('4402','macho','terneros','activo','desconocido','nacido',
     NULL,NULL,NULL,  25, NULL,NULL,NULL,NULL,NULL,NULL, '4102','9001',NULL,NULL),
  ('4403','hembra','terneros','activo','desconocido','nacido',
     NULL,NULL,NULL,  38, NULL,NULL,NULL,NULL,NULL,NULL, '4103',NULL,'HOLSTEIN 7HO14567',NULL),
  ('4404','macho','terneros','activo','desconocido','nacido',
     NULL,NULL,NULL, 120, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL),
  ('4405','hembra','terneros','activo','desconocido','nacido',
     NULL,NULL,NULL, 150, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL),
  ('4406','hembra','terneros','activo','desconocido','nacido',
     NULL,NULL,NULL, 200, NULL,NULL,NULL,NULL,NULL,NULL, NULL,'9002',NULL,NULL),
  ('4407','macho','terneros','activo','desconocido','nacido',
     NULL,NULL,NULL, 260, NULL,NULL,NULL,NULL,NULL,NULL, NULL,NULL,NULL,NULL),

  -- Dadas de baja (siguen en la app, bajo el filtro Bajas)
  ('4501','hembra','en_ordeno','vendido','vacia','nacido',
     150,NULL,NULL,NULL, NULL, 25,'venta', 480000,NULL,NULL, NULL,NULL,NULL, 0.70),
  ('4502','hembra','en_ordeno','muerto','preñada','nacido',
     273,  90,NULL,NULL, NULL, 60,'muerte',NULL,NULL,NULL, NULL,NULL,NULL, 0.83),
  ('4503','hembra','novillas','descartado','vacia','nacido',
     NULL,NULL, 26,NULL, NULL, 90,'descarte',NULL,NULL,NULL, NULL,NULL,NULL,NULL),
  ('4504','macho','terneros','vendido','desconocido','nacido',
     NULL,NULL,NULL, 210, NULL, 40,'venta',  95000,NULL,NULL, NULL,NULL,NULL,NULL),
  ('4505','hembra','secas','vendido','vacia','nacido',
     280,NULL,NULL,NULL, NULL, 15,'venta', 510000,NULL, 40, NULL,NULL,NULL, 0.75)
) AS t(ident, sexo, grupo, estado, repro, origen, del, prob, nac_m, nac_d,
       precio_compra, baja_dias, motivo_baja, precio_venta, retiro_dias, seca,
       madre, padre_toro, padre_pajilla, factor);

-- Los animales. `id` sale de un md5 del identificador: es estable, así que
-- volver a correr el script no crea duplicados ni rompe las referencias.
INSERT INTO public.animales
  (id, lecheria_id, identificador, sexo, grupo, estado, estado_reproductivo,
   origen, precio_compra, fecha_compra, madre_id, padre_id, padre_pajilla,
   fecha_nacimiento, fecha_probable_parto, fecha_ultimo_parto,
   retiro_leche_hasta, created_at, updated_at)
SELECT
  md5(p.k || 'animal:' || h.ident)::uuid,
  p.lecheria,
  h.ident,
  h.sexo,
  h.grupo,
  h.estado,
  h.repro,
  h.origen,
  h.precio_compra,
  -- La fecha de compra cae en la misma semana en que se anotó el gasto de
  -- «Compra de ganado», más abajo: los dos salen de esta misma cuenta.
  CASE WHEN h.origen = 'comprado' THEN
    ((p.hoy - (((right(h.ident, 1)::int % 4) * 3 + 1) * 7))::timestamp
       AT TIME ZONE 'America/Costa_Rica') END,
  CASE WHEN h.madre IS NOT NULL
       THEN md5(p.k || 'animal:' || h.madre)::uuid END,
  CASE WHEN h.padre_toro IS NOT NULL
       THEN md5(p.k || 'animal:' || h.padre_toro)::uuid END,
  h.padre_pajilla,
  CASE
    WHEN h.nac_m IS NOT NULL THEN
      ((p.hoy - (h.nac_m || ' months')::interval)::date::timestamp
         AT TIME ZONE 'America/Costa_Rica')
    WHEN h.nac_d IS NOT NULL THEN
      ((p.hoy - h.nac_d)::timestamp AT TIME ZONE 'America/Costa_Rica')
  END,
  CASE WHEN h.prob IS NOT NULL
       THEN ((p.hoy + h.prob)::timestamp AT TIME ZONE 'America/Costa_Rica') END,
  CASE WHEN h.del IS NOT NULL
       THEN ((p.hoy - h.del)::timestamp AT TIME ZONE 'America/Costa_Rica') END,
  CASE WHEN h.retiro_dias IS NOT NULL
       THEN ((p.hoy + h.retiro_dias)::timestamp AT TIME ZONE 'America/Costa_Rica') END,
  now(), now()
FROM hato h, p;

-- ---------------------------------------------------------------------------
-- 4. La hoja de vida de cada animal
-- ---------------------------------------------------------------------------

-- Partos. El de la lactancia en curso, y para las que llevan rato en la finca
-- también el anterior: así la hoja de vida no arranca en blanco.
INSERT INTO public.eventos_animal
  (id, animal_id, lecheria_id, tipo, fecha, sexo_cria, cria_animal_id,
   detalle, registrado_por, created_at, updated_at)
SELECT
  md5(p.k || 'parto:' || h.ident || ':' || v.n)::uuid,
  md5(p.k || 'animal:' || h.ident)::uuid,
  p.lecheria,
  'parto',
  ((p.hoy - h.del - v.atras)::timestamp AT TIME ZONE 'America/Costa_Rica'),
  CASE WHEN h.ident IN ('4102','4104','4107') THEN 'macho' ELSE 'hembra' END,
  CASE WHEN v.n = 0 THEN c.id END,
  CASE WHEN v.n = 0 THEN 'Parto normal, sin ayuda.' ELSE 'Lactancia anterior.' END,
  p.usuario, now(), now()
FROM hato h
CROSS JOIN p
CROSS JOIN (VALUES (0, 0), (1, 395)) AS v(n, atras)
LEFT JOIN LATERAL (
  SELECT md5(p.k || 'animal:' || h2.ident)::uuid AS id
    FROM hato h2 WHERE h2.madre = h.ident LIMIT 1
) c ON true
WHERE h.del IS NOT NULL
  AND (v.n = 0 OR h.del >= 145);

-- Secado y el cambio de grupo que lo acompaña.
INSERT INTO public.eventos_animal
  (id, animal_id, lecheria_id, tipo, fecha, detalle, grupo_anterior, grupo_nuevo,
   registrado_por, created_at, updated_at)
SELECT
  md5(p.k || 'secado:' || h.ident)::uuid,
  md5(p.k || 'animal:' || h.ident)::uuid,
  p.lecheria, 'secado',
  ((p.hoy - h.seca)::timestamp AT TIME ZONE 'America/Costa_Rica'),
  'Se secó para descansar antes del parto.', NULL, NULL,
  p.usuario, now(), now()
FROM hato h, p WHERE h.seca IS NOT NULL
UNION ALL
SELECT
  md5(p.k || 'cambio:' || h.ident)::uuid,
  md5(p.k || 'animal:' || h.ident)::uuid,
  p.lecheria, 'cambio_grupo',
  ((p.hoy - h.seca)::timestamp AT TIME ZONE 'America/Costa_Rica'),
  NULL, 'en_ordeno', 'secas',
  p.usuario, now(), now()
FROM hato h, p WHERE h.seca IS NOT NULL;

-- Servicios de las preñadas: se las sirvió unos 283 días antes del parto
-- probable. Van alternando monta (con toro de la finca) e inseminación (con
-- pajilla), para que se vean los dos caminos.
INSERT INTO public.eventos_animal
  (id, animal_id, lecheria_id, tipo, fecha, toro_id, toro_pajilla, detalle,
   registrado_por, created_at, updated_at)
SELECT
  md5(p.k || 'servicio:' || h.ident)::uuid,
  md5(p.k || 'animal:' || h.ident)::uuid,
  p.lecheria,
  CASE WHEN right(h.ident, 1)::int % 2 = 0 THEN 'monta' ELSE 'inseminacion' END,
  ((p.hoy + h.prob - 283)::timestamp AT TIME ZONE 'America/Costa_Rica'),
  CASE WHEN right(h.ident, 1)::int % 2 = 0
       THEN md5(p.k || 'animal:9001')::uuid END,
  CASE WHEN right(h.ident, 1)::int % 2 = 1
       THEN 'HOLSTEIN 7HO14567' END,
  NULL, p.usuario, now(), now()
FROM hato h, p
WHERE h.prob IS NOT NULL AND h.estado = 'activo';

-- La palpación que confirmó esa preñez, unos 45 días después del servicio.
INSERT INTO public.eventos_animal
  (id, animal_id, lecheria_id, tipo, fecha, resultado, detalle,
   registrado_por, created_at, updated_at)
SELECT
  md5(p.k || 'palpa:ok:' || h.ident)::uuid,
  md5(p.k || 'animal:' || h.ident)::uuid,
  p.lecheria, 'palpacion',
  ((p.hoy + h.prob - 238)::timestamp AT TIME ZONE 'America/Costa_Rica'),
  'preñada', 'Preñez confirmada.',
  p.usuario, now(), now()
FROM hato h, p
WHERE h.prob IS NOT NULL AND h.estado = 'activo' AND h.prob <= 240;

-- Servicios sin confirmar todavía: son las que la app manda a palpar.
INSERT INTO public.eventos_animal
  (id, animal_id, lecheria_id, tipo, fecha, toro_id, toro_pajilla,
   registrado_por, created_at, updated_at)
SELECT
  md5(p.k || 'serv2:' || t.ident)::uuid,
  md5(p.k || 'animal:' || t.ident)::uuid,
  p.lecheria, t.tipo,
  ((p.hoy - t.dias)::timestamp AT TIME ZONE 'America/Costa_Rica'),
  CASE WHEN t.toro IS NOT NULL THEN md5(p.k || 'animal:' || t.toro)::uuid END,
  t.pajilla, p.usuario, now(), now()
FROM p, (VALUES
  ('4105','monta',        40, '9001', NULL),
  ('4307','monta',        35, '9002', NULL),
  ('4108','inseminacion', 70, NULL,   'JERSEY 29JE4102'),
  ('4117','inseminacion', 50, NULL,   'HOLSTEIN 7HO14567')
) AS t(ident, tipo, dias, toro, pajilla);

-- Palpaciones que salieron vacías. Llevan observaciones y tratamiento: es el
-- caso que estrenó esos dos campos.
INSERT INTO public.eventos_animal
  (id, animal_id, lecheria_id, tipo, fecha, resultado, detalle, tratamiento,
   registrado_por, created_at, updated_at)
SELECT
  md5(p.k || 'palpa:vacia:' || t.ident)::uuid,
  md5(p.k || 'animal:' || t.ident)::uuid,
  p.lecheria, 'palpacion',
  ((p.hoy - t.dias)::timestamp AT TIME ZONE 'America/Costa_Rica'),
  'vacia', t.nota, t.trat, p.usuario, now(), now()
FROM p, (VALUES
  ('4111', 30, 'Ovario derecho pequeño, sin cuerpo lúteo.',
           'Lutalyse 5 ml intramuscular, repetir a los 11 días.'),
  ('4117', 20, 'Útero con líquido, huele mal. Viene de un parto complicado.',
           'Lavado uterino y oxitetraciclina por 3 días.'),
  ('4206', 25, 'Vacía. Está muy flaca para volver a servirla ya.',
           'Subirle el concentrado y revisar en un mes.')
) AS t(ident, dias, nota, trat);

-- Celos. No cuentan como servicio: estas vacas siguen saliendo «sin servicios»
-- en Vacas por servir, que es justamente lo que había que arreglar.
INSERT INTO public.eventos_animal
  (id, animal_id, lecheria_id, tipo, fecha, detalle,
   registrado_por, created_at, updated_at)
SELECT
  md5(p.k || 'celo:' || t.ident)::uuid,
  md5(p.k || 'animal:' || t.ident)::uuid,
  p.lecheria, 'celo',
  ((p.hoy - t.dias)::timestamp AT TIME ZONE 'America/Costa_Rica'),
  'Se dejó montar de las otras. No se sirvió.',
  p.usuario, now(), now()
FROM p, (VALUES
  ('4104', 5), ('4106', 12), ('4206', 8), ('4301', 3), ('4302', 16)
) AS t(ident, dias);

-- Sanidad. La de 4105 deja leche en retiro hasta pasado mañana.
INSERT INTO public.eventos_animal
  (id, animal_id, lecheria_id, tipo, fecha, medicamento_id, dosis, dias_retiro,
   costo, detalle, registrado_por, created_at, updated_at)
SELECT
  md5(p.k || 'san:' || t.ident || ':' || t.dias)::uuid,
  md5(p.k || 'animal:' || t.ident)::uuid,
  p.lecheria, 'sanidad',
  ((p.hoy - t.dias)::timestamp AT TIME ZONE 'America/Costa_Rica'),
  md5(p.k || 'med:' || t.med)::uuid, t.dosis, t.retiro, t.costo, t.nota,
  p.usuario, now(), now()
FROM p, (VALUES
  ('4105',  2, 'Oxitetraciclina LA',    '20 ml', 4, 1480::numeric,
   'Mastitis en el cuarto trasero izquierdo.'),
  ('4111', 18, 'Vitaminas AD3E',        '10 ml', 0,  288,
   'Viene decaída, se le puso vitamina.'),
  ('4117', 20, 'Penicilina + Estrept.', '15 ml', 3, 1920,
   'Tratamiento del útero después de la palpación.'),
  ('4404', 60, 'Ivermectina 1%',        '10 ml', 0,  190,
   'Desparasitada de rutina.'),
  ('4405', 60, 'Ivermectina 1%',        '10 ml', 0,  190,
   'Desparasitada de rutina.'),
  ('4406', 60, 'Ivermectina 1%',        '10 ml', 0,  190,
   'Desparasitada de rutina.'),
  ('4201', 15, 'Sellador de pezones',   '1 aplicación', 0, 183,
   'Sellada al secarla.'),
  ('4202', 30, 'Sellador de pezones',   '1 aplicación', 0, 183,
   'Sellada al secarla.')
) AS t(ident, dias, med, dosis, retiro, costo, nota);

-- Observaciones: notas sueltas que el ganadero escribe y quedan en la hoja.
INSERT INTO public.eventos_animal
  (id, animal_id, lecheria_id, tipo, fecha, detalle,
   registrado_por, created_at, updated_at)
SELECT
  md5(p.k || 'obs:' || t.ident)::uuid,
  md5(p.k || 'animal:' || t.ident)::uuid,
  p.lecheria, 'observacion',
  ((p.hoy - t.dias)::timestamp AT TIME ZONE 'America/Costa_Rica'),
  t.nota, p.usuario, now(), now()
FROM p, (VALUES
  ('4101',  6, 'Parió sola en el potrero de arriba. La ternera mamó bien.'),
  ('4117', 10, 'Lleva tres servicios y no agarra. Si no queda esta vez, se vende.'),
  ('4111',  4, 'Baja mucho la producción cuando llueve fuerte.'),
  ('4301',  9, 'Ya tiene tamaño de sobra para servirla.'),
  ('9001', 22, 'Toro tranquilo, sirve bien. Cuidarlo con las novillas chicas.')
) AS t(ident, dias, nota);

-- Bajas.
INSERT INTO public.eventos_animal
  (id, animal_id, lecheria_id, tipo, fecha, motivo_baja, precio_venta, detalle,
   registrado_por, created_at, updated_at)
SELECT
  md5(p.k || 'baja:' || h.ident)::uuid,
  md5(p.k || 'animal:' || h.ident)::uuid,
  p.lecheria, 'baja',
  ((p.hoy - h.baja_dias)::timestamp AT TIME ZONE 'America/Costa_Rica'),
  h.motivo_baja, h.precio_venta,
  CASE h.motivo_baja
    WHEN 'venta'    THEN 'Se vendió en la subasta.'
    WHEN 'muerte'   THEN 'Se enredó en el alambre y no se recuperó.'
    ELSE 'Se descartó: no volvió a preñarse en un año.'
  END,
  p.usuario, now(), now()
FROM hato h, p WHERE h.baja_dias IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 5. Semanas, pesas de leche y reporte
-- ---------------------------------------------------------------------------

-- Catorce semanas de lunes a domingo. `n` es cuántas semanas atrás: n = 0 es
-- la de hoy, que va abierta, y n = 13 la más vieja. Todo lo que sigue —los
-- litros de cada pesada, los gastos que no son de todas las semanas— cuenta
-- hacia atrás con ese número, así que el orden importa.
CREATE TEMP TABLE sem ON COMMIT DROP AS
SELECT
  g.i                                AS n,
  md5(p.k || 'semana:' || d.lunes)::uuid AS id,
  d.lunes                            AS inicio,
  (d.lunes + 6)                      AS fin
FROM p
CROSS JOIN generate_series(0, 13) AS g(i)
CROSS JOIN LATERAL (
  SELECT (date_trunc('week', p.hoy::timestamp)::date - g.i * 7) AS lunes
) d;

INSERT INTO public.semanas
  (id, lecheria_id, fecha_inicio, fecha_fin, cerrada, created_at, updated_at)
SELECT s.id, p.lecheria, s.inicio, s.fin,
       s.fin < p.hoy, now(), now()
FROM sem s, p;

-- Una pesada por semana, los miércoles.
INSERT INTO public.pesas_sesiones
  (id, lecheria_id, fecha, cerrada, created_at, updated_at)
SELECT md5(p.k || 'sesion:' || s.inicio)::uuid, p.lecheria,
       ((s.inicio + 2)::timestamp AT TIME ZONE 'America/Costa_Rica'),
       s.fin < p.hoy, now(), now()
FROM sem s, p;

-- Los litros de cada vaca en cada pesada.
--
-- Entra la vaca que ya había parido ese día, que todavía no se había secado y
-- que todavía no se había dado de baja. Los litros salen de la curva según los
-- días de lactancia que llevaba ESE día, por lo buena lechera que es cada una
-- y con un vaivén semanal, para que el gráfico no salga plano.
INSERT INTO public.pesas_leche
  (id, sesion_id, animal_id, litros, litros_manana, litros_tarde,
   concentrado_kg, created_at, updated_at)
SELECT
  md5(p.k || 'pesa:' || s.inicio || ':' || h.ident)::uuid,
  md5(p.k || 'sesion:' || s.inicio)::uuid,
  md5(p.k || 'animal:' || h.ident)::uuid,
  x.manana + x.tarde,
  x.manana,
  x.tarde,
  round(((x.manana + x.tarde) / 3.0)::numeric, 1),
  now(), now()
FROM sem s
CROSS JOIN p
JOIN hato h ON h.del IS NOT NULL
CROSS JOIN LATERAL (SELECT h.del - s.n * 7 AS del_ese_dia) d
CROSS JOIN LATERAL (
  SELECT round((
    CASE
      WHEN d.del_ese_dia <=  30 THEN 18.8
      WHEN d.del_ese_dia <=  70 THEN 26.0
      WHEN d.del_ese_dia <= 120 THEN 24.0
      WHEN d.del_ese_dia <= 180 THEN 21.0
      WHEN d.del_ese_dia <= 240 THEN 18.0
      WHEN d.del_ese_dia <= 305 THEN 14.0
      ELSE 10.0
    END
    * h.factor
    * (1 + (((s.n * 13 + right(h.ident,2)::int * 7) % 7) - 3) * 0.02)
  )::numeric, 1) AS total
) e
CROSS JOIN LATERAL (
  SELECT round((e.total * 0.55)::numeric, 1) AS manana,
         round((e.total * 0.45)::numeric, 1) AS tarde
) x
WHERE d.del_ese_dia >= 0
  AND (h.seca IS NULL OR s.n * 7 > h.seca)
  AND (h.baja_dias IS NULL OR s.n * 7 > h.baja_dias)
  AND e.total > 0;

-- Calidad de la leche que reportó la planta, semana a semana. Los valores van
-- subiendo y bajando a propósito, para que se vean los distintos grados.
INSERT INTO public.calidad_leche
  (id, lecheria_id, semana_id, solidos_totales_pct, celulas_somaticas,
   conteo_bacterial, created_at, updated_at)
SELECT
  md5(p.k || 'calidad:' || s.inicio)::uuid, p.lecheria, s.id,
  round((12.35 + ((s.n * 5) % 9) * 0.11)::numeric, 2),
  (155000 + ((s.n * 37) % 11) * 31000)::numeric,
  ( 18000 + ((s.n * 53) % 13) * 29000)::numeric,
  now(), now()
FROM sem s, p
WHERE s.n <= 11;

-- ---------------------------------------------------------------------------
-- 6. Finanzas de la semana
-- ---------------------------------------------------------------------------

-- La leche entregada: los litros de la pesada por siete días.
INSERT INTO public.ingresos_semana
  (id, lecheria_id, semana_id, tipo, monto, litros, detalle,
   created_at, updated_at)
SELECT
  md5(p.k || 'ing:leche:' || s.inicio)::uuid, p.lecheria, s.id, 'leche',
  round((t.litros * 7 * 480)::numeric, 0),
  round((t.litros * 7)::numeric, 1),
  'Entrega a la cooperativa.',
  now(), now()
FROM sem s
CROSS JOIN p
CROSS JOIN LATERAL (
  SELECT coalesce(sum(pl.litros), 0) AS litros
    FROM public.pesas_leche pl
   WHERE pl.sesion_id = md5(p.k || 'sesion:' || s.inicio)::uuid
     AND pl.deleted_at IS NULL
) t
WHERE t.litros > 0;

-- Las ventas de ganado caen en la semana en que se dieron de baja.
INSERT INTO public.ingresos_semana
  (id, lecheria_id, semana_id, tipo, monto, animal_id, detalle,
   created_at, updated_at)
SELECT
  md5(p.k || 'ing:venta:' || h.ident)::uuid, p.lecheria, s.id, 'venta_ganado',
  h.precio_venta, md5(p.k || 'animal:' || h.ident)::uuid,
  'Venta de ' || h.ident || '.', now(), now()
FROM hato h
CROSS JOIN p
JOIN sem s ON (p.hoy - h.baja_dias) BETWEEN s.inicio AND s.fin
WHERE h.precio_venta IS NOT NULL;

INSERT INTO public.ingresos_semana
  (id, lecheria_id, semana_id, tipo, monto, detalle, created_at, updated_at)
SELECT md5(p.k || 'ing:otro')::uuid, p.lecheria, s.id, 'otro',
       85000, 'Venta de abono del corral.', now(), now()
FROM sem s, p WHERE s.n = 3;

-- Los gastos de cada semana.
INSERT INTO public.gastos_semana
  (id, lecheria_id, semana_id, categoria, monto, detalle, created_at, updated_at)
SELECT
  md5(p.k || 'gasto:' || s.inicio || ':' || g.categoria)::uuid,
  p.lecheria, s.id, g.categoria,
  round((g.base * (1 + (((s.n * 11) % 5) - 2) * 0.06))::numeric, 0),
  g.nota, now(), now()
FROM sem s
CROSS JOIN p
CROSS JOIN (VALUES
  ('Salarios',            160000::numeric, 'Peón, semana completa.'),
  ('Concentrado',         185000, 'Concentrado de ordeño.'),
  ('Luz',                  24000, 'Bomba y sala de ordeño.'),
  ('Combustible',          28000, 'Diésel del tractor.'),
  ('Transporte de leche',  35000, 'Flete a la planta.')
) AS g(categoria, base, nota);

-- Gastos que no son de todas las semanas.
INSERT INTO public.gastos_semana
  (id, lecheria_id, semana_id, categoria, monto, detalle, created_at, updated_at)
SELECT
  md5(p.k || 'gasto:x:' || s.inicio || ':' || g.categoria)::uuid,
  p.lecheria, s.id, g.categoria, g.monto, g.nota, now(), now()
FROM sem s
CROSS JOIN p
CROSS JOIN (VALUES
  ('Medicamentos',      1, 42800::numeric, 'Antibióticos y vitaminas.'),
  ('Medicamentos',      5, 31500, 'Sellador de pezones.'),
  ('Medicamentos',      9, 19000, 'Desparasitante para los terneros.'),
  ('Compras Dos Pinos', 2, 96000, 'Sal mineral y detergente de ordeño.'),
  ('Compras Dos Pinos', 7, 78000, 'Insumos de la sala.'),
  ('Otros',             4, 55000, 'Reparación de la cerca eléctrica.'),
  ('Otros',            10, 120000, 'Mantenimiento de la ordeñadora.')
) AS g(categoria, semana, monto, nota)
WHERE s.n = g.semana;

-- El toro y las vacas que se compraron entran como gasto, igual que lo hace la
-- app cuando se registra un animal comprado con su precio.
INSERT INTO public.gastos_semana
  (id, lecheria_id, semana_id, categoria, monto, detalle, created_at, updated_at)
SELECT
  md5(p.k || 'gasto:compra:' || h.ident)::uuid,
  p.lecheria, s.id, 'Compra de ganado', h.precio_compra,
  'Compra de ' || h.ident || '.', now(), now()
FROM hato h
CROSS JOIN p
JOIN sem s ON s.n = (right(h.ident, 1)::int % 4) * 3 + 1
WHERE h.precio_compra IS NOT NULL;

COMMIT;

-- ---------------------------------------------------------------------------
-- Comprobación
-- ---------------------------------------------------------------------------

SELECT grupo, count(*) AS cabezas
  FROM public.animales
 WHERE lecheria_id = 'd70a8c89-f2ba-47ea-9044-5e2378f90f89'
   AND deleted_at IS NULL AND estado = 'activo'
 GROUP BY grupo ORDER BY grupo;

SELECT 'animales activos' AS que, count(*) FROM public.animales
 WHERE lecheria_id='d70a8c89-f2ba-47ea-9044-5e2378f90f89'
   AND deleted_at IS NULL AND estado='activo'
UNION ALL SELECT 'animales dados de baja', count(*) FROM public.animales
 WHERE lecheria_id='d70a8c89-f2ba-47ea-9044-5e2378f90f89'
   AND deleted_at IS NULL AND estado<>'activo'
UNION ALL SELECT 'eventos', count(*) FROM public.eventos_animal
 WHERE lecheria_id='d70a8c89-f2ba-47ea-9044-5e2378f90f89' AND deleted_at IS NULL
UNION ALL SELECT 'semanas', count(*) FROM public.semanas
 WHERE lecheria_id='d70a8c89-f2ba-47ea-9044-5e2378f90f89' AND deleted_at IS NULL
UNION ALL SELECT 'pesadas', count(*) FROM public.pesas_sesiones
 WHERE lecheria_id='d70a8c89-f2ba-47ea-9044-5e2378f90f89' AND deleted_at IS NULL
UNION ALL SELECT 'litros anotados', count(*) FROM public.pesas_leche pl
  JOIN public.pesas_sesiones ps ON ps.id=pl.sesion_id
 WHERE ps.lecheria_id='d70a8c89-f2ba-47ea-9044-5e2378f90f89' AND pl.deleted_at IS NULL
UNION ALL SELECT 'ingresos', count(*) FROM public.ingresos_semana
 WHERE lecheria_id='d70a8c89-f2ba-47ea-9044-5e2378f90f89' AND deleted_at IS NULL
UNION ALL SELECT 'gastos', count(*) FROM public.gastos_semana
 WHERE lecheria_id='d70a8c89-f2ba-47ea-9044-5e2378f90f89' AND deleted_at IS NULL
UNION ALL SELECT 'calidad de leche', count(*) FROM public.calidad_leche
 WHERE lecheria_id='d70a8c89-f2ba-47ea-9044-5e2378f90f89' AND deleted_at IS NULL;
