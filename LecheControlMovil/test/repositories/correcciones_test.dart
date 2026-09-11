import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/domain/grupos.dart';
import 'package:leche_control/data/domain/semana.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/data/repositories/animales_repository.dart';
import 'package:leche_control/data/repositories/eventos_repository.dart';
import 'package:leche_control/data/repositories/finanzas_repository.dart';
import 'package:leche_control/data/repositories/pesas_repository.dart';

import '../support/local_db_seed.dart';

/// Arreglar lo que se digitó mal: corregir y eliminar en las cinco tablas que
/// el ganadero llena a mano.
///
/// Lo que se prueba acá no es que la fila cambie —eso es un UPDATE— sino que
/// **lo que el dato arrastraba se vaya con él**: que borrar un parto le
/// devuelva el grupo a la vaca, que corregir el precio de un animal corrija el
/// gasto de Finanzas, que quitar una pesada devuelva la vaca a la lista de las
/// que faltan.
void main() {
  late AppDatabase db;
  late AnimalesRepository animales;
  late EventosRepository eventos;
  late FinanzasRepository finanzas;
  late PesasRepository pesas;
  const lecheriaId = 'lecheria-1';

  setUp(() async {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    finanzas = FinanzasRepository(db);
    animales = AnimalesRepository(db, finanzasRepository: finanzas);
    eventos = EventosRepository(db);
    pesas = PesasRepository(db);
    await seedCuentaLocal(db, usuarioId: 'user-1');
    await seedLecheria(db, usuarioId: 'user-1', lecheriaId: lecheriaId);
  });

  tearDown(() async {
    await db.close();
  });

  Future<SemanaRow> semana() =>
      finanzas.abrirSemana(lecheriaId: lecheriaId, fecha: DateTime(2026, 3, 4));

  group('finanzas', () {
    test('corregir un ingreso cambia lo digitado y lo deja pendiente', () async {
      final s = await semana();
      await finanzas.agregarIngreso(
        lecheriaId: lecheriaId,
        semanaId: s.id,
        tipo: TipoIngreso.leche,
        monto: 500000,
        litros: 1200,
      );
      final ingreso = await db.select(db.ingresosSemana).getSingle();

      await finanzas.editarIngreso(
        id: ingreso.id,
        tipo: TipoIngreso.leche,
        monto: 550000,
        litros: 1250,
        detalle: 'segunda entrega',
      );

      final corregido = await db.select(db.ingresosSemana).getSingle();
      expect(corregido.monto, 550000);
      expect(corregido.litros, 1250);
      expect(corregido.detalle, 'segunda entrega');
      expect(corregido.pendiente, isTrue);
    });

    test('un ingreso que deja de ser leche pierde los kilos', () async {
      final s = await semana();
      await finanzas.agregarIngreso(
        lecheriaId: lecheriaId,
        semanaId: s.id,
        tipo: TipoIngreso.leche,
        monto: 500000,
        litros: 1200,
      );
      final ingreso = await db.select(db.ingresosSemana).getSingle();

      await finanzas.editarIngreso(
        id: ingreso.id,
        tipo: TipoIngreso.otro,
        monto: 500000,
        litros: 1200,
      );

      final corregido = await db.select(db.ingresosSemana).getSingle();
      expect(corregido.tipo, TipoIngreso.otro);
      expect(
        corregido.litros,
        isNull,
        reason: 'los kilos son de la leche, no de un ingreso cualquiera',
      );
    });

    test('corregir un gasto cambia categoría, monto y detalle', () async {
      final s = await semana();
      await finanzas.agregarGasto(
        lecheriaId: lecheriaId,
        semanaId: s.id,
        categoria: 'Vetrinario',
        monto: 12000,
      );
      final gasto = await db.select(db.gastosSemana).getSingle();

      await finanzas.editarGasto(
        id: gasto.id,
        categoria: CategoriaGasto.medicamentos,
        monto: 15000,
        detalle: 'oxitetraciclina',
      );

      final corregido = await db.select(db.gastosSemana).getSingle();
      expect(corregido.categoria, CategoriaGasto.medicamentos);
      expect(corregido.monto, 15000);
      expect(corregido.detalle, 'oxitetraciclina');
    });

    test('las categorías de siempre no se guardan como sugerencia', () async {
      await finanzas.recordarCategoria(
        lecheriaId: lecheriaId,
        nombre: CategoriaGasto.concentrado,
      );
      expect(await db.select(db.categoriasGasto).get(), isEmpty);

      await finanzas.recordarCategoria(
        lecheriaId: lecheriaId,
        nombre: 'Cerca eléctrica',
      );
      final guardadas = await db.select(db.categoriasGasto).get();
      expect(guardadas.single.nombre, 'Cerca eléctrica');
    });

    test('olvidar una categoría no toca los gastos ya anotados', () async {
      final s = await semana();
      await finanzas.agregarGasto(
        lecheriaId: lecheriaId,
        semanaId: s.id,
        categoria: 'Vetrinario',
        monto: 12000,
      );
      await finanzas.recordarCategoria(
        lecheriaId: lecheriaId,
        nombre: 'Vetrinario',
      );
      final categoria = await db.select(db.categoriasGasto).getSingle();

      await finanzas.olvidarCategoria(categoria.id);

      expect(await finanzas.observarCategorias(lecheriaId).first, isEmpty);
      final gasto = await db.select(db.gastosSemana).getSingle();
      expect(gasto.categoria, 'Vetrinario');
      expect(gasto.deletedAt, isNull);
    });
  });

  group('ficha del animal', () {
    test('corregir el precio corrige el gasto de la compra', () async {
      final id = await animales.altaAnimal(
        lecheriaId: lecheriaId,
        identificador: 'A-100',
        sexo: Sexo.hembra,
        grupo: GrupoAnimal.enOrdeno,
        origen: OrigenAnimal.comprado,
        precioCompra: 450000,
        fechaCompra: DateTime(2026, 3, 4),
      );

      await animales.editarAnimal(
        animalId: id,
        identificador: 'A-101',
        sexo: Sexo.hembra,
        origen: OrigenAnimal.comprado,
        precioCompra: 480000,
        fechaCompra: DateTime(2026, 3, 4),
      );

      final gasto = await db.select(db.gastosSemana).getSingle();
      expect(gasto.monto, 480000);
      expect(
        gasto.detalle,
        'A-101',
        reason: 'el gasto tiene que seguir apuntando al mismo animal',
      );
    });

    test('un animal que deja de ser comprado se lleva su gasto', () async {
      final id = await animales.altaAnimal(
        lecheriaId: lecheriaId,
        identificador: 'A-100',
        sexo: Sexo.hembra,
        grupo: GrupoAnimal.enOrdeno,
        origen: OrigenAnimal.comprado,
        precioCompra: 450000,
        fechaCompra: DateTime(2026, 3, 4),
      );

      await animales.editarAnimal(
        animalId: id,
        identificador: 'A-100',
        sexo: Sexo.hembra,
        origen: OrigenAnimal.nacido,
      );

      final gasto = await db.select(db.gastosSemana).getSingle();
      expect(gasto.deletedAt, isNotNull);
      final animal = await (db.select(
        db.animales,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(animal.precioCompra, isNull);
      expect(animal.fechaCompra, isNull);
    });

    test('no deja repetir el identificador de otro animal', () async {
      await animales.altaAnimal(
        lecheriaId: lecheriaId,
        identificador: 'A-100',
        sexo: Sexo.hembra,
        grupo: GrupoAnimal.enOrdeno,
        origen: OrigenAnimal.nacido,
      );
      final segundo = await animales.altaAnimal(
        lecheriaId: lecheriaId,
        identificador: 'A-200',
        sexo: Sexo.hembra,
        grupo: GrupoAnimal.enOrdeno,
        origen: OrigenAnimal.nacido,
      );

      expect(
        () => animales.editarAnimal(
          animalId: segundo,
          identificador: 'A-100',
          sexo: Sexo.hembra,
          origen: OrigenAnimal.nacido,
        ),
        throwsA(isA<AnimalDuplicadoException>()),
      );
    });
  });

  group('eliminar y devolver animales', () {
    test('el animal recién registrado se elimina con su gasto', () async {
      final id = await animales.altaAnimal(
        lecheriaId: lecheriaId,
        identificador: 'A-100',
        sexo: Sexo.hembra,
        grupo: GrupoAnimal.enOrdeno,
        origen: OrigenAnimal.comprado,
        precioCompra: 450000,
        fechaCompra: DateTime(2026, 3, 4),
      );

      await animales.eliminarAnimal(id);

      final animal = await (db.select(
        db.animales,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(animal.deletedAt, isNotNull);
      final gasto = await db.select(db.gastosSemana).getSingle();
      expect(gasto.deletedAt, isNotNull);
    });

    test('el animal con historia no se elimina: se da de baja', () async {
      final id = await seedAnimal(db, lecheriaId: lecheriaId);
      await eventos.registrarObservacion(
        animalId: id,
        lecheriaId: lecheriaId,
        texto: 'coja de la pata izquierda',
      );

      expect(
        () => animales.eliminarAnimal(id),
        throwsA(isA<AnimalConHistoriaException>()),
      );
      final animal = await (db.select(
        db.animales,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(animal.deletedAt, isNull);
    });

    test('deshacer la baja devuelve el animal y borra el evento', () async {
      final id = await seedAnimal(db, lecheriaId: lecheriaId);
      await animales.registrarBaja(
        animalId: id,
        lecheriaId: lecheriaId,
        motivo: MotivoBaja.venta,
        precioVenta: 300000,
      );

      await animales.deshacerBaja(id);

      final animal = await (db.select(
        db.animales,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(animal.estado, EstadoAnimal.activo);
      expect(await eventos.listarHojaVida(id).first, isEmpty);
    });
  });

  group('eliminar un evento deshace lo que le hizo al animal', () {
    test('el secado devuelve la vaca a su grupo', () async {
      final id = await seedAnimal(
        db,
        lecheriaId: lecheriaId,
        grupo: GrupoAnimal.enOrdeno,
      );
      await eventos.registrarSecado(animalId: id, lecheriaId: lecheriaId);
      final evento = (await eventos.listarHojaVida(id).first).single;

      await eventos.eliminarEvento(evento.id);

      final animal = await (db.select(
        db.animales,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(animal.grupo, GrupoAnimal.enOrdeno);
    });

    test('el cambio de grupo devuelve al animal al grupo viejo', () async {
      final id = await seedAnimal(
        db,
        lecheriaId: lecheriaId,
        grupo: GrupoAnimal.novillas,
      );
      await animales.cambiarGrupo(
        animalId: id,
        lecheriaId: lecheriaId,
        nuevoGrupo: GrupoAnimal.enOrdeno,
      );
      final evento = (await eventos.listarHojaVida(id).first).single;

      await eventos.eliminarEvento(evento.id);

      final animal = await (db.select(
        db.animales,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(animal.grupo, GrupoAnimal.novillas);
    });

    test('la baja devuelve el animal al inventario', () async {
      final id = await seedAnimal(db, lecheriaId: lecheriaId);
      await animales.registrarBaja(
        animalId: id,
        lecheriaId: lecheriaId,
        motivo: MotivoBaja.muerte,
      );
      final evento = (await eventos.listarHojaVida(id).first).single;

      await eventos.eliminarEvento(evento.id);

      final animal = await (db.select(
        db.animales,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(animal.estado, EstadoAnimal.activo);
    });

    test('la palpación vuelve al diagnóstico anterior', () async {
      final id = await seedAnimal(db, lecheriaId: lecheriaId);
      await eventos.registrarPalpacion(
        animalId: id,
        lecheriaId: lecheriaId,
        resultado: ResultadoPalpacion.vacia,
        fecha: DateTime(2026, 1, 10),
      );
      await eventos.registrarPalpacion(
        animalId: id,
        lecheriaId: lecheriaId,
        resultado: ResultadoPalpacion.preniada,
        fechaProbableParto: DateTime(2026, 10, 1),
        fecha: DateTime(2026, 3, 10),
      );
      final ultima = (await eventos.listarHojaVida(id).first).first;

      await eventos.eliminarEvento(ultima.id);

      final animal = await (db.select(
        db.animales,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(animal.estadoReproductivo, EstadoReproductivo.vacia);
      expect(animal.fechaProbableParto, isNull);
    });

    test('el parto devuelve el grupo, el parto anterior y borra la cría',
        () async {
      final id = await seedAnimal(
        db,
        lecheriaId: lecheriaId,
        grupo: GrupoAnimal.secas,
        fechaUltimoParto: DateTime(2025, 1, 5),
      );
      // El parto viejo que tiene que volver a mandar en los días de lactancia.
      await db
          .into(db.eventosAnimal)
          .insert(
            EventosAnimalCompanion.insert(
              id: 'parto-viejo',
              animalId: id,
              lecheriaId: lecheriaId,
              tipo: TipoEventoAnimal.parto,
              fecha: DateTime(2025, 1, 5),
              createdAt: DateTime(2025, 1, 5),
              updatedAt: DateTime(2025, 1, 5),
            ),
          );

      final criaId = await eventos.registrarParto(
        animalId: id,
        lecheriaId: lecheriaId,
        sexoCria: Sexo.hembra,
        identificadorCria: 'C-1',
        fecha: DateTime(2026, 3, 10),
      );
      final partoNuevo = (await eventos.listarHojaVida(id).first).first;
      expect(partoNuevo.criaAnimalId, criaId);

      await eventos.eliminarEvento(partoNuevo.id);

      final madre = await (db.select(
        db.animales,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(madre.grupo, GrupoAnimal.secas);
      expect(madre.fechaUltimoParto, DateTime(2025, 1, 5));
      expect(madre.estadoReproductivo, EstadoReproductivo.desconocido);

      final cria = await (db.select(
        db.animales,
      )..where((t) => t.id.equals(criaId))).getSingle();
      expect(cria.deletedAt, isNotNull);
    });

    test('la cría que ya tiene pesas no se borra: se suelta de la madre',
        () async {
      final id = await seedAnimal(db, lecheriaId: lecheriaId);
      final criaId = await eventos.registrarParto(
        animalId: id,
        lecheriaId: lecheriaId,
        sexoCria: Sexo.hembra,
        fecha: DateTime(2026, 3, 10),
      );
      final sesion = await pesas.abrirSesion(lecheriaId: lecheriaId);
      await pesas.registrarPesa(
        sesionId: sesion.id,
        animalId: criaId,
        litrosManana: 5,
      );
      final parto = (await eventos.listarHojaVida(id).first).first;

      await eventos.eliminarEvento(parto.id);

      final cria = await (db.select(
        db.animales,
      )..where((t) => t.id.equals(criaId))).getSingle();
      expect(cria.deletedAt, isNull);
      expect(cria.madreId, isNull);
    });

    test('una observación se borra sin tocar nada del animal', () async {
      final id = await seedAnimal(
        db,
        lecheriaId: lecheriaId,
        grupo: GrupoAnimal.enOrdeno,
      );
      await eventos.registrarObservacion(
        animalId: id,
        lecheriaId: lecheriaId,
        texto: 'nota',
      );
      final evento = (await eventos.listarHojaVida(id).first).single;

      await eventos.eliminarEvento(evento.id);

      final animal = await (db.select(
        db.animales,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(animal.grupo, GrupoAnimal.enOrdeno);
      expect(animal.estado, EstadoAnimal.activo);
      expect(await eventos.listarHojaVida(id).first, isEmpty);
    });
  });

  group('corregir un evento', () {
    test('mover la fecha del último parto mueve los días de lactancia',
        () async {
      final id = await seedAnimal(db, lecheriaId: lecheriaId);
      await eventos.registrarParto(
        animalId: id,
        lecheriaId: lecheriaId,
        sexoCria: Sexo.macho,
        fecha: DateTime(2026, 3, 10),
      );
      final parto = (await eventos.listarHojaVida(id).first).first;

      await eventos.editarEvento(
        eventoId: parto.id,
        fecha: DateTime(2026, 3, 1),
        detalle: 'fue el domingo, no el martes',
      );

      final animal = await (db.select(
        db.animales,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(animal.fechaUltimoParto, DateTime(2026, 3, 1));
      final corregido = await (db.select(
        db.eventosAnimal,
      )..where((t) => t.id.equals(parto.id))).getSingle();
      expect(corregido.detalle, 'fue el domingo, no el martes');
    });
  });

  group('pesas', () {
    test('quitar una pesada devuelve la vaca a las que faltan', () async {
      final id = await seedAnimal(db, lecheriaId: lecheriaId);
      final sesion = await pesas.abrirSesion(lecheriaId: lecheriaId);
      await pesas.registrarPesa(
        sesionId: sesion.id,
        animalId: id,
        litrosManana: 10,
        litrosTarde: 8,
      );
      final pesa = await db.select(db.pesasLeche).getSingle();
      expect(
        await pesas.faltantesDeSesion(
          lecheriaId: lecheriaId,
          sesionId: sesion.id,
        ),
        isEmpty,
      );

      await pesas.eliminarPesa(pesa.id);

      final faltantes = await pesas.faltantesDeSesion(
        lecheriaId: lecheriaId,
        sesionId: sesion.id,
      );
      expect(faltantes.single.id, id);
      expect(await pesas.observarPesasDeSesion(sesion.id).first, isEmpty);
    });

    test('corregir una pesada recalcula el total del día', () async {
      final id = await seedAnimal(db, lecheriaId: lecheriaId);
      final sesion = await pesas.abrirSesion(lecheriaId: lecheriaId);
      await pesas.registrarPesa(
        sesionId: sesion.id,
        animalId: id,
        litrosManana: 10,
        litrosTarde: 8,
      );
      final pesa = await db.select(db.pesasLeche).getSingle();
      expect(pesa.litros, 18);

      await pesas.editarPesa(
        pesaId: pesa.id,
        litrosManana: 12,
        litrosTarde: 8,
        concentradoKg: 4,
      );

      final corregida = await db.select(db.pesasLeche).getSingle();
      expect(corregida.litros, 20);
      expect(corregida.concentradoKg, 4);
      expect(corregida.pendiente, isTrue);
    });

    test('reabrir una pesa cerrada la deja seguir', () async {
      final sesion = await pesas.abrirSesion(lecheriaId: lecheriaId);
      await pesas.cerrarSesion(sesion.id);
      expect(await pesas.sesionAbierta(lecheriaId), isNull);

      await pesas.reabrirSesion(sesion.id);

      expect((await pesas.sesionAbierta(lecheriaId))?.id, sesion.id);
    });

    test('eliminar una pesa se lleva sus pesadas', () async {
      final id = await seedAnimal(db, lecheriaId: lecheriaId);
      final sesion = await pesas.abrirSesion(lecheriaId: lecheriaId);
      await pesas.registrarPesa(
        sesionId: sesion.id,
        animalId: id,
        litrosManana: 10,
      );

      await pesas.eliminarSesion(sesion.id);

      expect(await pesas.observarSesiones(lecheriaId).first, isEmpty);
      final pesa = await db.select(db.pesasLeche).getSingle();
      expect(pesa.deletedAt, isNotNull);
      expect(pesa.pendiente, isTrue);
    });

    test('una pesa eliminada no bloquea la de la semana', () async {
      final fecha = DateTime(2026, 3, 4);
      final primera = await pesas.abrirSesion(
        lecheriaId: lecheriaId,
        fecha: fecha,
      );
      await pesas.eliminarSesion(primera.id);

      final segunda = await pesas.abrirSesion(
        lecheriaId: lecheriaId,
        fecha: fecha,
      );

      expect(segunda.id, isNot(primera.id));
    });
  });
}

