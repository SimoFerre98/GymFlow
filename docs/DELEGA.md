# Lavorare in parallelo su GymFlow

Come far scrivere il codice a più assistenti contemporaneamente senza che si pestino i piedi, e
senza che la qualità scenda.

---

## Perché questa divisione, e non un'altra

Non è un'organizzazione teorica: viene da dove sono nati gli errori veri, misurati sulle storie
fatte finora.

| Errore | Dove è nato | Costo |
|---|---|---|
| US-045: un import che le regole Firestore rifiutano | **nel piano** — un assunto verificabile solo sul dispositivo, dato per buono a tavolino | una storia intera, rifatta con US-072 |
| US-042: sette tinte del segnaposto che contraddicono i mockup | **nel piano** — i mockup non erano nel repository | una storia da correggere, US-073 |
| US-070: la libreria irraggiungibile dal menu | **nessuno aveva aperto l'app** | tutto EP-009 invisibile per giorni |
| US-046: lo screen reader annunciava «14%» | **preso da un test**, non dalla review | zero, il test l'ha fermato prima |

**Nessuno di questi era "ho scritto male il codice".** Erano tutti nel piano o nella verifica. Da
qui la divisione: chi ha il contesto pianifica e rivede, chi è veloce implementa.

---

## Chi fa cosa

| Fase | Chi | Perché |
|---|---|---|
| 0 · Selezione | **Orchestratore** | Serve sapere quali dipendenze sono davvero soddisfatte e quali storie non si pestano i piedi |
| 1 · Piano | **Orchestratore** | È dove sono nati gli errori costosi. Richiede mockup, debito noto, architettura, storia del progetto |
| 2-4 · Branch, codice, verifica | **Esecutore** (altra chat, altro modello, altro strumento) | Il piano dice file, approccio, test e confini: è lavoro meccanico e parallelizzabile |
| 5 · Review | **Orchestratore** | Adversariale, e su codice che non ha scritto: è un vantaggio, non un limite |
| 6-8 · Via libera, merge, chiusura | **Umano + orchestratore** | Il merge resta una decisione umana |

---

## Il mandato: cos'è e come si consegna

Il piano `docs/planning/US-XXX.md` **è** il mandato. Contiene già tutto quello che serve a chi
implementa: contesto con file e riga, approccio con le alternative scartate, elenco dei file da
toccare, passi, piano di test, rischi e fuori scope.

A un esecutore si consegna esattamente questo:

```
Repository: C:\Users\s.ferrero\Code\GymFlow   (branch main aggiornato)
Leggi:      AGENTS.md, poi docs/planning/US-XXX.md
Fai:        fasi 2, 3 e 4 del ciclo in docs/WORKFLOW.md
Consegna:   branch feature/US-XXX-slug pushato, e il riepilogo in fondo ad AGENTS.md
Non fare:   merge in main, dipendenze nuove, file fuori dal piano
```

Se l'esecutore non legge file automaticamente (una chat semplice), si incolla il contenuto di
`AGENTS.md` e del piano. Sono scritti per essere autosufficienti.

---

## Come si evita di lavorare due volte sulla stessa cosa

**È già successo.** Il 2026-08-06 due sessioni hanno salvato gli stessi mockup nel repository in
parallelo, in due cartelle diverse: lavoro doppio, e per poco non sovrascritto.

La regola che lo impedisce è una sola, e costa un commit:

> **Prima di scrivere una riga, si rivendica la storia su `main` e si pusha.**
> Un commit che porta lo `Status` della storia a `🔵 IN PROGRESS` e ci scrive chi la sta facendo.

Chi trova una storia già `🔵 IN PROGRESS` ne prende un'altra. Chi finisce, la porta a `🔍 IN REVIEW`
sempre con un commit su `main`.

Non serve altro: nessun sistema di lock, nessuno strumento in più. Serve solo che tutti lo facciano
**prima**, non dopo.

### Il branch si pusha

Cambia rispetto a com'era finora, quando i branch restavano locali. Se chi implementa e chi rivede
sono su macchine o sessioni diverse, un branch locale non è recensibile. Il branch si pusha, la
review avviene sul branch, e **solo il merge in `main` resta una decisione umana**.

