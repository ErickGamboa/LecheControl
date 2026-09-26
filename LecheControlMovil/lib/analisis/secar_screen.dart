import 'package:flutter/material.dart';

import '../app/etiqueta_animal.dart';
import '../app/theme.dart';
import '../data/domain/grupos.dart';
import '../data/domain/secar.dart';
import '../hoja_vida/hoja_vida_screen.dart';
import '../services.dart';

/// Vacas por secar (Módulo 6 — Análisis): las preñadas a las que les faltan
/// para parir los días que diga la finca o menos, y que **siguen en ordeño**.
///
/// Cuántos días son lo decide cada finca en Ajuste de métricas; de fábrica son
/// [diasParaSecarPorDefecto].
///
/// La vaca necesita dos meses largos de descanso antes de parir, y el aviso
/// tiene que venir de la app porque de la finca no viene: la vaca camina al
/// ordeño todos los días como si nada, y cuando alguien se acuerda de mirar la
/// fecha probable de parto ya se pasó.
///
/// **No se sale sola.** La saca el secado y nada más; mientras siga en ordeño
/// el aviso se queda, y la que ya se pasó de la fecha queda de primera en vez
/// de desaparecer. Es lo contrario de lo que haría una lista que se limpia al
/// vencerse, y es a propósito: el problema no se arregla porque pase el tiempo.
///
/// Al tocar una vaca se abre su hoja de vida, que es de donde se la seca.
class SecarScreen extends StatefulWidget {
  const SecarScreen({super.key, required this.lecheriaId});

  final String lecheriaId;

  @override
  State<SecarScreen> createState() => _SecarScreenState();
}

/// La lista y la regla con la que se armó. Van juntas porque las dos hacen
/// falta para pintar la pantalla: el número se escribe en pantalla y tiene
/// que ser el mismo con el que se filtró, no uno parecido.
typedef _Datos = ({List<VacaPorSecar> vacas, int dias});

class _SecarScreenState extends State<SecarScreen> {
  late Future<_Datos> _futuro;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _futuro = _leer();
  }

  Future<_Datos> _leer() async {
    return (
      vacas: await palpacionRepo.porSecar(widget.lecheriaId),
      dias: await curvaRepo.diasParaSecarDe(widget.lecheriaId),
    );
  }

  /// Se vuelve a leer la lista al regresar: si allá se la secó, ya no va acá.
  Future<void> _abrirHojaDeVida(VacaPorSecar vaca) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HojaVidaScreen(animalId: vaca.animalId),
      ),
    );
    if (mounted) setState(_cargar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vacas por secar')),
      body: SafeArea(
        child: FutureBuilder<_Datos>(
          future: _futuro,
          builder: (context, snap) {
            final datos = snap.data;
            if (datos == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final vacas = datos.vacas;
            if (vacas.isEmpty) return _SinVacas(dias: datos.dias);

            return ListView(
              padding: const EdgeInsets.all(LecheSpacing.lg),
              children: [
                _Resumen(vacas: vacas),
                const SizedBox(height: LecheSpacing.lg),
                for (final v in vacas)
                  _FilaVaca(vaca: v, onTap: () => _abrirHojaDeVida(v)),
                const SizedBox(height: LecheSpacing.lg),
                _Criterio(dias: datos.dias),
                const SizedBox(height: LecheSpacing.xl),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.vacas});

  final List<VacaPorSecar> vacas;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final pasadas = vacas.where((v) => v.pasadaDeFecha).length;

    return Card(
      key: const ValueKey('secar.resumen'),
      child: Padding(
        padding: const EdgeInsets.all(LecheSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${vacas.length} ${vacas.length == 1 ? 'VACA' : 'VACAS'} '
              'POR SECAR',
              style: textos.titleSmall,
            ),
            const SizedBox(height: LecheSpacing.sm),
            Text(
              pasadas == 0
                  ? 'Ninguna se ha pasado de la fecha de parto.'
                  : pasadas == 1
                  ? '1 ya se pasó de la fecha de parto y sigue en ordeño.'
                  : '$pasadas ya se pasaron de la fecha de parto y siguen '
                        'en ordeño.',
              style: textos.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaVaca extends StatelessWidget {
  const _FilaVaca({required this.vaca, required this.onTap});

  final VacaPorSecar vaca;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;

    // El color no se difumina por posición como en Vacas por servir: acá el
    // umbral es real y no relativo a la finca. Setenta días son setenta días,
    // y pasarse de la fecha de parto es otra cosa —no «un poco peor»—, así
    // que se pinta distinto y punto.
    final urgente = vaca.pasadaDeFecha;
    final fondo = urgente
        ? Color.lerp(esquema.surface, const Color(0xFFD32F2F), 0.14)
        : null;
    final borde = urgente ? const Color(0xFFD32F2F) : esquema.outlineVariant;

    return Card(
      key: ValueKey('secar.vaca.${vaca.animalId}'),
      color: fondo,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borde, width: urgente ? 1.5 : 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(LecheSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          etiquetaAnimal(vaca.identificador, vaca.alias),
                          style: textos.titleMedium,
                        ),
                        const SizedBox(width: LecheSpacing.sm),
                        Expanded(
                          child: Text(
                            GrupoAnimal.etiqueta(vaca.grupo),
                            style: textos.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(vaca.resumen, style: textos.bodyMedium),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    vaca.cifra,
                    style: textos.headlineSmall?.copyWith(
                      color: urgente
                          ? const Color(0xFFB71C1C)
                          : esquema.onSurface,
                    ),
                  ),
                  Text(
                    urgente ? 'días de más' : 'días',
                    style: textos.bodySmall?.copyWith(color: esquema.outline),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: esquema.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _SinVacas extends StatelessWidget {
  const _SinVacas({required this.dias});

  final int dias;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LecheSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 56),
            const SizedBox(height: LecheSpacing.lg),
            Text(
              'Ninguna vaca está por secarse',
              style: textos.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: LecheSpacing.sm),
            Text(
              'Acá van a salir las preñadas a las que les falten '
              '$dias días o menos para parir y que todavía estén en ordeño.',
              style: textos.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Criterio extends StatelessWidget {
  const _Criterio({required this.dias});

  final int dias;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LecheSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CÓMO SE ARMA ESTA LISTA', style: textos.titleSmall),
            const SizedBox(height: LecheSpacing.sm),
            Text(
              'Entra la vaca preñada a la que le faltan $dias días o '
              'menos para parir y que todavía no está en Secas. Va primero la '
              'que menos le falta.\n\n'
              'Una vaca que se pasó de la fecha y sigue ordeñándose no se va '
              'de la lista: queda de primera, con los días de más en rojo.\n\n'
              'La única forma de salir es secarla. Al registrarle el secado '
              'pasa al grupo Secas y desaparece de acá sola.',
              style: textos.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
