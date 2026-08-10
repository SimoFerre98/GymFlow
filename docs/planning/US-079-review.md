# US-079 — Review

**Data:** 2026-08-10 · **Branch:** `fix/US-079-add-exercise-visible-errors`
**Commit rivisti:** `7fb418b` (consegna) + `a274805` (correzioni fatte in review)
**Chi ha implementato:** Agy · **Chi rivede:** non ha scritto il codice

**Verdetto: APPROVATA CON RISERVE** — un rilievo bloccante trovato e corretto, la guardia
sul sorgente rifatta perché lasciava passare il caso peggiore, e il criterio principale che
resta da confermare sul dispositivo.

---

## Numeri, misurati nel worktree

| | Dichiarato | Misurato alla consegna | Dopo le correzioni |
|---|---|---|---|
| `flutter analyze` | 56 | **56** | **56** |
| `flutter test` | 436 verdi | **436 verdi** | **437 verdi** |
| File toccati | 3 | 3, tutti previsti dal piano | 3 |

**L'elenco degli avvisi è identico riga per riga a quello di `main`**, non solo il totale. Né
aumenti né cali da spiegare.

---

## 🔴-1 · Il dettaglio tecnico dell'errore veniva buttato — corretto

Questo è il rilievo che conta, ed è l'ironia della storia.

Come consegnato, `exercise_library_screen.dart:96-98`:

```dart
} catch (e) {
  return const AddExerciseResult.saveError('add_exercise_error_saving');
}
```

`e` **non viene usato.** Dopo il diff, `grep -n debugPrint exercise_library_screen.dart` non
trova più **niente**: prima della storia c'era `debugPrint('Error saving exercise: $e')`, dopo
non c'è nessun log di nessun tipo.

Il piano lo chiedeva a lettere chiare, nella tabella dei rischi:

> `permission-denied` non significa niente per un atleta. Un messaggio comprensibile, **con il
> dettaglio tecnico nel log**.

Metà del requisito è soddisfatta e metà è andata nella direzione opposta. Il risultato netto
è che il fallimento è passato da **muto** a **visibile ma non diagnosticabile**: l'utente vede
«Errore durante il salvataggio», e chi deve capire perché non ha nulla.

Vale la pena dire perché è più grave della media in **questa** storia. US-079 esiste perché un
`permission-denied` è rimasto invisibile per sei mesi, e la lezione scritta in `HANDOFF.md` è
letteralmente «quando un dato non arriva, il primo controllo è `adb logcat | grep
PERMISSION_DENIED`». Togliere l'unica riga di log del salvataggio esercizi rimuove lo
strumento che ha chiuso il caso, dalla storia nata da quel caso. Se domani le regole Firestore
cambiassero di nuovo, si tornerebbe a indovinare.

**Corretto in `a274805`.** Il `catch` registra il dettaglio e restituisce la chiave
comprensibile. Che il log parta davvero non è dedotto: si vede nell'output del test del
fallimento di salvataggio, che ora stampa

```
Errore nel salvataggio dell'esercizio: Exception: Firestore write denied
```

---

## 🔴-2 · La guardia sul sorgente vietava il male minore e permetteva il maggiore — corretta

Il test consegnato cercava questo:

```dart
RegExp(r'catch\s*\([^)]*\)\s*\{\s*debugPrint\([^)]*\);?\s*\}')
```

Cioè: **solo** i `catch` il cui corpo è esattamente un `debugPrint`. Un `catch (e) {}` vuoto,
o con dentro un commento, inghiotte l'errore in modo più completo e passava.

Provato sul file vero, non dedotto. Tre mutazioni, ognuna verificata applicata prima di
lanciare il test:

| Corpo del `catch` iniettato | Guardia consegnata | Guardia corretta |
|---|---|---|
| `debugPrint('pop non riuscito: $e');` | 🔴 rosso | 🔴 rosso |
| `// ingoiato di proposito` | ✅ **verde** | 🔴 rosso |
| *(vuoto)* | ✅ **verde** | 🔴 rosso |

**Corretto in `a274805`**: la regola è rovesciata. Invece di elencare le forme vietate, il
test chiede che il corpo di ogni `catch` **faccia qualcosa** dell'errore — `return`,
`rethrow`, `throw`, o mostrarlo con `ToastUtils`. Un corpo che si limita a registrare o a
tacere finisce nell'elenco dei colpevoli, col proprio testo nel messaggio di fallimento.

Limite dichiarato della guardia nuova, scritto anche nel test: i `catch` con graffe annidate
nel corpo non vengono esaminati, perché il confronto è su testo e non su un albero sintattico.
Contengono per definizione un blocco, quindi non sono il caso del `catch` muto — ma non è una
prova, è un confine.

