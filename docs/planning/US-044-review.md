# US-044 — Review

**Verdetto:** APPROVATA CON RISERVE
**Diff esaminato:** `git diff main...HEAD` · 17 file, +937 / −3
**Verifica:** `flutter analyze` **66 avvisi, zero errori** (baseline invariato) · `flutter test` **253 test verdi** (erano 237) · `flutter build apk --debug` **riuscita**

Chiude **EP-009**. La riserva riguarda i tre criteri che vivono a schermo — riproduzione, stato
della sessione, cronometro — e che nessun test può dimostrare: hanno bisogno di una WebView, di una
sessione vera e di un cronometro che batte.

---

## Copertura dei criteri

| # | Criterio | Esito | Prova |
|---|---|---|---|
| 1 | Il video si apre da libreria, scheda esercizio e sessione attiva | ✅ nel codice, **da confermare sul dispositivo** | Le tre schermate passano l'azione alla miniatura. **«Scheda esercizio» è stata interpretata come la scheda di allenamento**: una schermata di dettaglio dell'esercizio non esiste (il `TODO` in `exercise_library_screen.dart` è ancora lì) e questa storia non la crea |
| 2 | Dalla sessione attiva, lo stato della sessione è intatto alla chiusura del video | ⚠️ **strutturale** | `showModalBottomSheet` non smonta la schermata sotto: lo stato di `ActiveSessionScreen`, e con esso le serie registrate, non viene toccato. **È un fatto della struttura, non una misura**: da provare con una sessione vera |
| 3 | Il cronometro della sessione continua a scorrere mentre il video è aperto | ⚠️ **strutturale** | Stessa ragione: il `Timer` vive nello stato della schermata sotto, che non viene smontata. Da provare guardando i secondi prima e dopo |
| 4 | Un video non disponibile mostra un messaggio, non una schermata bianca | ✅ | 3 test unitari (404, 401) + 1 widget test che verifica il messaggio a schermo e l'assenza della rotellina |
| 5 | Senza rete si spiega che il video richiede connessione | ✅ | Test: `SocketException`, `TimeoutException` e `HttpException` danno «offline», e il widget test verifica che il messaggio sia **diverso** da quello del video rimosso |
| 6 | Il video non parte da solo con l'audio a volume pieno | ⚠️ **strutturale** | `autoPlay: false` in `exercise_video_sheet.dart:70`, che è anche il default del package. Risolto alla radice invece che abbassando il volume. **Non montabile in un test** (vedi sotto) |

---

## Cosa ha trovato la review

### 🔴 Il test ha dimostrato che lo stato «disponibile» non è verificabile

Il primo giro di test è fallito così:

```
A platform implementation for `webview_flutter` has not been set.
new YoutubePlayerController.fromVideoId
_ExerciseVideoSheetState._check
```

Costruire il controller — non montarlo, **costruirlo** — richiede già la piattaforma WebView. Il
test è stato riscritto perché provi l'attesa senza arrivare allo stato disponibile.

La conseguenza va detta chiaramente e non aggirata: **il ramo in cui il video si vede davvero non è
coperto da nessun test**, e non può esserlo senza un dispositivo. I test coprono i tre rami che
restano, che sono anche quelli in cui l'utente rischia di vedere una schermata bianca.

### 🟡 L'apertura del video costa un giro di rete prima di partire

L'interrogazione oEmbed aggiunge un'attesa prima del riproduttore: su rete lenta, fino a cinque
secondi di rotellina prima di scoprire che si è offline. È il prezzo di poter distinguere «non
disponibile» da «senza connessione», che è ciò che due criteri chiedono.

L'alternativa — aprire subito il riproduttore e scoprire dopo — mostrerebbe un riquadro nero che
non spiega niente, che è esattamente ciò che il criterio 4 vieta.

### 🟡 Cinque file di piattaforma toccati che non c'erano nel piano

`linux/`, `windows/` e `macos/` hanno i registrant dei plugin rigenerati da `flutter pub get`, per
`url_launcher` e `webview_flutter`. Sono **generati dallo strumento**, non scritti a mano, e sono
versionati nel repository: lasciarli fuori renderebbe il repository incoerente con `pubspec.lock`.
Nessuno di quei target è compilabile oggi.

### 🟡 Il tocco sulla miniatura convive con il tocco sulla cella

