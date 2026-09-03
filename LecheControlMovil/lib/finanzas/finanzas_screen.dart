import 'package:flutter/material.dart';

import '../app/formato.dart';
import '../app/theme.dart';
import '../app/widgets/quick_number_field.dart';
import '../data/domain/semana.dart';
import '../data/local/database.dart';
import '../data/repositories/finanzas_repository.dart';
import '../services.dart';

/// Finanzas de la semana (Módulos 4 y 5, fusionados). Se anota la plata que
/// entró —leche y venta de ganado— y la que salió —peón, concentrado,
/// medicamentos, cerca…— y la app muestra la utilidad de la semana.
///
/// Los ingresos **no se calculan**: se digita lo que efectivamente entró. El
/// precio por kilo sale de dividir lo que pagó la planta entre los kilos que
/// se le entregaron, y con ese precio real se reparte el ingreso entre las
/// vacas.
///
/// La leche se le entrega a la planta en kilos —así la pesa y así la paga—,
/// aunque en la finca se ordeñe y se anote en litros. La columna sigue
/// llamándose `litros` en la base para no forzar una migración; lo que se ve
/// en pantalla son kilos.
class FinanzasScreen extends StatefulWidget {
  const FinanzasScreen({super.key, required this.lecheriaId});

  final String lecheriaId;

  @override
  State<FinanzasScreen> createState() => _FinanzasScreenState();
}

