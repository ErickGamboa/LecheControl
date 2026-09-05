import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/analisis/partos_pdf.dart';
import 'package:leche_control/data/domain/grupos.dart';
import 'package:leche_control/data/domain/partos_proyectados.dart';

/// El PDF se manda por WhatsApp, así que un archivo corrupto no se descubre
/// hasta que el destinatario no lo puede abrir. Acá se prueba que salga un PDF
/// de verdad y que los casos raros no lo revienten.
void main() {
  final hoy = DateTime(2026, 9, 5);

  VacaPorParir vaca(
    String id,
    DateTime fecha, {
    OrigenFechaParto origen = OrigenFechaParto.confirmada,
    String? tipoServicio,
    String? toroPajilla,
  }) => VacaPorParir(
    animalId: 'id-$id',
    identificador: id,
    grupo: GrupoAnimal.secas,
    fechaProbable: fecha,
    origen: origen,
    tipoServicio: tipoServicio,
    toroPajilla: toroPajilla,
  );

  Future<List<int>> pdf(
    List<VacaPorParir> vacas, {
    List<String> sinFecha = const [],
  }) => construirPdfPartos(
    nombreLecheria: 'Lechería Erick',
    proyeccion: proyectarPartos(
      vacas: vacas,
      preniadasSinFecha: sinFecha,
      hoy: hoy,
    ),
    generadoEl: DateTime(2026, 9, 5, 7, 5),
  );

  test('genera un PDF válido', () async {
    final bytes = await pdf([
      vaca('1001', DateTime(2026, 10, 12)),
      vaca(
        '1002',
        DateTime(2027, 3, 2),
        origen: OrigenFechaParto.estimada,
        tipoServicio: TipoEventoAnimal.inseminacion,
        toroPajilla: 'Pajilla 44',
      ),
    ]);

    // La firma de todo PDF. Si esto falla, el archivo no abre en ningún lado.
    expect(latin1.decode(bytes.take(4).toList()), '%PDF');
    expect(bytes.length, greaterThan(1000));
  });

  test('no revienta sin preñadas', () async {
    // Se puede tocar compartir en una finca sin ninguna vaca preñada: la hoja
    // sale igual, con los doce meses vacíos.
    final bytes = await pdf([]);
    expect(latin1.decode(bytes.take(4).toList()), '%PDF');
  });

  test('aguanta las que se pasaron de fecha y las que no tienen', () async {
    final bytes = await pdf(
      [vaca('1001', DateTime(2026, 6, 1))],
      sinFecha: const ['1007', '1009'],
    );
    expect(latin1.decode(bytes.take(4).toList()), '%PDF');
  });

  test('aguanta la fecha rarísima que cae fuera del calendario', () async {
    final bytes = await pdf([vaca('1001', DateTime(2028, 1, 1))]);
    expect(latin1.decode(bytes.take(4).toList()), '%PDF');
  });

  test('aguanta acentos y nombres largos', () async {
    // La fuente por defecto del PDF no tiene todos los caracteres; los
    // acentos del español sí, y conviene que un cambio de fuente lo rompa acá
    // antes que en el teléfono del ganadero.
    final bytes = await pdf([
      vaca('Ñata 77 · Inseminación', DateTime(2026, 11, 3)),
    ]);
    expect(latin1.decode(bytes.take(4).toList()), '%PDF');
  });

  test('un hato grande sale en varias páginas sin fallar', () async {
    final muchas = [
      for (var i = 1; i <= 120; i++)
        vaca('$i', DateTime(2026, 9 + (i % 12), 1 + (i % 27))),
    ];
    final bytes = await pdf(muchas);
    expect(latin1.decode(bytes.take(4).toList()), '%PDF');
    // Con 120 vacas repartidas en doce meses la tabla no cabe en una hoja: el
    // documento tiene que crecer, no recortarse.
    expect(bytes.length, greaterThan(4000));
  });
}
