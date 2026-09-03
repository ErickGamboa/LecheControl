import 'package:flutter/material.dart';

import '../analisis/analisis_calidad_screen.dart';
import '../app/theme.dart';
import '../app/widgets/quick_number_field.dart';
import '../data/domain/calidad_leche.dart';
import '../data/domain/semana.dart';
import '../data/local/database.dart';
import '../services.dart';
import 'widgets/guia_calidad_leche.dart';

/// Calidad de leche (Módulo 3 — Registro de leche).
///
/// Una vez por semana la planta manda el resultado de los análisis de la leche
/// que se le entregó: **sólidos totales**, **células somáticas** y **conteo
/// bacterial**. Acá se anotan, uno por semana, y la app dice en qué escalón
/// cayó cada uno según las tablas de la planta.
///
/// No se calcula nada: son datos que llegan de afuera. Lo único que la app
/// pone de su parte es la lectura —el grado y qué significa— para que el papel
/// de la planta no haya que interpretarlo de memoria.
///
/// Los tres son opcionales por separado: la planta no siempre manda los tres
/// el mismo día y media semana anotada sirve más que ninguna.
class CalidadLecheScreen extends StatefulWidget {
  const CalidadLecheScreen({
    super.key,
    required this.lecheriaId,
    required this.nombreLecheria,
  });

  final String lecheriaId;
  final String nombreLecheria;

  @override
  State<CalidadLecheScreen> createState() => _CalidadLecheScreenState();
}

class _CalidadLecheScreenState extends State<CalidadLecheScreen> {
  SemanaRow? _semana;
  bool _cargando = true;
  bool _guardado = false;

