# US-049 — Review

**Verdetto:** APPROVATA — le correzioni sono state applicate da chi rivede, vedi in fondo
**Diff esaminato:** `git diff main...origin/feature/US-049-workout-summary` · 9 file, +982 / −4
**Verifica rifatta da chi rivede**, in un worktree separato:
`flutter analyze` **63 avvisi** (baseline 63) · `flutter test` **326 verdi** · entrambi confermano il rapporto

È il primo lavoro consegnato da un esecutore esterno. Va detto subito quello che è andato bene,
perché è la parte che conta di più: **i file toccati sono esattamente i nove previsti dal piano**,
nessuno in più; i test sono veri e mirati, non decorativi; e i criteri nel backlog **non sono stati
spuntati**, incluso quello sui record che il piano vietava esplicitamente di spuntare. Il rapporto
di consegna dichiara un dubbio reale sulla geometria del ritaglio, ed è fondato.

---

## Copertura dei criteri

| # | Criterio | Esito | Prova |
|---|---|---|---|
| 1 | Volume, serie completate su totale, sforzo medio, calorie, battito | ⚠️ **il volume è sbagliato** | Rilievo 🔴 2. Il resto è corretto e testato |
| 2 | Le serie non completate sono indicate, non nascoste | ✅ | `'${completedSets} / ${totalSets}'` e un test sul caso 12/18 |
| 3 | Un record superato è riportato con il valore precedente | ⬜ **non spuntato, correttamente** | È US-050. Vedi 🔵 7 su dove andrà |
| 4 | Raggiungibile dallo storico | ✅ | `dashboard_screen.dart:429` riempie un `// TODO: Detail view`. **Da confermare sull'APK** |
| 5 | Chiudendo il riepilogo la sessione risulta salvata | ✅ nel codice, ⚠️ **lo dice male** | Il salvataggio precede la navigazione. Ma vedi 🔴 1 |
| 6 | Interrompendo a metà, riporta ciò che è stato fatto | ✅ | Test dedicato |
| 7 | Calorie e battito assenti non compaiono a zero | ✅ | Righe condizionali più due test |

---

## 🔴 Da correggere prima del merge

### 1. «Salva e chiudi» dice una cosa che non succede

`workout_summary_screen.dart:141` — il pulsante fa `Navigator.pop()` e nient'altro. **Il
salvataggio è già avvenuto prima**, in `active_session_screen.dart:259`, ed è proprio ciò che il
criterio 5 richiede.

Nel percorso di fine allenamento è fuorviante. Nel secondo percorso è **falso**: aprendo dallo
storico una sessione di tre giorni fa, la schermata dice «Allenamento chiuso» e offre «Salva e
chiudi». Non c'è niente da salvare.

**Correzione**: la chiave `workout_summary_close_cta` diventa «Chiudi» / «Close». Se si vuole tenere
il senso di conclusione nel percorso principale, si passa un parametro alla schermata e si usano due
chiavi — ma la più semplice basta.

### 2. Il volume perde i mezzi chili, e con US-046 i mezzi chili sono la norma

`workout_summary.dart:63` — `volume += (set.weight * set.reps).toInt()`.

`toInt()` **tronca**, e tronca **a ogni serie**, non alla fine:

```
62,5 kg × 7 ripetizioni = 437,5  →  437   (perde 0,5)
```

US-046 ha appena reso il passo del carico **2,5 kg**: mezzi chili non sono un caso limite, sono il
caso normale. Su diciotto serie si perdono fino a nove chili, e il numero mostrato è semplicemente
sbagliato.

**Perché nessun test l'ha preso**: tutti i pesi nei test sono interi — 60, 15, 20. È l'unica lacuna
vera in una batteria altrimenti buona.

**Correzione**: accumulare in `double` e arrotondare una volta sola alla fine
(`volume.round()`), con un test che usa 62,5 × 7.

---

## 🟡 Da valutare

### 3. Una stringa italiana scritta nel codice

`workout_summary.dart:82` — `session.workoutName.isNotEmpty ? session.workoutName : 'Allenamento'`.

È una stringa **visibile** — finisce nell'intestazione dello scontrino — e in inglese resta
«Allenamento». Il test di US-071 non la vede: controlla le chiavi `t('...')`, non i letterali.

