# LecheControl

Flutter app for dairy farm (`lechería`) management: animals, milk weighing,
health, reproduction, costs, profitability, and alerts. The app is
**offline-first**: every write goes to a local Drift/SQLite database first
and is synchronized with Supabase in the background.

Aplicación Flutter para el manejo de una lechería: animales, pesa de leche,
sanidad, reproducción, gastos, rentabilidad y alertas. La app es
**offline-first**: cada operación se guarda primero en una base local
(Drift/SQLite) y se sincroniza con Supabase en segundo plano cuando hay
internet.

## Main modules / Módulos principales

- Módulo 0 — Cuenta y lechería (login, sin auto-registro)
- Módulo 1 — Trabajo (identificar animal, registrar eventos)
- Módulo 2 — Inventario del hato
- Módulo 3 — Pesa de leche
- Módulo 4 — Gastos (parámetros del período y costos fijos)
- Módulo 5 — Rentabilidad por vaca
- Módulo 6 — Hoja de vida
- Módulo 7 — Sanidad (catálogo de medicamentos y aplicaciones)
- Módulo 9 — Alertas reproductivas y de manejo

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

LecheControl needs **its own** Supabase project (do not reuse HatoControl's).
Until one is created, the app still runs fully offline (see Demo mode
below). To connect a real project:

1. Create a Supabase project.
2. Run the SQL in `supabase/migrations/20260729120000_lechecontrol_v1.sql`
   (Supabase → SQL Editor → paste → run). It creates every table, RLS policy
   and the `planes` seed.
3. Run the app with your project's URL and anon (publishable) key:

   ```bash
   flutter run \
     --dart-define=LECHE_SUPABASE_URL=https://TU-PROYECTO.supabase.co \
     --dart-define=LECHE_SUPABASE_ANON_KEY=TU_ANON_KEY
   ```

The `anon` key is a public client key by design (RLS enforces real security).
**Never** commit a `service_role` key.

Accounts are **not** self-registered in the app (Módulo 0, invariant no. 9):
an administrator creates the `cuentas`/`usuarios` rows and gives credentials
to the farmer. See the bottom of the migration file for a manual example.

### Demo mode / modo demo

To explore every module without a Supabase project, run with
`LECHE_DEMO=true`. On first launch it seeds a local-only lechería with 5
animals, medications, monthly parameters, and a closed milk-weighing
session, then logs in offline automatically:

```bash
flutter run --dart-define=LECHE_DEMO=true
```

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
