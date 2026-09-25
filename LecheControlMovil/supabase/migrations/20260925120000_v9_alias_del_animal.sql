-- v9: el alias del animal.
--
-- El arete oficial es largo y nadie lo usa hablando: la vaca `1542` es «la 99»
-- o «la Pinta». El alias es ese nombre, y es por donde el ganadero la va a
-- buscar en la app.
--
-- **No es una segunda llave.** No lleva índice único a propósito: dos vacas
-- pueden llamarse «Pinta» y la finca sabe cuál es cuál. El que identifica al
-- animal sigue siendo el arete, que es el que tiene el índice único y el que
-- viaja en las referencias. El alias solo acompaña.
--
-- Columna nula y nada más, así que la versión de la app que está publicada hoy
-- sigue funcionando igual mientras la nueva se reparte.

ALTER TABLE public.animales
  ADD COLUMN IF NOT EXISTS alias text;

COMMENT ON COLUMN public.animales.alias IS
  'Nombre corto con el que se le dice al animal en la finca. Opcional, no '
  'único, y se muestra siempre junto al arete, nunca en su lugar.';
