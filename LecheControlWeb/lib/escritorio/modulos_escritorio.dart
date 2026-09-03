import 'package:flutter/material.dart';
import 'package:leche_control/ajustes/ajustes_screen.dart';
import 'package:leche_control/analisis/analisis_screen.dart';
import 'package:leche_control/app/theme.dart';
import 'package:leche_control/data/local/database.dart';
import 'package:leche_control/finanzas/finanzas_screen.dart';
import 'package:leche_control/inventario/inventario_screen.dart';
import 'package:leche_control/pesa/registro_leche_screen.dart';
import 'package:leche_control/sanidad/sanidad_screen.dart';
import 'package:leche_control/trabajo/trabajo_screen.dart';

import 'tablero_escritorio.dart';

/// Una entrada de la barra lateral.
///
/// `construir` devuelve **la misma pantalla que abre el teléfono**, con los
/// mismos parámetros. Este archivo es una tabla de rutas, no una capa de
/// interfaz: si alguna vez hace falta escribir un widget acá para que un
/// módulo se vea bien en escritorio, es señal de que el arreglo va en la
/// pantalla del paquete móvil y beneficia a los tres clientes.
class ModuloEscritorio {
  const ModuloEscritorio({
    required this.clave,
    required this.titulo,
    required this.icono,
    required this.color,
    required this.construir,
  });

  /// Identificador estable, usado en las `ValueKey` de los tests.
  final String clave;

  /// Lo que se lee en la barra lateral y en la barra superior ("dónde estoy").
  final String titulo;

  final IconData icono;

  /// El mismo color con el que el módulo se pinta en la grilla del teléfono,
  /// para que quien pase del celular a la computadora reconozca el módulo por
  /// el color antes de leer el nombre.
  final Color color;

  final Widget Function(LecheriaRow lecheria, String usuarioId) construir;
}

/// Los módulos del menú, en el mismo orden que la grilla del teléfono
/// (`HomeScreen`), con «Inicio» al frente.
///
/// «Inicio» es el único que no abre una pantalla del teléfono, sino
/// `TableroEscritorio`: los mismos dos widgets que el celular muestra arriba
/// —el conteo del hato y el gráfico semanal— usando el ancho del monitor, sin
/// la grilla de tarjetas, porque acá el camino a los módulos es esta misma
/// barra lateral. Los widgets vienen del paquete móvil; el tablero solo los
/// acomoda.
const List<ModuloEscritorio> modulosEscritorio = [
  ModuloEscritorio(
    clave: 'inicio',
    titulo: 'Inicio',
    icono: Icons.home_outlined,
    color: kAzulLeche,
    construir: _inicio,
  ),
  ModuloEscritorio(
    clave: 'trabajo',
    titulo: 'Trabajo',
    icono: Icons.nfc,
    color: kVerdeLeche,
    construir: _trabajo,
  ),
  ModuloEscritorio(
    clave: 'inventario',
    titulo: 'Inventario',
    icono: Icons.list_alt,
    color: kAzulLeche,
    construir: _inventario,
  ),
  ModuloEscritorio(
    clave: 'registroLeche',
    titulo: 'Registro de leche',
    icono: Icons.water_drop_outlined,
    color: kVerdeLeche,
    construir: _registroLeche,
  ),
  ModuloEscritorio(
    clave: 'finanzas',
    titulo: 'Finanzas',
    icono: Icons.payments_outlined,
    color: kAmbarLeche,
    construir: _finanzas,
  ),
  ModuloEscritorio(
    clave: 'sanidad',
    titulo: 'Sanidad',
    icono: Icons.medical_services_outlined,
    color: kAzulLeche,
    construir: _sanidad,
  ),
  ModuloEscritorio(
    clave: 'analisis',
    titulo: 'Análisis',
    icono: Icons.insights_outlined,
    color: kVerdeLeche,
    construir: _analisis,
  ),
];

/// Ajustes va aparte, al pie de la barra lateral y debajo de un separador.
///
/// En el teléfono tampoco es una tarjeta del menú: vive en el ícono de la
/// barra superior. Es configuración de las métricas, no trabajo del día.
const ModuloEscritorio moduloAjustes = ModuloEscritorio(
  clave: 'ajustes',
  titulo: 'Ajuste de métricas',
  icono: Icons.tune,
  color: kAzulLeche,
  construir: _ajustes,
);

/// Todos los paneles que el shell puede montar, en el orden de sus índices.
const List<ModuloEscritorio> panelesEscritorio = [
  ...modulosEscritorio,
  moduloAjustes,
];

// Constructores sueltos y no cierres dentro de la lista, porque la lista es
// `const` y un cierre no lo es.

Widget _inicio(LecheriaRow lecheria, String usuarioId) =>
    TableroEscritorio(lecheria: lecheria);

Widget _trabajo(LecheriaRow lecheria, String usuarioId) =>
    TrabajoScreen(lecheriaId: lecheria.id, usuarioId: usuarioId);

Widget _inventario(LecheriaRow lecheria, String usuarioId) =>
    InventarioScreen(lecheriaId: lecheria.id, usuarioId: usuarioId);

Widget _registroLeche(LecheriaRow lecheria, String usuarioId) =>
    RegistroLecheScreen(
      lecheriaId: lecheria.id,
      nombreLecheria: lecheria.nombre,
    );

Widget _finanzas(LecheriaRow lecheria, String usuarioId) =>
    FinanzasScreen(lecheriaId: lecheria.id);

Widget _sanidad(LecheriaRow lecheria, String usuarioId) =>
    SanidadScreen(lecheriaId: lecheria.id, usuarioId: usuarioId);

Widget _analisis(LecheriaRow lecheria, String usuarioId) =>
    AnalisisScreen(lecheriaId: lecheria.id, nombreLecheria: lecheria.nombre);

Widget _ajustes(LecheriaRow lecheria, String usuarioId) =>
    AjustesScreen(lecheriaId: lecheria.id);
