# LecheControl — Especificación funcional (cómo debe funcionar la app)

> **Para:** Desarrollo
> **De:** Erick
> **Propósito:** Este documento describe **cómo debe comportarse la aplicación**, no cómo está hoy. La idea es orientar el desarrollo hacia esta visión. Es una app para un **ganadero de lechería**: sencilla, **mucho de tocar y poco de escribir**, El objetivo del cliente es **ordenar su lechería, recolectar datos, hacer cálculos y tomar decisiones** (qué vacas son las más rentables, cuáles secar, cuánto gana al mes) teniendo la información a mano.

---

## Principios generales (aplican a toda la app)

- **Offline primero:** la app **funciona completamente sin internet**. Todo se registra, se consulta y se calcula localmente en el dispositivo, aunque no haya señal en el campo. La conexión **nunca es requisito** para trabajar.
- **Sincronización automática con la nube:** cuando el dispositivo **agarra internet**, la app **sube y vincula todos los datos a la nube (Supabase)** sola, en segundo plano, sin que el usuario tenga que hacer nada. Si hay varios cambios acumulados sin señal, se sincronizan todos al reconectar. (Ver Módulo 8 — Sincronización.)
- **Poco teclado:** toques y valores por defecto. Escribir solo lo mínimo (litros, precios, kg).
- **Un solo usuario operativo:** el ganadero mete toda la información. **No hay auto-registro**; las cuentas las crea el administrador (Erick) y se las entrega. (Ver Módulo 0.)
- **Una lechería activa:** todos los módulos operan sobre la lechería de la cuenta. (Por ahora una lechería por cuenta.)
- **Identificador único por animal:** un solo número por animal. Puede llegar por el **lector RFID** o **escribirse manualmente** en el mismo campo (es el mismo dato). No manejamos número visual aparte por ahora.
- **Nada se borra:** el animal que se vende, muere o se descarta no se elimina; pasa a **historial** (trazabilidad).
- **Todo alimenta la Hoja de Vida:** cada acción (pesa de leche, sanidad, palpación, preñez, secado, parto, cambio de grupo, baja) queda registrada en la hoja de vida del animal con su fecha.
- **Estados del hato:** cada animal vive en un **grupo por estado** (En ordeño, Secas, Novillas/Vaquillas, Terneros, En tratamiento). El estado se usa para filtrar y para **repartir costos** (los costos fijos se dividen entre las vacas en ordeño).

---

## Módulo 0 — Acceso (Login)

- **Login con Supabase Auth** (correo + contraseña).
- **Sin auto-registro:** el administrador crea la cuenta y entrega las credenciales al ganadero.
- **Sesión persistente y offline:** el **primer login requiere internet** (una sola vez). Después la sesión queda guardada y la app **abre y funciona sin señal**; no se pide login cada vez ni se necesita internet para entrar.
- Al iniciar sesión se entra directo al home page con todos los modulos.

---

## Módulo 1 — Pantalla de Trabajo  ⭐ pantalla principal

Es **la** pantalla donde el ganadero trabaja frente al animal. Sirve para **identificar un animal y registrarle eventos**, y para **entrar a su hoja de vida**.

### Identificar al animal
1. **Identificador:** se captura con el **lector RFID** o se escribe manualmente (mismo campo).
2. **Si el animal ya existe:** muestra una **tarjeta** con su **estado actual** (grupo, estado reproductivo, última producción de leche, si está **en retiro de leche**) y **botones grandes** para registrarle eventos. Un toque en la tarjeta abre su **Hoja de Vida**.
3. **Si el animal es nuevo:** ofrece **registrarlo de una vez** en inventario, pidiendo lo mínimo (ver abajo).

### Registrar un animal nuevo (alta en inventario)
Se pide solo lo mínimo, la mayoría por toque:
- **Identificador** (RFID o manual).
- **Sexo** (Hembra / Macho).
- **Grupo/estado** al que entra (En ordeño, Secas, Novillas, Terneros).
- **Origen:**
  - **Comprado** → **precio de compra** y **fecha**.
  - **Nacido en la finca** → sin precio de compra (o costo aparte si se define después); si viene de un parto registrado, queda **vinculado a su madre**.

### Eventos que se registran por animal (botones grandes)
Cada evento queda en la **hoja de vida** con su fecha. Eventos disponibles:

