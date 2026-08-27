# Roadmap — LecheControl

Estado del desarrollo respecto a `docs/ESPECIFICACION_FUNCIONAL.md` (fuente
de verdad del producto). Última actualización: 2026-07-29.

## Construido ✅

### Plataforma / infraestructura
- Esquema Drift completo (16 tablas locales) con `pendiente`, `deletedAt`,
  UUID de cliente, migración `onCreate: createAll`.
- `SyncService` con `TableSyncSpec` por tabla (push+pull para dominio,
  pull-only para `planes`/`cuentas`/`usuarios`), reintentos por fila,
  cursores compuestos `(updated_at, id)`, guard anti-pisado de cambios
  locales pendientes.
- `SyncRemoteGateway`/`SupabaseSyncRemoteGateway` (sin subida de fotos: no
  aplica al dominio de LecheControl).
- Migración SQL de Supabase completa: 13 tablas de dominio + `planes`,
  helpers `private.es_miembro_lecheria`/`private.es_admin_lecheria`, RLS en
  cada tabla, triggers `updated_at`, seed de planes.
- Sesión local offline (`SesionLocalRepository`) + `AuthGate` (sesión
  Supabase → offline → login) + arranque tolerante a Supabase sin configurar.
- Modo demo (`LECHE_DEMO=true`): siembra una lechería con 5 animales,
  medicamentos, parámetros del mes y una sesión de pesa cerrada, sin
  necesitar un proyecto de Supabase.
- Tema visual propio (verde/teal + crema, sin morado) y widgets táctiles
  compartidos (`ScanField`, `QuickNumberField`).

### Módulo 0 — Acceso
- Login con Supabase Auth (correo + contraseña), sin registro.
- Entrada sin conexión con sesión cacheada; al iniciar sesión entra directo
  al Home con la lechería activa (o a un formulario mínimo si es la primera
  vez y todavía no existe la lechería).
- Cuenta suspendida / prueba vencida → pantallas simples con contacto de
  soporte, en vez de bloquear con un error genérico.

### Módulo 1 — Pantalla de Trabajo
- Identificación por `ScanField` (RFID o manual) contra el inventario local.
- Tarjeta de estado: grupo, estado reproductivo, última producción, aviso de
  retiro de leche vigente, concentrado actual.
- Botones grandes para: Sanidad, Celo/Monta/Inseminación, Palpación, Secado
  (solo si está en ordeño), Parto (solo si está preñada), Cambiar de grupo,
  Concentrado, Dar de baja.
- Alta de animal nuevo desde la misma pantalla cuando no se encuentra el
  identificador.

### Módulo 2 — Inventario
- Lista con buscador por identificador y filtro por grupo.
- Alta de animal, baja rápida (venta/muerte/descarte) y acceso a la hoja de
  vida por toque.

### Módulo 3 — Registro de leche
- Menú de entrada con las dos cosas que se anotan de la leche: la pesa y la
  calidad.
- **Pesa:** apertura/reutilización de sesión, contador de pesadas vs.
  faltantes (contra el grupo En ordeño), corrección si un animal ya se pesó.
- Resumen de sesión (total, promedio, máximo, mínimo, variación vs. la
  sesión anterior) y accesos a historial/tendencia por animal.
- **Calidad:** sólidos totales, células somáticas y conteo bacterial por
  semana, con el grado de cada uno y las tablas de la planta como guía.
  Se analiza en Análisis → Calidad de leche.

### Módulo 4 — Gastos
- Parámetros del mes (precio del litro, precio del concentrado, umbral de
  secado) y lista de costos fijos con su total.

### Módulo 5 — Rentabilidad
- Tabla completa por vaca en ordeño (litros, costo concentrado, costo fijo
  por vaca, costo total, ingreso, utilidad), utilidad total del período,
  Top 5 mejores/peores y candidatas a secar según el umbral configurado.
- Leche en retiro se descarta del ingreso automáticamente (D-05 del spec).

### Módulo 6 — Hoja de vida
- Encabezado con estado actual (sexo, grupo, estado, estado reproductivo,
  fecha probable de parto, retiro de leche, concentrado).
- Pestaña de eventos (todo tipo, con su detalle) y pestaña de pesas
  históricas.

### Módulo 7 — Sanidad
- Catálogo de medicamentos (CRUD) con dosis fija o por aplicación y días de
  retiro.
- Aplicación rápida desde Sanidad o desde la Pantalla de Trabajo: calcula el
  costo y, si corresponde, deja al animal en retiro de leche.

### Módulo 8 — Sincronización
- Icono de estado en el Home + hoja de detalle (cambios pendientes por
  subir, sincronizar ahora).
- Aviso de modo sin conexión.

### Módulo 9 — Alertas
- Celo esperado, confirmar preñez, vacía hace mucho, próxima a secar,
  próxima a parir, fin de retiro de leche — todas calculadas en el momento a
  partir de eventos + configuración, sin tablas de alertas persistidas.
- Badge de alertas pendientes en el Home; toque navega a la hoja de vida.

## Pendiente / próximos pasos ⏳

- **Proyecto de Supabase real**: crear el proyecto, correr la migración SQL,
  y pasar `LECHE_SUPABASE_URL`/`LECHE_SUPABASE_ANON_KEY` por `--dart-define`.
  Sin esto la app solo funciona en modo local/demo.
- **Gestión de equipo**: no hay UI para invitar operarios a una lechería
  (la tabla `lecheria_miembros` y las políticas RLS ya soportan varios
  miembros con rol `admin`/`operario`, pero falta la pantalla).
- **Edición de `config_alertas`** desde la UI (hoy usa siempre los valores
  por defecto salvo que se edite directo en la base).
- **Costo de sanidad en la utilidad total del período** (Módulo 5): la
  fórmula del spec la incluye; `RentabilidadRepository.utilidadTotalPeriodo`
  hoy solo suma ingreso − concentrado − costo fijo por vaca, sin restar el
  costo de sanidad del período.
- **Pruebas automatizadas** de repositorios y del motor de sync (hoy solo
  hay un smoke test de widgets).
- **Assets de tienda** (ícono, capturas, política de privacidad) para
  publicar en App Store / Play Store.
- **Exportar/backup manual** de datos (no está en el spec v1, pero es una
  extensión natural del modo offline-first).