---

## Quali storie si possono fare in parallelo

Due storie sono parallelizzabili quando **non toccano gli stessi file**. Il piano di ciascuna
elenca i file: il confronto è meccanico.

Stato al 2026-08-06:

| Storia | File principali | Parallela con |
|---|---|---|
| **US-073** grafica ai mockup | `ui/widgets/exercise_image`, `exercise_thumbnail`, `expressive_card`, `core/theme/*` | US-047, US-049 |
| **US-047** metriche dal vivo | `ui/screens/active_session_screen`, `services/health_service` | US-073 |
| **US-049** riepilogo di fine allenamento | schermata nuova, `active_session_screen` (chiusura) | US-073 |
| US-047 e US-049 fra loro | **entrambe toccano `active_session_screen`** | ⚠️ **no**, si pestano i piedi |

Quindi: **US-073 in parallelo a una fra US-047 e US-049**, l'altra dopo.

---

## Cosa non si delega

Non per gelosia: perché sono i punti in cui un assunto sbagliato costa una storia intera.

- **Regole Firestore, configurazione Firebase, workflow CI.** US-045 è morta esattamente lì.
- **Modello dati e migrazioni.** Un campo sbagliato si porta dietro i dati già salvati.
- **Codice nativo Kotlin** (US-053, US-054): le uniche due storie che escono da Dart.
- **Decisioni che il backlog lascia aperte.** Se il piano non dice cosa fare, l'esecutore si ferma e
  chiede: non decide.
- **Il merge.**

---

## Le regole che si fanno rispettare da sole

Un esecutore che non legge la documentazione viene fermato lo stesso. È la parte che vale di più,
perché non dipende dalla buona volontà di nessuno.

| Regola | Chi la fa rispettare | Stato |
|---|---|---|
| Nessuna chiave di localizzazione senza traduzione EN e IT | `test/localization_test.dart` — legge il sorgente | ✅ attivo |
| La palette non regredisce sotto WCAG | `test/contrast_test.dart` — 60 test | ✅ attivo |
| La libreria curata resta leggibile e coerente | `test/exercise_seed_test.dart` — legge l'asset vero | ✅ attivo |
| Gli avvisi dell'analyzer non superano 55 | **nessuno**: si controlla a mano | ⬜ da fare, richiede una modifica alla CI |
| Nessun colore letterale o valore numerico nei widget | **nessuno** | ⬜ previsto da US-022 |

Le due righe vuote sono il prossimo investimento sensato: rendono le regole eseguibili invece che
scritte, ed è ciò che permette di andare veloci senza controllare tutto a mano.

---

## Come si rivede il lavoro di un altro

Uguale alla fase 5 di [`WORKFLOW.md`](WORKFLOW.md), con una differenza: **si riparte dal diff senza
sapere cosa l'autore intendeva fare**. È un vantaggio — chi ha scritto il codice rilegge ciò che
voleva scrivere, chi non l'ha scritto legge ciò che c'è.

```bash
git fetch origin && git diff main...origin/feature/US-XXX-slug
flutter analyze     # deve dare ≤ 55
flutter test        # deve essere verde
```

E poi la checklist adversariale, che per il lavoro altrui ha due voci in più:

- I criteri spuntati sono davvero dimostrati da un test, o solo dichiarati?
- Il diff contiene file che il piano non prevedeva?
- Ci sono criteri spuntati che richiederebbero un dispositivo? Vanno riaperti.

---

---

## Consegnare una storia ad Agy (Antigravity), con l'umano come tramite

**Perché serve un tramite.** `agy -p` — la modalità non interattiva — **non funziona**:
risponde `timeout waiting for response` con `duration_seconds: 0` e zero turni, sia dentro
una shell senza tty sia nel terminale dell'utente, sia in 1.1.8 sia in 1.1.11. `agy models`
invece risponde, quindi non è l'autenticazione. Finché il difetto resta, l'orchestratore non
può lanciare Agy da sé: prepara il mandato, l'utente lo incolla nella sessione interattiva,
e riporta indietro il rapporto di consegna.

