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

  group('el alias', () {
    test('la vaca aparece buscando por su alias', () {
      // El caso de todos los días: la 1542 es «la 99» en la finca.
      final c = coincidenciaDe('1542', '99', '99');
      expect(c?.calce, CalceArete.exacto);
      expect(c?.porAlias, isTrue, reason: 'hay que poder decir por qué salió');
    });

    test('también a pedazos, como el arete', () {
      final c = coincidenciaDe('1542', 'Pinta', 'pin');
      expect(c?.calce, CalceArete.empiezaCon);
      expect(c?.porAlias, isTrue);
    });

    test('si pega el arete, no se marca como alias', () {
      final c = coincidenciaDe('1542', '99', '42');
      expect(c?.calce, CalceArete.terminaEn);
      expect(c?.porAlias, isFalse);
    });

    test('pegando los dos, manda el calce más fuerte', () {
      // El alias es exacto y el arete solo contiene: gana el alias.
      final c = coincidenciaDe('1990', '99', '99');
      expect(c?.calce, CalceArete.exacto);
      expect(c?.porAlias, isTrue);
    });

    test('empatados, manda el arete', () {
      // Los dos exactos. El arete es el dato oficial y va primero.
      final c = coincidenciaDe('99', '99', '99');
      expect(c?.porAlias, isFalse);
    });

    test('sin alias, se busca solo por arete', () {
      expect(coincidenciaDe('1542', null, '99'), isNull);
    });

    test('lo que no pega por ninguno de los dos, no pega', () {
      expect(coincidenciaDe('1542', 'Pinta', '777'), isNull);
    });
  });

  group('el orden con alias', () {
    (String, CoincidenciaAnimal) par(String id, String? alias, String texto) {
      final c = coincidenciaDe(id, alias, texto)!;
      return (c.porAlias ? alias! : id, c);
    }

    test('el que pegó por arete va antes que el que pegó por alias', () {
      // Las dos son exactas: la del arete 99 antes que la que se llama 99.
      final lista = [par('1542', '99', '99'), par('99', null, '99')]
        ..sort(compararCoincidencia);
      expect(lista.first.$2.porAlias, isFalse);
    });
  });
}
