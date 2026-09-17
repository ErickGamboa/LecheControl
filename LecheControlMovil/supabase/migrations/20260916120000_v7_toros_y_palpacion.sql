-- v7: los toros del hato, el padre de cada cría y el tratamiento de la
-- palpación.
--
-- Esta migración va **antes** de publicar la app nueva. Las columnas son todas
-- nulas y el grupo nuevo se agrega al CHECK sin quitar ninguno, así que la
-- versión vieja de la app sigue funcionando igual mientras tanto: manda las
-- mismas columnas de siempre y el servidor las acepta.

-- ---------------------------------------------------------------- animales

-- El grupo 'toros'. Se recrea el CHECK porque Postgres no sabe ampliarlo.
ALTER TABLE public.animales DROP CONSTRAINT IF EXISTS animales_grupo_check;
ALTER TABLE public.animales
  ADD CONSTRAINT animales_grupo_check
  CHECK (grupo IN ('en_ordeno','secas','novillas','terneros','toros'));

-- De quién es hija. `padre_id` es un toro del hato; `padre_pajilla` es la
-- etiqueta de la pajilla cuando el padre no está en la finca. Los llena solo
-- el evento de parto, leyendo el último servicio de la madre.
ALTER TABLE public.animales
  ADD COLUMN IF NOT EXISTS padre_id uuid REFERENCES public.animales (id);
ALTER TABLE public.animales
  ADD COLUMN IF NOT EXISTS padre_pajilla text;

COMMENT ON COLUMN public.animales.padre_id IS
  'Toro del hato con el que se montó a la madre. Lo pone el evento de parto.';
COMMENT ON COLUMN public.animales.padre_pajilla IS
  'Pajilla con la que se inseminó a la madre, cuando el padre no es del hato.';

-- ----------------------------------------------------------- eventos_animal

-- Con cuál toro fue la monta. Va ligado al animal y no como texto: así la
-- cría queda con el padre de verdad y no con un nombre escrito a mano.
ALTER TABLE public.eventos_animal
  ADD COLUMN IF NOT EXISTS toro_id uuid REFERENCES public.animales (id);

-- Qué se le aplicó a la vaca cuando la palpación salió vacía. Texto libre: es
-- una nota para la hoja de vida, no una aplicación de Sanidad, así que no
-- mueve el retiro de leche.
ALTER TABLE public.eventos_animal
  ADD COLUMN IF NOT EXISTS tratamiento text;

COMMENT ON COLUMN public.eventos_animal.toro_id IS
  'Toro del hato con el que se montó. La pajilla va en toro_pajilla.';
COMMENT ON COLUMN public.eventos_animal.tratamiento IS
  'Tratamiento anotado en una palpación vacía. No registra sanidad.';

-- Buscar las crías de un toro es la consulta natural de esta tabla.
CREATE INDEX IF NOT EXISTS idx_animales_padre
  ON public.animales (padre_id)
  WHERE padre_id IS NOT NULL;
