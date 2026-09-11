import 'package:flutter/material.dart';

import '../app/formato.dart';
import '../app/widgets/acciones_fila.dart';
import '../data/domain/curva_lactancia.dart';
import '../data/domain/grupos.dart';
import '../data/local/database.dart';
import '../data/repositories/pesas_repository.dart';
import '../inventario/acciones_animal.dart';
import '../services.dart';

/// Hoja de vida de un animal (Módulo 1 y 6): identificación, estado actual y
/// el historial completo de eventos (reproductivos, sanitarios, de manejo) y
/// de pesas de leche, en dos pestañas.
///
/// Es también donde se arregla lo que quedó mal anotado: la ficha del animal,
/// desde el menú de la barra, y cada evento, desde su propia fila.
class HojaVidaScreen extends StatelessWidget {
  const HojaVidaScreen({super.key, required this.animalId});

  final String animalId;

  /// Acciones sobre el animal entero. Al eliminarlo se sale de la pantalla:
  /// quedarse viendo la hoja de vida de algo que ya no existe no tiene
  /// sentido.
  Future<void> _accion(
    BuildContext context,
    String cual,
    AnimalRow animal,
  ) async {
    final navegador = Navigator.of(context);
    switch (cual) {
      case 'ficha':
        await corregirFichaAnimal(context, animal);
      case 'devolver':
        await devolverAlHato(context, animal);
      case 'eliminar':
        final eliminado = await eliminarAnimal(context, animal);
        if (eliminado) navegador.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AnimalRow?>(
      stream: animalesRepo.observarAnimal(animalId),
      builder: (context, snapshot) {
        final animal = snapshot.data;
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(animal?.identificador ?? 'Hoja de vida'),
              actions: [
                if (animal != null)
                  PopupMenuButton<String>(
                    key: const ValueKey('hojaVida.menu'),
                    tooltip: 'Corregir este animal',
                    onSelected: (v) => _accion(context, v, animal),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'ficha',
                        child: Text('Corregir la ficha'),
                      ),
                      if (animal.estado != EstadoAnimal.activo)
                        const PopupMenuItem(
                          value: 'devolver',
                          child: Text('Devolver al hato'),
                        ),
                      const PopupMenuItem(
                        value: 'eliminar',
                        child: Text('Eliminar el animal'),
                      ),
                    ],
                  ),
              ],
              // Los colores van a mano: por defecto Material pinta la pestaña
              // elegida del azul de la marca, que sobre la barra —azul de la
              // marca— desaparecía. «Eventos» se leía en blanco sobre blanco.
              bottom: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: 'Eventos', icon: Icon(Icons.timeline)),
                  Tab(text: 'Pesas', icon: Icon(Icons.water_drop_outlined)),
                ],
              ),
            ),
            body: animal == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      _EncabezadoAnimal(animal: animal),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _TabEventos(animal: animal),
                            _TabPesas(animalId: animal.id),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _EncabezadoAnimal extends StatelessWidget {
  const _EncabezadoAnimal({required this.animal});

  final AnimalRow animal;

  /// Fija o corrige la fecha del último parto. Es la única forma de cargar
  /// los días de lactancia de una vaca que ya estaba en la finca antes de
  /// usar la app, o de arreglar una fecha mal digitada.
  Future<void> _editarUltimoParto(BuildContext context) async {
    final ahora = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: animal.fechaUltimoParto ?? ahora,
      firstDate: DateTime(ahora.year - 3),
      lastDate: ahora,
      helpText: 'Fecha del último parto',
    );
    if (elegida == null) return;
    await animalesRepo.editarFechaUltimoParto(
      animalId: animal.id,
      fecha: elegida,
    );
    sincronizarSiSePuede();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pronta = esPronta(animal.fechaProbableParto);
    final dlac = diasLactancia(animal.fechaUltimoParto);
    final esVacaDeOrdeno =
        animal.sexo == Sexo.hembra && animal.grupo == GrupoAnimal.enOrdeno;

    return Container(
      width: double.infinity,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          Chip(label: Text(Sexo.etiqueta(animal.sexo))),
          Chip(label: Text(GrupoAnimal.etiqueta(animal.grupo))),
          Chip(label: Text(EstadoAnimal.etiqueta(animal.estado))),
          // Los días de lactancia son la base del reporte de producción, así
          // que se muestran acá y se pueden corregir de un toque.
          if (esVacaDeOrdeno)
            ActionChip(
              key: const ValueKey('hojaVida.dlac'),
              avatar: Icon(
                dlac == null ? Icons.warning_amber : Icons.event_outlined,
                size: 18,
                color: dlac == null ? Colors.orange.shade800 : null,
              ),
              label: Text(
                dlac == null ? 'Sin último parto' : '$dlac días de lactancia',
              ),
              onPressed: () => _editarUltimoParto(context),
            ),
          if (animal.sexo == Sexo.hembra)
            Chip(
              label: Text(
                EstadoReproductivo.etiqueta(animal.estadoReproductivo),
              ),
            ),
          if (animal.fechaProbableParto != null)
            Chip(
              // La vaca pronta no cambia de grupo, así que el aviso va acá:
              // es lo que hay que saber cuando se la tiene enfrente.
              backgroundColor: pronta
                  ? theme.colorScheme.tertiaryContainer
                  : null,
              avatar: const Icon(Icons.child_friendly_outlined, size: 18),
              label: Text(
                pronta
                    ? '${etiquetaPronta(animal.fechaProbableParto)} '
                          '(${_fmt(animal.fechaProbableParto!)})'
                    : 'Parto: ${_fmt(animal.fechaProbableParto!)}',
              ),
            ),
        ],
      ),
    );
  }

  String _fmt(DateTime f) => '${f.day}/${f.month}/${f.year}';
}