Va anche notato **dove** sta: in un file di calcolo puro, che non dovrebbe conoscere le stringhe
dell'interfaccia. La correzione naturale è lasciare `workoutName` vuoto nel modello e risolvere il
ripiego nel widget con una chiave nuova.

### 4. Il file nuovo reintroduce il debito che US-022 esiste per togliere

`workout_summary_screen.dart` e `workout_receipt.dart` usano `expressive.spacing.md` in alcuni punti
e valori scritti a mano in molti altri: `EdgeInsets.symmetric(horizontal: 12, vertical: 6)`,
`BorderRadius.circular(999)`, `SizedBox(height: 52)`, `fontSize: 10/12/13/16/19`,
`EdgeInsets.fromLTRB(16, 16, 16, 22)`, `letterSpacing: -0.5`.

`AGENTS.md` è esplicito: *«Nessun valore numerico per spaziature, raggi e misure: vengono da
`context.expressive`»*. Che l'esecutore usi i token altrove dimostra che la regola era nota.

**Perché conta più del solito**: US-022 e US-023 esistono per togliere questi valori dalle schermate
vecchie. Reintrodurli in un file **nuovo** significa creare debito già pianificato per la rimozione.

Le misure senza token — `cornerFull` c'è, `999` no; per i corpi di testo servirebbe il `TextTheme` —
si risolvono con i token esistenti nella quasi totalità dei casi.

### 5. I mesi tradotti a mano, con `intl` già nel progetto

`workout_summary_screen.dart:25-50` — due liste di dodici abbreviazioni, e un `_formatDate` che
sceglie in base alla lingua.

`intl` è già una dipendenza e `calendar_screen.dart` usa già `DateFormat`. `DateFormat.MMMd(locale)`
fa la stessa cosa, in tutte le lingue, e continua a funzionare quando ne verrà aggiunta una terza.

---

## 🔵 Osservazioni

### 6. Il ritaglio degenera su larghezze minuscole

`ReceiptClipper` calcola `count = (w / 14).round()`. Per `w < 7` viene `0`, il ciclo non gira e il
bordo inferiore diventa una diagonale dall'angolo destro al lato sinistro. Non succede — una card è
larga centinaia di dp — ma un `count.clamp(1, …)` costa una parola.

**Il dubbio dichiarato nel rapporto è corretto e la scelta è quella giusta**: l'ultimo arco chiude
esattamente su `x = 0`, quindi non ci sono denti troncati ai bordi, e il raggio varia fra 6,96 e
7,14 dp per le larghezze reali. Impercettibile, e preferibile a un dente tagliato a metà.

### 7. Il posto per i record non c'è

Il piano diceva di lasciarlo pronto sotto lo scontrino. Fra scontrino e pulsante c'è solo una
spaziatura. Non è un difetto — un contenitore vuoto sarebbe peggio — ma US-050 dovrà inserirsi lì, e
il suo mandato va aggiornato di conseguenza.

### 8. Volume e RPE contano serie diverse

Il volume somma **solo le serie completate**; la media dello sforzo usa **tutte** le serie con un
RPE, completate o no. Entrambi i comportamenti seguono la lettera del piano, che però era ambiguo su
questo. È una decisione da prendere: uno sforzo dichiarato su una serie non completata conta?

---

## ⚠️ Un errore del piano, non dell'esecutore

Il mandato specificava per lo scontrino: **fondo `scheme.primary`, testo `scheme.onPrimary`**.

È giusto solo nel tema scuro. Nel tema chiaro `primary` è `amberOnLight` `#7A5A2E` — **marrone
scuro**, non ambra: seguendo il piano alla lettera sarebbe uscito uno scontrino marrone con testo
chiaro, che il mockup non prevede.

L'esecutore ha usato `primaryContainer` / `onPrimaryContainer` nel tema chiaro, che sono l'ambra e
il testo scuro: **più fedele al mockup di quanto chiedesse il mandato**. La scelta è giusta, ma non
era dichiarata nel rapporto di consegna — e una deviazione silenziosa, anche quando migliora le
cose, è esattamente ciò che la riga «Fuori piano» serve a intercettare.

**`DESIGN-SPEC.md` va corretto**: la riga sui colori dello scontrino deve dire «`primary` in scuro,
`primaryContainer` in chiaro», altrimenti il prossimo mandato ripete l'errore.

