# LecheControl — agent working guide

## Product context
Flutter offline-first app for dairy farm management (`lechería`), built around
three things:

1. **Cattle inventory and events** — births, health, reproduction, culling.
2. **Weekly milk recording** (`Registro de leche`) — the per-cow weighing
   (morning + evening litres and concentrate kg, feeding a production report
   that grades each cow against a reference lactation curve), plus the weekly
   **milk quality** figures the plant reports back (total solids, somatic
   cells, bacterial count). Quality is typed in, never computed; the app only
   states which band each figure falls in.
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
- Feature UI: `auth/`, `cuenta/`, `home/`, `trabajo/`, `inventario/`, `pesa/` (Registro de leche: menú, pesa + reporte de producción, calidad de leche), `analisis/`, `finanzas/`, `hoja_vida/`, `sanidad/`.
- `lib/data/domain/`: reglas de negocio puras y testeables sin base de datos
  (`curva_lactancia.dart`, `semana.dart`, `grupos.dart`, `calidad_leche.dart`).

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

## Platform requirements (network)

The app must reach Supabase from any installed device, not just from
`flutter run`.

- **Android:** `INTERNET` and `ACCESS_NETWORK_STATE` live in
  `android/app/src/main/AndroidManifest.xml`. Flutter only scaffolds
  `INTERNET` into `src/debug/` and `src/profile/`, so a missing entry in
  `main` breaks login and sync in **release only**, with no error pointing at
  the permission. `test/plataforma/permisos_red_test.dart` guards this.
- **iOS:** nothing to declare. Supabase is HTTPS and ATS allows that by
  default; do not add `NSAllowsArbitraryLoads`.
- **Credentials:** `SupabaseConfig` embeds the project URL and the `anon` key
  as defaults, because an installed APK gets no `--dart-define`. The `anon`
  key is public by design; RLS is the real boundary.
- Auth is email/password (`signInWithPassword`) — no OAuth, so no deep-link
  URL schemes or intent filters are needed.

**Still open:** `android/app/build.gradle.kts` signs release with the debug
keystore (Flutter's scaffold TODO). Fine for sideloading an APK; Play Store
will reject it. Needs a real keystore before store distribution.

## Keep `lib/` web-compatible (non-negotiable)

This package is **consumed as a path dependency** by the sibling project
`../LecheControlWeb`, which compiles it to Flutter web. There is no second copy
of the product: the browser on a phone renders *this* widget tree, and the
desktop layout wraps *these* screens. A regression here breaks three clients at
once, and the web build is the only place it shows up.

**Rules:**

1. **No bare `dart:io` in `lib/`.** Not `File`, not `Directory`, not
   `Platform.*`, not `Process`. Today `lib/` has zero occurrences — keep it
   that way. If you genuinely need a platform API, hide it behind a
   conditional export and never delete the web branch:

   ```dart
   // lib/x/algo.dart
   export 'algo_web.dart' if (dart.library.io) 'algo_io.dart';
   ```

   `dart:io` inside `test/` is fine (see
   `test/plataforma/permisos_red_test.dart`), because tests only run on the VM.

2. **Do not remove the `web:` argument in `_abrirConexion()`**
   (`lib/data/local/database.dart`). Without `DriftWebOptions`, drift throws
   `ArgumentError` the moment it opens the database on web. The options are
   *ignored* on Android/iOS, so they cost the phone nothing.

3. **Bumping `drift` or `sqlite3` is a two-project change.** The `sqlite3.wasm`
   and `drift_worker.js` files in `LecheControlWeb/web/` must match the
   versions resolved in **this** `pubspec.lock` exactly. A mismatch fails at
   runtime in the browser, not at compile time. After any bump, re-download
   both (`LecheControlWeb/scripts/sincronizar_web_assets.sh`) and re-run
   `flutter build web` there.

4. **Declare assets file by file**, never a whole folder. A folder entry ships
   images the app never opens inside the APK and the IPA, and the web project
   has to mirror the list. All four current assets are declared individually
   and all four are used.

5. **Shared behavior lives here, never in the web project.** Creating and
   editing records, account state, permissions, statistics, formatting — if
   both clients must do it the same way, it belongs in this package. The web
   project is allowed to contain only: `main.dart`, the width adapter, the
   desktop layout, copied assets and `web/`.

   Three seams exist for exactly this reason — extend them rather than
   duplicating anything on the web side:

   - `ConstructorHome` (`lib/cuenta/cuenta_gate.dart`) lets the desktop shell
     swap the home screen *without* re-implementing the session → account →
     lechería path.
   - `ResumenHato` and `ProduccionSemanal` (`lib/home/widgets/`) are used by
     both `HomeScreen` and the web's desktop dashboard. **Do not inline them
     back into `HomeScreen`**: the counts, the group order, the colours and
     where tapping the chart leads must be decided once.
   - `LineaProduccion.altoGrafico` defaults to the phone's 104 px; the desktop
     dashboard passes a larger value. Keep the default — it is what the phone
     layout depends on.

6. **Close dialogs with the dialog's context, never the screen's.**

   ```dart
   // WRONG — works on the phone by accident, crashes on desktop
   showDialog(context: context, builder: (_) => AlertDialog(actions: [
     TextButton(onPressed: () => Navigator.pop(context), ...),
   ]));

   // RIGHT
   showDialog(context: context, builder: (contextoDialogo) => AlertDialog(actions: [
     TextButton(onPressed: () => Navigator.pop(contextoDialogo), ...),
   ]));
   ```

   `showDialog` mounts on the **root** navigator, but `Navigator.pop(context)`
   pops the *nearest* one. On the phone there is only one navigator, so the
   nearest is the root and it happens to work. On desktop each section runs in
   its own `Navigator`, so the nearest is the section's: the pop removes the
   module screen instead of the dialog, the section is left with no routes, and
   Flutter shows the red `Assertion failed: _history.isNotEmpty` screen.

   It compiles, and the screen's own tests pass. `test/plataforma/
   dialogos_context_test.dart` scans the source and fails with the exact file
   and line. Do not silence it — name the builder parameter.

   `showModalBottomSheet` is not affected: it defaults to the nearest
   navigator, which is the same one the sheet was pushed onto.

7. **Verify with a build, not by reading imports.** Before finishing any change
   that touches `lib/`, run `flutter build web` in `../LecheControlWeb`.

**Read-only permissions — known gap.** `Miembros.rol` accepts
`'admin' | 'operario'`, and `LecheriasRepository.crearLecheria` always writes
`'admin'`. **No screen reads that column**, so there is no read-only mode in
any client. When you implement one, it must be enforced in this package (a
repository guard, not a hidden button), so all three clients inherit it. RLS is
currently the only real boundary.

## Quality commands

```bash
dart format lib test
flutter analyze
flutter test
```

Web compatibility of `lib/` (run from the sibling project):

```bash
cd ../LecheControlWeb && flutter build web
```

If Drift schema changed:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Guardrails
- Do not add network calls in widgets unless auth-only.
- Do not clear `pendiente` until upload succeeds.
- Do not advance sync cursors beyond rows successfully applied locally.
- Do not add a global timeout around a whole sync run, and do not add a
  "sync now" button. Sync must upload everything in one go, retrying until
  nothing is pending, triggered automatically (startup, save, reconnect,
  periodic retry). Request-level timeouts live in `SyncRemoteGateway`.
