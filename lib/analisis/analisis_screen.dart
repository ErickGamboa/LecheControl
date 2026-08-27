import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../app/widgets/opcion_menu_card.dart';
import 'analisis_calidad_screen.dart';
import 'analisis_finanzas_screen.dart';
import 'analisis_leche_screen.dart';
import 'dieta_concentrado_screen.dart';
import 'palpacion_screen.dart';

/// Análisis (Módulo 6): mirar la finca **a lo largo del tiempo**, no la
/// semana de hoy.
///
/// El resto de la app trabaja siempre sobre la semana en curso —se pesa esta
/// semana, se anotan los gastos de esta semana—. Acá se abren todas: cuánta
/// leche viene saliendo, cómo viene esa leche de calidad, cómo vienen las
/// utilidades y cuánto concentrado se está gastando. Son preguntas distintas,
/// así que se elige cuál antes de entrar.
class AnalisisScreen extends StatelessWidget {
  const AnalisisScreen({
    super.key,
    required this.lecheriaId,
    required this.nombreLecheria,
  });

  final String lecheriaId;
  final String nombreLecheria;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Análisis')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LecheSpacing.lg),
          children: [
            Text(
              '¿Qué querés analizar?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: LecheSpacing.md),
            OpcionMenuCard(
              valueKey: 'analisis.leche',
              icono: const Icon(Icons.water_drop_outlined),
              color: kVerdeLeche,
              titulo: 'Leche',
              detalle:
                  'Todas las pesas, semana por semana: litros, vacas y '
                  'promedio. Desde acá se abre el reporte de cualquiera.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AnalisisLecheScreen(
                    lecheriaId: lecheriaId,
                    nombreLecheria: nombreLecheria,
                  ),
                ),
              ),
            ),
            const SizedBox(height: LecheSpacing.md),
            OpcionMenuCard(
              valueKey: 'analisis.calidad',
              icono: const Icon(Icons.science_outlined),
              color: kAzulLeche,
              titulo: 'Calidad de leche',
              detalle:
                  'Sólidos totales, células somáticas y conteo bacterial '
                  'semana a semana, con el grado de cada uno.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AnalisisCalidadScreen(
                    lecheriaId: lecheriaId,
                    nombreLecheria: nombreLecheria,
                  ),
                ),
              ),
            ),
            const SizedBox(height: LecheSpacing.md),
            OpcionMenuCard(
              valueKey: 'analisis.finanzas',
              icono: const Icon(Icons.savings_outlined),
              color: kAzulLeche,
              titulo: 'Finanzas',
              detalle:
                  'Ingresos, gastos y utilidad de todas las semanas, con el '
                  'acumulado y el precio real por kilo.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      AnalisisFinanzasScreen(lecheriaId: lecheriaId),
                ),
              ),
            ),
            const SizedBox(height: LecheSpacing.md),
            OpcionMenuCard(
              valueKey: 'analisis.palpacion',
              icono: const ImageIcon(AssetImage('assets/icono_palpacion.png')),
              color: kAmbarLeche,
              titulo: 'Vacas por palpar',
              detalle:
                  'Las recién paridas y las que ya se sirvieron y no '
                  'confirman preñez, en una hoja para el veterinario.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PalpacionScreen(
                    lecheriaId: lecheriaId,
                    nombreLecheria: nombreLecheria,
                  ),
                ),
              ),
            ),
            const SizedBox(height: LecheSpacing.md),
            OpcionMenuCard(
              valueKey: 'analisis.dieta',
              icono: const ImageIcon(AssetImage('assets/icono_dieta.png')),
              color: kVerdeLeche,
              titulo: 'Dieta de concentrado',
              detalle:
                  'Cuánto concentrado le toca a cada vaca según su última '
                  'pesa, y cuánto se le está dando.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DietaConcentradoScreen(
                    lecheriaId: lecheriaId,
                    nombreLecheria: nombreLecheria,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
