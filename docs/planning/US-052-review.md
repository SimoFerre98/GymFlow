# US-052 — Review

**Data:** 2026-08-11 · **Branch:** `feature/US-052-time-pill`
**Commit rivisti:** `cbee460` (la consegna) + `525426d` (le correzioni)
**Chi ha implementato:** Gemini · **Chi rivede:** non ha scritto il codice consegnato

**Verdetto: RESPINTA alla consegna, APPROVATA dopo le correzioni.**
Il difetto che ha fatto respingere non era nella pillola: era in ciò che la pillola faceva a **tutte
le altre schermate** quando non c'era.

---

## Cosa era giusto, e va detto per primo

Questa consegna è la più curata della serie, e le tre trappole del piano sono state affrontate tutte:

- **Il `navigatorKey` è stato creato fuori da `build`** (`app.dart:8`), che era l'avvertenza
  esplicita del piano. La navigazione funziona ed è provata.
- **Il file è stato aggiunto alla lista sorvegliata** dal design system (`:31-34`), e la pillola è
  stata riscritta sui token: via `Colors.white`, `fontSize: 18`, `elevation: 8` e quel
  `Theme.of(context).primaryColor` che non è un ruolo di Material 3.
- **La precedenza al recupero sul cronometro è stata scelta e dichiarata**, ed è la risposta giusta
  al rilievo aperto dalla review di US-094: prima la pillola mostrava il cronometro anche mentre era
  il recupero a scadere.
- **`analyze`: 17, elenco identico a `main`.** Vero.
- **`flutter test`: verde**, e il conteggio sale di tredici — sette test nuovi più sei generati
  dall'aver aggiunto il file alla lista sorvegliata. Verificato.
- **Nessun file fuori dai quattro del piano.**

---

## 🔴-1 · A pillola **nascosta**, ogni schermata scendeva di 40 dp

La `SafeArea` stava attorno a **tutto** l'overlay:

```dart
return SafeArea(
  bottom: false,
  child: AnimatedSize(
    child: showOverlay ? _buildPill(...) : const SizedBox.shrink(),
  ),
);
```

Una `SafeArea` impagina il proprio figlio **anche se ha dimensione zero**: aggiunge il bordo di
sistema e diventa alta quanto quello. Misurato con una barra di stato da 40 dp:

| Stato | Ingombro di `TimerOverlay` | Dove comincia la `AppBar` |
|---|---|---|
| Pillola nascosta, **consegnato** | **40 dp** | y = 40, e alta 96 — cioè con altri 40 dp interni |
| Pillola nascosta, dopo la correzione | **0 dp** | y = 0, alta 96 — come senza pillola |

Cioè **ottanta dp di striscia vuota in cima a ogni schermata dell'applicazione, a timer fermo**, che
è lo stato in cui l'app si trova quasi sempre. Non è un dettaglio della pillola: è una regressione su
tutto.

**Perché nessun test l'ha vista**: la superficie di prova di `flutter_test` non ha bordi di sistema.
Con `padding` zero, `SafeArea` non aggiunge niente e il difetto è invisibile. I test ora girano con
un bordo di 40 dp, ed è l'unica ragione per cui si vede.

## 🔴-2 · I test provavano una `Column` scritta nel file di test

```dart
home: const Scaffold(
  body: Column(
    children: [TimerOverlay(), Expanded(child: ...)],
  ),
),
```

Non è il telaio dell'applicazione: è una sua imitazione costruita nel test. **Rimettendo lo `Stack`
in `app.dart` — cioè il difetto che questa storia chiude — quei test restavano verdi.** Misurato.

Vale in particolare per il criterio che definisce la storia, «il contenuto si sposta invece di
essere coperto»: era verificato su una `Column` che il test si era scritto da solo.

È il difetto n. 3 dell'handoff, «test che provano i pezzi e non il cablaggio fra loro», nella stessa
forma di US-036.

**Corretto**: il telaio è diventato `GymFlowShell`, un widget in `app.dart`, e i test montano
quello. Non è una ripulitura estetica — è ciò che rende i criteri verificabili sulla struttura vera.

## 🟡-1 · La barra ripeteva il bordo di sistema

