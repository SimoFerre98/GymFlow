# GymFlow — passaggio di consegne

**Aggiornato:** 2026-09-12 · **Commit:** `1a60331` su `main` (`dev` allineato in fast-forward).

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

1. **Far confermare all'utente sul telefono la nuova logica della Home** (punto 4 della lista sopra)
   — installata il 2026-09-12, non ancora vista dal vivo.
2. **Le due decisioni di prodotto della sezione 1** (card del record, filtro Recenti) restano
   dell'utente — chiederle prima di implementare qualcosa, non indovinare.
3. **Se l'utente lo richiede di nuovo**, riprendere la ricerca di ADR-002/mockup 05 su Claude Design
   ("Turno 3", turni 1-2 mancanti).
4. **Altrimenti**, tornare al backlog per la prossima storia eseguibile — **non fidarsi di un elenco
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

## 8. Verifica rapida all'inizio di una sessione

```bash
git status --porcelain
git branch -a                                        # quali branch esistono davvero, oggi
git log --oneline -5
adb devices -l                                        # il telefono è ancora la fonte più aggiornata
```

---

_Documento di passaggio · GymFlow · aggiornato il 2026-09-12 sul commit `1a60331`, branch `main`_
