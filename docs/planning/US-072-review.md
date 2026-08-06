# US-072 — Review

**Verdetto:** APPROVATA CON RISERVE
**Diff esaminato:** `git diff main...HEAD` · 9 file, +480 / −180
**Verifica:** `flutter analyze` **63 avvisi** (baseline invariato), zero errori · `flutter test` **289 test verdi** (erano 282) · `flutter build apk --debug` **riuscita**

La riserva è una sola: **non è stata provata sul telefono**, che si è scollegato prima
dell'installazione. Per una storia nata da un errore scoperto solo su dispositivo, è la riserva che
pesa di più.

---

## Copertura dei criteri

| # | Criterio | Esito | Prova |
|---|---|---|---|
| 1 | La libreria curata è disponibile senza alcuna scrittura su Firestore | ✅ | `importCuratedExercises` non esiste più, e `getExercises` interroga solo `userId == <utente>`. Nessun percorso del codice scrive un esercizio curato |
| 2 | Gli esercizi curati compaiono al primo avvio, senza azioni dell'utente | ✅ | Test: con Firestore che restituisce lista vuota, il provider espone comunque i curati |
| 3 | Gli esercizi dell'utente compaiono accanto ai curati e restano suoi | ✅ | Test: 2 curati + 1 personale = 3, e il personale conserva `isCustom` e `userId` |
| 4 | Nessun doppione a parità di identificativo | ✅ | Test: un esercizio dell'utente con id `ex_001` compare **una volta sola**, e vince il suo |
| 5 | Disponibile anche senza rete | ✅ **nel modo che conta** | Test con uno stream che emette `permission-denied` — l'errore vero — e i curati ci sono lo stesso. **Da confermare in modalità aereo** |
| 6 | Il comando «Carica Dati Default» è rimosso | ✅ | Voce, metodo e sei chiavi di localizzazione |

---

## Cosa ha trovato la review

### 🔴 `AsyncValue.value` rilancia l'errore — e sarebbe successo proprio nel caso reale

Il test «se Firestore rifiuta, i curati ci sono lo stesso» è fallito con `Exception:
permission-denied` sollevata da dentro `Exercises.build`.

Causa: in Riverpod, **`AsyncValue.value` rilancia l'errore** su un `AsyncError`; per ottenere `null`
serve `valueOrNull`. Il codice diceva:

```dart
final custom = ref.watch(customExercisesProvider).value ?? const <Exercise>[];
```

Il `?? const []` sembrava proteggere da tutto e non proteggeva da niente. Con Firestore che risponde
`permission-denied` — **esattamente ciò che accade sul dispositivo dell'utente** — la libreria
sarebbe esplosa invece di mostrare i 43 curati: cioè avrebbe fallito nel solo caso per cui questa
storia esiste.

Corretto con `valueOrNull` in entrambi i provider. Lo stesso errore era anche nell'indice, dove
avrebbe fatto cadere ogni cella di lista che lo consulta.

### 🔴 Il baseline era risalito a 64

Un `import` di `material.dart` rimasto nel file di test nuovo. Rimosso: **63**.

### 🟡 Il diff cancella 92 righe da `firestore_service.dart` e una voce dalle impostazioni

`getExercises` non interroga più `isCustom == false`: quella query cercava la libreria condivisa e
restituiva **sempre zero documenti**, perché nessuno era mai riuscito a scriverceli. Toglierla
elimina anche uno dei due stream combinati con `Rx.combineLatest2`.

La voce «Carica Dati Default» sparisce dalle impostazioni: era il pulsante che dava l'errore.

Entrambe sono **rimozioni di funzionalità visibili**, non solo pulizia. Se qualcuno cercasse quel
comando, la risposta è che non serve più: gli esercizi ci sono già.

### 🟡 US-045 resta a backlog come `✅ DONE`, ma metà del suo lavoro è stata rifatta

