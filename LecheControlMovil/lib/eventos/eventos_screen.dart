import 'package:flutter/material.dart';

import '../app/etiqueta_animal.dart';
import '../app/widgets/scan_field.dart';
import '../data/domain/grupos.dart';
import '../data/local/database.dart';
import '../data/repositories/animales_repository.dart';
import '../services.dart';
import 'alta_animal_sheet.dart';
import 'tarjeta_animal.dart';

/// **Eventos** (Módulo 1): identificar un animal y anotarle lo que le pasó.
///
/// Antes se llamaba Trabajo, que no decía qué había adentro. Es la misma
/// pantalla de siempre —identificar y anotar con botones grandes— con dos
/// cosas nuevas:
///
/// 1. **El arete se puede buscar a pedazos.** Se escribe `117` y la lista se
///    acorta sola. Sentado con la hoja del peón nadie digita `542117` veinte
///    veces, y el lector RFID sigue funcionando igual: manda el código
///    completo de un golpe y cae directo en la ficha.
/// 2. **Cada evento lleva su día**, que se escoge dentro del propio evento.
///    Ver [TarjetaAnimal].
class EventosScreen extends StatefulWidget {
  const EventosScreen({
    super.key,
    required this.lecheriaId,
    required this.usuarioId,
  });

  final String lecheriaId;
  final String usuarioId;

  @override
  State<EventosScreen> createState() => _EventosScreenState();
}

class _EventosScreenState extends State<EventosScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  AnimalRow? _animal;
  List<AnimalEncontrado> _candidatos = const [];
  bool _buscando = false;
  bool _noEncontrado = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Mientras se escribe: acorta la lista, sin decidir por nadie.
  Future<void> _filtrar(String texto) async {
    setState(() {
      _animal = null;
      _noEncontrado = false;
    });
    if (texto.trim().isEmpty) {
      setState(() => _candidatos = const []);
      return;
    }
    final encontrados = await animalesRepo.buscarParecidos(
      widget.lecheriaId,
      texto,
    );
    // Entre que se escribió y que respondió la base pudo haberse escrito otra
    // cosa: si el texto ya no es el mismo, esta respuesta llegó tarde y se
    // descarta, o la lista parpadearía con resultados viejos.
    if (!mounted || _ctrl.text != texto) return;
    setState(() => _candidatos = encontrados);
  }

  /// Al dar enter o al leer un arete con el lector: se busca el exacto y se
  /// entra de una. El lector manda el código completo, así que acá no hay nada
  /// que escoger.
  Future<void> _buscar([String? valor]) async {
    final identificador = (valor ?? _ctrl.text).trim();
    if (identificador.isEmpty) return;
    setState(() {
      _buscando = true;
      _noEncontrado = false;
      _animal = null;
      _candidatos = const [];
    });
    final animal = await animalesRepo.buscarPorIdentificador(
      widget.lecheriaId,
      identificador,
    );
    if (!mounted) return;
    setState(() {
      _buscando = false;
      _animal = animal;
      _noEncontrado = animal == null;
    });
  }

  void _escoger(AnimalRow animal) {
    setState(() {
      _animal = animal;
      _candidatos = const [];
    });
    _focus.unfocus();
  }

  void _limpiar() {
    _ctrl.clear();
    setState(() {
      _animal = null;
      _candidatos = const [];
      _noEncontrado = false;
    });
    _focus.requestFocus();
  }

  Future<void> _refrescarAnimal() async {
    final animal = _animal;
    if (animal == null) return;
    final actualizado = await animalesRepo.buscarPorIdentificador(
      widget.lecheriaId,
      animal.identificador,
    );
    if (mounted) setState(() => _animal = actualizado);
  }

  Future<void> _altaAnimalNuevo() async {
    final identificador = _ctrl.text.trim();
    final creado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AltaAnimalSheet(
        lecheriaId: widget.lecheriaId,
        identificadorInicial: identificador,
      ),
    );
    if (creado == true) await _buscar(identificador);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eventos')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ScanField(
                      key: const ValueKey('trabajo.identificador'),
                      controller: _ctrl,
                      focusNode: _focus,
                      labelText: 'Identificador (RFID o manual)',
                      prefixIcon: const Icon(Icons.nfc),
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.search,
                      onChanged: _filtrar,
                      onSubmitted: _buscar,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: const ValueKey('trabajo.buscar'),
                    onPressed: _buscando ? null : () => _buscar(),
                    icon: const Icon(Icons.search),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(child: _cuerpo()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cuerpo() {
    if (_buscando) return const Center(child: CircularProgressIndicator());

    final animal = _animal;
    if (animal != null) {
      return TarjetaAnimal(
        // La llave lleva el id para que al cambiar de animal la ficha se
        // reconstruya entera en vez de reusar el estado del anterior.
        key: ValueKey('eventos.tarjeta.${animal.id}'),
        animal: animal,
        lecheriaId: widget.lecheriaId,
        usuarioId: widget.usuarioId,
        onLimpiar: _limpiar,
        onCambio: _refrescarAnimal,
      );
    }
    if (_candidatos.isNotEmpty) return _lista();
    if (_noEncontrado || _ctrl.text.trim().isNotEmpty) {
      return _AnimalNoEncontrado(onAlta: _altaAnimalNuevo);
    }
    return const _EstadoInicial();
  }

  Widget _lista() => ListView.builder(
    itemCount: _candidatos.length,
    itemBuilder: (context, i) {
      final encontrado = _candidatos[i];
      final a = encontrado.animal;
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          key: ValueKey('eventos.candidato.${a.identificador}'),
          // El arete y el alias van los dos, y el alias se resalta cuando fue
          // **por él** que el animal apareció. Escribir «99» y ver salir la
          // 1542 sin explicación parece un filtro malo; con el alias marcado
          // se entiende de una.
          title: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: a.identificador,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (soloAlias(a.alias) case final texto?)
                  TextSpan(
                    text: '  ·  $texto',
                    style: TextStyle(
                      fontWeight: encontrado.porAlias
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: encontrado.porAlias
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ),
          subtitle: Text(
            '${GrupoAnimal.etiqueta(a.grupo)} · '
            '${EstadoReproductivo.etiqueta(a.estadoReproductivo)}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _escoger(a),
        ),
      );
    },
  );
}

class _EstadoInicial extends StatelessWidget {
  const _EstadoInicial();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.nfc, size: 72, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Escaneá o escribí el identificador del animal',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimalNoEncontrado extends StatelessWidget {
  const _AnimalNoEncontrado({required this.onAlta});

  final VoidCallback onAlta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.help_outline,
              size: 72,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No encontramos ese animal',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '¿Es un animal nuevo? Registralo de una vez.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const ValueKey('trabajo.alta.abrir'),
              onPressed: onAlta,
              icon: const Icon(Icons.add),
              label: const Text('Registrar animal nuevo'),
            ),
          ],
        ),
      ),
    );
  }
}
