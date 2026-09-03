# LecheControl Web

La versión de LecheControl para el navegador: el mismo producto que la app
instalada, servido en el celular y en la computadora.

- **En el navegador del celular** se ve *idéntica* a la app nativa. No parecida:
  es literalmente el mismo árbol de widgets.
- **En la computadora** mantiene los colores, el diseño y el logo, pero con
  barra lateral fija, barra superior y el módulo abierto al centro.

---

## La idea en una frase

**Este proyecto no tiene producto.** Tiene el `main.dart`, un adaptador que
elige distribución según el ancho, la carpeta de escritorio, los assets
copiados y `web/`. Todo lo demás —pantallas, repositorios, base local,
sincronización, tema, reglas de negocio— vive en `../LecheControlMovil` y entra
por dependencia de ruta:

```yaml
dependencies:
  leche_control:
    path: ../LecheControlMovil
```

Un arreglo en el paquete móvil sale en las tres versiones a la vez. Si en vez
de esto se hubiera copiado `lib/`, o reescrito en React, cada arreglo habría
que programarlo dos veces para siempre.

## Qué hay acá adentro

```
lib/
  main.dart                        arranque: bootstrap del móvil + MaterialApp
  adaptador/adaptador_leche.dart   la regla del corte (1000 px)
  escritorio/
    shell_escritorio.dart          el marco: lateral + superior + paneles
    barra_lateral.dart             logo, módulos, ajustes, cerrar sesión
    barra_superior.dart            dónde estoy + estado de sincronización
    modulos_escritorio.dart        tabla de rutas: qué pantalla abre cada módulo
    panel_modulo.dart              un Navigator por sección
    tablero_escritorio.dart        el «Inicio» de la computadora
assets/                            copiados del móvil (ver scripts/)
web/                               index.html, sqlite3.wasm, drift_worker.js
scripts/sincronizar_web_assets.sh  resincroniza assets y wasm
```

Eso es todo. Si alguna vez hace falta escribir aquí una regla de negocio, una
validación, un cálculo o una pantalla, **va en el paquete móvil**, no acá.

---

## Cómo se decide entre celular y computadora

El corte está en **1000 px** de ancho (`kCorteEscritorio`).

Lo importante es *dónde* se aplica. La decisión **no** envuelve la app entera:
se pasa como `construirHome` a `AuthGate`, del paquete móvil, así que corre
**después** de resolver sesión → cuenta → lechería.

```
AuthGate ─┬─ sin sesión ────────────► LoginScreen        (siempre la del móvil)
          └─ con sesión ─► CuentaGate ─┬─ suspendida ───► SuspendidaScreen
                                       ├─ prueba vencida► SuscripcionScreen
                                       ├─ sin lechería ─► crear lechería
                                       └─ todo bien ────► construirHome(...)
                                                             │
                                              ┌──────────────┴──────────────┐
                                         < 1000 px                     ≥ 1000 px
                                         HomeScreen                ShellEscritorio
```

Dos consecuencias buscadas:

1. **El login y las pantallas de cuenta son siempre las del móvil**, sin marco.
   Ya vienen centradas y limitadas a 420 px, así que en un monitor se ven bien
   sin ayuda. Y sobre todo: la lógica de sesión, estado de la cuenta y licencia
   no se escribe dos veces.

2. **No se rearma el árbol al arrastrar la ventana.** Si el `LayoutBuilder`
   estuviera arriba del `AuthGate`, cada píxel de un arrastre reconstruiría los
   gates y volvería a suscribir los streams de cuenta y lechería.

### Por qué el celular queda exacto

Debajo del corte, `construirHomeSegunAncho` devuelve `HomeScreen` **sin
envolverlo en nada**: ni un padding, ni un tema, ni un widget intermedio. Es lo
único que garantiza que las dos versiones móviles sean idénticas y no apenas
parecidas.

---

## Un `Navigator` por sección

Cada módulo del escritorio se monta dentro de su propio `Navigator`
(`panel_modulo.dart`). Sin eso, las pantallas del teléfono —que navegan con
`Navigator.of(context).push(...)`— encontrarían el `Navigator` de la app y la
hoja de vida de una vaca se abriría **encima de todo**, tapando la barra
lateral.

De regalo, cada sección recuerda dónde iba: se puede dejar Inventario abierto en
una hoja de vida, irse a Finanzas y volver a Inventario a esa misma hoja.

Los paneles se montan **la primera vez que se visitan** y desde ahí quedan
vivos. Montar los ocho de entrada sería abrir ocho juegos de streams contra la
base local para mirar uno.

Un segundo clic en la sección donde ya se está vuelve a la raíz de esa sección.

### El aire alrededor del módulo

