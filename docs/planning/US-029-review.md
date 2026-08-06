# Review US-029

**Verdetto:** APPROVATA
**Data:** 2026-08-06 · **Diff:** 1 workflow nuovo, 1 test rimosso, 1 test nuovo

> Autoverifica con checklist adversariale (modello a singolo agente).

## Copertura dei criteri

| Criterio (riscritto) | Esito | Prova |
|---|---|---|
| Workflow su push a `main` e `dev` | ✅ | `ci.yml` dichiara i due branch |
| Fallisce se l'analyzer riporta errori | ✅ | **Provato**: errore di sintassi introdotto di proposito → exit code 1; rimosso → exit code 0 |
| Fallisce se un test fallisce | ✅ | `flutter test` senza flag permissivi: un fallimento interrompe il job |
| Verde sullo stato attuale | ✅ | Sequenza CI riprodotta in locale: `analyze` exit 0, **15 test verdi** |
| Avviabile manualmente | ✅ | `workflow_dispatch` presente |
| Un errore introdotto di proposito lo rende rosso | ✅ | Vedi seconda riga: verificato empiricamente, non per deduzione |

## Rilievi

### 🔴 Bloccanti

Nessuno.

### 🟡 Da valutare — due decisioni che meritano di essere viste

1. **I criteri originali sono stati riscritti.** Parlavano di controllo "sulle pull request", ma le PR sono state rimosse dal processo dopo la stesura del backlog: un workflow su `pull_request` non si sarebbe mai attivato. I criteri sono stati riportati sul flusso reale mantenendo invariato l'obiettivo. La revisione è annotata nella storia con data e motivo, e nel change log. **Non è stato adattato il criterio all'implementazione: è stato corretto un criterio diventato falso.**

2. **`test/widget_test.dart` è stato rimosso e sostituito, anticipando in parte US-032 e US-031.** Il file generato da `flutter create` cercava il testo `'GymFlow Initializing...'`, mai esistito in questa applicazione: falliva da sempre e non verificava nulla. Senza rimuoverlo, questa storia non poteva soddisfare il criterio "verde sullo stato attuale".

   Al suo posto, 15 test su `StatisticsHelper`: logica pura, nessuna dipendenza da Firebase o Isar. **US-031 resta necessaria** — mancano i mapper, i casi limite completi e la copertura del resto della logica. Questa è la base minima che rende il gate sensato, non la sua sostituzione.

   L'alternativa scartata era escludere `flutter test` dal gate: avrebbe prodotto un controllo che non controlla ciò che conta.

### 🔵 Suggerimenti

3. **Versione di Flutter fissata a `3.38.7`** invece di `channel: stable`. Con il canale mobile, la CI cambia comportamento a ogni rilascio e un fallimento non dice più se la colpa è del codice o del toolchain. `deploy_web.yml` ha ancora `channel: stable`: US-004 dovrà correggerlo alla ripresa di EP-008.

4. **Gli avvisi non sono ancora bloccanti** (`--no-fatal-infos --no-fatal-warnings`). I 67 residui sono debito preesistente tracciato in US-030: renderli bloccanti oggi darebbe un gate rosso al primo push. Il commento nel workflow dice esplicitamente quale storia rimuoverà i flag.

5. **I nuovi test hanno confermato il comportamento atteso di `StatisticsHelper`**, incluso il caso "due allenamenti nello stesso giorno contano una volta sola" e "la serie resta viva se l'ultimo allenamento è di ieri". Nessun difetto emerso: la logica delle serie consecutive si comporta come documentato.

## Fuori scope rilevato

L'aggiunta di `test/statistics_helper_test.dart` eccede la lettera della storia. È dichiarata, motivata e circoscritta: senza test veri il gate sarebbe verde su zero verifiche. Vedi rilievo 2.

## Regressioni sospette

| Verifica | Esito |
|---|---|
| `flutter analyze` (sequenza CI esatta) | 67 issue, zero errori, **exit code 0** |
| `flutter test` | **15 test, tutti verdi** — per la prima volta in questo repository |
| Validità del workflow | YAML valido, un job, sei step |
| Prova negativa | Errore deliberato → exit 1. Il gate non è verde per costruzione |
| Codice applicativo | Non toccato: il diff riguarda solo `.github/`, `test/` e `docs/` |

## Effetto sul repository

Il repository torna ad avere una CI, dopo la sospensione decisa con US-039. Da questo merge in poi, un errore di compilazione su `main` o `dev` viene segnalato entro pochi minuti invece di restare invisibile fino al prossimo controllo manuale — che è esattamente la circostanza che ha reso necessaria US-001.

**US-030 e US-031 sono ora eseguibili.**
