# US-075 — Review

**Storia:** Il cronometro si apre invece di mostrare una schermata rossa · **Epic:** EP-003 · 1 punto
**Branch:** `fix/US-075-time-tools-provider-crash` · **Base:** `main` `ba7cf93`
**Recensita il:** 2026-08-07

**Verdetto: APPROVATA.** Il difetto è riprodotto prima, corretto, e la correzione è
**verificata sul dispositivo**, non dedotta.

---

## Verifica

| | Esito |
|---|---|
| `flutter analyze` | **63** — uguale al baseline |
| `flutter test` | **348 verdi**, di cui 3 nuovi |
| `flutter build apk --debug` | riuscita |
| Installazione sul telefono | `adb install -r`, `firstInstallTime` invariato |
| **Cronometro aperto sul dispositivo** | ✅ nessuna schermata rossa, nessuna eccezione Flutter nel log |

Il diff è di un file: `time_tools_screen.dart`, 27 righe aggiunte e 33 rimosse.

---

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| Nessun `ErrorWidget` aprendo la schermata | ✅ | Test che monta la schermata e verifica `takeException()` nullo. **E verificato al contrario**: reintroducendo `didChangeDependencies` due test su tre diventano rossi con la stessa eccezione vista sul telefono |
| L'overlay si nasconde entrando e ricompare uscendo | ✅ | Test sul valore di `isToolsVisible` prima, durante e dopo lo smontaggio |
| Nessun provider modificato nei metodi di ciclo di vita | ✅ | `grep` su tutto `lib/src`: le tre chiamate a `setToolsVisible` erano le **uniche** modifiche di provider fuori da un callback in tutto il progetto. Ora l'unica resta in `dispose`, dentro un microtask |
| Il cronometro non si azzera | ✅ | Test: durata del conto alla rovescia e stato «in corsa» sopravvivono all'apertura e chiusura della schermata |
| I commenti-diario sono sostituiti | ✅ | Venti righe di tentativi e un `scheduleMicrotask` dal corpo vuoto, sostituiti dalla ragione delle due scelte |

---

## Due cose che il test ha insegnato sul servizio

Non sono difetti di questa storia, ma sono fatti che non erano scritti da nessuna parte e
che il prossimo che scrive un test sul tempo pagherebbe di nuovo.

**Il cronometro misura con `DateTime.now()`, quindi l'orologio finto dei test non lo
muove.** Il primo tentativo di test faceva avanzare il tempo di tre secondi e si aspettava
`stopwatchElapsed > 0`: è rimasto a zero. Di conseguenza anche `lapStopwatch()` rifiuta,
perché rifiuta a tempo zero. Lo stato verificabile senza orologio è quello che l'orologio
non governa: `isStopwatchRunning`, `timerDuration`, `stopwatchLaps` se già popolati.

**Il ticker a 30 ms non si ferma mai, e questo rompe `testWidgets`.** Un `ProviderContainer`
creato a mano va smontato **dentro** il corpo del test: in un `addTearDown` il framework
trova un timer pendente e fallisce prima. È il debito che US-013 traccia, e questa è la
prima volta che si vede il suo costo fuori dal telefono.

Entrambe sono annotate nei commenti dei test, dove servono.

---

## Rilievi

### 🟡 1 — Perché anche il solo aprire il menu dava la schermata rossa

Il difetto è stato riprodotto **toccando l'icona del menu sulla dashboard**, non entrando
nel cronometro. Dopo la correzione lo stesso gesto apre il menu, e il cronometro si apre a
sua volta.

Non ho una spiegazione completa del perché quel gesto arrivasse a costruire
`TimeToolsScreen`. Quello che posso affermare è più solido di un'ipotesi: un `grep` su
tutto `lib/src` mostra che **le tre chiamate corrette erano le uniche modifiche di
provider fuori da un callback in tutto il progetto**, quindi non esisteva un secondo
candidato; e dopo la correzione né il menu né il cronometro sollevano più niente. Se il
percorso del menu avesse avuto una causa propria, sarebbe ancora rotto.

### 🔵 2 — Il cronometro mostra «00:00:0»: l'ultima cifra è tagliata

Visibile nello screenshot di verifica. Il tempo è formattato su otto caratteri e il testo
non ci sta nella larghezza disponibile: l'ultima cifra viene troncata. **Non è questa
storia** — è grafica, e la schermata del tempo la ridisegna US-051 sul mockup 03 — ma è un
difetto vero e visibile, non un dettaglio di stile.

### 🔵 3 — I pulsanti sono rosso e verde acceso

«Azzera» è rosso e «Avvia» è verde, e le icone del menu sono blu, verde, giallo e viola.
Nessuno di questi colori è nella palette Indigo, dove l'azione è **una sola cosa**:
ambra. È il debito che US-022 e US-023 devono recuperare, e questa schermata ne è
l'esempio più netto.

---

## Fuori piano rilevato

Nessuno. Il diff contiene i due file previsti dal piano.

---

## Limiti di questa review

- **La riapparizione dell'overlay uscendo dalla schermata è provata da un test, non
  guardata sul telefono.** Il criterio di US-007 «l'overlay continua a comparire, essere
  trascinabile e controllabile» resta da confermare a mano, ed è lo stesso criterio la cui
  mancata verifica ha lasciato passare questo difetto.
- **Il caso del riaggancio** — la ragione per cui ho preferito `dispose` a `deactivate` —
  non è coperto da un test: costruirne uno richiederebbe un albero che sposta la schermata
  fra due rami, e non è la spesa giusta per un punto.
- **Non ho misurato se il microtask arriva abbastanza presto** perché l'overlay non
  lampeggi durante la transizione di uscita. Un microtask precede il frame successivo,
  quindi in teoria no; sul telefono non l'ho guardato.

---

_Review del 2026-08-07 · US-075 · difetto riprodotto sul dispositivo prima e dopo_
