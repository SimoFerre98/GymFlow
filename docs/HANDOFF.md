# GymFlow — passaggio di consegne

**Aggiornato:** 2026-08-10 · **Commit:** `d97cb53` su `main` e `dev`

Questo documento serve a chi riprende il lavoro in una sessione nuova, con un altro modello o senza la cronologia della conversazione. Contiene **ciò che non si deduce leggendo il repository**: decisioni prese a voce, trappole dell'ambiente, e il livello di rigore atteso.

Da leggere in quest'ordine:

1. **Questo file** — stato, decisioni, trappole
2. [`../AGENTS.md`](../AGENTS.md) — le regole operative, valide per qualunque assistente. [`../CLAUDE.md`](../CLAUDE.md) contiene solo le specificità di Claude Code e rimanda qui
3. [`WORKFLOW.md`](WORKFLOW.md) — il processo per ogni storia
4. [`DELEGA.md`](DELEGA.md) — come si lavora in parallelo, e cosa non si delega
5. [`DESIGN-SPEC.md`](DESIGN-SPEC.md) — le specifiche visive estratte dai mockup, con la conversione px → dp
6. [`BACKLOG.md`](BACKLOG.md) — le 94 storie con dipendenze e stati
7. [`adr/001-material-3-expressive.md`](adr/001-material-3-expressive.md) — la decisione sul design system

---

## 1. Dove siamo

**47 storie completate su 102** · tag `v0.1.0` marca la fine del risanamento tecnico.

### ⚠️ Leggi prima questo: Firestore negava tutto da sei mesi

Scoperto il **2026-08-10** aprendo US-018. Le regole in produzione erano quelle di prova
generate alla creazione del database, con la loro scadenza:

```
allow read, write: if request.time < timestamp.date(2026, 2, 24);
```

**Falsa dal 24 febbraio 2026.** Ogni lettura e ogni scrittura negate, a tutti, per quasi sei
mesi. Verificato sul dispositivo: sei `PERMISSION_DENIED` in dodici secondi di avvio.

Spiegava insieme cose che avevano spiegazioni separate: lo storico allenamenti vuoto sulla
dashboard, «Nuovo esercizio» che non salvava, **US-045 morta** con `permission-denied` e
**US-072 nata per aggirarla**, l'errore su `ensureFriendCode`, e il commento in `getExercises`
sulla query che «restituiva sempre zero documenti».

Ora `firestore.rules` è nel repository e le regole pubblicate danno a ogni utente **solo i
propri dati**. Dopo: **una** negazione, la query della condivisione fra amici, chiusa
deliberatamente — vedi **US-080**. Lo storico è tornato: tredici sessioni sulla dashboard.

**La lezione, per la prossima volta**: quando un dato non arriva, il primo controllo è
`adb logcat | grep PERMISSION_DENIED`, non il codice che lo legge.

**EP-009 «Contenuti degli esercizi» è chiusa** per intero. **EP-010 «Sessione di allenamento» è a 4 storie su 6**, ed è dove è concentrato tutto il lavoro recente.

| Fatto | Effetto misurato |
|---|---|
| US-001 | Il branch `dev` non compilava: errore di compilazione risolto |
| US-039 | Deploy web sospeso: la pipeline non fallisce più per un target rimandato |
| US-014 | 20 controller rilasciati, nessuno squilibrio in `lib/` |
| US-024 | Avvisi analyzer **da 172 a 66** |
| US-005, US-006, US-007 | Migrazione completa a Riverpod, `package:provider` rimosso |
| US-029 | CI attiva, primi test reali del progetto |
| US-040 | Build release ripristinata: 25,9 MB contro i 101 del debug |
| US-033, US-034 | Design system Expressive e palette Indigo |
| US-021 | Componenti visivi condivisi, con catalogo interno |
| US-041÷US-045, US-070, US-072 | EP-009 intera: foto e video, catena di ripiego, miniature, libreria curata che si carica da sola |
| US-071 | Stringhe non tradotte che si vedevano a schermo |
| US-073 | Componenti allineati ai mockup: gradiente unico, pallino salmone, card su `ink-700` |
| US-046 | Serie registrabile con i cursori, **senza tastiera** |
| US-047 | Pannello delle metriche dal vivo nella sessione, con sparkline |
| US-049 | Riepilogo di fine allenamento, con lo scontrino |
| US-050 | Record personali riconosciuti mentre succedono |
| US-025 | **Il lavoro di US-022 si vede**: la barra in basso non punta piu al duplicato mai convertito, e le 230 righe del duplicato sono via |
| US-079 | «Nuovo esercizio» dice quando fallisce, invece di non fare niente |
| US-082 | La sessione attiva, la schermata piu usata, prende i colori e le misure del design system |
| US-093 | **Il cronometro e il timer rispondono di nuovo ai tasti**: due viste non si iscrivevano allo stato, e lo schermo restava fermo sul primo frame |
| US-008 | I servizi arrivano dai provider nelle tre schermate principali, e per la prima volta **un test monta una schermata vera** con un servizio finto |
| US-036 | Il movimento a molla nei token, e sul cambio di voce della barra. `motor` installato |
| US-062 | **La home apre con l'allenamento di oggi e una sola azione**: e la prima schermata del mockup 01 a schermo |
| US-095 | Le statistiche hanno una schermata loro, e la home resta corta com'e disegnata |

