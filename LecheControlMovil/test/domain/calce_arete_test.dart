// Buscar un animal escribiendo un pedazo del arete. Lo que importa no es
// cuáles pegan —eso es un `contains` y no tiene gracia— sino en qué ORDEN se
// muestran: si el que buscaba tiene que leer una lista larga, le salía más
// rápido digitar el arete completo.

import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/domain/calce_arete.dart';

void main() {
  group('de qué forma pega', () {
    test('el arete completo es exacto', () {
      expect(calceDeArete('542117', '542117'), CalceArete.exacto);
    });

    test('los últimos números', () {
      expect(calceDeArete('542117', '117'), CalceArete.terminaEn);
    });

    test('los primeros', () {
      expect(calceDeArete('542117', '5421'), CalceArete.empiezaCon);
    });

    test('un pedazo del medio', () {
      expect(calceDeArete('542117', '211'), CalceArete.contiene);
    });

    test('lo que no está, no pega', () {
      expect(calceDeArete('542117', '999'), isNull);
    });

    test('sin nada escrito no pega nada', () {
      // Importa: con el campo vacío la lista no se llena con el hato entero.
      expect(calceDeArete('542117', ''), isNull);
      expect(calceDeArete('542117', '   '), isNull);
    });

    test('la letra del arete no obliga a acordarse de cómo se escribió', () {
      expect(calceDeArete('A-204', 'a-204'), CalceArete.exacto);
      expect(calceDeArete('A-204', '204'), CalceArete.terminaEn);
    });
  });

  group('el orden', () {
    test('manda el calce: exacto, final, principio, medio', () {
      final aretes = ['211999', '117', '5421170', '542117', '117542'];
      // '117'    -> exacto
      // '542117' -> termina en 117
      // '5421170'-> contiene 117
      // '117542' -> empieza con 117
      // '211999' -> no pega
      expect(aretesQuePegan(aretes, '117'), [
        '117',
        '542117',
        '117542',
        '5421170',
      ]);
    });

    test('entre iguales, primero el arete más corto', () {
      // El que escribió poco tenía poco que escribir: casi siempre buscaba
      // la vaca de arete corto. Los tres terminan en 30; el exacto va de
      // primero y los otros dos se ordenan por largo.
      expect(aretesQuePegan(['99930', '30', '4530'], '30'), [
        '30',
        '4530',
        '99930',
      ]);
    });

    test('y con el mismo largo, en orden', () {
      expect(aretesQuePegan(['4530', '1230'], '30'), ['1230', '4530']);
    });

    test('lo que no pega no aparece', () {
      expect(aretesQuePegan(['4101', '4102', '9001'], '41'), ['4101', '4102']);
    });

    test('sin nada escrito, lista vacía', () {
      expect(aretesQuePegan(['4101', '4102'], ''), isEmpty);
    });
  });
}
