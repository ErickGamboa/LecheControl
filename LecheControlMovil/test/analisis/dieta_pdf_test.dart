import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/analisis/dieta_pdf.dart';
import 'package:leche_control/data/domain/dieta_concentrado.dart';

/// El PDF se manda por WhatsApp, así que un archivo corrupto no se descubre
/// hasta que el destinatario no lo puede abrir. Acá se prueba que salga un PDF
/// de verdad y que los casos raros no lo revienten.
void main() {
  RacionVaca racion(
    String id, {
    double litros = 18,
    double? actual = 4,
    bool manual = false,
  }) => RacionVaca(
    identificador: id,
    esManual: manual,
    litrosLeche: litros,
    fechaPesa: DateTime(2026, 8, 17),
    concentradoActualKg: actual,
    racionKg: racionConcentrado(litrosLeche: litros, kgLechePorKg: 3),
  );

  Future<List<int>> pdf(List<RacionVaca> raciones) => construirPdfDieta(
    nombreLecheria: 'Lechería Erick',
    kgLechePorKg: 3,
    raciones: raciones,
    generadoEl: DateTime(2026, 8, 19, 7, 5),
  );

  test('genera un PDF válido', () async {
    final bytes = await pdf([racion('1'), racion('2', litros: 25, actual: 6)]);

    // La firma de todo PDF. Si esto falla, el archivo no abre en ningún lado.
    expect(latin1.decode(bytes.take(4).toList()), '%PDF');
    expect(bytes.length, greaterThan(1000));
  });

  test('no revienta sin vacas', () async {
    // Se puede tocar compartir en una finca que todavía no pesó.
    final bytes = await pdf([]);
    expect(latin1.decode(bytes.take(4).toList()), '%PDF');
  });

  test('aguanta una vaca sin concentrado anotado', () async {
    final bytes = await pdf([racion('1', actual: null)]);
    expect(latin1.decode(bytes.take(4).toList()), '%PDF');
  });

  test('aguanta vacas manuales y acentos', () async {
    // La fuente por defecto del PDF no tiene todos los caracteres; los
    // acentos del español sí, y conviene que un cambio de fuente lo rompa acá
    // antes que en el teléfono del ganadero.
    final bytes = await pdf([racion('77 ñ', manual: true)]);
    expect(latin1.decode(bytes.take(4).toList()), '%PDF');
  });

  test('un hato grande sale en varias páginas sin fallar', () async {
    final muchas = [
      for (var i = 1; i <= 120; i++) racion('$i', litros: 10 + (i % 20)),
    ];
    final bytes = await pdf(muchas);
    expect(latin1.decode(bytes.take(4).toList()), '%PDF');
    // Con 120 vacas la tabla no cabe en una hoja: el documento tiene que
    // crecer, no recortarse.
    expect(bytes.length, greaterThan(4000));
  });
}