class _TabEventos extends StatelessWidget {
  const _TabEventos({required this.animal});

  final AnimalRow animal;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EventoAnimalRow>>(
      stream: eventosRepo.listarHojaVida(animal.id),
      builder: (context, snapshot) {
        final eventos = snapshot.data ?? const [];
        if (eventos.isEmpty) {
          return const Center(child: Text('Todavía no hay eventos.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: eventos.length,
          itemBuilder: (context, i) => _EventoTile(evento: eventos[i]),
        );
      },
    );
  }
}

class _EventoTile extends StatelessWidget {
  const _EventoTile({required this.evento});

  final EventoAnimalRow evento;

  /// Qué se deshace al borrar este evento, dicho antes de borrarlo.
  ///
  /// Un evento no es solo una línea: el secado movió la vaca de grupo y el
  /// parto le reinició los días de lactancia. El ganadero tiene que leer eso
  /// antes de decidir, no descubrirlo después en el reporte.
  String? get _queSeDeshace => switch (evento.tipo) {
    TipoEventoAnimal.parto =>
      'La vaca vuelve al grupo anterior, pierde esta fecha de último parto '
          '—y con ella los días de lactancia— y queda sin estado '
          'reproductivo hasta la próxima palpación. La cría se elimina si '
          'todavía no tiene nada anotado.',
    TipoEventoAnimal.palpacion =>
      'La vaca vuelve al diagnóstico anterior y se le quita la fecha probable '
          'de parto. Hay que volver a palparla para fijarla.',
    TipoEventoAnimal.secado =>
      'La vaca vuelve al grupo '
          '${GrupoAnimal.etiqueta(evento.grupoAnterior ?? '')}.',
    TipoEventoAnimal.cambioGrupo =>
      'El animal vuelve al grupo '
          '${GrupoAnimal.etiqueta(evento.grupoAnterior ?? '')}.',
    TipoEventoAnimal.baja => 'El animal vuelve al inventario como activo.',
    _ => null,
  };

  Future<void> _corregir(BuildContext context) async {
    final corregido = await showDialog<bool>(
      context: context,
      builder: (_) => _CorregirEventoDialog(evento: evento),
    );
    if (corregido == true) sincronizarSiSePuede();
  }

  Future<void> _eliminar(BuildContext context) async {
    final f = evento.fecha;
    final confirmado = await confirmarEliminar(
      context,
      titulo: 'Eliminar el evento',
      queSeVa:
          '${TipoEventoAnimal.etiqueta(evento.tipo)} del '
          '${f.day}/${f.month}/${f.year}.',
      advertencia: _queSeDeshace,
    );
    if (!confirmado) return;
    await eventosRepo.eliminarEvento(evento.id);
    sincronizarSiSePuede();
  }

  IconData get _icono => switch (evento.tipo) {
    TipoEventoAnimal.sanidad => Icons.medical_services_outlined,
    TipoEventoAnimal.celo => Icons.favorite_outline,
    TipoEventoAnimal.monta => Icons.favorite_outline,
    TipoEventoAnimal.inseminacion => Icons.favorite_outline,
    TipoEventoAnimal.palpacion => Icons.fact_check_outlined,
    TipoEventoAnimal.secado => Icons.pause_circle_outline,
    TipoEventoAnimal.parto => Icons.child_friendly_outlined,
    TipoEventoAnimal.cambioGrupo => Icons.swap_horiz,
    TipoEventoAnimal.baja => Icons.remove_circle_outline,
    TipoEventoAnimal.concentrado => Icons.grass_outlined,
    TipoEventoAnimal.observacion => Icons.sticky_note_2_outlined,
    _ => Icons.circle_outlined,
  };

