import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/domain/dieta_concentrado.dart';

/// El PDF de la dieta de concentrado, para verlo en pantalla o mandarlo por
/// WhatsApp.
///
/// Es la misma tabla de la pantalla, pero en papel tiene que sostenerse sola:
/// lleva el nombre de la finca, la regla con la que se calculó y la fecha, de
/// modo que un PDF viejo no se confunda con el de hoy.
///
/// El azul de la marca va acá repetido y no importado de `theme.dart`
/// porque es un `PdfColor`, no un `Color` de Flutter: son dos tipos distintos.
const _azulLeche = PdfColor.fromInt(0xFF082850);

/// La tabla se parte en varias páginas sola cuando el hato no cabe en una.
Future<Uint8List> construirPdfDieta({
  required String nombreLecheria,
  required double kgLechePorKg,
  required List<RacionVaca> raciones,
  required DateTime generadoEl,
}) async {
  final doc = pw.Document(
    title: 'Dieta de concentrado',
    author: 'LecheControl',
  );

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
                '$nombreLecheria · Dieta de concentrado',
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
          kgLechePorKg: kgLechePorKg,
          generadoEl: generadoEl,
        ),
        pw.SizedBox(height: 14),
        _tabla(raciones),
        pw.SizedBox(height: 10),
        pw.Text(
          'Cada vaca sale con su última pesa, que puede ser de días distintos '
          '(ver la columna Pesa). Las marcadas con * se pesan sin estar en el '
          'inventario.',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _encabezado({
  required String nombreLecheria,
  required double kgLechePorKg,
  required DateTime generadoEl,
}) {
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
                'Dieta de concentrado',
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
          '1 kg de concentrado por cada ${_num(kgLechePorKg)} kg de leche',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
      ),
    ],
  );
}

pw.Widget _tabla(List<RacionVaca> raciones) {
  const bordeGris = pw.BorderSide(color: PdfColors.grey400, width: 0.5);

  return pw.Table(
    border: const pw.TableBorder(
      horizontalInside: bordeGris,
      top: bordeGris,
      bottom: bordeGris,
    ),
    columnWidths: const {
      0: pw.FlexColumnWidth(2),
      1: pw.FlexColumnWidth(1.6),
      2: pw.FlexColumnWidth(1.8),
      3: pw.FlexColumnWidth(1.6),
      4: pw.FlexColumnWidth(1.4),
      5: pw.FlexColumnWidth(1.4),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _celdaEncabezado('Vaca', izquierda: true),
          _celdaEncabezado('Leche'),
          _celdaEncabezado('Corresponde'),
          _celdaEncabezado('Recibe'),
          _celdaEncabezado('Dif.'),
          _celdaEncabezado('Pesa'),
        ],
      ),
      for (final r in raciones)
        pw.TableRow(
          children: [
            _celda(
              r.esManual ? '${r.identificador} *' : r.identificador,
              izquierda: true,
            ),
            _celda('${_num(r.litrosLeche)} L'),
            _celda(
              r.racionKg == null ? '—' : '${_num(r.racionKg!)} kg',
              negrita: true,
            ),
            _celda(
              r.concentradoActualKg == null
                  ? '—'
                  : '${_num(r.concentradoActualKg!)} kg',
            ),
            _celdaDiferencia(r.diferenciaKg),
            _celda(_fechaCorta(r.fechaPesa)),
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

/// Igual que en pantalla: naranja si le falta, azul si le sobra. En blanco y
/// negro el signo sigue diciendo de qué lado está.
pw.Widget _celdaDiferencia(double? diferencia) {
  if (diferencia == null) return _celda('—');
  if (diferencia.abs() < 0.05) return _celda('0');
  final falta = diferencia > 0;
  return _celda(
    '${falta ? '+' : '-'}${_num(diferencia.abs())}',
    negrita: true,
    color: falta ? PdfColors.orange800 : PdfColors.blue700,
  );
}

String _num(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

String _fechaCorta(DateTime f) => '${f.day}/${f.month}';

String _fechaLarga(DateTime f) =>
    '${f.day}/${f.month}/${f.year} · ${_dosDigitos(f.hour)}:'
    '${_dosDigitos(f.minute)}';

String _dosDigitos(int n) => n.toString().padLeft(2, '0');
