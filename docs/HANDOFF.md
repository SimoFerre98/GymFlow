# GymFlow — passaggio di consegne

**Aggiornato:** 2026-09-13 · **Commit:** `c748169` su `main` (`dev` allineato in fast-forward,
entrambi pubblicati su `origin`). US-111 e US-087 sono entrambe mergiate. Dei sette difetti minori
segnalati durante la prima prova di US-111, tutti e sette sono sistemati nel codice. Una seconda
prova sullo stesso APK (prima che i sette fix fossero confermati uno per uno) ha segnalato **altri
cinque difetti**: quattro sistemati, uno (colore secondario ancora sbagliato in modalità chiara)
resta **non individuato** — vedi sezione 6, punto 2b.

**L'utente ha poi chiesto di proseguire in autonomia** (anche a telefono scollegato, aspettando i
limiti di sessione se esauriti) invece di fermarsi a ogni difetto: la sessione ha continuato a
rivedere sistematicamente il resto dell'app, non solo quanto segnalato, in tre passate successive.
Prima passata: **sei difetti concreti** in `active_session_screen.dart`, `calendar_screen.dart`,
`workout_summary_screen.dart` e `firestore_service.dart` — vedi sezione 6, punto 2c. Seconda
passata (sette schermate mai riviste finora): **altri cinque difetti**, il più grave dei quali
faceva risultare "raggiunti" obiettivi utente completamente scollegati dall'allenamento fatto — vedi
sezione 6, punto 2d. Terza passata (dodici schermate fra impostazioni, timer, autenticazione e
programmi): **altri dodici difetti**, tre dei quali potevano far perdere dati reali dell'utente
(riordino di un programma annullato salvando, data di una misura corporea spostata, account
registrato senza profilo e senza via d'uscita) — vedi sezione 6, punto 2e. **Nessuno dei
trentaquattro fix totali di oggi è stato ancora confermato sul telefono**: l'`adb` non ha rilevato
il device per gran parte di questa sessione — build, test e commit sono comunque proseguiti, ma la
prova reale resta da fare appena il telefono torna raggiungibile.

Questo file serve a chi riprende il lavoro **senza la cronologia della conversazione** — umano o
assistente AI, e su qualunque macchina: la sessione che ha scritto questa versione girava su una
macchina Linux personale, non più sul PC Windows citato nelle versioni precedenti di questo file,
**perso** nel frattempo (vedi sezione 1, ora chiusa). Contiene ciò che **non si deduce leggendo il
repository**: decisioni prese a voce, trappole dell'ambiente, il livello di rigore atteso.

## Cosa leggere, e cosa non leggere

| Leggi | Perché |
|---|---|
| **Questo file**, per intero | È il più corto che contenga tutto |
| [`../AGENTS.md`](../AGENTS.md) | Le regole che fanno fallire una consegna |
| [`WORKFLOW.md`](WORKFLOW.md) | Il ciclo in 8 fasi — **attualmente sospeso**, vedi sezione 2 |
| [`DESIGN-SPEC.md`](DESIGN-SPEC.md) | Riscritto il 2026-09-09 dal codice recuperato (`app_palette.dart`, `immersivo_tokens.dart`): oggi allineato, non più storico |

**`docs/design/` ha due file**: `06-inventario-app.html` (atlante fotografico di tutte le schermate,
scritto per l'audit del 2026-09-09 — vedi [[gymflow-audit-schermate]] in memoria) e
`GymFlow Immersivo Impostazioni.html` (estratto "Turno 3" di una conversazione Claude Design). I tre
mockup storici Material 3 Expressive/Indigo sono stati rimossi il 2026-09-09, direzione superata.
`docs/design/05-immersivo-toxic-forest.html` e `docs/adr/002-immersivo-toxic-forest.md` restano
**non recuperati** — citati nel codice ma mai committati, la ricerca nella conversazione Claude
Design ("Turno 3", turni 1-2 non ancora trovati) è **sospesa su richiesta esplicita dell'utente**,
non fallita: riprenderla solo se richiesto di nuovo.

**`BACKLOG.md` è 110 storie, 65 `✅ DONE`** (ricontare con `grep -c "^#### US-"` e
`grep -c "✅ DONE" docs/BACKLOG.md` — il numero di `DONE` cambia più spesso di quanto questo file
venga aggiornato, non fidarsene oltre l'ordine di grandezza). Si consulta cercando, non leggendo
tutto: `grep -n "^#### US-0XX" docs/BACKLOG.md`.

---

## 1. Il redesign "Immersivo" — recuperato, integrato, ora in cura ordinaria

**Riassunto per chi non ha la sezione storica**: tra il 14 e il 21 agosto 2026 è stato scritto, sul
PC Windows dell'utente (poi perso), un redesign visivo completo — **"Immersivo / Toxic Forest"**,
che sostituisce Material 3 Expressive e la palette Indigo (`DESIGN-SPEC.md`). Nessun commit era mai
arrivato su GitHub. Recuperato il 2026-09-09 per via forense dal Dart Kernel di un APK debug
installato sul telefono (109 file su 111 integrali, il dettaglio tecnico del metodo resta nel
commit `ff893a5` e in memoria [[gymflow-immersivo-toxic-forest]] se serve replicarlo altrove).

**Da allora, chiuso**:
- Branch `recovery/immersivo-toxic-forest` **mergiato in `main`/`dev`** con via libera esplicito.
- `DESIGN-SPEC.md` **riscritto** dal codice recuperato (`app_palette.dart`, `immersivo_tokens.dart`).
- **Audit completo delle 27 schermate** (`docs/AUDIT-SCHERMATE.md`, atlante fotografico in
  `docs/design/06-inventario-app.html`): il ciclo centrale (Home, esercizi, sessione, riepilogo,
  schede, statistiche, timer, calendario, aspetto, login) era già solido; 6 schermate periferiche
  sistemate allo stesso standard (`health_detail`, `program_creator`, `connect_friend`,
  `friend_detail`, `gym_settings`, `timer_settings`).
- **Traguardi/Obiettivi**: risolta la collisione di nome fra `GoalsScreen` e `gamification_screen.dart`
  (entrambe si chiamavano "Obiettivi" in italiano) e l'assenza di un ingresso permanente alla prima.
- **Palestra/Recupero completati** secondo il mockup "Turno 3": schermo sempre acceso durante la
  sessione (`wakelock_plus`), conto alla rovescia vocale (`flutter_tts`), statistiche
  sessioni/ore/anno per palestra. Il promemoria d'arrivo (geolocalizzazione in background) è stato
  **esplicitamente lasciato fuori** — non riprenderlo senza che l'utente lo richieda di nuovo.
- **Coerenza visiva verificata sul telefono vero** (non solo su `flutter test`): bottone indietro
  della libreria esercizi uniformato alle altre 16 schermate (incapsulava `BackPill` in un `AppBar`
  vero invece della stessa riga con titolo e filetto); interruttori squadrati (`ImmersivoSwitch`,
  `lib/src/ui/widgets/immersivo_switch.dart`) al posto di `Switch`/`SwitchListTile` di Material,
  strutturalmente tondi e non tematizzabili ad angoli vivi.
- **Build APK funzionante su questa macchina Linux** — vedi sezione 3, non più un problema aperto.
- **Cinque difetti segnalati dall'utente su creazione/modifica schede e Home, sistemati il
  2026-09-12** (commit `bfdb68b`..`522776a`, poi `1a60331` per la pulizia del repo):
  - Etichette illeggibili ("Se...", "Rip...", "P...") nella configurazione di serie/ripetizioni/peso
    di un esercizio — l'etichetta di Material dentro il campo era troppo stretta; spostata sopra il
    campo come in `_buildNameField`, stesso file.
  - Riordinare i giorni di un programma trascinandoli poteva far crashare l'app: la logica operava
    su `workoutIds` (la sorgente Firestore) usando indici presi da `programWorkouts` (la lista
    mostrata, che include "orfani" non in `workoutIds`) — due liste di lunghezza diversa, indici non
    intercambiabili. **Diagnosticato per lettura del codice, non riprodotto dal vivo** — coordinate
    di tocco sbagliate durante la prova hanno impedito una riproduzione affidabile.
  - La riga durata/serie/volume nell'editor di un giorno usciva dallo schermo con numeri di volume
    grandi — le tre colonne non erano vincolate (`Expanded`).
  - **Non c'era modo di eliminare un giorno da un programma**, solo riordinarlo: aggiunto swipe con
    conferma, stesso schema già in uso per gli esercizi e per gli eventi del calendario
    (`Dismissible` + `confirmDismiss`).
  - **La Home proponeva sempre lo stesso allenamento** (il passo successivo del ciclo del programma),
    ignorando la programmazione del giorno. Nuova funzione pura testata `selectHeroWorkout` in
    `dashboard_screen.dart`: sessione già avviata > allenamento programmato per oggi non ancora fatto
    > ciclo del programma > primo modello disponibile. Il badge ora distingue "OGGI" (c'è una
    programmazione o una ripresa) da "SUGGERITO" (fallback sul ciclo).
  - Bottone indietro della libreria esercizi che andava in overflow con `backLabel` lunghi
    (`Flexible` invece di figlio non vincolato in un `Row`).

**Ancora aperto, genuinamente**:
1. **Ritrovare `ADR-002`/`docs/design/05-immersivo-toxic-forest.html`** — sospeso su richiesta
   dell'utente, non fallito. Vedi il box in cima al file.
2. **Decisione di prodotto, non tecnica**: la `_RecordBar` in `workout_summary_screen.dart` non
   mostra più le ripetizioni della serie né la data del massimale precedente — voluto o da
   recuperare? Segnalato da `docs/AUDIT-SCHERMATE.md`, mai deciso con l'utente.
3. **Decisione di prodotto, non tecnica**: il filtro "Recenti" nella libreria esercizi
   (`ExerciseSegmentFilter.recent`) è uno stub che restituisce sempre lista vuota — implementarlo o
   toglierlo dal segmentato?
4. **La nuova logica della Home (`selectHeroWorkout`) non è stata ancora vista dall'utente
   sul telefono** — coperta da 6 test unitari e installata il 2026-09-12, ma non confermata dal
   vivo. Verificarla appena possibile: badge "OGGI" quando c'è una programmazione per oggi o una
   sessione da riprendere, "SUGGERITO" quando arriva dal ciclo del programma.

---

## 2. ⚠️ Il processo formale è sospeso

**`WORKFLOW.md` non è stato seguito per gran parte del lavoro recente**, non solo per il redesign
Immersivo. La cronologia di agosto mostra commit `US-FIX:`/`US-STYLE:` diretti su `main`/`dev` senza
branch di storia, e almeno tre `Merge branch '...' into dev` — un vero merge, non lo squash che il
processo prescrive, e `dev` non dovrebbe mai ricevere commit propri. Non è un incidente isolato: è
una scelta esplicita dell'utente più volte, quando il ritmo ha contato più del rispetto delle fasi.

**Conseguenza pratica**: non fidarsi di `BACKLOG.md`/`docs/planning/` come specchio fedele di tutto
il lavoro reale fatto sul codice. Verificare sempre lo stato vero — `git log`, l'app installata —
prima di pianificare.

**Regola nuova, esplicita, dal 2026-09-08**: qualunque modifica rilevante va **committata e pushata
il prima possibile**, anche fuori dal ciclo formale se necessario. Non deve mai restare solo su un
disco locale. È la lezione diretta della sezione 1: un push su un branch anche non mergiato avrebbe
evitato l'intero recupero forense.

---

## 3. Ambiente: **non più il PC Windows**

Le versioni precedenti di questo file descrivevano un ambiente Windows (`C:\Users\s.ferrero\...`,
`%LOCALAPPDATA%\Android\Sdk`) che **non esiste più** — quel PC è perso (sezione 1). La sessione che
scrive questa versione girava su una macchina **Linux personale** dell'utente, diversa anche dal
laptop di lavoro. Se in futuro si torna a lavorare da un PC Windows o da un'altra macchina, questa
sezione va riscritta da capo: non ereditarla.

**Su questa macchina Linux (Ubuntu 26.04), impostato da zero il 2026-09-09:**

| Strumento | Stato |
|---|---|
| Flutter | Via **snap** (`/snap/bin/flutter`, 3.47.2 stable) — non nel PATH di sistema per gli script, ma `flutter`/`dart` funzionano da shell interattiva |
| Android SDK | **Funzionante**: SDK utente in `/home/sta0135/Android/Sdk` (non più `/usr/lib/android-sdk`, root-owned), `sdk.dir` in `android/local.properties` (gitignored) punta lì. `cmdline-tools`, `platform-tools`, `build-tools`, `platforms`, `ndk` installati, licenze accettate (`sdkmanager --licenses`). `flutter build apk --debug` **verificato funzionante** su questa macchina |
| `adb` | Installato via `apt`. Telefono riconosciuto: `RFGL10YZ5RX`, Samsung S26 Ultra (`SM_S948B`) |
| `gh` (GitHub CLI) | Autenticato come `SimoFerre98`; `git push`/`pull` funzionano tramite le sue credenziali |

**Trappole specifiche della build APK, trovate il 2026-09-10:**
- L'URL corretto per scaricare i `cmdline-tools` è `https://dl.google.com/android/repository/...`
  — **non** `/android/repo/...` (percorso plausibile ma sbagliato: sembra un blocco di rete, non lo
  è). Verificare su developer.android.com se il link cambia ancora.
- AGP 8+ rifiuta `isar_flutter_libs 3.1.0+1` con "Namespace not specified" (dichiarava il pacchetto
  solo nel proprio `AndroidManifest.xml`, come si usava prima di AGP8). Risolto in
  `android/build.gradle.kts` con un blocco generico che eredita il namespace da lì per qualunque
  plugin ne sia privo — non nominato a `isar_flutter_libs` in particolare, resta valido anche se
  cambia il plugin che ha il problema.
- Una build fatta con una keystore di debug locale nuova **non è compatibile** con un APK firmato
  da un'altra macchina (qui: il PC Windows perso): `adb install -r` fallisce con
  `INSTALL_FAILED_UPDATE_INCOMPATIBLE`. Serve disinstallare e reinstallare (perdita dati locali,
  Firestore sopravvive) **solo la prima volta**: le build successive da questa stessa macchina
  condividono la stessa keystore di debug, quindi `adb install -r` normale.

**`sudo` non può mai essere lanciato dall'assistente**: questo ambiente non ha un terminale
interattivo a cui `sudo` possa chiedere la password, a prescindere dai permessi concessi. Per comandi
che richiedono `sudo` con una certa frequenza (oggi solo `apt`), l'utente ha configurato
`/etc/sudoers.d/claude-apt` con `NOPASSWD` **solo** per `/usr/bin/apt` e `/usr/bin/apt-get` — non per
altro, deliberatamente ristretto.

**Alcune azioni Bash richiedono un permesso esplicito** oltre a quanto l'assistente può fare di
default: il classificatore di permessi blocca `git push origin --delete`, `git checkout --` e
comandi che sovrascrivono file in blocco (`rsync`/`cp -r` su `lib/`), anche quando l'operazione è
sicura (branch non-`main`, tutto tracciato da git). Si sbloccano aggiungendo una riga mirata a
`.claude/settings.local.json` (non versionato) — vedi quello che c'è già lì per il formato. Non
allargare questi permessi oltre il comando esatto che serve in quel momento.

**Trappole indipendenti dalla macchina, confermate ancora valide:**

| Trappola | Come si evita |
|---|---|
| **`dart run build_runner build` dopo aver toccato un solo file** | Rigenera **tutti** i `.g.dart`. La versione di `riverpod_generator` installata può differire da quella che ha scritto l'ultimo commit e produrre nomi diversi per lo stesso provider (visto di nuovo il 2026-09-09 su `HealthServiceProvider` → `healthServiceProviderProvider`, la stessa trappola di US-102). Dopo la rigenerazione, `git status` su **tutta** `providers/` |
| **`dart format` su questo repository** | Non lanciarlo: riscriverebbe centinaia di righe non toccate |
| **`git merge --squash`** | Non marca il branch come merged: si cancella con `git branch -D` |
| **Il buffer di `logcat` gira** | `adb logcat -c` prima di riprodurre un difetto |
| **Non fidarsi del rapporto di un sub-agente** | Rifare `flutter analyze`/`flutter test` in prima persona prima di accettare un esito — ha già trovato discrepanze in passato (sezione 4) |

```bash
adb devices -l                                       # verifica il telefono prima di installare
flutter build apk --debug --target-platform android-arm64
adb -s RFGL10YZ5RX install -r build/app/outputs/flutter-apk/app-debug.apk
```

**Mai `flutter install`**: disinstalla l'app e cancella i dati. Con `adb install -r` si conserva
tutto — si verifica che `firstInstallTime` in `adb shell dumpsys package com.example.gymflow`
**non** sia cambiato.

---

## 4. Il livello di rigore atteso

**Quando un criterio non è verificabile, si dichiara. Non si spunta.**

**Non fidarsi del rapporto di consegna, nemmeno di un sub-agente diligente.** Il 2026-09-09 l'agente
che ha aggiornato i test ha consegnato un rapporto dettagliato e onesto — verificato comunque di
persona con `flutter analyze`/`flutter test` prima di accettarlo, per prassi, e confermato identico.
Il 2026-08-10: una consegna dichiarava «nessun nuovo avviso» avendone introdotti tre, e «456 verdi»
con la suite rossa.

**Confrontare l'ELENCO degli avvisi con `main`, non il totale.**

**Rompere il codice di proposito e controllare che un test diventi rosso.**

### Dove nascono i difetti, in ordine di frequenza misurata

1. **Valori del mockup copiati invece che convertiti.** `dp = px × 1,36` per i mockup storici
   (ormai rimossi), `× 1,20` per il terzo. Se e quando si ritrova `05-immersivo-toxic-forest.html`,
   verificare il suo fattore di conversione da zero: non è detto sia lo stesso.
2. **Test che certificano meno del loro nome.**
3. **Test che provano i pezzi e non il cablaggio fra loro.**
4. **Criteri spuntati e non veri.**
5. **Dati inventati mostrati come veri.**
6. **Riscritture che cancellano senza dichiararlo.** Il caso più recente: la card del record
   personale nel redesign Immersivo (sezione 1) — dichiarato nel commit, non ancora deciso con
   l'utente se è voluto.
7. **Troncamenti nei calcoli.**
8. **Codice recuperato per via forense con rumore binario in coda non ripulito.** Nuovo il
   2026-09-09: l'estrazione automatica dal Dart Kernel a volte lascia, dopo la graffa di chiusura
   vera di un file, alcune righe di byte non stampabili che sembrano quasi codice. Si individua
   contando parentesi/graffe fino a ogni riga candidata: il bilancio torna a zero esattamente alla
   riga vera, mai prima.

---

## 5. Decisioni prese, che non si deducono dal codice

### Direzione visiva attuale: "Immersivo / Toxic Forest" (sostituisce Indigo/Material 3 Expressive)

| Ruolo | Valore | Significato |
|---|---|---|
| Sfondo (Toxic Forest) | `AppPalette.bgDeep` `#0B2027` | |
| Superficie card | `AppPalette.surfaceCard` `#143540` | |
| **Azione** | `AppPalette.accent` (giallo neon `#EEF800` in Toxic Forest, uno dei 4 stili) | **Un solo significato: cosa fare adesso** — regola invariata dalla direzione Indigo, solo generalizzata |
| **Dati vitali** | `AppPalette.accentSecondary` (verde bosco in Toxic Forest) | Mai per le azioni. Non cambia con l'`accentPreset` scelto dall'utente: se cambiasse anche questo, la distinzione azione↔dato sparirebbe |

**4 palette intere** (`AppThemeStyle`: `classico`, `digitalPulse`, `toxicForest` — **default**,
`deepSeaNeon`), ciascuna con **6 preset di colore per l'accento** (`accentPresets`), scelti
dall'utente in Impostazioni → Aspetto con anteprima live. Lo switcher di stile a schede della
versione precedente (US-STYLE) è sparito da lì.

**Estetica: angoli vivi, non arrotondati.** `ImmersivoShape` ha quasi tutti i raggi a 0: i confini si
disegnano con un filetto (bordo sottile), non con l'elevazione. `radiusFull` resta solo per elementi
genuinamente circolari (avatar). **Bagliori (`glow`)** — liste di `BoxShadow` colorate — al posto
delle ombre neutre. **Font Anton** (Google Fonts), condensato e maiuscolo, per titoli e numeri: non
più la scala Material 3 "emphasized". Vedi `lib/src/core/theme/immersivo_tokens.dart` e
`DESIGN-SPEC.md` (riscritto, allineato).

### Trainer e schede: l'ordine deciso resta valido

**EP-016 «Schede come le scrive un allenatore» viene prima di EP-017 «Trainer e clienti».** Nessuna
informazione nuova la mette in discussione — verificare comunque lo stato reale delle storie
US-083/086/087 nel backlog prima di assumerlo ancora vero.

### Verifica tramite APK

Il ciclo **non esegue l'app**: produce un APK, l'utente prova sul telefono. Su questa macchina la
build funziona (sezione 3): `flutter build apk --debug`, poi `adb install -r` sul percorso generato.
Per modifiche solo visive, l'utente ha chiesto di vederle davvero installate prima di considerarle
concluse — non fermarsi a `flutter test` verde.

---

## 6. Cosa fare adesso

Le priorità, in ordine, così come emerse dalla sessione che ha scritto questo file:

1. ✅ **US-111 e US-087 sono entrambe `✅ DONE`, mergiate in `main` il 2026-09-13.** US-111 (cache
   locale Isar) confermata sul telefono dall'utente. US-087 (invito trainer↔cliente/amico) chiudeva
   *insieme* i punti 3 e 8 della sezione 8 — regole già pubblicate su `gymflow-d5d09` e verificate
   dall'API. Piano e review di entrambe in `docs/planning/`. US-089 e US-092 (EP-017) sono ora
   eseguibili.
2. **Provando US-111 sul telefono, l'utente ha segnalato 7 difetti minori (2026-09-13), estranei a
   quella storia — sistemati tutti e sette in due sessioni di correzioni rapide (commit
   `6614c8c`..`aaa7cf5` per i primi sei, poi `6a41d36`), diretti su `main`, stesso schema dei cinque
   difetti del 2026-09-12**:
   - ✅ Colore secondario del tema chiaro (`app_theme.dart` usava un tono da scuro)
   - ✅ Selettore data dell'abbonamento che non si apriva più (initialDate nel passato violava
     l'assert di `showDatePicker` con un abbonamento già scaduto)
   - ✅ Eliminare un programma lasciava le sue schede orfane (`deleteProgram` ora le cancella insieme)
   - ✅ Nessun modo di correggere/cancellare una misura corporea già salvata (aggiunto tocca-per-
     modificare e swipe-per-cancellare)
   - ✅ Banner scorrevole a filo col titolo in Schede (spaziatura mancante)
   - ✅ Titolo lungo nella Home diventava un blocco enorme (dimensione ora dipende dalla lunghezza)
   - ✅ **Foto profilo non caricava offline** — sistemato (commit `6a41d36`). `cached_network_image`
     **non era una dipendenza nuova**: era già in `pubspec.yaml:72`, aggiunta in precedenza per le
     immagini degli esercizi (`exercise_image.dart`), solo mai usata per la foto profilo — la nota
     precedente in questo file era disallineata su questo punto. Approvazione comunque chiesta
     esplicitamente all'utente prima di procedere (regola "chiedi sempre prima di aggiungere una
     dipendenza"), anche se di fatto non serviva aggiungerne una. Modificati i due punti reali che
     mostrano la foto — `profile_screen.dart` (righe ~211 e ~295) e `settings_screen.dart` (riga
     ~273) — sostituendo `NetworkImage` con `CachedNetworkImageProvider`; l'eviction dopo il cambio
     foto usa `CachedNetworkImage.evictFromCache`, che svuota sia la cache in memoria sia quella su
     disco. **Un terzo `NetworkImage` esiste in `app_drawer.dart:38`, non toccato**: quel widget è
     codice morto, nessun file lo importa in tutta la codebase — segnalato a parte, non è questo il
     difetto segnalato dall'utente.
   - **APK con tutti e sette i fix installata sul telefono il 2026-09-13** (`firstInstallTime`
     invariato, dati conservati) — **nessuno dei sette ancora confermato dall'utente sul
     dispositivo**: verificare appena possibile che funzionino davvero prima di considerarli chiusi
     per bene (regola generale di questo progetto: l'APK prova, non `flutter test`).
2b. **Prima ancora che i sette fossero confermati, una seconda prova sullo stesso APK ha segnalato
   altri cinque difetti (2026-09-13, stesso giorno)**. L'utente ha poi chiesto di proseguire in
   autonomia (anche a telefono scollegato) invece di fermarsi a chiedere conferma passo per passo —
   quattro sono stati sistemati in questa sessione, uno resta aperto:
   - ⬜ **Colore secondario ancora sbagliato in modalità chiara** — **non individuato**. Il fix del
     punto 2 (commit `6614c8c`) aveva corretto `AppTheme.lightTheme` (usava `style.darkSurfaceHigh`,
     un tono pensato per lo scuro); l'utente segnala che il problema persiste comunque, ma non ha
     indicato la schermata/elemento esatto. Verificato che il valore attuale
     (`style.tertiaryOnLight.withValues(alpha: 0.8)`) supera comunque i contrasti già coperti da
     `test/contrast_test.dart` — ma quel test non copre la coppia `secondary`/`onSecondary`
     specificamente, quindi un problema di contrasto lì passerebbe inosservato. Non riprodotto:
     serve la schermata esatta dall'utente, o uno screenshot del telefono, prima di poter
     continuare a indagare invece di indovinare.
   - ✅ **Cancellare un programma dava un errore Firebase** (commit `fa2073c`) — `deleteProgram`
     cercava le sue schede filtrando solo su `parentProgramId`; le regole Firestore richiedono che
     ogni query dimostri `eMio()` (owner via `userId`), quindi la lettura veniva negata con
     `permission-denied` prima ancora del batch di cancellazione. Aggiunto un test in
     `firestore-tests/rules.test.mjs` che riproduce sia la negazione sulla query vecchia sia il
     successo di quella nuova.
   - ✅ **Il selettore data aveva ancora gli angoli arrotondati** (commit `ee8247d`) —
     `showDatePicker` non eredita `dialogTheme`: aveva il suo `DatePickerThemeData` di default,
     mai agganciato allo stile "angoli vivi".
   - ✅ **Tasto "esci" dentro le impostazioni lingua** (commit `5538bc4`) — `_buildSignOut` in
     `GeneralSettingsScreen` era un doppione quasi identico di quello già in `SettingsScreen`,
     residuo del recupero del redesign Immersivo da bytecode decompilato (commit `ff893a5`), mai
     voluto lì secondo il commento in testa al file. Rimosso; il logout resta in Impostazioni.
   - ✅ **Tasto Google Fit silenzioso quando fallisce** (commit `8c479c2`) — `requestPermissions()`
     torna `false` in silenzio sia quando l'SDK/Health Connect manca sia quando l'utente ha già
     negato il permesso due volte (Android smette di richiederlo). Aggiunto un toast d'errore che
     apre le impostazioni dell'app (`openAppSettings`) e un `try/catch` attorno alla chiamata. **Non
     risolve la causa di fondo**, che resta da confermare sul dispositivo (log `debugPrint('SALUTE:
     ...')`, o controllare a mano se il permesso Salute risulta negato in modo permanente) — questo
     fix toglie solo il silenzio, non garantisce che il permesso venga concesso.
   - **Un terzo `NetworkImage` (non toccato dal fix della foto profilo) vive in `app_drawer.dart`,
     widget morto** — segnalato come task separato, **avviato dall'utente in una sessione/worktree
     indipendente** (`modest-benz-04b0fa`) mentre questa sessione proseguiva: non toccare quei file
     da qui, quella sessione ha già in corso la rimozione.
   - **Nessuno di questi cinque fix è stato ancora costruito in un APK e installato sul telefono**
     al momento in cui questa nota è stata scritta: l'`adb` non rilevava il device. Farlo appena
     torna raggiungibile, insieme alla conferma dei sette fix del punto 2.
2c. **Con il telefono ancora scollegato, l'utente ha chiesto di proseguire in autonomia** invece di
   fermarsi ad aspettarlo: la sessione ha rivisto sistematicamente altre schermate (non solo quelle
   segnalate), dispacciando un agente di ricerca su `active_session_screen.dart`,
   `workout_summary_screen.dart`, `exercise_library_screen.dart` e `program_list_screen.dart`, e
   verificando di persona ogni difetto trovato prima di agire (compreso rileggere il sorgente del
   plugin `flutter_riverpod` installato per confermare un dettaglio prima di fidarsi). Sei difetti
   concreti sistemati, tutti con test dove l'architettura lo permetteva, verificati rossi senza il
   fix:
   - ✅ **Spostare un allenamento programmato vecchio di oltre un anno non apriva il selettore data**
     (commit `19a32e2`) — stesso difetto già visto per la data dell'abbonamento (`initialDate` fuori
     da `[firstDate, lastDate]`), qui in `calendar_screen.dart` (`_rescheduleWorkout`).
   - ✅ **L'obiettivo "N allenamenti a settimana" non superava mai 1** (commit `c2bf4a2`) —
     `WorkoutSummaryScreen` aggiornava il progresso passando `[session]` (solo la sessione mostrata)
     invece di tutte le sessioni recenti; riaprire dallo storico una sessione più vecchia di 7 giorni
     azzerava anche un progresso vero. Due test in `test/workout_summary_goals_test.dart`.
   - ✅ **Precompilare i pesi dell'ultima volta poteva sovrascrivere una serie già fatta**
     (commit `7ce4065`) — la lettura da Firestore in `active_session_screen.dart` è più lenta di un
     tocco: se una serie era già stata segnata come fatta (anche riprendendo una sessione lasciata
     attiva in background), il numero veniva rimpiazzato in silenzio da quello della sessione
     precedente, spunta verde compresa. Estratta `applicaPesiUltimaSessione`, cinque test in
     `test/applica_pesi_ultima_sessione_test.dart`.
   - ✅ **Uscire durante il salvataggio di fine allenamento poteva far credere di aver eliminato la
     sessione** (commit `666968c`) — mentre `_finishWorkout` salva, il pulsante indietro restava
     attivo: scegliendo "elimina l'allenamento" in quella finestra, la sessione veniva comunque
     salvata (già in scrittura) e il codice avrebbe sollevato un `StateError` invece di eliminare
     davvero qualcosa. Bloccato il pop mentre `_isSaving` è vero. **Non testabile** con l'attuale
     sospensione dei test su questa schermata (debito US-008) — da confermare sul device.
   - ✅ **Il tempo di recupero era sbagliato se lo stesso esercizio compariva due volte nella scheda**
     (commit `94e1ada`) — `_onSetCompleted` cercava lo slot della scheda per `exerciseId`, che trova
     sempre il primo; con lo stesso esercizio due volte (riscaldamento e blocco pesante, per
     esempio) il secondo prendeva sempre il recupero del primo. Estratta `recuperoDellaSerie`, cerca
     per posizione. Quattro test in `test/recupero_della_serie_test.dart`.
   - ✅ **Creare un nuovo programma non disattivava quelli esistenti** (commit `2ea55ef`) — ogni
     programma nasce con `isActive: true` (`program_creator_screen.dart`) ma nulla disattivava i
     precedenti: con due o più programmi, tutti restavano "ATTIVA" nella lista e la Home
     (`dashboard_screen.dart`, `.where((p) => p.isActive).firstOrNull`) sceglieva arbitrariamente il
     primo, disallineando quale fosse il programma attivo fra le due schermate. `saveProgram` ora
     disattiva gli altri programmi attivi dello stesso utente prima di salvare quello nuovo. **Non
     testabile** in Dart con l'attuale `FirestoreService` (debito US-008/US-009) — da confermare sul
     device.
   - **Trovato ma non sistemato, per scelta**: combinare il segmento "Miei" con un filtro per gruppo
     muscolare in `exercise_library_screen.dart` dà sempre lista vuota per gli esercizi
     personalizzati — sintomo del form "Nuovo esercizio" incompleto (niente gruppo muscolare
     raccolto), già tracciato più sotto in questo file. La correzione vera è completare il form, non
     il filtro.
   - **Nessuno di questi sei fix è stato ancora installato sul telefono**: stesso stato del punto
     2b, `adb` non ha mai rilevato il device in questa sessione.
2d. **Ancora col telefono scollegato, una seconda passata dell'agente su sette schermate mai
   riviste** (`workout_creator_screen.dart`, `exercise_detail_screen.dart`, `gym_settings_screen.dart`,
   `health_detail_screen.dart`, `statistics_screen.dart`, `gamification_screen.dart`,
   `goals_screen.dart`) ha trovato altri cinque difetti concreti — due file (`exercise_detail_screen.dart`,
   `gym_settings_screen.dart`) non ne avevano nessuno, verificato di persona:
   - ✅ **Il più grave**: un obiettivo utente senza esercizio collegato poteva risultare "raggiunto al
     100%" per un allenamento completamente scollegato (commit `7827f04`) — `goals_screen.dart`
     ("Nuovo obiettivo") crea sempre `GoalType.targetLoad`, qualunque titolo/unità scelga l'utente, e
     non lascia mai associare un esercizio (`exerciseId` sempre nullo). Un obiettivo "Corri 10 km"
     risultava "100% raggiunto" sollevando 60 kg in uno squat, perché `updateProgressFromSessions`
     interpretava `exerciseId == null` come "va bene qualunque esercizio". Ora un obiettivo
     `targetLoad` senza esercizio non viene più toccato — non risolve la causa (manca un selettore di
     tipo/esercizio in fase di creazione, una decisione di prodotto, non una correzione meccanica).
     Due test in `test/goals_provider_test.dart`.
   - ✅ **La media di battito e peso includeva i giorni senza dato come zero** (commit `9a2fc84`) —
     un peso registrato una volta a settimana faceva scendere la "media" mostrata a un settimo del
     valore reale, e lo stesso zero artificiale schiacciava sempre a 0 il minimo del grafico a linea.
     Estratta `riempiDatiSalute` in `health_detail_screen.dart`, tre test. Sistemato nello stesso
     commit anche un difetto minore collegato: la freccia "mese successivo" restava attiva anche sul
     mese corrente.
   - ✅ **Modificare un esercizio con superserie ne perdeva l'assegnazione** (commit `a746d2d`) —
     `_ExerciseConfigurationSheetState` non riportava `superSetGroup` ricostruendo l'esercizio.
     **Impatto oggi limitato**: nessuna schermata scrive o mostra `superSetGroup` (verificato con
     grep su tutto `lib/src/ui/`), quindi riguarda solo dati preesistenti con superserie assegnata
     altrove — sistemato comunque, costo nullo.
   - ✅ **Streak e badge in "Traguardi" leggevano una fonte diversa dal resto dell'app** (commit
     `b35707f`) — `gamification_screen.dart` usava uno `StreamBuilder` diretto su
     `FirestoreService().getUserSessions`, non `dashboardSessionsProvider` (cache locale Isar
     offline-first, US-111) come Home e Statistiche: un allenamento appena chiuso o fatto offline
     comparivano subito altrove ma non ancora qui. **Non testabile** con un widget test — la
     schermata istanzia `AuthService` direttamente, debito US-008 non coperto da questo fix.
   - **Trovato ma non sistemato, per scelta**: `WorkoutTypePieChart` (`charts/workout_type_pie_chart.dart`)
     e `WorkoutReceipt` (`workout_receipt.dart`) risultano codice morto, come `app_drawer.dart` già
     segnalato prima — nessuna schermata li istanzia più. Segnalato come task separato
     (`task_6dd6d8e4`), non toccato da questa sessione.
   - **Nessuno di questi cinque fix è stato ancora installato sul telefono**: stesso stato dei punti
     precedenti.
2e. **Terza passata, dodici schermate mai riviste** (impostazioni, aspetto, timer, crediti,
   cronometro, amici, login/registrazione, misure corporee, creazione programma), due agenti in
   parallelo. Dodici difetti concreti, tutti sistemati; due file (`general_settings_screen.dart`,
   `timer_settings_screen.dart`) senza nulla di concreto:
   - ✅ **Stream del profilo ricreato a ogni rebuild, tasto Esci silenzioso in caso di errore**
     (commit `145e056`, `settings_screen.dart`) — violava la regola del progetto "mai uno Stream
     dentro build": ogni `setState` (anche solo salvare l'abbonamento) faceva tornare per un istante
     l'intera schermata ai placeholder. Aggiunto anche un `try/catch` al logout, come già fatto per
     Google Fit.
   - ✅ **I pulsanti +/- del recupero potevano far "risorgere" il timer o bloccare l'anello pieno**
     (commit `9c402b9`, `timer_service.dart`) — "-15s" quasi a zero chiamava `resetTimer()` invece di
     concludere come uno scadere naturale (niente vibrazione/suono, tempo tornato alla durata
     piena); "+1m" non allungava `timerDuration`, con l'anello di progresso bloccato pieno oltre la
     durata originale. Quattro test, verificati rossi col codice precedente.
   - ✅ **Il login rifiutava password corrette** (commit `2d2e33e`) — validava la stessa regola della
     registrazione (minimo 6 caratteri), ma Firebase impone quel vincolo solo alla creazione
     dell'account: un account con password più corta (da console, o precedente a questa regola) non
     poteva mai autenticarsi da qui.
   - ✅ **Modificare una misura corporea ne spostava la data a oggi** (commit `2d2e33e`,
     `body_measurements_screen.dart`) — correggere anche solo un refuso su una misura vecchia la
     faceva sparire dal punto giusto della cronologia e ricomparire in cima come appena presa.
   - ✅ **Salvare le info di un programma dopo un riordino annullava il riordino stesso** (commit
     `1f7606f`, `program_creator_screen.dart`) — `_saveProgram` scriveva `workoutIds` dallo snapshot
     fisso preso all'apertura dello schermo, non dall'ultimo stato noto: riordinare i giorni e poi
     toccare "Salva" (es. per correggere il nome) cancellava silenziosamente il riordino appena
     fatto, o reintroduceva il riferimento a una scheda nel frattempo eliminata. Corretta nello
     stesso commit anche la convalida del nome (un campo di soli spazi passava come "obbligatorio"
     compilato) e lo stesso difetto "Stream dentro build" del punto sopra.
   - ✅ **Un invito poteva essere duplicato, quelli scaduti restavano "in sospeso" per sempre**
     (commit `6acce90`, `firestore_service.dart` + `connect_friend_screen.dart`) — `createInvite` non
     controllava un invito pendente preesistente verso la stessa persona; gli inviti in uscita non
     mostravano mai lo stato scaduto (a differenza di quelli in entrata, che già lo fanno). Test in
     `firestore-tests/rules.test.mjs` che conferma la query di controllo permessa dalle regole.
   - ✅ **Un fallimento durante la registrazione lasciava un account autenticato senza profilo, senza
     modo di riprovare** (commit `c748169`, `auth_service.dart`) — se la scrittura del profilo su
     Firestore falliva dopo che l'account Firebase Auth era già stato creato (e autenticato), non
     c'era alcun rollback: l'utente restava bloccato per sempre in uno stato "loggato ma senza
     profilo", e un nuovo tentativo con la stessa email falliva con `email-already-in-use`. Ora un
     fallimento in una fase successiva elimina l'account appena creato prima di rilanciare l'errore.
     **Non testabile** senza un emulatore Firebase Auth (il repo ha solo l'emulatore Firestore) — da
     confermare sul device, idealmente simulando un errore di rete a metà registrazione.
   - **Trovato ma non sistemato, per scelta**: nel dialog "Password dimenticata" di
     `login_screen.dart` il pulsante "Invia" non ha uno stato di caricamento — toccarlo due volte
     avvia due chiamate concorrenti a `sendPasswordResetEmail`. Conseguenza reale solo una doppia
     email di reset, non una corruzione di dati: il costo di sistemarlo bene (uno `StatefulBuilder`
     nel dialog) non sembrava valerne la pena per un effetto così minore.
   - **Nessuno di questi dodici fix è stato ancora installato sul telefono**: stesso stato dei punti
     precedenti.
3. **`../CLAUDE.md` ha un numero disallineato, trovato verificando l'analyzer per il fix del punto
   2**: dice "il baseline è 6, tutti `deprecated_member_use`, US-102 resta aperta per quelli" — ma
   `docs/BACKLOG.md:2988` segna **US-102 ✅ DONE** e `flutter analyze` su `main` (`6a41d36`) dà
   **davvero 0 avvisi**, verificato di persona. Non corretto qui: `CLAUDE.md` è un file di regole
   condiviso, va proposto all'utente prima di riscriverlo. Il vero baseline da usare nelle prossime
   review è **0**, non 6.
4. **Sezione 8 qui sotto**: le altre priorità dell'utente dal 2026-09-13, ancora da pianificare —
   notifiche/promemoria, backup/esportazione, uso dell'RPE, sostituzione esercizi/infortuni,
   accessibilità, eliminazione account (+ accesso Google, da valutare la fattibilità).
5. **Le due decisioni di prodotto della sezione 1** (card del record, filtro Recenti) restano
   dell'utente — chiederle prima di implementare qualcosa, non indovinare.
6. **Se l'utente lo richiede di nuovo**, riprendere la ricerca di ADR-002/mockup 05 su Claude Design
   ("Turno 3", turni 1-2 mancanti).
7. **Altrimenti**, tornare al backlog per la prossima storia eseguibile — **non fidarsi di un elenco
   scritto qui**: si ricava con `grep -n "^#### US-\|^\*\*Status:" docs/BACKLOG.md`, una storia è
   pronta quando tutte quelle in `Depends on` sono `✅ DONE`.

---

## 7. Convenzioni di scrittura

- **Italiano** per commenti, documentazione e commit. Il codice resta in inglese.
- **I commenti spiegano il perché.**
- **Nessun riferimento ad AI** nei commit o nel codice. Nessun trailer `Co-Authored-By`.
- **Le review dichiarano i limiti.**
- Niente stringhe fuori dalla localizzazione, niente colori fuori da `app_palette.dart`, niente
  numeri per spaziature e raggi: vengono da `context.immersivo` (non più `context.expressive`).

---

## 8. Audit di copertura funzionale (2026-09-13) — cosa non copre l'app oggi

Richiesto dall'utente durante la review di US-111, prima di pianificare qualunque storia nuova:
"stiliamo cosa non copriamo con l'app e cosa potremmo fare". **Non sono ancora storie di backlog**:
niente `US-XXX`, niente criteri di accettazione — solo la mappa da cui scegliere. Quando una di
queste diventa una storia vera, va tolta da qui e messa in `BACKLOG.md`, non lasciata doppia.

Verificato leggendo il codice (non la documentazione), il 2026-09-13.

### Priorità dichiarate dall'utente (in quest'ordine, il 2026-09-13)

L'utente vuole dare l'app a un amico e ad altre persone: questo rende alcune voci più urgenti di
quanto lo sarebbero altrimenti, in particolare la sezione ⚠️ più sotto.

1. **Notifiche/promemoria** — non esiste affatto. Manca perfino la libreria (`flutter_local_notifications`
   non è in `pubspec.yaml`). Il solo canale di notifica esistente (`timer_notification_channel.dart`)
   serve al countdown del recupero durante l'allenamento attivo, non a promemoria programmati. Un
   allenamento programmato (`scheduled_workout.dart`) non genera mai un avviso.
2. **Backup/esportazione dati** — non esiste affatto. Nessun CSV/PDF/JSON esportabile, nessun
   backup/ripristino manuale, in nessuna schermata.
3. ✅ **Trainer/clienti (EP-017) — il fondamento è fatto.** US-086 e **US-087 (invito, 2026-09-13)**
   sono `✅ DONE`: il patto che lega due utenti esiste, testato e con le regole pubblicate. Restano
   `⬜ TODO`, ora **eseguibili**: QR (US-088, cancello esplicito su due dipendenze nuove), elenco
   clienti (US-089), scheda cliente (US-090, dipende anche da US-089), andamento (US-091, dipende
   anche da US-092), consenso/revoca (US-092). Nessuna schermata cliente esiste ancora nel codice.
4. **Usare l'RPE che già raccogliamo** — `WorkoutSet.rpe` (`workout.dart:12`) si raccoglie ad ogni
   serie e c'è già una funzione scritta **e testata** (`StatisticsHelper.calculateAverageRPE`,
   `statistics_helper.dart:137`, `test/statistics_helper_test.dart`) — ma **nessuna schermata la
   chiama**. Un dato raccolto e mai mostrato come andamento nel tempo.
5. **Sostituzione esercizi / infortuni** — non esiste affatto. Nessun modo di segnare un esercizio
   come "da evitare" o di farsi proporre un'alternativa per lo stesso gruppo muscolare.
6. **Accessibilità** — scarsa. `Semantics(` presente solo in 6 widget minori, assente in Home e
   nella schermata di allenamento attivo. La scala dei caratteri di sistema
   (`MediaQuery.textScaler`) non è mai gestita, né rispettata né bloccata: semplicemente ignorata.
7. **Aggiunta il 2026-09-13 — Eliminazione account** (+ **accesso con Google, da valutare la
   fattibilità**). Nessuna delle due esiste oggi: la cancellazione è negata di proposito a livello
   di regole (vedi ⚠️ sotto), l'accesso è solo email/password (`auth_service.dart`,
   `login_screen.dart`, `register_screen.dart`). Google richiederebbe il pacchetto `google_sign_in`
   (dipendenza nuova, da approvare) **e** una configurazione lato Firebase Console (provider Google,
   impronta SHA del certificato Android) che non si fa da riga di comando dentro questo repository.
8. ✅ **Sistemare la funzionalità amico — fatta insieme al punto 3, da US-087** ("assolutamente",
   parole dell'utente). Era **lo stesso lavoro** del trainer/clienti, non un secondo modello:
   `docs/BACKLOG.md` lo diceva già esplicitamente prima di iniziare («US-087 sostituisce e assorbe
   US-080»). `connect_friend_screen.dart` è stata riscritta sul nuovo invito (invita/accetta/
   rifiuta/sciogli). **Resta un pezzo, non tutto**: la condivisione vera di calendario/schede non è
   ancora ricollegata all'invito accettato — è la parte rimasta di US-080 nel backlog, ridotta a
   quello. Nota tecnica ancora valida: `docs/BACKLOG.md` ha una **voce duplicata e contraddittoria di
   US-084** (una `✅ DONE`, una `⬜ TODO`) — la prima è quella vera (`superSetGroup` esiste nel
   codice), la seconda va ripulita quando si torna a toccare quella sezione.
   **Trovata il 2026-09-13 rivedendo il resto dell'app**: `_FriendsAtGym` in `gym_settings_screen.dart`
   (righe 464-484) chiama `FirestoreService.getUsers(profile.friends)`, che interroga `users` con
   `whereIn` sul documento — negato dalle stesse regole (`users/{userId}`: solo `request.auth.uid ==
   userId` legge), esattamente come `getSharedSessions`/`getSharedScheduledWorkouts` più sotto in
   quel file, già commentati come tali. **Non è una regressione da sistemare oggi**: `profile.friends`
   non viene più scritto da nessuno dopo US-087 (stesso debito già noto, "i tre campi restano sul
   modello ma inutilizzati"), quindi la condizione che attiverebbe questa query (`friends` non vuoto)
   non si verifica più per un utente nuovo — resta silenziosa. A differenza dei due metodi sorella,
   qui manca il `.onErrorReturnWith` con `debugPrint` che spiega perché non succede nulla: se si
   riprende US-080, vale la pena decidere lì se questo widget va rifatto sull'invito accettato o tolto
   insieme al campo `friends`.

### ⚠️ Rilevante proprio perché si vuole condividere l'app con altre persone

Non ancora decisioni, solo fatti da conoscere prima di distribuire l'app a chi non è l'utente stesso:

- **Nessuna cancellazione account, e negata di proposito**: `firestore.rules:60`,
  `allow delete: if false` su `users/{userId}`, con un commento che lo dichiara intenzionale.
  Nessun percorso alternativo esiste per farla comunque.
- **Nessuna esportazione/backup dati, nessun consenso GDPR, nessuna privacy policy in-app.** Il
  mockup delle impostazioni generali mostra "Privacy e permessi" ed "Elimina account", ma dietro non
  c'è nessun campo/provider/metodo reale (`general_settings_screen.dart:19-24`, commento esplicito).
- **`Isar.open(...)` ha sempre `inspector: true`** (`database_provider.dart`), senza distinzione fra
  debug e release — da verificare se va bene così prima di distribuire l'app a persone esterne.
- **L'aggiunta di un amico per codice ha una falla architetturale nota**: chi cerca legge i
  documenti di *tutti* gli utenti (`firestore.rules:8-15`, commento esplicito). **Già tracciata come
  US-080** nel backlog — non è una scoperta nuova di questo audit, solo un fatto da tenere presente
  nello stesso contesto.

### Da valutare, non ancora scelte dall'utente

- **Catalogo esercizi curati sbilanciato**: 43 esercizi totali, di cui 42 forza e **zero cardio**.
  Tricipiti il gruppo più esile (4 esercizi, 1 senza immagine); petto il peggiore per immagini
  mancanti (3 su 9). Fonte: `assets/data/exercises_seed.json`.
  **Aggiunto il 2026-09-13**: mancano anche le varianti per presa (es. lat machine — presa larga,
  stretta, inversa, neutra/V), oggi accorpate sotto un solo titolo. Deciso con l'utente: **un
  esercizio per presa**, non un attributo su un esercizio solo — coerente con come il catalogo già
  distingue varianti (panca piana/inclinata) e senza toccare lo schema: `Exercise` ha già solo
  un'immagine/video/lista muscoli a testa, separare per presa è pura estensione di contenuto, non
  un cambio tecnico. Stessa categoria di lavoro della riga sopra, non una voce a parte.
- **Il form "Nuovo esercizio" personalizzato esiste ma è incompleto**: si può già creare un
  esercizio proprio (`exercise_library_screen.dart:555` → `AddExerciseDialog`), ma il form fa
  compilare solo nome e tipo — niente gruppo muscolare (salvato vuoto), niente immagine, niente
  descrizione (fissa a "Custom exercise"). Un criterio della storia che l'ha introdotta (US-079,
  `BACKLOG.md:2248`) non è mai stato confermato dal vivo: che l'esercizio sopravviva davvero al
  riavvio dell'app con Firestore vero. **Sintomo concreto trovato il 2026-09-13**: combinando il
  segmento "Miei" con un filtro per gruppo muscolare in `exercise_library_screen.dart`, il risultato
  è sempre vuoto per qualunque esercizio personalizzato (`filterExercises`, `musclesTargeted.any(...)`
  su una lista sempre vuota è sempre falso) — corretto dato lo stato dei dati, non un bug del filtro,
  ma confuso per chi lo prova senza saperlo. Non sistemato: la correzione vera è completare il form,
  non il filtro.
- **Tipi di allenamento fissi**: `WorkoutType` ha 4 valori (forza, cardio, mobilità, sport),
  calcolati automaticamente dalla categoria dell'esercizio — non scelti liberamente. Nessun modo di
  distinguere bici/corsa/boxe/crossfit come sottotipi: ricadono tutti su "cardio".
- **Foto di progresso**: non esiste. `image_picker` è già una dipendenza ma serve solo per la foto
  profilo (`profile_screen.dart:79-80`); le misure corporee restano solo numeri.
- **Localizzazione cablata a due lingue**: `localization_provider.dart` è due mappe statiche
  (`_en`/`_it`, ~550 chiavi ciascuna) scelte con un ternario su `languageCode == 'it'`. Aggiungerne
  una terza richiede modificare quel ternario e tradurre ~550 chiavi a mano, non un file di
  traduzione da affiancare.
- **Nessun onboarding guidato**: dopo la registrazione si arriva dritti sulla Home (empty state se
  non c'è ancora un programma). Nessun wizard profilo/obiettivi, nessuna scheda di esempio
  precompilata — il primo utente crea tutto da zero.

---

## 9. Verifica rapida all'inizio di una sessione

```bash
git status --porcelain
git branch -a                                        # quali branch esistono davvero, oggi
git log --oneline -5
adb devices -l                                        # il telefono è ancora la fonte più aggiornata
```

---

_Documento di passaggio · GymFlow · aggiornato il 2026-09-13 sul commit `c748169`, branch `main`_
