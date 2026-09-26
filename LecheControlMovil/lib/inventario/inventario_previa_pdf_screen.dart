import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../data/local/database.dart';
import 'inventario_pdf.dart';

/// Previsualización del inventario filtrado en PDF.
///
/// Igual que las otras previas de la app: se abre acá en vez de mandar el
/// archivo de una, porque muchas veces alcanza con ver la hoja y tomarle una
/// captura. El que quiera el archivo lo tiene en el botón de compartir.
class InventarioPreviaPdfScreen extends StatelessWidget {
  const InventarioPreviaPdfScreen({
    super.key,
    required this.nombreLecheria,
    required this.animales,
    required this.filtros,
    required this.generadoEl,
  });

  final String nombreLecheria;
  final List<AnimalRow> animales;

  /// Los filtros que estaban puestos, escritos. Van al encabezado del PDF.
  final String filtros;

  /// Se recibe hecha y no se saca acá con `DateTime.now()`: el preview puede
  /// reconstruir el PDF varias veces —al rotar, al cambiar de hoja— y la fecha
  /// del encabezado no tiene por qué moverse en el camino.
  final DateTime generadoEl;

  String get _nombreArchivo =>
      'inventario-${generadoEl.year}-'
      '${_dosDigitos(generadoEl.month)}-${_dosDigitos(generadoEl.day)}.pdf';

  static String _dosDigitos(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventario en PDF')),
      body: PdfPreview(
        build: (formato) => construirPdfInventario(
          nombreLecheria: nombreLecheria,
          animales: animales,
          filtros: filtros,
          generadoEl: generadoEl,
        ),
        pdfFileName: _nombreArchivo,
        allowSharing: true,
        allowPrinting: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        padding: const EdgeInsets.all(8),
        loadingWidget: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
