// La tabla de módulos es la lista de rutas del escritorio. Si alguien agrega
// un módulo al teléfono y se olvida de esta lista, en la computadora no hay
// forma de llegar: no hay grilla de tarjetas que lo salve.

import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/home/home_screen.dart';
import 'package:leche_control_web/escritorio/modulos_escritorio.dart';
import 'package:leche_control_web/escritorio/tablero_escritorio.dart';

void main() {
  final lecheria = LecheriaRow(
    id: 'lecheria-1',
    nombre: 'Lechería de Prueba',
    creadaPor: 'usuario-1',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    pendiente: false,
  );

  test('están los seis módulos del teléfono, más Inicio', () {
    expect(modulosEscritorio.map((m) => m.clave).toList(), [
      'inicio',
      // El mismo orden que la grilla de HomeScreen, para que quien use las
      // dos versiones encuentre los módulos donde los dejó.
      'trabajo',
      'inventario',
      'registroLeche',
      'finanzas',
      'sanidad',
      'analisis',
    ]);
  });

  test('Ajustes va al final y aparte de los módulos', () {
    expect(modulosEscritorio, isNot(contains(moduloAjustes)));
    expect(panelesEscritorio.last, moduloAjustes);
    expect(panelesEscritorio.length, modulosEscritorio.length + 1);
  });

  test('no hay claves repetidas', () {
    final claves = panelesEscritorio.map((m) => m.clave).toList();
    expect(claves.toSet().length, claves.length);
  });

  test('todos tienen título legible', () {
    for (final modulo in panelesEscritorio) {
      expect(modulo.titulo.trim(), isNotEmpty, reason: modulo.clave);
    }
  });

  // Construir el widget no lo monta, así que estas dos pruebas no tocan la
  // base local: solo comprueban a qué apunta cada entrada del menú.

  test('Inicio abre el tablero de escritorio, no el home del teléfono', () {
    final abierto = modulosEscritorio.first.construir(lecheria, 'usuario-1');

    expect(abierto, isA<TableroEscritorio>());
    // Si esto falla, alguien volvió a poner la grilla de seis tarjetas en la
    // computadora: repite la barra lateral y obliga a angostar el panel a
    // ancho de celular.
    expect(abierto, isNot(isA<HomeScreen>()));
  });

  test('los demás módulos abren las pantallas del teléfono', () {
    // El único que no es una pantalla del móvil es Inicio. Cualquier otro que
    // deje de serlo significa que se está escribiendo producto en el proyecto
    // web, que es justo lo que esta arquitectura evita.
    for (final modulo in panelesEscritorio.skip(1)) {
      final abierto = modulo.construir(lecheria, 'usuario-1');
      expect(
        abierto.runtimeType.toString(),
        endsWith('Screen'),
        reason: '${modulo.clave} no abre una pantalla del paquete móvil',
      );
    }
  });
}
