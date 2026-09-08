# LecheControl

Flutter app for dairy farm (`lechería`) management: animals, milk weighing,
health, reproduction, costs, profitability, and alerts. The app is
**offline-first**: every write goes to a local Drift/SQLite database first
and is synchronized with Supabase in the background.

Aplicación Flutter para el manejo de una lechería: animales, pesa de leche,
sanidad, reproducción y finanzas semanales. La app es
**offline-first**: cada operación se guarda primero en una base local
(Drift/SQLite) y se sincroniza con Supabase en segundo plano cuando hay
internet.

## Main modules / Módulos principales

- Módulo 0 — Cuenta y lechería (login, sin auto-registro)
- Módulo 1 — Trabajo (identificar animal, registrar eventos)
- Módulo 2 — Inventario del hato
- Módulo 3 — Pesa de leche semanal y reporte de producción
- Módulo 4 — Finanzas de la semana (ingresos digitados, gastos y utilidad)
- Módulo 6 — Hoja de vida (dentro de Inventario)
- Módulo 7 — Sanidad (catálogo de medicamentos y aplicaciones)
- Módulo 8 — Análisis (todas las semanas: leche y finanzas)

## Architecture / Arquitectura

```text
Flutter UI → Repositories → Drift/SQLite (local, source of truth for the UI)
                         ↕
                    SyncService
                         ↕
                   Supabase/Postgres (remote backup + multi-device sync)
```

- `lib/data/local/database.dart` — esquema Drift (todas las tablas de dominio).
- `lib/data/repositories/` — reglas de negocio; la UI nunca llama a Supabase
  directamente, siempre pasa por un repositorio.
- `lib/data/sync/sync_service.dart` — motor de sincronización bidireccional
  (`TableSyncSpec` por tabla: sube lo `pendiente`, baja lo nuevo del servidor).
- `lib/services.dart` — instancias compartidas de repositorios y servicios.

Aligned with the sibling project `../HatoControlRun` (same offline-first +
SyncService patterns), adapted to the dairy domain.

Useful docs / documentos útiles:
- `AGENTS.md` — guía y reglas para agentes de código
- `docs/ESPECIFICACION_FUNCIONAL.md` — documento fuente de verdad del producto
- `docs/ROADMAP.md` — qué está construido y qué falta
- `docs/MODELO_DATOS.md` — resumen del modelo de datos (tablas locales y remotas)
- `supabase/migrations/` — esquema versionado de Supabase (SQL)

## Local setup / Configuración local

Install Flutter (see `pubspec.yaml` for the SDK constraint), then:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Quality checks / comandos de calidad:

```bash
dart format lib test
flutter analyze
flutter test
```

If the Drift schema changes / si cambia el esquema de Drift:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Supabase configuration / configuración de Supabase

LecheControl uses **its own** Supabase project, `yskvlaovqvjfodiroaqz` (do not
reuse HatoControl's, `geocoundyilwxrnbhcqu`). Its URL and anon key are the
defaults in `lib/config/supabase_config.dart`, so a plain `flutter run` — and
any installed APK — is connected to the cloud database out of the box. No
`--dart-define` needed.

The `anon` key is a public client key by design: it ships inside every client
build and is extractable from any APK. RLS policies enforce real security.
**Never** commit a `service_role` key.

To point a build at a **different** project (e.g. staging), override the
defaults without editing the file:

```bash
flutter run \
  --dart-define=LECHE_SUPABASE_URL=https://OTRO-PROYECTO.supabase.co \
  --dart-define=LECHE_SUPABASE_ANON_KEY=OTRA_ANON_KEY
```

`scripts/run_dev.sh` does this for you, reading the values from a gitignored
`.local/e2e_credentials.env` and refusing to start if the URL points at
HatoControl.

Setting up a project from scratch: create it, then run the SQL in
`supabase/migrations/20260729120000_lechecontrol_v1.sql` (Supabase → SQL
Editor → paste → run). It creates every table, RLS policy and the `planes`
seed.

Accounts are **not** self-registered in the app (Módulo 0, invariant no. 9):
an administrator creates the `cuentas`/`usuarios` rows and gives credentials
to the farmer. See the bottom of the migration file for a manual example.

### No hay modo demo / There is no demo mode

Hubo uno (`LECHE_DEMO=true`) y **no se vuelve a poner**. Sembraba una lechería
falsa y llamaba a `supabase.auth.signOut()` en *cada* arranque, así que en la
build de TestFlight que salió con esa bandera el ganadero abría la app y en vez
de su finca veía una inventada con 3 animales, ya sin sesión y sin poder subir
lo que había digitado. Se perdieron datos reales.

Si hace falta enseñar la app sin tocar datos de nadie, se crea una cuenta de
verdad en Supabase (`supabase/scripts/dar_de_alta_usuario.sql`) y se entra con
ella. Nunca sembrando datos desde el arranque.

No queda nada de ese modo en el código. Si algún teléfono todavía tiene la
finca falsa guardada de una build vieja, se borra la app y se instala de nuevo:
no había nada real que perder.

## Agent-friendly repo notes / Notas para agentes

- Spanish domain terms are intentional: `lechería`, `animal`, `pesa`,
  `sanidad`, `cuenta`. Preserve them in code and UI.
- Keep business rules in repositories/sync services, not directly in widgets.
- Local writes to syncable tables must set `updatedAt` and `pendiente = true`;
  never hard-delete a domain row (soft delete via `deletedAt`).
- If the data shape changes, update the Drift schema/migrations, the sync
  service, the Supabase SQL migration, and `docs/MODELO_DATOS.md` together.

## Notes

- Supabase anon/publishable keys are public client keys. Never commit
  `service_role` secrets.
- After editing the Drift schema, regenerate `lib/data/local/database.g.dart`
  with `dart run build_runner build --delete-conflicting-outputs`.
