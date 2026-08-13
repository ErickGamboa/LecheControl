# QA automation — LecheControl

Test suite layout, how to run it locally, and how to seed a real Supabase
user for the visible e2e flow. Modeled on the equivalent setup in the sibling
project `HatoControlRun` (`docs/QA_AUTOMATION.md` there), adapted to
LecheControl's schema and domain (`lechería`, `animal`, `pesa`, `gastos`,
`rentabilidad`).

## ⚠️ Project safety

LecheControl has its **own** Supabase project — never reuse or touch
HatoControl's:

| Project | Supabase project ref | Use for |
|---|---|---|
| **LecheControl** (this repo) | `yskvlaovqvjfodiroaqz` | Everything in this doc. |
| HatoControlRun (sibling repo) | `geocoundyilwxrnbhcqu` | **Never.** Different app, different schema, different dart-defines (`HATO_*`). |

If a script or SQL snippet in this doc ever references
`geocoundyilwxrnbhcqu`, that's a bug — stop and fix it before running
anything against it.

## Test layers

1. **Unit / offline (`test/`)** — pure Dart + Drift against an in-memory
   SQLite database (`NativeDatabase.memory()`), no device, no network.
   - `test/support/local_db_seed.dart`: seed helpers (`seedCuentaLocal`,
     `seedLecheria`, `seedAnimal`) for repository tests.
   - `test/repositories/*_test.dart`: one file per repository
     (`animales`, `pesas`, `rentabilidad`, …).
   - `test/integration/offline_local_flow_test.dart`: exercises the full
     ganadero flow (alta lechería → alta animal → pesa → parámetros →
     rentabilidad) against the local database only, asserting nothing ever
     touches the network.
   - Run: `flutter test` (see `scripts/test.sh`).

2. **Device integration (`integration_test/`)** — real widget tree on a
   real device/simulator via `flutter_test` + `integration_test`.
   - `integration_test/helpers/integration_helpers.dart`: shared wait/tap/log
     helpers (`waitFor`, `invokeButton`, `e2eStep`, `pauseIntegration`, …).
   - `integration_test/helpers/supabase_assert.dart`: polls Supabase
     (`waitForSupabaseRow`, `listSupabaseRows`) to confirm sync landed.
   - `integration_test/app_smoke_test.dart`: boots the real app
     (`package:leche_control/main.dart`) and asserts the login screen
     renders. Works with **no** Supabase configuration (offline/demo mode) —
     see `lib/app_bootstrap.dart`: without `LECHE_SUPABASE_URL`/
     `LECHE_SUPABASE_ANON_KEY`, `AuthGate` skips `Supabase.initialize` and,
     with no local session saved, shows `LoginScreen` directly.
   - `integration_test/supabase_e2e_test.dart`: the visible dairy flow
     against a **real** Supabase project and a **real, pre-seeded** user —
     login → (create lechería if it's the user's first run) → Trabajo (alta
     animal) → Pesa de leche (register litros) → Gastos (set prices) →
     Rentabilidad (see the row) → confirm the animal synced to Supabase.
     Skips (does not fail) if `LECHE_E2E_EMAIL`/`LECHE_E2E_PASSWORD` are
     unset.
   - Run smoke: `flutter test -d macos integration_test/app_smoke_test.dart`
     (or `-d <simulator name>`).
   - Run the Supabase e2e: `scripts/run_e2e.sh` (see below).

## Running locally

```bash
./scripts/test.sh              # format + analyze + unit/offline tests
./scripts/verify_platforms.sh  # + macOS build + device smoke (macOS, iOS sim)
```

## ValueKeys added for testability

Added to existing screens (minimal, no new widgets besides where noted) so
both integration tests and manual QA can target elements reliably:

