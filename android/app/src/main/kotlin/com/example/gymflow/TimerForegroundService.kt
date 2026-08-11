package com.example.gymflow

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat

/**
 * Il recupero prosegue fuori dall'app: US-053.
 *
 * È un servizio in primo piano, non una notifica sola. Una notifica normale
 * non basta a garantire «il conteggio prosegue con l'app in background e a
 * schermo bloccato»: quando il sistema toglie risorse a un'app in background —
 * su Samsung è aggressivo — il `Timer` di Dart si ferma con lei. Un servizio in
 * primo piano tiene il processo vivo.
 *
 * **Il servizio è la fonte di verità mentre `TimerNotifier` non è raggiungibile
 * — cioè quando l'app non è in primo piano.** Non tiene un proprio contatore
 * che avanza tick per tick: calcola il resto da un `orarioFine` assoluto
 * (`endTimeMillis - now()`), così i due lati — questo servizio e il ticker di
 * Dart — non possono andare fuori sincrono fra loro, perché nessuno dei due
 * accumula un errore: entrambi leggono lo stesso orologio.
 *
 * I comandi della notifica — pausa, prolunga — **non richiedono che Flutter sia
 * vivo**: li gestisce un `BroadcastReceiver` interno che aggiorna lo stato di
 * questo servizio e basta. Quando l'app torna in primo piano, è lei a chiedere
 * lo stato di qui (vedi `MainActivity.STATE` nel canale), non il contrario:
 * spingere un evento in un motore Flutter che potrebbe non esistere e' fragile,
 * leggerlo quando l'app torna e' l'unica forma che non dipende da *quando*
 * l'utente riapre l'app.
 *
 * ⚠️ **Non verificato su un dispositivo reale.** Il tipo di servizio in primo
 * piano (`specialUse`), il comportamento sotto l'ottimizzazione batteria di
 * One UI, e l'aspetto vero della notifica sono tre cose che un `flutter build`
 * non può dimostrare.
 */
class TimerForegroundService : Service() {

    companion object {
        /** Da Dart: il timer parte, o riparte da una pausa. */
        const val ACTION_START = "com.example.gymflow.timer.START"

        /** Da Dart: il timer si e messo in pausa dentro l'app. */
        const val ACTION_SET_PAUSED = "com.example.gymflow.timer.SET_PAUSED"

        /** Dal pulsante della notifica: alterna, non impone — la notifica non
         * sa se Dart e vivo, quindi decide da sola guardando il proprio stato. */
        const val ACTION_PAUSE_RESUME = "com.example.gymflow.timer.PAUSE_RESUME"

        /** Dal pulsante della notifica. */
        const val ACTION_EXTEND = "com.example.gymflow.timer.EXTEND"

        /** Da Dart o dalla notifica: il timer e stato azzerato o e scaduto. */
        const val ACTION_STOP = "com.example.gymflow.timer.STOP"

        const val EXTRA_END_TIME_MILLIS = "endTimeMillis"
        const val EXTRA_REMAINING_MILLIS = "remainingMillis"

        /** Quanto aggiunge «prolunga»: 30 s, lo stesso passo dei tempi pronti. */
        const val ESTENSIONE_MILLIS = 30_000L

        private const val CANALE_ID = "timer_recupero"
        private const val NOTIFICA_ID = 42

        /**
         * Lo stato corrente, letto da `MainActivity` quando l'app torna in
         * primo piano. `null` se il servizio non è (mai stato) attivo.
         *
         * Un campo statico e non un `Binder` restituito da `onBind`: il
         * servizio può morire e rinascere (Android lo può ricreare), e un
         * riferimento al `Binder` di prima sarebbe stantio. Questo campo
         * invece lo scrive il servizio vivo, ogni volta che il suo stato
         * cambia — e la lettura è innocua se il servizio non c'è: resta
         * `null`, e `MainActivity` lo sa gestire.
         */
        @Volatile
        var statoCorrente: StatoTimer? = null
    }

    /** Il resto e la pausa, cosi come le vede chi guarda la notifica. */
    data class StatoTimer(
        val endTimeMillis: Long,
        val inPausa: Boolean,
        val remainingAlPausaMillis: Long,
    ) {
        fun restanteOra(): Long =
            if (inPausa) remainingAlPausaMillis else endTimeMillis - System.currentTimeMillis()
    }

    private var stato: StatoTimer? = null
    private val handler = Handler(Looper.getMainLooper())
    private var ricevitore: BroadcastReceiver? = null

    private val aggiornaOgniSecondo = object : Runnable {
        override fun run() {
            val s = stato ?: return
            if (!s.inPausa && s.restanteOra() <= 0) {
                fermaServizio()
                return
            }
            aggiornaNotifica()
            handler.postDelayed(this, 1_000)
        }
    }