- **Sanidad** 🚑 — aplicar uno o varios medicamentos al animal. Registra: medicamento, dosis, **días de retiro (leche)** y **costo**. Al aplicar un medicamento con retiro, el animal queda **"en retiro de leche"** hasta una fecha calculada (fecha aplicación + días de retiro): durante ese tiempo **su leche no se cuenta como ingreso** (leche de descarte). *(Ver Módulo 7 — Sanidad.)*
- **Celo / Monta / Inseminación** — fecha del servicio y, si aplica, **toro / pajilla** usada.
- **Palpación / Diagnóstico** — resultado **Preñada / Vacía** (con fecha probable de parto si está preñada), o resultado de ultrasonido.
- **Secado** — marca la vaca como **seca** (deja de ordeñarse) y la pasa al grupo **Secas** con su fecha.
- **Parto** — registra el parto, el **sexo de la cría** y **crea el ternero** como animal nuevo vinculado a la madre. La vaca vuelve al grupo **En ordeño**.
- **Cambiar de grupo/estado** — mover el animal entre grupos (queda la fecha del cambio).

> **Nota:** la captura de la **producción de leche** no se hace aquí una a una, sino en el **Módulo 3 — Pesa de leche** (flujo optimizado para pesar todo el hato de corrido). Desde la Pantalla de Trabajo siempre se puede consultar la última producción del animal.

---

## Módulo 2 — Inventario de animales

- **Lista de todos los animales** con **buscador** y **filtro por grupo/estado**.
- Columnas sugeridas: **Animal | Grupo | Estado reproductivo | Última producción (L)**.
- **Alta de animal** con el mismo mínimo que en la Pantalla de Trabajo.
- **Tocar un animal** → abre su **Hoja de Vida**.
- **Cambiar de grupo/estado** desde la lista (queda en la hoja de vida con fecha).
- **Bajas:** un animal puede salir por **venta**, **muerte** o **descarte**. No se borra: **deja de aparecer** en inventario y pesas, pero **queda en Historial** con el motivo y la fecha.

---

## Módulo 3 — Pesa de leche (semanal)

Una vez por semana el ganadero **pesa la leche** de las vacas en ordeño para sacar conclusiones. Es un flujo rápido, animal por animal.

### Registrar una pesa
1. Se abre una **sesión de pesa** con su **fecha**. La sesión es **de la semana**, no del día: si se entra otro día de esa misma semana se **sigue la misma pesa**, no se arranca una vacía. Para hacer una segunda pesa en la semana hay que **cerrar** la abierta.
2. Por cada vaca en ordeño se **elige la vaca de una lista con buscador** —que solo muestra las que faltan por pesar, y se va vaciando sola— y se digita:
   - **Litros de la mañana** y **litros de la tarde** (el total del día lo suma la app).
   - **Kilos de concentrado** que comió ese día.
   Basta con anotar un solo ordeño si la vaca se ordeña una vez.
3. **Contador visible:** vacas pesadas y **faltantes** (respecto al grupo En ordeño).
4. Si una vaca **ya se pesó en esta sesión** y se vuelve a elegir: mostrar el registro y **preguntar si se corrige** (no duplicar).
5. **Vacas manuales:** una vaca que no está en el inventario se puede pesar igual, con su identificador suelto. Se le anota la leche pero **no tiene días de lactancia** ni comparación contra la curva, y **no cuenta** contra el total de vacas por pesar. En los listados sale marcada con asterisco.

### Historial de pesas
Desde la pesa se llega al **historial**: todas las semanas pesadas, con vacas, litros y promedio, y desde ahí se abre el **reporte** de cualquiera. Sin esto el trabajo de la semana anterior quedaba guardado pero sin forma de consultarlo.

### Días de lactancia (DLac)
Los días desde el **último parto** de la vaca. La app los lleva sola: el evento de parto reinicia la cuenta. Para las vacas que ya estaban en la finca antes de usar la app, la fecha del último parto se puede **cargar a mano una sola vez**. Una vaca sin esa fecha aparece sin DLac y no se compara contra la curva.

### Reporte de producción
Al cerrar la pesa se arma el **reporte general de producción lechera**:

