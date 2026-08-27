import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../data/domain/dieta_concentrado.dart';
import '../services.dart';
import 'dieta_previa_pdf_screen.dart';

/// Dieta de concentrado (Módulo 6): cuánto concentrado le toca a cada vaca.
///
/// La ración sale de **su** última pesa, no de la última pesa de la finca: la
/// vaca que no se pesó esta semana entra con la de la anterior en vez de
/// quedarse sin ración. Por eso cada fila muestra de qué día viene.
///
/// Al lado de la ración va lo que **ya se le está dando**, que la pesa guarda
/// junto con los litros. Sin esa columna la pantalla diría qué hacer sin decir
/// qué está pasando, y corregir la dieta obligaría a ir y volver al reporte.
class DietaConcentradoScreen extends StatefulWidget {
  const DietaConcentradoScreen({
    super.key,
    required this.lecheriaId,
    required this.nombreLecheria,
  });

  final String lecheriaId;

  /// Va en el encabezado del PDF: la hoja tiene que decir de qué finca es.
  final String nombreLecheria;

  @override
  State<DietaConcentradoScreen> createState() => _DietaConcentradoScreenState();
}

class _DietaConcentradoScreenState extends State<DietaConcentradoScreen> {
  late Future<({double kgLechePorKg, List<RacionVaca> raciones})> _futuro;
  bool _exportando = false;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<({double kgLechePorKg, List<RacionVaca> raciones})> _cargar() async {
    final kg = await curvaRepo.kgLechePorKgConcentradoDe(widget.lecheriaId);
    final raciones = await pesasRepo.dietaConcentrado(
      widget.lecheriaId,
      kgLechePorKg: kg,
    );
    return (kgLechePorKg: kg, raciones: raciones);
  }

  /// Abre la hoja en PDF para verla. Desde ahí se comparte, o se le toma una
  /// captura y listo.
  Future<void> _verPdf() async {
    if (_exportando) return;
    setState(() => _exportando = true);
    try {
      final datos = await _futuro;
      if (!mounted) return;
      if (datos.raciones.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todavía no hay dieta que exportar.')),
        );
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DietaPreviaPdfScreen(
            nombreLecheria: widget.nombreLecheria,
            kgLechePorKg: datos.kgLechePorKg,
            raciones: datos.raciones,
            generadoEl: DateTime.now(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dieta de concentrado'),
        actions: [
          IconButton(
            key: const ValueKey('dieta.verPdf'),
            tooltip: 'Ver en PDF',
            onPressed: _exportando ? null : _verPdf,
            icon: _exportando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child:
            FutureBuilder<({double kgLechePorKg, List<RacionVaca> raciones})>(
              future: _futuro,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final kgLechePorKg = snap.data!.kgLechePorKg;
                final raciones = snap.data!.raciones;

                if (raciones.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Todavía no hay pesas de vacas en ordeño. La dieta '
                        'sale de lo que dio cada vaca en su última pesa.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(LecheSpacing.md),
                  children: [
                    _Regla(kgLechePorKg: kgLechePorKg, raciones: raciones),
                    const SizedBox(height: LecheSpacing.md),
                    _Tabla(raciones: raciones),
                    const SizedBox(height: LecheSpacing.sm),
                    Text(
                      'Cada vaca sale con su última pesa, que puede ser de '
                      'días distintos. Las marcadas con * se pesan sin estar '
                      'en el inventario.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                );
              },
            ),
      ),
    );
  }
}

/// La regla vigente y el total de concentrado que pide el hato.
class _Regla extends StatelessWidget {
  const _Regla({required this.kgLechePorKg, required this.raciones});

  final double kgLechePorKg;
  final List<RacionVaca> raciones;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalRacion = raciones.fold<double>(
      0,
      (a, r) => a + (r.racionKg ?? 0),
    );
    final totalActual = raciones.fold<double>(
      0,
      (a, r) => a + (r.concentradoActualKg ?? 0),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LecheSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1 kg de concentrado por cada '
              '${_num(kgLechePorKg)} kg de leche',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: LecheSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _Dato(
                    etiqueta: 'Le corresponde al hato',
                    valor: '${_num(totalRacion)} kg',
                  ),
                ),
                Expanded(
                  child: _Dato(
                    etiqueta: 'Está recibiendo',
                    valor: totalActual == 0 ? '—' : '${_num(totalActual)} kg',
                  ),
                ),
              ],
            ),
            const SizedBox(height: LecheSpacing.xs),
            Text(
              '${raciones.length} vacas en ordeño con pesa.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          valor,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          etiqueta,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
      ],
    );
  }
}

class _Tabla extends StatelessWidget {
  const _Tabla({required this.raciones});

  final List<RacionVaca> raciones;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 18,
          headingRowHeight: 36,
          dataRowMinHeight: 34,
          dataRowMaxHeight: 40,
          columns: const [
            DataColumn(label: Text('Vaca')),
            DataColumn(label: Text('Leche'), numeric: true),
            DataColumn(label: Text('Corresponde'), numeric: true),
            DataColumn(label: Text('Recibe'), numeric: true),
            DataColumn(label: Text('Dif.'), numeric: true),
            DataColumn(label: Text('Pesa')),
          ],
          rows: [
            for (final r in raciones)
              DataRow(
                cells: [
                  DataCell(
                    Text(
                      r.esManual ? '${r.identificador} *' : r.identificador,
                      style: TextStyle(
                        color: r.esManual ? Colors.blue.shade700 : null,
                      ),
                    ),
                  ),
                  DataCell(Text('${_num(r.litrosLeche)} L')),
                  DataCell(
                    Text(
                      r.racionKg == null ? '—' : '${_num(r.racionKg!)} kg',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(
                    Text(
                      r.concentradoActualKg == null
                          ? '—'
                          : '${_num(r.concentradoActualKg!)} kg',
                    ),
                  ),
                  DataCell(_CeldaFalta(diferencia: r.diferenciaKg)),
                  DataCell(Text(_fecha(r.fechaPesa))),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Cuánto concentrado le falta o le sobra a la vaca.
///
/// Naranja si le falta y azul si le sobra, no verde/rojo: acá ninguno de los
/// dos lados es "bueno" — de menos produce menos, y de más es plata tirada.
class _CeldaFalta extends StatelessWidget {
  const _CeldaFalta({required this.diferencia});

  final double? diferencia;

  @override
  Widget build(BuildContext context) {
    final d = diferencia;
    if (d == null) return const Text('—');

    final theme = Theme.of(context);
    if (d.abs() < 0.05) {
      return Text('0.0', style: TextStyle(color: theme.hintColor));
    }

    final falta = d > 0;
    final oscuro = theme.brightness == Brightness.dark;
    final color = falta
        ? (oscuro ? Colors.orange.shade300 : Colors.orange.shade800)
        : (oscuro ? Colors.lightBlue.shade200 : Colors.blue.shade700);

    return Text(
      '${falta ? '+' : '-'}${_num(d.abs())}',
      style: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }
}

String _num(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

String _fecha(DateTime f) => '${f.day}/${f.month}';
