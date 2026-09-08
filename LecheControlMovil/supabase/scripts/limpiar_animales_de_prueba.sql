-- ===========================================================================
-- Borrar los animales que dejan las pruebas automáticas
-- ===========================================================================
--
-- El e2e (`integration_test/supabase_e2e_test.dart`) da de alta un animal de
-- verdad en la cuenta con la que corre, con un identificador que empieza con
-- `E2E-`. Eso es a propósito: es la única forma de probar que el alta sube al
-- servidor. Pero después quedan ahí, y en la cuenta de prueba de Apple no se
-- ven bien.
--
-- Este script los borra igual que los borraría la app: marcando `deleted_at`,
-- no con DELETE. Así la baja también le llega a los teléfonos que ya los
-- habían bajado. Un DELETE de verdad los dejaría en el teléfono para siempre.
--
-- CÓMO SE USA
--   1. SQL Editor del proyecto de LecheControl (yskvlaovqvjfodiroaqz).
--   2. Correr primero el SELECT del final para ver qué va a tocar.
--   3. Correr el bloque de arriba.
--
-- Solo toca lo que empieza con `E2E-`: ningún animal de un ganadero se llama
-- así.
-- ===========================================================================

-- Las pesas primero: cuelgan del animal y si no, quedan huérfanas en los
-- reportes de producción.
UPDATE public.pesas_leche p
   SET deleted_at = now(),
       updated_at = now()
 WHERE p.deleted_at IS NULL
   AND p.animal_id IN (
     SELECT a.id FROM public.animales a WHERE a.identificador LIKE 'E2E-%'
   );

UPDATE public.eventos_animal e
   SET deleted_at = now(),
       updated_at = now()
 WHERE e.deleted_at IS NULL
   AND e.animal_id IN (
     SELECT a.id FROM public.animales a WHERE a.identificador LIKE 'E2E-%'
   );

UPDATE public.animales
   SET deleted_at = now(),
       updated_at = now()
 WHERE identificador LIKE 'E2E-%'
   AND deleted_at IS NULL;

-- Comprobación: tiene que devolver cero filas.
SELECT identificador, lecheria_id
  FROM public.animales
 WHERE identificador LIKE 'E2E-%'
   AND deleted_at IS NULL;
