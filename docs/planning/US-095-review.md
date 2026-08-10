# US-095 — Review

**Data:** 2026-08-10 · **Branch:** `feature/US-095-statistics-screen`
**Commit rivisti:** `78bfb7f` (consegna) + `6909e59` (correzione in review)
**Chi ha implementato:** Gemini · **Chi rivede:** non ha scritto il codice

**Verdetto: APPROVATA.** È la consegna migliore ricevuta: i numeri sono veri, lo spostamento è
davvero uno spostamento, e il dubbio dichiarato nel rapporto era **il rilievo giusto, trovato
dall'autore stesso**. Un rilievo, corretto.

---

## I numeri, misurati nel worktree

| | Dichiarato | Misurato |
|---|---|---|
| `flutter analyze` | 17 (baseline 17) | **17**, elenco identico a `main` |
| `flutter test` | 501 verdi | **501 verdi** |
| File toccati | 6 | 6, tutti previsti dal piano |

Primo rapporto in cui **analyze e test coincidono con la misura al primo colpo**, senza un
baseline immaginato e senza una suite rossa spacciata per verde.

---

## Era uno spostamento? Sì, e l'ho verificato senza rileggere 600 righe

Il punto 1 del piano era l'unico che contava: «il diff deve leggersi come taglia e incolla». 611
righe fuori dalla dashboard, 620 dentro la schermata nuova — la forma è giusta, ma la forma non
prova niente.

Il controllo che prova: ho estratto le righe **uscite** dalla dashboard e quelle **entrate** nella
schermata, normalizzate e ordinate, e le ho confrontate.

**Righe uscite e non arrivate: 14**, e ognuna si spiega — commenti (`// HERO BLOCK (Nuovo)`,
`// DASHBOARD VIEW`), `_currentView` che è stato rinominato nel commento, l'import di
`live_metrics_provider` che è migrato, `loc.t('dashboard_title')` che non serve più perché il
segmentato ora dice «Statistiche», e `drawer: const AppDrawer()` — che mi ha fatto sobbalzare e
**era un mio falso allarme**: il cassetto è ancora sulla dashboard, alla riga 146. Il mio confronto
guardava una direzione sola, e una riga spostata dentro lo stesso file gli sembra persa.

**Righe entrate e non uscite dalla dashboard**: solo l'intelaiatura — dichiarazioni di classe,
`import`, `AppBar`, `initState`, le due chiavi nuove, e il `titleEmphasized` che la guardia
pretende. **Nessun blocco riscritto.** La dichiarazione «Riscritto: nessuno» regge.

Due controlli puntuali in più:

- **Le quattro tessere sono le stesse quattro**: `workouts_label`, `streak_label`, `volume_label`,
  `rpe_label`, con le stesse chiamate a `StatisticsHelper`. Era il rischio con la stella — l'errore
  di US-066 — e non si è ripetuto.
- **`_buildHealthSection` è identica**, riga per riga, verificato con un `diff` fra la versione su
  `main` e quella nuova. Il piano chiedeva di spostarla **rotta** — Health Connect nega i passi, è
  US-100 — e così è stato fatto. Resistere alla tentazione di aggiustarla mentre la si sposta è
  esattamente la disciplina che rende il diff leggibile.

---

## 🟡-1 · La guardia della card condivisa era stata indebolita — corretto

Ed è il rilievo che **l'autore ha trovato da sé**, scrivendolo nei dubbi:

> Avendo tolto `ExpressiveCard` dalla `DashboardScreen` […] ho rimosso `dashboard_screen.dart` dal
> gruppo «le tre schermate usano la card condivisa» e l'ho rimpiazzato con `statistics_screen.dart`.
> È possibile che questo debba essere gestito dichiarandolo invece che omettendolo?

**Sì, ed è la domanda giusta.** Togliendo le statistiche, dalla dashboard è sparito il nome
`ExpressiveCard` — ma la card condivisa la dashboard **la usa ancora**: la riceve da
`HomeHeroCard`, che `ExpressiveCard` la usa due volte. Il criterio è «usa la card condivisa», non
«scrive quella parola», e togliere il file dalla lista faceva sparire la guardia insieme al
problema.

