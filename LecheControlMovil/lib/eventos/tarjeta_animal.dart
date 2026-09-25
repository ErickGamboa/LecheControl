import 'package:flutter/material.dart';

import '../app/etiqueta_animal.dart';
import '../app/theme.dart';
import '../app/widgets/aviso_rapido.dart';
import '../app/widgets/campo_fecha_evento.dart';
import '../data/domain/grupos.dart';
import '../data/local/database.dart';
import '../hoja_vida/hoja_vida_screen.dart';
import '../sanidad/sanidad_aplicar_sheet.dart';
import '../services.dart';
import 'palpacion_dialog.dart';

/// La ficha del animal con los botones de evento: lo que se ve después de
/// identificarlo.
///
/// **Cada evento se anota con su propio día.** Todos los diálogos abren en hoy
/// —que es el caso de casi siempre, con la vaca al lado— y todos dejan
/// cambiarlo sin salirse. Es lo que hace que la app le sirva igual al que
/// anota en el corral y al que se sienta días después con la libreta del peón:
/// antes, ese segundo dejaba todo corrido los días que hubiera tardado en
/// digitar, y eso mueve los días de lactancia, la fecha probable de parto y el
/// próximo celo.
class TarjetaAnimal extends StatelessWidget {
  const TarjetaAnimal({
    super.key,
    required this.animal,
    required this.lecheriaId,
    required this.usuarioId,
    required this.onLimpiar,
    required this.onCambio,
  });

  final AnimalRow animal;
  final String lecheriaId;
  final String usuarioId;
  final VoidCallback onLimpiar;
  final VoidCallback onCambio;

  bool get _pronta => esPronta(
    animal.fechaProbableParto,
    estadoReproductivo: animal.estadoReproductivo,
  );

  /// Con qué día abre un diálogo: hoy, **con la hora**.
  ///
  /// La hora importa aunque no se muestre. Si no se toca nada, el evento queda
  /// con el momento exacto y dos eventos del mismo día conservan su orden en
  /// la hoja de vida. El calendario, en cambio, devuelve la medianoche del día
  /// escogido, que es lo correcto para una fecha vieja: de un apunte de papel
  /// nadie sabe la hora.
  DateTime get _fechaInicial => DateTime.now();

