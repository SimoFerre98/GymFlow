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

# Secondo giro — 2026-08-11

**Commit rivisti:** `efcc4a6` (la consegna che chiudeva i rilievi) + `6cd71e9` (le correzioni fatte
in questa review)

**Verdetto: RESPINTA alla consegna, APPROVATA dopo le correzioni.**

## Cosa era vero nella consegna

Verificato rifacendo tutto, non leggendo il rapporto:

- **`analyze`: 17, elenco identico a `main`.** Confrontato riga per riga.
- **`flutter test`: 501 verdi**, la suite intera — non i dieci del file che il rapporto citava.
- **Il file di test non e stato toccato** per farlo diventare verde: `git diff 18c0c7b..efcc4a6 --
  test/` e vuoto. Era il sospetto piu ovvio ed e infondato.
- **Le diciassette stringhe sono davvero passate nel dizionario**, con la chiave in EN e IT — tutte
  e quindici le chiavi nuove compaiono due volte — e le traduzioni italiane sono italiane.
- **🟡-1 e 🔵-1 del primo giro sono chiusi**, e bene: `_buildPeriodTab` prende ora un `bool`
  esplicito invece di confrontare l'etichetta tradotta.

## 🔴-3 · Il test riconosceva una forma sola, e ne restavano trentanove

Il test scritto nel primo giro leggeva **riga per riga** e cercava `Text('…')`, `labelText:`,
`hintText:`, `title:`. Il suo limite era dichiarato — «una stringa che arriva a un widget per
un'altra strada gli sfugge» — ma la misura di quel limite no.

`Text(` con la stringa **sulla riga sotto** — che e come vengono spezzate le righe lunghe — non
veniva visto. Ne una stringa passata come argomento a un widget interno: `_buildStatCard(context,
'Streak', …)`, `label: 'Sets'`.

**Trentanove stringhe**, non diciassette. Fra queste `'Welcome Back'` e `'Join GymFlow'`, cioe le
prime parole che un utente nuovo legge, e tutti i messaggi d'errore dei toast — «Upload failed»,
«Failed to save profile», «Gym Info Saved!».

Il criterio «tutte le stringhe sostituite» era quindi **spuntato e non vero per la seconda volta**,
e stavolta con un test verde a sostenerlo. È la lezione dell'handoff sui test che sorvegliano meno
di quanto promettono, e la variante nuova e questa: **un test che riconosce una forma sola sorveglia
una forma sola** — e da quel momento e la forma, non la regola, a definire cosa e un difetto.

**Corretto in questa review.** La rete e rovesciata: si guarda **ogni** letterale che comincia per
maiuscola, e cio che non deve finire a schermo va dichiarato — per il contesto in cui compare
(`debugPrint(`, `DateFormat(`, `Exception(`) o per nome, col motivo accanto. Le trentanove stringhe
sono nel dizionario, in EN e IT.

**Mutazione, e diversa da quella dichiarata**: rimessa `'Exercises'` a mano sulla riga sotto
`Text(` — la forma che prima sfuggiva — il test diventa rosso e la indica per riga.

## 🔴-4 · La schermata di accesso non si iscriveva alla localizzazione

`login_screen.dart` leggeva **quindici** stringhe con `ref.read(localizationNotifierProvider)`, di
cui sette dentro `build`, e non chiamava `ref.watch` da nessuna parte. `read` non crea
un'iscrizione: cambiando lingua quella schermata sarebbe rimasta nella lingua di prima finche
qualcos'altro non l'avesse ricostruita.

**È lo stesso difetto di US-093**, dove il cronometro non si muoveva per la stessa ragione. E come
allora, nessuno dei test sul sorgente poteva vederlo: contano le stringhe tradotte, non guardano
cosa viene disegnato.

Oggi non e visibile a un utente — la lingua si cambia dalle impostazioni, e per arrivare al login
bisogna uscire, cosa che ricostruisce la schermata. È un difetto che aspetta, non uno che morde.

**Corretto**, e coperto da `test/localization_live_switch_test.dart`, che monta la schermata, cambia
lingua e pretende che il testo cambi. **Mutazione**: rimesso `read` al posto di `watch`, il test
diventa rosso.

## 🔵 Minori del secondo giro

| | Cosa |
|---|---|
| 1 | Il rapporto diceva «10 test passati» citando **un file solo**: la suite ne aveva 501. Il numero della suite e l'unico che dice qualcosa |
| 2 | «Fuori piano: nessuno» ma il diff toglie il BOM da sei file. Innocuo, e non l'ho rimesso: rimetterlo sarebbe rumore in piu |
| 3 | Cinque delle mie chiavi nuove collidevano con chiavi gia nel dizionario. Tre avevano lo stesso significato e ho riusato quelle vecchie; due no (`welcome_back` e la home, `exercises_title` e la libreria) e hanno preso un nome proprio |

## Copertura dei criteri, aggiornata

| Criterio | Esito |
|---|---|
| Tutte le stringhe sostituite | ✅ e stavolta con un test che vede piu di una forma |
| Le chiavi sono in EN e IT | ✅ verificate una per una, e il test del progetto lo impone |
| Nessuna grafica alterata | ✅ nel diff non entra un solo valore visivo |
| Nessuna chiave Firestore o valore salvato tradotto | ✅ `'male'` resta il valore, `Male` era l'etichetta |
| Il test sul sorgente esiste ed e verde | ✅ |
| L'interfaccia si aggiorna senza riavvio | ✅ **su una schermata**, provato; ⬜ sulle altre sette resta da confermare sull'APK |

## Limiti dichiarati del secondo giro

1. **La rete e piu larga, non completa.** Prende i letterali che cominciano per **maiuscola**: una
   stringa che comincia per minuscola gli sfugge ancora. Trentanove era un minimo misurato con una
   regola, non un totale.
2. **Il cambio lingua a caldo e provato su una schermata sola**, quella di accesso: e l'unica delle
   otto che si monta senza Firebase. Per le altre resta il controllo sul sorgente, che prova una
   cosa piu debole — che la stringa venga dal dizionario, non che la schermata si iscriva.
3. **Non ho aperto l'app**, e le traduzioni non le ha lette un occhio umano in contesto: `'Serie'`
   per `Sets` e giusto in palestra, ma e la parola che in italiano fa anche «serie di giorni».

---

_Review di fase 5 · US-027 · su codice non scritto da chi rivede · secondo giro il 2026-08-11_
