-- ===========================================================================
-- Dar de alta a un usuario de LecheControl
-- ===========================================================================
--
-- POR QUÉ HACE FALTA ESTO
--
-- Crear el usuario en Supabase Auth (Authentication > Add user) **no alcanza**.
-- No hay ningún trigger sobre `auth.users`: las filas de `public.cuentas` y
-- `public.usuarios` las crea el administrador a mano, y son las que la app
-- necesita para saber de qué cuenta cuelga la lechería.
--
-- Si falta cualquiera de las dos, el ganadero inicia sesión bien y después se
-- queda en «Preparando tu cuenta…», porque la app espera una fila que nunca
-- va a llegar. Es exactamente lo que pasó con la cuenta de prueba de Apple.
--
-- CÓMO SE USA
--
--   1. Crear primero el usuario en Supabase: Authentication > Users > Add user
--      (con su correo y contraseña).
--   2. Abrir el SQL Editor del proyecto y pegar este script.
--   3. Cambiar las tres variables de abajo.
--   4. Correrlo. Se puede correr las veces que haga falta: si la cuenta ya
--      existe, no la duplica.
--
-- ===========================================================================

DO $$
DECLARE
  -- >>> CAMBIAR ESTAS TRES <<<
  v_correo         text := 'appletest@ejemplo.com';
  v_nombre_cuenta  text := 'Cuenta de prueba';
  v_nombre_usuario text := 'Apple Test';

  v_uid    uuid;
  v_email  text;
  v_cuenta uuid;
BEGIN
  SELECT id, email INTO v_uid, v_email
  FROM auth.users
  WHERE lower(email) = lower(v_correo);

  IF v_uid IS NULL THEN
    RAISE EXCEPTION
      'No hay ningún usuario en Auth con el correo %. Crealo primero en '
      'Authentication > Users > Add user.', v_correo;
  END IF;

  -- La cuenta: si el usuario ya es dueño de una, se reutiliza.
  SELECT id INTO v_cuenta
  FROM public.cuentas
  WHERE dueno_id = v_uid AND deleted_at IS NULL
  LIMIT 1;

  IF v_cuenta IS NULL THEN
    v_cuenta := gen_random_uuid();
    -- `plan` y `estado` quedan en su valor por defecto ('invitado', 'activa').
    -- La app no mira ninguno de los dos: no cobra nada y no se vence. Del
    -- plan solo sale `limite_lecherias`, que es el tope estructural de una
    -- lechería por cuenta.
    INSERT INTO public.cuentas (id, nombre, dueno_id)
    VALUES (v_cuenta, v_nombre_cuenta, v_uid);
    RAISE NOTICE 'Cuenta creada: %', v_cuenta;
  ELSE
    RAISE NOTICE 'El usuario ya tenía cuenta: %', v_cuenta;
  END IF;

  -- El perfil. Es la fila que la app cruza con `cuentas` para saber de qué
  -- cuenta es el usuario; sin ella se queda esperando para siempre.
  INSERT INTO public.usuarios (id, nombre, email, cuenta_id)
  VALUES (v_uid, v_nombre_usuario, v_email, v_cuenta)
  ON CONFLICT (id) DO UPDATE
    SET cuenta_id  = EXCLUDED.cuenta_id,
        email      = COALESCE(EXCLUDED.email, public.usuarios.email),
        nombre     = COALESCE(public.usuarios.nombre, EXCLUDED.nombre),
        updated_at = now();

  RAISE NOTICE 'Listo: % ya puede entrar (cuenta %).', v_correo, v_cuenta;
END $$;

-- Comprobación. Tiene que devolver una fila con la cuenta llena; si
-- `cuenta_id` o `cuenta_nombre` salen vacíos, la app se va a quedar esperando.
SELECT
  u.email,
  u.id           AS usuario_id,
  u.cuenta_id,
  c.nombre       AS cuenta_nombre,
  c.estado,
  c.plan,
  p.limite_lecherias
FROM public.usuarios u
LEFT JOIN public.cuentas c ON c.id = u.cuenta_id
LEFT JOIN public.planes  p ON p.codigo = c.plan
WHERE lower(u.email) = lower('appletest@ejemplo.com');  -- <<< el mismo correo
