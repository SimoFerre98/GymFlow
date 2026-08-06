# Review US-039

**Verdetto:** APPROVATA
**Data:** 2026-08-06 · **Diff esaminato:** `git diff main...HEAD` (3 file, 1 file di codice)

> **Natura della review.** Autoverifica con checklist adversariale, non giudizio indipendente: chi ha scritto il codice è anche chi lo revisiona, secondo il modello a singolo agente adottato in `docs/WORKFLOW.md`. Il limite è noto e il controllo effettivo resta l'approvazione umana della fase 6. Due rilievi 🟡 sono emersi e sono stati corretti prima di chiudere la review.

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| Non più eseguito automaticamente sui push a `main` | ✅ | Parser YAML: trigger risolto a `{'workflow_dispatch': None}`. Assert su assenza di `push` superato |
| Resta nel repository e avviabile manualmente | ✅ | File presente in `.github/workflows/`; `workflow_dispatch` valido come trigger |
| Commento che spiega la sospensione e rimanda a EP-008 | ✅ | Righe 1-25: causa tecnica, riferimento a EP-008, istruzioni di ripristino, avvertenza sull'avvio manuale |
| Dopo un push su `main`, nessuna esecuzione fallita | ⏳ | **Non verificabile prima del merge.** Prova disponibile: assenza del trigger `push`. Da confermare in fase 8 |
| Reversibile con la sola riattivazione del trigger | ✅ | Diff limitato al blocco `on:`, al `name:` e al commento. Zero righe del job modificate (verificato con grep su `flutter`, `firebase`, `uses:`, `runs-on`, `repoToken`, `projectId`, `channelId`) |

## Rilievi

### 🔴 Bloccanti

Nessuno.

### 🟡 Da valutare — entrambi corretti durante la review

1. **Istruzioni di ripristino incomplete.** Il commento elencava due passi (trigger, rimozione del commento) ma ometteva il ripristino di `name:`, che era stato modificato in "(sospeso, avvio manuale)". Chi avesse seguito le istruzioni alla lettera avrebbe lasciato il workflow riattivato ma con un nome che ne dichiara la sospensione — contraddittorio e fuorviante. In tensione diretta col criterio di reversibilità.
   **Correzione:** aggiunto il passo 2 con il nome originale da ripristinare.

2. **Nessuna avvertenza sull'esito dell'avvio manuale.** Il commento dichiarava il workflow "avviabile a mano" senza dire che oggi **fallisce comunque** allo step `flutter build web --release`. Un collega avrebbe potuto lanciarlo aspettandosi una pubblicazione e concluderne che la sospensione fosse mal fatta.
   **Correzione:** aggiunto un blocco ATTENZIONE che chiarisce l'esito atteso e lo scopo residuo dell'avvio manuale (verificare i progressi di US-003).

### 🔵 Suggerimenti

3. **Il cambio di `name:` crea una nuova voce nella lista Actions di GitHub.** La vecchia "Deploy to Firebase Hosting on merge" resterà visibile nello storico come workflow senza esecuzioni recenti. Effetto cosmetico, nessuna azione necessaria — ma spiega perché in Actions compariranno due voci.

4. **Il trigger su `master` è stato rimosso insieme a quello su `main`.** Il branch `master` non esiste nel repository (`git branch -r` mostra solo `origin/main` e `origin/dev`), quindi era già inerte. Il ripristino documentato reintroduce solo `main`, che è l'intenzione corretta: se un giorno servisse `master`, va aggiunto consapevolmente.

## Fuori scope rilevato

Nessuno. Il diff tocca esattamente i file previsti dal piano:

| File | Previsto | Presente nel diff |
|---|---|---|
| `.github/workflows/deploy_web.yml` | sì | sì |
| `docs/BACKLOG.md` | sì | sì |
| `docs/planning/US-039.md` | sì (è il piano) | sì |

Nessuna modifica a `lib/`, `test/`, `pubspec.yaml`, `firebase.json` o alla configurazione Firebase.

## Regressioni sospette

| Verifica | Esito |
|---|---|
| `flutter analyze` | 172 issue, zero errori. Una in meno di prima di US-001, nessuna nuova |
| `flutter test` | **Fallisce, ma già su `main`.** Eseguito su entrambi i branch con esito identico: il `widget_test.dart` predefinito cerca `'GymFlow Initializing...'`, testo che non esiste nell'app. Fallimento preesistente e già tracciato in US-032. Il diff non tocca `lib/` né `test/`: impossibile che derivi da questa storia |
| Verifica su emulatore | **Non applicabile.** La storia non modifica codice dell'app; il suo *Demonstrates* riguarda la lista delle esecuzioni su GitHub, osservabile solo dopo il merge. Dichiarato invece di essere silenziosamente omesso |
| Validità sintattica del workflow | Parser YAML: file valido, 1 job, 5 step, tutti preservati |
| Segreti nel diff | Nessuno introdotto. I riferimenti `secrets.GITHUB_TOKEN` e `secrets.FIREBASE_SERVICE_ACCOUNT_GYMFLOW_D5D09` erano preesistenti e non sono stati toccati |

## Conseguenza da tenere presente

Con questa storia il repository resta **senza alcuna CI attiva**: `deploy_web.yml` era l'unico workflow. È un effetto atteso e documentato tra i rischi del piano, ma va chiuso presto: **US-029** introduce il gate di verifica su pull request ed è nella stessa fase dell'ordine di esecuzione. Fino ad allora, analyze e test vanno eseguiti a mano prima di ogni PR.