  String get _subtitulo {
    final partes = <String>[];
    if (evento.detalle != null) partes.add(evento.detalle!);
    if (evento.dosis != null) partes.add('Dosis: ${evento.dosis}');
    if (evento.diasRetiro != null) {
      partes.add('${evento.diasRetiro} días de retiro');
    }
    if (evento.costo != null) {
      partes.add('Costo: ${colones(evento.costo!)}');
    }
    if (evento.resultado != null) {
      partes.add(ResultadoPalpacion.etiqueta(evento.resultado!));
    }
    if (evento.toroPajilla != null) partes.add(evento.toroPajilla!);
    if (evento.grupoAnterior != null && evento.grupoNuevo != null) {
      partes.add(
        '${GrupoAnimal.etiqueta(evento.grupoAnterior!)} → '
        '${GrupoAnimal.etiqueta(evento.grupoNuevo!)}',
      );
    }
    if (evento.motivoBaja != null) {
      partes.add(MotivoBaja.etiqueta(evento.motivoBaja!));
    }
    if (evento.precioVenta != null) {
      partes.add(colones(evento.precioVenta!));
    }
    if (evento.sexoCria != null) {
      partes.add('Cría: ${Sexo.etiqueta(evento.sexoCria!)}');
    }
    return partes.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final f = evento.fecha;
    return Card(
      child: ListTile(
        key: ValueKey('hojaVida.evento.${evento.id}'),
        leading: CircleAvatar(child: Icon(_icono, size: 20)),
        title: Text(TipoEventoAnimal.etiqueta(evento.tipo)),
        subtitle: _subtitulo.isEmpty ? null : Text(_subtitulo),
        onTap: () => _corregir(context),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${f.day}/${f.month}/${f.year}'),
            MenuFila(
              key: ValueKey('hojaVida.evento.menu.${evento.id}'),
              onEditar: () => _corregir(context),
              onEliminar: () => _eliminar(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Corrige la fecha y la nota de un evento.
///
/// Solo esos dos campos, y se dice por qué: el resto de lo que trae un evento
/// —que la palpación diera preñada, el sexo de la cría— cambió la ficha del
/// animal cuando se registró, y enmendarlo a medias dejaría la hoja de vida
/// diciendo una cosa y la vaca otra. Para eso se elimina el evento, que sí
/// deshace todo, y se vuelve a registrar.
class _CorregirEventoDialog extends StatefulWidget {
  const _CorregirEventoDialog({required this.evento});

  final EventoAnimalRow evento;

  @override
  State<_CorregirEventoDialog> createState() => _CorregirEventoDialogState();
}

class _CorregirEventoDialogState extends State<_CorregirEventoDialog> {
  late DateTime _fecha = widget.evento.fecha;
  late final TextEditingController _detalleCtrl = TextEditingController(
    text: widget.evento.detalle ?? '',
  );
  bool _guardando = false;

  @override
  void dispose() {
    _detalleCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final ahora = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(ahora.year - 5),
      lastDate: ahora,
      helpText: 'Fecha del evento',
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    await eventosRepo.editarEvento(
      eventoId: widget.evento.id,
      fecha: _fecha,
      detalle: _detalleCtrl.text,
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final esParto = widget.evento.tipo == TipoEventoAnimal.parto;
    return AlertDialog(
      title: Text('Corregir ${TipoEventoAnimal.etiqueta(widget.evento.tipo)}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            key: const ValueKey('hojaVida.corregirEvento.fecha'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Fecha'),
            subtitle: Text('${_fecha.day}/${_fecha.month}/${_fecha.year}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: _elegirFecha,
          ),
          if (esParto)
            Text(
              'Mover la fecha del último parto le cambia los días de '
              'lactancia a la vaca en el reporte.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('hojaVida.corregirEvento.nota'),
            controller: _detalleCtrl,
            decoration: const InputDecoration(
              labelText: 'Nota',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          Text(
            'Lo demás de este evento no se corrige acá: si está mal, se '
            'elimina y se vuelve a registrar.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const ValueKey('hojaVida.corregirEvento.guardar'),
          onPressed: _guardando ? null : _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _TabPesas extends StatelessWidget {
  const _TabPesas({required this.animalId});

  final String animalId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PesaHistorial>>(
      stream: pesasRepo.historialAnimal(animalId),
      builder: (context, snapshot) {
        final historial = (snapshot.data ?? const []).reversed.toList();
        if (historial.isEmpty) {
          return const Center(child: Text('Todavía no hay pesas.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: historial.length,
          itemBuilder: (context, i) {
            final p = historial[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.water_drop_outlined),
                title: Text('${p.litros.toStringAsFixed(1)} L'),
                trailing: Text(
                  '${p.fecha.day}/${p.fecha.month}/${p.fecha.year}',
                ),
              ),
            );
          },
        );
      },
    );
  }
}
