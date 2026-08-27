// Quién entra a la lista de palpación decide a qué vacas revisa el
// veterinario cuando viene. Una vaca de más es un viaje perdido; una de menos
// es una preñez que nadie confirmó.

import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/domain/grupos.dart';
import 'package:leche_control/data/domain/palpacion.dart';

void main() {
  final hoy = DateTime(2026, 8, 26);

  RazonPalpacion? razon({
    DateTime? parto,
    DateTime? servicio,
    DateTime? palpacion,
    String estado = EstadoReproductivo.vacia,
  }) => razonDePalpacion(
    fechaUltimoParto: parto,
    fechaUltimoServicio: servicio,
    fechaUltimaPalpacion: palpacion,
    estadoReproductivo: estado,
    hoy: hoy,
  );

  group('recién paridas', () {
    test('entra la que parió dentro de la ventana', () {
      expect(
        razon(parto: DateTime(2026, 8, 22))?.motivo,
        MotivoPalpacion.posparto,
      );
    });

    test('el último día de la ventana todavía entra', () {
      // 15 días justos: 11 de agosto.
      expect(
        razon(parto: DateTime(2026, 8, 11))?.motivo,
        MotivoPalpacion.posparto,
      );
    });

    test('un día después ya no entra', () {
      expect(razon(parto: DateTime(2026, 8, 10)), isNull);
    });

    test('una vaca vieja de parida y sin servicio no entra', () {
      expect(razon(parto: DateTime(2026, 3, 1)), isNull);
    });

    test('el posparto manda sobre un servicio viejo', () {
      // Se sirvió, quedó preñada y parió: el servicio de antes del parto ya
      // cumplió. Lo que toca ahora es la revisión de posparto.
      final r = razon(
        parto: DateTime(2026, 8, 22),
        servicio: DateTime(2025, 11, 10),
      );
      expect(r?.motivo, MotivoPalpacion.posparto);
      expect(r?.fecha, DateTime(2026, 8, 22));
    });
  });

  group('servidas sin confirmar', () {
    test('entra la servida después del parto y sin palpar', () {
      final r = razon(
        parto: DateTime(2026, 4, 1),
        servicio: DateTime(2026, 7, 10),
      );
      expect(r?.motivo, MotivoPalpacion.servidaSinConfirmar);
      expect(r?.fecha, DateTime(2026, 7, 10));
    });

    test('una preñada confirmada no se palpa', () {
      expect(
        razon(
          parto: DateTime(2026, 4, 1),
          servicio: DateTime(2026, 7, 10),
          estado: EstadoReproductivo.preniada,
        ),
        isNull,
      );
    });

    test('un servicio anterior al último parto no cuenta', () {
      // Ese servicio terminó en el parto de mayo. Sin esta regla la vaca
      // quedaría clavada en la lista para siempre.
      expect(
        razon(parto: DateTime(2026, 5, 20), servicio: DateTime(2025, 8, 10)),
        isNull,
      );
    });

    test('si ya se palpó después del servicio, el trabajo está hecho', () {
      expect(
        razon(
          parto: DateTime(2026, 4, 1),
          servicio: DateTime(2026, 7, 10),
          palpacion: DateTime(2026, 8, 20),
        ),
        isNull,
      );
    });

    test('una palpación anterior al servicio no la saca', () {
      // La palparon en junio, la volvieron a servir en julio: hay que palpar
      // de nuevo.
      final r = razon(
        parto: DateTime(2026, 4, 1),
        servicio: DateTime(2026, 7, 10),
        palpacion: DateTime(2026, 6, 15),
      );
      expect(r?.motivo, MotivoPalpacion.servidaSinConfirmar);
    });

    test('una novilla servida entra aunque nunca haya parido', () {
      final r = razon(servicio: DateTime(2026, 7, 10));
      expect(r?.motivo, MotivoPalpacion.servidaSinConfirmar);
    });

    test('una novilla sin servicio no entra', () {
      expect(razon(), isNull);
    });
  });

  group('orden de la lista', () {
    VacaPorPalpar vaca(String id, MotivoPalpacion motivo, int dias) =>
        VacaPorPalpar(
          animalId: id,
          identificador: id,
          grupo: GrupoAnimal.enOrdeno,
          estadoReproductivo: EstadoReproductivo.vacia,
          motivo: motivo,
          fecha: hoy.subtract(Duration(days: dias)),
          dias: dias,
        );

    test('primero las recién paridas y dentro manda la más atrasada', () {
      final lista = [
        vaca('A', MotivoPalpacion.servidaSinConfirmar, 30),
        vaca('B', MotivoPalpacion.posparto, 2),
        vaca('C', MotivoPalpacion.servidaSinConfirmar, 60),
        vaca('D', MotivoPalpacion.posparto, 12),
      ]..sort(compararPorPalpar);

      expect(lista.map((v) => v.identificador), ['D', 'B', 'C', 'A']);
    });
  });

  test('el detalle del servicio junta tipo y toro', () {
    final v = VacaPorPalpar(
      animalId: 'a1',
      identificador: '1001',
      grupo: GrupoAnimal.enOrdeno,
      estadoReproductivo: EstadoReproductivo.vacia,
      motivo: MotivoPalpacion.servidaSinConfirmar,
      fecha: hoy,
      dias: 0,
      tipoServicio: TipoEventoAnimal.inseminacion,
      toroPajilla: 'Pajilla 44',
    );
    expect(v.detalleServicio, 'Inseminación · Pajilla 44');
  });

  test('una recién parida no arrastra el servicio de la preñez anterior', () {
    final v = VacaPorPalpar(
      animalId: 'a1',
      identificador: '1001',
      grupo: GrupoAnimal.enOrdeno,
      estadoReproductivo: EstadoReproductivo.vacia,
      motivo: MotivoPalpacion.posparto,
      fecha: hoy,
      dias: 3,
    );
    expect(v.detalleServicio, isEmpty);
  });
}
