import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Configurazione applicata automaticamente a tutti i test di questa cartella.
///
/// `AppTheme` costruisce la scala tipografica con `GoogleFonts.outfitTextTheme`,
/// che di default scarica il font a runtime. Nei test la rete non e
/// disponibile e il tentativo fa fallire il caso con
/// `Failed to load font with url: ...`, per un motivo che non ha nulla a che
/// vedere con cio che si sta verificando.
///
/// Disattivando il recupero a runtime, GoogleFonts ripiega sul font di sistema:
/// i test verificano struttura e valori del tema, non il disegno dei glifi.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
