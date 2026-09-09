# GymFlow — passaggio di consegne

**Aggiornato:** 2026-09-09 · **Commit:** `d5b2327` su `recovery/immersivo-toxic-forest`
(pushato, **non ancora mergiato in `main`**). `main`/`dev` sono fermi a `ab08290` (14 agosto).

Questo file serve a chi riprende il lavoro **senza la cronologia della conversazione** — umano o
assistente AI, e su qualunque macchina: la sessione che ha scritto questa versione girava su una
macchina Linux personale, non più sul PC Windows citato nelle versioni precedenti di questo file,
**perso** nel frattempo (vedi sezione 1). Contiene ciò che **non si deduce leggendo il repository**:
decisioni prese a voce, trappole dell'ambiente, il livello di rigore atteso, e — questa volta — la
storia di come una settimana di lavoro quasi persa è stata recuperata.

## Cosa leggere, e cosa non leggere

| Leggi | Perché |
|---|---|
| **Questo file**, per intero | È il più corto che contenga tutto |
| [`../AGENTS.md`](../AGENTS.md) | Le regole che fanno fallire una consegna |
| [`WORKFLOW.md`](WORKFLOW.md) | Il ciclo in 8 fasi — **attualmente sospeso**, vedi sezione 2 |
| [`DESIGN-SPEC.md`](DESIGN-SPEC.md) | ⚠️ **Stale**: descrive la direzione precedente (Material 3 Expressive/Indigo), non quella oggi nel codice. Non riscritto ancora — vedi sezione 2 |

⚠️ **`docs/design/` ha oggi un solo file**, `GymFlow Immersivo Impostazioni.html` (un estratto di
conversazione con Claude Design, "Turno 3", non un mockup nel formato dei tre precedenti). I tre
mockup storici (`01-direzione-visiva.html`, `02-schermate-app.html`, `03-timer-e-movimento.html`,
direzione Material 3 Expressive/Indigo) sono stati **rimossi dal repository** il 2026-09-09: la
direzione che descrivevano è superata. Il mockup che dovrebbe sostituirli come fonte autorevole,
`docs/design/05-immersivo-toxic-forest.html`, e l'ADR che lo accompagna,
`docs/adr/002-immersivo-toxic-forest.md`, sono **citati per nome dal codice ma non recuperabili**:
non sono mai stati committati e non sono file compilati in un APK, quindi il trucco della sezione 1
non può ritrovarli. Cercare nella conversazione "Turno 3" su Claude Design (turni 1 e 2 della stessa
conversazione, non ancora ritrovati) prima di rassegnarsi a riscriverli da zero.

⚠️ **`BACKLOG.md` è 3455 righe, 110 storie, 64 `✅ DONE`** (contato il 2026-09-09 con
`grep -c "^#### US-"` e `grep -c "✅ DONE"` — **non fidarsi dell'intestazione del file**, che dice
ancora "81 storie" ed è ferma al 6 agosto: mai aggiornata nonostante il footer del file stesso dica
110). Si consulta cercando, non leggendo tutto: `grep -n "^#### US-0XX" docs/BACKLOG.md`.

---

## 1. Dove siamo: il codice di una settimana intera era quasi perso

**Il fatto più importante di questa consegna.** Tra il 14 e il 21 agosto 2026 è stato scritto,
sul PC Windows dell'utente, un redesign visivo completo dell'app — cambio di nome, cambio di
identità: **"Immersivo / Toxic Forest"**, che sostituisce integralmente Material 3 Expressive e la
palette Indigo (ADR-001, `DESIGN-SPEC.md`). Quel PC è andato perso. **Nessun commit di quel lavoro
è mai arrivato su GitHub**: `main`/`dev` si fermano al 14 agosto (`ab08290`), l'APK installato sul
telefono (`RFGL10YZ5RX`) era del 21 agosto — sette giorni di lavoro reale, a rischio di sparire per
sempre.

### Come è stato recuperato

