import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../data/domain/partos_proyectados.dart';
import 'partos_pdf.dart';

/// Previsualización del PDF del calendario de partos.
///
/// Igual que la de la dieta y la de palpación: se abre acá en vez de mandar el
/// archivo de una porque muchas veces alcanza con **ver la hoja y tomarle una
/// captura**. El que quiera el archivo lo tiene en el botón de compartir de
/// esta misma pantalla.
class PartosPreviaPdfScreen extends StatelessWidget {
  const PartosPreviaPdfScreen({
    super.key,
    required this.nombreLecheria,
    required this.proyeccion,
    required this.generadoEl,
  });

  final String nombreLecheria;
  final ProyeccionPartos proyeccion;

  /// Se recibe hecha y no se saca acá con `DateTime.now()`: el preview puede
  /// reconstruir el PDF varias veces (al rotar, al cambiar de hoja) y la fecha
  /// del encabezado no tiene por qué moverse en el camino.
  final DateTime generadoEl;

  String get _nombreArchivo =>
      'partos-por-mes-${generadoEl.year}-'
      '${_dosDigitos(generadoEl.month)}-${_dosDigitos(generadoEl.day)}.pdf';

  static String _dosDigitos(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Partos en PDF')),
      body: PdfPreview(
        build: (formato) => construirPdfPartos(
          nombreLecheria: nombreLecheria,
          proyeccion: proyeccion,
          generadoEl: generadoEl,
        ),
        pdfFileName: _nombreArchivo,
        // Solo compartir. Imprimir no: en la finca no hay impresora, y el
        // botón junto al de compartir solo daba en qué equivocarse.
        allowSharing: true,
        allowPrinting: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        // Sin relleno extra: la idea es que la hoja se vea lo más grande
        // posible para la captura.
        padding: const EdgeInsets.all(8),
        loadingWidget: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