**Cosa prepara l'orchestratore, prima di passare la palla:**

1. Il piano in `docs/planning/US-XXX.md`, committato su `main`.
2. Lo stato della storia a `📋 PLANNED · delegabile` nel backlog.
3. **Il worktree già creato**, con il branch giusto:
   ```bash
   git worktree add ../GF0XX -b fix/US-0XX-slug
   ```
   Il worktree lo crea l'orchestratore e non l'esecutore: è ciò che garantisce che Agy non
   scriva mai nella cartella principale, dove qualcun altro sta lavorando.

### Il mandato da incollare

Va incollato così com'è, cambiando solo il codice della storia e i due percorsi. È
autosufficiente: rimanda ai file del repository invece di ripetere le regole, perché il
piano e `AGENTS.md` sono scritti per essere letti da chi non ha la conversazione.

```
Lavora in: C:\Users\s.ferrero\Code\GF0XX
Questo e un git worktree del progetto GymFlow, sul branch fix/US-0XX-slug.
NON toccare C:\Users\s.ferrero\Code\GymFlow: e un'altra cartella di lavoro.

Leggi, in quest'ordine:
1. AGENTS.md               le regole operative del progetto
2. docs/planning/US-0XX.md il tuo mandato: cosa fare, quali file, quali test
3. docs/DESIGN-SPEC.md     solo se tocchi qualcosa che si vede

Fai le fasi 2, 3 e 4 del ciclo in docs/WORKFLOW.md:
- implementa quello che dice il piano, e nient'altro
- resta nei file elencati nel piano
- commit in italiano con il codice storia in testa, nessuna firma e nessun
  riferimento ad assistenti AI
- verifica con:
    C:/Users/s.ferrero/Flutter/bin/flutter.bat analyze
    C:/Users/s.ferrero/Flutter/bin/flutter.bat test
  analyze deve dare 55 o meno. Se sale, hai introdotto qualcosa: sistemalo.

NON fare: merge in main, push, dipendenze nuove in pubspec.yaml, file fuori
dal piano, modifiche alle regole Firestore o ai workflow CI.

Quando hai finito, scrivi SOLO questo rapporto, senza altro testo attorno:

=== CONSEGNA US-0XX ===
Branch:      <nome del branch>
Commit:      <lista dei messaggi di commit, uno per riga>
File:        <file toccati, uno per riga>
Fuori piano: <file toccati che il piano non prevedeva, con il motivo; oppure "nessuno">
analyze:     <numero> avvisi   (baseline 55)
test:        <numero> verdi    (erano 458)
Test rotto:  <hai provato a rompere il codice per vedere il test fallire? cosa
             hai rotto e cosa e diventato rosso; oppure "non provato">
Criteri:     <per ogni criterio del piano: soddisfatto, oppure non soddisfatto
             e perche, oppure "da confermare sul dispositivo">
Dubbi:       <cosa non ti convince del tuo stesso lavoro>
=== FINE ===
```

**La riga «Test rotto» è quella che vale di più.** In questo progetto tre difetti sono
passati perché i test verificavano meno di quanto dicesse il loro nome, o provavano un
oggetto finto invece del codice. Chiedere all'esecutore di rompere il codice di proposito
costa un minuto e trova quella classe di errori prima della review.

**La riga «Dubbi» è la seconda.** Chi rivede sa già dove guardare, se gliela scrivono.

### Cosa fa l'orchestratore quando torna il rapporto

Non si fida del rapporto: **rifà `analyze` e `test` nel worktree**, riparte dal diff con
`git diff main...HEAD`, e applica la checklist adversariale della fase 5. I numeri
dichiarati vanno confrontati con quelli misurati — è già capitato che due storie
dichiarassero gli stessi numeri perché erano misurati sullo stesso albero.

---

_Scritto il 2026-08-06, dopo che una collisione fra due sessioni parallele ha reso evidente il
problema. Sezione su Agy aggiunta il 2026-08-07._