**Stato di salute:** **17 avvisi**, **zero errori**, **501 test verdi** (erano 102 a inizio progetto), CI verde su entrambi i branch.

### Le due storie consegnate da Agy, e cosa ha trovato la review

Sono le prime due arrivate dall'esecutore esterno con l'umano come tramite (vedi
[`DELEGA.md`](DELEGA.md)). **Entrambe con i numeri dichiarati corretti** — verificati rifacendo
`analyze` e `test` nei worktree, elenco degli avvisi confrontato riga per riga con `main`, non
solo il totale. E in entrambe la review ha trovato qualcosa che i test non prendevano:

- **US-025**: il test si chiamava «usa `ProgramListScreen` per la terza voce» e cercava la
  stringa nel file intero. Con `_screens = [ProgramListScreen, Calendar, Dashboard]` — cioè la
  voce «Workouts» che apre il Dashboard, storia annullata — restava **verde**.
- **US-079**: il `catch` scartava l'eccezione. Dopo il diff nel file non restava **un solo**
  `debugPrint`, dove prima ce n'era uno. Il piano chiedeva «un messaggio comprensibile, con il
  dettaglio tecnico nel log»: metà fatta, metà nella direzione opposta. In una storia nata da un
  `permission-denied` invisibile per sei mesi.
- **US-079**: la guardia sul sorgente vietava i `catch` col solo `debugPrint` e lasciava passare
  il `catch` vuoto, che inghiotte di più. Provato con tre mutazioni.
- **US-079**: «un fallimento è visibile a schermo» era spuntato con un test su una funzione che
  restituisce una chiave. Prova la **decisione**, non la comparsa.

Corretto tutto in review, dentro i due branch, prima del merge. **La lezione per i mandati
futuri**: chiedere all'esecutore la riga «Test rotto» funziona — l'ha compilata in entrambi i
casi — ma la mutazione che scegli tu è quella che il tuo test già prende. Le mutazioni che
trovano i buchi le sceglie chi rivede.

**I 17 avvisi rimasti non sono rumore.** US-030 ha fatto la pulizia di massa il 2026-08-10 — da 55 a 17 — con `dart fix` limitato alle regole che non possono cambiare comportamento, piu gli undici `print` e i doppi trattini bassi. **Cio che resta e stato lasciato di proposito**: sei typedef dai provider scritti come funzione, tre `BuildContext` usati dopo un `await` che sono difetti potenziali veri, due confronti con null, due blocchi di codice morto, e **tre variabili «non usate» che sono intenzioni non implementate** — l'ora che il dialogo di fine allenamento butta, «Azzera» che compare a cronometro su zero, un `_isLoading` scritto e mai letto. E **US-102**, e quelle tre non si cancellano: si implementano o si dichiarano.

**Un calo va spiegato quanto un aumento**, e si spiega solo confrontando l'elenco con quello di `main`: in US-047 veniva da un rifacimento fuori mandato, in US-066 e US-008 dal codice che la storia riscriveva davvero.

### Dove è arrivata la grafica

Dopo **US-022** (dashboard, calendario, lista allenamenti), **US-026** (le stesse in italiano)
e **US-065** (libreria ridisegnata come nel mockup), le schermate principali hanno il design
system: nessun colore letterale, nessuna misura scritta a mano, e un **test sul sorgente** che
impedisce che tornino.

Restano fuori: le schermate secondarie (**US-023**, bloccata da US-037 e US-038) e cinque
schermate di **EP-014**.

⚠️ **La sessione attiva è rimasta in mezzo**: ha 21 valori scritti a mano e **non è coperta
da nessuna storia** — US-022 faceva le principali, US-023 le secondarie. È la schermata più
usata dell'app. Aspetta una decisione: storia nuova o allargamento di US-023.

---

## 2. Ambiente: quello che non funziona come ti aspetti

Queste cose costano mezz'ora se le scopri da solo.

### Flutter non è nel PATH

```
C:\Users\s.ferrero\Flutter\bin
```

Va anteposto al PATH in ogni comando PowerShell:

```powershell
$env:PATH = "C:\Users\s.ferrero\Flutter\bin;" + $env:PATH
```

Flutter 3.38.7, Dart 3.10.7.

### Piattaforme

| Target | Stato |
|---|---|
| **Android** | ✅ L'unico attivo |
| Web | ❌ Isar genera interi a 64 bit non rappresentabili in JavaScript. Accantonato in **EP-008** |
| Windows desktop | ❌ Visual Studio non installato |

