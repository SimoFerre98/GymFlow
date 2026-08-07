# US-047 — Review

**Storia:** Metriche dal vivo durante la sessione · **Epic:** EP-010 · 5 punti
**Branch:** `feature/US-047-live-metrics` · **Base:** `main` `6b3f15e`
**Recensita il:** 2026-08-07 · **Chi:** orchestratore (non l'autore del codice)

**Verdetto: APPROVATA CON RISERVE.** I due rilievi bloccanti sono stati corretti in
review (commit `US-047: correzioni di review`). Restano una decisione di prodotto e tre
criteri che non si chiudono senza dispositivo.

---

## Premessa: com'è arrivata questa storia

Il lavoro **non era su un branch**. Era non committato nella cartella principale,
mescolato con quello di US-050, su un branch indietro di un commit rispetto a `main`.
La separazione è documentata più sotto, perché ha conseguenze su come vanno letti i
numeri del rapporto di consegna.

**Il rapporto dichiarava 62 avvisi contro un baseline di 63, e il calo non era un
merito di questa storia.** Veniva dalla riscrittura non richiesta del dialogo
`_finishWorkout`, che cancellava la variabile inutilizzata `selectedTime`
(`active_session_screen.dart:153`) — uno dei 63 avvisi, tracciato da US-030. La
riscrittura è stata rimossa: era fuori dal mandato, cambiava il flusso di chiusura
dell'allenamento e nel farlo metteva `workout_summary_title` («Workout Summary») come
titolo di un dialogo di conferma. Il numero vero di questa storia è **63, uguale al
baseline**.

---

## Verifica, rifatta

Misurata nel worktree `../GF047`, non presa dal rapporto.

| | Esito |
|---|---|
| `flutter analyze` | **63** — baseline rimisurato su `main`: 63 |
| `flutter test` | **329 verdi**, di cui 14 nuovi |
| `flutter build apk --debug` | riuscita |

---

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| Calorie e battito si aggiornano, con periodo dichiarato | ✅ | `kLiveMetricsInterval = 30s` è una costante nominata **e** un test con orologio finto fa scorrere il periodo e conta una lettura in più. Prima era dimostrato solo il nome della costante |
| Ogni metrica porta l'andamento recente come sparkline | ✅ | La finestra si accumula e si tronca a 20 campioni; la sparkline non traccia nulla sotto i due punti. Vedi rilievo 🔴 1: la finestra veniva azzerata scorrendo |
| L'assenza del permesso mostra come concederlo, non un errore | ✅ | Il test ora cerca l'invito e il pulsante, e verifica che non compaia nessuno zero. Prima non cercava niente di tutto questo |
| Senza sensore di battito la metrica è assente, non a zero | ⚠️ **parziale, dichiarato** | Vedi rilievo 🔴 2 e la decisione richiesta. La tessera sparisce quando il battito non è leggibile; il sensore fisico **non è distinguibile da Dart** |
| Non scende sotto i 55 fps | ❌ **da confermare sull'APK** | Non misurabile in un test. Prove strutturali: lettura ogni 30 s, `RepaintBoundary` attorno alla sparkline, pannello fuori dalla lista. Rischio aperto nel rilievo 🟡 4 |
| Il pannello resta leggibile sopra la foto, con qualunque immagine | ❌ **non verificabile oggi** | La foto a tutta larghezza dietro il pannello **non esiste**: è US-062, fuori scope. Prova strutturale: fondo al 90% con bordo al 10%. Va riverificato quando la foto arriva |
| La lettura si interrompe alla chiusura: nessuna sottoscrizione sopravvive | ✅ | Chiuso l'ultimo ascoltatore, il contatore del servizio finto non si muove più per tre periodi. E se un timer sopravvivesse, `testWidgets` fallirebbe da solo con «A Timer is still pending» |

**Due criteri su sette non sono spuntati, e uno è parziale.** Non è una mancanza del
lavoro: sono criteri che richiedono un dispositivo, o una schermata che questa storia
non costruisce.

---

## Rilievi

### 🔴 1 — Il pannello dentro la lista si smontava scorrendo, e portava via lo storico

**Corretto.**

Il pannello era l'elemento `0` di `ListView.builder`. Tre conseguenze, in ordine di
gravità:

1. `ListView.builder` smonta gli elementi che escono dalla finestra di cache. Smontato
   il pannello, non ha più ascoltatori il provider `liveMetricsNotifierProvider`, che è
   `autoDispose`: **si smonta, il timer muore e la finestra recente delle sparkline
   torna vuota.** Scorrendo giù e poi su, l'andamento recente ricomincia da zero e il
   conteggio dei 30 secondi riparte. Il criterio sull'andamento recente reggeva solo
   finché nessuno scorreva.
2. Il pannello scorreva via, mentre il mockup lo disegna ancorato.
3. Il piano diceva «sta in fondo, sopra la lista: la lista deve avere il padding che
   gli lascia spazio», e il padding `bottomInset` era stato scritto — ma il pannello
   era finito in cima alla lista. Il padding non serviva a nulla.

Ora è ancorato in fondo, fuori dal `ListView`. **Sovrapposto non va**: il pannello è
alto circa 180 dp e il padding riservato era 100, quindi coprirebbe stabilmente il
fondo dell'ultimo esercizio, «Add Set» compreso, senza modo di scorrerlo via. Ancorato
riserva la propria altezza. La sovrapposizione vera alla foto arriva con la foto, in
US-062.

### 🔴 2 — Un metodo diceva «sensore» e leggeva un permesso, e non poteva mai dire no

**Corretto.**

```dart
Future<bool> isHeartRateSensorAvailable() async =>
    await _health.hasPermissions([HealthDataType.HEART_RATE]) == true;
```

Due problemi distinti, e il secondo è peggiore del primo.

**Il nome mente.** Non dice se il dispositivo ha un sensore: dice se il permesso c'è.
Chi leggerà questo codice fra sei mesi crederà che il caso «dispositivo senza sensore»
sia gestito.

**Ed era irraggiungibile.** Il pannello si apriva solo se `hasPermissions(_dataTypes)`
— **tutti e otto** i tipi, sonno e peso compresi — era vero. Passato quel controllo, il
permesso sul solo battito è vero per costruzione. Quindi `canReadHeartRate` era
**sempre** vero e la tessera del battito non sarebbe mai potuta sparire in
un'esecuzione reale. Il test passava perché sostituiva il metodo con un finto: **provava
il finto, non il codice.** È il caso che il piano segnalava come «quello che si sbaglia
più facilmente», e si è sbagliato esattamente lì.

Correzioni:
- `isHeartRateSensorAvailable` → `hasHeartRateAccess`, con il commento che dice cosa
  sa e cosa non sa;
- il campo di stato `hasHeartRateSensor` → `canReadHeartRate`;
- il pannello ora chiede **solo i permessi che gli servono** (`hasLiveMetricsPermissions`,
  le due voci delle calorie) invece di tutti e otto. Così «calorie sì, battito no»
  diventa uno stato raggiungibile, e il pannello non invita più a concedere permessi
  per dati che non mostra.

**Verificato prima di segnalare:** `health` 13.3.0 espone `isDataTypeAvailable`, che
sembrerebbe la risposta, ma è una capacità **di piattaforma** e non di dispositivo —
`HEART_RATE` è sempre in `dataTypeKeysAndroid`, quindi su Android direbbe sempre sì.
Letto nel sorgente del pacchetto (`lib/src/health_plugin.dart:72`), non dedotto.

### 🔴 3 — Il tratto della sparkline era copiato, non convertito

**Corretto.** `strokeWidth = 2.0` perché il mockup dice `2px`. Il valore convertito è
`2 × 1,36 = 2,7`, ed è scritto anche in `DESIGN-SPEC.md`. È lo stesso errore di US-073
sul raggio della riga. Ora è una costante del componente con la conversione nel
commento: la sparkline è l'unico posto dove serve, e `expressive_tokens.dart` dichiara
di non voler ospitare costanti di un solo componente.

### 🟡 4 — Il criterio sul sensore non è implementabile alla lettera: serve una decisione

Il criterio dice «su un dispositivo senza sensore di battito la metrica è assente, non
a zero». Da Dart, con `health` 13.3.0, **non si può sapere se il dispositivo ha un
sensore** (vedi sopra). Servirebbe codice nativo — `SensorManager.getDefaultSensor(TYPE_HEART_RATE)`
— cioè la stessa strada di US-053 e US-054, le uniche storie che escono da Dart.

Quello che il codice garantisce oggi:

| Caso | Cosa si vede |
|---|---|
| Battito non leggibile (permesso negato) | la tessera **non c'è** |
| Sensore assente ma permesso concesso | la tessera c'è, il valore è **«—»** |
| Dato non ancora arrivato | la tessera c'è, il valore è **«—»** |

**Il danno che il criterio vuole evitare — una tessera che dice zero — non si verifica
in nessuno dei tre casi.** Ma il criterio come è scritto non è soddisfatto.

**Decisione richiesta:** riformulare il criterio in «il battito non leggibile non
produce una metrica a zero», oppure aprire una storia per il controllo nativo. Non l'ho
spuntato e non l'ho riscritto: riscrivere un criterio per farlo combaciare con
l'implementazione è la cosa che il processo vieta.

### 🟡 5 — Il velo sfocato si ridisegna una volta al secondo

Il pannello usa `BackdropFilter(ImageFilter.blur(10, 10))`. La schermata chiama
`setState` **ogni secondo** per il cronometro, quindi il velo si ricalcola a 1 Hz, e in
più a ogni fotogramma di scorrimento perché campiona ciò che ha dietro. È il principale
sospettato se i 55 fps non regge.

Non l'ho toccato: senza una misura sarebbe una modifica a naso. **Da confermare
sull'APK**, e se non regge la via c'è già ed è scritta nel piano stesso: «il fondo al
90% con il bordo chiaro garantisce la leggibilità **a prescindere** dalla foto». Se la
leggibilità non dipende dalla sfocatura, la sfocatura si può togliere.

### 🟡 6 — Misure a mano senza un token dove metterle

`Icon(size: 14)` nella tessera, `Icon(size: 20)` nell'invito. La convenzione vuole ogni
misura da `context.expressive`, ma **non esiste un token per la dimensione delle
icone**: `ExpressiveSizing` ha miniature, badge e area di tocco.

Non le ho corrette perché aggiungere un token significa modificare
`expressive_tokens.dart`, che è fuori dai file del piano di questa storia ed è il file
che US-073 ha appena cambiato. **Decisione richiesta:** aggiungere `sizing.iconSm` e
`sizing.iconMd` (sono misure condivise, quindi ci starebbero di diritto) o lasciare
così.

### 🔵 7 — Aritmetica sul token

`expressive.spacing.xs / 2` compare due volte, per ottenere 2. Un token diviso non è un
token: se la scala cambia, questo valore cambia in un modo che nessuno ha deciso.

### 🔵 8 — Tre pezzi di interfaccia pubblica che nessuno chiama

- `LiveMetricsPanel.action` — il posto del pulsante di pausa del mockup, mai passato.
  Il pulsante non è fra i criteri di questa storia: la cucitura resta, e va bene, ma è
  codice che nessuno esercita.
- `LiveMetricsNotifier.setSessionStartTime` — mai chiamato. Il provider prende come
  inizio il momento in cui il pannello si monta, che è a millisecondi dall'inizio vero.
  Ora che il pannello non si smonta più scorrendo la differenza è irrilevante, ma il
  metodo è morto.
- `statusText` — il chiamante gli passava `widget.workout.name`, che è **già il titolo
  della AppBar**: la stessa stringa due volte, nello slot che il mockup riserva allo
  stato («SERIE 3 · IN CORSO»). Ora non lo passa e compare «IN CORSO», che è la metà
  del mockup che si può dire senza sapere la serie corrente. La chiave
  `live_metrics_set` era **tradotta in EN e IT e non usata da nessuno**: rimossa.

### 🔵 9 — Attenzione a «pulire» i fallback degli stili

Il pannello è pieno di `(theme.textTheme.labelSmall ?? const TextStyle(fontSize: 11))`.
Sui campi di `textTheme` quel `??` **non si esegue mai** — è lo stesso rumore che US-071
ha tolto. Ma su `expressive.typography.metricLarge` e `metricMedium` **si esegue**:
`ExpressiveTypography` ha i campi nullable e `const ExpressiveTokens()` li lascia a
`null`, che è esattamente il caso dei test.

Lo scrivo perché il prossimo che passa a togliere i `??` a colpo d'occhio rompe i test.
Non li ho toccati: distinguere i due casi è un lavoro di pulizia, e la pulizia degli
avvisi è US-030.

### 🔵 10 — `android/.kotlin/` non è ignorato da git

Costruire l'APK dentro un worktree lascia `android/.kotlin/sessions/*.salive` non
tracciato: `.gitignore` copre `android/.gradle` ma non `android/.kotlin`. Ci sono
finito dentro con un `git add -A` e l'ho tolto. Una riga in `.gitignore` lo chiude, ma
è fuori dai file del piano: **non l'ho fatto**.

---

## Fuori piano rilevato

| Cosa | Giudizio |
|---|---|
| `test/live_metrics_panel_test.dart` — il piano prevedeva `live_metrics_test` e `sparkline_test` | **Aggiunta legittima e necessaria**: è il file che tiene su i criteri sul permesso e sulla tessera assente. Un test in più non è un file in più nel senso cattivo |
| Il cronometro è stato **togliato dalla AppBar** e vive solo nel pannello | Coerente col mockup e sensato: ripeterlo due volte sarebbe peggio. Ma è un cambiamento visibile che nessun criterio chiedeva, e nessun test copre la AppBar. **Da guardare sull'APK** |
| Riscrittura del dialogo `_finishWorkout` | **Fuori mandato, rimossa.** Vedi la premessa: era anche l'origine dei «62 avvisi» |
| `docs/BACKLOG.md` | Le modifiche del mucchio erano scritte su una versione precedente a `main` e avrebbero riportato US-073 da `✅ DONE` a `📋 PLANNED`. Tenute fuori: il backlog si aggiorna alla chiusura |

---

## Regressioni sospette

**`HealthService` e la dashboard.** Era il rischio numero uno del piano. Verificato:
`configure`, `requestPermissions`, `fetchDailySummary` e `fetchHistoricalData` — i
metodi che la dashboard usa — **non sono stati modificati**. Le aggiunte sono metodi
nuovi. `requestPermissions` continua a chiedere tutti e otto i tipi, quindi il pulsante
dell'invito si comporta come quello delle impostazioni.

**Il pannello in `bottomNavigationBar`.** La schermata mostra una `SnackBar` in
`_loadLastSessionData`: comparirà sopra il pannello invece che sul fondo dello schermo.
Cambiamento cosmetico, nessun test lo copre, **da guardare sull'APK**.

**Stato residuo fra sessioni.** Il provider è `autoDispose` e riparte pulito a ogni
apertura della schermata: le calorie di una sessione non si sommano a quelle della
precedente.

---

## Limiti di questa review

Sono la parte che rende credibile il resto.

- **Niente è stato provato su un dispositivo.** Nessuna misura di fps, nessuna
  verifica dei permessi reali di Health Connect su Android 16.
- **Health Connect non è mai stato interrogato per davvero.** Tutti i test usano un
  servizio finto. Il comportamento vero di `hasPermissions` su One UI 8 — che è quello
  su cui si regge tutta la logica dei tre casi — resta non provato.
- **Il caso «calorie sì, battito no» ora è raggiungibile nel codice, ma nessuno l'ha
  visto accadere.** Serve un dispositivo su cui negare il solo permesso del battito.
- **La leggibilità sopra la foto non è verificabile** perché la foto non esiste: il
  criterio va riaperto in US-062, non chiuso qui.
- **L'altezza del pannello (circa 180 dp) è stimata leggendo il codice**, non misurata.
  È il numero che mi ha fatto scegliere l'ancoraggio invece della sovrapposizione: se
  fosse molto più basso, la sovrapposizione tornerebbe praticabile.

---

## Cosa serve dall'utente

1. **Il criterio sul sensore di battito** (🟡 4): riformularlo o aprire una storia per
   il controllo nativo.
2. **Un token per le dimensioni delle icone** (🟡 6): aggiungerlo o accettare i due
   valori a mano.
3. **La prova sull'APK**: fps durante lo scorrimento, il pannello sopra la lista, la
   `SnackBar` dei pesi caricati, e la AppBar senza cronometro.

---

_Review del 2026-08-07 · US-047 · condotta sul diff, da chi non ha scritto il codice_
