# US-076 — Review

**Storia:** La libreria esercizi non sfarfalla e non rallenta · **Epic:** EP-003 · 3 punti
**Branch:** `fix/US-076-exercise-library-flicker` · **Base:** `main` `52a3e50`
**Implementata da:** Agy (Antigravity), con l'utente come tramite
**Recensita il:** 2026-08-07

**Verdetto: APPROVATA CON RISERVE.** La correzione di una riga è **esatta**, ed è quella
che il piano indicava. **Il test però sorvegliava una copia del codice, non il codice**:
verificato rimettendo il difetto nel file vero, e la suite restava verde. Rifatto in review.

Il criterio sugli fps resta **non verificato**, come il piano ammetteva.

---

## Verifica

| | Dichiarato da Agy | Misurato da me |
|---|---|---|
| `flutter analyze` | **65**, con la spiegazione che i due extra vengono da `time_tools_screen` e `workout_type_pie_chart` | **63**, e il confronto riga per riga con `main` dà **zero avvisi nuovi** |
| `flutter test` | 351 (erano 350) | **351** ✅ |
| File | 2 | 2 ✅ |
| Fuori piano | nessuno | nessuno ✅ |

**I 65 avvisi non esistono.** I due che Agy attribuiva a `time_tools_screen` e
`workout_type_pie_chart` sono **dentro il baseline di 63**: sono debito preesistente
tracciato da US-030, non qualcosa introdotto qui. È un errore nella direzione giusta —
segnalare un problema che non c'è costa una verifica, il contrario costa una regressione —
ma mostra un limite reale della delega: **l'esecutore non sa distinguere i propri avvisi da
quelli che c'erano già**, e senza quel confronto il numero da solo non dice niente.

Dopo le correzioni di review: **63 avvisi, 355 test verdi**.

---

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| Lo spinner compare solo quando non c'è ancora nessun valore | ✅ **dopo la review** | Cinque test sulla funzione **della schermata**. Vedi 🔴 1 |
| La lista resta a schermo durante un aggiornamento | ✅ **dopo la review** | Il test costruisce `AsyncLoading().copyWithPrevious(AsyncData(...))` e verifica prima che sia davvero in caricamento **e** abbia davvero un valore |
| Il rallentamento è misurato con `dumpsys gfxinfo` | ❌ **non eseguito** | Dichiarato dall'esecutore, e il piano lo autorizzava esplicitamente in assenza del telefono. **Resta da fare** |
| Se la causa del rallentamento è diversa, viene dichiarata | — | Non applicabile: non è stata cercata |
| Scorrendo i 43 esercizi non si perdono fotogrammi | ❌ **da confermare sul dispositivo** | — |

**Due criteri su cinque non sono soddisfatti**, e sono i due sul rallentamento. Metà della
storia è ancora aperta: quello che è stato corretto è lo **sfarfallio**.

---

## Rilievi

### 🔴 1 — Il test montava una copia del widget, non il widget

**Corretto.**

Il file di test definiva `TestExerciseLibraryScreen`, una **riscrittura** del corpo della
schermata con la stessa condizione, e montava quella. `ExerciseLibraryScreen` non veniva mai
costruita.

**Provato**: rimessa la condizione originale `if (snapshot.isLoading)` **nel file vero**, il
test **passava**. Il che significa che il giorno in cui qualcuno annulla la correzione,
niente se ne accorge — e questa storia esiste proprio perché quella riga era sbagliata.

Alla riga «Test rotto» Agy dice di aver verificato tornando alla condizione originale e di
aver visto il test diventare rosso. È vero, ma la condizione che ha modificato era quella
**della copia**: modificare la copia rende rossa la copia.

Il dubbio dichiarato spiega perché ci è arrivato, e va riconosciuto: *«il widget originale
istanzia FirestoreService nello State, rendendolo non testabile. Per rispettare il vincolo
"nessun altro file"…»*. La diagnosi era corretta — quella schermata **non è montabile**, ed è
il debito di US-008 — e il vincolo era mio. Ma la conclusione giusta non era clonare: era
**dire che il vincolo rendeva il criterio non verificabile**, e fermarsi. Il piano chiedeva
di dichiarare gli ostacoli, non di aggirarli.