L'APK installato era una build **debug** (mai release, per prassi del progetto). Le build debug
Flutter incorporano nel Dart Kernel (`assets/flutter_assets/kernel_blob.bin` dentro l'APK) il
**testo sorgente originale** di ogni file `.dart` compilato — serve al debugger per "view source".
Estratto l'APK dal telefono via `adb`, cercando nel dump di `strings` i marcatori
`file:///C:/Users/s.ferrero/Code/GymFlow/lib/....dart` (il percorso reale sul PC perduto), il testo
fra un marcatore e il successivo è il contenuto quasi letterale di quel file, commenti italiani
compresi. **109 file su 111 recuperati integralmente**, con parentesi bilanciate; gli altri due
sistemati a mano (uno rigenerato con `build_runner`, un altro con una coda di rumore binario tagliata
dopo verifica). Sei file sono del tutto nuovi rispetto a quanto era su GitHub: `immersivo_tokens.dart`
e quattro sotto-schermate delle impostazioni (`appearance_`, `general_`, `gym_`,
`timer_settings_screen.dart`) più `ticker_marquee.dart`.

Il codice recuperato vive sul branch **`recovery/immersivo-toxic-forest`** (pushato, non mergiato):
- `flutter analyze` su `lib/`: **zero errori**. Due interventi manuali oltre al recupero automatico
  sono stati necessari — vedi commit `ff893a5` per il dettaglio (rumore binario tagliato in
  `expressive_segmented_control.dart`; `healthServiceProvider` rinominato in
  `healthServiceProviderProvider` in 3 punti, perché la classe `HealthServiceProvider` finisce già in
  "Provider" e **questa** versione di `riverpod_generator` genera il nome doppio — la stessa trappola
  già in sezione 3 dalle versioni precedenti di questo file, ricomparsa per lo stesso motivo).
- `flutter test`: **873/873 verdi** (commit `d5b2327`), dopo aver aggiornato 17 file di test che
  usavano l'API precedente di `AppPalette` (`amber`/`salmon`/`indigo900`, rimossi) o assumevano una
  struttura di schermata che il redesign ha cambiato o eliminato del tutto (l'intera `SliverAppBar`
  con saluto e cassetto della dashboard non esiste più; il widget condiviso `WorkoutReceipt` non è
  più usato da `WorkoutSummaryScreen`).

  ⚠️ **Segnalazione da portare in review, non richiusa**: la nuova `_RecordBar` in
  `workout_summary_screen.dart` non mostra più né le ripetizioni della serie che ha stabilito il
  record né la data del massimale precedente. È un cambiamento di **contenuto**, non solo di stile —
  va deciso con l'utente se è voluto o una perdita da recuperare.

### Cosa manca ancora, di questa storia

1. **Decidere quando/come portare `recovery/immersivo-toxic-forest` in `main`.** Per ora è solo
   pushato. Nessun merge senza via libera esplicito (vale la regola di sempre, ora più che mai: è
   un branch enorme, 107+ file).
2. **Ritrovare, o riscrivere dichiarandolo, `ADR-002` e `docs/design/05-immersivo-toxic-forest.html`**
   — vedi il box in cima al file.
3. **Riscrivere `DESIGN-SPEC.md`** sulla base del codice ora recuperato (`app_palette.dart`,
   `immersivo_tokens.dart` sono la fonte più affidabile oggi, insieme agli screenshot presi
   dall'app installata). Finché non è fatto, `DESIGN-SPEC.md` va trattato come **storico**, non come
   riferimento.
4. **Aggiornare i numeri stantii** in `BACKLOG.md` (intestazione) e in `../CLAUDE.md` ("Stato del
   progetto" diceva 94 storie/40 completate; sono 110/64).
5. Due segnalazioni minori spawnate come task separati durante l'aggiornamento dei test: un commento
   ormai stantio in `exercise_row.dart` sui raggi Material 3 Expressive, e il sospetto che
   `WorkoutReceipt` sia codice morto (usato solo dai suoi stessi test).

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
| Android SDK | `/usr/lib/android-sdk`, **manca `cmdline-tools`**: `flutter build apk` non è stato verificato qui. `flutter analyze` e `flutter test` **non ne hanno bisogno** e funzionano pienamente |
| `adb` | Installato via `apt` (richiede `sudo`, vedi sotto). Telefono riconosciuto: `RFGL10YZ5RX`, Samsung S26 Ultra (`SM_S948B`) |
| `gh` (GitHub CLI) | Autenticato come `SimoFerre98`; `git push`/`pull` funzionano tramite le sue credenziali |

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
più la scala Material 3 "emphasized". Vedi `lib/src/core/theme/immersivo_tokens.dart`, il file più
affidabile su questa direzione finché `DESIGN-SPEC.md` non è riscritto.

### Trainer e schede: l'ordine deciso resta valido

**EP-016 «Schede come le scrive un allenatore» viene prima di EP-017 «Trainer e clienti».** Nessuna
informazione nuova la mette in discussione — verificare comunque lo stato reale delle storie
US-083/086/087 nel backlog prima di assumerlo ancora vero.

### Verifica tramite APK

Il ciclo **non esegue l'app**: produce un APK, l'utente prova sul telefono. Su questa macchina Linux,
`flutter build apk` non è stato testato per l'assenza di `cmdline-tools` — se serve una build,
verificare prima se conviene completare quel setup o tornare a una macchina con toolchain Android
completa.

---

## 6. Cosa fare adesso

Le priorità, in ordine, così come emerse dalla sessione che ha scritto questo file:

1. **Chiudere i punti aperti della sezione 1**: decidere il merge di `recovery/immersivo-toxic-forest`,
   la ricerca di ADR-002/mockup 05, la riscrittura di `DESIGN-SPEC.md`, la card del record.
2. **Riallineare `BACKLOG.md` e `CLAUDE.md`** ai numeri veri (110 storie, 64 `✅ DONE`).
3. **Solo dopo**, tornare al backlog per la prossima storia eseguibile — **non fidarsi di un elenco
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
git rev-list --left-right --count main...recovery/immersivo-toxic-forest
adb devices -l                                        # il telefono è ancora la fonte più aggiornata
```

---

_Documento di passaggio · GymFlow · riscritto il 2026-09-09 sul commit `d5b2327`,
branch `recovery/immersivo-toxic-forest`_