### Dispositivi

- **Telefono**: Samsung S26 Ultra, `RFGL10YZ5RX`, Android 16. Si scollega spesso: verificare con `adb devices` prima di installare.
- **Emulatore**: `Medium_Phone_API_36.1`, avviabile da `%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe`
- **adb**: `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`

Il ciclo **non esegue l'app**: produce un APK che l'utente prova sul telefono.

```bash
flutter build apk --debug --target-platform android-arm64
adb -s RFGL10YZ5RX install -r build/app/outputs/flutter-apk/app-debug.apk
```

**Mai `flutter install`**: disinstalla l'app e cancella i dati, e l'utente si ritrova scollegato da Firebase. Con `adb install -r` l'aggiornamento conserva tutto — si verifica confrontando `firstInstallTime` e `lastUpdateTime` in `adb shell dumpsys package com.example.gymflow`: se il primo è cambiato, i dati sono stati cancellati.

### Trappole degli strumenti

| Trappola | Cosa succede | Come si evita |
|---|---|---|
| **Heredoc doppio in bash** | `python3 - <<'EOF'` con fallback su `python` apre una REPL interattiva che va in timeout | Scrivere lo script in un file e lanciarlo |
| **Percorso 8.3 dello scratchpad** | `C:\Users\SE4AB~1.FER\...` funziona in bash ma **non** in PowerShell | In PowerShell usare `C:\Users\s.ferrero\AppData\Local\Temp\...` |
| **`sleep` in bash** | Bloccato dall'ambiente | `run_in_background: true`, oppure un ciclo di attesa in PowerShell |
| **`git merge --squash`** | Non marca il branch come merged | Cancellare con `git branch -D`, non `-d` |
| **Redirect binario in PowerShell** | `adb exec-out screencap > file.png` corrompe il file con un BOM | `adb shell screencap -p /sdcard/x.png` poi `adb pull` |
| **Amend fuori dai comandi** | Un commit su `main` è stato amendato senza che nessuno lo chiedesse, creando divergenza con `origin` | Verificare `git rev-list --left-right --count main...origin/main` prima di pushare |
| **Screenshot dell'emulatore** | Può catturare un'app di sistema in primo piano | Verificare `adb shell dumpsys window \| grep mCurrentFocus` |
| **`flutter install` disinstalla** | Stampa «Uninstalling old version...» e **cancella i dati dell'app**: l'utente si ritrova scollegato da Firebase | Usare `adb install -r <apk>`: stessa firma di debug, dati conservati |
| **Percorsi Android in bash** | `adb shell screencap -p /sdcard/x.png` diventa `C:/…/Git/sdcard/x.png` | Anteporre `MSYS_NO_PATHCONV=1` |
| **Telefono bloccato** | Nessuna misura e nessuna navigazione via `adb` sono possibili, e un blocco protetto non va aggirato | Chiedere all'utente di sbloccare |
| **Percorsi troppo lunghi nei worktree** | `git worktree remove` fallisce con «Filename too long» se dentro c'è una `build/`: Windows non arriva in fondo ai percorsi di Gradle | `Remove-Item -LiteralPath "\\?\C:\...\GF0XX" -Recurse -Force` in PowerShell, poi `git worktree prune` |
| **`android/.kotlin` non è ignorato** | Costruire l'APK lascia `android/.kotlin/sessions/*.salive` non tracciato: `.gitignore` copre `android/.gradle` ma non `.kotlin`, e un `git add -A` lo committa | Aggiungere i file per nome, non con `-A`. La riga in `.gitignore` manca ancora |
| **`git add -A` in un worktree** | Raccoglie anche i registrant di plugin rigenerati da `pub get` e gli avanzi di Gradle | Elencare i file, oppure controllare `git show --stat` prima di proseguire |
| **`firebase deploy --only firestore:rules`** | Con la configurazione multi-database **non fa niente**, e stampa comunque «Deploy complete!». Il ruleset attivo resta quello vecchio, e sembra tutto a posto | Usare `--only firestore`, che compila e carica davvero. Verificare il ruleset attivo dall'API delle regole, non fidarsi dell'output |
| **Le regole Firestore hanno una scadenza** | Quelle generate alla creazione del database negano tutto dopo una data. In questo progetto era il 24 febbraio 2026, e per quasi sei mesi ogni lettura e scrittura e stata negata senza che nessuno lo collegasse ai sintomi | `firestore.rules` e ora nel repository. Se un dato non arriva, il primo controllo e `adb logcat \| grep PERMISSION_DENIED` |
| **`dart format` su questo repository** | I file **non** sono formattati con `dart format`: lanciarlo su un file riscrive centinaia di righe non toccate e rende la review impossibile | Rientrare a mano, o con `sed` su un intervallo di righe. Verificare il diff prima di committare |

---

## 3. Il processo, e il suo spirito

Le fasi sono in [`WORKFLOW.md`](WORKFLOW.md). Qui c'è **perché** sono così, che è ciò che serve per applicarle a casi nuovi.

