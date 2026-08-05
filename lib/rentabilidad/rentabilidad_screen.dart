import 'package:flutter/material.dart';

import '../app/formato.dart';
import '../data/local/database.dart';
import '../data/repositories/rentabilidad_repository.dart';
import '../hoja_vida/hoja_vida_screen.dart';
import '../services.dart';

/// Rentabilidad por vaca (Módulo 5): tabla del mes actual con ingreso, costo
/// y utilidad diaria por vaca en ordeño, más el top 5 de mejores/peores y
/// las candidatas a secar.
class RentabilidadScreen extends StatefulWidget {
  const RentabilidadScreen({super.key, required this.lecheriaId});

  final String lecheriaId;

  @override
  State<RentabilidadScreen> createState() => _RentabilidadScreenState();
}

class _RentabilidadScreenState extends State<RentabilidadScreen> {
  List<FilaRentabilidad>? _filas;
  ParametrosPeriodoRow? _periodo;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final ahora = DateTime.now();
    final periodo = await gastosRepo.obtenerPeriodo(
      widget.lecheriaId,
      ahora.year,
      ahora.month,
    );
    final filas = await rentabilidadRepo.calcularTabla(widget.lecheriaId);
    if (!mounted) return;
    setState(() {
      _periodo = periodo;
      _filas = filas;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rentabilidad'),
        actions: [
          IconButton(onPressed: _cargar, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : (_filas == null || _filas!.isEmpty)
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _periodo == null
                      ? 'Configurá los parámetros del mes en Gastos para '
                            'poder calcular la rentabilidad.'
                      : 'No hay vacas en ordeño con datos para calcular.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                key: const ValueKey('rentabilidad.lista'),
                padding: const EdgeInsets.all(16),
                children: [
                  _ResumenTotal(filas: _filas!),
                  const SizedBox(height: 20),
                  Text(
                    'Top 5 mayor utilidad',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  for (final f in rentabilidadRepo.top5MayorUtilidad(_filas!))
                    _FilaRentabilidadTile(fila: f),
                  const SizedBox(height: 20),
                  Text(
                    'Top 5 menor utilidad',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  for (final f in rentabilidadRepo.top5MenorUtilidad(_filas!))
                    _FilaRentabilidadTile(fila: f),
                  const SizedBox(height: 20),
                  Text(
                    'Candidatas a secar',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  for (final f in rentabilidadRepo.candidatasASecar(
                    _filas!,
                    _periodo?.umbralSecadoLitros ?? 8,
                  ))
                    _FilaRentabilidadTile(fila: f),
                  const SizedBox(height: 20),
                  Text(
                    'Detalle completo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  for (final f in _filas!) _FilaRentabilidadTile(fila: f),
                ],
              ),
            ),
    );
  }
}

class _ResumenTotal extends StatelessWidget {
  const _ResumenTotal({required this.filas});

  final List<FilaRentabilidad> filas;

  @override
  Widget build(BuildContext context) {
    final total = rentabilidadRepo.utilidadTotalPeriodo(filas);
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Utilidad diaria total', style: theme.textTheme.titleMedium),
            Text(
              colones(total),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: total >= 0
                    ? Colors.green.shade800
                    : theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaRentabilidadTile extends StatelessWidget {
  const _FilaRentabilidadTile({required this.fila});

  final FilaRentabilidad fila;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        title: Text(fila.animal.identificador),
        subtitle: Text(
          '${fila.litrosDia.toStringAsFixed(1)} L · '
          'Costo: ${colones(fila.costoTotalDia)}'
          '${fila.enRetiro ? ' · En retiro' : ''}',
        ),
        trailing: Text(
          colones(fila.utilidadDia),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: fila.utilidadDia >= 0
                ? Colors.green.shade800
                : theme.colorScheme.error,
          ),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HojaVidaScreen(animalId: fila.animal.id),
          ),
        ),
      ),
    );
  }
}
