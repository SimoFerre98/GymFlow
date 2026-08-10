# GymFlow

App Flutter per il tracciamento degli allenamenti. Backend Firebase (Auth, Firestore, Storage), stato con Riverpod, persistenza locale con Isar.

> **Le regole operative valgono per chiunque lavori al codice e stanno in [`AGENTS.md`](AGENTS.md)** — leggibile da qualunque assistente o strumento. Questo file contiene le specificità di Claude Code e non ripete quelle regole: se divergessero, varrebbe `AGENTS.md`.
>
> Per far lavorare più assistenti in parallelo: [`docs/DELEGA.md`](docs/DELEGA.md).

## Se è la tua prima sessione su questo progetto

**Leggi [`docs/HANDOFF.md`](docs/HANDOFF.md) prima di toccare qualsiasi cosa.** Contiene ciò che non si deduce dal repository: decisioni prese a voce, trappole dell'ambiente che costano mezz'ora se le scopri da solo, il livello di rigore atteso nelle verifiche, e i limiti noti del materiale ricevuto.

## Regola prima di tutte

**Il lavoro sul backlog segue il processo in [`docs/WORKFLOW.md`](docs/WORKFLOW.md).** Quando ti viene chiesto di implementare una storia (`US-XXX`), esegui il ciclo completo: planning → branch → implementazione → verifica → review → via libera → merge → chiusura. Non saltare fasi, non anticipare il merge.

Per avviare il ciclo su una storia: `/gymflow-story US-XXX`.

**La grafica segue i mockup, non l'inventiva.** I tre mockup approvati sono in [`docs/design/`](docs/design/) e il loro estratto operativo — valori già convertiti in dp — è in [`docs/DESIGN-SPEC.md`](docs/DESIGN-SPEC.md). Prima di scrivere un widget che si vede, si guarda lì. **I pixel dei mockup non si copiano**: il telaio è largo 282 px e il telefono 384 dp, quindi `dp ≈ px × 1,36`.

**Il baseline degli avvisi è 56.** Una storia che lo alza ha introdotto qualcosa: va sistemato prima del merge, non spiegato dopo. (Era 66 fino a US-071, 63 fino a US-066, che ne ha tolti sette riscrivendo la schermata delle misure.)

**Un calo va spiegato quanto un aumento.** In US-047 il calo veniva da un rifacimento fuori mandato, in US-066 dal codice che la storia riscriveva davvero: la differenza si vede solo confrontando l'**elenco** degli avvisi con quello di `main`, non il totale.

**Quando un criterio non è verificabile, dichiaralo.** Non spuntarlo. Ogni review fatta finora ha una sezione sui limiti, ed è quella che rende credibile il resto.

## Comandi

L'SDK Flutter non è nel PATH di sistema. Anteponi il percorso, oppure usa il binario completo:

```bash
C:/Users/s.ferrero/Flutter/bin/flutter.bat analyze
```