Conseguenza del punto precedente, e trovata solo misurando: con la pillola visibile, la pillola
copre la fascia di sistema **e la `AppBar` sotto se la prende di nuovo**, lasciando altri 40 dp
vuoti fra la pillola e il titolo. Ora al contenuto viene tolta, e la barra torna alta
`kToolbarHeight`.

## 🟡-2 · Il rapporto non riporta il totale dei test

> «test: 7 verdi in time_pill_test.dart (oltre a tutti gli altri passati)»

Il numero della suite è l'unico che dice qualcosa, ed è la riga che l'handoff cita come già andata
storta una volta — «456 verdi» con la suite rossa. Qui la suite era davvero verde, ma per saperlo ho
dovuto rifarla.

E manca la riga **«Test rotto»** che il mandato chiedeva: nessuna mutazione è stata provata. È la
riga che vale di più, e le tre mutazioni fatte in review hanno trovato rossi che nessuno aveva visto.

## 🟡-3 · Il difetto dei «Timer pendenti» corretto senza dire dove

> «Ho corretto un difetto di test causato dai Timer pendenti»

Il diff non mostra modifiche a `timer_service.dart` né ad altri test, quindi la correzione sta dentro
il file nuovo — probabilmente gli azzeramenti a fine test. Va bene, ma un difetto «corretto» va detto
**dove**: se avesse toccato il servizio sarebbe stato fuori piano, e per accorgersene ho dovuto
leggere tutto il diff.

## 🔵 Minori

| | Cosa |
|---|---|
| 1 | I test usavano `find.byType(Container)` come sinonimo di «la pillola». In un albero vero i `Container` sono molti: ora la pillola ha una chiave |
| 2 | Il rapporto non conferma che il trascinamento è stato tolto, che il mandato chiedeva esplicitamente. È stato tolto, ed è giusto: ora c'è un test che lo fissa |
| 3 | Il tocco che naviga sta sul `GestureDetector` esterno, e al centro della pillola ci sono i comandi: toccare lì mette in pausa. È corretto, ma il test di navigazione deve toccare il testo, non «la pillola» |

---

## Copertura dei criteri

| Criterio | Esito |
|---|---|
| Occupa una posizione fissa in alto | ✅ e il trascinamento non la sposta più: c'è un test |
| Compare solo quando cronometro o recupero sono attivi | ✅ |
| Un tocco porta alla schermata del tempo | ✅ `navigatorKey`, e la rotta è verificata |
| Porta i comandi di pausa e azzeramento | ✅ verificati sullo stato del notifier, non sull'icona |
| Non compare sulla schermata del tempo | ✅ |
| Il contenuto sottostante si sposta invece di essere coperto | ✅ e ora **sul telaio vero**, non su una copia nel test |
| Non toglie spazio quando non c'è | ✅ **criterio aggiunto in review**: era il difetto 🔴-1 |
| Si guarda bene, entrata e uscita comprese | ⬜ **Da confermare sull'APK** |

**Mutazioni, tutte diverse da quelle dell'esecutore — che non ne aveva dichiarata nessuna:**

| Mutazione | Esito |
|---|---|
| La `SafeArea` torna attorno a tutto | 🔴 `quando non c e, non occupa niente` |
| Il telaio torna uno `Stack` | 🔴 `il contenuto si sposta invece di essere coperto` |
| Il bordo di sistema non viene tolto al contenuto | 🔴 `la barra non ripete il bordo di sistema` |

---

## Fuori scope rilevato

Nessuno. `timer_service.dart` non è stato toccato, come chiesto.

## Limiti dichiarati di questa review

1. **Non ho aperto l'app.** Tutto quello che c'è qui sono misure di geometria in `flutter_test`. Che
   la pillola si legga, che l'animazione d'entrata non faccia sobbalzare l'interfaccia, e che
   spingere giù tutte le schermate non risulti fastidioso, sono giudizi che vogliono il telefono.
2. **Il bordo di sistema provato è uno solo**, 40 dp in alto. Telefoni con notch, barre di
   navigazione a gesti o schermi curvi hanno altri valori: la correzione legge il bordo vero, ma
   l'ho verificata a un valore solo.
3. **Non ho provato la pillola sopra una schermata con `SliverAppBar`** — la home. Le misure sono
   state fatte con `AppBar` normale e senza barra: che una barra che si comprime si comporti bene
   sotto la pillola resta da vedere sull'APK.

---

_Review di fase 5 · US-052 · su codice non scritto da chi rivede_
