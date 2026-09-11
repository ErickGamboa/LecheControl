import 'package:flutter/material.dart';

import '../analisis/analisis_leche_screen.dart';
import '../app/theme.dart';
import '../app/widgets/acciones_fila.dart';
import '../app/widgets/quick_number_field.dart';
import '../data/domain/curva_lactancia.dart';
import '../data/domain/semana.dart';
import '../data/local/database.dart';
import '../data/repositories/pesas_repository.dart';
import '../services.dart';
import 'reporte_screen.dart';
import 'selector_vaca_sheet.dart';

/// Pesa de leche (Módulo 3). Abre o reutiliza la sesión de la semana y va vaca a
/// vaca: se **elige** la vaca de una lista con buscador y se anotan los litros
/// de la **mañana**, los de la **tarde** y los **kilos de concentrado**.
///
/// La lista solo trae las que faltan por pesar, así que se va vaciando sola
/// conforme avanza la ordeña. Se elige en vez de digitar porque en el corral,
/// con las manos ocupadas, teclear el número de cada vaca es la parte más
/// lenta y la que más errores mete.
///
/// Una vaca que no está en el inventario se puede pesar igual, como **vaca
/// manual**: queda con su identificador suelto, sin días de lactancia. Es lo
/// que el cliente marca con asterisco en su reporte.
class PesaScreen extends StatefulWidget {
  const PesaScreen({
    super.key,
    required this.lecheriaId,
    required this.nombreLecheria,
    this.sesionId,
  });

  final String lecheriaId;
  final String nombreLecheria;

  /// Pesa concreta sobre la que trabajar. En null —lo normal— se abre o se
  /// reutiliza la de esta semana.
  ///
  /// Viene con algo cuando se entra desde Análisis de leche a arreglar una
  /// pesa anterior: sin esto, la pantalla abriría igual la de la semana en
  /// curso y las correcciones caerían en la semana equivocada.
  final String? sesionId;

  @override
  State<PesaScreen> createState() => _PesaScreenState();
}

class _PesaScreenState extends State<PesaScreen> {
  PesaSesionRow? _sesion;
  bool _cargando = true;

  final _mananaCtrl = TextEditingController();
  final _mananaFocus = FocusNode();
  final _tardeCtrl = TextEditingController();
  final _tardeFocus = FocusNode();
  final _concentradoCtrl = TextEditingController();

  /// Vaca del inventario que se está pesando ahora.
  AnimalRow? _animalActual;

  /// Identificador de una vaca que NO está en el inventario y que el ganadero
  /// decidió pesar igual.
  String? _manualActual;

  String? _mensaje;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  @override
  void dispose() {
    _mananaCtrl.dispose();
    _mananaFocus.dispose();
    _tardeCtrl.dispose();
    _tardeFocus.dispose();
    _concentradoCtrl.dispose();
    super.dispose();
  }

  Future<void> _iniciar() async {
    final pedida = widget.sesionId;
    final sesion = pedida == null
        ? await pesasRepo.abrirSesion(lecheriaId: widget.lecheriaId)
        : await pesasRepo.sesionPorId(pedida);
    if (!mounted) return;
    setState(() {
      _sesion = sesion;
      _cargando = false;
    });
  }

  bool get _hayVacaEnCurso => _animalActual != null || _manualActual != null;

  void _limpiarCaptura() {
    _animalActual = null;
    _manualActual = null;
    _mananaCtrl.clear();
    _tardeCtrl.clear();
    _concentradoCtrl.clear();
  }

  double? _leer(TextEditingController c) {
    final texto = c.text.trim().replaceAll(',', '.');
    if (texto.isEmpty) return null;
    return double.tryParse(texto);
  }

  Future<void> _elegirVaca() async {
    final sesion = _sesion;
    if (sesion == null) return;

    final elegida = await elegirVaca(
      context,
      lecheriaId: widget.lecheriaId,
      sesionId: sesion.id,
    );
    if (!mounted || elegida == null) return;

    setState(() {
      _animalActual = elegida.animal;
      _manualActual = elegida.manual;
      _mensaje = null;
      _mananaCtrl.clear();
      _tardeCtrl.clear();
      _concentradoCtrl.clear();
    });
    _mananaFocus.requestFocus();
  }