| Azione | Comando |
|---|---|
| Analisi statica | `flutter analyze` |
| Test | `flutter test` |
| Build APK per prova su telefono | `flutter build apk --debug` |
| Esecuzione (non usata nel ciclo: prova sull'APK) | `flutter run -d emulator-5554` |
| Avvio emulatore | `%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe -avd Medium_Phone_API_36.1` |
| Codice generato (Riverpod, Isar) | `dart run build_runner build --delete-conflicting-outputs` |

**Target attivo: Android.** Il Web non compila (Isar genera interi a 64 bit non rappresentabili in JavaScript) ed è accantonato in EP-008. Windows desktop non è compilabile: manca Visual Studio.

## Struttura

```
lib/src/
├── core/
│   ├── providers/    provider Riverpod (+ file .g.dart generati)
│   ├── theme/        tema dell'applicazione
│   └── utils/        funzioni pure di calcolo
├── models/           modelli di dominio, modelli locali Isar, mapper
├── services/         accesso a Firebase, salute, timer
└── ui/
    ├── screens/      una schermata per file
    └── widgets/      componenti riutilizzabili
```

## Convenzioni

**Stato e dipendenze**
- Riverpod è il sistema di riferimento. `package:provider` è in via di rimozione: non aggiungerne usi nuovi.
- Non istanziare i servizi direttamente nelle schermate. Prendili dai provider. `FirestoreService()` dentro un `build` è un errore.
- Rigenera il codice con `build_runner` dopo aver modificato provider o modelli Isar. Non modificare a mano i file `.g.dart`.

**Widget**
- Mai creare uno `Stream` o un `Future` dentro `build`: si ricrea a ogni rebuild. Vanno in `initState` o in un provider.
- Nessun effetto collaterale in `build`: niente scritture su controller, niente navigazione, niente chiamate di rete.
- Ogni `TextEditingController`, `AnimationController`, `ScrollController` e sottoscrizione va rilasciato in `dispose`.
- Usa `const` ovunque il compilatore lo consenta.

**Interfaccia**
- La direzione è **Material 3 Expressive** (EP-005). Flutter non lo supporta: i token vivono in una `ThemeExtension` interna. Leggi da lì, non usare valori numerici.
- Colori dai ruoli del `ColorScheme`. Nessun colore letterale nei widget.
- Niente `withOpacity`: è deprecato.
- Ogni stringa visibile passa dalla localizzazione, con la chiave presente sia in EN sia in IT.

**Dati**
- Le query Firestore con `whereIn` hanno un limite di dieci elementi. Suddividi in gruppi: non troncare.
- Il database Firestore usato è `gymflow`, non quello predefinito.

**Git**
- Un branch per storia, sempre da `main` aggiornato: `feature/US-XXX-slug`.
- Messaggi di commit in italiano, con il riferimento alla storia: `US-010: sposta lo stream fuori da build()`.
- Mai committare su `main` direttamente: si entra solo con `merge --squash` da un branch di storia, dopo il via libera.
- Niente pull request: il branch resta locale, non si pusha, e si cancella dopo il merge.
- **`dev` è uno specchio di `main`**, non un branch di integrazione. Dopo ogni merge va riallineato in fast-forward. Non si sviluppa su `dev`, non ci si mergiano feature.
- Il ciclo di una storia è eseguito da **un solo agente**, tutte le fasi, senza delegare.
- **Nessuna attribuzione ad AI nei messaggi di commit**: niente trailer `Co-Authored-By` verso assistenti, niente firme automatiche, nessun riferimento a come il codice è stato prodotto.

## Chiedi sempre prima di

- Mergiare in `main`
- Aggiungere una dipendenza a `pubspec.yaml`
- Modificare le regole Firestore, i workflow CI o la configurazione Firebase
- Uscire dai file previsti dal piano della storia in corso
- Riattivare il deploy web (sospeso da US-039, si riprende con EP-008)

## Da non toccare

- `gymflow-d5d09-*.json` — chiave di service account, esclusa da git. Non committarla, non stamparne il contenuto.
- `lib/firebase_options.dart` — generato da FlutterFire CLI.
- `**/*.g.dart` — generati da build_runner.

## Documenti di riferimento

| File | Cosa contiene |
|---|---|
| [`docs/HANDOFF.md`](docs/HANDOFF.md) | Stato, decisioni prese, trappole, domande aperte. **Da leggere per primo.** |
| [`docs/BACKLOG.md`](docs/BACKLOG.md) | 69 storie con dipendenze, blocchi e stato |
| [`docs/WORKFLOW.md`](docs/WORKFLOW.md) | Il processo per ogni storia |
| [`docs/DESIGN-SPEC.md`](docs/DESIGN-SPEC.md) | **Le specifiche visive estratte dai mockup**, con la conversione px → dp |
| [`docs/design/`](docs/design/) | I tre mockup approvati, in HTML: si aprono in un browser |
| [`docs/adr/001-material-3-expressive.md`](docs/adr/001-material-3-expressive.md) | Perché Material 3 Expressive è costruito e non installato |
| `docs/planning/US-XXX.md` | Piano di ogni storia affrontata |
| `docs/planning/US-XXX-review.md` | Review, con i limiti dichiarati |

## Stato del progetto

Il backlog è in [`docs/BACKLOG.md`](docs/BACKLOG.md): **71 storie, 15 epiche, 224 punti**, di cui 19 completate. Ogni storia riporta `Depends on`, `Blocks` e `Status`. Una storia è eseguibile quando tutte quelle in `Depends on` sono `✅ DONE`.

**Direzione visiva: palette Indigo, app scura per impostazione predefinita.** Ambra `#F0C38E` significa sempre e solo "cosa fare adesso"; salmone `#F1AA9B` è riservato ai dati vitali. Tenerli distinti è deliberato: se l'ambra compare su qualcosa che non è un'azione, perde la sua funzione.

Debito noto e già tracciato — non aprire storie nuove per queste, esistono già:

| Debito | Storia |
|---|---|
| Stream ricreati dentro `build` in undici punti | US-010, US-011, US-012 |
| 61 istanziazioni dirette dei servizi nelle schermate | US-008, US-009 |
| Regole Firestore non versionate | US-018 |
| 63 avvisi dell'analyzer | US-030 |
| Ticker del timer sempre attivo a 30 ms | US-013 |
| Limite `whereIn` a 10 non gestito | US-019, US-020 |

**Debito visibile a schermo**: l'app è diventata scura con US-034, ma le schermate contengono ancora `Colors.grey[...]` ereditati dal fondo chiaro. **Alcuni testi secondari appaiono sbiaditi**: lo sistemano US-022 e US-023. Se l'utente lo segnala, è questo — non un difetto nuovo.

Già risolti, non riaprirli: doppio state management (EP-002), controller non rilasciati (US-014), API deprecate (US-024), assenza di CI e test (US-029), build release rotta (US-040).
