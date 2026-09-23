// Quién entra a Vacas por servir. Son dos puertas distintas —la vaca que
// parió y no volvió a preñarse, y la novilla que ya tiene edad— y lo que las
// hace comparables es el atraso: cuánto lleva cada una pudiendo servirse sin
// que nadie la sirviera.

import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/domain/grupos.dart';
import 'package:leche_control/data/domain/servir.dart';

void main() {
  final hoy = DateTime(2026, 8, 26);

  RazonServir? razon({
    String sexo = Sexo.hembra,
    DateTime? parto,
    DateTime? nacimiento,
    String estado = EstadoReproductivo.vacia,
  }) => razonDeServir(
    sexo: sexo,
    fechaUltimoParto: parto,
    fechaNacimiento: nacimiento,
    estadoReproductivo: estado,
    hoy: hoy,
  );

  group('meses de edad', () {
    test('cuenta por calendario, no dividiendo días entre 30', () {
      // Del 26 de mayo de 2025 al 26 de agosto de 2026 son 15 meses justos.
      expect(mesesDesde(DateTime(2025, 5, 26), hoy: hoy), 15);
    });

    test('un día antes del cumplemés todavía no cuenta', () {
      expect(mesesDesde(DateTime(2025, 5, 27), hoy: hoy), 14);
    });

    test('el día que cumple los 15 meses sale de la cuenta', () {
      expect(fechaPrimerServicio(DateTime(2025, 5, 26)), DateTime(2026, 8, 26));
    });
  });

  group('la edad en palabras', () {
    // Mientras el animal es joven se habla en meses, que es como se cuenta una
    // novilla. Pasados los dos años eso deja de servir: a un toro de monta
    // nadie le dice "56 meses".
    test('de un año y medio, en meses', () {
      expect(edadEnPalabras(18), '18 meses');
    });

    test('de un mes, en singular', () {
      expect(edadEnPalabras(1), '1 mes');
    });

    test('a los dos años cambia a años', () {
      expect(edadEnPalabras(24), '2 años');
    });

    test('los meses que sobran se dicen', () {
      expect(edadEnPalabras(56), '4 años y 8 meses');
    });

    test('un mes de sobra, en singular', () {
      expect(edadEnPalabras(25), '2 años y 1 mes');
    });
  });

  group('novilla primeriza', () {
    test('entra el día que cumple los 15 meses', () {
      final r = razon(nacimiento: DateTime(2025, 5, 26));
      expect(r?.motivo, MotivoServir.novillaPrimeriza);
      expect(r?.diasDeAtraso, 0);
    });

    test('un día antes todavía no', () {
      expect(razon(nacimiento: DateTime(2025, 5, 27)), isNull);
    });

    test('cuanto más pasa, más atraso acumula', () {
      final r = razon(nacimiento: DateTime(2025, 1, 26));
      expect(r?.motivo, MotivoServir.novillaPrimeriza);
      // Cumplió los 15 meses el 26 de abril de 2026: 122 días atrás.
      expect(r?.diasDeAtraso, 122);
    });

    test('sin fecha de nacimiento no entra', () {
      // No hay forma de saber si ya tiene edad, y meterla a ciegas sería
      // mandar a servir a una ternera.
      expect(razon(), isNull);
    });

    test('la preñada no entra aunque tenga edad', () {
      expect(
        razon(
          nacimiento: DateTime(2024, 1, 1),
          estado: EstadoReproductivo.preniada,
        ),
        isNull,
      );
    });

    test('un macho no entra por más viejo que sea', () {
      expect(razon(sexo: Sexo.macho, nacimiento: DateTime(2020, 1, 1)), isNull);
    });
  });

  group('vaca abierta', () {
    test('entra a los 50 días del parto, con cero de atraso', () {
      final r = razon(parto: DateTime(2026, 7, 7));
      expect(r?.motivo, MotivoServir.vacaAbierta);
      expect(r?.diasDeAtraso, 0);
    });

    test('a los 49 todavía no', () {
      expect(razon(parto: DateTime(2026, 7, 8)), isNull);
    });

    test('el parto manda sobre la fecha de nacimiento', () {
      // Una vaca que ya parió se mide desde el parto: que además se sepa
      // cuándo nació no la vuelve novilla.
      final r = razon(
        parto: DateTime(2026, 1, 1),
        nacimiento: DateTime(2022, 1, 1),
      );
      expect(r?.motivo, MotivoServir.vacaAbierta);
    });

    test('la recién parida con fecha de nacimiento tampoco entra', () {
      // Parió hace 10 días: está dentro del período de espera, y su edad no
      // tiene nada que ver.
      expect(
        razon(parto: DateTime(2026, 8, 16), nacimiento: DateTime(2022, 1, 1)),
        isNull,
      );
    });
  });

  group('la tarjeta', () {
    VacaPorServir animal(MotivoServir motivo) => VacaPorServir(
      animalId: 'a1',
      identificador: 'X',
      grupo: GrupoAnimal.novillas,
      estadoReproductivo: EstadoReproductivo.vacia,
      motivo: motivo,
      servicios: 1,
      diasDeAtraso: 10,
      diasLactancia: motivo == MotivoServir.vacaAbierta ? 60 : null,
      mesesEdad: motivo == MotivoServir.novillaPrimeriza ? 16 : null,
    );

    test('la vaca se mide en días de lactancia', () {
      final v = animal(MotivoServir.vacaAbierta);
      expect(v.cifra, '60');
      expect(v.resumen, '60 días de lactancia · 1 servicio');
    });

    test('la novilla se mide en meses de edad', () {
      final n = animal(MotivoServir.novillaPrimeriza);
      expect(n.cifra, '16m');
      expect(n.resumen, '16 meses de edad · 1 servicio');
    });
  });

  group('el orden', () {
    VacaPorServir conAtraso(String id, int atraso, MotivoServir motivo) =>
        VacaPorServir(
          animalId: id,
          identificador: id,
          grupo: GrupoAnimal.enOrdeno,
          estadoReproductivo: EstadoReproductivo.vacia,
          motivo: motivo,
          servicios: 0,
          diasDeAtraso: atraso,
          diasLactancia: 0,
          mesesEdad: 0,
        );

    test('manda el atraso, sin importar si es vaca o novilla', () {
      final lista = [
        conAtraso('A', 10, MotivoServir.vacaAbierta),
        conAtraso('B', 200, MotivoServir.novillaPrimeriza),
        conAtraso('C', 50, MotivoServir.vacaAbierta),
        conAtraso('D', 120, MotivoServir.novillaPrimeriza),
      ]..sort(compararPorServir);

      expect(lista.map((v) => v.identificador), ['B', 'D', 'C', 'A']);
    });
  });
}
