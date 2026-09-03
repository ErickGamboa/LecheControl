// El corte entre teléfono y escritorio es lo único que decide este proyecto,
// así que es lo único que se prueba acá. Lo que dibujan las pantallas ya está
// probado en el paquete móvil, y volverlo a probar sería duplicar el trabajo
// que esta arquitectura existe para no duplicar.

import 'package:flutter_test/flutter_test.dart';
import 'package:leche_control_web/adaptador/adaptador_leche.dart';

void main() {
  group('corte de ancho', () {
    test('un teléfono en vertical recibe la distribución del teléfono', () {
      // iPhone 15, Pixel 8, Galaxy S24: todos por debajo de 500 px lógicos.
      for (final ancho in [320.0, 360.0, 390.0, 412.0, 430.0]) {
        expect(
          distribucionPara(ancho),
          Distribucion.telefono,
          reason: '$ancho px debería ser teléfono',
        );
      }
    });

    test('una tablet en vertical todavía recibe la del teléfono', () {
      // iPad de 10" en vertical mide 810 px lógicos: la app se ve como en el
      // celular, que es mejor que una barra lateral aplastada.
      expect(distribucionPara(768), Distribucion.telefono);
      expect(distribucionPara(810), Distribucion.telefono);
    });

    test('un monitor o portátil recibe la de escritorio', () {
      for (final ancho in [1280.0, 1440.0, 1920.0, 2560.0]) {
        expect(
          distribucionPara(ancho),
          Distribucion.escritorio,
          reason: '$ancho px debería ser escritorio',
        );
      }
    });

    test('el corte es cerrado por abajo: 1000 px ya es escritorio', () {
      expect(distribucionPara(kCorteEscritorio - 1), Distribucion.telefono);
      expect(distribucionPara(kCorteEscritorio), Distribucion.escritorio);
      expect(distribucionPara(kCorteEscritorio + 1), Distribucion.escritorio);
    });

    test('un ancho de cero no revienta y cae en teléfono', () {
      // Pasa de verdad: durante el primer cuadro, y en un iframe que todavía
      // no midió. Mejor la distribución del teléfono que una excepción.
      expect(distribucionPara(0), Distribucion.telefono);
    });
  });
}
