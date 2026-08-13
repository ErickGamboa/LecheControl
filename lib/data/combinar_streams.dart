import 'dart:async';

/// Une dos streams en uno que emite cada vez que **cualquiera** de los dos
/// cambia, usando el último valor conocido del otro.
///
/// Existe porque `a.asyncExpand((x) => b.map(...))` —que es lo que parece
/// hacer lo mismo— tiene una trampa: mientras el stream interior siga abierto,
/// el exterior queda **pausado**. Con streams de Drift, que nunca terminan,
/// eso significa que los cambios del primero no vuelven a llegar nunca: se
/// refrescaba media pantalla y la otra media se quedaba congelada.
///
/// No emite hasta tener un valor de cada lado, así que quien escucha nunca
/// recibe un resultado a medias.
Stream<R> combinarUltimos<A, B, R>(
  Stream<A> a,
  Stream<B> b,
  R Function(A, B) unir,
) {
  late final StreamController<R> control;
  StreamSubscription<A>? subA;
  StreamSubscription<B>? subB;
  late A ultimoA;
  late B ultimoB;
  var hayA = false;
  var hayB = false;

  void emitir() {
    if (hayA && hayB) control.add(unir(ultimoA, ultimoB));
  }

  control = StreamController<R>(
    onListen: () {
      subA = a.listen(
        (valor) {
          ultimoA = valor;
          hayA = true;
          emitir();
        },
        onError: control.addError,
      );
      subB = b.listen(
        (valor) {
          ultimoB = valor;
          hayB = true;
          emitir();
        },
        onError: control.addError,
      );
    },
    onPause: () {
      subA?.pause();
      subB?.pause();
    },
    onResume: () {
      subA?.resume();
      subB?.resume();
    },
    onCancel: () async {
      await subA?.cancel();
      await subB?.cancel();
    },
  );

  return control.stream;
}
