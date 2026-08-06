# Review US-040

**Verdetto:** APPROVATA
**Data:** 2026-08-06 · **Diff:** 1 file di configurazione (`android/build.gradle.kts`)

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| `flutter build apk --release` termina con exit code 0 | ✅ | Build da `flutter clean`: tre pacchetti prodotti |
| Il pacchetto si installa e si avvia su un telefono reale | ⏳ | **Da confermare sull'APK**: nessun dispositivo collegato (`adb devices` vuoto) |
| `flutter build apk --debug` continua a funzionare | ✅ | Eseguita dopo la correzione, completa |
| La causa è documentata nel file toccato | ✅ | 18 righe di commento: diagnosi, perché solo in release, perché non cambia il runtime, quando rimuoverlo |
| La dimensione del pacchetto è riportata | ✅ | arm64-v8a **25,9 MB** · armeabi-v7a 22,7 MB · x86_64 27,7 MB |

## Verifica A/B — il punto centrale di questa review

La domanda che conta: **è stato il fix a risolvere, o il `flutter clean` che l'ha accompagnato?** Una correzione di build che funziona per motivi diversi da quelli creduti è peggio di nessuna correzione.

Verificato disattivando il fix e ricostruendo da pulito:

| Configurazione | Esito |
|---|---|
| Soglia `current < 0` — il blocco non scatta mai, tutto il resto identico | ❌ `AAPT: error: resource android:attr/lStar not found` su `:isar_flutter_libs:verifyReleaseResources` |
| Soglia `current < 31` — blocco attivo, da `flutter clean` | ✅ tre pacchetti prodotti |

**Il fix è necessario e sufficiente.** Il `flutter clean` non c'entra: entrambe le prove partono da pulito.

## Rilievi

### 🔴 Bloccanti

Nessuno.

### 🟡 Da valutare — emerso e corretto durante l'implementazione

1. **Primo tentativo fallito per ordine di valutazione.** Il blocco era stato messo dopo `subprojects { project.evaluationDependsOn(":app") }`, che forza la valutazione dei sottoprogetti: Gradle rifiutava con `Cannot run Project.afterEvaluate(Action) when the project is already evaluated`.
   **Corretto** spostandolo prima di quel blocco. È una dipendenza d'ordine fragile: se qualcuno riordinasse il file, tornerebbe a rompersi. Il commento non lo dice — ma l'errore di Gradle è immediato ed esplicito, quindi non può passare inosservato.

### 🔵 Suggerimenti

2. **Il blocco è condizionale, non una forzatura.** Tocca solo i moduli sotto la soglia: se un aggiornamento futuro di Isar alzasse il proprio `compileSdk`, diventerebbe inerte da sé invece di continuare a imporre un valore. Il commento indica la condizione di rimozione.

3. **`compileSdk` non è `minSdk`.** Alzare il primo cambia la piattaforma con cui il modulo viene compilato, non i dispositivi su cui gira. La compatibilità con Android vecchi dichiarata da Isar resta intatta.

4. **La release è firmata con la chiave di debug**, come dichiara il `TODO` in `app/build.gradle.kts`. Va bene per le prove interne; una chiave vera serve solo per la distribuzione sugli store, che non è in programma. Non toccato: fuori scope.

5. **Guadagno concreto sulla dimensione**: 25,9 MB contro i 101 MB del pacchetto debug arm64. Il pacchetto passa da scomodo a trasferibile.

## Fuori scope rilevato

Nessuno. Un solo file toccato, quello previsto. Nessuna modifica a codice Dart, dipendenze o configurazione Firebase.

## Regressioni sospette

| Verifica | Esito |
|---|---|
| `flutter build apk --release` | ✅ tre pacchetti, da `flutter clean` |
| `flutter build apk --debug` | ✅ completa: la correzione non rompe il percorso che già funzionava |
| `flutter analyze` | 66 issue, **zero errori** — invariato |
| `flutter test` | **15 verdi** |
| Comportamento a runtime | `minSdk` non toccato; solo la piattaforma di compilazione cambia |

## Cosa resta da confermare

L'installazione e l'avvio su un telefono reale. Il pacchetto è prodotto e firmato, ma nessun dispositivo era collegato durante la verifica (`adb devices` vuoto). **È il primo controllo da fare sull'APK.**