El panel no llega a los bordes: lleva un tope de ancho
(`kAnchoMaximoContenido`, 1120 px) y un margen a los lados
(`kMargenLateralPanel`). Las dos cosas, no una: en un monitor grande manda el
tope y sobra margen; en un portátil de 1280 el contenido llega al tope y sin el
margen quedaría pegado a la barra lateral y al borde derecho.

No es estética. Las pantallas son las del teléfono —listas, formularios y
tarjetas de una sola columna—, y estiradas a lo ancho de un monitor quedan como
renglones de punta a punta: el identificador de la vaca a la izquierda y el
menú de tres puntos a medio metro, a la derecha.

El tope va **por fuera** del `Navigator`, no adentro, para que también lo
respeten las pantallas hijas: si no, se entraría a un módulo con su aire y la
pantalla siguiente saltaría de punta a punta.

Las esquinas de arriba van redondeadas porque los módulos traen su propia
`AppBar` oscura: sin eso, esa franja queda cortada a escuadra contra la barra
superior y se lee como un desalineo en vez de como un módulo apoyado sobre el
marco. Abajo no hace falta — el fondo del panel y el de la pantalla son el
mismo crema.

El tablero de Inicio no pone ancho ni margen propios: se los da este mismo
panel, y por eso el tablero y las listas de Inventario arrancan en la misma
línea.

---

## El «Inicio» de la computadora

Los ocho módulos abren **la misma pantalla del teléfono**. El único que no es
`Inicio`, y conviene explicar por qué.

En el teléfono, `HomeScreen` son tres cosas apiladas: el conteo del hato, el
gráfico semanal y una grilla de seis tarjetas. Esa grilla es ahí **el único
camino a los módulos**. En la computadora ese camino es la barra lateral, que
está siempre a la vista, así que repetirla salía caro dos veces:

1. La grilla tiene dos columnas y proporción fijas. Estirada a 1200 px, cada
   tarjeta mide más de 500 px y hay que bajar para ver las últimas dos. Para
   que se vieran bien había que angostar el panel a ancho de celular — y
   entonces el gráfico, que es justo lo que gana con un monitor, quedaba del
   tamaño de un teléfono.
2. `HomeScreen` trae su propia `AppBar` con el nombre de la lechería, el
   estado del sync, Ajustes y Cerrar sesión: exactamente lo que ya están
   diciendo la barra superior y el pie de la barra lateral. Dos franjas
   pegadas repitiéndose.

Así que `Inicio` en la computadora es `TableroEscritorio`: **los mismos dos
widgets del paquete móvil** —`ResumenHato` y `ProduccionSemanal`— usando el
ancho, sin la grilla y sin `AppBar`.

Los dos widgets se extrajeron de `HomeScreen` a
`lib/home/widgets/` del paquete móvil justamente para esto. El teléfono los
sigue usando en el mismo lugar y con los mismos datos; el dato, el orden de los
grupos, los colores y a dónde lleva tocar el gráfico se deciden **una sola
vez**, allá. El tablero solo los acomoda.

Lo único que el tablero cambia es el alto del gráfico: `LineaProduccion` acepta
`altoGrafico`, que en el teléfono vale 104 px (lo que sobra arriba de las
tarjetas) y acá 320. En 104 px repartidos en un monitor no se distingue una
semana buena de una mala.

---

## Siempre en modo claro

La web va **siempre en claro**, aunque la computadora o el celular estén en
modo oscuro (`themeMode: ThemeMode.light` en `main.dart`, y el fondo de
`index.html` sin variante para `prefers-color-scheme: dark`).

Es una decisión del producto, no un descuido. Vale la pena saber que **la app
instalada no se comporta así**: `app_bootstrap.dart` usa `ThemeMode.system`, o
sea que en un teléfono puesto en oscuro la nativa se ve oscura. El tema
`LecheTheme.dark` sigue existiendo en el paquete móvil y no se tocó; acá
simplemente no se usa.

Para devolverle el modo oscuro a la web alcanza con volver a poner
`darkTheme: LecheTheme.dark` y `themeMode: ThemeMode.system` en `main.dart`, y
la variante oscura del fondo en `index.html`. El resto ya está listo: la barra
lateral monta el logo sobre un disco claro cuando el tema es oscuro, porque el
PNG es azul marino y contra un fondo negro no se lee.

---

## La base local en el navegador

En el navegador no hay SQLite nativo: drift usa **SQLite compilado a
WebAssembly** más un worker. Los dos archivos están en `web/`:

| archivo | de dónde sale | versión |
|---|---|---|
| `sqlite3.wasm` | releases de `sqlite3.dart` | la del `pubspec.lock` del móvil |
| `drift_worker.js` | releases de `drift` | la del `pubspec.lock` del móvil |

**Tienen que ser las versiones exactas del lock.** Una versión distinta no
falla al compilar: falla en el navegador, al abrir la base. Para resincronizar
después de subir `drift` o `sqlite3`:

```bash
./scripts/sincronizar_web_assets.sh
```