  Future<void> _abrirHistorial() {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnalisisLecheScreen(
          lecheriaId: widget.lecheriaId,
          nombreLecheria: widget.nombreLecheria,
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    final sesion = _sesion;
    if (sesion == null || !_hayVacaEnCurso) return;

    final manana = _leer(_mananaCtrl);
    final tarde = _leer(_tardeCtrl);
    if (manana == null && tarde == null) {
      setState(() => _mensaje = 'Anotá al menos un ordeño (mañana o tarde).');
      return;
    }
    final concentrado = _leer(_concentradoCtrl);
    final animalId = _animalActual?.id;
    final manual = _manualActual;

    final existente = await pesasRepo.registrarPesa(
      sesionId: sesion.id,
      animalId: animalId,
      identificadorManual: manual,
      litrosManana: manana,
      litrosTarde: tarde,
      concentradoKg: concentrado,
    );
    if (!mounted) return;

    if (existente != null) {
      final nuevoTotal = (manana ?? 0) + (tarde ?? 0);
      final corregir = await showDialog<bool>(
        context: context,
        // Con el contexto del diálogo, no el de la pantalla: ver la nota en
        // `trabajo_screen.dart`. Con el de la pantalla, en la versión de
        // escritorio se cierra la sección en vez del diálogo.
        builder: (contextoDialogo) => AlertDialog(
          title: const Text('Ya se pesó hoy'),
          content: Text(
            '${_animalActual?.identificador ?? manual} ya tiene '
            '${existente.litros.toStringAsFixed(1)} L registrados en esta '
            'sesión. ¿Corregir por ${nuevoTotal.toStringAsFixed(1)} L?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(contextoDialogo, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(contextoDialogo, true),
              child: const Text('Corregir'),
            ),
          ],
        ),
      );
      if (corregir != true) return;
      await pesasRepo.registrarPesa(
        sesionId: sesion.id,
        animalId: animalId,
        identificadorManual: manual,
        litrosManana: manana,
        litrosTarde: tarde,
        concentradoKg: concentrado,
        corregir: true,
      );
      if (!mounted) return;
    }

    sincronizarSiSePuede();
    setState(() {
      _limpiarCaptura();
      _mensaje = null;
    });
    // Encadenar es lo natural en la ordeña: guardar una vaca y que salga
    // enseguida la lista para la siguiente, sin un toque de más.
    await _elegirVaca();
  }

