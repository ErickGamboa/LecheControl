import 'package:leche_control/app_bootstrap.dart' as app;

Future<void> main() async {
  await app.bootstrapLecheControl();
  app.runLecheControlApp();
}