El script lee las versiones del `pubspec.lock` del móvil, las baja y comprueba
que el `.wasm` empiece con el número mágico de WebAssembly (si el release no
existe, GitHub devuelve una página HTML con código 200).

Quién le pasa esas rutas a drift es `_abrirConexion()` en
`../LecheControlMovil/lib/data/local/database.dart`, con `DriftWebOptions`. Vive
en el paquete móvil a propósito: **en Android e iOS esas opciones se ignoran**,
así que no cuestan nada en el teléfono y así el proyecto web no necesita saber
nada de drift.

### Qué implementación termina usando

En el arranque se ve en la consola algo como:

```
Using WasmStorageImplementation.sharedIndexedDb due to missing browser features:
  {MissingBrowserFeature.dedicatedWorkersInSharedWorkers,
   MissingBrowserFeature.sharedArrayBuffers}
```

Es **informativo, no un error**. `sharedIndexedDb` guarda de verdad y sobrevive
al cierre del navegador. La alternativa más rápida (OPFS) necesita
`SharedArrayBuffer`, que exige las cabeceras `COOP`/`COEP`; ponerlas
complicaría las llamadas a Supabase, y no vale la pena por un cambio de
velocidad que en este volumen de datos no se nota.

---

## Los assets

Flutter solo encuentra `Image.asset('assets/...')` en el paquete que corre, no
en sus dependencias de ruta. Por eso los PNG están **copiados** en este
proyecto.

Van declarados en `pubspec.yaml` **uno por uno, no como carpeta**: una carpeta
completa mete en el bundle imágenes que la app nunca abre. Son los mismos
cuatro que declara el móvil, y los cuatro se usan.

El script de sincronización avisa si quedó un archivo en `assets/` que ya nadie
declara.

### El logo sobre fondo oscuro

El PNG es transparente y el dibujo es azul marino y verde, así que sobre una
superficie oscura se hunde contra el fondo. Donde eso puede pasar va sobre un
disco claro —disco y no cuadro, porque el borde recto se lee como una caja
pegada encima—: el login del móvil, y la barra lateral del escritorio si
alguna vez se le devuelve el tema oscuro a la web.

En el splash de `index.html` no lleva placa, porque ahí el fondo es siempre el
crema claro.

---

## `web/index.html`

Dos cosas que no son decorativas:

- **`body` clavado al viewport, con `overflow: hidden`.** Sin esto la página
  mide más que la pantalla visible y el navegador del celular esconde y muestra
  su barra de direcciones al arrastrar: la app *brinca* en medio de una pesa.
  Todo el desplazamiento tiene que quedar adentro de Flutter, que es donde las
  listas ya saben scrollear. `overscroll-behavior: none` mata además el
  "recargar arrastrando" de Android, que en medio de un formulario borra lo
  escrito.

- **La etiqueta `viewport`.** Sin ella el navegador del celular supone una
  página de escritorio de ~980 px y la app cruzaría el corte de 1000 px por
  poco. Flutter la reemplaza por la suya al arrancar —y lo dice en el log, no
  es un error—, pero hace falta igual para que el splash mida bien antes de que
  el motor cargue.

---

## Sin modo sin conexión (a propósito)

La web no promete funcionar sin internet. La base local igual guarda en el
navegador y la sincronización sigue siendo automática —es el mismo código del
teléfono—, pero no está pensada ni probada como cliente offline. Para trabajar
en el potrero sin señal, la app instalada.

---

## Comandos

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter build web
```

Para ver el escritorio con datos, sin necesitar una cuenta de Supabase:

```bash
flutter run -d chrome --dart-define=LECHE_DEMO=true --dart-define=LECHE_DB_NAME=demoweb
```

`LECHE_DB_NAME` aísla la base de demostración de la del uso diario.

**Antes de dar por buena cualquier cosa que toque `lib/` del móvil**, este
proyecto tiene que compilar:

```bash
cd ../LecheControlWeb && flutter build web
```

Es la única forma de descubrir que se coló un `dart:io`, porque en el teléfono
no se nota.

---

## El repositorio

Los dos proyectos van en **un solo repositorio**:

```
LecheControl/
├── vercel.json
├── LecheControlMovil/     ← el producto
└── LecheControlWeb/       ← este proyecto
```

Si se separan, quien clone el repo web no encuentra `../LecheControlMovil` y no
compila nada. Vercel incluido.

## Vercel

El `vercel.json` está en la **raíz del repositorio**, no en esta carpeta, y en
la configuración del proyecto el **Root Directory tiene que quedar vacío**: el
build necesita ver `LecheControlMovil/` para resolver la dependencia de ruta.

La versión de Flutter está fijada en el `installCommand` (**3.44.1**, la misma
con la que se desarrolló). Al subir la versión de Flutter en la máquina, hay
que subirla también ahí.
