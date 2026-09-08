-- ===========================================================================
-- Revisar en qué estado está cada usuario de LecheControl
-- ===========================================================================
--
-- Para cuando alguien inicia sesión bien pero la app se queda esperando, o
-- entra y no ve su lechería. Muestra de una las cuatro cosas que la app
-- necesita y dice cuál falta.
--
-- Se pega entero en el SQL Editor de Supabase. Solo lee: no cambia nada.
-- ===========================================================================

SELECT
  a.email,
  a.id AS auth_uid,

  -- 1. El perfil. Sin esta fila la app se queda en «Preparando tu cuenta…».
  CASE WHEN u.id IS NULL THEN '❌ FALTA' ELSE '✅' END AS perfil,

  -- 2. El perfil tiene que apuntar a una cuenta. Sin esto, igual: espera.
  CASE WHEN u.cuenta_id IS NULL THEN '❌ SIN CUENTA' ELSE '✅' END AS apunta_a_cuenta,

  -- 3. La cuenta tiene que existir de verdad (y no estar borrada).
  CASE
    WHEN u.cuenta_id IS NULL THEN '—'
    WHEN c.id IS NULL THEN '❌ LA CUENTA NO EXISTE'
    WHEN c.deleted_at IS NOT NULL THEN '❌ CUENTA BORRADA'
    ELSE '✅'
  END AS cuenta,

  -- 4. La lechería sale de la membresía, no de la cuenta. Si no hay ninguna,
  --    la app ofrece crearla (eso es normal en un usuario nuevo).
  COALESCE(l.cuantas, 0) AS lecherias,

  c.nombre AS cuenta_nombre,
  c.id     AS cuenta_id,
  c.dueno_id,
  CASE WHEN c.dueno_id = a.id THEN 'sí' ELSE 'no' END AS es_dueno,
  a.last_sign_in_at

FROM auth.users a
LEFT JOIN public.usuarios u ON u.id = a.id
LEFT JOIN public.cuentas  c ON c.id = u.cuenta_id
LEFT JOIN LATERAL (
  SELECT count(*) AS cuantas
  FROM public.lecheria_miembros m
  JOIN public.lecherias le ON le.id = m.lecheria_id AND le.deleted_at IS NULL
  WHERE m.usuario_id = a.id AND m.deleted_at IS NULL
) l ON true
ORDER BY a.created_at;

-- ---------------------------------------------------------------------------
-- Las lecherías, y de qué cuenta cuelga cada una. Sirve para ver si una quedó
-- huérfana: colgada de una cuenta que ya nadie tiene asignada.
-- ---------------------------------------------------------------------------
SELECT
  le.nombre        AS lecheria,
  le.id            AS lecheria_id,
  le.cuenta_id,
  c.nombre         AS cuenta_nombre,
  le.deleted_at,
  (SELECT count(*)
     FROM public.lecheria_miembros m
    WHERE m.lecheria_id = le.id AND m.deleted_at IS NULL) AS miembros,
  (SELECT string_agg(u2.email, ', ')
     FROM public.lecheria_miembros m
     JOIN public.usuarios u2 ON u2.id = m.usuario_id
    WHERE m.lecheria_id = le.id AND m.deleted_at IS NULL) AS quienes
FROM public.lecherias le
LEFT JOIN public.cuentas c ON c.id = le.cuenta_id
ORDER BY le.created_at;
