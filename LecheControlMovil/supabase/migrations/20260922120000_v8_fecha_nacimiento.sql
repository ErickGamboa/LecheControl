-- v8: la fecha de nacimiento del animal.
--
-- Es lo que hace que una novilla aparezca sola en Vacas por servir al cumplir
-- los 15 meses. Es opcional: de las vacas que ya estaban en la finca cuando se
-- empezó a usar la app casi nunca se sabe, y obligarla sería pedirle al
-- ganadero que invente una fecha.
--
-- Columna nula y nada más, así que la versión vieja de la app sigue
-- funcionando igual mientras la nueva se publica.

ALTER TABLE public.animales
  ADD COLUMN IF NOT EXISTS fecha_nacimiento timestamptz;

COMMENT ON COLUMN public.animales.fecha_nacimiento IS
  'Cuándo nació. Con ella, una novilla entra sola a Vacas por servir a los 15 meses.';