In libreria la cella seleziona l'esercizio (quando si arriva da «aggiungi esercizio») e la
miniatura apre il video. Due gesti sovrapposti a pochi millimetri: **funziona, ma è il tipo di cosa
che si giudica col dito, non leggendo il codice**. Se risulta scomodo, l'alternativa è spostare
l'apertura del video su un tocco lungo o su un pulsante nel dettaglio, quando il dettaglio esisterà.

### 🔵 Nella scheda e in sessione il tocco è vivo solo a indice risolto

`ExerciseThumbnailById` passa `onTap: null` finché l'indice non ha risolto l'esercizio: meglio
nessun gesto che un gesto che apre «video non disponibile» perché l'esercizio non è ancora
arrivato. Effetto collaterale: per un istante dopo l'apertura della scheda, la miniatura non
risponde.

### 🔵 `close()` sul controller, non `dispose()`

Il controller di `youtube_player_iframe` si chiude con `close()`. Senza, **l'audio continuerebbe
dopo la chiusura del foglio**, perché la WebView sopravvive al widget. Verificato sul sorgente del
package (`youtube_player_controller.dart:657`), non dedotto dal nome.

---

## Checklist adversariale

| Domanda | Risposta |
|---|---|
| Risorse rilasciate? | Il controller è chiuso in `dispose`. È l'unica risorsa creata, ed è quella che farebbe più danno se sopravvivesse: audio che continua a suonare |
| Rete assente? | È un caso trattato, non un incidente: tre eccezioni diverse portano allo stesso esito «offline», con un messaggio suo |
| Dato assente? | Esercizio senza video né ricerca: messaggio dedicato, nessun pulsante. Testato |
| `Stream` o `Future` dentro `build`? | No: l'interrogazione parte da `initState` e il risultato vive nello stato |
| Effetti collaterali in `build`? | No |
| `BuildContext` attraverso un `await`? | Due punti: `if (!mounted) return;` dopo l'interrogazione, e `if (!opened && mounted)` dopo `launchUrl` |
| Convenzioni di `CLAUDE.md`? | Colori dai ruoli dello schema; spaziature e forme dai token; nessun colore letterale (`MaterialType.transparency` invece di un colore trasparente); sei stringhe nuove, tutte in EN e IT |
| Può rompere qualcosa di non testato? | La sessione attiva. Il diff lì è di cinque righe che aggiungono un `onTap` alla miniatura: non tocca stato, cronometro né salvataggio |
| Segreti nel diff? | Nessuno |
| Comprensibile fra sei mesi? | Il punto meno ovvio è perché si interroga oEmbed prima di aprire il riproduttore: il commento sul servizio spiega che senza non si potrebbero dare due messaggi diversi |

---

## Limiti dichiarati

1. **Il ramo «il video si vede» non è testato**, e non è testabile senza dispositivo.
2. **I criteri 2 e 3 sono strutturali**: un foglio modale non smonta la schermata sotto è un fatto
   di Flutter, non una misura fatta da noi. La prova è aprire il video durante una sessione e
   guardare il cronometro.
3. **«Scheda esercizio» è stata interpretata** come la scheda di allenamento, perché una schermata
   di dettaglio dell'esercizio non esiste.
4. **L'attesa prima del video** non è stata misurata su rete reale.
5. **Solo 15 esercizi su 43 apriranno un video**; gli altri 28 apriranno una ricerca. È il materiale
   che c'è, ed è la domanda aperta n. 2 del documento di passaggio.
6. **La review è un'autoverifica.**

---

## Da confermare sul dispositivo

1. **Libreria**: toccare la miniatura di un esercizio con l'indicatore → il video si apre e **non
   parte da solo**. Toccarne una senza indicatore → il messaggio con «Cerca su YouTube».
2. **Sessione attiva**: aprire il video durante una sessione con serie già registrate. Alla
   chiusura: le serie ci sono ancora e **il cronometro è avanzato**, non ripartito.
3. **Modalità aereo**: il messaggio deve dire che serve una connessione, non che il video non
   esiste.
4. **Chiudere il foglio mentre il video suona**: l'audio deve smettere.

---

_Review del 2026-08-06 · fase 5 del ciclo in [`WORKFLOW.md`](../WORKFLOW.md)_
