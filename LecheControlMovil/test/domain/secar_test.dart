// Quién entra a Vacas por secar.
//
// La regla es corta pero tiene dos filos que importan más de lo que parece:
// la vaca **no se va sola** de la lista —solo la saca el secado— y la que se
// pasó de la fecha sigue adentro, de primera. Las dos cosas son el punto de la
// lista: si se fuera sola al pasarse, el aviso desaparecería justo cuando más
// hace falta.

import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/domain/grupos.dart';
import 'package:leche_control/data/domain/secar.dart';

void main() {
  final hoy = DateTime(2026, 9, 25);

  int? faltan({
    String grupo = GrupoAnimal.enOrdeno,
    String estado = EstadoReproductivo.preniada,
    DateTime? probable,
    int dias = diasParaSecarPorDefecto,
  }) => diasQueFaltanParaSecar(
    grupo: grupo,
    estadoReproductivo: estado,
    fechaProbableParto: probable,
    diasParaSecar: dias,
    hoy: hoy,
  );

  group('quién entra', () {
    test('entra el día que le faltan 65 para parir', () {
      expect(faltan(probable: hoy.add(const Duration(days: 65))), 65);
    });

    test('un día antes de eso todavía no', () {
      expect(faltan(probable: hoy.add(const Duration(days: 66))), isNull);
    });

    test('la finca manda: con 80 configurados, la de 70 entra', () {
      // El número no es de la app, es de la finca. Con el período seco más
      // largo la misma vaca entra antes, y esa es toda la gracia de poder
      // configurarlo.
      final probable = hoy.add(const Duration(days: 70));
      expect(faltan(probable: probable), isNull);
      expect(faltan(probable: probable, dias: 80), 70);
    });

    test('cuanto más cerca del parto, menos días', () {
      expect(faltan(probable: hoy.add(const Duration(days: 12))), 12);
    });

    test('la que pare hoy sigue adentro', () {
      expect(faltan(probable: hoy), 0);
    });

    test('la que se pasó de la fecha NO se va: queda en negativo', () {
      // Es la más urgente de todas. Si desapareciera al pasarse, el aviso se
      // apagaría justo cuando la vaca está por parir dando leche.
      expect(faltan(probable: hoy.subtract(const Duration(days: 8))), -8);
    });
  });

  group('quién no entra', () {
    test('la que ya está seca', () {
      // Es lo único que la saca de la lista, y es lo que hace que sirva.
      expect(
        faltan(
          grupo: GrupoAnimal.secas,
          probable: hoy.add(const Duration(days: 30)),
        ),
        isNull,
      );
    });

    test('la que no está preñada', () {
      expect(
        faltan(
          estado: EstadoReproductivo.vacia,
          probable: hoy.add(const Duration(days: 30)),
        ),
        isNull,
      );
    });

    test('la preñada sin fecha probable', () {
      // No hay de dónde contar. A esa lo que le corresponde es palparla.
      expect(faltan(probable: null), isNull);
    });

    test('la de estado desconocido', () {
      expect(
        faltan(
          estado: EstadoReproductivo.desconocido,
          probable: hoy.add(const Duration(days: 30)),
        ),
        isNull,
      );
    });
  });

  group('la tarjeta', () {
    VacaPorSecar vaca(int dias, {double? litros}) => VacaPorSecar(
      animalId: 'a1',
      identificador: '1542',
      alias: null,
      grupo: GrupoAnimal.enOrdeno,
      diasParaParir: dias,
      diasLactancia: 250,
      ultimaProduccion: litros,
    );

    test('los días que faltan, con la leche de la última pesa', () {
      final v = vaca(30, litros: 12.4);
      expect(v.cifra, '30');
      expect(
        v.resumen,
        'le faltan 30 días para parir · 12.4 L en la última pesa',
      );
      expect(v.pasadaDeFecha, isFalse);
    });

    test('sin pesas, solo los días', () {
      expect(vaca(30).resumen, 'le faltan 30 días para parir');
    });

    test('la que pare hoy lo dice con todas las letras', () {
      expect(vaca(0).resumen, 'pare hoy');
      expect(vaca(1).resumen, 'pare mañana');
    });

    test('la pasada de fecha se marca y el número lleva el más', () {
      final v = vaca(-8);
      expect(v.pasadaDeFecha, isTrue);
      expect(v.cifra, '+8');
      expect(v.resumen, 'se pasó 8 días de la fecha de parto');
    });
  });

  test('el orden: primero la que se pasó, después la más cercana', () {
    final lista = [vacaCon('A', 40), vacaCon('B', -5), vacaCon('C', 12)]
      ..sort(compararPorSecar);
    expect(lista.map((v) => v.identificador), ['B', 'C', 'A']);
  });
}

VacaPorSecar vacaCon(String id, int dias) => VacaPorSecar(
  animalId: id,
  identificador: id,
  alias: null,
  grupo: GrupoAnimal.enOrdeno,
  diasParaParir: dias,
  diasLactancia: null,
  ultimaProduccion: null,
);