**Il modello è cambiato il 2026-08-06: si lavora in parallelo.** Vedi [`DELEGA.md`](DELEGA.md). In sintesi: **chi ha il contesto pianifica (fase 1) e rivede (fase 5), chi è veloce implementa (fasi 2-4)**, e il merge resta una decisione dell'utente. La divisione non è teorica: viene da dove sono nati gli errori veri, che erano tutti **nel piano o nella verifica**, non nel codice.

**La review non è più un'autoverifica, e questo è un guadagno.** Chi rivede non ha scritto il codice, quindi legge ciò che c'è invece di ciò che intendeva scrivere. Vale la pena sapere quanto rende: nelle due storie recensite il 2026-08-07 (US-047 e US-050) la review ha trovato **tre difetti che avrebbero raggiunto l'utente**, tutti invisibili ai test perché i test provavano dei finti.

**Niente pull request.** `merge --squash` in `main`, push, allineamento di `dev`. Se chi implementa e chi rivede sono su macchine diverse il branch si pusha (lo dice `DELEGA.md`); nel lavoro locale resta locale e si cancella dopo il merge.

**Un worktree per storia.** `git worktree add ../GF0XX feature/US-0XX-slug`. Serve perché la cartella principale contiene spesso lavoro non committato di qualcun altro, e `flutter analyze` misurato su un albero sporco non misura niente.

**`dev` è uno specchio di `main`**, non un branch di integrazione. Dopo ogni merge va riportato in fast-forward. Se il fast-forward fallisce, fermarsi: significa che qualcuno ha committato su `dev`.

**I commit non attribuiscono nulla ad assistenti AI.** Nessun trailer `Co-Authored-By`, nessuna firma. In italiano, con il codice storia in testa.

### Il livello di rigore atteso

Questo è il punto che si perde più facilmente cambiando sessione. Esempi concreti di cosa ha significato "verificato" nelle storie fatte:

- **US-040**: il fix della build release è stato provato **disattivandolo** e ricostruendo da `flutter clean`, per dimostrare che era il fix a funzionare e non il clean. Un fix di build che funziona per motivi diversi da quelli creduti è peggio di nessun fix.
- **US-029**: il gate CI è stato verificato **introducendo un errore di sintassi di proposito** e controllando l'exit code, poi rimuovendolo. Non dedotto: provato.
- **US-034**: i contrasti WCAG sono stati **misurati** prima di scrivere il tema, e sono diventati 35 test che impediscono la regressione.
- **US-041**: i test hanno trovato che `endsWith('youtube.com')` accetta `notyoutube.com`. Il bug non era ipotetico.
- **US-014**: il criterio sulla memoria non era misurabile con gli strumenti disponibili. È stato **dichiarato come limite** nella review, con la prova strutturale che era possibile fornire, invece di essere spuntato senza verifica.
- **US-047**: prima di dichiarare «il sensore di battito non è distinguibile da Dart» è stato **letto il sorgente del pacchetto** `health` 13.3.0, dove `isDataTypeAvailable` si rivela una capacità di piattaforma e non di dispositivo. Un limite dichiarato senza averlo verificato è un alibi.

**La regola che ne deriva**: quando un criterio non è verificabile, si dichiara. Non si spunta e non si nasconde. Ogni review fatta ha una sezione sui limiti, ed è quella che rende il resto credibile.

### Dove nascono i difetti, in ordine di frequenza misurata

Serve per sapere dove guardare per primi in una review. Ogni voce è successa davvero.

1. **Valori del mockup copiati invece che convertiti.** ⚠️ **La forma piu letterale l'ha portata US-062**: cinque `fontSize: 8.5`, che e la riga `.exr-meta { font-size: 8.5px }` del CSS. E la lezione dentro la lezione: la guardia ne ha visti tre su undici, perche il piano chiedeva di aggiungere i **file nuovi** alla lista sorvegliata e non era stato fatto. Un test che sorveglia solo i file vecchi non sorveglia niente. `dp = px × 1,36` per i mockup 01 e 02, `× 1,20` per il 03. Successo in US-073 (raggio della riga: 16 invece di 22), in US-047 (tratto della sparkline: 2 invece di 2,7) e in US-050 (raggio e bordo della card dei record). **Tre storie su tre** che toccavano il mockup.
2. **Test che certificano meno di quanto dica il loro nome.** In US-073 un test si chiamava «il raggio segue cornerMd» e attestava l'errore. In US-047 il test «mostra il prompt» non cercava il prompt, e quello su `autoDispose` verificava solo che non si sollevassero eccezioni.
3. **Test che provano i pezzi e non il cablaggio fra loro.** In **US-093** il cronometro non si muoveva da un giorno: le viste prendevano il notifier con `ref.read`, che non crea iscrizioni, e non venivano mai ricostruite. I test di US-075 provavano il **notifier** — corretto — e che la schermata **si aprisse senza eccezioni**. Entrambi verdi, entrambi ciechi: **nessuno guardava cosa viene disegnato.** Quando una schermata e provata solo con asserzioni sullo stato, il difetto vive nel mezzo.
4. **Test che provano il finto invece del codice.** In US-047 il caso «senza sensore» passava perché il servizio finto sostituiva il metodo; nel codice vero quello stato era **irraggiungibile**. In US-050 il record si provava passando il valore al widget, scavalcando il provider che nell'app non funzionava.
5. **Letterali numerici al posto dei token**, anche in file nuovi. Se un token ha il valore sbagliato **si cambia il token**, non lo si aggira.
6. **Troncamenti nei calcoli.** In US-049 il volume faceva `toInt()` a ogni serie e perdeva i mezzi chili, che con il passo da 2,5 kg sono la norma. Nessun test lo prendeva perché usavano tutti pesi interi.
7. **Criteri spuntati che richiedono un dispositivo**, o che l'implementazione non soddisfa. In US-050 il criterio sulle ripetizioni era spuntato e il codice confronta solo il carico.