---

## 🟡-1 · Il criterio principale era dimostrato da una funzione che restituisce una stringa

Il rapporto dichiarava: «Un fallimento è visibile a schermo: soddisfatto (dimostrato da unit
test su `handleAddExerciseSubmit`, mostra il messaggio con `ToastUtils.showError`)».

I due pezzi della frase non stanno insieme. Il test dimostra che la funzione restituisce
`AddExerciseOutcome.saveError` e la chiave `'add_exercise_error_saving'`. È la **decisione**,
non la comparsa. Che quella decisione diventi qualcosa che si vede dipende dall'anello
successivo, che nessun test toccava — ed è la classe di difetto n. 3 di questo progetto: si
prova il pezzo comodo e si dà per fatto quello scomodo.

L'anello poteva rompersi davvero. `ToastUtils` non usa `ScaffoldMessenger`: alza un
`OverlayEntry` con `Overlay.of(context)` (`toast_utils.dart:22`). Chiamato con il
`dialogContext`, quell'`Overlay.of` deve risalire fino all'overlay del `Navigator` — quello
che ospita anche la rotta del dialogo — e l'inserimento senza `above:`/`below:` va in cima
alla pila. Se non fosse così, il messaggio finirebbe dietro la barriera modale e la storia
sarebbe finta.

**Colmato in `a274805`** con un `testWidgets` che apre un `AlertDialog` vero, alza il toast col
contesto del dialogo, e verifica due cose insieme: che il messaggio sia nell'albero, e che il
dialogo **sia ancora aperto**.

Il test non è vacuo, e anche questo è provato: sostituendo la chiamata a `ToastUtils.showError`
con un `onPressed: () {}` diventa rosso —

```
Actual: Found 0 widgets with text "errore di salvataggio"
il messaggio d'errore deve essere presente nell'albero
```

**Cosa resta comunque non provato**, e va detto: questo test monta un dialogo *costruito nel
test*, non quello di `_showAddExerciseDialog`. Prova il meccanismo del toast, non il cablaggio
della schermata — che non è montabile perché istanzia `FirestoreService` nel proprio `State`,
il debito di US-008 che il piano stesso cita. La catena
`onPressed → handleAddExerciseSubmit → shouldCloseDialog → toast` è verificata a pezzi, letta
per intero solo a occhio (`exercise_library_screen.dart:574-598`). È il limite strutturale
della storia, non una dimenticanza.

---

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| Un esercizio creato viene salvato e compare in «Miei» | ⬜ **Da confermare sull'APK** | Serve Firestore vero. È la prova che chiude la storia |
| Un fallimento è visibile a schermo | ✅ *dopo la correzione* | `testWidgets` sul toast alzato dal contesto del dialogo, con mutazione che lo fa arrossire |
| Il dialogo non si chiude quando fallisce | ✅ parziale | `shouldCloseDialog` falso per entrambi i tipi di errore + lo stesso `testWidgets`; il cablaggio della schermata resta letto e non montato |
| Il nome vuoto è rifiutato con un messaggio | ✅ | Vuoto e soli spazi danno `add_exercise_name_empty`, e `saveExercise` non viene chiamata. Togliendo il `.trim()` il test diventa rosso |
| Nessun `catch` inghiotte un errore di scrittura | ✅ *dopo la correzione* | La guardia rifatta, con le tre mutazioni sopra |
| Le stringhe sono localizzate | ✅ | Quattro chiavi nuove in EN e IT; `localization_test.dart` verde. `'save'` e `'cancel'` esistevano già (`:249`/`:526`, `:167`/`:438`) |

### Le altre mutazioni, per capire cosa i test tengono davvero

| Mutazione sul file vero | Esito |
|---|---|
| Il `catch` restituisce `success()` invece di `saveError` — il fallimento diventa un successo silenzioso | 🔴 rosso, `add_exercise_test.dart:55` |
| `rawName.trim()` → `rawName` — i soli spazi diventano un nome valido | 🔴 rosso, due test |

Nessuna delle due era coperta «per fortuna»: i test guardano il comportamento che conta.

---

## 🟡-2 · Il piano chiedeva di verificare per primo che il salvataggio funzioni

Il piano è esplicito: «**Il primo passo è verificarlo**, non dedurlo: apri Menu → Esercizi →
"+", scrivi un nome, salva, e guarda se compare nel segmentato "Miei"».

Il rapporto risponde deducendo:

