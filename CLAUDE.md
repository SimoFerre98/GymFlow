# GymFlow

App Flutter per il tracciamento degli allenamenti. Backend Firebase (Auth, Firestore, Storage), stato con Riverpod, persistenza locale con Isar.

## Regola prima di tutte

**Il lavoro sul backlog segue il processo in [`docs/WORKFLOW.md`](docs/WORKFLOW.md).** Quando ti viene chiesto di implementare una storia (`US-XXX`), esegui il ciclo completo: planning → branch → implementazione → verifica → review → via libera → PR → chiusura. Non saltare fasi, non anticipare il merge.

Per avviare il ciclo su una storia: `/gymflow-story US-XXX`.

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

## Stato del progetto

Il backlog è in [`docs/BACKLOG.md`](docs/BACKLOG.md): 39 storie, 8 epiche, 115 punti. Ogni storia riporta `Depends on`, `Blocks` e `Status`.

Debito noto e già tracciato — non aprire storie nuove per queste, esistono già:
- Doppio state management, Provider e Riverpod in parallelo (EP-002)
- Stream ricreati dentro `build` in tredici punti (EP-003)
- Controller mai rilasciati in sei file (US-014)
- Regole Firestore non versionate (US-018)
- Copertura di test quasi nulla (EP-007)