**Corretto in `6909e59`**: la guardia accetta anche la via indiretta, e dichiara **quale** widget
fa da tramite. Provato: facendo smettere a `HomeHeroCard` di usare `ExpressiveCard`, il test
diventa rosso — quindi la catena è sorvegliata per intero e non solo il primo anello.

Vale la pena dire cosa distingue questo caso: non è un errore, è una **decisione presa nel posto
sbagliato**. Indebolire un test per farlo passare è una cosa che si fa in trenta secondi e che
nessuno nota mai; averla scritta nei dubbi invece di lasciarla passare è il motivo per cui questa
consegna è approvata e non respinta.

---

## Le mie mutazioni, diverse dalla sua

Il rapporto dichiara di aver togliuto `BodyMeasurementsChart` e visto il test arrossire. Ne ho
fatte due altrove, sul file vero e verificate presenti prima di lanciare:

| Mutazione | Esito |
|---|---|
| `HomeHeroCard` smette di usare `ExpressiveCard` (2 punti) | 🔴 rosso sulla guardia riscritta: prova che la catena indiretta è coperta |
| `_buildHealthSection` rinominata nella schermata nuova | 🔴 rosso: «StatisticsScreen deve contenere `_buildHealthSection`» |

La seconda conferma che il test sul «non si è perso niente» ha denti anche per le sezioni che non
sono grafici.

---

## Copertura dei criteri

| Criterio | Esito |
|---|---|
| Le sei voci spostate e non riscritte | ✅ verificato col confronto riga per riga, non col rapporto |
| Nessun dato irraggiungibile | ✅ le quattro tessere sono quattro, la salute è identica, lo storico è nella schermata nuova |
| La schermata è raggiungibile | ✅ dal menu **e dalla home**, con un'icona nella barra in alto. Era la lezione di US-070, dove una schermata raggiungibile solo dal menu è rimasta invisibile per giorni |
| La home non contiene più le statistiche | ✅ con test sul sorgente in entrambe le direzioni |
| Il design system regge | ✅ la schermata nuova è fra le sorvegliate **nello stesso commit in cui nasce**, come il piano chiedeva |
| Gli avvisi non salgono | ✅ 17, elenco identico |
| Si apre e si legge, e la home è più corta | ⬜ **Da confermare sull'APK** |

---

## 🔵 Rilievi minori

| | Cosa |
|---|---|
| 1 | Il segmentato ora dice «Statistiche / Storico» e la chiave `dashboard_title` non è più usata da nessuno: resta nel dizionario come orfana. Innocua, ma è debito che nessun test prende |
| 2 | `expect(count, equals(5))` per contare `_buildStatCard` conta 4 chiamate più la definizione: funziona, ed è fragile a una riscrittura del metodo. Va bene per il criterio che doveva coprire |
| 3 | `statistics_screen.dart` non ha un `drawer`: è coerente con le altre schermate aperte con `Navigator.push`, che hanno il tasto indietro. Da guardare sull'APK che non risulti un vicolo cieco |

---

## Limiti dichiarati di questa review

1. **Non ho aperto l'app.** Che la home sia ora più corta e che la schermata nuova si legga si
   giudica guardando. In particolare **non ho verificato che l'icona nella barra in alto si capisca**:
   un grafico a torta come simbolo di «statistiche» è convenzionale, ma è un giudizio visivo.
2. **Nessuna delle due schermate si monta in un test** — Firebase e Isar, il limite di US-008 — e
   tutta la verifica dello spostamento è **sul sorgente**. Sa dire che il codice è stato spostato,
   non che funzioni dopo lo spostamento. Se una sezione si è rotta nel trasloco, si vede solo
   sull'APK: **le quattro tessere coi numeri giusti, i due grafici che disegnano, lo storico che
   elenca**.
3. **La sezione salute è ancora rotta**, per scelta: US-100.
4. **Non ho verificato l'ordine visivo** delle sezioni nella schermata nuova rispetto a com'era
   sulla home. Il codice le mette nella stessa sequenza, ma il segmentato in cima cambia il
   contesto.

---

_Review di fase 5 · US-095 · su codice non scritto da chi rivede_
