package com.example.gymflow

import io.flutter.embedding.android.FlutterFragmentActivity

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
class MainActivity : FlutterFragmentActivity()
