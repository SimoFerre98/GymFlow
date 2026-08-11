# GymFlow — passaggio di consegne

**Aggiornato:** 2026-08-10 · **Commit:** `e913a37` su `main` e `dev`, allineati e pushati

Questo file serve a chi riprende il lavoro **senza la cronologia della conversazione**. Contiene
ciò che **non si deduce leggendo il repository**: decisioni prese a voce, trappole dell'ambiente,
e il livello di rigore atteso.

## Cosa leggere, e cosa non leggere

| Leggi | Perché |
|---|---|
| **Questo file**, per intero | È il più corto che contenga tutto |
| [`../AGENTS.md`](../AGENTS.md) · 153 righe | Le cinque regole che fanno fallire una consegna |
| [`WORKFLOW.md`](WORKFLOW.md) · 318 righe | Le 8 fasi. Leggi almeno le fasi 4 e 5 |
| [`DELEGA.md`](DELEGA.md) · 236 righe | Come si delega, e **il modello del mandato da incollare** |
| [`DESIGN-SPEC.md`](DESIGN-SPEC.md) · 185 righe | **Obbligatorio** se tocchi qualcosa che si vede |

⚠️ **`BACKLOG.md` è 3208 righe e 190 KB: non leggerlo tutto.** È la fonte di verità, e si consulta
**cercando**: `grep -n "^#### US-0XX" docs/BACKLOG.md` per una storia, `grep -n "Status:" ` per lo
stato di tutte. Leggere una storia significa leggere il suo blocco, non il file.

⚠️ **`docs/planning/` ha 82 file per 780 KB**: sono i piani e le review di ogni storia affrontata.
**Non si leggono in blocco.** Si apre `US-XXX.md` quando si lavora a `US-XXX`, e
`US-XXX-review.md` quando serve sapere perché una cosa è com'è. Le review delle storie chiuse sono
archivio: preziose come precedenti, inutili come lettura.

⚠️ **`README.md` sovrastima l'app.** Descrive funzioni come complete quando sono intenzioni
(«drag & drop planner», «sync with device calendar»). Le sue affermazioni tecniche sono state
corrette, il resto no: **non usarlo come fonte di verità su cosa l'app fa**.

---

## 1. Dove siamo

**47 storie completate su 102.** **17 avvisi** dell'analyzer, **zero errori**, **501 test verdi**
(erano 102 a inizio progetto). CI verde su entrambi i branch.

### ⚠️ Leggi prima questo: Firestore negava tutto da sei mesi

Scoperto il 2026-08-10. Le regole in produzione erano quelle di prova generate alla creazione del
database, con la loro scadenza: `if request.time < timestamp.date(2026, 2, 24)`. **Falsa dal 24
febbraio.** Ogni lettura e ogni scrittura negate, a tutti, per quasi sei mesi.

Spiegava insieme cose che sembravano separate: lo storico vuoto, «Nuovo esercizio» che non salvava,
**US-045 morta** e **US-072 nata per aggirarla**, l'errore su `ensureFriendCode`.

Ora `firestore.rules` è nel repository e ogni utente vede **solo i propri dati**. Resta **una**
negazione, deliberata: la query della condivisione fra amici — vedi **US-080**.

**La lezione, e vale ancora**: quando un dato non arriva, il primo controllo è
`adb logcat | grep PERMISSION_DENIED`, non il codice che lo legge. Il 2026-08-10 ha trovato un
secondo difetto per questa strada — vedi US-098.

### Cosa si vede a schermo, oggi

