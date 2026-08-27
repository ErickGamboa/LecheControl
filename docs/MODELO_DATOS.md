# Modelo de datos — LecheControl

Resumen del esquema local (Drift/SQLite, `lib/data/local/database.dart`) y su
espejo remoto (Supabase/Postgres, `supabase/migrations/20260729120000_lechecontrol_v1.sql`).
Ver también `lib/data/sync/sync_service.dart` para el mapeo exacto de columnas
(local camelCase ↔ remoto snake_case).

## Convenciones generales

- **Id**: todas las tablas de dominio usan `id` `TEXT` (UUID v4 generado en el
  cliente) como llave primaria. `planes` usa `codigo` como llave natural.
- **`createdAt` / `updatedAt`**: `createdAt` lo fija el cliente al crear y no
  cambia. `updatedAt` en Supabase SIEMPRE lo fija el servidor (`DEFAULT now()`
  + trigger en cada `UPDATE`) — así "gana el último que escribe" sin relojes
  de dispositivos desincronizados.
- **`deletedAt`**: borrado suave. Nunca se hace `DELETE` de una fila de
  dominio (D-08 del spec); se marca `deletedAt` y desaparece de las listas
  activas pero permanece en el historial.
- **`pendiente`**: solo existe en la base local. `true` mientras el cambio no
  se subió a Supabase; el motor de sync lo pone en `false` tras subir con
  éxito. Las tablas de solo lectura (`planes`, `cuentas`, `usuarios`) no
  tienen esta columna: el cliente nunca las escribe.
- **Sync**: `planes`, `cuentas`, `usuarios` son *pull-only* (las administra
  soporte). El resto de las tablas de dominio son *push + pull*.

## Tablas de solo lectura (licenciamiento)

| Tabla | Columnas clave | Notas |
|---|---|---|
| `planes` | `codigo` PK, `nombre`, `limite_lecherias`, `updated_at` | Catálogo fijo: `invitado`, `light`, `medium`, `pro`. |
| `cuentas` | `id`, `nombre`, `dueno_id`, `plan`, `estado` (`activa`/`suspendida`), `prueba_termina` | Unidad de licenciamiento; una cuenta puede tener varias lecherías según el límite del plan. |
| `usuarios` | `id` (= `auth.users.id`), `nombre`, `email`, `cuenta_id` | Perfil del usuario autenticado. |

## Lechería y membresía

| Tabla | Columnas clave | Notas |
|---|---|---|
| `lecherias` | `id`, `nombre`, `creada_por`, `cuenta_id`, `deleted_at` | v1: una lechería activa por cuenta. |
| `lecheria_miembros` | `id`, `lecheria_id`, `usuario_id`, `rol` (`admin`/`operario`) | Único activo por `(lecheria_id, usuario_id)`. Toda tabla de dominio se filtra por `private.es_miembro_lecheria`. |

## Hato y hoja de vida

| Tabla | Columnas clave | Notas |
|---|---|---|
| `animales` | `id`, `lecheria_id`, `identificador` (único por lechería, activos), `sexo`, `grupo`, `estado`, `estado_reproductivo`, `origen`, `precio_compra`, `fecha_compra`, `madre_id`, `fecha_probable_parto`, `retiro_leche_hasta`, `fecha_ultimo_parto` | `grupo` ∈ `en_ordeno, secas, novillas, terneros`. El estado **pronta** (le falta poco para parir) no se guarda: sale de `fecha_probable_parto`, justamente para que la vaca no tenga que salir de Secas. `retiro_leche_hasta` quedó sin uso — los medicamentos ya no llevan días de retiro. `fecha_ultimo_parto` es la base de los días de lactancia (DLac) del reporte de producción: la fija el evento `parto` y se puede corregir a mano desde la hoja de vida, que es como se cargan las vacas que ya estaban en la finca. |
| `eventos_animal` | `id`, `animal_id`, `lecheria_id`, `tipo`, `fecha`, + columnas específicas por tipo (`medicamento_id`/`dosis`/`dias_retiro`/`costo` para sanidad; `resultado` para palpación; `toro_pajilla` para servicio; `grupo_anterior`/`grupo_nuevo` para cambios de grupo/secado; `motivo_baja`/`precio_venta` para bajas; `sexo_cria`/`cria_animal_id` para partos) | Es la hoja de vida completa (Módulo 6): un registro append-only por evento. `tipo` ∈ `sanidad, celo, monta, inseminacion, palpacion, secado, parto, cambio_grupo, baja, concentrado`. |

