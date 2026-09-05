import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/domain/grupos.dart';
import '../data/domain/partos_proyectados.dart';

/// El calendario de partos en una hoja, para pegarla en la lechería o
/// mandarla por WhatsApp.
///
/// Está armada como la de vacas por palpar: se sostiene sola —lleva el nombre
/// de la finca, la fecha y con qué criterio se hizo—, porque una hoja de hace
/// tres meses ya no dice lo mismo que la de hoy.
///
/// El azul de la marca va repetido y no importado de `theme.dart` porque es un
/// `PdfColor`, no un `Color` de Flutter: son dos tipos distintos.
const _azulLeche = PdfColor.fromInt(0xFF082850);

/// Una sola tabla para los doce meses, con una banda gris por mes.
///
/// Se hizo así y no con una tabla por mes porque `MultiPage` parte una tabla
/// larga por filas sola: el mes que no cabe sigue en la página siguiente sin
/// que haya que calcular nada. Los meses sin partos también salen —que
/// noviembre venga vacío es justo lo que se viene a ver—.
Future<Uint8List> construirPdfPartos({
  required String nombreLecheria,
  required ProyeccionPartos proyeccion,
  required DateTime generadoEl,
}) async {
  final doc = pw.Document(title: 'Partos por mes', author: 'LecheControl');

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
                '$nombreLecheria · Partos por mes',
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
          proyeccion: proyeccion,
          generadoEl: generadoEl,
        ),
        pw.SizedBox(height: 14),
        _tabla(proyeccion, generadoEl),
        if (proyeccion.sinFecha.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          _aviso(
            '${proyeccion.sinFecha.length} '
            '${proyeccion.sinFecha.length == 1 ? 'preñada' : 'preñadas'} sin '
            'fecha de parto: ${proyeccion.sinFecha.join(', ')}. Están '
            'marcadas como preñadas pero no tienen fecha probable anotada ni '
            'un servicio del cual sacarla.',
          ),
        ],
        if (proyeccion.fueraDeRango.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          _aviso(
            '${proyeccion.fueraDeRango.length} con fecha más allá de los doce '
            'meses: '
            '${proyeccion.fueraDeRango.map((v) => '${v.identificador} '
                '(${_fechaCorta(v.fechaProbable)}/'
                '${v.fechaProbable.year})').join(', ')}. '
            'Casi siempre es una fecha mal digitada.',
          ),
        ],
        pw.SizedBox(height: 10),
        pw.Text(
          'La preñez se cuenta en $diasGestacion días (unos nueve meses). '
          'Confirmada: la fecha que anotó la palpación. Estimada: el último '
          'servicio más la gestación. Una vaca pasada de fecha sigue en el mes '
          'en curso hasta que se le registre el parto.',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _encabezado({
  required String nombreLecheria,
  required ProyeccionPartos proyeccion,
  required DateTime generadoEl,
}) {
  final pico = proyeccion.mesConMasPartos;

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
                'Partos por mes',
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
          '${proyeccion.totalPreniadas} '
          '${proyeccion.totalPreniadas == 1 ? 'vaca preñada' : 'vacas preñadas'}'
          ' · ${proyeccion.totalEnCalendario} en los próximos '
          '${proyeccion.meses.length} meses'
          '${pico == null ? '' : ' · más partos en ${pico.etiqueta} '
              '(${pico.cantidad})'}',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
      ),
    ],
  );
}

pw.Widget _tabla(ProyeccionPartos proyeccion, DateTime generadoEl) {
  const bordeGris = pw.BorderSide(color: PdfColors.grey400, width: 0.5);

  return pw.Table(
    border: const pw.TableBorder(
      horizontalInside: bordeGris,
      top: bordeGris,
      bottom: bordeGris,
    ),
    columnWidths: const {
      0: pw.FlexColumnWidth(1.1),
      1: pw.FlexColumnWidth(1.6),
      2: pw.FlexColumnWidth(1.3),
      3: pw.FlexColumnWidth(1.2),
      4: pw.FlexColumnWidth(1.3),
      5: pw.FlexColumnWidth(2.2),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _celdaEncabezado('Día'),
          _celdaEncabezado('Vaca', izquierda: true),
          _celdaEncabezado('Grupo', izquierda: true),
          _celdaEncabezado('Faltan'),
          _celdaEncabezado('Fecha', izquierda: true),
          _celdaEncabezado('Servicio', izquierda: true),
        ],
      ),
      for (final mes in proyeccion.meses) ...[
        _bandaDeMes(mes),
        for (final v in mes.vacas) _filaVaca(v, generadoEl),
      ],
    ],
  );
}

/// La banda que separa un mes del siguiente. Lleva el conteo al lado del
/// nombre para no tener que contar filas.
pw.TableRow _bandaDeMes(MesDePartos mes) {
  return pw.TableRow(
    decoration: _fondoDeMes(mes),
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Text(
          mes.etiqueta,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: mes.vacio ? PdfColors.grey600 : _azulLeche,
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Text(
          mes.vacio
              ? 'Sin partos'
              : '${mes.cantidad} ${mes.cantidad == 1 ? 'vaca' : 'vacas'}',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: mes.vacio ? pw.FontWeight.normal : pw.FontWeight.bold,
            color: mes.vacio ? PdfColors.grey600 : PdfColors.black,
          ),
        ),
      ),
      pw.SizedBox(),
      pw.SizedBox(),
      pw.SizedBox(),
      pw.SizedBox(),
    ],
  );
}

/// El fondo de la banda: los meses con partos se marcan más que los vacíos,
/// para que la hoja se recorra buscando los cargados.
pw.BoxDecoration _fondoDeMes(MesDePartos mes) => pw.BoxDecoration(
  color: mes.vacio ? PdfColors.grey100 : PdfColors.grey200,
);

pw.TableRow _filaVaca(VacaPorParir v, DateTime hoy) {
  final dias = v.dias(hoy: hoy);
  final pasada = dias < 0;

  return pw.TableRow(
    children: [
      _celda('${v.fechaProbable.day}', negrita: true),
      _celda(v.identificador, izquierda: true, negrita: true),
      _celda(GrupoAnimal.etiqueta(v.grupo), izquierda: true),
      _celda(
        pasada ? 'Pasada' : '$dias d',
        color: pasada ? PdfColors.red800 : null,
        negrita: pasada,
      ),
      _celda(
        v.origen.etiqueta,
        izquierda: true,
        color: v.origen == OrigenFechaParto.estimada
            ? PdfColors.orange800
            : null,
      ),
      _celda(
        // Raya corta y no raya larga: la fuente por defecto del PDF no tiene
        // el guion largo y la celda saldría en blanco.
        v.detalleServicio.isEmpty ? '-' : v.detalleServicio,
        izquierda: true,
      ),
    ],
  );
}

pw.Widget _aviso(String texto) => pw.Container(
  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
  decoration: pw.BoxDecoration(
    color: PdfColors.grey100,
    borderRadius: pw.BorderRadius.circular(4),
  ),
  child: pw.Text(
    texto,
    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
  ),
);

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
