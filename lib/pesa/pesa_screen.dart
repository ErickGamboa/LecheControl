import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../app/widgets/quick_number_field.dart';
import '../app/widgets/scan_field.dart';
import '../data/domain/grupos.dart';
import '../data/local/database.dart';
import '../data/repositories/pesas_repository.dart';
import '../services.dart';

/// Pesa de leche (Módulo 3): abre/reutiliza la sesión del día, permite
/// escanear/ingresar cada vaca y su producción, muestra un contador de
/// pesadas vs. faltantes, y al cerrar presenta el resumen de la sesión.
class PesaScreen extends StatefulWidget {
  const PesaScreen({super.key, required this.lecheriaId});

  final String lecheriaId;

  @override
  State<PesaScreen> createState() => _PesaScreenState();
}

class _PesaScreenState extends State<PesaScreen> {
  PesaSesionRow? _sesion;
  bool _cargando = true;
  final _identCtrl = TextEditingController();
  final _identFocus = FocusNode();
  final _litrosCtrl = TextEditingController();
  final _litrosFocus = FocusNode();
  AnimalRow? _animalActual;
  String? _mensaje;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  @override
  void dispose() {
    _identCtrl.dispose();
    _identFocus.dispose();
    _litrosCtrl.dispose();
    _litrosFocus.dispose();
    super.dispose();
  }

  Future<void> _iniciar() async {
    final sesion = await pesasRepo.abrirSesion(lecheriaId: widget.lecheriaId);
    if (!mounted) return;
    setState(() {
      _sesion = sesion;
      _cargando = false;
    });
  }

  Future<void> _buscarAnimal(String identificador) async {
    if (identificador.trim().isEmpty) return;
    final animal = await animalesRepo.buscarPorIdentificador(
      widget.lecheriaId,
      identificador.trim(),
    );
    if (!mounted) return;
    if (animal == null) {
      setState(() {
        _animalActual = null;
        _mensaje = 'Animal no encontrado';
      });
      return;
    }
    setState(() {
      _animalActual = animal;
      _mensaje = null;
    });
    _litrosFocus.requestFocus();
  }