## Registro de leche (Módulo 3)

| Tabla | Columnas clave | Notas |
|---|---|---|
| `pesas_sesiones` | `id`, `lecheria_id`, `fecha`, `cerrada` | Una sesión por día (se reutiliza si ya hay una abierta). |
| `pesas_leche` | `id`, `sesion_id`, `animal_id`, `identificador_manual`, `litros`, `litros_manana`, `litros_tarde`, `concentrado_kg` | Sin `lecheria_id` propio: la membresía se valida vía `pesas_sesiones.lecheria_id`. Un registro por vaca por sesión (se corrige, no se duplica). `litros` es el total del día y lo calcula el cliente. Viene `animal_id` (vaca del inventario) **o** `identificador_manual` (vaca que se pesa sin ficha, sin días de lactancia), nunca los dos. Las filas anteriores a v2 no tienen desglose mañana/tarde y el reporte las marca como tales. |

| `calidad_leche` | `id`, `lecheria_id`, `semana_id`, `solidos_totales_pct`, `celulas_somaticas`, `conteo_bacterial` | Lo que reporta la planta de la leche entregada, **una fila por semana** (única por `(lecheria_id, semana_id)` entre las activas). La semana es la misma de las finanzas (`semanas`), por eso cuelga de `semana_id` y no lleva su propio calendario. Los tres análisis son opcionales por separado: la planta no siempre manda los tres el mismo día. Una fila que se queda sin ningún valor se borra suave — una lectura vacía no es una semana medida y haría un hueco en los gráficos. La app no calcula nada con esto: solo dice en qué escalón cayó cada número (`domain/calidad_leche.dart`, donde viven las tablas de la planta y las de referencia). |

## Reporte de producción (Módulo 3)

| Tabla | Columnas clave | Notas |
|---|---|---|
| `curva_referencia` | `id`, `lecheria_id`, `orden`, `dia_desde`, `dia_hasta`, `litros_esperados` | Siete tramos editables por lechería (pantalla `lib/ajustes/curva_screen.dart`): cuántos litros se esperan según los días de lactancia. Para una vaca concreta el esperado **no** es el escalón del tramo — se interpola entre el punto central de cada tramo (`(dia_desde + dia_hasta) / 2`; para el último, `dia_hasta` nulo, `dia_desde + 25`), para que la curva suba y baje suave. Valores iniciales: 18.8 / 26 / 24 / 21 / 18 / 14 / 10. `CurvaRepository.promediosRealesDelHato` calcula lo que el hato produce de verdad en cada tramo, sobre todas las pesas, para poder recalibrar tramo por tramo cuando haya suficientes observaciones (10 por defecto). |
| `config_reporte` | `id`, `lecheria_id`, `pct_excelente`, `pct_bueno`, `pct_vigilar`, `pct_bajo`, `umbral_secado_litros` | Único por lechería. Umbrales de `producción ÷ esperado` para etiquetar cada vaca. |

## Finanzas semanales (Módulo 4 y 5)

El período es la **semana** (lunes a domingo), no el mes. Los ingresos **no se
calculan**: se digita la plata que efectivamente entró.

| Tabla | Columnas clave | Notas |
|---|---|---|
| `semanas` | `id`, `lecheria_id`, `fecha_inicio`, `fecha_fin`, `cerrada` | Único por `(lecheria_id, fecha_inicio)`. `fecha_inicio` es el lunes. Columnas `date` en Postgres: el sync manda solo el día. |
| `ingresos_semana` | `id`, `lecheria_id`, `semana_id`, `tipo`, `monto`, `litros`, `animal_id`, `detalle` | `tipo` ∈ `leche, venta_ganado, otro`. `litros` solo aplica a `leche`: `monto / litros` da el precio real por litro de la semana. `animal_id` solo aplica a `venta_ganado`, para la hoja de vida del animal. |
| `gastos_semana` | `id`, `lecheria_id`, `semana_id`, `categoria`, `monto`, `detalle` | Los botones fijos son Salarios, Luz, Concentrado, Medicamentos y Combustible (`CategoriaGasto` en `domain/semana.dart`); la categoría sigue siendo texto libre para lo que no cae en ninguno. **Compra de ganado** la mete sola el alta de un animal comprado, con el identificador en `detalle`. |
| `categorias_gasto` | `id`, `lecheria_id`, `nombre`, `orden` | Sin uso desde que los botones de gasto son fijos. Se conserva por el sync y por lo que ya estaba cargado. |

