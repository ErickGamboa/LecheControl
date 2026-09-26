import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../app/etiqueta_animal.dart';
import '../data/domain/grupos.dart';
import '../data/local/database.dart';

/// El inventario filtrado, en papel.
///
/// Lo que se exporta es **exactamente lo que se está viendo**: los mismos
/// animales, en el mismo orden, con los filtros que estaban puestos. Por eso
/// el encabezado los escribe con todas las letras. Una hoja que dice «12
/// animales» sin decir de cuáles no sirve para nada dentro de un mes, y la
/// gracia de exportar es justamente poder guardarla o mandarla.
const _azulLeche = PdfColor.fromInt(0xFF082850);

Future<Uint8List> construirPdfInventario({
  required String nombreLecheria,
  required List<AnimalRow> animales,
  required String filtros,
  required DateTime generadoEl,
}) async {
  final doc = pw.Document(title: 'Inventario', author: 'LecheControl');

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 28),
      header: (context) => context.pageNumber == 1
          ? pw.SizedBox()
          : pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Text(
                '$nombreLecheria · Inventario',
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
          cuantos: animales.length,
          filtros: filtros,
          generadoEl: generadoEl,
        ),
        pw.SizedBox(height: 14),
        _tabla(animales),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _encabezado({
  required String nombreLecheria,
  required int cuantos,
  required String filtros,
  required DateTime generadoEl,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        nombreLecheria,
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
          color: _azulLeche,
        ),
      ),
      pw.SizedBox(height: 2),
      pw.Text(
        'Inventario · ${cuantos == 1 ? '1 animal' : '$cuantos animales'}',
        style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
      ),
      pw.SizedBox(height: 6),
      pw.Text(
        filtros,
        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
      ),
      pw.SizedBox(height: 2),
      pw.Text(
        'Generado el ${_fechaLarga(generadoEl)}',
        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
      ),
    ],
  );
}

pw.Widget _tabla(List<AnimalRow> animales) {
  return pw.TableHelper.fromTextArray(
    border: null,
    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
    cellHeight: 20,
    headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
    cellStyle: const pw.TextStyle(fontSize: 9),
    cellAlignments: {
      0: pw.Alignment.centerLeft,
      1: pw.Alignment.centerLeft,
      2: pw.Alignment.centerLeft,
      3: pw.Alignment.centerLeft,
      4: pw.Alignment.centerRight,
    },
    headers: ['Animal', 'Grupo', 'Sexo', 'Estado', 'Ingresó'],
    data: [
      for (final a in animales)
        [
          etiquetaAnimal(a.identificador, a.alias),
          GrupoAnimal.etiqueta(a.grupo),
          Sexo.etiqueta(a.sexo),
          a.estado == EstadoAnimal.activo
              ? EstadoReproductivo.etiqueta(a.estadoReproductivo)
              : EstadoAnimal.etiqueta(a.estado),
          _fechaCorta(a.createdAt),
        ],
    ],
    rowDecoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
    ),
  );
}

String _fechaCorta(DateTime f) => '${f.day}/${f.month}/${f.year}';

String _fechaLarga(DateTime f) =>
    '${f.day} de ${_meses[f.month - 1]} de ${f.year}, '
    '${f.hour.toString().padLeft(2, '0')}:'
    '${f.minute.toString().padLeft(2, '0')}';

const _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'setiembre',
  'octubre',
  'noviembre',
  'diciembre',
];
