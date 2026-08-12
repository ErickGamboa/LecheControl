# LecheControl — agent working guide

## Product context
Flutter offline-first app for dairy farm management (`lechería`), built around
three things:

1. **Cattle inventory and events** — births, health, reproduction, culling.
2. **Weekly milk weighing** — morning + evening litres and concentrate kg per
   cow, feeding a production report that grades each cow against a reference
   lactation curve.
3. **Weekly finances** — income (milk, cattle sales) and expenses are typed in,
   not calculated; the week's profit is the difference.

Local state is Drift/SQLite; Supabase is the remote sync/auth backend.

**Product behavior source of truth:** `docs/ESPECIFICACION_FUNCIONAL.md`. If a feature is not described there, do not build it. Implementation sequencing lives in `docs/ROADMAP.md`.

Architecture is intentionally aligned with sibling project `../HatoControlRun` (same offline-first + SyncService patterns).

## Language and documentation policy
- Domain is Spanish-first (`lechería`, `animal`, `pesa`, `sanidad`, `cuenta`). Preserve domain names in code and UI.
- Agent/developer docs should be understandable in English.
- Keep README, `AGENTS.md`, and `docs/` updated when workflows change.

## Architecture map
- `lib/main.dart` / `lib/app_bootstrap.dart`: bootstrap, Supabase init, connectivity-triggered sync.
- `lib/services.dart`: global singleton service/repository instances.
- `lib/data/local/database.dart`: Drift schema and migrations.
- `lib/data/repositories/`: local-first business operations. UI calls repositories, not Supabase.
- `lib/data/sync/sync_service.dart`: bidirectional sync Drift ↔ Supabase.
- Feature UI: `auth/`, `cuenta/`, `home/`, `trabajo/`, `inventario/`, `pesa/` (captura + reporte de producción), `finanzas/`, `hoja_vida/`, `sanidad/`.
- `lib/data/domain/`: reglas de negocio puras y testeables sin base de datos
  (`curva_lactancia.dart`, `semana.dart`, `grupos.dart`).

## Non-negotiable invariants
1. Offline-first: writes go to Drift first and set `pendiente=true`.
2. Server writes happen in `SyncService`, not from UI screens.
3. Every domain row uses a client-generated UUID primary key.
4. Soft deletes / bajas use `deletedAt` or estado historial; do not hard-delete animals.
5. Local writes that change syncable data must update `updatedAt` and mark `pendiente=true`.
6. Animal identifiers must be unique per lechería.
7. Never commit Supabase `service_role` secrets.
8. Regenerated Drift files (`database.g.dart`) after schema changes.
9. No self-registration in the app; accounts are created by the administrator.
10. One active lechería per account (v1).

## Quality commands

```bash
dart format lib test
flutter analyze
flutter test
```

If Drift schema changed:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Guardrails
- Do not add network calls in widgets unless auth-only.
- Do not clear `pendiente` until upload succeeds.
- Do not advance sync cursors beyond rows successfully applied locally.