> Si noti che `FirestoreService.addExercise` imposta correttamente `userId` ed `isCustom:
> true`, che combaciano con le regole Firestore aggiornate il 2026-08-10 […] **il salvataggio
> lato Firestore ora funziona.**

Il ragionamento è giusto e l'ho ricontrollato: `Exercise.toMap()` include `userId`, le regole
pubblicate consentono la scrittura di un documento che dichiara chi scrive come proprietario.
Ma «funziona» è un'affermazione sul dispositivo, e la frase finale è più sicura di quanto la
prova consenta. È lo stesso passaggio che ha ucciso US-045: un assunto su Firestore dato per
buono a tavolino.

Nessuna correzione possibile da qui — è la prova che tocca a te. Il criterio resta **non
spuntato**.

---

## 🔵 Rilievi minori, nessuno bloccante

| | Dove | Cosa |
|---|---|---|
| 1 | `exercise_library_screen.dart:562` | Il menu del tipo mostra `type.name.toUpperCase()`: «STRENGTH», «CARDIO», non tradotti. **Preesistente**, il diff non tocca quel blocco, e il piano dice che il dialogo «chiede nome e tipo, e resta così» |
| 2 | `exercise_library_screen.dart:197` | `'Please log in'` scritto a mano. Preesistente |
| 3 | `exercise_library_screen.dart:89` | `description: 'Custom exercise'` finisce **nei dati** in inglese, per ogni esercizio creato da un italiano. Preesistente e invariato, ma è un campo salvato: se un giorno lo si mostra, si vede. Vale una riga di backlog, non una correzione qui |
| 4 | `exercise_library_screen.dart:531` | `ref.read` invece di `ref.watch` per `loc`: se la lingua cambia col dialogo aperto, le etichette non seguono. Dentro un dialogo modale è un caso che non capita |

---

## Checklist adversariale — cosa ho cercato

| Voce | Esito |
|---|---|
| File fuori dal piano? | No. Tre file, esattamente quelli della tabella |
| `nameController` viene rilasciato? | **Sì**, `:607`, dopo `await showDialog`. Era il rischio esplicito del piano (US-014): la ristrutturazione non l'ha perso |
| `BuildContext` usato dopo un `await`? | Guardato: `if (!dialogContext.mounted) return;` a `:582`, prima di `pop`, `setState` e toast |
| `setState` dello `StatefulBuilder` chiamato dopo un `await`? | Sì, ma `dialogContext` è il genitore dello `StatefulBuilder`: se è montato lo è anche lui |
| Il widget è stato clonato nel file di test? | **No.** Era l'errore di US-076, e il piano lo vietava: la logica è estratta in `handleAddExerciseSubmit` e provata lì, come `exerciseLibraryViewFor` |
| L'errore di validazione si pulisce da solo? | Sì, `onChanged` azzera `nameError` (`:548-552`): l'utente non resta col messaggio rosso mentre corregge |
| Stream o Future dentro `build`? | Nessuno introdotto |
| `FirestoreService.addExercise` è stato toccato? | No, come chiedeva il piano |
| Regole Firestore, CI, `pubspec.yaml` toccati? | No |
| Segreti, credenziali, percorsi locali? | Nessuno |
| Avanzi di Gradle o registrant di plugin nei commit? | No: entrambi i commit elencano i file |

---

## Limiti dichiarati di questa review

1. **Non ho provato l'app.** Il criterio che chiude la storia — l'esercizio salvato che compare
   in «Miei» — richiede Firestore vero e resta da confermare sull'APK. Con esso resta non
   verificato che il toast d'errore si veda **sopra** la barriera modale sullo schermo: il test
   dimostra che il messaggio è nell'albero e che l'`Overlay` giusto viene trovato, non l'ordine
   di disegno.
2. **La catena completa dentro `_showAddExerciseDialog` è letta, non eseguita.** La schermata
   non è montabile (debito di US-008). Le sue tre decisioni sono provate separatamente.
3. **Non ho provato il percorso di rete assente**, che è l'altro modo per cui questo `catch`
   scatta. Il codice non distingue i motivi del fallimento: un solo messaggio per
   `permission-denied`, timeout e rete assente. È una scelta difendibile — il piano chiedeva un
   messaggio comprensibile — ma è una scelta, non una verifica.
4. **`ToastUtils` non è stato messo in discussione**, solo usato. Il suo
   `Future.delayed(3s, () => overlayEntry.remove())` senza guardia (`toast_utils.dart:92-94`) è
   fuori dallo scope di questa storia; vedi la nota su US-081 nel riepilogo.
5. **I 56 avvisi** non sono stati esaminati: sono il debito di US-030.

---

_Review di fase 5 · US-079 · su codice non scritto da chi rivede_
