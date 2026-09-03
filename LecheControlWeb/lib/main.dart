import 'package:flutter/material.dart';
import 'package:leche_control/app/theme.dart';
import 'package:leche_control/app_bootstrap.dart' as movil;
import 'package:leche_control/auth/auth_gate.dart';

import 'adaptador/adaptador_leche.dart';

/// Punto de entrada de LecheControl en el navegador.
///
/// El arranque es el mismo del teléfono: `bootstrapLecheControl()` inicializa
/// Supabase, carga la sesión local, abre la base local (SQLite compilado a
/// WebAssembly, ver `web/sqlite3.wasm`) y deja la sincronización andando sola.
/// No hay una versión web del arranque porque no hace falta: el paquete móvil
/// ya es compatible con web y esa es una regla escrita en su `AGENTS.md`.
///
/// Lo único propio de este proyecto es qué se dibuja: `AuthGate` recibe un
/// `construirHome` que, según el ancho, monta la pantalla del teléfono tal
/// cual o el marco de escritorio.
Future<void> main() async {
  await movil.bootstrapLecheControl();
  runApp(const AppLecheControlWeb());
}

class AppLecheControlWeb extends StatelessWidget {
  const AppLecheControlWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LecheControl',
      debugShowCheckedModeBanner: false,
      // El mismo tema del teléfono, no una copia parecida: los colores, los
      // radios y la tipografía salen de `LecheTheme`, en el paquete móvil.
      theme: LecheTheme.light,
      // Siempre claro, aunque la computadora o el celular estén en modo
      // oscuro. Es una decisión del producto, no un descuido: la web se usa en
      // el galpón y en la oficina, y el mismo tono claro en las tres versiones
      // evita que la misma pantalla se vea de dos maneras según el aparato.
      //
      // Ojo: el paquete móvil sí trae `LecheTheme.dark` y la app instalada
      // sigue el ajuste del sistema (`ThemeMode.system` en `app_bootstrap`).
      // El tema oscuro no se borró; acá simplemente no se usa. Para
      // devolverle el modo oscuro a la web alcanza con volver a poner
      // `darkTheme: LecheTheme.dark` y `themeMode: ThemeMode.system`.
      themeMode: ThemeMode.light,
      // `AuthGate` es el de siempre. La decisión de ancho va adentro, en el
      // home, y no acá arriba: si envolviera el gate en un `LayoutBuilder`,
      // cada píxel de un arrastre de ventana volvería a construir los gates
      // y a resuscribir los streams de cuenta y lechería.
      home: const AuthGate(construirHome: construirHomeSegunAncho),
    );
  }
}
