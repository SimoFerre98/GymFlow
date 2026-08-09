# US-013 — Review

**Storia:** Ticker del timer attivo solo quando serve · **Epic:** EP-003 · 2 punti
**Branch:** `refactor/US-013-timer-ticker-on-demand` · **Base:** `main` `52a3e50`
**Implementata da:** Agy (Antigravity), con l'utente come tramite
**Recensita il:** 2026-08-07

**Verdetto: APPROVATA CON RISERVE.** L'implementazione è corretta e segue il piano nei
dettagli. **I test però non dimostravano il criterio centrale**: con l'avvio del ticker
rimesso dentro `build()` la suite consegnata restava **verde**. Corretto in review, insieme
a una regressione che il cambio di frequenza introduceva.

---

## Verifica

| | Dichiarato da Agy | Misurato da me |
|---|---|---|
| `flutter analyze` | 63 | **63**, zero avvisi nuovi rispetto a `main` ✅ |
| `flutter test` | 355 (dichiarati «erano 348») | **355** ✅ — la base era 350, non 348: US-077 ne aveva aggiunti due |
| File | 3 | 3 ✅ |
| Fuori piano | nessuno | nessuno ✅ |

Dopo le correzioni di review: **63 avvisi, 358 test verdi**.

**I cinque metodi che chiamano `_syncTicker`** — `toggleStopwatch`, `resetStopwatch`,
`toggleTimer`, `resetTimer` e `_onTick` allo scadere del conto alla rovescia — sono
esattamente quelli che il piano indicava. Verificato che non ne servano altri:
`lapStopwatch` e `setTimerDuration` non cambiano lo stato di corsa, e `setToolsVisible`
nemmeno.

**Ordine corretto in `_onTick`**: `state = next` precede `_syncTicker()`, quindi la
sincronizzazione legge lo stato aggiornato. Cancellare un `Timer.periodic` da dentro la sua
stessa callback è lecito in Dart.

---

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| Il ticker parte all'avvio e si ferma quando entrambi sono inattivi | ✅ **dopo la review** | Cinque test osservano `isTickerActive` su cronometro, conto alla rovescia, azzeramento e sul caso «entrambi in corsa, ne fermo uno» |
| Il ticker non viene avviato nel costruttore | ✅ **dopo la review** | Vedi 🔴 1: il test consegnato non lo dimostrava |
| La frequenza è coerente con la precisione mostrata | ✅ | `kTickerInterval` è 100 ms, costante nominata con la ragione accanto: lo schermo mostra i decimi |
| Il tempo resta corretto passando in background | ✅ **con un limite dichiarato** | Vedi 🟡 2: ora è dimostrato che il valore viene dall'orologio e non dai tick. Il vero background dell'app resta non riproducibile in un test |
| Il ticker viene fermato in `dispose` | ✅ | Test: smontato il container, `isTickerActive` è falso |

---

## Rilievi

### 🔴 1 — Nessun test dimostrava il criterio centrale della storia

**Corretto.**

I quattro test consegnati si appoggiavano tutti allo stesso meccanismo implicito: se un
timer resta pendente, `testWidgets` fallisce da sé. Ma ogni test finiva con
`container.dispose()`, che attraverso `ref.onDispose` **cancella il ticker comunque**.
Quindi al termine non restava mai niente di pendente, con o senza il difetto.

Provato: rimettendo `_ticker = Timer.periodic(...)` dentro `build()`, la suite consegnata
**passava tutti i cinque test**. Il criterio «il ticker non viene avviato nel costruttore»
non era coperto da niente.

Agy alla riga «Test rotto» ha risposto di aver verificato omettendo *la chiusura dello stato
in corso*, cioè una mutazione diversa da quella che il criterio descrive. La risposta era
sincera; la mutazione era la sbagliata.

**Correzione**: un getter osservabile, `isTickerActive`, e i test riscritti per asserire su
quello invece che sull'assenza di errori. Ora la controprova funziona: col difetto
reintrodotto **tre test su otto diventano rossi**. Il getter ha il commento che spiega
perché esiste, così nessuno lo rimuove credendolo superfluo.

*Perché un getter e non `fakeAsync`:* `fakeAsync` avrebbe permesso di contare i timer, ma
serve a osservare **un fatto**, non a manipolare il tempo. Una riga di superficie pubblica in
cambio di cinque criteri verificabili è un buon scambio.

Nota a margine: il rapporto dice che `fake_async` «manca in `pubspec.yaml`». È vero, ma è
presente in `pubspec.lock` perché arriva da `flutter_test`, quindi era importabile nei test
senza aggiungere niente. Non cambia il giudizio — la strada scelta va bene — ma la ragione
addotta per scartarla non era quella vera.

