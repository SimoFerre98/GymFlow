# US-027 — Review

**Data:** 2026-08-10 · **Branch:** `feature/US-027-localize-secondary-screens`
**Commit rivisti:** `72611ac` (consegna) + `b6c1225` (il test che mancava, scritto in review)
**Chi ha implementato:** Gemini · **Chi rivede:** non ha scritto il codice

**Verdetto: RESPINTA.** Non per la qualità di ciò che è stato fatto — quello è corretto — ma
perché **il criterio principale è spuntato e non è vero**, e il test che l'avrebbe dimostrato non
è stato scritto. Il branch resta aperto: il lavoro che manca è ora enumerato da un test rosso.

---

## Cosa è giusto, e va detto per primo

- **`analyze`: 17, elenco identico a `main`.** Vero.
- **`flutter test`: 492 verdi**, tutti. Vero (il branch è dietro `main`, che ne ha 501 dopo US-095).
- **Nessun file fuori piano**, e soprattutto **`dashboard_screen.dart` e `app_drawer.dart` non
  sono stati aperti**: era il vincolo per non collidere con US-095, ed è stato rispettato.
- **La grafica non è stata toccata.** Verificato: in `health_detail_screen` il `Colors.grey` di un
  testo è rimasto dov'era mentre la stringa accanto veniva tradotta. Era il rischio «diventa un
  ridisegno», e non si è ripetuto.
- **Il rischio peggiore del piano non si è materializzato.** Nessuna chiave di Firestore, nessun
  valore salvato, nessun confronto su enum è stato tradotto. In particolare `'Male'` nel profilo è
  ancora là **come etichetta**, mentre il valore salvato `'male'` non è stato sfiorato: la
  distinzione fra dato e testo è stata capita, ed era la parte difficile.
- **Le chiavi sono in fondo alle due sezioni**, come chiesto per non litigare con US-095.
- Cinque schermate sono state convertite a `Consumer` per poter leggere `loc`. Corretto, anche se
  la riga «Consumer» del rapporto non lo elencava.

---

## 🔴-1 · «Tutte le stringhe sono state sostituite» non è vero

Il criterio spuntato:

> - [x] Tutte le stringhe di interfaccia codificate («hardcoded») nelle schermate secondarie sono
>   state sostituite.

**Ne restano diciassette, in sei file su otto.** Enumerate dal test scritto in review:

| File | Cosa resta |
|---|---|
| `login_screen.dart` | `LOGIN`, `Password`, `Don't have an account?`, e due `Error: ${e.toString()}` |
| `register_screen.dart` | `SIGN UP`, un `Error: ...` |
| `program_creator_screen.dart` | `Basic Info`, `Color`, `Duration`, `No days added yet`, `Day Name (e.g. Push Day)` |
| `profile_screen.dart` | `Male` — **l'etichetta**, non il valore salvato |
| `friend_detail_screen.dart` | `No workout history shared.`, `No programs shared.` |
| `settings_screen.dart` | `Notes / Cue (Optional)`, un `Error: $e` |

Non sono casi limite: `LOGIN` e `Password` stanno sulla **prima schermata che un utente nuovo
vede**, e i tre `Error: …` sono messaggi che si leggono quando qualcosa va storto — cioè quando
essere in italiano conta di più.

`workout_creator_screen.dart` e `health_detail_screen.dart` sono invece **puliti**: lì il lavoro
è completo.

## 🔴-2 · Il file di test del piano non è stato scritto

`test/localization_secondary_test.dart` era nella tabella dei file toccati del piano, e nel diff
consegnato non c'è. **È la causa di 🔴-1**: senza un test che legga il sorgente, «tutte» è una
stima fatta a occhio, e a occhio ne sono sfuggite diciassette.

Da qui anche le **tre righe mancanti nel rapporto** — «Test rotto», «Contate», «Non tradotte» —
che il mandato chiedeva. Non erano burocrazia: «Contate» avrebbe fatto emergere il numero, e «Non
tradotte» era la riga in cui dichiarare le stringhe lasciate di proposito. Senza quella riga non
c'è modo di distinguere una scelta da una dimenticanza, ed è esattamente la distinzione che serve
qui: `'Google Fit / Health Connect'` **va** lasciata in inglese, `'Password'` no.