- **Producción por vaca:** identificador, DLac, mañana, tarde, total, concentrado, total de la pesa anterior y estado.
- **Resumen del hato:** vacas registradas, en producción, secas o prontas, manuales; producción total, promedio general y promedio de las vacas en producción.
- **Curva de lactancia:** el promedio real del hato por tramo de días en leche, contra la curva de referencia.
- **Mejores vacas** y **vacas por debajo de lo esperado**, con su `% del esperado`.
- **Top 5 mayor y menor producción**, **distribución por rango** (Alta > 18 L, Media 12-18 L, Baja 8-12 L, Muy baja < 8 L) y **estado reproductivo**.
- **Recomendaciones:** Mantener / Vigilar / Revisar, según el `% del esperado`.

### Curva de referencia (litros esperados según DLac)
Una tabla de **siete tramos editables** por lechería, precargada con `0-30 → 18.8`, `31-70 → 26`, `71-120 → 24`, `121-180 → 21`, `181-240 → 18`, `241-305 → 14`, `>305 → 10`.

Para una vaca concreta el esperado **no es el escalón del tramo**: la app **interpola** entre el día central de cada tramo, para que la curva suba y baje suave y una vaca no salte de "Excelente" a "Muy bajo" por cumplir un día más.

`% del esperado = producción del día ÷ litros esperados para sus DLac`. Los umbrales de calificación (por defecto: ≥100 % Excelente, 85-99 % Bueno, 70-84 % Vigilar, 60-69 % Bajo, <60 % Muy bajo) también son editables.

A los ~3 meses de pesas la app muestra el **promedio real del hato** por tramo junto a la tabla y ofrece **adoptarlo**, tramo por tramo. Así la referencia deja de ser un valor genérico y pasa a ser el de esa finca.

### Al terminar la pesa — Resumen
- **Total de vacas** pesadas.
- **Producción total (L)**, **Promedio/vaca (L)**, **Máximo (L)**, **Mínimo (L)**.
- **Variación** respecto a la pesa anterior.

### Comportamiento por vaca (histórico)
- Por cada vaca se guarda la **serie de pesas** en el tiempo (una columna por fecha).
- La app calcula por vaca: **Promedio**, **Tendencia** (subiendo / estable / bajando) y **Diferencia** contra la pesa anterior.
- Todo alimenta la **Hoja de Vida** y el **reporte de producción**.

---

## Módulo 4 — Finanzas (semanal)

Una sola pantalla. El período es la **semana, de lunes a domingo**.

### Ingresos — se digitan, no se calculan
Cada semana el ganadero anota **la plata que efectivamente entró**:

- **Leche:** el monto que pagó la planta y, junto a él, **los litros que pagó**.
- **Venta de ganado:** el monto y, si aplica, qué animal se vendió (queda en su hoja de vida).
- **Otro.**

> Esto reemplaza la decisión vieja de calcular el ingreso como `litros × precio`. Ya no se digita un precio del litro: **sale de dividir lo que pagaron entre los litros que pagaron**, así que es el precio real de esa semana.

### Gastos
Se anota cada salida con su **categoría** (salario del peón, concentrado, medicamentos, cerca, combustible, transporte…). Las categorías son botones; si el ganadero escribe una nueva, queda guardada para la próxima.

### Utilidad de la semana
`Σ ingresos − Σ gastos`. Puede ser negativa, y se muestra igual.

---

## Módulo 8 — Análisis

El resto de la app trabaja sobre **la semana en curso**: se pesa esta semana, se anotan los gastos de esta semana. Análisis abre **todas las semanas juntas**, que es lo que hace falta para saber si la finca va bien o mal. Se elige qué mirar:

### Leche
Todas las pesas, semana por semana: **vacas, litros y promedio**, con un gráfico de litros por semana y cuánto **subió o bajó** contra la semana anterior. Tocando una semana se abre su **reporte de producción**.

Las sesiones sin ninguna vaca pesada no se listan: son las que la app abre sola al entrar a la pantalla de pesa, y contarlas torcería los promedios.

### Finanzas
**Ingresos, gastos y utilidad de todas las semanas**, con el acumulado, el promedio semanal y el precio real por litro de cada una. Las semanas con pérdida salen en rojo, también en el gráfico.

Igual que en leche, una semana sin ingresos ni gastos no cuenta.

---