  /// Arregla los litros de una vaca ya pesada, desde la lista de abajo.
  Future<void> _corregirPesada(PesaDeSesion detalle) async {
    final guardado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CorregirPesaSheet(detalle: detalle),
    );
    if (guardado == true) sincronizarSiSePuede();
  }

  /// Quita una pesada: se pesó la vaca equivocada.
  Future<void> _eliminarPesada(PesaDeSesion detalle) async {
    final confirmado = await confirmarEliminar(
      context,
      titulo: 'Quitar la pesada',
      queSeVa:
          '${detalle.etiqueta}, con '
          '${detalle.pesa.litros.toStringAsFixed(1)} L.',
      advertencia: detalle.esManual
          ? null
          : 'La vaca vuelve a la lista de las que faltan por pesar.',
      textoBoton: 'Quitar',
    );
    if (!confirmado) return;
    await pesasRepo.eliminarPesa(detalle.pesa.id);
    sincronizarSiSePuede();
  }

  Future<void> _cerrarSesion() async {
    final sesion = _sesion;
    if (sesion == null) return;
    final resumen = await pesasRepo.resumenSesion(sesion.id);
    final faltantes = await pesasRepo.faltantesDeSesion(
      lecheriaId: widget.lecheriaId,
      sesionId: sesion.id,
    );
    if (!mounted) return;
    final confirmado = await showDialog<bool>(
      context: context,
      // Con el contexto del diálogo, no el de la pantalla: ver la nota en
      // `trabajo_screen.dart`. Con el de la pantalla, en la versión de
      // escritorio se cierra la sección en vez del diálogo.
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('Cerrar sesión de pesa'),
        content: _ResumenSesionWidget(resumen: resumen, faltantes: faltantes),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contextoDialogo, false),
            child: const Text('Seguir pesando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(contextoDialogo, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmado == true) {
      await pesasRepo.cerrarSesion(sesion.id);
      sincronizarSiSePuede();
      if (!mounted) return;
      // Cerrar la pesa y ver el reporte es un solo movimiento: es para lo que
      // se pesó. Al salir del reporte, se sale también de la pesa.
      await _abrirReporte();
      if (mounted) Navigator.of(context).maybePop();
    }
  }

  Future<void> _abrirReporte() {
    final sesion = _sesion;
    if (sesion == null) return Future.value();
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReporteScreen(
          lecheriaId: widget.lecheriaId,
          sesionId: sesion.id,
          nombreLecheria: widget.nombreLecheria,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando || _sesion == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pesa de leche')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pesa de leche'),
            // Se pesa un día por semana: decir de qué semana es esta pesa
            // evita confundirla con la de la semana pasada.
            // Sin el "Semana del " delante: con tres acciones y el botón
            // Cerrar en la barra, el texto completo no cabe y se corta.
            Text(
              etiquetaSemana(
                lunesDe(_sesion!.fecha),
                domingoDe(_sesion!.fecha),
              ),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                // Hereda el color de la barra (blanco en claro, claro en
                // oscuro) y solo le baja la intensidad.
                color: Theme.of(
                  context,
                ).appBarTheme.foregroundColor?.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const ValueKey('pesa.historial'),
            tooltip: 'Pesas anteriores',
            onPressed: _abrirHistorial,
            icon: const Icon(Icons.history),
          ),
          IconButton(
            key: const ValueKey('pesa.verReporte'),
            tooltip: 'Ver reporte',
            onPressed: _abrirReporte,
            icon: const Icon(Icons.assessment_outlined),
          ),
          TextButton.icon(
            key: const ValueKey('pesa.cerrar'),
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Cerrar'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ContadorSesion(
              key: const ValueKey('pesa.contador'),
              lecheriaId: widget.lecheriaId,
              sesionId: _sesion!.id,
            ),
            const SizedBox(height: 16),
            if (!_hayVacaEnCurso)
              FilledButton.icon(
                key: const ValueKey('pesa.elegirVaca'),
                onPressed: _elegirVaca,
                icon: const Icon(Icons.search),
                label: const Text('Elegir vaca'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
              ),
            if (_mensaje != null) ...[
              const SizedBox(height: 8),
              Text(_mensaje!, style: TextStyle(color: Colors.red.shade700)),
            ],
            if (_hayVacaEnCurso) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _CabeceraVaca(
                      animal: _animalActual,
                      manual: _manualActual,
                    ),
                  ),
                  TextButton.icon(
                    key: const ValueKey('pesa.cambiarVaca'),
                    onPressed: _elegirVaca,
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Cambiar'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: QuickNumberField(
                      key: const ValueKey('pesa.manana'),
                      controller: _mananaCtrl,
                      focusNode: _mananaFocus,
                      labelText: 'Mañana',
                      suffixText: 'L',
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _tardeFocus.requestFocus(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickNumberField(
                      key: const ValueKey('pesa.tarde'),
                      controller: _tardeCtrl,
                      focusNode: _tardeFocus,
                      labelText: 'Tarde',
                      suffixText: 'L',
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              QuickNumberField(
                key: const ValueKey('pesa.concentrado'),
                controller: _concentradoCtrl,
                labelText: 'Concentrado',
                suffixText: 'kg',
                onSubmitted: (_) => _guardar(),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const ValueKey('pesa.guardar'),
                onPressed: _guardar,
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            _ListaPesadas(
              sesionId: _sesion!.id,
              onCorregir: _corregirPesada,
              onEliminar: _eliminarPesada,
            ),
          ],
        ),
      ),
    );
  }
}

/// Quién se está pesando: identificador, días de lactancia y grupo. Para una
/// vaca manual avisa que no tiene ficha.
class _CabeceraVaca extends StatelessWidget {
  const _CabeceraVaca({required this.animal, required this.manual});

  final AnimalRow? animal;
  final String? manual;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme;
    if (animal == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$manual *', style: estilo.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Vaca manual — sin ficha ni días de lactancia',
            style: estilo.bodySmall?.copyWith(color: Colors.orange.shade800),
          ),
        ],
      );
    }

    final dlac = diasLactancia(animal!.fechaUltimoParto);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(animal!.identificador, style: estilo.titleLarge),
        const SizedBox(height: 4),
        Text(
          dlac == null
              ? 'Sin parto registrado — no se puede calcular días de lactancia'
              : '$dlac días de lactancia',
          style: estilo.bodySmall?.copyWith(
            color: dlac == null ? Colors.orange.shade800 : null,
          ),
        ),
      ],
    );
  }
}

class _ContadorSesion extends StatelessWidget {
  const _ContadorSesion({
    super.key,
    required this.lecheriaId,
    required this.sesionId,
  });

