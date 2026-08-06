# Review US-007

**Verdetto:** APPROVATA CON RISERVE
**Data:** 2026-08-06 · **Diff:** 9 file di codice, `pubspec.yaml`, 1 generato

> La riserva **non riguarda il codice della storia**, che è completo e verificato, ma il fatto che un criterio — il comportamento dell'overlay — sia verificabile solo provando l'APK. Vedi in fondo.

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| Stato di cronometro e timer da un provider Riverpod | ✅ | `TimerNotifier` annotato `@Riverpod(keepAlive: true)`, stato `TimerState` immutabile |
| L'overlay continua a comparire, essere trascinabile e controllabile | ⏳ | **Da confermare sull'APK.** Compila; logica di visibilità, trascinamento e comandi non modificate |
| `MultiProvider` rimosso da `app.dart` | ✅ | `app.dart` è ora 28 righe: solo `MaterialApp`. Zero occorrenze di `MultiProvider` in `lib/` |
| Dipendenza `provider` rimossa da `pubspec.yaml` | ✅ | Assente; `flutter pub get` completa; **zero import di `package:provider` in tutto `lib/`** |
| Doppio `@override` su `build` corretto | ✅ | Risolto in US-005; riconfermato sul file attuale |

**Il debito `legacy` introdotto da US-005 e US-006 è stato interamente estinto**: cinque prefissi rimossi, nessun residuo.

## Rilievi

### 🔴 Bloccanti

Nessuno.

### 🟡 Da valutare

1. **La build release fallisce — difetto preesistente, scoperto qui.** `flutter build apk --release` si interrompe su `:isar_flutter_libs:verifyReleaseResources` con `AAPT: error: resource android:attr/lStar not found`.

   **Non è causato da questa storia**: nessuna modifica tocca la configurazione Android o le dipendenze native, e il difetto riguarda `isar_flutter_libs`, presente da prima. Non era mai emerso perché nessuno aveva provato una build release da gennaio — l'ultimo `app-release.apk` sul disco è datato 28 gennaio 2026.

   **Aperta US-040** (HIGH, 2pt) con diagnosi e piste di soluzione. Non risolto qui: sarebbe stato un intervento sulla configurazione Gradle, fuori dai file previsti dal piano e da una storia che parla di state management.

   Conseguenza pratica: la prova si fa con un pacchetto di debug, 101 MB contro i 57 dell'ultima release riuscita.

### 🔵 Suggerimenti

2. **I getter di comodo sul notifier** (`isStopwatchRunning`, `stopwatchElapsed`, …) leggono `state` e permettono ai consumatori di continuare a scrivere `service.X` sia per le letture sia per i comandi. Senza, ognuno dei circa trenta usi in `time_tools_screen` andava riscritto distinguendo `ref.watch` da `ref.read(...notifier)`: un diff molto più grande e molto più facile da sbagliare.

3. **Il ticker resta a 30 ms sempre attivo**, deliberatamente. È un difetto noto e tracciato in **US-013**, che questa storia sblocca. Correggerlo qui avrebbe reso impossibile distinguere una regressione della migrazione da un cambio voluto di comportamento.

4. **Il ciclo di vita del ticker** passa da `dispose()` a `ref.onDispose()`, con annullamento esplicito e azzeramento del riferimento.

5. **Gli avvisi sono scesi a 66, uno in meno del baseline**: la rimozione di `package:provider` ha eliminato anche un import inutilizzato preesistente.

## Fuori scope rilevato

Un'estensione rispetto alla lettera del piano: la migrazione di `FirestoreService` in tre file. Era **necessaria**, non opzionale — finché `FirestoreService` restava registrato nel `MultiProvider`, quel `MultiProvider` non poteva essere rimosso, e la sua rimozione è metà della storia. Ha usato `firestoreServiceProvider`, che già esisteva inutilizzato.

Le 61 istanziazioni dirette dei servizi restano intatte: sono US-008 e US-009.

## Regressioni sospette

| Verifica | Esito |
|---|---|
| `flutter analyze` | **66 issue, zero errori** — uno in meno del baseline di 67 |
| `flutter test` | **15 test, tutti verdi** |
| `flutter build apk --debug` | Completa: `app-arm64-v8a-debug.apk`, 101 MB |
| `flutter build apk --release` | **Fallisce** — difetto preesistente, vedi rilievo 1 e US-040 |
| `flutter pub get` dopo la rimozione | Completa senza conflitti: nessun pacchetto dipendeva da `provider` come diretta |
| Import residui | Zero `package:provider` in `lib/` |

## Riserva, esplicita

Il comportamento dell'overlay flottante — comparsa, trascinamento, comandi di avvio, pausa e azzeramento — **non è stato verificato in esecuzione**. Il processo non prevede più l'avvio su emulatore e la build release non è disponibile.

Ciò che è dimostrato: il codice compila, la logica di visibilità e le richiamate dei comandi sono invariate, lo stato è `keepAlive` quindi il cronometro sopravvive ai cambi di schermata. Ciò che non è dimostrato: che a schermo si comporti come prima.

**È il punto da provare per primo sull'APK.** Aprire gli strumenti tempo, avviare il cronometro, uscire dalla schermata e controllare che l'overlay compaia, si trascini e risponda ai comandi.
