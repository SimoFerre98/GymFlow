import 'package:flutter/services.dart';

/// Lo stato del servizio nativo del recupero, letto quando l'app torna in
/// primo piano.
///
/// Non e un `push`: il servizio non spinge eventi dentro Flutter mentre l'app
/// e in background, perche il motore potrebbe non esistere in quel momento (o
/// essere stato terminato dal sistema) e un canale verso il nulla fallirebbe
/// in silenzio proprio quando servirebbe di piu. Si legge invece **una
/// volta**, quando l'app torna visibile: a quel punto il motore c'e per
/// certo.
class StatoServizioTimer {
  const StatoServizioTimer({
    required this.orarioFine,
    required this.inPausa,
    required this.restanteAllaPausa,
  });

  final DateTime orarioFine;
  final bool inPausa;
  final Duration restanteAllaPausa;

  /// Quanto resta **ora**, in tutti e due gli stati.
  Duration restanteOra() =>
      inPausa ? restanteAllaPausa : orarioFine.difference(DateTime.now());
}

/// Il lato Dart del servizio in primo piano che tiene vivo il recupero fuori
/// dall'app: US-053.
///
/// Un'interfaccia e non una classe sola per la stessa ragione di `AvvisiTempo`
/// in `timer_service.dart`: parla con un canale di piattaforma che in un test
/// non esiste, e senza poterla sostituire nessuno dei comportamenti — quando
/// si avvia il servizio, quando no, come si riconcilia lo stato al ritorno —
/// sarebbe dimostrabile.
abstract class TimerNotificationChannel {
  /// Il recupero parte, o riparte da una pausa.
  Future<void> avvia(DateTime orarioFine);

  /// Il recupero si e messo in pausa dentro l'app: la notifica deve fermarsi
  /// sul tempo restante invece di continuare a scendere.
  Future<void> metteInPausa(Duration restante);

  /// Il recupero e stato azzerato, o e scaduto: via la notifica, via il
  /// servizio.
  Future<void> ferma();

  /// Lo stato del servizio, se e attivo. `null` se non lo e — non e mai stato
  /// avviato, e stato fermato, o la piattaforma non lo supporta.
  Future<StatoServizioTimer?> leggiStato();
}

/// Quello vero: parla con `TimerForegroundService` via un canale nativo.
///
/// Ogni chiamata e avvolta in un `try`/`catch` silenzioso e non per
/// distrazione: su una piattaforma senza questo canale — iOS, desktop, i test
/// — invocarlo lancia `MissingPluginException`. Il recupero **dentro l'app**
/// non deve fermarsi per questo: e il criterio «negato il permesso, o assente
/// il canale, il timer funziona comunque dentro l'app», e qui si applica alla
/// lettera anche al canale stesso, non solo al permesso.
class TimerNotificationChannelAndroid implements TimerNotificationChannel {
  TimerNotificationChannelAndroid({MethodChannel? canale})
    : _canale =
          canale ??
          const MethodChannel('com.example.gymflow/timer_notification');

  final MethodChannel _canale;

  @override
  Future<void> avvia(DateTime orarioFine) async {
    try {
      await _canale.invokeMethod('start', {
        'endTimeMillis': orarioFine.millisecondsSinceEpoch,
      });
    } catch (_) {
      // Vedi il commento della classe.
    }
  }

  @override
  Future<void> metteInPausa(Duration restante) async {
    try {
      await _canale.invokeMethod('pause', {
        'remainingMillis': restante.inMilliseconds,
      });
    } catch (_) {}
  }

  @override
  Future<void> ferma() async {
    try {
      await _canale.invokeMethod('stop');
    } catch (_) {}
  }

  @override
  Future<StatoServizioTimer?> leggiStato() async {
    try {
      final mappa = await _canale.invokeMapMethod<String, Object?>(
        'getState',
      );
      if (mappa == null) return null;
      return StatoServizioTimer(
        orarioFine: DateTime.fromMillisecondsSinceEpoch(
          mappa['endTimeMillis'] as int,
        ),
        inPausa: mappa['inPausa'] as bool,
        restanteAllaPausa: Duration(
          milliseconds: mappa['remainingAlPausaMillis'] as int,
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
