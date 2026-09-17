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

  group('paridas sin diagnóstico', () {
    test('la recién parida todavía no entra: se le da el margen', () {
      // 4 días. Está dentro de los 15 de gracia.
      expect(razon(parto: DateTime(2026, 8, 22)), isNull);
    });

    test('a los 15 días justos tampoco: el margen es completo', () {
      expect(razon(parto: DateTime(2026, 8, 11)), isNull);
    });

    test('pasados los 15 días entra', () {
      final r = razon(parto: DateTime(2026, 8, 10)); // 16 días
      expect(r?.motivo, MotivoPalpacion.paridaSinDiagnostico);
      expect(r?.fecha, DateTime(2026, 8, 10));
    });

    test('y no sale sola por más tiempo que pase', () {
      // Esto es lo que cambió: antes salía de la lista al día 16, hubiera
      // pasado el veterinario o no. Una vaca sin diagnosticar no deja de
      // necesitarlo porque se olvidó por más tiempo.
      expect(
        razon(parto: DateTime(2026, 3, 1))?.motivo,
        MotivoPalpacion.paridaSinDiagnostico,
      );
    });

    test('sale cuando se le registra el diagnóstico', () {
      expect(
        razon(parto: DateTime(2026, 3, 1), palpacion: DateTime(2026, 3, 20)),
        isNull,
      );
    });

    test('una palpación anterior al parto no cuenta como diagnóstico', () {
      // Es la que confirmó la preñez que terminó en ese parto.
      expect(
        razon(
          parto: DateTime(2026, 3, 1),
          palpacion: DateTime(2025, 9, 1),
        )?.motivo,
        MotivoPalpacion.paridaSinDiagnostico,
      );
    });

    test('la preñada confirmada no entra aunque parió hace meses', () {
      expect(
        razon(parto: DateTime(2026, 3, 1), estado: EstadoReproductivo.preniada),
        isNull,
      );
    });

    test('un servicio viejo de antes del parto no la salva de la lista', () {
      // Ese servicio ya cumplió: terminó en el parto. La vaca sigue sin
      // diagnóstico posterior.
      final r = razon(
        parto: DateTime(2026, 3, 1),
        servicio: DateTime(2025, 6, 10),
      );
      expect(r?.motivo, MotivoPalpacion.paridaSinDiagnostico);
      expect(r?.fecha, DateTime(2026, 3, 1));
    });

    test('si además está servida, manda el servicio', () {
      // Los dos motivos aplican; el servicio es el dato más útil porque dice
      // con qué se sirvió y hace cuánto.
      final r = razon(
        parto: DateTime(2026, 3, 1),
        servicio: DateTime(2026, 7, 10),
      );
      expect(r?.motivo, MotivoPalpacion.servidaSinConfirmar);
      expect(r?.fecha, DateTime(2026, 7, 10));
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

    test('un servicio anterior al último parto no cuenta como servicio', () {
      // Ese servicio terminó en el parto de mayo. Si contara, la vaca
      // quedaría clavada como "servida sin confirmar" para siempre. Entra
      // igual a la lista, pero por el otro motivo y con la fecha del parto.
      final r = razon(
        parto: DateTime(2026, 5, 20),
        servicio: DateTime(2025, 8, 10),
      );
      expect(r?.motivo, MotivoPalpacion.paridaSinDiagnostico);
      expect(r?.fecha, DateTime(2026, 5, 20));
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

    test('primero las servidas y dentro manda la más atrasada', () {
      final lista = [
        vaca('A', MotivoPalpacion.servidaSinConfirmar, 30),
        vaca('B', MotivoPalpacion.paridaSinDiagnostico, 20),
        vaca('C', MotivoPalpacion.servidaSinConfirmar, 60),
        vaca('D', MotivoPalpacion.paridaSinDiagnostico, 120),
      ]..sort(compararPorPalpar);

      expect(lista.map((v) => v.identificador), ['C', 'A', 'D', 'B']);
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

  test('una parida sin diagnóstico no arrastra el servicio anterior', () {
    final v = VacaPorPalpar(
      animalId: 'a1',
      identificador: '1001',
      grupo: GrupoAnimal.enOrdeno,
      estadoReproductivo: EstadoReproductivo.vacia,
      motivo: MotivoPalpacion.paridaSinDiagnostico,
      fecha: hoy,
      dias: 3,
    );
    expect(v.detalleServicio, isEmpty);
  });
}