  final String lecheriaId;
  final String sesionId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PesaDeSesion>>(
      stream: pesasRepo.observarDetalleSesion(sesionId),
      builder: (context, snapshot) {
        final detalle = snapshot.data ?? const <PesaDeSesion>[];
        // Contra el total del hato solo cuentan las vacas del inventario: las
        // manuales son extra y sumarlas haría ver "38 de 36".
        final delInventario = detalle.where((d) => !d.esManual).length;
        final manuales = detalle.length - delInventario;
        final litros = detalle.fold<double>(0, (a, d) => a + d.pesa.litros);

        return FutureBuilder<List<AnimalRow>>(
          future: pesasRepo.faltantesDeSesion(
            lecheriaId: lecheriaId,
            sesionId: sesionId,
          ),
          builder: (context, faltantesSnap) {
            final faltan = faltantesSnap.data?.length;
            final total = faltan == null ? null : delInventario + faltan;
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kVerdeLeche.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        total == null
                            ? '$delInventario pesadas'
                            : '$delInventario de $total pesadas',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        manuales == 0
                            ? '${litros.toStringAsFixed(1)} L en total'
                            : '${litros.toStringAsFixed(1)} L en total · '
                                  '$manuales manual${manuales == 1 ? '' : 'es'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Icon(
                    faltan == 0 && delInventario > 0
                        ? Icons.check_circle
                        : Icons.pending_outlined,
                    color: kVerdeLeche,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ListaPesadas extends StatelessWidget {
  const _ListaPesadas({
    required this.sesionId,
    required this.onCorregir,
    required this.onEliminar,
  });

  final String sesionId;
  final void Function(PesaDeSesion) onCorregir;
  final void Function(PesaDeSesion) onEliminar;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PesaDeSesion>>(
      stream: pesasRepo.observarDetalleSesion(sesionId),
      builder: (context, snapshot) {
        final detalle = snapshot.data ?? const <PesaDeSesion>[];
        if (detalle.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('Todavía no hay pesadas en esta sesión.'),
            ),
          );
        }
        return Column(
          children: [
            for (final d in detalle)
              _FilaPesada(
                detalle: d,
                onCorregir: () => onCorregir(d),
                onEliminar: () => onEliminar(d),
              ),
          ],
        );
      },
    );
  }
}

class _FilaPesada extends StatelessWidget {
  const _FilaPesada({
    required this.detalle,
    required this.onCorregir,
    required this.onEliminar,
  });

  final PesaDeSesion detalle;
  final VoidCallback onCorregir;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final p = detalle.pesa;
    final partes = <String>[
      if (p.litrosManana != null) 'M ${p.litrosManana!.toStringAsFixed(1)}',
      if (p.litrosTarde != null) 'T ${p.litrosTarde!.toStringAsFixed(1)}',
      if (p.concentradoKg != null)
        '${p.concentradoKg!.toStringAsFixed(1)} kg conc.',
    ];
    final dlac = detalle.diasLactanciaHoy();

    return ListTile(
      key: ValueKey('pesa.fila.${p.id}'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.water_drop_outlined,
        color: detalle.esManual ? Colors.orange.shade700 : kVerdeLeche,
      ),
      title: Text(detalle.etiqueta),
      subtitle: Text(
        [
          if (dlac != null) '$dlac días',
          // Las pesas anteriores a esta versión traen solo el total: se dice,
          // en vez de inventar un reparto que nadie midió.
          if (partes.isEmpty) 'sin desglose' else partes.join(' · '),
        ].join(' · '),
      ),
      // Tocar la vaca ya pesada la abre para arreglarle los litros. Es el
      // gesto que se busca solo cuando uno se da cuenta del error mirando la
      // lista.
      onTap: onCorregir,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${p.litros.toStringAsFixed(1)} L',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          MenuFila(
            key: ValueKey('pesa.fila.menu.${p.id}'),
            onEditar: onCorregir,
            onEliminar: onEliminar,
            textoEliminar: 'Quitar',
          ),
        ],
      ),
    );
  }
}

/// Arregla los litros de una vaca que ya se pesó en esta sesión.
///
/// Los campos vienen cargados con lo que hay: casi siempre se corrige un solo
/// número, y volver a digitar los tres sería pedir de más.
class _CorregirPesaSheet extends StatefulWidget {
  const _CorregirPesaSheet({required this.detalle});

