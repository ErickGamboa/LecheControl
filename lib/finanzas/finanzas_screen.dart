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
/// precio por litro sale de dividir lo que pagó la planta entre los litros
/// que pagó, y con ese precio real se reparte el ingreso entre las vacas.
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
                'litro (${resumen.litrosLeche.toStringAsFixed(0)} L).',
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
                            '${i.litros!.toStringAsFixed(0)} L',
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
    await finanzasRepo.agregarIngreso(
      lecheriaId: widget.lecheriaId,
      semanaId: widget.semanaId,
      tipo: _tipo,
      monto: monto,
      litros: double.tryParse(_litrosCtrl.text.trim().replaceAll(',', '.')),
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
                labelText: 'Litros que pagaron',
                suffixText: 'L',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 6),
              Text(
                'Con los litros, la app saca el precio real por litro y '
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
    // Si escribió una categoría nueva, la próxima vez le sale como botón.
    await finanzasRepo.recordarCategoria(
      lecheriaId: widget.lecheriaId,
      nombre: categoria,
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
            StreamBuilder<List<CategoriaGastoRow>>(
              stream: finanzasRepo.observarCategorias(widget.lecheriaId),
              builder: (context, snap) {
                final categorias = snap.data ?? const <CategoriaGastoRow>[];
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in categorias)
                      ChoiceChip(
                        key: ValueKey('finanzas.gasto.cat.${c.nombre}'),
                        label: Text(c.nombre),
                        selected: _categoriaCtrl.text == c.nombre,
                        onSelected: (_) =>
                            setState(() => _categoriaCtrl.text = c.nombre),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('finanzas.gasto.categoria'),
              controller: _categoriaCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'En qué se gastó',
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
