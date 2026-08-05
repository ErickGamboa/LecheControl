import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../app/widgets/scan_field.dart';
import '../data/domain/grupos.dart';
import '../data/local/database.dart';
import '../data/repositories/animales_repository.dart';
import '../hoja_vida/hoja_vida_screen.dart';
import '../sanidad/sanidad_aplicar_sheet.dart';
import '../services.dart';

/// Pantalla de Trabajo (Módulo 1) — la pantalla principal: identificar un
/// animal (RFID o manual) y registrarle eventos con botones grandes, o darlo
/// de alta si es nuevo.
class TrabajoScreen extends StatefulWidget {
  const TrabajoScreen({
    super.key,
    required this.lecheriaId,
    required this.usuarioId,
  });

  final String lecheriaId;
  final String usuarioId;

  @override
  State<TrabajoScreen> createState() => _TrabajoScreenState();
}

class _TrabajoScreenState extends State<TrabajoScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  AnimalRow? _animal;
  bool _buscando = false;
  bool _noEncontrado = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _buscar([String? valor]) async {
    final identificador = (valor ?? _ctrl.text).trim();
    if (identificador.isEmpty) return;
    setState(() {
      _buscando = true;
      _noEncontrado = false;
      _animal = null;
    });
    final animal = await animalesRepo.buscarPorIdentificador(
      widget.lecheriaId,
      identificador,
    );
    if (!mounted) return;
    setState(() {
      _buscando = false;
      _animal = animal;
      _noEncontrado = animal == null;
    });
  }

  void _limpiar() {
    _ctrl.clear();
    setState(() {
      _animal = null;
      _noEncontrado = false;
    });
    _focus.requestFocus();
  }

  Future<void> _refrescarAnimal() async {
    final animal = _animal;
    if (animal == null) return;
    final actualizado = await animalesRepo.buscarPorIdentificador(
      widget.lecheriaId,
      animal.identificador,
    );
    if (mounted) setState(() => _animal = actualizado);
  }

  Future<void> _altaAnimalNuevo() async {
    final identificador = _ctrl.text.trim();
    final creado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AltaAnimalSheet(
        lecheriaId: widget.lecheriaId,
        identificadorInicial: identificador,
      ),
    );
    if (creado == true) {
      await _buscar(identificador);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trabajo')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ScanField(
                      key: const ValueKey('trabajo.identificador'),
                      controller: _ctrl,
                      focusNode: _focus,
                      labelText: 'Identificador (RFID o manual)',
                      prefixIcon: const Icon(Icons.nfc),
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _buscar,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: const ValueKey('trabajo.buscar'),
                    onPressed: _buscando ? null : () => _buscar(),
                    icon: const Icon(Icons.search),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buscando
                    ? const Center(child: CircularProgressIndicator())
                    : _animal != null
                    ? _TarjetaAnimal(
                        animal: _animal!,
                        lecheriaId: widget.lecheriaId,
                        usuarioId: widget.usuarioId,
                        onLimpiar: _limpiar,
                        onCambio: _refrescarAnimal,
                      )
                    : _noEncontrado
                    ? _AnimalNoEncontrado(onAlta: _altaAnimalNuevo)
                    : const _EstadoInicial(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstadoInicial extends StatelessWidget {
  const _EstadoInicial();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.nfc, size: 72, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Escaneá o escribí el identificador del animal',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimalNoEncontrado extends StatelessWidget {
  const _AnimalNoEncontrado({required this.onAlta});

  final VoidCallback onAlta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.help_outline,
              size: 72,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No encontramos ese animal',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '¿Es un animal nuevo? Registralo de una vez.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const ValueKey('trabajo.alta.abrir'),
              onPressed: onAlta,
              icon: const Icon(Icons.add),
              label: const Text('Registrar animal nuevo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaAnimal extends StatelessWidget {
  const _TarjetaAnimal({
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

  bool get _enRetiro =>
      animal.retiroLecheHasta != null &&
      animal.retiroLecheHasta!.isAfter(DateTime.now());

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
                    if (_enRetiro) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_amber,
                              size: 16,
                              color: theme.colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'En retiro de leche hasta '
                              '${_fmtFecha(animal.retiroLecheHasta!)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (animal.concentradoKgDia > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Concentrado: ${animal.concentradoKgDia.toStringAsFixed(1)} kg/día',
                        style: theme.textTheme.bodySmall,
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
                icono: Icons.medical_services_outlined,
                etiqueta: 'Sanidad',
                onTap: () async {
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => SanidadAplicarSheet(
                      animalId: animal.id,
                      lecheriaId: lecheriaId,
                      usuarioId: usuarioId,
                    ),
                  );
                  onCambio();
                },
              ),
              _BotonEvento(
                icono: Icons.favorite_outline,
                etiqueta: 'Celo / Monta / Insem.',
                onTap: () => _servicioDialog(context),
              ),
              _BotonEvento(
                icono: Icons.fact_check_outlined,
                etiqueta: 'Palpación',
                onTap: () => _palpacionDialog(context),
              ),
              if (animal.grupo == GrupoAnimal.enOrdeno)
                _BotonEvento(
                  icono: Icons.pause_circle_outline,
                  etiqueta: 'Secado',
                  onTap: () => _secadoDialog(context),
                ),
              if (animal.estadoReproductivo == EstadoReproductivo.preniada)
                _BotonEvento(
                  icono: Icons.child_friendly_outlined,
                  etiqueta: 'Parto',
                  onTap: () => _partoDialog(context),
                ),
              _BotonEvento(
                icono: Icons.swap_horiz,
                etiqueta: 'Cambiar de grupo',
                onTap: () => _cambiarGrupoDialog(context),
              ),
              _BotonEvento(
                icono: Icons.grass_outlined,
                etiqueta: 'Concentrado',
                onTap: () => _concentradoDialog(context),
              ),
              _BotonEvento(
                icono: Icons.remove_circle_outline,
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
      builder: (_) => SimpleDialog(
        title: const Text('Tipo de servicio'),
        children: [
          for (final t in [
            TipoEventoAnimal.celo,
            TipoEventoAnimal.monta,
            TipoEventoAnimal.inseminacion,
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, t),
              child: Text(TipoEventoAnimal.etiqueta(t)),
            ),
        ],
      ),
    );
    if (tipo == null || !context.mounted) return;

    final toroCtrl = TextEditingController();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(TipoEventoAnimal.etiqueta(tipo)),
        content: TextField(
          controller: toroCtrl,
          decoration: const InputDecoration(
            labelText: 'Toro / pajilla (opcional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    await eventosRepo.registrarServicio(
      animalId: animal.id,
      lecheriaId: lecheriaId,
      tipo: tipo,
      toroPajilla: toroCtrl.text.trim().isEmpty ? null : toroCtrl.text.trim(),
      registradoPor: usuarioId,
    );
    onCambio();
  }

  Future<void> _palpacionDialog(BuildContext context) async {
    String resultado = ResultadoPalpacion.preniada;
    DateTime fechaProbableParto = DateTime.now().add(const Duration(days: 283));
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Palpación / diagnóstico'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: [
                  for (final r in ResultadoPalpacion.todos)
                    ButtonSegment(
                      value: r,
                      label: Text(ResultadoPalpacion.etiqueta(r)),
                    ),
                ],
                selected: {resultado},
                onSelectionChanged: (s) => setState(() => resultado = s.first),
              ),
              if (resultado == ResultadoPalpacion.preniada) ...[
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fecha probable de parto'),
                  subtitle: Text(
                    '${fechaProbableParto.day}/${fechaProbableParto.month}/${fechaProbableParto.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final elegida = await showDatePicker(
                      context: dialogContext,
                      initialDate: fechaProbableParto,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 400)),
                    );
                    if (elegida != null) {
                      setState(() => fechaProbableParto = elegida);
                    }
                  },
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
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (confirmado != true) return;
    await eventosRepo.registrarPalpacion(
      animalId: animal.id,
      lecheriaId: lecheriaId,
      resultado: resultado,
      fechaProbableParto: resultado == ResultadoPalpacion.preniada
          ? fechaProbableParto
          : null,
      registradoPor: usuarioId,
    );
    onCambio();
  }

  Future<void> _secadoDialog(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Secado'),
        content: Text(
          '¿Marcar a ${animal.identificador} como seca? Pasará al grupo Secas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    await eventosRepo.registrarSecado(
      animalId: animal.id,
      lecheriaId: lecheriaId,
      registradoPor: usuarioId,
    );
    onCambio();
  }

  Future<void> _partoDialog(BuildContext context) async {
    String sexoCria = Sexo.hembra;
    final identificadorCtrl = TextEditingController();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Parto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
    await eventosRepo.registrarParto(
      animalId: animal.id,
      lecheriaId: lecheriaId,
      sexoCria: sexoCria,
      identificadorCria: identificadorCtrl.text.trim().isEmpty
          ? null
          : identificadorCtrl.text.trim(),
      registradoPor: usuarioId,
    );
    onCambio();
  }

  Future<void> _cambiarGrupoDialog(BuildContext context) async {
    final nuevoGrupo = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Cambiar de grupo'),
        children: [
          for (final g in GrupoAnimal.todos)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, g),
              child: Text(GrupoAnimal.etiqueta(g)),
            ),
        ],
      ),
    );
    if (nuevoGrupo == null || nuevoGrupo == animal.grupo) return;
    await animalesRepo.cambiarGrupo(
      animalId: animal.id,
      lecheriaId: lecheriaId,
      nuevoGrupo: nuevoGrupo,
      registradoPor: usuarioId,
    );
    onCambio();
  }

  Future<void> _concentradoDialog(BuildContext context) async {
    final ctrl = TextEditingController(
      text: animal.concentradoKgDia.toStringAsFixed(1),
    );
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Concentrado (kg/día)'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Kg por día',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    final kg = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0;
    await animalesRepo.actualizarConcentrado(animalId: animal.id, kgDia: kg);
    onCambio();
  }

  Future<void> _bajaDialog(BuildContext context) async {
    String motivo = MotivoBaja.venta;
    final precioCtrl = TextEditingController();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Dar de baja'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
    await animalesRepo.registrarBaja(
      animalId: animal.id,
      lecheriaId: lecheriaId,
      motivo: motivo,
      precioVenta: double.tryParse(precioCtrl.text.replaceAll(',', '.')),
      registradoPor: usuarioId,
    );
    if (context.mounted) Navigator.of(context).maybePop();
    onCambio();
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

  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icono),
      label: Text(etiqueta, textAlign: TextAlign.center),
      style: FilledButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}