class _FinanzasScreenState extends State<FinanzasScreen> {
  SemanaRow? _semana;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _abrirSemana(DateTime.now());
  }

  Future<void> _abrirSemana(DateTime fecha) async {
    setState(() => _cargando = true);
    final semana = await finanzasRepo.abrirSemana(
      lecheriaId: widget.lecheriaId,
      fecha: fecha,
    );
    if (!mounted) return;
    setState(() {
      _semana = semana;
      _cargando = false;
    });
  }

  void _cambiarSemana(int semanas) {
    final actual = _semana;
    if (actual == null) return;
    _abrirSemana(actual.fechaInicio.add(Duration(days: 7 * semanas)));
  }

  Future<void> _agregarIngreso() async {
    final semana = _semana;
    if (semana == null) return;
    final guardado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _IngresoSheet(lecheriaId: widget.lecheriaId, semanaId: semana.id),
    );
    if (guardado == true) sincronizarSiSePuede();
  }

  Future<void> _agregarGasto() async {
    final semana = _semana;
    if (semana == null) return;
    final guardado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _GastoSheet(lecheriaId: widget.lecheriaId, semanaId: semana.id),
    );
    if (guardado == true) sincronizarSiSePuede();
  }

  @override
  Widget build(BuildContext context) {
    final semana = _semana;
    if (_cargando || semana == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Finanzas')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Finanzas')),
      body: SafeArea(
        child: Column(
          children: [
            _SelectorSemana(
              semana: semana,
              onAnterior: () => _cambiarSemana(-1),
              onSiguiente: () => _cambiarSemana(1),
            ),
            Expanded(
              child: StreamBuilder<ResumenSemana>(
                stream: finanzasRepo.observarResumen(semana),
                builder: (context, snap) {
                  final resumen =
                      snap.data ??
                      ResumenSemana(
                        semana: semana,
                        ingresos: const [],
                        gastos: const [],
                      );
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _TarjetaUtilidad(resumen: resumen),
                      const SizedBox(height: 16),
                      _SeccionIngresos(
                        resumen: resumen,
                        onAgregar: _agregarIngreso,
                      ),
                      const SizedBox(height: 16),
                      _SeccionGastos(
                        resumen: resumen,
                        onAgregar: _agregarGasto,
                      ),
                      const SizedBox(height: 32),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectorSemana extends StatelessWidget {
  const _SelectorSemana({
    required this.semana,
    required this.onAnterior,
    required this.onSiguiente,
  });

  final SemanaRow semana;
  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;

  @override
  Widget build(BuildContext context) {
    final esActual = lunesDe(DateTime.now()) == semana.fechaInicio;
    return Container(
      color: kVerdeLeche.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('finanzas.semanaAnterior'),
            onPressed: onAnterior,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Semana anterior',
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  etiquetaSemana(semana.fechaInicio, semana.fechaFin),
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                Text(
                  esActual ? 'Esta semana' : '${semana.fechaInicio.year}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('finanzas.semanaSiguiente'),
            // No tiene sentido cargar plata de una semana que no pasó.
            onPressed: esActual ? null : onSiguiente,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Semana siguiente',
          ),
        ],
      ),
    );
  }
}

class _TarjetaUtilidad extends StatelessWidget {
  const _TarjetaUtilidad({required this.resumen});

  final ResumenSemana resumen;

  @override
  Widget build(BuildContext context) {
    final utilidad = resumen.utilidad;
    final positiva = utilidad >= 0;
    final color = positiva ? kVerdeLeche : Colors.red.shade700;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              positiva ? 'Ganancia de la semana' : 'Pérdida de la semana',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              colones(utilidad),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _Cifra(
                    etiqueta: 'Entró',
                    valor: colones(resumen.totalIngresos),
                    color: kVerdeLeche,
                  ),
                ),
                Expanded(
                  child: _Cifra(
                    etiqueta: 'Salió',
                    valor: colones(resumen.totalGastos),
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            if (resumen.precioRealPorLitro != null) ...[
              const SizedBox(height: 12),
              Text(
                'La planta pagó ${colones(resumen.precioRealPorLitro!)} por '
                'kilo (${resumen.litrosLeche.toStringAsFixed(0)} kg).',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra({
    required this.etiqueta,
    required this.valor,
    required this.color,
  });

  final String etiqueta;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(etiqueta, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(
          valor,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({
    required this.titulo,
    required this.textoBoton,
    required this.onAgregar,
    required this.hijo,
  });

  final String titulo;
  final String textoBoton;
  final VoidCallback onAgregar;
  final Widget hijo;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  titulo,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: onAgregar,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(textoBoton),
                ),
              ],
            ),
            hijo,
          ],
        ),
      ),
    );
  }
}

class _SeccionIngresos extends StatelessWidget {
  const _SeccionIngresos({required this.resumen, required this.onAgregar});

  final ResumenSemana resumen;
  final VoidCallback onAgregar;

  @override
  Widget build(BuildContext context) {
    return _Seccion(
      titulo: 'INGRESOS',
      textoBoton: 'Anotar',
      onAgregar: onAgregar,
      hijo: resumen.ingresos.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Todavía no anotaste plata que entró esta semana.'),
            )
          : Column(
              children: [
                for (final i in resumen.ingresos)
                  Dismissible(
                    key: ValueKey(i.id),
                    direction: DismissDirection.endToStart,
                    background: const _FondoBorrar(),
                    onDismissed: (_) async {
                      await finanzasRepo.eliminarIngreso(i.id);
                      sincronizarSiSePuede();
                    },
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(TipoIngreso.etiqueta(i.tipo)),
                      subtitle: Text(
                        [
                          if (i.litros != null)
                            '${i.litros!.toStringAsFixed(0)} kg',
                          if (i.detalle != null) i.detalle!,
                        ].join(' · '),
                      ),
                      trailing: Text(
                        colones(i.monto),
                        style: TextStyle(
                          color: kVerdeLeche,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _SeccionGastos extends StatelessWidget {
  const _SeccionGastos({required this.resumen, required this.onAgregar});

  final ResumenSemana resumen;
  final VoidCallback onAgregar;

  @override
  Widget build(BuildContext context) {
    return _Seccion(
      titulo: 'GASTOS',
      textoBoton: 'Anotar',
      onAgregar: onAgregar,
      hijo: resumen.gastos.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Todavía no anotaste gastos de esta semana.'),
            )
          : Column(
              children: [
                for (final g in resumen.gastos)
                  Dismissible(
                    key: ValueKey(g.id),
                    direction: DismissDirection.endToStart,
                    background: const _FondoBorrar(),
                    onDismissed: (_) async {
                      await finanzasRepo.eliminarGasto(g.id);
                      sincronizarSiSePuede();
                    },
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(g.categoria),
                      subtitle: g.detalle == null ? null : Text(g.detalle!),
                      trailing: Text(
                        colones(g.monto),
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (resumen.gastosPorCategoria.length > 1) ...[
                  const Divider(),
                  for (final c in resumen.gastosPorCategoria)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(child: Text(c.categoria)),
                          Text(
                            colones(c.monto),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}

class _FondoBorrar extends StatelessWidget {
  const _FondoBorrar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red.shade700,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 16),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }
}

// ------------------------------------------------------------------ sheets

class _IngresoSheet extends StatefulWidget {
  const _IngresoSheet({required this.lecheriaId, required this.semanaId});

  final String lecheriaId;
  final String semanaId;

  @override
  State<_IngresoSheet> createState() => _IngresoSheetState();
}

class _IngresoSheetState extends State<_IngresoSheet> {
  String _tipo = TipoIngreso.leche;
  final _montoCtrl = TextEditingController();
  final _litrosCtrl = TextEditingController();
  final _detalleCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _montoCtrl.dispose();
    _litrosCtrl.dispose();
    _detalleCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final monto = double.tryParse(_montoCtrl.text.trim().replaceAll(',', '.'));
    if (monto == null || monto <= 0) {
      setState(() => _error = 'Poné cuánta plata entró.');
      return;
    }
    final kg = double.tryParse(_litrosCtrl.text.trim().replaceAll(',', '.'));

    if (!await _confirmarSiPasaElTope(kg)) return;

    await finanzasRepo.agregarIngreso(
      lecheriaId: widget.lecheriaId,
      semanaId: widget.semanaId,
      tipo: _tipo,
      monto: monto,
      litros: kg,
      detalle: _detalleCtrl.text,
    );
    if (mounted) Navigator.pop(context, true);
  }

  /// Avisa si esta entrega hace que la semana pase el tope de kilos de la
  /// finca. Devuelve si hay que seguir guardando.
  ///
  /// El tope se mide contra **el acumulado de la semana**, no contra la
  /// entrega suelta: la planta puede pagar en dos tandas y lo que castiga es
  /// el total. Y avisa, no bloquea — los kilos entregados son un hecho, la app
  /// no está para negarlos sino para que nadie se lleve la sorpresa al cobrar.
  Future<bool> _confirmarSiPasaElTope(double? kgNuevos) async {
    if (_tipo != TipoIngreso.leche || kgNuevos == null || kgNuevos <= 0) {
      return true;
    }
    final tope = await curvaRepo.topeKgLecheDe(widget.lecheriaId);
    if (tope == null || tope <= 0) return true;

    final yaAnotados = await finanzasRepo.kgLecheDeSemana(widget.semanaId);
    final total = yaAnotados + kgNuevos;
    if (total <= tope) return true;

    // Lo que se pasa es del total de la semana contra el tope, no de esta
    // entrega sola: si la semana ya venía pasada, el exceso arrastra lo de
    // antes, que es justo lo que la planta va a castigar.
    final exceso = total - tope;

    if (!mounted) return false;
    final seguir = await showDialog<bool>(
      context: context,
      // Con el contexto del diálogo, no el de la pantalla: ver la nota en
      // `trabajo_screen.dart`. Con el de la pantalla, en la versión de
      // escritorio se cierra la sección en vez del diálogo.
      builder: (contextoDialogo) => AlertDialog(
        key: const ValueKey('finanzas.ingreso.alertaTope'),
        icon: const Icon(Icons.warning_amber_rounded),
        title: const Text('Se pasa del tope'),
        content: Text(
          'Con esta entrega la semana llega a ${_kg(total)} kg y el tope de la '
          'finca es ${_kg(tope)} kg.\n\n'
          'Son ${_kg(exceso)} kg de más. A la planta le pueden castigar el '
          'precio de esos kilos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contextoDialogo, false),
            child: const Text('Revisar'),
          ),
          FilledButton(
            key: const ValueKey('finanzas.ingreso.alertaTope.guardar'),
            onPressed: () => Navigator.pop(contextoDialogo, true),
            child: const Text('Guardar igual'),
          ),
        ],
      ),
    );
    return seguir == true;
  }

  static String _kg(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

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
              'Anotar un ingreso',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final t in TipoIngreso.todos)
                  ChoiceChip(
                    key: ValueKey('finanzas.ingreso.tipo.$t'),
                    label: Text(TipoIngreso.etiqueta(t)),
                    selected: _tipo == t,
                    onSelected: (_) => setState(() => _tipo = t),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            QuickNumberField(
              key: const ValueKey('finanzas.ingreso.monto'),
              controller: _montoCtrl,
              labelText: 'Cuánto entró',
              suffixText: '₡',
              autofocus: true,
              textInputAction: TextInputAction.next,
            ),
            if (_tipo == TipoIngreso.leche) ...[
              const SizedBox(height: 12),
              QuickNumberField(
                key: const ValueKey('finanzas.ingreso.litros'),
                controller: _litrosCtrl,
                labelText: 'Kilos entregados',
                suffixText: 'kg',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 6),
              Text(
                'Con los kilos, la app saca el precio real por kilo y '
                'reparte el ingreso entre las vacas.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _detalleCtrl,
              decoration: const InputDecoration(
                labelText: 'Detalle (opcional)',
                border: OutlineInputBorder(),
              ),
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
              key: const ValueKey('finanzas.ingreso.guardar'),
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

class _GastoSheet extends StatefulWidget {
  const _GastoSheet({required this.lecheriaId, required this.semanaId});

  final String lecheriaId;
  final String semanaId;

  @override
  State<_GastoSheet> createState() => _GastoSheetState();
}

class _GastoSheetState extends State<_GastoSheet> {
  final _categoriaCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _detalleCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _categoriaCtrl.dispose();
    _montoCtrl.dispose();
    _detalleCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final categoria = _categoriaCtrl.text.trim();
    if (categoria.isEmpty) {
      setState(() => _error = 'Elegí o escribí en qué se gastó.');
      return;
    }
    final monto = double.tryParse(_montoCtrl.text.trim().replaceAll(',', '.'));
    if (monto == null || monto <= 0) {
      setState(() => _error = 'Poné cuánto se gastó.');
      return;
    }
    await finanzasRepo.agregarGasto(
      lecheriaId: widget.lecheriaId,
      semanaId: widget.semanaId,
      categoria: categoria,
      monto: monto,
      detalle: _detalleCtrl.text,
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
              'Anotar un gasto',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // Los cinco gastos de todas las semanas, para tocar y seguir. La
            // compra de ganado no está: esa la anota sola la app cuando se
            // registra un animal comprado.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in CategoriaGasto.todos)
                  ChoiceChip(
                    key: ValueKey('finanzas.gasto.cat.$c'),
                    label: Text(c),
                    selected: _categoriaCtrl.text == c,
                    onSelected: (_) => setState(() => _categoriaCtrl.text = c),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Escape para lo que no cae en ninguno de los cinco (una cerca,
            // un repuesto). Se sigue pudiendo escribir, pero el camino
            // corto son los botones de arriba.
            TextField(
              key: const ValueKey('finanzas.gasto.categoria'),
              controller: _categoriaCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Otro (si no está en la lista)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            QuickNumberField(
              key: const ValueKey('finanzas.gasto.monto'),
              controller: _montoCtrl,
              labelText: 'Cuánto se gastó',
              suffixText: '₡',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detalleCtrl,
              decoration: const InputDecoration(
                labelText: 'Detalle (opcional)',
                border: OutlineInputBorder(),
              ),
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
              key: const ValueKey('finanzas.gasto.guardar'),
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