Ciò che sopravvive è la parte pura — `ExerciseSeed.parse` e i suoi 21 test, che questa storia usa
tale e quale. Ciò che è stato buttato è la scrittura su Firestore e il resoconto.

Non riapro US-045: il backlog resta leggibile perché US-072 dichiara in testa che cosa corregge. Ma
va detto che **il costo dell'assunto non verificato è stato una storia intera**.

### 🔵 La libreria non crea più lo stream dentro `build`

`exercise_library_screen.dart` leggeva `_firestore.getExercises(user.uid)` dentro `build`: uno
stream nuovo a ogni ricostruzione. Ora legge il provider. È **uno degli undici punti** di
US-010÷US-012, chiuso come conseguenza e non per iniziativa. La schermata resta con gli altri suoi
difetti: servizi istanziati nei campi, colori scritti a mano.

### 🔵 I curati compaiono prima degli esercizi dell'utente

`Exercises.build` non aspetta Firestore: espone i curati subito e aggiunge i personali quando
arrivano. È voluto — meglio una libreria piena che una vuota in attesa della rete — ma significa che
per una frazione di secondo la lista può crescere sotto gli occhi. Sul telefono va guardato.

---

## Checklist adversariale

| Domanda | Risposta |
|---|---|
| Firestore rifiuta? | **È il caso che ha aperto la storia**, ed è un test |
| Utente non autenticato? | `CustomExercises` restituisce lista vuota senza interrogare Firestore; i curati arrivano lo stesso |
| Asset mancante o corrotto? | `ExerciseSeed.parse` non solleva eccezioni e restituisce un elenco vuoto con gli scarti annotati (3 test in `exercise_seed_test`). Se l'asset sparisse da `pubspec.yaml`, `rootBundle` solleverebbe e il provider andrebbe in errore: **la libreria sarebbe vuota**. Un test blocca il percorso dell'asset perché almeno il rinominarlo non passi inosservato |
| L'asset viene riletto a ogni ricostruzione? | No: il provider tiene il risultato |
| Doppioni? | Testato, e vince l'utente |
| Risorse rilasciate? | I provider sono `autoDispose`; nessuna sottoscrizione a mano |
| `Stream` dentro `build`? | **Uno in meno** rispetto a prima |
| Convenzioni? | Nessuna stringa nuova; sei chiavi rimosse insieme al comando |
| Segreti nel diff? | Nessuno |

---

## Limiti dichiarati

1. **Non provata sul telefono.** È la riserva del verdetto: il dispositivo si è scollegato. La prova
   che conta — aprire «Esercizi» e vedere 43 voci con 15 miniature — non è stata fatta.
2. **Le regole Firestore restano non versionate** (US-018). Il rifiuto di scrittura si è potuto
   scoprire solo premendo un pulsante su un telefono: US-018 diventa più urgente di prima.
3. **I curati non sono modificabili dall'utente**: nessuna foto propria su un esercizio curato.
   Prima nemmeno, ma ora è strutturale.
4. **Aggiornare la libreria richiede una versione dell'app.** È il compromesso scelto: in cambio,
   funziona offline e non ha permessi da concedere.
5. La review è un'autoverifica. Ha trovato due difetti, di cui uno che avrebbe reso inutile l'intera
   storia proprio nel caso d'uso reale.

---

## Da confermare sul telefono

1. **Menu → «Esercizi»**: 43 esercizi, **15 con miniatura vera e indicatore del video**, gli altri
   con il segnaposto colorato. È la prova che finora non è mai stata possibile.
2. **Modalità aereo**: la libreria resta piena.
3. **Impostazioni**: la voce «Carica Dati Default» non c'è più.
4. **Toccare una miniatura**: si apre l'esecuzione (US-044, mai potuta provare per mancanza di
   esercizi).

---

_Review del 2026-08-06 · fase 5 del ciclo in [`WORKFLOW.md`](../WORKFLOW.md)_