---

## Processo

Due scostamenti da [`DELEGA.md`](../DELEGA.md), entrambi senza conseguenze qui:

- **La storia non è stata rivendicata su `main` prima di iniziare.** È passata da `PLANNED` a
  `REVIEW` in un colpo solo, sul branch. Nessuna collisione è avvenuta, ma è la regola che esiste
  proprio perché il 6 agosto due sessioni hanno fatto lo stesso lavoro in parallelo.
- Lo stato scritto è `🔍 REVIEW`; gli stati del progetto sono `🔍 IN REVIEW`.

---

## Limiti dichiarati

1. **Nessuna prova sul dispositivo.** La resa della dentellatura, la leggibilità dello scontrino e
   il percorso dallo storico sono da guardare sull'APK.
2. **La schermata non è montabile in un test** con Firebase: i test coprono i calcoli e lo
   scontrino, non la navigazione dalla sessione né dalla dashboard.
3. **Chi rivede non ha scritto il codice**, il che qui è un vantaggio: i due rilievi 🔴 sono
   entrambi cose che l'autore aveva davanti e non ha visto, e uno dei due nasce da un mio errore nel
   mandato.

---

## Cosa serve per il merge

| | Rilievo | Costo |
|---|---|---|
| 🔴 | «Salva e chiudi» → «Chiudi» | una chiave |
| 🔴 | Volume in `double`, arrotondato una volta, con un test a 62,5 kg | poche righe |
| 🟡 | `'Allenamento'` → chiave di localizzazione, risolta nel widget | poche righe |
| 🟡 | Valori numerici → token | il grosso del lavoro residuo |
| 🟡 | Mesi → `DateFormat` | poche righe |

I due 🔴 vanno fatti. I 🟡 sono una decisione: farli ora costa poco, farli dopo significa che US-022
troverà debito nuovo in file appena scritti.

---

_Review del 2026-08-07 · fase 5 del ciclo in [`WORKFLOW.md`](../WORKFLOW.md) · rivisto in worktree separato, senza toccare il lavoro in corso su US-073_


---

## Correzioni applicate prima del merge

Fatte da chi rivede, invece di rimandare il lavoro indietro.

| Rilievo | Correzione | Prova |
|---|---|---|
| 🔴 «Salva e chiudi» | La chiave diventa «Chiudi» / «Close» | Test aggiornato: cerca «Chiudi» |
| 🔴 Volume troncato | Accumulo in `double`, `round()` una volta sola alla fine | **Test nuovo**: tre serie da 62,5 × 7 danno 1313, non 1311 |
| 🟡 `'Allenamento'` nel modello | Il modello lascia il nome vuoto; il widget risolve con `workout_untitled`, tradotta | Test aggiornato: il modello restituisce stringa vuota |
| 🟡 Valori numerici a mano | Tutti sostituiti con token e stili del tema | `grep` su entrambi i file: **zero** occorrenze |
| 🔵 Ritaglio degenere | `count.clamp(1, 1000)` | — |

**Un rilievo è stato ritirato.** Avevo chiesto di sostituire le liste dei mesi con `DateFormat` di
`intl`. Verificando prima di agire: il progetto **non chiama mai `initializeDateFormatting`**, e
`calendar_screen` usa `DateFormat('HH:mm')` senza locale proprio per questo. `DateFormat.MMMd('it')`
lancerebbe un'eccezione a runtime. Le liste scritte a mano sono la scelta corretta, e ora hanno un
commento che spiega perché. Se un giorno servisse la formattazione localizzata delle date, è una
storia sua: tocca l'avvio dell'app.

**Una correzione ha richiesto una seconda passata.** Sostituendo `fontSize: 12` con
`textTheme.bodyMedium` (14 dp) le righe dello scontrino sono andate in overflow di 28 pixel: il
mockup dice 9 px → **12 dp**, quindi il token giusto era `bodySmall`. Preso da tre test che sono
diventati rossi — la ragione per cui i test del widget valgono più di un'occhiata.

**Verifica finale**: `analyze` 63, `flutter test` **327 verdi** (erano 326: +1 sul volume, gli altri
aggiornati), APK debug costruito.