**Aggiornato il 2026-08-11, dopo una sessione di implementazione diretta** (niente fasi di
`WORKFLOW.md`, per scelta esplicita dell'utente: si formalizza a fine lavoro, non prima). Il
**test sul sorgente** (`test/design_system_usage_test.dart`) ora sorveglia **l'intero albero di
`lib/src/ui`**, non solo le quattro schermate principali: schermate e widget, uno per uno, elencati
in `schermate` e `widgetDeiMockup` dentro il file stesso.

**US-023** (schermate secondarie) e **US-038** (barra di navigazione) sono ✅ **DONE** — vedi le loro
voci in `BACKLOG.md` per cosa e stato toccato e cosa e dichiarato limite. La barra in basso non usa
più `google_nav_bar`: il pacchetto e stato tolto anche da `pubspec.yaml`, non solo dal widget.

**Il debito visibile di US-034** — `Colors.grey` ereditati dal fondo chiaro — non dovrebbe più
comparire in nessuna schermata: ogni file di `lib/src/ui` e passato dai ruoli del `ColorScheme`.
Se l'utente segnala ancora testi sbiaditi, è una regressione, non il debito noto — e il test
guardiano dovrebbe già averla presa, quindi il primo sospetto è un colore letto da un posto che il
test non guarda (uno stile di `Theme.of(context).textTheme` senza `.copyWith`, per esempio).

---

## 2. ⚠️ Cosa è in volo adesso

**Tre worktree aperti**, e due contengono lavoro:

| Worktree | Branch | Stato |
|---|---|---|
| `C:\Users\s.ferrero\Code\GF027` | `feature/US-027-localize-secondary-screens` | ⚠️ **RESPINTA**, e il lavoro che resta è **enumerato da un test rosso**: `flutter test test/localization_secondary_test.dart`. Diciassette stringhe. Leggi `docs/planning/US-027-review.md` |
| `C:\Users\s.ferrero\Code\GF094` | `feature/US-094-session-timer-button` | 📋 Pianificata, **non iniziata**. Piano in `docs/planning/US-094.md` |
| `C:\Users\s.ferrero\.gemini\antigravity\worktrees\GymFlow\*` | vari | **Rumore di Gemini**: se li trovi vuoti e fermi a un commit di `main`, si rimuovono |

**Il mandato per finire US-027 e quello per US-094 sono già scritti** e sono stati consegnati
all'utente. Se servono di nuovo, si ricostruiscono dal modello in `DELEGA.md` più i due piani.

### Chi fa cosa

Il modello è cambiato il 2026-08-06 e vale ancora: **chi ha il contesto pianifica (fase 1) e
rivede (fase 5), chi è veloce implementa (fasi 2-4)**, e il merge resta una decisione dell'utente.
L'esecutore oggi è **Gemini (Antigravity CLI)**, con l'utente come tramite: l'orchestratore prepara
il mandato, l'utente lo incolla, e riporta indietro il rapporto.

⚠️ **`agy -p` non funziona** (`timeout waiting for response`, zero turni): l'orchestratore non può
lanciarlo da sé. E **Gemini crea worktree propri** anche quando il mandato lo vieta: quando torna
un rapporto, `git worktree list` prima di cercare il branch.

---

## 3. Ambiente: quello che non funziona come ti aspetti

Flutter **non è nel PATH**: `export PATH="/c/Users/s.ferrero/Flutter/bin:$PATH"`. Flutter 3.38.7,
Dart 3.10.7.

| Target | Stato |
|---|---|
| **Android** | ✅ l'unico attivo |
| Web | ❌ Isar genera interi a 64 bit non rappresentabili in JS. Accantonato in **EP-008** |
| Windows desktop | ❌ Visual Studio non installato |

**Telefono**: Samsung S26 Ultra, `RFGL10YZ5RX`. Si scollega spesso: `adb devices` prima di
installare. `adb` sta in `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`.

```bash
flutter build apk --debug --target-platform android-arm64
adb -s RFGL10YZ5RX install -r build/app/outputs/flutter-apk/app-debug.apk
```

**Mai `flutter install`**: disinstalla l'app e cancella i dati, e l'utente si ritrova scollegato da
Firebase. Con `adb install -r` si conserva tutto — si verifica che `firstInstallTime` in
`adb shell dumpsys package com.example.gymflow` **non** sia cambiato.

| Trappola | Come si evita |
|---|---|
| **`dart format` su questo repository** | **Non lanciarlo**: i file non sono formattati così, e riscriverebbe centinaia di righe non toccate. `dart fix --apply --code=<regola>` invece è sicuro e mirato: US-030 ha fatto 23 correzioni con un diff di 9 file |
| **`git checkout -- <file>` dopo una mutazione** | Ripristina **tutto** il file, quindi cancella anche la correzione che stavi verificando. Succeduto due volte. Usa una **copia di sicurezza** |
| **`git switch` dentro un worktree** | Sposta **quel** worktree, non la cartella principale. Un `git switch dev` girato in `GF027` ha spostato quel worktree su `dev` e un `reset` successivo ha fatto regredire `dev`. Verifica sempre `pwd` |
| **`git merge --squash`** | Non marca il branch come merged: si cancella con `git branch -D` |
| **Rimuovere un worktree** | `git worktree remove` fallisce con «Filename too long» se dentro c'è una `build/`. Serve `Remove-Item -LiteralPath "\\?\C:\...\GF0XX" -Recurse -Force` in PowerShell, poi `git worktree prune`. Con `--force` e senza `build/` funziona |
| **`firebase deploy --only firestore:rules`** | Con il multi-database **non fa niente** e stampa «Deploy complete!». Usare `--only firestore` e verificare il ruleset dall'API |
| **`git add -A` in un worktree** | Raccoglie avanzi di Gradle e registrant di plugin rigenerati. Elencare i file |
| **Percorsi Android in bash** | Anteporre `MSYS_NO_PATHCONV=1` |
| **`sleep` in bash** | Bloccato: usare `run_in_background` |
| **Il buffer di `logcat` gira** | 240.000 righe e la traccia sparisce. `adb logcat -c` **prima** di far riprodurre un difetto |

---

## 4. Il livello di rigore atteso

È il punto che si perde cambiando sessione, ed è il più importante di questo file.

**Quando un criterio non è verificabile, si dichiara. Non si spunta.** Ogni review del progetto ha
una sezione sui limiti, ed è quella che rende credibile il resto.

**Non fidarsi del rapporto di consegna.** Si rifanno `analyze` e `test` nel worktree, e si riparte
dal diff. Il 2026-08-10: una consegna dichiarava «nessun nuovo avviso» avendone introdotti tre nel
proprio file di test, e «456 verdi» con **la suite rossa**. Un'altra dichiarava un baseline che non
esisteva.

**Confrontare l'ELENCO degli avvisi con `main`, non il totale.** Un calo va spiegato quanto un
aumento: può venire dal codice che la storia riscriveva davvero — legittimo — o da un rifacimento
fuori mandato.

**Rompere il codice di proposito e controllare che un test diventi rosso.** È il controllo che ha
trovato più difetti in assoluto. Tre avvertenze pagate care: **verifica che la mutazione sia
davvero nel file** prima di crederci; muta il **file vero**, non una copia; e **scegli una
mutazione diversa** da quella che l'esecutore ha già provato — la sua è quella che il suo test
prende già.

### Dove nascono i difetti, in ordine di frequenza misurata

1. **Valori del mockup copiati invece che convertiti.** `dp = px × 1,36` per i mockup 01 e 02,
   `× 1,20` per il 03. Successo in US-073, US-047, US-050, e in US-062 nella forma più letterale
   possibile: cinque `fontSize: 8.5`, cioè la riga `.exr-meta { font-size: 8.5px }` del CSS. In
   US-082 in forma nuova: `spacing.sm + spacing.xs` per riottenere 12 senza scrivere un letterale.
   **La lezione dentro la lezione**: la guardia ne vide tre su undici, perché il piano chiedeva di
   aggiungere i **file nuovi** alla lista sorvegliata e non era stato fatto. Un test che sorveglia
   solo i file vecchi non sorveglia niente.
2. **Test che certificano meno del loro nome.** In US-025 «usa `ProgramListScreen` per la terza
   voce» cercava la stringa nel file intero: restava verde con la schermata montata sulla prima
   voce. In US-062 «changes arc based on fraction and radius» controllava solo il parametro del
   costruttore.
3. **Test che provano i pezzi e non il cablaggio fra loro.** In US-093 il cronometro non si muoveva
   da un giorno: le viste prendevano il notifier con `ref.read`, che non crea iscrizioni. I test
   provavano il notifier — corretto — e che la schermata si aprisse senza eccezioni. Entrambi
   verdi, entrambi ciechi: **nessuno guardava cosa viene disegnato**. In US-036 il test della
   transizione montava un widget scritto nel file di test.
4. **Criteri spuntati e non veri.** In US-027 «tutte le stringhe sostituite» con diciassette
   rimaste. In US-066 «il peso arriva da Salute» diventato «nessuna importazione da Salute» ✓.
5. **Dati inventati mostrati come veri.** In US-062 `currentDay: 3`, `progressFraction: 0.72` e
   `durationMinutes: 45` erano i numeri d'esempio del mockup: l'anello avrebbe indicato 72% a chi
   non si è mai allenato. **Un numero inventato è peggio di un numero assente**: il secondo si nota
   e si chiede, il primo si crede.
6. **Riscritture che cancellano senza dichiararlo.** In US-066 la schermata delle misure è passata
   da undici campi a quattro e i dati salvati sono diventati invisibili. Niente falliva. Da qui la
   regola per gli spostamenti: **il diff deve leggersi come taglia e incolla**, e si verifica
   confrontando le righe uscite con quelle entrate (fatto in US-095).
7. **Troncamenti nei calcoli.** Un `toInt()` dentro un ciclo perde i mezzi chili a ogni serie:
   corretto in US-049 e **sopravvissuto** in `statistics_helper` fino a US-096, perché erano due
   calcoli diversi.

E tre rilievi che si sono rivelati **sbagliati**, per ricordare che si verifica prima di segnalare:
«usa `DateFormat` per i mesi», «le sagome non sono outline», e «il cronometro tronca una cifra».
Nel 2026-08-10 se ne aggiungono due miei: un `FadeTransition` che credevo sollevasse un'assertion
(`getAlphaFromOpacity` limita internamente) e un `drawer` che credevo perso e era solo spostato.

---

## 5. Decisioni prese, che non si deducono dal codice

### Direzione visiva: palette Indigo, app scura

| Ruolo | Colore | Significato |
|---|---|---|
| Sfondo | `#221E3A` | |
| Superfici | `#312C51` / `#48426D` | Card, e card dentro card |
| **Azione** | `#F0C38E` ambra | **Un solo significato: cosa fare adesso** |
| **Dati vitali** | `#F1AA9B` salmone | Battito, sforzo. Mai per le azioni |

La separazione è deliberata: se l'ambra compare su qualcosa che non è un'azione, l'occhio impara a
ignorarla. È già stata corretta due volte in review (US-082, US-062).

⚠️ **L'ambra come fondo non è `primary` nel tema chiaro**, è `primaryContainer`: nel chiaro
`primary` è un marrone scuro pensato per il testo.

### Material 3 Expressive: costruito, non installato

Flutter non lo supporta. Vedi [`adr/001-material-3-expressive.md`](adr/001-material-3-expressive.md).
Tutti i token passano da `ExpressiveTokens`, letta con `context.expressive`.

**`motor 1.1.0` è installato** (US-036) e serve per la **fisica**, non per le curve: la molla del
mockup è `Cubic(0.34, 1.56, 0.64, 1)`, che si scrive in una riga. Ciò che una curva a durata fissa
non sa fare è ripartire da posizione e velocità correnti quando un gesto la interrompe.

### Trainer e schede: l'ordine è deciso

**EP-016 «Schede come le scrive un allenatore» viene prima di EP-017 «Trainer e clienti».**
Verificato nel modello: `WorkoutTemplateExercise` ha **un** `targetSets`, **un** `targetReps` e
**un** `targetWeight`, quindi **nessuna delle quattro schede reali** dell'utente è rappresentabile.
Un trainer che non può scrivere `4x(15-12-10-8)` con i carichi non usa l'app per lavoro.

- **US-083** (modello delle serie, 8pt) è pianificata e **non delegabile**. Il punto 4 è deciso:
  `perSide` vive nel piano, Isar resta fuori.
- **US-087** (l'invito) **assorbe US-080**: lo stesso meccanismo serve a trainer e amici.
- **US-092** (consenso e revoca) viene **prima** di US-091 (l'andamento): un consenso aggiunto
  sopra una funzione che già mostra tutto è un consenso finto.

### Verifica tramite APK

Il ciclo **non esegue l'app**: produce un APK, l'utente prova sul telefono. I criteri che
richiedono interazione si marcano **«da confermare sull'APK»**, mai spuntati.

---

## 6. Prove sul dispositivo in sospeso

L'APK installato il 2026-08-10 alle 23:54 contiene tutto fino a `e913a37`.

| Cosa | Dove | Storia |
|---|---|---|
| ⭐ **L'evento programmato compare nel calendario.** Se **ancora** non compare, il difetto è nella **scrittura** e non nella lettura, e va cercato altrove | Calendario → «+» | US-098 |
| ⭐ Nel trasloco non si è rotto niente: quattro tessere coi numeri giusti, due grafici che disegnano, storico che elenca | menu → Statistiche, o l'icona in alto sulla home | US-095 |
| La home senza l'anello non risulta povera. Se lo fosse, **non** si rimettono i numeri finti: si sblocca US-059 e si fa US-063 | apri l'app | US-062 |
| Un esercizio creato compare in «Miei» e sopravvive alla chiusura | Menu → Esercizi → «+» | US-079 |
| La schermata rossa `_dependents.isEmpty`. **Serve lo stack**: `adb logcat -c`, riprodurre, `adb logcat -d \| grep -A40 dependents` | creando un esercizio | US-081 |
| Il cronometro scorre, e l'assestamento a molla sul cambio voce si vede senza risultare lento | Menu → Cronometro; le tre voci della barra | US-093, US-036 |
| Il saluto mostra il nome dal primo istante, non «Atleta» | apri l'app | US-008 |
| La build **release** si installa e si avvia | serve un APK release | US-040 |
| 55 fps su 100 esercizi, in build **profile** | menu → Design system | US-043 |

---

## 7. Cosa fare adesso

**Non fidarti di un elenco di storie eseguibili scritto qui**: invecchia in un giorno. Si ricava
dal backlog — una storia è pronta quando tutte quelle in `Depends on` sono `✅ DONE`.

Le priorità decise con l'utente, in ordine:

1. **Finire US-027** (branch aperto, test rosso che elenca il lavoro) e **US-094** (pianificata).
2. **US-083**, il modello delle serie: sblocca l'importazione delle schede reali **e** il trainer.
   Non delegabile.
3. **US-101** (il saluto sotto l'hamburger) e **US-100** (Health Connect nega `READ_STEPS`, e la
   sezione salute della dashboard **fallisce in silenzio**). Entrambe piccole e delegabili.
4. **US-102**, gli avvisi rimasti (11 al 2026-08-11, scesi da 13 sistemando i due `dead_code` di
   `workout_type_pie_chart.dart` dentro il lavoro di US-023). **Non sono rumore**: tre restano
   intenzioni non implementate — l'ora che il dialogo di fine allenamento butta, «Azzera» che
   compare a cronometro su zero, `_isLoading` scritto e mai letto in `settings_screen.dart:37`.
   **Non si cancellano: si implementano o si dichiarano.**
5. ~~US-038 (la barra in basso) sblocca US-023 e US-051~~ — **fatte entrambe**, US-051 resta da
   verificare a parte (badge di Obiettivi, non toccati in questa sessione).

### Decisioni ancora aperte

- **US-099**: la vibrazione «in stile iPhone» **probabilmente non è raggiungibile** con
  `HapticFeedback`, che l'SDK stesso dichiara non adatto al controllo preciso; su Android diventa
  `LONG_PRESS`/`VIRTUAL_KEY`, tocchi brevi tarati dal produttore. Si prova `heavyImpact()` perché
  costa zero, e **se è moscia serve una dipendenza**: decisione dell'utente.
- **US-074**: il record tiene conto delle ripetizioni? Serve decidere se un massimale stimato aiuta
  o confonde.
- **`docs/design/04-other-ideas.html`**: un mockup nuovo aggiunto dall'utente il 2026-08-10, **non
  ancora letto né estratto in `DESIGN-SPEC.md`**. Se contiene decisioni visive, va estratto **prima**
  che qualcuno ci lavori sopra, o si ripete la storia dei pixel copiati.
- Le **tessere della dashboard**: sforzo e calorie in salmone, conteggi in indigo. Da confermare.
- **«Recenti»** nella libreria è una voce che non filtra niente: resta o sparisce?

---

## 8. Convenzioni di scrittura

- **Italiano** per commenti, documentazione e commit. Il codice resta in inglese.
- **I commenti spiegano il perché.** Un commento che ripete la riga sotto è rumore.
- **Nessun riferimento ad AI** nei commit o nel codice. Nessun trailer `Co-Authored-By`.
- **Le review dichiarano i limiti.** Una review senza sezione sui limiti è sospetta.
- Niente stringhe fuori dalla localizzazione, niente colori fuori da `app_palette.dart`, niente
  numeri per spaziature e raggi: vengono da `context.expressive`.

---

## 9. Verifica rapida all'inizio di una sessione

```bash
git worktree list                                    # PRIMA di git log: c'è lavoro in volo?
git status --porcelain
git log --oneline -5
git rev-list --left-right --count origin/main...main
git rev-list --left-right --count main...dev         # deve dare 0 0
```

Il 2026-08-07 è servito **mezzo pomeriggio** per rimediare a due storie consegnate come un unico
mucchio non committato, con rapporti che dichiaravano gli stessi numeri perché misurati sullo
stesso albero. Da qui la regola del worktree per storia, e il motivo per cui il primo comando non
è `git log`.

---

_Documento di passaggio · GymFlow · riscritto il 2026-08-10 sul commit `e913a37`_