  final _solidosCtrl = TextEditingController();
  final _somaticasCtrl = TextEditingController();
  final _bacterialCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // El escalón de cada análisis se muestra mientras se digita, así que la
    // pantalla se rehace con cada tecla.
    for (final c in [_solidosCtrl, _somaticasCtrl, _bacterialCtrl]) {
      c.addListener(_alEscribir);
    }
    _abrirSemana(DateTime.now());
  }

  @override
  void dispose() {
    for (final c in [_solidosCtrl, _somaticasCtrl, _bacterialCtrl]) {
      c
        ..removeListener(_alEscribir)
        ..dispose();
    }
    super.dispose();
  }

  void _alEscribir() {
    if (!mounted) return;
    setState(() => _guardado = false);
  }

  Future<void> _abrirSemana(DateTime fecha) async {
    setState(() {
      _cargando = true;
      _guardado = false;
    });
    final semana = await calidadRepo.abrirSemana(
      lecheriaId: widget.lecheriaId,
      fecha: fecha,
    );
    final calidad = await calidadRepo.deSemana(semana.id);
    if (!mounted) return;
    // Fuera del setState: escribir en los controladores dispara
    // `_alEscribir`, que ya llama a setState por su cuenta.
    _solidosCtrl.text = _texto(calidad?.solidosTotalesPct, decimales: 2);
    _somaticasCtrl.text = _texto(calidad?.celulasSomaticas);
    _bacterialCtrl.text = _texto(calidad?.conteoBacterial);
    setState(() {
      _semana = semana;
      _cargando = false;
    });
  }

  /// Cómo se muestra en el campo un valor ya guardado. Sin separador de miles:
  /// el campo es para editar, y un `290.000` que después hay que volver a
  /// interpretar es justo lo que [_leerConteo] tiene que deshacer.
  static String _texto(double? valor, {int decimales = 0}) {
    if (valor == null) return '';
    if (decimales == 0) return valor.round().toString();
    if (valor == valor.roundToDouble()) return valor.round().toString();
    return valor
        .toStringAsFixed(decimales)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  /// Un porcentaje: la coma se lee como punto decimal (así se digita acá).
  double? _leerPorcentaje(TextEditingController c) {
    final texto = c.text.trim().replaceAll(',', '.');
    if (texto.isEmpty) return null;
    return double.tryParse(texto);
  }

  /// Un conteo (células, UFC): se le quitan puntos y comas antes de leerlo.
  ///
  /// Estos números se escriben en cientos de miles y es natural teclearlos con
  /// separador —"290.000"—. Leídos como decimal darían 290, que cae cuatro
  /// escalones más abajo en la tabla. Como un conteo de células nunca lleva
  /// decimales, quitar los separadores no es ambiguo: nadie quiso decir 290,0.
  double? _leerConteo(TextEditingController c) {
    final texto = c.text.trim().replaceAll(RegExp(r'[.,]'), '');
    if (texto.isEmpty) return null;
    return double.tryParse(texto);
  }

  void _cambiarSemana(int semanas) {
    final actual = _semana;
    if (actual == null) return;
    _abrirSemana(actual.fechaInicio.add(Duration(days: 7 * semanas)));
  }

  Future<void> _guardar() async {
    final semana = _semana;
    if (semana == null) return;

    await calidadRepo.guardar(
      lecheriaId: widget.lecheriaId,
      semanaId: semana.id,
      solidosTotalesPct: _leerPorcentaje(_solidosCtrl),
      celulasSomaticas: _leerConteo(_somaticasCtrl),
      conteoBacterial: _leerConteo(_bacterialCtrl),
    );
    sincronizarSiSePuede();
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() => _guardado = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Calidad guardada — '
          '${etiquetaSemana(semana.fechaInicio, semana.fechaFin)}',
        ),
      ),
    );
  }

  Future<void> _abrirAnalisis() {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnalisisCalidadScreen(
          lecheriaId: widget.lecheriaId,
          nombreLecheria: widget.nombreLecheria,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final semana = _semana;
    if (_cargando || semana == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Calidad de leche')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final solidos = _leerPorcentaje(_solidosCtrl);
    final somaticas = _leerConteo(_somaticasCtrl);
    final bacterial = _leerConteo(_bacterialCtrl);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calidad de leche'),
        actions: [
          IconButton(
            key: const ValueKey('calidad.historial'),
            tooltip: 'Semanas anteriores',
            onPressed: _abrirAnalisis,
            icon: const Icon(Icons.insights_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _SelectorSemana(
              semana: semana,
              onAnterior: () => _cambiarSemana(-1),
              onSiguiente: () => _cambiarSemana(1),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(LecheSpacing.lg),
                children: [
                  Text(
                    'Lo que reportó la planta de la leche de esta semana. '
                    'Se puede anotar solo lo que haya llegado.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: LecheSpacing.lg),
                  _CampoCalidad(
                    valueKey: 'calidad.solidos',
                    controller: _solidosCtrl,
                    etiqueta: 'Sólidos totales',
                    sufijo: '%',
                    escalon: nivelSolidosTotales(solidos),
                  ),
                  const SizedBox(height: LecheSpacing.lg),
                  _CampoCalidad(
                    valueKey: 'calidad.somaticas',
                    controller: _somaticasCtrl,
                    etiqueta: 'Células somáticas',
                    sufijo: 'cél./mL',
                    ayuda: 'Ej.: 250000',
                    escalon: nivelCelulasSomaticas(somaticas),
                  ),
                  const SizedBox(height: LecheSpacing.lg),
                  _CampoCalidad(
                    valueKey: 'calidad.bacterial',
                    controller: _bacterialCtrl,
                    etiqueta: 'Conteo bacterial',
                    sufijo: 'UFC/mL',
                    ayuda: 'Ej.: 290000',
                    escalon: gradoBacterial(bacterial),
                  ),
                  const SizedBox(height: LecheSpacing.xl),
                  FilledButton.icon(
                    key: const ValueKey('calidad.guardar'),
                    onPressed: _guardar,
                    icon: Icon(_guardado ? Icons.check : Icons.save),
                    label: Text(_guardado ? 'Guardado' : 'Guardar'),
                  ),
                  const SizedBox(height: LecheSpacing.xl),
                  Text(
                    'CÓMO SE LEE',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: LecheSpacing.sm),
                  GuiaCalidadLeche(
                    resaltarSolidos: solidos,
                    resaltarSomaticas: somaticas,
                    resaltarBacterial: bacterial,
                  ),
                  const SizedBox(height: LecheSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un análisis: el número que manda la planta y, debajo, en qué escalón cayó.
class _CampoCalidad extends StatelessWidget {
  const _CampoCalidad({
    required this.valueKey,
    required this.controller,
    required this.etiqueta,
    required this.sufijo,
    required this.escalon,
    this.ayuda,
  });

  final String valueKey;
  final TextEditingController controller;
  final String etiqueta;
  final String sufijo;
  final String? ayuda;
  final RangoCalidad? escalon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuickNumberField(
          key: ValueKey(valueKey),
          controller: controller,
          labelText: etiqueta,
          suffixText: sufijo,
        ),
        if (ayuda != null && escalon == null) ...[
          const SizedBox(height: LecheSpacing.xs),
          Text(ayuda!, style: Theme.of(context).textTheme.bodySmall),
        ],
        if (escalon != null) ...[
          const SizedBox(height: LecheSpacing.sm),
          EtiquetaEscalon(escalon: escalon!),
        ],
      ],
    );
  }
}

/// Igual que el de Finanzas: la semana se elige con las flechas, y no se puede
/// pasar de la semana en curso.
class _SelectorSemana extends StatelessWidget {
  const _SelectorSemana({
    required this.semana,
    required this.onAnterior,
    required this.onSiguiente,
  });

  final SemanaRow semana;
  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;

  @override
  Widget build(BuildContext context) {
    final esActual = lunesDe(DateTime.now()) == semana.fechaInicio;
    return Container(
      color: kVerdeLeche.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('calidad.semanaAnterior'),
            onPressed: onAnterior,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Semana anterior',
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  etiquetaSemana(semana.fechaInicio, semana.fechaFin),
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                Text(
                  esActual ? 'Esta semana' : '${semana.fechaInicio.year}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('calidad.semanaSiguiente'),
            onPressed: esActual ? null : onSiguiente,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Semana siguiente',
          ),
        ],
      ),
    );
  }
}