/// Hoja para dar de alta un animal nuevo (Módulo 1 y 2): identificador, sexo,
/// grupo y origen (comprado con precio/fecha, o nacido en la finca).
class _AltaAnimalSheet extends StatefulWidget {
  const _AltaAnimalSheet({required this.lecheriaId, this.identificadorInicial});

  final String lecheriaId;
  final String? identificadorInicial;

  @override
  State<_AltaAnimalSheet> createState() => _AltaAnimalSheetState();
}

class _AltaAnimalSheetState extends State<_AltaAnimalSheet> {
  late final TextEditingController _identCtrl = TextEditingController(
    text: widget.identificadorInicial,
  );
  final _precioCtrl = TextEditingController();
  String _sexo = Sexo.hembra;
  String _grupo = GrupoAnimal.enOrdeno;
  String _origen = OrigenAnimal.nacido;
  DateTime _fechaCompra = DateTime.now();
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _identCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final identificador = _identCtrl.text.trim();
    if (identificador.isEmpty) {
      setState(() => _error = 'Ingresá el identificador');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await animalesRepo.altaAnimal(
        lecheriaId: widget.lecheriaId,
        identificador: identificador,
        sexo: _sexo,
        grupo: _grupo,
        origen: _origen,
        precioCompra: _origen == OrigenAnimal.comprado
            ? double.tryParse(_precioCtrl.text.replaceAll(',', '.'))
            : null,
        fechaCompra: _origen == OrigenAnimal.comprado ? _fechaCompra : null,
      );
      sincronizarSiSePuede();
      if (mounted) Navigator.pop(context, true);
    } on AnimalDuplicadoException {
      setState(() {
        _error = 'Ya existe un animal activo con ese identificador';
        _guardando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo guardar: $e';
        _guardando = false;
      });
    }
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
              'Registrar animal nuevo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('trabajo.alta.identificador'),
              controller: _identCtrl,
              decoration: const InputDecoration(
                labelText: 'Identificador',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text('Sexo', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                for (final s in Sexo.todos)
                  ButtonSegment(
                    value: s,
                    label: KeyedSubtree(
                      key: ValueKey(
                        s == Sexo.hembra
                            ? 'trabajo.alta.sexoHembra'
                            : 'trabajo.alta.sexoMacho',
                      ),
                      child: Text(Sexo.etiqueta(s)),
                    ),
                  ),
              ],
              selected: {_sexo},
              onSelectionChanged: (s) => setState(() => _sexo = s.first),
            ),
            const SizedBox(height: 16),
            Text('Grupo', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              key: const ValueKey('trabajo.alta.grupo'),
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final g in GrupoAnimal.altaDisponibles)
                  ChoiceChip(
                    key: ValueKey('trabajo.alta.grupo.$g'),
                    label: Text(GrupoAnimal.etiqueta(g)),
                    selected: _grupo == g,
                    onSelected: (_) => setState(() => _grupo = g),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Origen', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                for (final o in OrigenAnimal.todos)
                  ButtonSegment(
                    value: o,
                    label: KeyedSubtree(
                      key: ValueKey(
                        o == OrigenAnimal.nacido
                            ? 'trabajo.alta.origenNacido'
                            : 'trabajo.alta.origenComprado',
                      ),
                      child: Text(OrigenAnimal.etiqueta(o)),
                    ),
                  ),
              ],
              selected: {_origen},
              onSelectionChanged: (s) => setState(() => _origen = s.first),
            ),
            if (_origen == OrigenAnimal.comprado) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _precioCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Precio de compra',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha de compra'),
                subtitle: Text(
                  '${_fechaCompra.day}/${_fechaCompra.month}/${_fechaCompra.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final elegida = await showDatePicker(
                    context: context,
                    initialDate: _fechaCompra,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (elegida != null) setState(() => _fechaCompra = elegida);
                },
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              key: const ValueKey('trabajo.alta.guardar'),
              onPressed: _guardando ? null : _guardar,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _guardando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
