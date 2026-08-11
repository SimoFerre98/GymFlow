package com.example.gymflow

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * `FlutterFragmentActivity` e non `FlutterActivity`, e non e una preferenza.
 *
 * Il plugin `health` registra il proprio `ActivityResultLauncher` per la
 * richiesta dei permessi di Health Connect, e quell'API vuole una
 * `ComponentActivity`. Con la `FlutterActivity` normale la registrazione non
 * avviene: `requestAuthorization` torna `false` **in silenzio** — niente
 * schermata di sistema, niente errore, niente in `logcat` a meno di guardare il
 * tag del plugin, che dice «Permission launcher not found».
 *
 * Trovato l'11 agosto provando l'app sul telefono, dopo aver scartato due
 * ipotesi sbagliate: i permessi mancanti nel manifest (veri, e corretti) e la
 * `configure()` mai chiamata (vera anche quella). Nessuna delle due bastava.
 */
class MainActivity : FlutterFragmentActivity() {

    /**
     * Il canale del recupero fuori dall'app: US-053.
     *
     * `TimerNotifier` (Dart) comanda il servizio da qui — avvia, metti in
     * pausa, prolunga, ferma — e legge il suo stato una volta, quando l'app
     * torna in primo piano. Non e il servizio a spingere gli eventi qui: un
     * `MethodChannel` verso un motore Flutter che potrebbe non esistere (l'app
     * in background, magari uccisa) fallirebbe in silenzio, e sarebbe fragile
     * proprio nel momento in cui serve di piu. Leggere lo stato **quando
     * l'app torna** non ha questo problema, perche a quel punto il motore c'e
     * di certo.
     */
    private val nomeCanale = "com.example.gymflow/timer_notification"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, nomeCanale)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        val fine = (call.argument<Number>("endTimeMillis"))?.toLong()
                        if (fine == null) {
                            result.error("argomento_mancante", "endTimeMillis", null)
                            return@setMethodCallHandler
                        }
                        avviaServizio(TimerForegroundService.ACTION_START, fine, null)
                        result.success(null)
                    }
                    "pause" -> {
                        val restante = (call.argument<Number>("remainingMillis"))?.toLong()
                        if (restante == null) {
                            result.error("argomento_mancante", "remainingMillis", null)
                            return@setMethodCallHandler
                        }
                        avviaServizio(TimerForegroundService.ACTION_SET_PAUSED, null, restante)
                        result.success(null)
                    }
                    "stop" -> {
                        avviaServizio(TimerForegroundService.ACTION_STOP, null, null)
                        result.success(null)
                    }
                    "getState" -> {
                        val stato = TimerForegroundService.statoCorrente
                        result.success(
                            if (stato == null) {
                                null
                            } else {
                                mapOf(
                                    "endTimeMillis" to stato.endTimeMillis,
                                    "inPausa" to stato.inPausa,
                                    "remainingAlPausaMillis" to stato.remainingAlPausaMillis,
                                )
                            },
                        )
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun avviaServizio(azione: String, endTimeMillis: Long?, remainingMillis: Long?) {
        val intent = Intent(this, TimerForegroundService::class.java).apply {
            action = azione
            if (endTimeMillis != null) {
                putExtra(TimerForegroundService.EXTRA_END_TIME_MILLIS, endTimeMillis)
            }
            if (remainingMillis != null) {
                putExtra(TimerForegroundService.EXTRA_REMAINING_MILLIS, remainingMillis)
            }
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
}