  /// La fila de la fecha, para meter arriba del contenido de un diálogo.
  Widget _filaFecha(
    DateTime fecha,
    ValueChanged<DateTime> alCambiar, {
    String etiqueta = 'Pasó',
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    // Ancho completo aunque el diálogo alinee su contenido a la izquierda:
    // la fila se lee como un renglón del formulario y se toca sin apuntar.
    child: SizedBox(
      width: double.infinity,
      child: CampoFechaEvento(
        fecha: fecha,
        etiqueta: etiqueta,
        onCambiar: alCambiar,
      ),
    ),
  );

  /// Para los eventos que se escogen de una lista y no tienen formulario —el
  /// celo y el cambio de grupo—: se abre uno chiquito con la fecha y nada más,
  /// para que también se les pueda decir de qué día son.
  ///
  /// Devuelve null si se canceló.
  Future<DateTime?> _dialogoSoloFecha(
    BuildContext context,
    String titulo,
  ) async {
    var fecha = _fechaInicial;
    final ok = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => StatefulBuilder(
        builder: (contextoDialogo, setState) => AlertDialog(
          title: Text(titulo),
          content: CampoFechaEvento(
            fecha: fecha,
            onCambiar: (d) => setState(() => fecha = d),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(contextoDialogo, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const ValueKey('evento.soloFecha.guardar'),
              onPressed: () => Navigator.pop(contextoDialogo, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    return ok == true ? fecha : null;
  }

  /// Anota un evento y **avisa en pantalla si quedó o no**.
  ///
  /// Todos los eventos de esta pantalla pasan por acá, y no cada uno con su
  /// `await` suelto, por dos razones:
  ///
  /// 1. El acuse es el mismo siempre. El ganadero aprende una sola cosa —check
  ///    verde quedó, equis roja no quedó— en vez de una por evento.
  /// 2. **Un fallo no puede pasar callado.** Antes, si el registro reventaba,
  ///    el diálogo ya se había cerrado y la pantalla se quedaba igual: se veía
  ///    idéntico a que hubiera funcionado. El evento no quedaba y nadie se
  ///    enteraba hasta buscar la vaca en la hoja de vida.
  ///
  /// [queQuedo] es lo que dice el check. Va como "Anotado: Parto" y no como
  /// "Parto anotado" por una razón boba pero real: los eventos son unos
  /// masculinos y otros femeninos —el celo, la monta, la inseminación—, y
  /// pegarle el participio al nombre daba "Monta anotado". Con el participio
  /// adelante concuerda siempre.
  ///
  /// Devuelve si el evento quedó anotado, para el que necesite seguir: la
  /// baja, por ejemplo, cierra la ficha, y no debe cerrarla si falló.
  Future<bool> _anotar(
    BuildContext context, {
    required String queQuedo,
    required Future<void> Function() registrar,
  }) async {
    try {
      await registrar();
      if (context.mounted) AvisoRapido.exito(context, queQuedo);
      return true;
    } catch (error, pila) {
      // El motivo real va a la consola para poder depurarlo; en pantalla va
      // en palabras del ganadero, que es quien lo lee.
      debugPrint('Trabajo: no se pudo anotar «$queQuedo»: $error\n$pila');
      if (context.mounted) {
        AvisoRapido.fallo(context, 'No quedó anotado. Volvé a intentar.');
      }
      return false;
    } finally {
      // Se refresca pase lo que pase: si falló, la ficha tiene que mostrar el
      // estado de verdad y no el que se esperaba.
      onCambio();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            key: const ValueKey('trabajo.animal.tarjeta'),
            color: kVerdeLeche.withValues(alpha: 0.08),
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => HojaVidaScreen(animalId: animal.id),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: kVerdeLeche,
                          child: Text(
                            animal.identificador.length >= 2
                                ? animal.identificador.substring(0, 2)
                                : animal.identificador,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                animal.identificador,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // El nombre con el que se le dice en la finca,
                              // debajo del arete y no en su lugar.
                              if (soloAlias(animal.alias) case final texto?)
                                Text(
                                  texto,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              Text(
                                '${GrupoAnimal.etiqueta(animal.grupo)} · '
                                '${EstadoReproductivo.etiqueta(animal.estadoReproductivo)}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: onLimpiar,
                          icon: const Icon(Icons.close),
                          tooltip: 'Buscar otro',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<double?>(
                      future: pesasRepo.ultimaProduccion(animal.id),
                      builder: (context, snapshot) {
                        final litros = snapshot.data;
                        return Text(
                          litros != null
                              ? 'Última producción: ${litros.toStringAsFixed(1)} L'
                              : 'Sin pesas registradas',
                          style: theme.textTheme.bodyMedium,
                        );
                      },
                    ),
                    // Que se vea de una que la vaca está por parir, sin tener
                    // que abrir la hoja de vida ni sacar la cuenta.
                    if (_pronta) ...[
                      const SizedBox(height: 8),
                      Container(
                        key: const ValueKey('trabajo.animal.pronta'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ImageIcon(
                              const AssetImage('assets/icono_parto.png'),
                              size: 16,
                              color: theme.colorScheme.onTertiaryContainer,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${etiquetaPronta(animal.fechaProbableParto)} '
                              '(${_fmtFecha(animal.fechaProbableParto!)})',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Registrar evento', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _GrillaEventos(
            botones: [
              _BotonEvento(
                icono: const Icon(Icons.medical_services_outlined),
                etiqueta: 'Sanidad',
                onTap: () async {
                  // La hoja de sanidad aplica ella misma los medicamentos y
                  // sabe si aplicó alguno: devuelve `true` solo cuando quedó
                  // algo anotado. Cerrarla sin aplicar nada no es un fallo, y
                  // no tiene que sacar ni check ni equis.
                  final aplicado = await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => SanidadAplicarSheet(
                      animalId: animal.id,
                      lecheriaId: lecheriaId,
                      usuarioId: usuarioId,
                    ),
                  );
                  onCambio();
                  if (aplicado == null || !context.mounted) return;
                  if (aplicado) {
                    AvisoRapido.exito(context, 'Anotado: Sanidad');
                  } else {
                    AvisoRapido.fallo(
                      context,
                      'No quedó anotado. Volvé a intentar.',
                    );
                  }
                },
              ),
              _BotonEvento(
                icono: const Icon(Icons.favorite_outline),
                etiqueta: 'Celo / Monta / Insem.',
                onTap: () => _servicioDialog(context),
              ),
              _BotonEvento(
                icono: const Icon(Icons.fact_check_outlined),
                etiqueta: 'Palpación',
                onTap: () => _palpacionDialog(context),
              ),
              if (animal.grupo == GrupoAnimal.enOrdeno)
                _BotonEvento(
                  icono: const Icon(Icons.pause_circle_outline),
                  etiqueta: 'Secado',
                  onTap: () => _secadoDialog(context),
                ),
              if (animal.estadoReproductivo == EstadoReproductivo.preniada)
                _BotonEvento(
                  icono: const ImageIcon(AssetImage('assets/icono_parto.png')),
                  etiqueta: 'Parto',
                  onTap: () => _partoDialog(context),
                ),
              _BotonEvento(
                icono: const Icon(Icons.sticky_note_2_outlined),
                etiqueta: 'Observación',
                onTap: () => _observacionDialog(context),
              ),
              _BotonEvento(
                icono: const Icon(Icons.swap_horiz),
                etiqueta: 'Cambiar de grupo',
                onTap: () => _cambiarGrupoDialog(context),
              ),
              _BotonEvento(
                icono: const Icon(Icons.remove_circle_outline),
                etiqueta: 'Dar de baja',
                onTap: () => _bajaDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtFecha(DateTime f) => '${f.day}/${f.month}/${f.year}';

  Future<void> _servicioDialog(BuildContext context) async {
    final tipo = await showDialog<String>(
      context: context,
      // Se cierra con el contexto del diálogo, no con el de la pantalla.
      // `showDialog` monta el diálogo en el Navigator raíz; cerrarlo con el
      // contexto de la pantalla saca la ruta del Navigator *más cercano*, que
      // en la versión de escritorio es el de la sección —y deja la sección sin
      // rutas, con la pantalla roja de "_history.isNotEmpty"—. En el teléfono
      // hay un solo Navigator y por eso funcionaba de casualidad.
      builder: (contextoDialogo) => SimpleDialog(
        title: const Text('Tipo de servicio'),
        children: [
          for (final t in [
            TipoEventoAnimal.celo,
            TipoEventoAnimal.monta,
            TipoEventoAnimal.inseminacion,
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(contextoDialogo, t),
              child: Text(TipoEventoAnimal.etiqueta(t)),
            ),
        ],
      ),
    );
    if (tipo == null || !context.mounted) return;

    // El celo se anota y ya: no hay toro ni pajilla que preguntar, porque no
    // hubo servicio. Preguntarlo era lo que hacía que el celo se sintiera un
    // servicio más, que es justo lo que no es.
    if (tipo == TipoEventoAnimal.celo) {
      // Con la vaca al lado se anota y ya. Pasando apuntes hace falta decirle
      // de qué día es, así que se abre un diálogo con la fecha y nada más.
      final cuando = await _dialogoSoloFecha(
        context,
        'Celo de ${animal.identificador}',
      );
      if (cuando == null || !context.mounted) return;
      await _anotar(
        context,
        queQuedo: 'Anotado: ${TipoEventoAnimal.etiqueta(tipo)}',
        registrar: () => eventosRepo.registrarServicio(
          animalId: animal.id,
          lecheriaId: lecheriaId,
          tipo: tipo,
          registradoPor: usuarioId,
          fecha: cuando,
        ),
      );
      return;
    }

    final esMonta = tipo == TipoEventoAnimal.monta;
    // En la monta el toro se escoge de los que hay en la finca; en la
    // inseminación se escribe la pajilla, que viene en la etiqueta.
    final disponibles = esMonta
        ? await animalesRepo.toros(lecheriaId)
        : const <AnimalRow>[];
    if (!context.mounted) return;

    final pajillaCtrl = TextEditingController();
    String? toroId;
    var cuando = _fechaInicial;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => StatefulBuilder(
        builder: (contextoDialogo, setState) => AlertDialog(
          title: Text(TipoEventoAnimal.etiqueta(tipo)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _filaFecha(cuando, (d) => setState(() => cuando = d)),
              esMonta
                  ? (disponibles.isEmpty
                        // Sin toros cargados la monta igual se anota: es peor
                        // perder el evento que perder con cuál fue.
                        ? const Text(
                            'Todavía no hay toros en el hato. La monta se anota '
                            'igual; para poder escoger el toro, primero hay que '
                            'darlo de alta en el grupo Toros.',
                          )
                        : DropdownButtonFormField<String>(
                            key: const ValueKey('trabajo.servicio.toro'),
                            initialValue: toroId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Toro (opcional)',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              for (final t in disponibles)
                                DropdownMenuItem(
                                  value: t.id,
                                  child: Text(t.identificador),
                                ),
                            ],
                            onChanged: (v) => setState(() => toroId = v),
                          ))
                  : TextField(
                      key: const ValueKey('trabajo.servicio.pajilla'),
                      controller: pajillaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Pajilla (opcional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(contextoDialogo, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(contextoDialogo, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (confirmado != true) return;
    if (!context.mounted) return;
    final pajilla = pajillaCtrl.text.trim();
    await _anotar(
      context,
      queQuedo: 'Anotado: ${TipoEventoAnimal.etiqueta(tipo)}',
      registrar: () => eventosRepo.registrarServicio(
        animalId: animal.id,
        lecheriaId: lecheriaId,
        tipo: tipo,
        toroId: esMonta ? toroId : null,
        // El nombre del toro se guarda también como texto: así la hoja de
        // vida y el PDF siguen leyéndose aunque el toro se dé de baja.
        toroPajilla: esMonta
            ? disponibles
                  .where((t) => t.id == toroId)
                  .map((t) => t.identificador)
                  .firstOrNull
            : (pajilla.isEmpty ? null : pajilla),
        registradoPor: usuarioId,
        fecha: cuando,
      ),
    );
  }

  Future<void> _palpacionDialog(BuildContext context) async {
    final quedo = await mostrarPalpacionDialog(
      context,
      animalId: animal.id,
      lecheriaId: lecheriaId,
      identificador: animal.identificador,
      usuarioId: usuarioId,
    );
    // La ficha tiene que reflejar el estado nuevo: la palpación cambia la
    // preñez y con ella qué botones tienen sentido.
    if (quedo) onCambio();
  }

  Future<void> _secadoDialog(BuildContext context) async {
    var cuando = _fechaInicial;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => StatefulBuilder(
        builder: (contextoDialogo, setState) => AlertDialog(
          title: const Text('Secado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // «Se secó el» y no «Pasó el»: a la vaca no le pasa el secado,
              // se la seca.
              _filaFecha(
                cuando,
                (d) => setState(() => cuando = d),
                etiqueta: 'Se secó',
              ),
              Text(
                '¿Marcar a ${animal.identificador} como seca? '
                'Pasará al grupo Secas.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(contextoDialogo, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(contextoDialogo, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
    if (confirmado != true) return;
    if (!context.mounted) return;
    await _anotar(
      context,
      queQuedo: 'Anotado: Secado',
      registrar: () => eventosRepo.registrarSecado(
        animalId: animal.id,
        lecheriaId: lecheriaId,
        registradoPor: usuarioId,
        fecha: cuando,
      ),
    );
  }

  /// Nota libre sobre la vaca. Es el único evento que no cambia nada de la
  /// ficha: solo deja el texto apuntado en su hoja de vida.
  Future<void> _observacionDialog(BuildContext context) async {
    final textoCtrl = TextEditingController();
    var cuando = _fechaInicial;
    final guardar = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => StatefulBuilder(
        builder: (contextoDialogo, setState) => AlertDialog(
          title: Text('Observación de ${animal.identificador}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _filaFecha(cuando, (d) => setState(() => cuando = d)),
              TextField(
                key: const ValueKey('trabajo.observacion.texto'),
                controller: textoCtrl,
                autofocus: true,
                // Varias líneas y sin tope: la idea es que quepa lo que sea,
                // desde "cojea de la pata izquierda" hasta media historia.
                maxLines: 5,
                minLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Qué querés apuntar',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(contextoDialogo, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const ValueKey('trabajo.observacion.guardar'),
              onPressed: () => Navigator.pop(contextoDialogo, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (guardar != true) return;
    if (!context.mounted) return;
    await _anotar(
      context,
      queQuedo: 'Anotado: Observación',
      registrar: () => eventosRepo.registrarObservacion(
        animalId: animal.id,
        lecheriaId: lecheriaId,
        texto: textoCtrl.text,
        registradoPor: usuarioId,
        fecha: cuando,
      ),
    );
  }

  Future<void> _partoDialog(BuildContext context) async {
    String sexoCria = Sexo.hembra;
    final identificadorCtrl = TextEditingController();
    // De quién es la cría: sale del último servicio de la madre. Se muestra
    // antes de guardar porque es el único momento en que alguien puede decir
    // "ese no es"; después nadie lo reconstruye de memoria.
    final padre = await eventosRepo.ultimoServicioDe(animal.id);
    if (!context.mounted) return;
    final nombrePadre = padre.pajilla;
    var cuando = _fechaInicial;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Parto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _filaFecha(
                cuando,
                (d) => setState(() => cuando = d),
                etiqueta: 'Parió',
              ),
              Text(
                'Fecha: hoy',
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: [
                  for (final s in Sexo.todos)
                    ButtonSegment(value: s, label: Text(Sexo.etiqueta(s))),
                ],
                selected: {sexoCria},
                onSelectionChanged: (s) => setState(() => sexoCria = s.first),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: identificadorCtrl,
                decoration: const InputDecoration(
                  labelText: 'Identificador de la cría (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                nombrePadre == null || nombrePadre.isEmpty
                    ? 'No hay un servicio anotado antes de este parto, así '
                          'que la cría queda sin padre registrado.'
                    : 'Padre: $nombrePadre, del último servicio de la madre.',
                key: const ValueKey('trabajo.parto.padre'),
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (confirmado != true) return;
    if (!context.mounted) return;
    await _anotar(
      context,
      // El parto crea la cría además de anotar el evento, así que el acuse lo
      // dice: es lo que el ganadero va a ir a buscar después.
      queQuedo: 'Anotado: Parto · cría registrada',
      registrar: () => eventosRepo.registrarParto(
        animalId: animal.id,
        lecheriaId: lecheriaId,
        sexoCria: sexoCria,
        identificadorCria: identificadorCtrl.text.trim().isEmpty
            ? null
            : identificadorCtrl.text.trim(),
        registradoPor: usuarioId,
        fecha: cuando,
      ),
    );
  }

  Future<void> _cambiarGrupoDialog(BuildContext context) async {
    final nuevoGrupo = await showDialog<String>(
      context: context,
      builder: (contextoDialogo) => SimpleDialog(
        title: const Text('Cambiar de grupo'),
        children: [
          for (final g in GrupoAnimal.todos)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(contextoDialogo, g),
              child: Text(GrupoAnimal.etiqueta(g)),
            ),
        ],
      ),
    );
    if (nuevoGrupo == null || nuevoGrupo == animal.grupo) return;
    if (!context.mounted) return;

    // El grupo se escoge de una lista sin botón de guardar, así que la fecha
    // se pregunta después, en su propio diálogo.
    final cuando = await _dialogoSoloFecha(
      context,
      'Pasó a ${GrupoAnimal.etiqueta(nuevoGrupo)}',
    );
    if (cuando == null || !context.mounted) return;
    await _anotar(
      context,
      queQuedo: 'Anotado: pasó a ${GrupoAnimal.etiqueta(nuevoGrupo)}',
      registrar: () => animalesRepo.cambiarGrupo(
        animalId: animal.id,
        lecheriaId: lecheriaId,
        nuevoGrupo: nuevoGrupo,
        registradoPor: usuarioId,
        fecha: cuando,
      ),
    );
  }

  Future<void> _bajaDialog(BuildContext context) async {
    String motivo = MotivoBaja.venta;
    final precioCtrl = TextEditingController();
    var cuando = _fechaInicial;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Dar de baja'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _filaFecha(
                cuando,
                (d) => setState(() => cuando = d),
                etiqueta: 'Se fue',
              ),
              SegmentedButton<String>(
                segments: [
                  for (final m in MotivoBaja.todos)
                    ButtonSegment(
                      value: m,
                      label: Text(MotivoBaja.etiqueta(m)),
                    ),
                ],
                selected: {motivo},
                onSelectionChanged: (s) => setState(() => motivo = s.first),
              ),
              if (motivo == MotivoBaja.venta) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: precioCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Precio de venta',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirmar baja'),
            ),
          ],
        ),
      ),
    );
    if (confirmado != true) return;
    if (!context.mounted) return;
    final quedo = await _anotar(
      context,
      queQuedo:
          'Anotado: baja por ${MotivoBaja.etiqueta(motivo).toLowerCase()}',
      registrar: () => animalesRepo.registrarBaja(
        animalId: animal.id,
        lecheriaId: lecheriaId,
        motivo: motivo,
        precioVenta: double.tryParse(precioCtrl.text.replaceAll(',', '.')),
        registradoPor: usuarioId,
        fecha: cuando,
      ),
    );
    // Solo se cierra la ficha si la baja quedó: si falló, el animal sigue en
    // la finca y hay que poder volver a intentarlo sin buscarlo de nuevo. El
    // check se ve igual, porque vive en el overlay de la app y no en la ficha.
    if (quedo && context.mounted) Navigator.of(context).maybePop();
  }
}

/// Grilla de dos columnas para los botones de "Registrar evento".
///
/// Los botones de Secado y Parto son condicionales (dependen del grupo y del
/// estado reproductivo del animal), asi que la cantidad varia entre 6 y 8.
/// Con un numero impar, un GridView dejaba el ultimo boton pegado a la
/// izquierda con un hueco al lado; aca queda centrado y todos conservan el
/// mismo tamano.
class _GrillaEventos extends StatelessWidget {
  const _GrillaEventos({required this.botones});

  final List<Widget> botones;

  static const double _espacio = 12;
  static const double _relacionAspecto = 2.4;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = (constraints.maxWidth - _espacio) / 2;
        return Wrap(
          spacing: _espacio,
          runSpacing: _espacio,
          alignment: WrapAlignment.center,
          children: [
            for (final boton in botones)
              SizedBox(
                width: ancho,
                height: ancho / _relacionAspecto,
                child: boton,
              ),
          ],
        );
      },
    );
  }
}

class _BotonEvento extends StatelessWidget {
  const _BotonEvento({
    required this.icono,
    required this.etiqueta,
    required this.onTap,
  });

  /// Widget y no `IconData`: Parto usa un PNG propio en vez de un ícono de
  /// Material. Va como `ImageIcon` para que herede el color y el tamaño del
  /// botón igual que los demás.
  final Widget icono;
  final String etiqueta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: icono,
      label: Text(etiqueta, textAlign: TextAlign.center),
      style: FilledButton.styleFrom(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}