| Screen | Keys |
|---|---|
| `auth/login_screen.dart` (pre-existing) | `login.email`, `login.password`, `login.submit`, `login.offline` |
| `cuenta/cuenta_gate.dart` | `lecheria.nombre`, `lecheria.crear` |
| `home/home_screen.dart` | `home.trabajo`, `home.inventario`, `home.pesa`, `home.finanzas`, `home.sanidad`, `home.syncStatus`, `home.curva` |
| `trabajo/trabajo_screen.dart` | `trabajo.identificador`, `trabajo.buscar`, `trabajo.alta.abrir`, `trabajo.alta.identificador`, `trabajo.alta.sexoHembra`, `trabajo.alta.sexoMacho`, `trabajo.alta.grupo` (+ `trabajo.alta.grupo.<codigo>` per chip), `trabajo.alta.origenNacido`, `trabajo.alta.origenComprado`, `trabajo.alta.guardar`, `trabajo.animal.tarjeta` |
| `pesa/pesa_screen.dart` | `pesa.elegirVaca`, `pesa.cambiarVaca`, `pesa.manana`, `pesa.tarde`, `pesa.concentrado`, `pesa.guardar`, `pesa.cerrar`, `pesa.contador`, `pesa.historial`, `pesa.verReporte` |
| `pesa/selector_vaca_sheet.dart` | `selectorVaca.busqueda`, `selectorVaca.manual` |

`pesa.abrirSesion` was **not** added: `PesaScreen` opens/reuses today's
session automatically in `initState`, there is no button for it in the UI.
Past weeks are reached through `pesa.historial`, not by reopening a session.

## Seeding a Supabase e2e user

The app has **no self-registration** (D-09: accounts are created by the
administrator), so the e2e user must be seeded by hand, once, in the
LecheControl Supabase project (`yskvlaovqvjfodiroaqz`).

1. **Create the auth user**: Supabase Dashboard → Authentication → Users →
   *Add user* → set an email (e.g. `e2e@lechecontrol.test`) and a password.
   Copy the generated user UUID.

2. **Give it an active `pro` cuenta** (so the license check in
   `LecheriasRepository.crearLecheria` never blocks the flow) via the SQL
   Editor:

   ```sql
   -- Run in the LecheControl project (yskvlaovqvjfodiroaqz) ONLY.
   insert into public.cuentas (id, nombre, dueno_id, plan, estado)
   values (gen_random_uuid(), 'Cuenta E2E', '<uuid-del-usuario>', 'pro', 'activa');

   insert into public.usuarios (id, nombre, email, cuenta_id)
   values (
     '<uuid-del-usuario>',
     'Usuario E2E',
     'e2e@lechecontrol.test',
     (select id from public.cuentas where dueno_id = '<uuid-del-usuario>')
   );
   ```

   (This mirrors the manual "alta de cuenta nueva" recipe already documented
   at the bottom of `supabase/migrations/20260729120000_lechecontrol_v1.sql`.)

3. **First run** creates the lechería (v1: one per account) through the UI
   itself — `supabase_e2e_test.dart` detects whether `lecheria.nombre` (no
   lechería yet) or `home.trabajo` (already has one) shows up after login and
   branches accordingly. Subsequent runs reuse the same lechería and just add
   more animals/pesas to it.

4. Never insert directly into `auth.users` via SQL — always use the
   Dashboard/Admin API so Supabase Auth's password hashing is correct.

## dart-defines reference

| Variable | Used by | Purpose |
|---|---|---|
| `LECHE_SUPABASE_URL` | `lib/config/supabase_config.dart` | Supabase project URL. Required for anything beyond offline/demo mode. |
| `LECHE_SUPABASE_ANON_KEY` | `lib/config/supabase_config.dart` | Supabase anon/publishable key (safe to embed — RLS does the real enforcement). |
| `LECHE_DEMO` | `lib/demo/demo_env.dart` | `true`/`1`/`yes` seeds an offline demo lechería on startup (see `lib/demo/demo_seed.dart`). Not used by the test suite. |
| `LECHE_E2E_EMAIL` / `LECHE_E2E_PASSWORD` | `integration_test/supabase_e2e_test.dart` | Credentials of the pre-seeded e2e user. Test skips (not fails) when empty. |
| `LECHE_E2E_SLOW_MS` | `integration_test/helpers/integration_helpers.dart` | Pause (ms) after each e2e step, useful when demoing on a visible simulator. Defaults to `0`. |

Example manual run once credentials exist:

```bash
LECHE_SUPABASE_URL=https://yskvlaovqvjfodiroaqz.supabase.co \
LECHE_SUPABASE_ANON_KEY=<anon-key> \
LECHE_E2E_EMAIL=e2e@lechecontrol.test \
LECHE_E2E_PASSWORD=<password> \
LECHE_E2E_SLOW_MS=400 \
DEVICE=macos \
./scripts/run_e2e.sh
```

Watch a booted iOS Simulator while the e2e runs (separate terminal):

```bash
./scripts/watch_e2e_sim.sh
```