## Módulo 6 — Hoja de Vida del animal

Módulo para **consultar la hoja de vida** de cualquier animal (además del acceso directo tocándolo en inventario o en la Pantalla de Trabajo).

Muestra, ordenado por fecha, todo lo del animal:
- **Pesas de leche** (litros por fecha, con tendencia y diferencia).
- **Eventos reproductivos:** celo/monta/inseminación, palpación/diagnóstico, preñez, secado, parto.
- **Sanidad:** medicamento, dosis, fecha, **retiro de leche** (hasta cuándo).
- **Cambios de grupo/estado** (fechas).
- **Genealogía** (si nació en la finca: madre; y sus crías si es hembra que ha parido).
- **Estado actual:** grupo, estado reproductivo, última producción, concentrado actual, si está **en retiro de leche** (y hasta cuándo).
- **Baja** (cuando aplique): motivo (venta/muerte/descarte), fecha y, si es venta, precio.

---

## Módulo 7 — Sanidad

El usuario registra **una vez** los medicamentos que usa y tiene en la finca; luego aparecen para aplicarlos rápido desde la Pantalla de Trabajo.

Cada medicamento tiene:
- **Nombre** (ej.: Oxitetraciclina).
- **Costo del envase** y **rendimiento del envase** (ml del envase, o número de aplicaciones que rinde).
- **Días de retiro (leche)** — cuántos días la leche no se puede vender tras aplicarlo.
- **Tipo / dosis** — **fija** (ej. 5 ml siempre) o **por aplicación** (ej. spray = 1 aplicación). **No se dosifica por peso corporal**, así que **no se captura el peso de la vaca**.

**Costo por uso (suma a los costos del período):**
- Líquidos (dosis fija): `costo del envase ÷ ml del envase × ml aplicados`.
- Por aplicación: `costo del envase ÷ aplicaciones que rinde`.

---

## Módulo 8 — Sincronización con la nube (offline-first)

Este comportamiento es **transversal**: aplica a todos los módulos. El ganadero trabaja en el campo, muchas veces **sin señal**, y la app tiene que responder igual de rápido esté o no conectada.

### Cómo debe comportarse
- **Todo se guarda primero en el dispositivo (local).** Cada registro (alta de animal, pesa de leche, evento de sanidad/reproducción, gasto, etc.) se escribe de una vez en el almacenamiento local y queda disponible al instante, **haya o no internet**.
- **Trabajo 100% offline:** el ganadero puede pasar todo el día registrando sin señal. Nada lo bloquea por falta de conexión.
- **Sincronización automática al reconectar:** cuando el dispositivo **detecta internet**, la app **sube sola** todos los cambios pendientes a **Supabase** (la nube) y **baja** cualquier cambio nuevo, en **segundo plano**. El usuario **no tiene que apretar "sincronizar"**.
- **En lote:** si se acumularon muchos registros sin señal, al reconectar se **envían todos** de corrido y quedan **vinculados en la nube**.
- **Indicador de estado:** la app muestra de forma sencilla si hay **cambios pendientes de subir** o si ya está **todo sincronizado** (ej. un ícono/nube). Sin tecnicismos.
- **Respaldo en la nube:** una vez sincronizado, los datos quedan **respaldados en Supabase**; si se pierde o cambia el dispositivo, al iniciar sesión se **recuperan** todos los datos.

### Reglas para no perder ni duplicar datos
- **La nube nunca pisa datos locales sin sincronizar:** primero se suben los cambios locales pendientes y luego se baja lo de la nube.
- **Sin duplicados:** cada registro tiene un **identificador único** propio, así que reenviar por reintentos no crea copias.
- **Marca de tiempo:** todo registro guarda **cuándo se creó/editó** (fecha y hora), para ordenar correctamente y resolver conflictos si el mismo dato se tocó en dos lados.

> **Supuesto técnico (a validar con desarrollo):** el detalle de *cómo* se implementa el almacenamiento local y la cola de sincronización lo define el equipo de desarrollo. Este documento solo fija **el comportamiento esperado**: funcionar sin internet y sincronizar solo al reconectar.

---

## Módulo 9 — Alertas reproductivas y de manejo

