import 'package:flutter/material.dart';

import '../data/domain/grupos.dart';
import '../data/local/database.dart';
import '../data/repositories/pesas_repository.dart';
import '../services.dart';

/// Hoja de vida de un animal (Módulo 1 y 6): identificación, estado actual y
/// el historial completo de eventos (reproductivos, sanitarios, de manejo) y
/// de pesas de leche, en dos pestañas.
class HojaVidaScreen extends StatelessWidget {
  const HojaVidaScreen({super.key, required this.animalId});

  final String animalId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AnimalRow?>(
      stream: animalesRepo.observarAnimal(animalId),
      builder: (context, snapshot) {
        final animal = snapshot.data;
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(animal?.identificador ?? 'Hoja de vida'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Eventos', icon: Icon(Icons.timeline)),
                  Tab(text: 'Pesas', icon: Icon(Icons.water_drop_outlined)),
                ],
              ),
            ),
            body: animal == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      _EncabezadoAnimal(animal: animal),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _TabEventos(animal: animal),
                            _TabPesas(animalId: animal.id),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _EncabezadoAnimal extends StatelessWidget {
  const _EncabezadoAnimal({required this.animal});

  final AnimalRow animal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enRetiro =
        animal.retiroLecheHasta != null &&
        animal.retiroLecheHasta!.isAfter(DateTime.now());
    return Container(
      width: double.infinity,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          Chip(label: Text(Sexo.etiqueta(animal.sexo))),
          Chip(label: Text(GrupoAnimal.etiqueta(animal.grupo))),
          Chip(label: Text(EstadoAnimal.etiqueta(animal.estado))),
          if (animal.sexo == Sexo.hembra)
            Chip(
              label: Text(
                EstadoReproductivo.etiqueta(animal.estadoReproductivo),
              ),
            ),
          if (animal.fechaProbableParto != null)
            Chip(
              avatar: const Icon(Icons.child_friendly_outlined, size: 18),
              label: Text(_fmt(animal.fechaProbableParto!)),
            ),
          if (enRetiro)
            Chip(
              backgroundColor: theme.colorScheme.errorContainer,
              avatar: const Icon(Icons.warning_amber, size: 18),
              label: Text('Retiro hasta ${_fmt(animal.retiroLecheHasta!)}'),
            ),
          if (animal.concentradoKgDia > 0)
            Chip(
              avatar: const Icon(Icons.grass_outlined, size: 18),
              label: Text('${animal.concentradoKgDia.toStringAsFixed(1)} kg/d'),
            ),
        ],
      ),
    );
  }

  String _fmt(DateTime f) => '${f.day}/${f.month}/${f.year}';
}

class _TabEventos extends StatelessWidget {
  const _TabEventos({required this.animal});

  final AnimalRow animal;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EventoAnimalRow>>(
      stream: eventosRepo.listarHojaVida(animal.id),
      builder: (context, snapshot) {
        final eventos = snapshot.data ?? const [];
        if (eventos.isEmpty) {
          return const Center(child: Text('Todavía no hay eventos.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: eventos.length,
          itemBuilder: (context, i) => _EventoTile(evento: eventos[i]),
        );
      },
    );
  }
}

class _EventoTile extends StatelessWidget {
  const _EventoTile({required this.evento});

  final EventoAnimalRow evento;

  IconData get _icono => switch (evento.tipo) {
    TipoEventoAnimal.sanidad => Icons.medical_services_outlined,
    TipoEventoAnimal.celo => Icons.favorite_outline,
    TipoEventoAnimal.monta => Icons.favorite_outline,
    TipoEventoAnimal.inseminacion => Icons.favorite_outline,
    TipoEventoAnimal.palpacion => Icons.fact_check_outlined,
    TipoEventoAnimal.secado => Icons.pause_circle_outline,
    TipoEventoAnimal.parto => Icons.child_friendly_outlined,
    TipoEventoAnimal.cambioGrupo => Icons.swap_horiz,
    TipoEventoAnimal.baja => Icons.remove_circle_outline,
    TipoEventoAnimal.concentrado => Icons.grass_outlined,
    _ => Icons.circle_outlined,
  };

  String get _subtitulo {
    final partes = <String>[];
    if (evento.detalle != null) partes.add(evento.detalle!);
    if (evento.dosis != null) partes.add('Dosis: ${evento.dosis}');
    if (evento.diasRetiro != null) {
      partes.add('${evento.diasRetiro} días de retiro');
    }
    if (evento.costo != null) {
      partes.add('Costo: \$${evento.costo!.toStringAsFixed(0)}');
    }
    if (evento.resultado != null) {
      partes.add(ResultadoPalpacion.etiqueta(evento.resultado!));
    }
    if (evento.toroPajilla != null) partes.add(evento.toroPajilla!);
    if (evento.grupoAnterior != null && evento.grupoNuevo != null) {
      partes.add(
        '${GrupoAnimal.etiqueta(evento.grupoAnterior!)} → '
        '${GrupoAnimal.etiqueta(evento.grupoNuevo!)}',
      );
    }
    if (evento.motivoBaja != null) {
      partes.add(MotivoBaja.etiqueta(evento.motivoBaja!));
    }
    if (evento.precioVenta != null) {
      partes.add('\$${evento.precioVenta!.toStringAsFixed(0)}');
    }
    if (evento.sexoCria != null) {
      partes.add('Cría: ${Sexo.etiqueta(evento.sexoCria!)}');
    }
    return partes.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final f = evento.fecha;
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(_icono, size: 20)),
        title: Text(TipoEventoAnimal.etiqueta(evento.tipo)),
        subtitle: _subtitulo.isEmpty ? null : Text(_subtitulo),
        trailing: Text('${f.day}/${f.month}/${f.year}'),
      ),
    );
  }
}

class _TabPesas extends StatelessWidget {
  const _TabPesas({required this.animalId});

  final String animalId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PesaHistorial>>(
      stream: pesasRepo.historialAnimal(animalId),
      builder: (context, snapshot) {
        final historial = (snapshot.data ?? const []).reversed.toList();
        if (historial.isEmpty) {
          return const Center(child: Text('Todavía no hay pesas.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: historial.length,
          itemBuilder: (context, i) {
            final p = historial[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.water_drop_outlined),
                title: Text('${p.litros.toStringAsFixed(1)} L'),
                trailing: Text(
                  '${p.fecha.day}/${p.fecha.month}/${p.fecha.year}',
                ),
              ),
            );
          },
        );
      },
    );
  }
}
