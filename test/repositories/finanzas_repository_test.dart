import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/domain/semana.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/data/repositories/finanzas_repository.dart';

import '../support/local_db_seed.dart';

void main() {
  group('semana', () {
    test('el lunes de una semana es el mismo para todos sus días', () {
      // Del lunes 10 al domingo 16 de agosto de 2026.
      final lunes = DateTime(2026, 8, 10);
      for (var i = 0; i < 7; i++) {
        expect(lunesDe(lunes.add(Duration(days: i))), lunes);
      }
      // El lunes siguiente ya es otra semana.
      expect(
        lunesDe(lunes.add(const Duration(days: 7))),
        DateTime(2026, 8, 17),
      );
    });

    test('el domingo cierra la semana', () {
      expect(domingoDe(DateTime(2026, 8, 12)), DateTime(2026, 8, 16));
    });

    test('ignora la hora del día', () {
      expect(lunesDe(DateTime(2026, 8, 12, 23, 59)), DateTime(2026, 8, 10));
    });

    test('la etiqueta dice el mes una sola vez si no cruza', () {
      expect(
        etiquetaSemana(DateTime(2026, 8, 10), DateTime(2026, 8, 16)),
        '10 - 16 de agosto',
      );
    });

    test('la etiqueta nombra los dos meses cuando cruza', () {
      expect(
        etiquetaSemana(DateTime(2026, 9, 28), DateTime(2026, 10, 4)),
        '28 de setiembre - 4 de octubre',
      );
    });
  });

  group('FinanzasRepository', () {
    late AppDatabase db;
    late FinanzasRepository repo;
    const lecheriaId = 'lecheria-1';
    final miercoles = DateTime(2026, 8, 12);

    setUp(() async {
      db = AppDatabase.forExecutor(NativeDatabase.memory());
      repo = FinanzasRepository(db);
      await seedCuentaLocal(db, usuarioId: 'user-1');
      await seedLecheria(db, usuarioId: 'user-1', lecheriaId: lecheriaId);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'abrirSemana reutiliza la semana en curso en vez de duplicar',
      () async {
        final lunes = await repo.abrirSemana(
          lecheriaId: lecheriaId,
          fecha: DateTime(2026, 8, 10),
        );
        final viernes = await repo.abrirSemana(
          lecheriaId: lecheriaId,
          fecha: DateTime(2026, 8, 14),
        );

        expect(viernes.id, lunes.id);
        expect(await db.select(db.semanas).get(), hasLength(1));
        expect(lunes.fechaInicio, DateTime(2026, 8, 10));
        expect(lunes.fechaFin, DateTime(2026, 8, 16));
      },
    );

    test('la utilidad es lo que entró menos lo que salió', () async {
      final semana = await repo.abrirSemana(
        lecheriaId: lecheriaId,
        fecha: miercoles,
      );
      await repo.agregarIngreso(
        lecheriaId: lecheriaId,
        semanaId: semana.id,
        tipo: TipoIngreso.leche,
        monto: 400000,
        litros: 1000,
      );
      await repo.agregarIngreso(
        lecheriaId: lecheriaId,
        semanaId: semana.id,
        tipo: TipoIngreso.ventaGanado,
        monto: 250000,
      );
      await repo.agregarGasto(
        lecheriaId: lecheriaId,
        semanaId: semana.id,
        categoria: 'Salario del peón',
        monto: 90000,
      );
      await repo.agregarGasto(
        lecheriaId: lecheriaId,
        semanaId: semana.id,
        categoria: 'Concentrado',
        monto: 160000,
      );

      final resumen = await repo.resumenDe(semana);

      expect(resumen.totalIngresos, 650000);
      expect(resumen.totalGastos, 250000);
      expect(resumen.utilidad, 400000);
    });

    test('la utilidad puede quedar negativa y se informa igual', () async {
      final semana = await repo.abrirSemana(
        lecheriaId: lecheriaId,
        fecha: miercoles,
      );
      await repo.agregarIngreso(
        lecheriaId: lecheriaId,
        semanaId: semana.id,
        tipo: TipoIngreso.leche,
        monto: 100000,
        litros: 250,
      );
      await repo.agregarGasto(
        lecheriaId: lecheriaId,
        semanaId: semana.id,
        categoria: 'Medicamentos',
        monto: 180000,
      );

      final resumen = await repo.resumenDe(semana);

      expect(resumen.utilidad, -80000);
    });

    test('el precio por litro sale de la plata que entró', () async {
      final semana = await repo.abrirSemana(
        lecheriaId: lecheriaId,
        fecha: miercoles,
      );
      await repo.agregarIngreso(
        lecheriaId: lecheriaId,
        semanaId: semana.id,
        tipo: TipoIngreso.leche,
        monto: 380000,
        litros: 1000,
      );

      final resumen = await repo.resumenDe(semana);

      expect(resumen.precioRealPorLitro, 380);
    });

    test('sin litros anotados no se inventa un precio', () async {
      final semana = await repo.abrirSemana(
        lecheriaId: lecheriaId,
        fecha: miercoles,
      );
      await repo.agregarIngreso(
        lecheriaId: lecheriaId,
        semanaId: semana.id,
        tipo: TipoIngreso.leche,
        monto: 380000,
      );

      expect((await repo.resumenDe(semana)).precioRealPorLitro, isNull);
    });

    test('la venta de ganado no ensucia el precio del litro', () async {
      final semana = await repo.abrirSemana(
        lecheriaId: lecheriaId,
        fecha: miercoles,
      );
      await repo.agregarIngreso(
        lecheriaId: lecheriaId,
        semanaId: semana.id,
        tipo: TipoIngreso.leche,
        monto: 380000,
        litros: 1000,
      );
      await repo.agregarIngreso(
        lecheriaId: lecheriaId,
        semanaId: semana.id,
        tipo: TipoIngreso.ventaGanado,
        monto: 500000,
        litros: 999, // se ignora: no es leche
      );

      final resumen = await repo.resumenDe(semana);

      expect(resumen.precioRealPorLitro, 380);
      expect(resumen.totalIngresos, 880000);
    });

    test('agrupa los gastos por categoría, de mayor a menor', () async {
      final semana = await repo.abrirSemana(
        lecheriaId: lecheriaId,
        fecha: miercoles,
      );
      await repo.agregarGasto(
        lecheriaId: lecheriaId,
        semanaId: semana.id,
        categoria: 'Concentrado',
        monto: 100000,
      );
      await repo.agregarGasto(
        lecheriaId: lecheriaId,
        semanaId: semana.id,
        categoria: 'Concentrado',
        monto: 60000,
      );
      await repo.agregarGasto(
        lecheriaId: lecheriaId,
        semanaId: semana.id,
        categoria: 'Cerca',
        monto: 25000,
      );

      final porCategoria = (await repo.resumenDe(semana)).gastosPorCategoria;

      expect(porCategoria.first.categoria, 'Concentrado');
      expect(porCategoria.first.monto, 160000);
      expect(porCategoria.last.categoria, 'Cerca');
    });

    test('un gasto borrado deja de sumar', () async {
      final semana = await repo.abrirSemana(
        lecheriaId: lecheriaId,
        fecha: miercoles,
      );
      await repo.agregarGasto(
        lecheriaId: lecheriaId,
        semanaId: semana.id,
        categoria: 'Cerca',
        monto: 25000,
      );
      final gasto = (await db.select(db.gastosSemana).get()).single;

      await repo.eliminarGasto(gasto.id);

      expect((await repo.resumenDe(semana)).totalGastos, 0);
    });

    test('recordarCategoria no duplica una que ya existe', () async {
      await repo.recordarCategoria(
        lecheriaId: lecheriaId,
        nombre: 'Veterinario',
      );
      await repo.recordarCategoria(
        lecheriaId: lecheriaId,
        nombre: 'Veterinario',
      );

      expect(await db.select(db.categoriasGasto).get(), hasLength(1));
    });
  });
}