La app **avisa sola** de las cosas que el ganadero no debe dejar pasar, para que la reproducción y el manejo no se le vayan de las manos. Las alertas se calculan a partir de los eventos ya registrados (Módulo 1) y salen en una **lista sencilla** (y opcionalmente un contador/badge en el home).

Alertas que debe generar:
- **Celo esperado:** vaca con celo/servicio previo cuya fecha de próximo celo se aproxima (para estar pendiente).
- **Confirmar preñez:** vaca inseminada/montada que ya cumple el tiempo para **palpar** y no tiene diagnóstico aún.
- **Vaca vacía hace mucho:** vaca que lleva demasiado tiempo **sin preñarse** (días abiertos altos) → candidata a revisar o descartar.
- **Próxima a secar:** vaca preñada que se acerca a la fecha de **secado** recomendada (antes del parto).
- **Próxima a parir:** vaca preñada cerca de su **fecha probable de parto**.
- **Fin de retiro de leche:** vaca cuyo **retiro** está por vencer o venció (su leche ya se puede vender de nuevo).

> Los **umbrales de días** (cuándo salta cada alerta) son **configurables** con valores por defecto sensatos. La app **avisa**; la acción la decide el ganadero (un toque lo lleva al animal para registrar el evento).

---

## Resumen de cálculos clave (para no dejar ambigüedad)

| Cálculo | Fórmula |
|---|---|
| **Ingreso por vaca/día** | litros/día × precio del litro de leche · *(si la vaca está **en retiro**, su leche se descarta → ingreso = 0)* |
| **Costo concentrado por vaca/día** | kg concentrado/día × precio concentrado/kg |
| **Costo fijo por vaca/día** | costos fijos del día ÷ número de vacas en ordeño |
| **Costo total por vaca/día** | costo concentrado/día + costo fijo/vaca |
| **Utilidad por vaca/día** | ingreso/día − costo total/día |
| **Promedio de producción de una vaca** | Σ litros de sus pesas ÷ número de pesas |
| **Tendencia** | comparación de la última pesa contra el promedio / pesa anterior (sube, estable, baja) |
| **Diferencia entre pesas** | litros pesa actual − litros pesa anterior |
| **Fecha fin de retiro de leche** | fecha de aplicación + días de retiro |
| **Costo por uso (líquido)** | costo del envase ÷ ml del envase × ml aplicados |
| **Costo por uso (por aplicación)** | costo del envase ÷ aplicaciones que rinde |
| **Candidata a secar** | litros/día < umbral configurable  **o**  utilidad/día < 0 |
| **Utilidad del período (negocio)** | Σ ingresos − (costos fijos + costo concentrado + costo sanidad) |

---

## Decisiones confirmadas (aterrizadas con el cliente)

Estas decisiones ya están tomadas y se reflejan en los módulos de arriba:

1. **Precio de la leche:** **único por período** (un solo precio del litro para todo el hato en el mes). *(No se maneja precio por comprador/planta por ahora.)*
2. **Ingresos:** **solo calculados** (`litros × precio`). No se registran facturas ni pagos reales de la planta. *(Se puede agregar más adelante si hace falta cuadrar.)*
3. **Retiro de leche:** durante el retiro, la leche de esa vaca **se descarta y NO cuenta como ingreso**. *(La vaca se puede seguir pesando, pero esos litros no suman a la utilidad.)*
4. **Sanidad — dosis:** **fija o por aplicación**. **No** se calcula dosis por peso corporal; por lo tanto **no** se captura peso del cuerpo de la vaca.
5. **Período de costos:** **mes calendario** (del 1 al fin de mes).
6. **Concentrado:** **kg/día por vaca, manual y editable**. La app **no** sugiere la cantidad; la digita el ganadero.
7. **Grupos/estados del hato:** **En ordeño, Secas, Novillas/Vaquillas, Terneros** y **En tratamiento** (vacas en retiro/tratamiento sanitario). *(Sin grupos libres ni grupo de toros por ahora.)*
8. **Alertas reproductivas:** **sí** se incluyen (ver Módulo 9). Ej.: vaca próxima a secar/parir, vaca vacía hace mucho, celo esperado, fin de retiro de leche.

### Pendiente por definir

- **Exportar/compartir reportes (Excel/PDF):** **no** entra en esta primera versión; los resúmenes se consultan dentro de la app. *(Queda como posible mejora futura.)*
