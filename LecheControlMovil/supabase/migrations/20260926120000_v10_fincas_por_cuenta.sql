-- v10: cuántas fincas admite cada cuenta.
--
-- No cambia el esquema: las dos tablas ya existían y la app ya leía el tope.
-- Lo único que hace es poner los números correctos y dejar a todas las cuentas
-- de hoy en el mismo lugar.
--
--   light   1 finca
--   medium  3 fincas
--   pro     sin tope en la práctica
--
-- `pro` va con 99 y no con «sin límite» porque la columna es un entero con
-- CHECK (> 0). Permitir nulo pediría tocar el esquema en Supabase y en el
-- teléfono, con migración en los dos lados, para una diferencia que ningún
-- ganadero va a notar: nadie va a tener 99 fincas.
--
-- ⚠️ HAY CLIENTES USANDO LA APP. Por eso este script:
--   - no toca ni una fila de animales, eventos, pesas ni finanzas;
--   - deja a todas las cuentas en `light`, que es **un tope de 1**, igual que
--     el `invitado` en el que están hoy. Nadie pierde acceso a nada ni ve
--     cambiar una sola pantalla;
--   - y es idempotente: correrlo dos veces da lo mismo.
--
-- En la app **no se nombra nada de esto**. No hay pantalla de planes, no se
-- dice cuántas fincas tiene ni cuántas puede tener. Lo único que cambia para
-- el ganadero es si le aparece el botón de agregar finca.

BEGIN;

-- 1. Los topes.
--
-- El `updated_at = now()` no es de adorno: `planes` no tiene trigger que lo
-- mueva solo, y el sync de los teléfonos baja por el cursor (updated_at, id).
-- Sin tocarlo, el número cambia en Supabase y **ningún teléfono se entera
-- nunca**. Pasó en la primera corrida de este mismo script.
UPDATE public.planes SET limite_lecherias = 1,  nombre = 'Light',  updated_at = now() WHERE codigo = 'light';
UPDATE public.planes SET limite_lecherias = 3,  nombre = 'Medium', updated_at = now() WHERE codigo = 'medium';
UPDATE public.planes SET limite_lecherias = 99, nombre = 'Pro',    updated_at = now() WHERE codigo = 'pro';

-- `invitado` se queda en 1. Es el valor por defecto de la columna, así que
-- una cuenta recién creada cae ahí sola y se comporta igual que light.
UPDATE public.planes SET limite_lecherias = 1, updated_at = now() WHERE codigo = 'invitado';

-- 2. Todas las cuentas de hoy quedan en light.
--
-- Se excluyen las que ya estén en medium o pro para que volver a correr esto
-- no le baje el tope a una cuenta a la que después se lo subieron a mano.
UPDATE public.cuentas
   SET plan = 'light', updated_at = now()
 WHERE deleted_at IS NULL
   AND plan NOT IN ('medium', 'pro');

COMMIT;

-- ---------------------------------------------------------------------------
-- Comprobación
-- ---------------------------------------------------------------------------

-- `updated_at` tiene que haber quedado de hoy en las cuatro filas. Si quedó
-- vieja, los teléfonos no van a bajar los topes nuevos.
SELECT codigo, limite_lecherias, updated_at FROM public.planes ORDER BY limite_lecherias;

-- Cada cuenta, su tope y cuántas fincas tiene. `de_mas` debería ser 0 en
-- todas: si alguna quedara con más fincas que su tope, no se le borra
-- ninguna —los datos no se tocan— pero no va a poder agregar otra.
SELECT c.nombre,
       c.plan,
       p.limite_lecherias AS tope,
       count(l.id)        AS fincas,
       greatest(count(l.id) - p.limite_lecherias, 0) AS de_mas
  FROM public.cuentas c
  JOIN public.planes p ON p.codigo = c.plan
  LEFT JOIN public.lecherias l
         ON l.cuenta_id = c.id AND l.deleted_at IS NULL
 WHERE c.deleted_at IS NULL
 GROUP BY c.nombre, c.plan, p.limite_lecherias
 ORDER BY c.nombre;
