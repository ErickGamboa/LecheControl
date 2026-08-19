import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../data/domain/dieta_concentrado.dart';
import 'dieta_pdf.dart';

/// Previsualización del PDF de la dieta.
///
/// Se abre acá en vez de mandar el archivo de una porque muchas veces alcanza
/// con **ver la hoja y tomarle una captura** para pasarla por WhatsApp, sin
/// pasar por el compartir del sistema. El que sí quiera el archivo lo tiene en
/// el botón de compartir de esta misma pantalla.
///
/// El preview de `printing` rasteriza el PDF con el motor del sistema, así que
/// se ve igual en Android y en iOS.
class DietaPreviaPdfScreen extends StatelessWidget {
  const DietaPreviaPdfScreen({
    super.key,
    required this.nombreLecheria,
    required this.kgLechePorKg,
    required this.raciones,
    required this.generadoEl,
  });

  final String nombreLecheria;
  final double kgLechePorKg;
  final List<RacionVaca> raciones;

  /// Se recibe hecha y no se saca acá con `DateTime.now()`: el preview puede
  /// reconstruir el PDF varias veces (al rotar, al cambiar de hoja) y la fecha
  /// del encabezado no tiene por qué moverse en el camino.
  final DateTime generadoEl;

  String get _nombreArchivo =>
      'dieta-concentrado-${generadoEl.year}-'
      '${_dosDigitos(generadoEl.month)}-${_dosDigitos(generadoEl.day)}.pdf';

  static String _dosDigitos(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dieta en PDF')),
      body: PdfPreview(
        build: (formato) => construirPdfDieta(
          nombreLecheria: nombreLecheria,
          kgLechePorKg: kgLechePorKg,
          raciones: raciones,
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
        // Sin la marca de agua de "loading" encima ni relleno extra: la idea
        // es que la hoja se vea lo más grande posible para la captura.
        padding: const EdgeInsets.all(8),
        loadingWidget: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