  final PesaDeSesion detalle;

  @override
  State<_CorregirPesaSheet> createState() => _CorregirPesaSheetState();
}

class _CorregirPesaSheetState extends State<_CorregirPesaSheet> {
  late final TextEditingController _mananaCtrl;
  late final TextEditingController _tardeCtrl;
  late final TextEditingController _concentradoCtrl;

  /// Pesas viejas que solo traen el total, sin saber cuánto fue de la mañana
  /// y cuánto de la tarde. Se corrigen como un total y ya.
  late final bool _soloTotal;
  late final TextEditingController _totalCtrl;

  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.detalle.pesa;
    _soloTotal = p.litrosManana == null && p.litrosTarde == null;
    _mananaCtrl = TextEditingController(text: _texto(p.litrosManana));
    _tardeCtrl = TextEditingController(text: _texto(p.litrosTarde));
    _concentradoCtrl = TextEditingController(text: _texto(p.concentradoKg));
    _totalCtrl = TextEditingController(text: _texto(p.litros));
  }

  static String _texto(double? v) =>
      v == null ? '' : (v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v');

  @override
  void dispose() {
    _mananaCtrl.dispose();
    _tardeCtrl.dispose();
    _concentradoCtrl.dispose();
    _totalCtrl.dispose();
    super.dispose();
  }

  double? _leer(TextEditingController c) {
    final texto = c.text.trim().replaceAll(',', '.');
    if (texto.isEmpty) return null;
    return double.tryParse(texto);
  }

  Future<void> _guardar() async {
    final manana = _leer(_mananaCtrl);
    final tarde = _leer(_tardeCtrl);
    final total = _leer(_totalCtrl);
    if (_soloTotal ? total == null : (manana == null && tarde == null)) {
      setState(() => _error = 'Anotá al menos un ordeño (mañana o tarde).');
      return;
    }
    await pesasRepo.editarPesa(
      pesaId: widget.detalle.pesa.id,
      litrosManana: _soloTotal ? null : manana,
      litrosTarde: _soloTotal ? null : tarde,
      litrosTotal: _soloTotal ? total : null,
      concentradoKg: _leer(_concentradoCtrl),
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Corregir a ${widget.detalle.etiqueta}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_soloTotal)
              QuickNumberField(
                key: const ValueKey('pesa.corregir.total'),
                controller: _totalCtrl,
                labelText: 'Litros del día',
                suffixText: 'L',
                autofocus: true,
                textInputAction: TextInputAction.next,
              )
            else
              Row(
                children: [
                  Expanded(
                    child: QuickNumberField(
                      key: const ValueKey('pesa.corregir.manana'),
                      controller: _mananaCtrl,
                      labelText: 'Mañana',
                      suffixText: 'L',
                      autofocus: true,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickNumberField(
                      key: const ValueKey('pesa.corregir.tarde'),
                      controller: _tardeCtrl,
                      labelText: 'Tarde',
                      suffixText: 'L',
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            QuickNumberField(
              key: const ValueKey('pesa.corregir.concentrado'),
              controller: _concentradoCtrl,
              labelText: 'Concentrado',
              suffixText: 'kg',
              onSubmitted: (_) => _guardar(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              key: const ValueKey('pesa.corregir.guardar'),
              onPressed: _guardar,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumenSesionWidget extends StatelessWidget {
  const _ResumenSesionWidget({required this.resumen, required this.faltantes});

  final ResumenSesion resumen;
  final List<AnimalRow> faltantes;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vacas pesadas: ${resumen.totalVacas}'),
        Text('Total: ${resumen.totalLitros.toStringAsFixed(1)} L'),
        Text('Promedio: ${resumen.promedio.toStringAsFixed(1)} L'),
        Text('Máximo: ${resumen.maximo.toStringAsFixed(1)} L'),
        Text('Mínimo: ${resumen.minimo.toStringAsFixed(1)} L'),
        if (resumen.variacionRespectoAnterior != null)
          Text(
            'Variación vs. sesión anterior: '
            '${resumen.variacionRespectoAnterior! >= 0 ? '+' : ''}'
            '${resumen.variacionRespectoAnterior!.toStringAsFixed(1)} L',
          ),
        if (faltantes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Quedan ${faltantes.length} sin pesar',
            style: TextStyle(
              color: Colors.orange.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            faltantes.take(8).map((a) => a.identificador).join(', ') +
                (faltantes.length > 8 ? '…' : ''),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