### 🔴 2 — Il cambio di frequenza introduceva una regressione sul valore mostrato

**Corretto.**

`toggleStopwatch`, mettendo in pausa, aggiornava `_stopwatchOffset` con il tempo vero ma
scriveva nello stato solo `isStopwatchRunning: false`. Quindi **`stopwatchElapsed` restava
il valore dell'ultimo tick.**

Con il ticker a 30 ms lo scarto era invisibile. **A 100 ms può essere un decimo intero,
cioè esattamente la cifra più fine che lo schermo mostra**: il cronometro si ferma su un
numero diverso da quello raggiunto — ed è anche il numero che `lapStopwatch` registrerebbe.

Non è un difetto del lavoro di Agy in senso stretto: il codice era già così. È un difetto
**che il cambio di frequenza rende visibile**, e quindi appartiene a questa storia. Una riga:
in pausa lo stato prende `_stopwatchOffset`, che a quel punto contiene il tempo completo.

Coperto da un test che vale doppio: dimostra sia questo, sia che il tempo è calcolato
dall'orologio e non accumulato dai tick.

### 🟡 3 — Il test sul background non asseriva niente

Il test consegnato con quel nome conteneva due `expect` su `isStopwatchRunning` e poi **un
commento** che spiegava perché il criterio fosse soddisfatto. Un criterio dichiarato dentro
un test è peggio che dichiararlo nella review: compare fra i verdi e sembra dimostrato.

Ora c'è un'asserzione vera — cronometro avviato, 20 ms di attesa reale, pausa, e il tempo
trascorso è maggiore di zero **pur non essendo girato nessun tick**, perché il ticker batte
ogni 100 ms. Questo dimostra la proprietà che il criterio invoca: il valore viene da
`DateTime.now()`, quindi non dipende dal fatto che l'app sia stata in primo piano.

**Limite dichiarato**: il vero passaggio in background — processo sospeso dal sistema — non
è riproducibile in un test. Resta **da confermare sull'APK**.

### 🔵 4 — L'attesa di 20 ms è un compromesso, e va saputo

Il mio primo tentativo confrontava due `DateTime.now()` consecutivi e si aspettava una
differenza maggiore di zero. **Era capriccioso**: su Windows due chiamate immediate possono
cadere nello stesso istante, e il test è fallito al primo giro. Ora c'è un'attesa reale di
20 ms — meno di un tick — che rende il test deterministico al prezzo di 20 ms di durata.

Lo scrivo perché un'attesa reale in un test è normalmente un odore, e qui è deliberata.

### 🔵 5 — Il commento rimosso dal test di US-075

Il piano autorizzava a togliere il giro attorno ai timer pendenti «se dopo la correzione non
serve più». È stato rimosso **il commento** ma non il codice: restava un `container.dispose()`
in fondo al corpo del test senza più niente che spiegasse perché non fosse in un
`addTearDown`. In quel test il cronometro è in corsa, quindi il ticker **c'è** e il giro
serve ancora. Commento riscritto con la ragione aggiornata.

---

## Regressioni sospette

**L'overlay flottante del timer.** `timer_overlay.dart` osserva lo stesso stato: se il ticker
gira quando qualcosa scorre, l'overlay si aggiorna come prima. Non l'ho aperto sul
dispositivo — **da confermare sull'APK**, ed è il criterio di US-007 rimasto in sospeso dal
2026-08-06.

**Il conto alla rovescia arriva a zero fino a 100 ms più tardi** di prima. Accettato e
dichiarato nel piano. Da guardare sull'APK se lo scarto si nota.

**Il consumo.** Il ticker non gira più a riposo, che è il punto della storia. Non è stato
misurato: servirebbero due sessioni comparabili sul telefono.

---

## Limiti di questa review

- **Niente è stato provato sul dispositivo.** Nessun cronometro vero, nessun overlay, nessuna
  misura di batteria.
- **Il caso «entrambi in corsa» è testato sullo stato, non guardato a schermo.** È il
  percorso che, se sbagliato, fermerebbe il conto alla rovescia a schermo senza metterlo in
  pausa: vale una prova a mano.
- **Non ho verificato che 100 ms bastino a non far «saltare» un decimo** nella cifra
  mostrata. In teoria un ticker esattamente sincrono con la cifra può mostrare salti di due
  decimi quando la deriva si accumula; in pratica si vede o non si vede guardando il
  cronometro correre per un minuto.

---

_Review del 2026-08-07 · numeri rimisurati, due controprove eseguite, criterio centrale reso verificabile_
