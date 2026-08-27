import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/domain/grupos.dart';
import '../data/domain/palpacion.dart';

/// La hoja de vacas por palpar, para llevarla al corral o mandarla al
/// veterinario por WhatsApp.
///
/// Está armada igual que la de la dieta de concentrado: una fila por vaca, y
/// en papel se sostiene sola —lleva el nombre de la finca, con qué criterio se
/// hizo y la fecha—, de modo que una hoja vieja no se confunda con la de hoy.
/// Eso importa más acá que en la dieta: la lista cambia todos los días.
///
/// El azul de la marca va repetido y no importado de `theme.dart` porque es un
/// `PdfColor`, no un `Color` de Flutter: son dos tipos distintos.
const _azulLeche = PdfColor.fromInt(0xFF082850);

/// La tabla se parte en varias páginas sola cuando la lista no cabe en una.
Future<Uint8List> construirPdfPalpacion({
  required String nombreLecheria,
  required List<VacaPorPalpar> vacas,
  required DateTime generadoEl,
}) async {
  final doc = pw.Document(title: 'Vacas por palpar', author: 'LecheControl');

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 28),
      header: (context) => context.pageNumber == 1
          ? pw.SizedBox()
          // De la segunda página en adelante se repite de qué finca es: la
          // hoja suelta tiene que decirlo.
          : pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Text(
                '$nombreLecheria · Vacas por palpar',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Página ${context.pageNumber} de ${context.pagesCount}',
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ),
      build: (context) => [
        _encabezado(
          nombreLecheria: nombreLecheria,
          vacas: vacas,
          generadoEl: generadoEl,
        ),
        pw.SizedBox(height: 14),
        _tabla(vacas),
        pw.SizedBox(height: 10),
        pw.Text(
          'Recién parida: parió hace $diasRevisionPosparto días o menos. '
          'Servida: se le anotó celo, monta o inseminación y todavía no se '
          'confirma la preñez. La columna Fecha es la del parto o la del '
          'servicio, según el motivo.',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _encabezado({
  required String nombreLecheria,
  required List<VacaPorPalpar> vacas,
  required DateTime generadoEl,
}) {
  final posparto = vacas
      .where((v) => v.motivo == MotivoPalpacion.posparto)
      .length;
  final servidas = vacas.length - posparto;

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Vacas por palpar',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: _azulLeche,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                nombreLecheria,
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
              ),
            ],
          ),
          pw.Text(
            _fechaLarga(generadoEl),
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey200,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(
          '${vacas.length} ${vacas.length == 1 ? 'vaca' : 'vacas'} · '
          '$posparto recién ${posparto == 1 ? 'parida' : 'paridas'} · '
          '$servidas ${servidas == 1 ? 'servida' : 'servidas'} sin confirmar',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
      ),
    ],
  );
}

pw.Widget _tabla(List<VacaPorPalpar> vacas) {
  const bordeGris = pw.BorderSide(color: PdfColors.grey400, width: 0.5);

  return pw.Table(
    border: const pw.TableBorder(
      horizontalInside: bordeGris,
      top: bordeGris,
      bottom: bordeGris,
    ),
    columnWidths: const {
      0: pw.FlexColumnWidth(1.6),
      1: pw.FlexColumnWidth(1.8),
      2: pw.FlexColumnWidth(1.2),
      3: pw.FlexColumnWidth(0.9),
      4: pw.FlexColumnWidth(2.4),
      5: pw.FlexColumnWidth(1.4),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _celdaEncabezado('Vaca', izquierda: true),
          _celdaEncabezado('Motivo', izquierda: true),
          _celdaEncabezado('Fecha'),
          _celdaEncabezado('Días'),
          _celdaEncabezado('Servicio', izquierda: true),
          _celdaEncabezado('Grupo', izquierda: true),
        ],
      ),
      for (final v in vacas)
        pw.TableRow(
          children: [
            _celda(v.identificador, izquierda: true, negrita: true),
            _celda(
              v.motivo.etiquetaCorta,
              izquierda: true,
              // El posparto tiene fecha de vencimiento —dos semanas y la vaca
              // sale sola de la lista—, así que se marca para que salte a la
              // vista entre las servidas.
              color: v.motivo == MotivoPalpacion.posparto
                  ? PdfColors.orange800
                  : null,
            ),
            _celda(_fechaCorta(v.fecha)),
            _celda('${v.dias}', negrita: true),
            _celda(
              v.detalleServicio.isEmpty ? '—' : v.detalleServicio,
              izquierda: true,
            ),
            _celda(GrupoAnimal.etiqueta(v.grupo), izquierda: true),
          ],
        ),
    ],
  );
}

pw.Widget _celdaEncabezado(String texto, {bool izquierda = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    child: pw.Text(
      texto,
      textAlign: izquierda ? pw.TextAlign.left : pw.TextAlign.right,
      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
    ),
  );
}

pw.Widget _celda(
  String texto, {
  bool izquierda = false,
  bool negrita = false,
  PdfColor? color,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    child: pw.Text(
      texto,
      textAlign: izquierda ? pw.TextAlign.left : pw.TextAlign.right,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: negrita ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color,
      ),
    ),
  );
}

String _fechaCorta(DateTime f) => '${f.day}/${f.month}';

String _fechaLarga(DateTime f) =>
    '${f.day}/${f.month}/${f.year} · ${_dosDigitos(f.hour)}:'
    '${_dosDigitos(f.minute)}';

String _dosDigitos(int n) => n.toString().padLeft(2, '0');
