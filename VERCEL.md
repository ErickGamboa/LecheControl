# Publicar LecheControl Web en Vercel

La configuración vive en `vercel.json`, en la raíz del repo, para que quede
versionada y no dependa de clics en el panel.

## Qué se publica

El dominio tiene dos cosas: el sitio público y la app.

| URL           | Qué es                                          |
| ------------- | ----------------------------------------------- |
| `/`           | Portada de LecheControl (HTML estático)         |
| `/privacidad` | Política de privacidad                          |
| `/soporte`    | Soporte y preguntas frecuentes                  |
| `/app/`       | La app Flutter: el login y todo lo demás        |

**Las dos páginas legales son HTML plano a propósito.** App Store y Google
Play piden un enlace público a la política de privacidad y otro a soporte, y
el revisor (o el robot que las revisa) tiene que poder leerlas sin esperar a
que baje un bundle de Flutter de varios megas. Por eso también la portada es
estática: lo que se comparte y lo que indexa Google abre al instante.

Las tres páginas se editan en `LecheControlWeb/sitio/`. Si cambia la política
de privacidad, se cambia ahí y se actualiza la fecha de arriba.

> **La app se movió de `/` a `/app/`.** Antes el dominio servía la app en la
> raíz. Quien tenga guardado el enlace viejo cae ahora en la portada, que
> tiene el botón «Entrar» bien visible arriba y abajo, así que no queda a pie
> — pero si ese enlace está pegado en algún lado, conviene actualizarlo.

## Cómo conectarlo (una sola vez)

1. En Vercel: **Add New → Project** y elegir el repo `LecheControl`.
2. **Root Directory: la raíz del repo** (dejarlo vacío). No poner
   `LecheControlWeb`: la app web depende del paquete de la app móvil por ruta
   relativa (`../LecheControlMovil`), así que el build necesita ver las dos
   carpetas.
3. Framework Preset: **Other**.
4. Los comandos los toma de `vercel.json`; no hay que escribirlos a mano.
5. Deploy.

Que el proyecto de Android e iOS esté en el mismo repo no afecta nada: Vercel
solo publica lo que quede en `LecheControlWeb/build/sitio`.

## Qué hace el build

Vercel no trae Flutter instalado, así que el paso de instalación lo baja:

```
installCommand:  clona Flutter 3.44.1 en _flutter/ + precache web + pub get
buildCommand:    bash LecheControlWeb/scripts/construir_sitio.sh
outputDirectory: LecheControlWeb/build/sitio
```

El script compila la app con `--base-href /app/` y arma la carpeta que se
publica: el sitio estático en la raíz y `build/web` colgado de `app/`.

Por eso cada deploy tarda unos **3 a 5 minutos** en vez de segundos: se baja
el SDK de Flutter cada vez. Es el precio de no tener Flutter nativo en la
plataforma.

**La versión de Flutter está fijada a propósito** (`-b 3.44.1`, la misma con
la que se desarrolla). Si se usara `stable`, una liberación de Flutter podría
romper el deploy de producción un martes cualquiera sin que nadie tocara el
código. Al subir la versión local, actualizar también ese número en
`vercel.json`.

## Verlo en la computadora antes de subirlo

```bash
bash LecheControlWeb/scripts/construir_sitio.sh
```

Queda todo en `LecheControlWeb/build/sitio`. Cualquier servidor estático sobre
esa carpeta sirve para mirarlo, **pero ojo**: sin Vercel las URL sin `.html`
(`/privacidad`, `/soporte`) no resuelven solas, porque es `cleanUrls` el que
las arregla. Si el servidor que uses no lo hace, abrí `privacidad.html`
directo o usá uno que soporte esa reescritura.

## Alternativa: compilar acá y subir el resultado

Si esos minutos estorban:

```bash
bash LecheControlWeb/scripts/construir_sitio.sh
vercel deploy --prebuilt   # o subir build/sitio como sitio estático
```

Deploy en segundos, pero se pierde el automático al hacer `git push`.

## Notas

- `cleanUrls` es lo que hace que `/privacidad` funcione sin el `.html`. Esas
  URL son las que van en la ficha de App Store y Google Play, así que no
  conviene cambiarlas después de haberlas enviado a revisión.
- El `rewrites` a `/app/index.html` es para que cualquier URL dentro de
  `/app/` cargue la app. Hoy la app no usa rutas en la barra de direcciones,
  pero si algún día se agregan enlaces profundos, ya está listo. Los archivos
  que sí existen (el bundle, los assets, `sqlite3.wasm`, `drift_worker.js`) se
  sirven directo: en Vercel los rewrites corren después de buscar en el disco.
- Las imágenes del sitio salen de `LecheControlWeb/assets/`, que
  `scripts/sincronizar_web_assets.sh` mantiene igual a las del móvil. Si se
  cambia un PNG en el móvil, correr ese script antes de publicar.
- La clave `anon` de Supabase va embebida en el bundle y eso es correcto: es
  pública por diseño y la seguridad real la dan las políticas RLS. La clave
  `service_role` nunca debe llegar acá.
