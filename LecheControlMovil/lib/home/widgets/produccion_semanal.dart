import 'package:flutter/material.dart';

import '../../analisis/analisis_leche_screen.dart';
import '../../app/theme.dart';
import '../../data/repositories/pesas_repository.dart';
import '../../services.dart';
import 'linea_produccion.dart';

/// El gráfico de litros por semana, con su navegación al análisis de leche.
///
/// Vive aparte de `HomeScreen` porque lo usan dos distribuciones: el home del
/// teléfono y el tablero de escritorio de LecheControlWeb. Cuántas semanas se
/// consultan y a dónde lleva el toque se deciden una sola vez, acá.
class ProduccionSemanal extends StatelessWidget {
  const ProduccionSemanal({
    super.key,
    required this.lecheriaId,
    required this.nombreLecheria,
    this.altoGrafico = LineaProduccion.altoGraficoTelefono,
  });

  final String lecheriaId;
  final String nombreLecheria;

  /// Ver [LineaProduccion.altoGrafico]. Por omisión, el alto del teléfono.
  final double altoGrafico;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LecheSpacing.lg),
      child: StreamBuilder<List<SesionConTotales>>(
        // Un poco más que las semanas que se dibujan: puede haber pesas
        // vacías o una semana con dos, y no quiero que empujen a una real
        // fuera de la consulta.
        stream: pesasRepo.observarUltimasSesiones(lecheriaId, cuantas: 8),
        builder: (context, snap) {
          return LineaProduccion(
            key: const ValueKey('home.produccion'),
            puntos: armarSemanas(snap.data ?? const []),
            altoGrafico: altoGrafico,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AnalisisLecheScreen(
                  lecheriaId: lecheriaId,
                  nombreLecheria: nombreLecheria,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