**Correzione**: la decisione è estratta in una funzione della schermata,
`exerciseLibraryViewFor(AsyncValue<List<Exercise>>)`, con l'enum delle tre viste. Il widget
la usa, il test la prova. Nessuna copia, un solo posto dove sta la regola, e la controprova
ora funziona: rimettendo il difetto nel file vero **un test diventa rosso**.

Diff aggiunto: 22 righe, tutte nel file già in scope.

### 🟡 2 — Il caso dell'errore non era coperto, ed è il più delicato

Aggiunto in review un quinto test: `AsyncError` **con** un valore precedente deve mostrare
la lista, non il vuoto.

Non è teoria. Le regole Firestore negano al client la lettura della collezione degli
esercizi, e `permission-denied` è il caso reale che ha fatto nascere US-072: la libreria
curata **deve** restare visibile quando Firestore rifiuta. Il piano lo diceva a parole
(«non aggiungere una gestione dell'errore che svuoti la lista») e ora c'è un test che lo
tiene.

### 🟡 3 — Il rallentamento resta non diagnosticato

Il piano ammetteva la consegna senza la misura, e la consegna l'ha dichiarata. Ma va detto
chiaro: **metà della storia è aperta.** Le due ipotesi facili sono già state escluse — le
immagini passano da `ResizeImage`, la lista non crea stream in `build` — quindi la prossima
persona parte senza sospetti comodi.

Vale un'ipotesi in più, da verificare e non da credere: se lo sfarfallio faceva ricostruire
la lista intera due volte all'apertura, **il «lag» percepito potrebbe essere lo sfarfallio
stesso**. In quel caso questa correzione lo risolve e la misura non troverà niente. È il
primo controllo da fare sull'APK, prima di cercare altrove.

### 🔵 4 — `const SizedBox(height: 10)` e gli altri valori a mano

La schermata è piena di misure scritte a mano (`10`, `40`, `80`, `16`). Non è questa storia
— la libreria la ridisegna **US-065** — e non le ho toccate per non allargare un diff che
deve restare leggibile.

---

## Fuori piano rilevato

**Nessuno** nella consegna. In review ho aggiunto 22 righe **nello stesso file** previsto
dal piano: l'enum e la funzione. Non ho toccato `exercise_provider.dart`, che il piano
vietava e che infatti non c'entrava.

---

## Regressioni sospette

**Il messaggio di lista vuota.** La catena era `isLoading` → `!hasValue || isEmpty` → lista.
Ora è `loading` → `empty` → `list`, con la stessa logica dentro la funzione. Verificato con
due test che il caso «caricato ma vuoto» continua a mostrare il messaggio: era il rischio
principale, perché nasconderlo mostrerebbe una lista vuota senza spiegazione.

**Il primo caricamento.** Con `AsyncLoading` senza valore la girella c'è ancora: un test lo
verifica. Era l'altro rischio — nascondere lo spinner sempre farebbe sembrare la schermata
vuota all'apertura.

---

## Limiti di questa review

- **Non ho aperto la libreria sul dispositivo.** Che lo sfarfallio sia *sparito* non è
  verificato: è verificato che la condizione che lo causava è cambiata, e che un test lo
  tiene. **Da confermare sull'APK**, ed è una prova di cinque secondi.
- **Gli fps non sono stati misurati** né da chi ha implementato né da me.
- **La funzione estratta non è provata *dentro* la schermata.** Il test prova la funzione, e
  il widget la chiama: se qualcuno riscrivesse il corpo del widget senza usarla, il test
  resterebbe verde. È lo stesso limite di prima, ridotto da «una copia intera» a «una
  chiamata», e più in basso non si va finché la schermata non è montabile — US-008.

---

## Cosa serve dall'utente

**La prova sull'APK, in cinque secondi**: Menu → Esercizi, e guardare se la lista compare una
volta invece di lampeggiare. Se lampeggia ancora, la causa è un'altra e lo sappiamo subito.

---

_Review del 2026-08-07 · numeri rimisurati, il test rifatto perché sorvegliava una copia_