  Future<void> _guardarLitros() async {
    final sesion = _sesion;
    final animal = _animalActual;
    if (sesion == null || animal == null) return;
    final litros = double.tryParse(_litrosCtrl.text.replaceAll(',', '.'));
    if (litros == null) return;

    final existente = await pesasRepo.registrarPesa(
      sesionId: sesion.id,
      animalId: animal.id,
      litros: litros,
    );
    if (!mounted) return;
    if (existente != null) {
      final corregir = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Ya se pesó hoy'),
          content: Text(
            '${animal.identificador} ya tiene ${existente.litros.toStringAsFixed(1)} L '
            'registrados en esta sesión. ¿Corregir por ${litros.toStringAsFixed(1)} L?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Corregir'),
            ),
          ],
        ),
      );
      if (corregir == true) {
        await pesasRepo.registrarPesa(
          sesionId: sesion.id,
          animalId: animal.id,
          litros: litros,
          corregir: true,
        );
      } else {
        return;
      }
    }

    sincronizarSiSePuede();
    setState(() {
      _animalActual = null;
      _identCtrl.clear();
      _litrosCtrl.clear();
    });
    _identFocus.requestFocus();
  }

  Future<void> _cerrarSesion() async {
    final sesion = _sesion;
    if (sesion == null) return;
    final resumen = await pesasRepo.resumenSesion(sesion.id);
    if (!mounted) return;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión de pesa'),
        content: _ResumenSesionWidget(resumen: resumen),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir pesando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmado == true) {
      await pesasRepo.cerrarSesion(sesion.id);
      if (mounted) Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando || _sesion == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pesa de leche')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesa de leche'),
        actions: [
          TextButton.icon(
            key: const ValueKey('pesa.cerrar'),
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
            label: const Text('Cerrar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ContadorSesion(
              key: const ValueKey('pesa.contador'),
              lecheriaId: widget.lecheriaId,
              sesionId: _sesion!.id,
            ),
            const SizedBox(height: 16),
            ScanField(
              key: const ValueKey('pesa.identificador'),
              controller: _identCtrl,
              focusNode: _identFocus,
              labelText: 'Identificador',
              prefixIcon: const Icon(Icons.nfc),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              onSubmitted: _buscarAnimal,
            ),
            if (_mensaje != null) ...[
              const SizedBox(height: 8),
              Text(_mensaje!, style: TextStyle(color: Colors.red.shade700)),
            ],
            if (_animalActual != null) ...[
              const SizedBox(height: 16),
              Text(
                _animalActual!.identificador,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              QuickNumberField(
                key: const ValueKey('pesa.litros'),
                controller: _litrosCtrl,
                focusNode: _litrosFocus,
                labelText: 'Litros',
                suffixText: 'L',
                autofocus: true,
                onSubmitted: (_) => _guardarLitros(),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const ValueKey('pesa.guardar'),
                onPressed: _guardarLitros,
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            Expanded(
              child: StreamBuilder<List<PesaLecheRow>>(
                stream: pesasRepo.observarPesasDeSesion(_sesion!.id),
                builder: (context, snapshot) {
                  final pesas = snapshot.data ?? const [];
                  if (pesas.isEmpty) {
                    return const Center(
                      child: Text('Todavía no hay pesadas en esta sesión.'),
                    );
                  }
                  return ListView.builder(
                    itemCount: pesas.length,
                    itemBuilder: (context, i) {
                      final p = pesas[pesas.length - 1 - i];
                      return FutureBuilder<AnimalRow?>(
                        future:
                            (db.select(db.animales)
                                  ..where((t) => t.id.equals(p.animalId)))
                                .getSingleOrNull(),
                        builder: (context, animalSnap) {
                          return ListTile(
                            leading: const Icon(Icons.water_drop_outlined),
                            title: Text(animalSnap.data?.identificador ?? '…'),
                            trailing: Text('${p.litros.toStringAsFixed(1)} L'),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContadorSesion extends StatelessWidget {
  const _ContadorSesion({
    super.key,
    required this.lecheriaId,
    required this.sesionId,
  });

  final String lecheriaId;
  final String sesionId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PesaLecheRow>>(
      stream: pesasRepo.observarPesasDeSesion(sesionId),
      builder: (context, snapshot) {
        final pesadas = snapshot.data?.length ?? 0;
        return FutureBuilder<int>(
          future: animalesRepo.contarPorGrupo(lecheriaId, GrupoAnimal.enOrdeno),
          builder: (context, totalSnap) {
            final total = totalSnap.data ?? 0;
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kVerdeLeche.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$pesadas de $total pesadas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Icon(
                    pesadas >= total && total > 0
                        ? Icons.check_circle
                        : Icons.pending_outlined,
                    color: kVerdeLeche,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ResumenSesionWidget extends StatelessWidget {
  const _ResumenSesionWidget({required this.resumen});

  final ResumenSesion resumen;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vacas pesadas: ${resumen.totalVacas}'),
        Text('Total: ${resumen.totalLitros.toStringAsFixed(1)} L'),
        Text('Promedio: ${resumen.promedio.toStringAsFixed(1)} L'),
        Text('Máximo: ${resumen.maximo.toStringAsFixed(1)} L'),
        Text('Mínimo: ${resumen.minimo.toStringAsFixed(1)} L'),
        if (resumen.variacionRespectoAnterior != null)
          Text(
            'Variación vs. sesión anterior: '
            '${resumen.variacionRespectoAnterior! >= 0 ? '+' : ''}'
            '${resumen.variacionRespectoAnterior!.toStringAsFixed(1)} L',
          ),
      ],
    );
  }
}