    override fun onCreate() {
        super.onCreate()
        creaCanale()

        ricevitore = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                when (intent.action) {
                    ACTION_PAUSE_RESUME -> alternaPausa()
                    ACTION_EXTEND -> estendi()
                    ACTION_STOP -> fermaServizio()
                }
            }
        }
        val filtro = IntentFilter().apply {
            addAction(ACTION_PAUSE_RESUME)
            addAction(ACTION_EXTEND)
            addAction(ACTION_STOP)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(ricevitore, filtro, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(ricevitore, filtro)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // `startForeground` **prima** di guardare l'azione, sempre. Android
        // impone che un servizio avviato con `startForegroundService` — ed e
        // cosi che `MainActivity` lo avvia sempre, per ogni azione — lo chiami
        // entro pochi secondi da *questa* chiamata, altrimenti termina l'app.
        // Se l'azione risulta essere STOP, o una pausa senza un timer attivo,
        // si ferma comunque subito dopo: il contratto e stato onorato,
        // l'utente non vede niente di persistente.
        startForeground(NOTIFICA_ID, costruisciNotifica())

        when (intent?.action) {
            ACTION_START -> {
                val fine = intent.getLongExtra(EXTRA_END_TIME_MILLIS, -1L)
                if (fine <= 0) {
                    fermaServizio()
                    return START_NOT_STICKY
                }
                stato = StatoTimer(fine, inPausa = false, remainingAlPausaMillis = 0)
                statoCorrente = stato
                aggiornaNotifica()
                handler.removeCallbacks(aggiornaOgniSecondo)
                handler.post(aggiornaOgniSecondo)
            }
            ACTION_SET_PAUSED -> {
                val s = stato
                if (s == null) {
                    // Non c'e un timer attivo di cui tenere il segno: niente
                    // da mettere in pausa, e la notifica appena mostrata sopra
                    // non deve restare.
                    fermaServizio()
                    return START_NOT_STICKY
                }
                val restante = intent.getLongExtra(EXTRA_REMAINING_MILLIS, s.restanteOra())
                stato = s.copy(inPausa = true, remainingAlPausaMillis = restante)
                aggiornaNotifica()
            }
            ACTION_STOP -> fermaServizio()
            else -> {
                // Azione mancante o non riconosciuta: stesso trattamento di
                // STOP, non si resta appesi in primo piano senza uno stato.
                if (stato == null) fermaServizio()
            }
        }
        // NOT_STICKY: se il sistema uccide il servizio, non deve ripartire da
        // solo senza sapere piu da quale timer — l'app lo riavvierebbe con lo
        // stato giusto quando l'utente la riapre.
        return START_NOT_STICKY
    }

    private fun alternaPausa() {
        val s = stato ?: return
        stato = if (s.inPausa) {
            s.copy(
                inPausa = false,
                endTimeMillis = System.currentTimeMillis() + s.remainingAlPausaMillis,
            )
        } else {
            s.copy(inPausa = true, remainingAlPausaMillis = s.restanteOra())
        }
        aggiornaNotifica()
    }

    private fun estendi() {
        val s = stato ?: return
        stato = if (s.inPausa) {
            s.copy(remainingAlPausaMillis = s.remainingAlPausaMillis + ESTENSIONE_MILLIS)
        } else {
            s.copy(endTimeMillis = s.endTimeMillis + ESTENSIONE_MILLIS)
        }
        aggiornaNotifica()
    }

    private fun creaCanale() {
        val manager = getSystemService(NotificationManager::class.java)
        val canale = NotificationChannel(
            CANALE_ID,
            "Recupero",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Il conto alla rovescia del recupero mentre l'app è in background"
            setShowBadge(false)
        }
        manager.createNotificationChannel(canale)
    }

    private fun costruisciNotifica(): android.app.Notification {
        val s = stato
        val restanteMillis = s?.restanteOra()?.coerceAtLeast(0) ?: 0
        val minuti = restanteMillis / 60_000
        val secondi = (restanteMillis / 1_000) % 60
        val testoTempo = String.format("%02d:%02d", minuti, secondi)

        fun azione(action: String) = PendingIntent.getBroadcast(
            this,
            action.hashCode(),
            Intent(action),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val etichettaPausa = if (s?.inPausa == true) "Riprendi" else "Pausa"

        return NotificationCompat.Builder(this, CANALE_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(if (s?.inPausa == true) "Recupero in pausa" else "Recupero")
            .setContentText(testoTempo)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_STOPWATCH)
            .addAction(0, etichettaPausa, azione(ACTION_PAUSE_RESUME))
            .addAction(0, "+30s", azione(ACTION_EXTEND))
            .build()
    }

    private fun aggiornaNotifica() {
        statoCorrente = stato
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICA_ID, costruisciNotifica())
    }

    private fun fermaServizio() {
        handler.removeCallbacks(aggiornaOgniSecondo)
        stato = null
        statoCorrente = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onDestroy() {
        handler.removeCallbacks(aggiornaOgniSecondo)
        ricevitore?.let { unregisterReceiver(it) }
        statoCorrente = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
