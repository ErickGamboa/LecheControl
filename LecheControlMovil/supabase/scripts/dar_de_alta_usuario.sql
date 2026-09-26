-- ===========================================================================
-- Dar de alta a un usuario de LecheControl (y decidir cuántas fincas tiene)
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
-- CUÁNTAS FINCAS
--
--   light   1 finca     (lo normal)
--   medium  hasta 3
--   pro     sin tope en la práctica
--
-- Esto **vive acá adentro y en ningún otro lado**. La app no dice ni una
-- palabra del tema: no hay pantalla de planes, no dice cuántas fincas tiene
-- ni cuántas podría tener. Lo único que ve el ganadero es que el botón de
-- agregar finca le aparece o no le aparece.
--
-- Este mismo script sirve para las dos cosas: dar de alta a alguien nuevo, y
-- cambiarle después la cantidad de fincas a alguien que ya existe. Poner otro
-- valor en `v_plan` y volverlo a correr es todo.
--
-- CÓMO SE USA
--
--   1. Crear primero el usuario en Supabase: Authentication > Users > Add user
--      (con su correo y contraseña).
--   2. Abrir el SQL Editor del proyecto y pegar este script.
--   3. Cambiar las cuatro variables de abajo.
--   4. Correrlo. Se puede correr las veces que haga falta: si la cuenta ya
--      existe, no la duplica.
--
-- ===========================================================================

DO $$
DECLARE
  -- >>> CAMBIAR ESTAS CUATRO <<<
  v_correo         text := 'ganaderapuerto@gmail.com';
  v_nombre_cuenta  text := 'ganaderapuerto';
  v_nombre_usuario text := 'ganaderapuerto';
  v_plan           text := 'light';   -- 'light' | 'medium' | 'pro'

  v_uid    uuid;
  v_email  text;
  v_cuenta uuid;
  v_plan_antes text;
  v_tope   int;
  v_fincas int;
BEGIN
  -- El plan se revisa acá y no se deja en manos de la llave foránea: un
  -- 'ligth' mal escrito daría un error de constraint que no se entiende.
  SELECT limite_lecherias INTO v_tope FROM public.planes WHERE codigo = v_plan;
  IF v_tope IS NULL THEN
    RAISE EXCEPTION
      'El plan "%" no existe. Los que hay son: light (1 finca), '
      'medium (3) y pro (sin tope).', v_plan;
  END IF;

  SELECT id, email INTO v_uid, v_email
  FROM auth.users
  WHERE lower(email) = lower(v_correo);

  IF v_uid IS NULL THEN
    RAISE EXCEPTION
      'No hay ningún usuario en Auth con el correo %. Crealo primero en '
      'Authentication > Users > Add user.', v_correo;
  END IF;

  -- La cuenta: si el usuario ya es dueño de una, se reutiliza.
  SELECT id, plan INTO v_cuenta, v_plan_antes
  FROM public.cuentas
  WHERE dueno_id = v_uid AND deleted_at IS NULL
  LIMIT 1;

  IF v_cuenta IS NULL THEN
    v_cuenta := gen_random_uuid();
    -- `estado` queda en su valor por defecto ('activa'). La app no lo mira:
    -- no cobra nada y no se vence. Del plan solo sale `limite_lecherias`.
    INSERT INTO public.cuentas (id, nombre, dueno_id, plan)
    VALUES (v_cuenta, v_nombre_cuenta, v_uid, v_plan);
    RAISE NOTICE 'Cuenta creada: % (hasta % finca(s))', v_cuenta, v_tope;
  ELSE
    RAISE NOTICE 'El usuario ya tenía cuenta: %', v_cuenta;

    IF v_plan_antes IS DISTINCT FROM v_plan THEN
      -- Bajarle el tope a una cuenta **no le borra ninguna finca**: las que
      -- tiene se quedan y se siguen viendo. Lo único que pasa es que no le
      -- va a aparecer el botón de agregar hasta que vuelva a caber.
      SELECT count(*) INTO v_fincas
      FROM public.lecherias
      WHERE cuenta_id = v_cuenta AND deleted_at IS NULL;

      IF v_fincas > v_tope THEN
        RAISE WARNING
          'Ojo: la cuenta tiene % finca(s) y el nuevo tope es %. No se borra '
          'ninguna, pero no va a poder agregar más.', v_fincas, v_tope;
      END IF;

      UPDATE public.cuentas
         SET plan = v_plan, updated_at = now()
       WHERE id = v_cuenta;
      RAISE NOTICE 'Fincas: de % a % (hasta % finca(s))',
                   v_plan_antes, v_plan, v_tope;
    END IF;
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
--
-- `fincas` y `tope` son para el administrador. Si `fincas` < `tope`, al
-- ganadero le va a aparecer el botón de agregar finca; si no, no le aparece y
-- no se le dice por qué.
SELECT
  u.email,
  u.id            AS usuario_id,
  u.cuenta_id,
  c.nombre        AS cuenta_nombre,
  c.estado,
  c.plan,
  p.limite_lecherias AS tope,
  (SELECT count(*) FROM public.lecherias l
    WHERE l.cuenta_id = c.id AND l.deleted_at IS NULL) AS fincas
FROM public.usuarios u
LEFT JOIN public.cuentas c ON c.id = u.cuenta_id
LEFT JOIN public.planes  p ON p.codigo = c.plan
WHERE lower(u.email) = lower('ganaderapuerto@gmail.com');  -- <<< el mismo correo
