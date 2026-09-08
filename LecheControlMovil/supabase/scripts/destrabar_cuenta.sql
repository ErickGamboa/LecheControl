-- ===========================================================================
-- Destrabar una cuenta que se queda en «Preparando tu cuenta…»
-- ===========================================================================
--
-- PARA QUÉ SIRVE
--
-- Es el arreglo **desde el servidor**, para no tener que compilar y publicar
-- una versión nueva de la app.
--
-- EL PROBLEMA QUE RESUELVE
--
-- Hasta la versión que trae el cursor por usuario, la app guardaba **un solo
-- cursor de bajada por tabla**, compartido entre las cuentas que se usaran en
-- ese teléfono. La bajada pide las filas con `(updated_at, id) >` el cursor.
--
-- Entonces: si en el teléfono se sincronizó la cuenta A, el cursor de
-- `usuarios` quedaba en la fecha de la fila de A. Al entrar con la cuenta B,
-- si la fila de B era **más vieja**, quedaba detrás del cursor y no bajaba
-- nunca. Sin la fila de `usuarios` no se resuelve el join con `cuentas` y la
-- app espera para siempre.
--
-- CÓMO LO ARREGLA
--
-- Le pone `updated_at = now()` a las filas de esa cuenta. Con eso quedan
-- adelante de cualquier cursor que el teléfono tenga guardado, y la app las
-- baja en la próxima sincronización —o al tocar «Reintentar»—.
--
-- No cambia ni un dato de la lechería: solo la marca de tiempo que el sync usa
-- para saber qué falta bajar. Es lo mismo que pasaría si alguien editara el
-- perfil desde el panel.
--
-- CÓMO SE USA
--
--   1. Cambiar el correo de abajo.
--   2. Correrlo en el SQL Editor de Supabase.
--   3. En el teléfono: abrir la app y tocar «Reintentar» (o cerrar sesión y
--      volver a entrar).
--
-- CUÁNDO DEJA DE HACER FALTA
--
-- Con la versión que guarda el cursor **por usuario**, esto ya no pasa: cada
-- cuenta lleva el suyo y no se estorban. Al actualizar, la migración v8 -> v9
-- borra los cursores viejos y destraba solo lo que estuviera trabado. Este
-- script queda por si aparece un teléfono con una versión anterior.
-- ===========================================================================

DO $$
DECLARE
  -- >>> CAMBIAR <<<
  v_correo text := 'appletest@gmail.com';

  v_uid uuid;
BEGIN
  SELECT id INTO v_uid FROM auth.users WHERE lower(email) = lower(v_correo);

  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'No hay ningún usuario con el correo %', v_correo;
  END IF;

  UPDATE public.usuarios SET updated_at = now() WHERE id = v_uid;
  UPDATE public.cuentas  SET updated_at = now() WHERE dueno_id = v_uid;

  -- La lechería y su membresía también, por si el teléfono las tiene detrás
  -- del cursor: sin ellas la app entra pero pide crear una lechería nueva.
  UPDATE public.lecherias le SET updated_at = now()
   WHERE EXISTS (
     SELECT 1 FROM public.lecheria_miembros m
      WHERE m.lecheria_id = le.id AND m.usuario_id = v_uid
        AND m.deleted_at IS NULL
   );
  UPDATE public.lecheria_miembros SET updated_at = now()
   WHERE usuario_id = v_uid AND deleted_at IS NULL;

  RAISE NOTICE 'Listo. En el teléfono: abrir la app y tocar «Reintentar».';
END $$;

-- Comprobación: las filas de esta cuenta tienen que ser las más recientes de
-- la tabla. Si alguna quedó más vieja que la de otra cuenta, sigue trabada.
SELECT
  u.email,
  u.updated_at AS usuario_updated,
  c.updated_at AS cuenta_updated,
  u.updated_at = (SELECT max(updated_at) FROM public.usuarios) AS es_la_mas_nueva
FROM public.usuarios u
LEFT JOIN public.cuentas c ON c.id = u.cuenta_id
ORDER BY u.updated_at DESC;