E due rilievi che si sono rivelati **sbagliati**, per ricordare che si verifica prima di segnalare: «usa `DateFormat` per i mesi» (il progetto non chiama mai `initializeDateFormatting`, l'app sarebbe crollata) e «le sagome non sono outline» (per 5 icone su 7 la variante `_outlined` non esiste in Flutter).

---

## 4. Decisioni prese, e perché

Queste sono state prese in conversazione con l'utente. Non si deducono dal codice.

### Direzione visiva: palette Indigo

Scelta dall'utente con riferimenti visivi (immagini Pinterest di app fitness e commerce).

| Ruolo | Colore | Significato |
|---|---|---|
| Sfondo app | `#221E3A` | |
| Superfici | `#312C51` | Le card |
| Superfici sollevate | `#48426D` | Card dentro card |
| **Azione** | `#F0C38E` ambra | **Un solo significato: cosa fare adesso** |
| **Dati vitali** | `#F1AA9B` salmone | Battito, sforzo. Mai per le azioni |

**L'app è scura per impostazione predefinita.** La separazione ambra/salmone è deliberata: se l'ambra compare su qualcosa che non è un'azione, l'occhio impara a ignorarlo.

La palette **supera WCAG AA su ogni coppia di testo**, quattro in AAA. È verificato da `test/contrast_test.dart` e ha di fatto risolto US-028.

### Material 3 Expressive: non esiste in Flutter

Verificato sull'issue ufficiale: Flutter **non lo sviluppa** e non accetta contributi sul tema. Del set esistono nativamente solo `DynamicSchemeVariant.expressive`, `Durations` ed `Easing`.

Decisione: **approccio ibrido per categoria**, documentato in [`adr/001-material-3-expressive.md`](adr/001-material-3-expressive.md) con i dati di pub.dev che l'hanno determinata. In sintesi: `motor` per il motion a molla (238 like, 77k download), tutto il resto interno, perché la famiglia `m3e_*` è `0.x` e `m3e_buttons` richiede un SDK superiore a quello del progetto.

**Tutti i token passano da `ExpressiveTokens`**, letta con `context.expressive`. I widget non sanno da dove viene un token: è ciò che rende la migrazione futura un lavoro su un file solo.

### Contenuti degli esercizi: misto

Foto curate dal team, caricabili dall'utente, con **miniatura YouTube come terzo anello** e segnaposto generato come ultimo.

### Timer fuori dall'app

Via **Live Updates di Android 16** (`Notification.ProgressStyle`), che One UI 8 porta nella Now Bar. Verificato da fonti Samsung: **nessuna API proprietaria necessaria**. Richiede però codice nativo Kotlin: US-053 e US-054 sono **le uniche due storie del backlog che escono da Dart**.

### Verifica tramite APK

Il ciclo non esegue l'app su emulatore. Produce un APK, l'utente prova sul telefono. I criteri che richiedono interazione vanno marcati **"da confermare sull'APK"**, mai spuntati.

---

## 5. Il materiale ricevuto, e i suoi limiti

`SchedePalestra.md` nella radice del repository contiene 43 esercizi e 4 schede reali.

### Estratto e utilizzabile

`assets/data/exercises_seed.json` — 43 esercizi, 12 gruppi muscolari normalizzati. Lo legge l'app: **US-045** l'ha reso importabile e **US-072** l'ha reso automatico.

### Stato dei video: 15 su 43

Il materiale è arrivato in due giri. Il primo conteneva **solo ricerche** YouTube; il secondo **43 link a video, ma erano 7 video distinti riusati per categoria** — un video di panca piana assegnato a tutti i curl, uno di squat ai polpacci, uno di spinte al plank.

Verificati tutti con l'API oEmbed: esistono e sono di canali seri, ma **importarli tutti sarebbe stato peggio della ricerca**. Chi apre "come si fa il plank" e vede la panca piana smette di fidarsi; una ricerca lo porta comunque dove voleva andare.

**Regola applicata**: un video si assegna solo se il titolo corrisponde all'esercizio. Risultato:

| | N |
|---|---|
| Con video verificato (e quindi con miniatura) | **15** |
| Con sola ricerca (mostrano il segnaposto) | 28 |

**I 43 esercizi non richiedono più un gesto dell'utente.** US-045 li rendeva importabili da Impostazioni → «Carica Dati Default»; **US-072 li fa comparire da soli**, perché le regole Firestore negano al client la scrittura sulla collezione `exercises` e l'import scriveva dove non poteva. La libreria curata viaggia come asset e si fonde in lettura con gli esercizi dell'utente. **Gli otto esercizi inglesi caricati in passato restano in Firestore** e vanno decisi a parte.

I 15 sono in `assets/data/exercises_seed.json`, ognuno con un campo `videoNote` che riporta il titolo reale. Ogni identificativo è stato verificato esistente.

**Limite dichiarato**: la pertinenza è valutata dal *titolo*, non guardando i video.

**I 28 rimanenti** si completano con ricerche su `youtube.com` per nome dell'esercizio, verificando l'ID con:

```bash
curl -s "https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=ID&format=json"
```

Un `200` con un titolo pertinente basta per assegnarlo. **Non serve modificare codice**: il campo `videoUrl` popolato produce la miniatura automaticamente.

### ⚠️ Nota storica: il primo giro di URL

**43 su 43 sono ricerche YouTube** (`youtube.com/results?search_query=`). Conseguenza: la miniatura si ricava dall'identificativo del video, e una ricerca non ne ha, quindi **il terzo anello della catena di ripiego non produce nulla** per la libreria curata.

Gestito con il campo `videoSearchQuery`: l'app apre la ricerca, e `hasSpecificVideo` permette all'interfaccia di dire la verità invece di promettere un video che non c'è. **Sostituire le ricerche con video scelti è incrementale e non richiede modifiche al codice.**

### ⚠️ Le schede non sono importabili con il modello attuale

I formati reali dell'utente chiedono più di quanto il modello sappia esprimere:

| Formato | Significato |
|---|---|
| `4x10/6` | 4 serie, ripetizioni da 10 a 6 |
| `2x6 + 2x12` | Due blocchi diversi |
| `4x(15-12-10-8)` con pesi `45-50-55-60` | Piramide con carichi |
| `1x10 + 1x10 + Max + Max` | Serie a cedimento |
| `3x12 (4 iso 3" + 4 negativa 4" + 4)` | Tecnica speciale |
| `Superserie: Crunch + Crunch inversi` | Due esercizi accoppiati |
| `10 kg per parte` | Manubri, carico per lato |
| Recuperi `90s`, `1'`, `1:30'` | Formati diversi |

**Non è stato inventato un modello**: produrrebbe qualcosa che non regge le schede reali. Serve una decisione dell'utente — vedi domande aperte.

---

## 6. Domande aperte che richiedono l'utente

Nessuna di queste si può decidere da soli.

1. **Quanto strutturare il modello delle serie?** Un modello che copre tutti i formati sopra è complesso; uno che copre l'80% e conserva il resto come testo è più semplice ma non permette di calcolare i volumi correttamente. **Blocca l'importazione delle schede.**

2. **Chi scegli i 43 video?** Sostituire le ricerche con video specifici richiede di guardarli per giudicarne la qualità. Se lo fa un assistente, va detto che la selezione non è verificata visivamente.

3. **Colore personalizzato e contrasti.** I preset sono filtrati a valori che superano AA, ma se l'utente scegliesse un colore libero potrebbe violarli. Va deciso se limitare, calcolare una variante accessibile a runtime, o accettare il rischio.

4. **Impostazione per ridurre il movimento.** Material 3 Expressive spinge su animazioni pronunciate. Oggi si rispetta solo l'impostazione di sistema. Serve un controllo dedicato?

5. **Firma di produzione.** La release è firmata con la chiave di debug. Serve una chiave vera solo per distribuire sugli store.

6. **Il record tiene conto delle ripetizioni?** US-050 ha scelto la regola più semplice — è record il carico più alto sollevato per almeno una ripetizione — e ha dichiarato il resto come limite. Il criterio che chiedeva di considerare anche le ripetizioni **non è soddisfatto** ed è tracciato in **US-074**. Prima di implementare un massimale stimato va deciso se serve: il rischio è un numero corretto in palestra e illeggibile in un messaggio.

7. **Il sensore di battito non è distinguibile da Dart.** Verificato nel sorgente di `health` 13.3.0. Il criterio di US-047 va riformulato, oppure serve una storia per il controllo nativo — la stessa strada di US-053 e US-054.

---

## 7. Cosa fare adesso

**18 storie hanno tutte le dipendenze soddisfatte** (EP-008 esclusa). Le tre che contano:

| Storia | Perché adesso |
|---|---|
| **US-022** Design system alle schermate principali · 3pt | **È la storia che fa cambiare aspetto all'app.** Sblocca US-023 e quattro schermate di EP-014, e sistema i `Colors.grey[...]` ereditati dal fondo chiaro. Ha già un piano: [`planning/US-022.md`](planning/US-022.md). Dipendeva da US-073, che ora è chiusa |
| **US-065** Libreria esercizi ridisegnata · 3pt | Prima schermata di EP-014 eseguibile: segmentato Tutti / Miei / Recenti e chip per gruppo muscolare, tutto disegnato nel mockup 02 |
| **US-030** Azzerare gli avvisi · 3pt | 63 avvisi sono rumore che nasconde i problemi nuovi, e rendono il baseline l'unica difesa. **Sei** sono typedef deprecati nei provider generati da funzione: si tolgono riscrivendoli come notifier di classe |

Le altre eseguibili: US-008, US-013, US-026, US-028, US-031, US-035, US-036, US-052, US-055, US-059, US-068, US-074.

⚠️ **La tabella qui sopra è ferma al 2026-08-09 e va rifatta**: US-022, US-065, US-018, US-025,
US-079 sono chiuse, e US-066 è in `🔍 IN REVIEW` con tre criteri aperti. Prima di scegliere la
prossima storia, l'elenco vero si ricava dal backlog cercando `**Status:**`.

### Prove sul dispositivo ancora in sospeso

Nessuna di queste blocca il lavoro, ma ognuna è un criterio non spuntato in una storia chiusa.

| Cosa | Dove | Storia |
|---|---|---|
| L'ultimo esercizio della lista non finisce sotto il pannello delle metriche | dentro un allenamento, scorrere fino in fondo | US-047 |
| 55 fps durante lo scorrimento | idem. Sospetto: il velo sfocato del pannello si ricalcola al secondo per il cronometro | US-047 |
| La riga «+2,5 kg sul tuo massimo» compare davvero | serie con carico sopra il massimo, su un esercizio già fatto. **Nessun test copre questo percorso** | US-050 |
| La card dei record sotto lo scontrino | chiudere l'allenamento dopo aver battuto un massimo | US-050, US-049 |
| I 28 esercizi senza video hanno tutti lo stesso segnaposto, i 15 col video il pallino salmone | Menu → Esercizi | US-073 |
| L'overlay flottante del timer si trascina e si controlla | timer | US-007 |
| La build **release** si installa e si avvia | serve un APK release, non il debug | US-040 |
| 55 fps su 100 esercizi | menu → Design system → «100 esercizi» in build **profile**, poi `adb shell dumpsys gfxinfo com.example.gymflow` | US-043 |
| **Un esercizio creato compare in «Miei» e sopravvive alla chiusura dell'app** | Menu → Esercizi → «+», nome, Salva. **È il criterio che chiude US-079**, e il rapporto lo dichiarava funzionante per deduzione dalle regole: è il passaggio che ha ucciso US-045 | US-079 |
| La terza voce della barra apre la scheda curata, e il ritorno da «Nuova scheda» non lascia il vuoto | barra in basso → Allenamenti, aprire una scheda, tornare, cambiare voce e tornare | US-025 |
| L'eliminazione di una scheda funziona ancora, e in errore mostra **un** solo toast | barra in basso → Allenamenti → ⋮ → Elimina | US-025 |
| Le intestazioni delle colonne si leggono, e il titolo con `titleEmphasized` non e troppo grande | dentro un allenamento | US-082 |
| **Il cronometro scorre e il conto alla rovescia scende** | Menu → Cronometro, tocca Avvia | US-093 |
| Il calendario funziona ancora: eventi visibili, allenamento programmato, cancellazione con lo scorrimento | e la schermata col diff piu grosso di US-008 e **nessun test la monta** | US-008 |
| Il saluto della dashboard mostra il nome dal primo istante, non «Atleta» | apri l'app | US-008 |
| L'assestamento a molla sul cambio voce si vede, non risulta lento, e non costa piu di 16 ms | tocca le tre voci della barra, avanti e indietro | US-036 |
| Nel trasloco di US-095 non si e rotto niente: quattro tessere coi numeri giusti, due grafici che disegnano, storico che elenca | menu → Statistiche, o l'icona in alto sulla home | US-095 |
| ⭐ **La home nuova si legge, e senza l'anello non risulta povera.** Se lo fosse, la risposta non e rimettere i numeri finti: e sbloccare US-059 e fare US-063 | apri l'app | US-062 |
| ⭐ **L'evento programmato compare nel calendario.** Se ancora non compare, il difetto e nella **scrittura** e non nella lettura, e va cercato altrove | Calendario → «+», oppure «programma allenamento» | US-098 |
| Creare un esercizio non fa piu schermata rossa. **E se ne fa una che dice `_dependents.isEmpty`, serve lo stack**: `adb logcat -c`, riprodurre, `adb logcat -d \| grep -A40 dependents` | Menu → Esercizi → «+» | US-097, US-081 |

### Decisioni di prodotto lasciate aperte dalle storie chiuse

- **US-043**: nella scheda di allenamento il numero d'ordine dell'esercizio è stato sostituito dalla miniatura. Va deciso se rimetterlo come prefisso del titolo.
- **US-047**: manca un token per la dimensione delle icone, e due valori (`14`, `20`) sono scritti a mano nel pannello. Aggiungere `sizing.iconSm` / `iconMd` o accettarli.
- **US-050**: chi batte il record alla prima serie e poi imposta un carico intermedio si vede segnalare un secondo record contro il massimo vecchio, perché i massimi vengono dalle sessioni **salvate**. Errore o incoraggiamento?
- **US-050**: `test/unit/` è stata creata per un file solo, mentre tutti gli altri test stanno in `test/`. Convenzione nuova o file da spostare?

### ⚠️ Debito visibile introdotto da US-034

L'app è passata da chiara a scura, ma le schermate contengono ancora **decine di `Colors.grey[...]` e `Colors.white` scritti a mano**, ereditati dal fondo chiaro. **Su indigo alcuni testi secondari appaiono sbiaditi.**

Era previsto e dichiarato nella review di US-034. Lo sistemano **US-022** e **US-023**, sostituendoli con i ruoli del `ColorScheme`. Se l'utente segnala schermate sbiadite, è questo: non un difetto nuovo.

Il **catalogo del design system** (menu → Design system, solo in debug) mostra la palette applicata correttamente ed è il punto migliore per giudicare la direzione visiva.

---

## 8. Riferimenti visivi

I mockup approvati dal prodotto sono **nel repository**, in [`design/`](design/): tre pagine HTML autonome, apribili con un doppio clic.

| File | Contenuto |
|---|---|
| `01-direzione-visiva.html` | Sei schermate sulla palette Indigo, catena delle immagini, contrasti |
| `02-schermate-app.html` | Nove schermate: libreria, timer, calendario, obiettivi, traguardi, peso, impostazioni |
| `03-timer-e-movimento.html` | **Timer funzionante**, micro-interazioni, Now Bar |

Ogni schermata ha una didascalia che spiega **la decisione** che incorpora: il layout si deduce guardando, il motivo no. Vedi [`design/README.md`](design/README.md) per la mappa fra mockup e storie.

**Non sono specifiche al pixel.** Dove divergono dal design system vince il design system: i token sono la fonte di verità, i mockup l'intenzione.

Esistono anche come artifact su claude.ai, ma quei link sono privati e possono scadere: la copia autorevole è quella nel repository.

---

## 9. Convenzioni di scrittura

Valgono per codice, documentazione e commit.

- **Italiano** per commenti, documentazione, commit e artefatti di processo. Il codice resta in inglese.
- **I commenti spiegano il perché**, non il cosa. Un commento che ripete la riga sotto è rumore.
- **Nessun riferimento ad AI** nei commit o nel codice.
- **Le storie e i piani citano file e riga** quando parlano di codice esistente.
- **Le review dichiarano i limiti.** Una review senza sezione sui limiti è sospetta: significa che non si è guardato abbastanza.
- **Niente stringhe hardcoded nell'interfaccia**: tutto passa dalla localizzazione, con la chiave in EN e IT.
- **Niente colori letterali** fuori da `app_palette.dart`.
- **Niente valori numerici** per spaziature e raggi: vengono da `context.expressive`.

---

## 10. Verifica rapida dello stato

Da eseguire all'inizio di una sessione nuova, per capire dove si è:

```bash
git log --oneline -5
git rev-list --left-right --count origin/main...origin/dev
```

Il secondo comando deve dare `0	0`. Per lo stato del backlog, cercare `**Status:**` in `docs/BACKLOG.md`: le storie `✅ DONE` sono fatte, le `⬜ TODO` no, e una `🔵 IN PROGRESS` significa che qualcuno ha lasciato un lavoro a metà.

Per sapere quali storie sono eseguibili, servono le dipendenze: una storia è pronta quando **tutte** quelle nel suo campo `Depends on` sono `✅ DONE`.

**Controllare anche che non ci sia lavoro non committato**, e non solo che i branch siano allineati:

```bash
git status --porcelain
git worktree list
```

Il 2026-08-07 è servito **mezzo pomeriggio** per rimediare a due storie consegnate come un unico mucchio non committato nella cartella principale, senza un solo commit, mescolate fra loro e su un branch indietro rispetto a `main`. I due rapporti dichiaravano gli stessi identici numeri perché erano misurati sullo stesso albero. Da qui la regola del worktree per storia, e il motivo per cui il primo comando di una sessione non è `git log`.

---

_Documento di passaggio · GymFlow · aggiornato il 2026-08-07 · commit `cfb46cd`_
