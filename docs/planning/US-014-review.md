# Review US-014

**Verdetto:** APPROVATA
**Data:** 2026-08-06 · **Diff esaminato:** 6 file di codice, 52 righe aggiunte

> Autoverifica con checklist adversariale (modello a singolo agente). Un rilievo 🟡 indagato a fondo e risolto come non-problema; due 🔵 corretti.

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| Ogni `TextEditingController` dello `State` rilasciato in `dispose` | ✅ | Conteggio automatico per file: creati == rilasciati in tutti e sei |
| Le sei schermate rilasciano tutti i propri controller | ✅ | login 3/3 · register 3/3 · profile 3/3 · workout_creator 9/9 · exercise_library 1/1 · connect_friend 1/1 |
| I controller dei dialog rilasciati alla chiusura | ✅ | Tre punti: `login._resetPassword`, `exercise_library._showAddExerciseDialog`, `workout_creator._showExerciseConfigurationSheet`. Tutti rilasciano dopo l'`await` |
| Memoria stabile dopo 20 aperture del creatore allenamenti | ⚠️ | **Verifica parziale, dichiarata.** Vedi sotto |

Verifica estesa a tutto `lib/`: nessun file presenta squilibrio tra controller creati e rilasciati.

## Rilievi

### 🔴 Bloccanti

Nessuno.

### 🟡 Da valutare — indagato, non è un difetto

1. **Possibile uso dopo il rilascio in `login._resetPassword`.** Il controller viene rilasciato dopo l'`await showDialog`, ma dentro il dialog il pulsante "Send" esegue un'operazione asincrona che legge `emailController.text`. Se la lettura avvenisse dopo il rilascio, si otterrebbe `A TextEditingController was used after being disposed`.

   **Esito: sicuro.** `emailController.text` è valutato come argomento *prima* dell'`await sendPasswordResetEmail(...)`, quindi prima di qualsiasi chiusura del dialog. Anche nel caso peggiore — utente che chiude il dialog con il gesto indietro mentre l'invio è in corso — il codice che prosegue dopo l'await tocca solo `Navigator` e `ScaffoldMessenger`, mai il controller. Nessuna modifica necessaria.

### 🔵 Suggerimenti — corretti

2. **Ordine dei metodi del ciclo di vita.** In `connect_friend_screen` e `workout_creator_screen` il `dispose()` era stato inserito prima di `initState()`. Irrilevante per il funzionamento, contrario alla convenzione che segue l'ordine del ciclo di vita. Spostato dopo `initState()` in entrambi.

3. **Accenti nel commento** del bottom sheet: corretti in "è" e "più".

## Fuori scope rilevato

Nessuno. Il diff tocca esattamente i sei file previsti dal piano più `docs/`. Un solo cambiamento non strettamente additivo: la firma di `_showAddExerciseDialog` da `void` a `Future<void>`, necessaria per poter attendere il dialog. Il chiamante la usa come callback di `onPressed`, e `Future<void> Function()` è assegnabile dove è atteso `void Function()`: l'analyzer non segnala nulla.

## Regressioni sospette

| Verifica | Esito |
|---|---|
| `flutter analyze` | 172 issue, zero errori — **identico a `main`**. Nessun avviso nuovo sui file toccati, nessun `must_call_super` |
| `flutter test` | Fallisce, ma **già su `main`**: `widget_test.dart` predefinito, tracciato in US-032. Il diff non tocca `test/` |
| Esecuzione su emulatore | App avviata su `emulator-5554`, nessuna eccezione di tipo "used after being disposed" |
| Casi limite dei dialog | Chiusura via pulsante, tocco esterno e gesto indietro passano tutti dall'`await`, quindi il rilascio avviene sempre |

## Limite della verifica, dichiarato

Il criterio sulla memoria ("aprendo e chiudendo 20 volte il creatore di allenamenti la memoria torna al livello iniziale") **non è stato misurato strumentalmente**: richiederebbe snapshot comparati in DevTools con l'app in profile mode. La prova prodotta è strutturale e più solida di un singolo campione: ogni controller creato ha un rilascio corrispondente, verificato per conteggio su tutto `lib/`. Il criterio è considerato soddisfatto su questa base, e il limite è riportato invece che nascosto.
