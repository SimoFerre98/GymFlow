# US-025 — Review

**Data:** 2026-08-10 · **Branch:** `refactor/US-025-unify-workout-screens`
**Commit rivisti:** `679b361` (consegna) + `3ecabd8` (correzione fatta in review)
**Chi ha implementato:** Agy · **Chi rivede:** non ha scritto il codice

**Verdetto: APPROVATA CON RISERVE** — un rilievo corretto durante la review, due 🟡 che
richiedono una decisione e riguardano codice **preesistente** che questa storia rende
visibile per la prima volta.

---

## Numeri, misurati nel worktree e non presi dal rapporto

| | Dichiarato | Misurato |
|---|---|---|
| `flutter analyze` | 56 | **56** |
| `flutter test` | 434 verdi | **434 verdi** |
| File toccati | 3 | 3, tutti previsti dal piano |

**L'elenco degli avvisi è identico riga per riga a quello di `main`**, non solo il totale
(`diff` fra le due esecuzioni: nessuna differenza oltre all'intestazione). Il piano si
aspettava un possibile calo cancellando un file da 230 righe: non c'è stato, e la ragione è
verificabile — nessuno dei 56 avvisi era in `home_screen.dart`. I difetti di quel file
(`FirestoreService()` dentro `build`, stream ricreato a ogni ricostruzione, `Colors.grey`)
sono convenzioni del progetto, che l'analyzer non controlla. **Nessun calo da spiegare.**

---

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| Esiste una sola schermata delle schede | ✅ | `home_screen.dart` non esiste più; `grep -rn HomeScreen lib/` non trova nulla |
| La barra in basso porta a quella curata | ✅ | `main_screen.dart:22` monta `ProgramListScreen` come terza voce |
| Non si è perso niente | ✅ | Confronto rifatto in review, voce per voce: sotto |
| Il design system regge | ✅ | Suite intera verde, `design_system_usage_test.dart` compreso |
| La schermata si apre dalla barra | ⬜ **Da confermare sull'APK** | Richiede il dispositivo, non spuntato |

### Il confronto riga per riga, rifatto senza fidarsi del rapporto

Il rapporto dichiarava «`HomeScreen` non possedeva alcuna funzionalità assente in
`ProgramListScreen`». È l'affermazione più rischiosa della storia — è lo stesso punto dove
US-066 ha perso otto campi — quindi è stata rifatta dal sorgente cancellato.

| Cosa aveva `HomeScreen` | In `ProgramListScreen` |
|---|---|
| `AppBar` col titolo | ✅ `program_list_screen.dart:29`, e localizzato |
| `drawer: AppDrawer()` | ✅ riga 38 |
| `StreamBuilder` su `getUserPrograms` | ✅ riga 40 |
| Stato vuoto con icona e due righe di testo | ✅ righe 78-112, localizzato |
| Card che apre `ProgramCreatorScreen(program:)` | ✅ righe 176-183 |
| Pillola «ACTIVE» sulla scheda attiva | ✅ righe 209-229, ambra invece del verde fuori palette |
| `PopupMenuButton` → Elimina | ✅ righe 230-255 |
| Dialogo di conferma dell'eliminazione | ✅ `_confirmDelete`, righe 114-161 |
| Toast di conferma e di errore | ✅ righe 148-158 |
| Descrizione su due righe con ellissi | ✅ righe 260-271 |
| Date di inizio/fine, «Ongoing», «No dates set» | ✅ righe 281-288, localizzate |
| Conteggio dei giorni | ✅ righe 296-301 |

**Niente di unico è stato buttato.** In più `ProgramListScreen` ha uno stato di errore
(`snapshot.hasError`, righe 45-59) che `HomeScreen` non aveva: un guasto di lettura passa da
schermata vuota a messaggio.

Una sola differenza di comportamento, da dichiarare perché non è una perdita ma non è
identità: `HomeScreen` interrogava Firestore con `user?.uid ?? ''` anche a utente nullo,
`ProgramListScreen` mostra invece una schermata con `'Login required'` (riga 24). Vedi 🔵-1.

---

## Rilievi

### 🔴 → corretto in review · il terzo test certificava meno del proprio nome

Il test si chiama «`main_screen.dart` usa `ProgramListScreen` **per la terza voce**» e
verificava soltanto che la stringa `ProgramListScreen` comparisse **da qualche parte** nel
file.

Provato, non dedotto. Mutazione applicata al file vero e verificata prima di lanciare il
test — `_screens` diventa `[ProgramListScreen, CalendarScreen, DashboardScreen]`, cioè la voce
«Workouts» della barra mostra il Dashboard e la storia è annullata:

```
00:00 +3: All tests passed!
```

**Verde.** È esattamente la classe di difetto n. 2 del progetto: il test attesta l'errore.

Va detto a favore del test consegnato che la mutazione più ovvia la prende: sostituendo la
terza voce con `const DashboardScreen()` senza toccare l'ordine, l'identificatore
`ProgramListScreen` spariva dal file (l'`import` usa il nome in snake_case) e il test passava
a rosso. Il buco era la sola permutazione.

**Corretto in `3ecabd8`**: il test estrae la lista `_screens`, controlla che abbia tre voci e
che la terza sia `ProgramListScreen`. Rimessa la stessa mutazione, ora:

```
Expected: contains 'ProgramListScreen'
  Actual: 'const DashboardScreen()'
la terza voce della barra in basso deve essere ProgramListScreen, non const DashboardScreen()
```

Mutazione rimossa con `git checkout`, albero riportato pulito, suite intera rilanciata: 434
verdi, 56 avvisi.

### 🟡-1 · Due toast d'errore in fila, e i commenti-appunto dell'autore nel sorgente

`program_list_screen.dart:151-158`, dentro `_confirmDelete`:

```dart
} catch (e) {
  if (context.mounted) {
    // ToastUtils.showError(context, 'Error deleting program: $e');
    ToastUtils.showError(context, '${loc.t('error_deleting')}: $e');
    // I missed 'error_deleting', will fallback to English if missing or I should fix it.
    // I'll stick to English for technical error part.
    ToastUtils.showError(context, 'Error deleting program: $e');
  }
}
```

Chi non riesce a eliminare una scheda riceve **due** toast, il secondo in inglese. E la chiave
`error_deleting` **esiste** in entrambe le lingue (`localization_provider.dart:175` e `:446`):
il dubbio scritto nel commento era infondato, quindi la riga 157 e i due commenti sono
avanzi.

Sulla stessa funzione, riga 137: `loc.t('delete') != 'delete' ? loc.t('delete') : 'Delete'` è
un ternario morto — `'delete'` è tradotta (`:104`, `:375`), il ramo di ripiego non si prende
mai.

**Non è un difetto di US-025**: `git log -S` lo fa risalire a un commit `wip` anteriore a
US-022. Ma è US-025 che porta questa schermata sotto il dito dell'utente, quindi da oggi si
vede.

**Corretto su decisione dell'utente**, presa in fase 6 dopo che il rilievo gli è stato
presentato: la riga 157 e i tre commenti sono cancellati, e resta il solo toast localizzato. Il
ternario morto di riga 137 diventa `Text(loc.t('delete'))`.

**Fuori piano, dichiarato**: `program_list_screen.dart` non è fra i tre file della tabella del
piano, che dice anzi di non toccare quella schermata. La deroga è esplicita e riguarda solo
righe da cancellare — nessun comportamento nuovo, nessuna stringa nuova, nessun token toccato.
`design_system_usage_test.dart` resta verde.

### 🟡-2 · `@override` duplicato, righe 17-18 — corretto

```dart
@override
@override
Widget build(BuildContext context, WidgetRef ref) {
```

Compilava e l'analyzer non lo segnalava (i 56 avvisi non cambiano né prima né dopo).
Preesistente, rimosso nella stessa deroga.

### 🔵-1 · `'Login required'` non è localizzato

`program_list_screen.dart:24`. Preesistente da US-022, ma prima era raggiungibile solo dal
menu a panino; ora è la terza voce della barra. Il percorso è marginale — `MainScreen` si
mostra a utente autenticato — quindi non blocca.

### 🔵-2 · Il commento inglese sull'errore di lettura

`program_list_screen.dart:50`, «Technical error message usually kept in English or generic
error key». Il progetto scrive i commenti in italiano. Preesistente.

---

## Checklist adversariale — cosa ho cercato e non ho trovato

| Voce | Esito |
|---|---|
| Il diff contiene file non previsti dal piano? | No. Tre file, tutti nella tabella del piano |
| Il drawer compare due volte? | No: `MainScreen` non ha `drawer`, ce l'ha solo la schermata interna. Era il rischio dichiarato nel piano |
| Il pulsante del menu funziona dentro `IndexedStack`? | Sì per costruzione: il `Builder` del `leading` (righe 31-36) sta nel sottoalbero dello `Scaffold` di `ProgramListScreen`, quindi `Scaffold.of` trova quello e non l'esterno |
| `ConsumerWidget` dentro `IndexedStack` trova il `ProviderScope`? | Sì: `main.dart:21` lo mette alla radice |
| Il `FloatingActionButton` «New Program» della terza voce è sopravvissuto? | Sì: sta in `MainScreen` (`_currentIndex == 2`), non nella schermata sostituita, e il diff non lo tocca |
| Stream o Future creati dentro `build`? | Sì, `program_list_screen.dart:40` — **preesistente**, è il debito di US-011/US-012, e questa storia non lo introduce né lo peggiora |
| Risorse non rilasciate? | Nessun controller né sottoscrizione nel diff |
| Segreti, credenziali, percorsi locali? | Nessuno |
| Avanzi di Gradle o registrant di plugin nel commit? | No: entrambi i commit elencano i file. Nel worktree i `generated_plugin_registrant` risultano modificati da `pub get`, e sono rimasti **fuori** dai commit |

---

## Limiti dichiarati di questa review

1. **Non ho provato l'app.** Il criterio «la schermata si apre dalla barra» resta da
   confermare sull'APK, e con esso i due rischi che il piano affidava al dispositivo: il
   ritorno da `ProgramCreatorScreen` aperto con `Navigator.push` da dentro l'`IndexedStack`,
   e il comportamento del cambio voce dopo quel ritorno. Il ragionamento sopra dice che
   *dovrebbero* funzionare; non è una prova.
2. **L'ultima card sotto la barra flottante non è stata misurata.** `MainScreen` ha
   `extendBody: true` e la barra galleggia sopra il contenuto: se una scheda finisce nascosta
   dietro la pillola, era già così con `HomeScreen` (stesso padding, nessun `bottom` extra),
   quindi non è una regressione — ma non è nemmeno verificato che non sia un problema.
3. **La correttezza visiva del risultato non è stata guardata**, solo la sua conformità al
   design system attraverso il test sul sorgente. Che la schermata curata sia *quella giusta*
   è una decisione già presa nel piano, non una cosa che ho verificato io.
4. **`workout_type_pie_chart.dart:79` e gli altri 55 avvisi** non sono stati esaminati: sono
   il debito di US-030 e non appartengono a questa storia.

---

_Review di fase 5 · US-025 · su codice non scritto da chi rivede_
