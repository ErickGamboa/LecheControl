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
| `animales` | `id`, `lecheria_id`, `identificador` (único por lechería, activos), `sexo`, `grupo`, `estado`, `estado_reproductivo`, `origen`, `precio_compra`, `fecha_compra`, `madre_id`, `concentrado_kg_dia`, `fecha_probable_parto`, `retiro_leche_hasta` | `grupo` ∈ `en_ordeno, secas, novillas, terneros, en_tratamiento`. `retiro_leche_hasta` bloquea el ingreso de leche en Rentabilidad mientras esté vigente. |
| `eventos_animal` | `id`, `animal_id`, `lecheria_id`, `tipo`, `fecha`, + columnas específicas por tipo (`medicamento_id`/`dosis`/`dias_retiro`/`costo` para sanidad; `resultado` para palpación; `toro_pajilla` para servicio; `grupo_anterior`/`grupo_nuevo` para cambios de grupo/secado; `motivo_baja`/`precio_venta` para bajas; `sexo_cria`/`cria_animal_id` para partos) | Es la hoja de vida completa (Módulo 6): un registro append-only por evento. `tipo` ∈ `sanidad, celo, monta, inseminacion, palpacion, secado, parto, cambio_grupo, baja, concentrado`. |

## Pesa de leche (Módulo 3)

| Tabla | Columnas clave | Notas |
|---|---|---|
| `pesas_sesiones` | `id`, `lecheria_id`, `fecha`, `cerrada` | Una sesión por día (se reutiliza si ya hay una abierta). |
| `pesas_leche` | `id`, `sesion_id`, `animal_id`, `litros` | Sin `lecheria_id` propio: la membresía se valida vía `pesas_sesiones.lecheria_id`. Un registro por animal por sesión (se corrige, no se duplica). |

## Gastos y rentabilidad (Módulo 4 y 5)

| Tabla | Columnas clave | Notas |
|---|---|---|
| `parametros_periodo` | `id`, `lecheria_id`, `anio`, `mes`, `precio_litro`, `precio_concentrado_kg`, `umbral_secado_litros` | Único por `(lecheria_id, anio, mes)`. |
| `costos_fijos` | `id`, `lecheria_id`, `periodo_id`, `categoria`, `monto` | Se reparten entre las vacas activas del grupo `en_ordeno` (Módulo 5: `costoFijoDia = total / díasDelMes`, dividido entre la cantidad de vacas). |

Rentabilidad (`lib/data/repositories/rentabilidad_repository.dart`) no
persiste nada: se calcula en memoria a partir de la última pesa de cada vaca,
`parametros_periodo` y la suma de `costos_fijos` del mes.

## Sanidad (Módulo 7)

| Tabla | Columnas clave | Notas |
|---|---|---|
| `medicamentos` | `id`, `lecheria_id`, `nombre`, `costo_envase`, `tipo_dosis` (`fija`/`por_aplicacion`), `ml_envase`, `aplicaciones_envase`, `dosis_fija_ml`, `dias_retiro_leche` | Catálogo editable por lechería. El costo por aplicación se calcula en `MedicamentosRepository.calcularCosto`. |

Aplicar un medicamento (`SanidadRepository.aplicarMedicamento`) crea un
`eventos_animal` tipo `sanidad` y, si `dias_retiro_leche > 0`, fija
`animales.retiro_leche_hasta`.

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
