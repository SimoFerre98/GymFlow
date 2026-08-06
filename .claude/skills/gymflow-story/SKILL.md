---
name: gymflow-story
description: Esegue il ciclo completo di implementazione di una storia del backlog GymFlow — planning, branch, implementazione, verifica, review, merge e chiusura. Usa questa skill ogni volta che l'utente chiede di implementare, sviluppare, lavorare o "fare" una user story del backlog (US-001, US-010, ecc.), oppure chiede di prendere in carico la prossima storia disponibile. Si attiva su frasi come "implementa US-014", "lavora sulla prossima storia", "prendi in carico US-033", "fai la storia dei controller", "sviluppa la US-010".
---

# GymFlow — Ciclo di implementazione di una storia

Esegui il processo definito in `docs/WORKFLOW.md` sulla storia indicata. Questo file ne è la versione eseguibile: in caso di divergenza, `docs/WORKFLOW.md` prevale.

**Argomento:** un codice storia (`US-XXX`). Se manca, proponi le storie eseguibili e chiedi quale.

---

## Esecuzione

**Un solo agente esegue tutte e nove le fasi, dall'inizio alla fine, senza delegare.** Niente sotto-agenti per planning o review: la delega costa più tempo di quanto ne faccia risparmiare su storie di questa dimensione.

Questo significa che la review è un'**autoverifica**, non un giudizio indipendente. Per compensare, la fase 5 impone un cambio di ruolo esplicito e una checklist adversariale: si smette di difendere il proprio lavoro e si cerca attivamente il modo in cui è sbagliato. Il controllo reale resta il tuo via libera in fase 6.

> Puoi comunque chiedere una review indipendente su una storia specifica: basta dirlo, e la fase 5 viene delegata a un agente separato.

## Regole non negoziabili

1. **Una storia per volta.** Se un'altra è in `🔵 IN PROGRESS`, fermati e segnalalo.
2. **Nessun codice prima del piano.**
3. **La review è una fase distinta.** Non si fonde con l'implementazione e non si salta, nemmeno quando il codice sembra ovvio.
4. **Nessun merge senza via libera esplicito dell'utente.**
5. **Fuori scope significa fuori.** Ciò che emerge diventa una storia nuova, non un'aggiunta a questo branch.
6. **`dev` e `main` restano allineati.** Dopo ogni merge, `dev` viene riportato su `main`.
7. Tutti gli artefatti (piano, review, commit) sono in italiano.
8. **Nessuna attribuzione ad AI nei commit.** Niente trailer `Co-Authored-By` verso assistenti, niente firme automatiche, nessun riferimento a come il codice è stato prodotto.

---

## Fase 0 — Selezione

1. Leggi `docs/BACKLOG.md` e individua la storia.
2. Estrai `Depends on`, `Blocks`, `Status`, criteri di accettazione, epica.
3. Controlli bloccanti — se uno fallisce, **fermati e riferisci**:
   - Ogni dipendenza in `Depends on` è `✅ DONE`?
   - Lo stato non è già `✅ DONE`?
   - Nessun'altra storia è `🔵 IN PROGRESS`?
   - La storia **non** appartiene a EP-008? (accantonata: solo dopo la fase 5 dell'ordine di esecuzione — se l'utente la chiede comunque, avvisalo e chiedi conferma)
   - Il working tree è pulito?
4. Se non è stato passato alcun codice storia, elenca le storie eseguibili — stato `⬜ TODO` con tutte le dipendenze soddisfatte — ordinate per fase e priorità, e chiedi quale prendere.

---

## Fase 1 — Planning

Ispeziona il codice interessato, poi scrivi il piano. Non delegare.

Scrivi `docs/planning/US-XXX.md`:

```markdown
# US-XXX: <titolo>

**Epica:** EP-XXX | **Punti:** N | **Branch:** feature/US-XXX-slug
**Piano redatto:** <data>

## Contesto
<cosa esiste oggi, con riferimenti file:riga>

## Obiettivo
<una frase>

## Approccio
<la strada scelta e perché>

### Alternative scartate
| Alternativa | Perché no |
|---|---|

## File toccati
| File | Intervento |
|---|---|

## Passi
1. ...

## Piano di test
| Criterio di accettazione | Come lo verifico |
|---|---|

## Rischi
| Rischio | Come me ne accorgo | Mitigazione |
|---|---|---|

## Fuori scope
- ...
```

Porta lo stato a `📋 PLANNED`.

**Fermati e chiedi** se il piano rivela che la storia va suddivisa, ristimata, o che i criteri di accettazione sono sbagliati.

---

## Fase 2 — Branch

```bash
git switch main
git pull --ff-only origin main
git switch -c feature/US-XXX-slug
```

Prefisso secondo la natura: `feature/`, `fix/`, `refactor/`. Slug breve in inglese.
Porta lo stato a `🔵 IN PROGRESS` e committa l'aggiornamento del backlog e il piano.

---

## Fase 3 — Implementazione

- Segui il piano. Se si rivela sbagliato, aggiorna `docs/planning/US-XXX.md` annotando il perché, poi prosegui.
- Resta nei file previsti. Per uscirne, chiedi.
- Commit piccoli: `US-XXX: <cosa fa questo commit>`.
- Rispetta le convenzioni di `CLAUDE.md`: niente stream in `build`, niente effetti collaterali in `build`, `dispose` di ogni risorsa, servizi dai provider, stringhe localizzate, colori dal `ColorScheme`.