Utilidad de la semana = `Σ ingresos_semana − Σ gastos_semana`. No se persiste:
se calcula al abrir el módulo.

### Empezar de cero

`supabase/scripts/borrar_datos_finca.sql` vacía el contenido de la finca
(animales, eventos, pesas, medicamentos, gastos) y **mantiene** la cuenta, el
usuario, la lechería, la curva de referencia, los umbrales y las categorías de
gasto. No cambia el esquema, por eso vive en `scripts/` y no en `migrations/`.

⚠️ Antes de correrlo hay que **borrar los datos de la app en cada dispositivo**
(Ajustes → Aplicaciones → LecheControl → Almacenamiento → Borrar datos). Si no,
las filas locales marcadas `pendiente` se vuelven a subir en la siguiente
sincronización y los datos reaparecen.

### Tablas reemplazadas (se eliminan en la migración de limpieza)

`parametros_periodo` y `costos_fijos` (período mensual, precio del litro
digitado) quedan reemplazadas por `semanas` / `ingresos_semana` /
`gastos_semana`. `config_alertas` desaparece junto con el módulo de Alertas.
Siguen en el esquema hasta que la app deje de leerlas — ver
`supabase/migrations/20260810120100_v2_limpieza.sql`.

## Sanidad (Módulo 7)

| Tabla | Columnas clave | Notas |
|---|---|---|
| `medicamentos` | `id`, `lecheria_id`, `nombre`, `dosis_aplicacion`, `ml_envase` | Catálogo editable por lechería. `dosis_aplicacion` es texto libre, como dice la etiqueta ("10 ml cada 50 kilos"). Sin costo ni días de retiro: la plata de los medicamentos entra como gasto semanal. |

Aplicar (`SanidadRepository.aplicarMedicamentos`) admite **varios medicamentos
a la vez** y crea un `eventos_animal` tipo `sanidad` por cada uno, con la misma
fecha, el nombre en `detalle` y la dosis en `dosis`. No fija costo, ni días de
retiro, ni cambia el grupo del animal.

## Alertas (Módulo 9)

| Tabla | Columnas clave | Notas |
|---|---|---|
| `config_alertas` | `id`, `lecheria_id`, `dias_celo_esperado`, `dias_confirmar_preniez`, `dias_vacios_altos`, `dias_antes_secar`, `dias_antes_parto`, `dias_aviso_fin_retiro` | Único por lechería; valores por defecto sensatos si nunca se guardó. |

Las alertas en sí (`AlertasRepository.generarAlertas`) no se persisten: se
recalculan a partir de `animales` + `eventos_animal` + `config_alertas` cada
vez que se abre el módulo.

## Tablas solo locales (no viajan a Supabase)

| Tabla | Uso |
|---|---|
| `sync_cursores` | Por tabla: `(updated_at, id)` del último registro bajado del servidor. |
| `sync_estados` | Por tabla: última sincronización exitosa / último error, para mostrarle al usuario "N cambios pendientes" sin leer logs. |
| `sesiones_locales` | Identidad verificada la última vez que hubo internet, para permitir entrar sin conexión después. |

## RLS (Supabase)

Toda tabla de dominio con `lecheria_id` usa la función
`private.es_miembro_lecheria(lecheria_id, auth.uid())` para `SELECT`/`INSERT`/
`UPDATE`. `pesas_leche` (que no tiene `lecheria_id` propio) valida por `JOIN`
con `pesas_sesiones`. Ninguna tabla permite `DELETE` desde el cliente (borrado
siempre suave, vía `UPDATE` de `deleted_at`).