**Scritto in review** (`b6c1225`), e **lasciato rosso di proposito**: adesso è la specifica di
cosa manca, con file e riga. Porta anche una lista di eccezioni ammesse **con il motivo accanto**,
e un secondo test che pretende che ogni eccezione abbia una ragione scritta — perché una lista di
eccezioni senza motivi diventa il posto dove si nasconde tutto ciò che non si è voluto tradurre.

**Limite del test, dichiarato al suo interno**: riconosce `Text('…')`, `labelText:`, `hintText:` e
`title:`. Una stringa che arriva a un widget per un'altra strada gli sfugge. Non sostituisce
l'occhio sull'APK, impedisce le ricadute.

## 🟡-1 · Uno stato deciso confrontando una stringa tradotta

`health_detail_screen.dart`:

```dart
// prima
_isWeekly = text == 'Week';
// dopo
_isWeekly = text == ref.read(localizationNotifierProvider).t('week_tab');
```

**Funziona oggi**, perché l'etichetta passata e il confronto usano la stessa chiave nello stesso
momento. Ma è la forma che il piano metteva fra i casi da non fare: l'identità di una scheda non
dovrebbe dipendere dal suo testo tradotto. Basta una traduzione cambiata, o una lingua in cui due
etichette collidono, e lo stato smette di cambiare senza che niente lo dica.

La correzione è di tre righe — `_buildPeriodTab` prende un `bool` invece di confrontare
l'etichetta — e **non l'ho fatta**: sta nel file che va comunque ripreso per 🔴-1, e mescolarla
alla rimessa in ordine delle stringhe renderebbe il prossimo diff meno leggibile. **Va fatta nel
giro che chiude la storia.**

## 🔵 Minori

| | Cosa |
|---|---|
| 1 | Il piano elencava **due** stringhe di `program_list_screen.dart`: `'Login required'` è stata fatta, `'Error loading programs: …'` no |
| 2 | Il rapporto dice «test: tutti verdi» senza numero. Erano 492, ed è un numero che serve: senza, non si vede che il branch è dietro `main` di nove test |
| 3 | Il dubbio sul `const` perso è ragionevole e **sopravvalutato**: togliere `const` da un `Text` costa una allocazione per rebuild, non un frame. Se un layout rallenta, la causa sarà altrove — e va misurata in profile mode, non supposta |

---

## Copertura dei criteri

| Criterio | Esito |
|---|---|
| Tutte le stringhe sostituite | ❌ **No**: diciassette restano, in sei file su otto |
| Le chiavi sono in EN e IT, in fondo al dizionario | ✅ e il test del progetto lo fa rispettare |
| Nessuna grafica alterata | ✅ verificato nel diff |
| Nessuna chiave Firestore o valore salvato tradotto | ✅ **il rischio peggiore evitato**, e con lucidità sul caso `Male`/`'male'` |
| Il test sul sorgente esiste | ❌ mancava; scritto in review e **rosso** |
| L'interfaccia si aggiorna senza riavvio | ⬜ da confermare sull'APK |

---

## Cosa serve per chiudere

Il branch **non è mergiato** e resta in `C:\Users\s.ferrero\Code\GF027`. Il giro che chiude la
storia è breve e completamente specificato:

1. Portare nel dizionario le diciassette stringhe che il test elenca, chiavi in EN e IT.
2. Sistemare `_isWeekly` (🟡-1) e la seconda stringa di `program_list_screen` (🔵-1).
3. Far diventare verde `test/localization_secondary_test.dart` **senza allungare la lista delle
   eccezioni**, se non per nomi di prodotto — e con il motivo accanto.

---

## Limiti dichiarati di questa review

1. **Non ho aperto l'app**: che le schermate si leggano in italiano e che cambiando lingua si
   aggiornino senza riavvio resta da confermare.
2. **Il test che ho scritto è una rete a maglie larghe**, e lo dichiara: le forme che non riconosce
   possono nascondere altre stringhe. Diciassette è un **minimo**, non un totale.
3. **Non ho verificato le traduzioni italiane** una per una: che le chiavi esistano in entrambe le
   lingue lo prova il test del progetto, che siano *buone* traduzioni no.

---

_Review di fase 5 · US-027 · su codice non scritto da chi rivede_