---

## Fase 4 — Verifica

Nell'ordine, tutto verde prima di proseguire:

1. `flutter analyze` — zero errori, zero avvisi **nuovi** rispetto a `main`
2. `flutter test` — tutti verdi
3. `flutter run -d emulator-5554` — l'app parte e la funzionalità si comporta come da **Demonstrates**. Avvia l'emulatore se serve; se non è disponibile, segnalalo e chiedi come procedere invece di dichiarare la verifica superata.
4. Verifica i criteri di accettazione **uno per uno** e spuntali in `docs/BACKLOG.md`

Riporta gli esiti reali. Un passaggio saltato va dichiarato, non omesso.

---

## Fase 5 — Review

Cambia ruolo. Fino a un attimo fa stavi costruendo; adesso stai cercando di dimostrare che ciò che hai costruito è sbagliato.

Riparti dal diff, non dalla memoria: `git diff main...HEAD`. Rileggilo come se l'avesse scritto qualcun altro e dovessi decidere se lasciarlo entrare in `main`. Il ragionamento che ti ha portato a scriverlo non è una prova che sia corretto.

**Checklist adversariale** — per ciascuna voce, cerca attivamente il caso in cui fallisce:

- [ ] Ogni criterio di accettazione è soddisfatto? Con quale prova concreta, non con quale intenzione?
- [ ] Il diff contiene modifiche non previste dal piano?
- [ ] Cosa succede con dato assente, lista vuota, utente non autenticato, rete assente?
- [ ] Ogni risorsa creata viene rilasciata? Controller, sottoscrizioni, timer, stream.
- [ ] C'è uno `Stream` o un `Future` creato dentro `build`?
- [ ] C'è un effetto collaterale dentro `build`?
- [ ] Le convenzioni di `CLAUDE.md` sono rispettate? Servizi dai provider, stringhe localizzate, colori dal `ColorScheme`.
- [ ] Qualcosa in questo diff può rompere una funzionalità che non ho testato?
- [ ] Ci sono segreti, credenziali o percorsi locali nel diff?
- [ ] Se dovessi tornare su questo codice tra sei mesi senza contesto, lo capirei?

Se dalla checklist non emerge nulla, sospetta di non aver guardato abbastanza: cerca almeno un punto migliorabile prima di dichiarare la review conclusa.

Scrivi `docs/planning/US-XXX-review.md`:

```markdown
# Review US-XXX

**Verdetto:** APPROVATA | APPROVATA CON RISERVE | RESPINTA

## Copertura dei criteri
| Criterio | Esito | Prova |
|---|---|---|

## Rilievi
### 🔴 Bloccanti
### 🟡 Da valutare
### 🔵 Suggerimenti

## Fuori scope rilevato
## Regressioni sospette
```

Con verdetto `RESPINTA` o rilievi 🔴, torna alla fase 3 e ripeti dalla verifica.
Porta lo stato a `🔍 IN REVIEW`.

---

## Fase 6 — Via libera

Presenta all'utente, in forma compatta:

- Cosa è stato fatto, in quali file
- Esito di analyze, test ed esecuzione su emulatore
- Verdetto della review e come sono stati affrontati i rilievi
- Cosa resta fuori scope

**Attendi approvazione esplicita.** Non procedere oltre senza. Se arrivano richieste di modifica, torna alla fase 3.

---

## Fase 7 — Merge

Solo dopo il via libera della fase 6:

```bash
git switch main
git pull --ff-only origin main
git merge --squash feature/US-XXX-slug
git commit          # messaggio riepilogativo dell'intera storia
git push origin main
git branch -D feature/US-XXX-slug
```

Merge **squash**: una storia, un commit su `main`. Il branch resta locale, non si pusha, e si cancella con `-D` (lo squash non lo marca come merged).

**Non si usano pull request.** Il controllo di qualità sta nella review di fase 5 e nell'approvazione di fase 6.

---

## Fase 8 — Chiusura

1. Spunta tutti i criteri di accettazione della storia in `docs/BACKLOG.md`.
2. Porta lo stato a `✅ DONE`.
3. Controlla le storie in `Blocks`: segnala all'utente quali sono diventate eseguibili.
4. Se sono emersi problemi fuori scope, aprili come storie nuove in coda al backlog con ID progressivi e aggiorna il change log.
5. **Allinea `dev` a `main`** — obbligatorio, mai saltare:
   ```bash
   git switch main
   git pull --ff-only origin main
   git switch dev
   git merge --ff-only main
   git push origin dev
   git switch main
   ```
   Se il fast-forward fallisce, `dev` ha commit propri non passati da una PR: **fermati e segnalalo**, non forzare.
6. Verifica l'allineamento: `git rev-list --left-right --count main...dev` deve dare `0 0`.
7. Riepiloga in tre righe: cosa è entrato in `main`, cosa si è sbloccato, cosa suggerisci come prossima storia.

---

## Quando fermarti

Dipendenza non soddisfatta · storia da suddividere o ristimare · necessità di uscire dai file del piano · criterio di accettazione sbagliato o non verificabile · prima di ogni merge in `main` · prima di aggiungere una dipendenza a `pubspec.yaml` · prima di toccare regole Firestore, workflow CI o configurazione Firebase · rilievi 🟡 che richiedono una decisione di prodotto · emulatore non disponibile per la verifica.
