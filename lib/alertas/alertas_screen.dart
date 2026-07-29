import 'package:flutter/material.dart';

import '../data/repositories/alertas_repository.dart';
import '../hoja_vida/hoja_vida_screen.dart';
import '../services.dart';

/// Alertas reproductivas y de manejo (Módulo 9): celo esperado, confirmar
/// preñez, vacía hace mucho, próxima a secar, próxima a parir y fin de
/// retiro de leche. Tocar una alerta lleva a la hoja de vida del animal.
class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key, required this.lecheriaId});

  final String lecheriaId;

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  late Future<List<Alerta>> _alertasFuture;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _alertasFuture = alertasRepo.generarAlertas(widget.lecheriaId);
  }

  Future<void> _refrescar() async {
    setState(_cargar);
    await _alertasFuture;
  }

  IconData _icono(TipoAlerta tipo) => switch (tipo) {
    TipoAlerta.celoEsperado => Icons.favorite_outline,
    TipoAlerta.confirmarPreniez => Icons.fact_check_outlined,
    TipoAlerta.vaciaHaceMucho => Icons.hourglass_empty,
    TipoAlerta.proximaSecar => Icons.pause_circle_outline,
    TipoAlerta.proximaParir => Icons.child_friendly_outlined,
    TipoAlerta.finRetiro => Icons.warning_amber,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas'),
        actions: [
          IconButton(onPressed: _refrescar, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<Alerta>>(
        future: _alertasFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final alertas = snapshot.data!;
          if (alertas.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No hay alertas pendientes. ¡Buen trabajo!',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refrescar,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: alertas.length,
              itemBuilder: (context, i) {
                final a = alertas[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(_icono(a.tipo))),
                    title: Text(a.titulo),
                    subtitle: Text('${a.animal.identificador} · ${a.mensaje}'),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HojaVidaScreen(animalId: a.animal.id),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
