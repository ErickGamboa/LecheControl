import 'package:flutter/material.dart';

import '../ajustes/curva_screen.dart';
import '../app/theme.dart';
import '../data/domain/curva_lactancia.dart';
import '../data/domain/semana.dart';
import '../data/repositories/reporte_repository.dart';
import '../services.dart';

/// Reporte general de producción lechera de una sesión de pesa (Módulo 3).
///
/// Es la versión para teléfono del reporte que trajo el cliente: los mismos
/// bloques, uno debajo del otro, con las tablas anchas desplazables de lado.
class ReporteScreen extends StatefulWidget {
  const ReporteScreen({
    super.key,
    required this.lecheriaId,
    required this.sesionId,
    required this.nombreLecheria,
  });

  final String lecheriaId;
  final String sesionId;
  final String nombreLecheria;

  @override
  State<ReporteScreen> createState() => _ReporteScreenState();
}

class _ReporteScreenState extends State<ReporteScreen> {
  late Future<ReporteProduccion> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = reporteRepo.generar(
      lecheriaId: widget.lecheriaId,
      sesionId: widget.sesionId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de producción'),
        actions: [
          IconButton(
            key: const ValueKey('reporte.ajustarCurva'),
            tooltip: 'Curva de referencia',
            icon: const Icon(Icons.tune),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CurvaScreen(lecheriaId: widget.lecheriaId),
                ),
              );
              // Cambiar la curva cambia todas las evaluaciones del reporte.
              if (mounted) {
                setState(() {
                  _futuro = reporteRepo.generar(
                    lecheriaId: widget.lecheriaId,
                    sesionId: widget.sesionId,
                  );
                });
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<ReporteProduccion>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No se pudo armar el reporte: ${snap.error}'),
              ),
            );
          }
          final r = snap.data!;
          if (r.filas.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Esta sesión no tiene ninguna vaca pesada todavía.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Cabecera(nombre: widget.nombreLecheria, fecha: r.fecha),
              const SizedBox(height: 16),
              if (r.curvaVacia) ...[
                const _AvisoSinCurva(),
                const SizedBox(height: 16),
              ],
              _ResumenGeneral(reporte: r),
              const SizedBox(height: 16),
              _ProduccionPorVaca(reporte: r),
              const SizedBox(height: 16),
              if (!r.curvaVacia) ...[
                _CurvaDeLactancia(reporte: r),
                const SizedBox(height: 16),
                _RankingSegunCurva(
                  titulo: 'Mejores vacas según la curva',
                  color: kVerdeLeche,
                  filas: r.mejoresSegunCurva(),
                  vacio: 'Ninguna vaca tiene días de lactancia cargados.',
                ),
                const SizedBox(height: 16),
                _RankingSegunCurva(
                  titulo: 'Vacas por debajo de lo esperado',
                  color: Colors.red.shade700,
                  filas: r.debajoDeLoEsperado(),
                  vacio: 'Ninguna vaca está por debajo de lo esperado.',
                ),
                const SizedBox(height: 16),
              ],
              _TopLitros(reporte: r),
              const SizedBox(height: 16),
              _DistribucionPorRango(reporte: r),
              const SizedBox(height: 16),
              _EstadoDelHato(reporte: r),
              if (!r.curvaVacia) ...[
                const SizedBox(height: 16),
                _Recomendaciones(reporte: r),
              ],
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- piezas

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.nombre, required this.fecha});

  final String nombre;
  final DateTime fecha;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(nombre, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 2),
        Text(
          'Pesa del ${_fechaCorta(fecha)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          'Semana del ${etiquetaSemana(lunesDe(fecha), domingoDe(fecha))}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _AvisoSinCurva extends StatelessWidget {
  const _AvisoSinCurva();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade700),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade900),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Esta lechería todavía no tiene curva de referencia cargada, '
              'así que no se puede comparar cada vaca contra lo esperado '
              'para sus días de lactancia.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.titulo, required this.hijo});

  final String titulo;
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
            Text(
              titulo,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            hijo,
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor, this.color});

  final String etiqueta;
  final String valor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(
          valor,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ResumenGeneral extends StatelessWidget {
  const _ResumenGeneral({required this.reporte});

  final ReporteProduccion reporte;

  @override
  Widget build(BuildContext context) {
    final h = reporte.hato;
    return _Tarjeta(
      titulo: 'RESUMEN GENERAL',
      hijo: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Dato(
                  etiqueta: 'Vacas registradas',
                  valor: '${h.totalRegistradas}',
                ),
              ),
              Expanded(
                child: _Dato(
                  etiqueta: 'En producción',
                  valor: '${h.enProduccion}',
                  color: kVerdeLeche,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Dato(
                  etiqueta: 'Secas o prontas',
                  valor: '${h.secas + h.prontasAlParto}',
                  color: Colors.orange.shade800,
                ),
              ),
              Expanded(
                child: _Dato(
                  etiqueta: 'Manuales',
                  valor: '${h.manuales}',
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: _Dato(
                  etiqueta: 'Producción total',
                  valor: '${reporte.produccionTotal.toStringAsFixed(1)} L',
                  color: kAzulLeche,
                ),
              ),
              Expanded(
                child: _Dato(
                  etiqueta: 'Concentrado',
                  valor: '${reporte.concentradoTotalKg.toStringAsFixed(1)} kg',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Dato(
                  etiqueta: 'Promedio general',
                  valor: reporte.promedioGeneral.toStringAsFixed(2),
                ),
              ),
              Expanded(
                child: _Dato(
                  etiqueta: 'Promedio por vaca pesada',
                  valor: reporte.promedioPorVacaPesada.toStringAsFixed(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'El promedio general reparte la leche entre todo el hato '
              '(${reporte.hato.totalRegistradas} vacas). El de la derecha, '
              'solo entre las ${reporte.vacasPesadas} que se pesaron.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProduccionPorVaca extends StatelessWidget {
  const _ProduccionPorVaca({required this.reporte});

  final ReporteProduccion reporte;

  @override
  Widget build(BuildContext context) {
    return _Tarjeta(
      titulo: 'PRODUCCIÓN POR VACA',
      hijo: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 18,
          headingRowHeight: 36,
          dataRowMinHeight: 34,
          dataRowMaxHeight: 40,
          columns: const [
            DataColumn(label: Text('Vaca')),
            DataColumn(label: Text('DLac'), numeric: true),
            DataColumn(label: Text('Mañana'), numeric: true),
            DataColumn(label: Text('Tarde'), numeric: true),
            DataColumn(label: Text('Total'), numeric: true),
            DataColumn(label: Text('Conc. kg'), numeric: true),
            DataColumn(label: Text('Anterior'), numeric: true),
            DataColumn(label: Text('Estado')),
          ],
          rows: [
            for (final f in reporte.filas)
              DataRow(
                cells: [
                  DataCell(
                    Text(
                      f.esManual ? '${f.identificador} *' : f.identificador,
                      style: TextStyle(
                        color: f.esManual ? Colors.blue.shade700 : null,
                      ),
                    ),
                  ),
                  DataCell(Text(f.diasLactancia?.toString() ?? '—')),
                  DataCell(Text(_num(f.litrosManana))),
                  DataCell(Text(_num(f.litrosTarde))),
                  DataCell(
                    Text(
                      f.total.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(Text(_num(f.concentradoKg))),
                  DataCell(Text(_num(f.anterior))),
                  DataCell(_EtiquetaEvaluacion(evaluacion: f.evaluacion)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _EtiquetaEvaluacion extends StatelessWidget {
  const _EtiquetaEvaluacion({required this.evaluacion});

  final EvaluacionVaca? evaluacion;

  static Color colorDe(EvaluacionVaca e) => switch (e) {
    EvaluacionVaca.excelente => Colors.green.shade700,
    EvaluacionVaca.bueno => Colors.lightGreen.shade800,
    EvaluacionVaca.vigilar => Colors.orange.shade800,
    EvaluacionVaca.bajo => Colors.deepOrange.shade700,
    EvaluacionVaca.muyBajo => Colors.red.shade700,
  };

  @override
  Widget build(BuildContext context) {
    final e = evaluacion;
    if (e == null) {
      return Text('Sin DLac', style: Theme.of(context).textTheme.bodySmall);
    }
    return Text(
      e.etiqueta,
      style: TextStyle(color: colorDe(e), fontWeight: FontWeight.bold),
    );
  }
}

/// Curva ideal contra el promedio real del hato, tramo por tramo. En vez del
/// gráfico de líneas del reporte original —ilegible en un teléfono— se
/// muestran dos barras por tramo, que dicen lo mismo de un vistazo.
class _CurvaDeLactancia extends StatelessWidget {
  const _CurvaDeLactancia({required this.reporte});

  final ReporteProduccion reporte;

  @override
  Widget build(BuildContext context) {
    final maximo = reporte.curvaHato.fold<double>(0, (m, p) {
      final hato = p.promedioHato ?? 0;
      final ideal = p.tramo.litrosEsperados;
      return [m, hato, ideal].reduce((a, b) => a > b ? a : b);
    });

    return _Tarjeta(
      titulo: 'CURVA DE LACTANCIA — REFERENCIA VS HATO',
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final p in reporte.curvaHato) ...[
            _FilaCurva(punto: p, maximo: maximo == 0 ? 1 : maximo),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              _Leyenda(color: Colors.grey.shade400, texto: 'Referencia'),
              const SizedBox(width: 16),
              _Leyenda(color: kAzulLeche, texto: 'Tu hato'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Los tramos sin ninguna vaca quedan en blanco.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _FilaCurva extends StatelessWidget {
  const _FilaCurva({required this.punto, required this.maximo});

  final PuntoCurvaHato punto;
  final double maximo;

  @override
  Widget build(BuildContext context) {
    final t = punto.tramo;
    final rango = t.diaHasta == null
        ? '> ${t.diaDesde - 1} d'
        : '${t.diaDesde}-${t.diaHasta} d';
    final hato = punto.promedioHato;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(rango, style: Theme.of(context).textTheme.bodySmall),
            Text(
              hato == null
                  ? '${t.litrosEsperados.toStringAsFixed(1)} L · sin vacas'
                  : '${hato.toStringAsFixed(1)} L de '
                        '${t.litrosEsperados.toStringAsFixed(1)} L · '
                        '${punto.vacas} vaca${punto.vacas == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 3),
        _Barra(
          valor: t.litrosEsperados,
          maximo: maximo,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 2),
        _Barra(valor: hato ?? 0, maximo: maximo, color: kAzulLeche),
      ],
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({
    required this.valor,
    required this.maximo,
    required this.color,
  });

  final double valor;
  final double maximo;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final ancho = (valor / maximo).clamp(0.0, 1.0) * restricciones.maxWidth;
        return Container(
          height: 8,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Container(
            width: ancho,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda({required this.color, required this.texto});

  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(texto, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _RankingSegunCurva extends StatelessWidget {
  const _RankingSegunCurva({
    required this.titulo,
    required this.color,
    required this.filas,
    required this.vacio,
  });

  final String titulo;
  final Color color;
  final List<FilaReporte> filas;
  final String vacio;

  @override
  Widget build(BuildContext context) {
    return _Tarjeta(
      titulo: titulo.toUpperCase(),
      hijo: filas.isEmpty
          ? Text(vacio, style: Theme.of(context).textTheme.bodySmall)
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 18,
                headingRowHeight: 36,
                dataRowMinHeight: 34,
                dataRowMaxHeight: 40,
                columns: const [
                  DataColumn(label: Text('Vaca')),
                  DataColumn(label: Text('DLac'), numeric: true),
                  DataColumn(label: Text('Dio'), numeric: true),
                  DataColumn(label: Text('Esperado'), numeric: true),
                  DataColumn(label: Text('%'), numeric: true),
                  DataColumn(label: Text('Evaluación')),
                ],
                rows: [
                  for (final f in filas)
                    DataRow(
                      cells: [
                        DataCell(Text(f.identificador)),
                        DataCell(Text('${f.diasLactancia}')),
                        DataCell(
                          Text(
                            f.total.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(Text(f.esperado!.toStringAsFixed(1))),
                        DataCell(
                          Text(
                            '${f.porcentajeDelEsperado!.toStringAsFixed(0)} %',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DataCell(_EtiquetaEvaluacion(evaluacion: f.evaluacion)),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}

class _TopLitros extends StatelessWidget {
  const _TopLitros({required this.reporte});

  final ReporteProduccion reporte;

  @override
  Widget build(BuildContext context) {
    return _Tarjeta(
      titulo: 'MAYOR Y MENOR PRODUCCIÓN',
      hijo: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _ListaTop(
              titulo: 'Mayor',
              color: kVerdeLeche,
              filas: reporte.topMayorProduccion(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ListaTop(
              titulo: 'Menor',
              color: Colors.red.shade700,
              filas: reporte.topMenorProduccion(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListaTop extends StatelessWidget {
  const _ListaTop({
    required this.titulo,
    required this.color,
    required this.filas,
  });

  final String titulo;
  final Color color;
  final List<FilaReporte> filas;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        for (final f in filas)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    f.esManual ? '${f.identificador} *' : f.identificador,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${f.total.toStringAsFixed(1)} L',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DistribucionPorRango extends StatelessWidget {
  const _DistribucionPorRango({required this.reporte});

  final ReporteProduccion reporte;

  static const _colores = {
    RangoProduccion.alta: Colors.green,
    RangoProduccion.media: Colors.blue,
    RangoProduccion.baja: Colors.orange,
    RangoProduccion.muyBaja: Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final dist = reporte.distribucionPorRango;
    final total = reporte.vacasPesadas;

    return _Tarjeta(
      titulo: 'DISTRIBUCIÓN POR RANGO',
      hijo: Column(
        children: [
          for (final rango in RangoProduccion.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _colores[rango],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(rango.etiqueta)),
                  Text('${dist[rango]}'),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 48,
                    child: Text(
                      total == 0
                          ? '—'
                          : '${(dist[rango]! / total * 100).toStringAsFixed(1)} %',
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total pesadas',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '$total',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              const SizedBox(
                width: 48,
                child: Text(
                  '100 %',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EstadoDelHato extends StatelessWidget {
  const _EstadoDelHato({required this.reporte});

  final ReporteProduccion reporte;

  @override
  Widget build(BuildContext context) {
    final h = reporte.hato;
    final total = h.totalRegistradas;
    final filas = <(String, int)>[
      ('En producción', h.enProduccion),
      ('Secas', h.secas),
      ('Prontas al parto', h.prontasAlParto),
      ('Manuales', h.manuales),
    ];

    return _Tarjeta(
      titulo: 'ESTADO DEL HATO',
      hijo: Column(
        children: [
          for (final (etiqueta, cantidad) in filas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(child: Text(etiqueta)),
                  Text('$cantidad'),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 48,
                    child: Text(
                      total == 0
                          ? '—'
                          : '${(cantidad / total * 100).toStringAsFixed(1)} %',
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '$total',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 60),
            ],
          ),
        ],
      ),
    );
  }
}

class _Recomendaciones extends StatelessWidget {
  const _Recomendaciones({required this.reporte});

  final ReporteProduccion reporte;

  static Color colorDe(RecomendacionVaca r) => switch (r) {
    RecomendacionVaca.mantener => Colors.green.shade700,
    RecomendacionVaca.vigilar => Colors.orange.shade800,
    RecomendacionVaca.revisar => Colors.red.shade700,
  };

  @override
  Widget build(BuildContext context) {
    final conteo = reporte.recomendaciones;
    return _Tarjeta(
      titulo: 'RECOMENDACIONES',
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final r in RecomendacionVaca.values) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colorDe(r),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${r.titulo} — ${conteo[r]} '
                        'vaca${conteo[r] == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: colorDe(r),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        r.descripcion,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

String _num(double? v) => v == null ? '—' : v.toStringAsFixed(1);

String _fechaCorta(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';
