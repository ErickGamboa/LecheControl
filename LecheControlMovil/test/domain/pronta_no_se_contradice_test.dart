// "En ordeño · Vacía · Pronta · pasada de fecha" apareció en pantalla en una
// finca de verdad: tres estados, dos de ellos peleados. Pronta se deducía solo
// de la fecha probable de parto, sin mirar nunca si la vaca figuraba preñada.

import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/domain/grupos.dart';

void main() {
  final hoy = DateTime(2026, 9, 15);
  final enOchoDias = DateTime(2026, 9, 23);
  final haceDoceDias = DateTime(2026, 9, 3);

  group('esPronta', () {
    test('la preñada con fecha cerca sí está pronta', () {
      expect(
        esPronta(
          enOchoDias,
          estadoReproductivo: EstadoReproductivo.preniada,
          hoy: hoy,
        ),
        isTrue,
      );
    });

    test('la preñada pasada de fecha sigue pronta: todavía no parió', () {
      expect(
        esPronta(
          haceDoceDias,
          estadoReproductivo: EstadoReproductivo.preniada,
          hoy: hoy,
        ),
        isTrue,
      );
    });

    test('la vacía con una fecha vieja encima NO está pronta', () {
      // Es el caso de la 542117: parió, quedó vacía, y la fecha probable del
      // parto anterior se quedó pegada en la ficha.
      expect(
        esPronta(
          haceDoceDias,
          estadoReproductivo: EstadoReproductivo.vacia,
          hoy: hoy,
        ),
        isFalse,
      );
    });

    test('la de preñez desconocida tampoco', () {
      expect(
        esPronta(
          enOchoDias,
          estadoReproductivo: EstadoReproductivo.desconocido,
          hoy: hoy,
        ),
        isFalse,
      );
    });

    test('sin estado se sigue comportando como antes', () {
      expect(esPronta(enOchoDias, hoy: hoy), isTrue);
    });
  });

  group('fichaReproductivaContradictoria', () {
    test('vacía con fecha de parto se contradice', () {
      expect(
        fichaReproductivaContradictoria(
          EstadoReproductivo.vacia,
          haceDoceDias,
        ),
        isTrue,
      );
    });

    test('preñada sin fecha también se contradice', () {
      // El caso espejo, que no se nota: la vaca desaparece de Prontas y de
      // los partos proyectados sin que nadie sepa por qué. Lo produce borrar
      // una palpación (`_deshacerPalpacion`).
      expect(
        fichaReproductivaContradictoria(EstadoReproductivo.preniada, null),
        isTrue,
      );
    });

    test('preñada con fecha está bien', () {
      expect(
        fichaReproductivaContradictoria(
          EstadoReproductivo.preniada,
          enOchoDias,
        ),
        isFalse,
      );
    });

    test('vacía sin fecha está bien: es la recién parida', () {
      expect(
        fichaReproductivaContradictoria(EstadoReproductivo.vacia, null),
        isFalse,
      );
    });
  });
}
