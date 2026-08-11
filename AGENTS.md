# GymFlow — istruzioni per chi lavora al codice

App Flutter per il tracciamento degli allenamenti. Backend Firebase, stato con Riverpod,
persistenza locale con Isar. Target attivo: **solo Android**.

Questo file è il briefing valido per **qualunque** assistente o strumento. Claude Code legge anche
[`CLAUDE.md`](CLAUDE.md), che contiene solo le sue specificità e rimanda qui: le regole stanno in un
posto solo, così non divergono.

---

## Se stai per scrivere codice, leggi prima questi

1. **[`docs/planning/US-XXX.md`](docs/planning/)** — il piano della storia che ti è stata
   assegnata. **È il tuo mandato**: dice cosa fare, quali file toccare, quali test scrivere e cosa
   resta fuori. Non è un suggerimento.
2. **[`docs/DESIGN-SPEC.md`](docs/DESIGN-SPEC.md)** — se tocchi qualcosa che si vede. I mockup in
   [`docs/design/`](docs/design/) sono la fonte autorevole della grafica, e **sono vincolanti**.
3. **[`docs/WORKFLOW.md`](docs/WORKFLOW.md)** — il ciclo completo, se non ti è chiaro cosa
   significa «finito».
4. **[`docs/HANDOFF.md`](docs/HANDOFF.md)** — trappole dell'ambiente che costano mezz'ora se le
   scopri da solo.

---

## Comandi

L'SDK Flutter **non è nel PATH**. Anteponilo:

```bash
export PATH="/c/Users/s.ferrero/Flutter/bin:$PATH"   # bash
$env:PATH = "C:\Users\s.ferrero\Flutter\bin;" + $env:PATH   # PowerShell
```

| Cosa | Comando |
|---|---|
| Analisi statica | `flutter analyze` |
| Test | `flutter test` |
| APK di prova | `flutter build apk --debug --target-platform android-arm64` |
| Installazione sul telefono | `adb install -r build/app/outputs/flutter-apk/app-debug.apk` |
| Codice generato (Riverpod, Isar) | `dart run build_runner build --delete-conflicting-outputs` |

**Non usare `flutter install`**: disinstalla l'app e cancella i dati dell'utente, che si ritrova
scollegato. `adb install -r` conserva tutto.

---

## Le cinque regole che fanno fallire una consegna

Sono le uniche non negoziabili. Tutto il resto è nel piano della storia.

### 1. Gli avvisi dell'analyzer non salgono

Il baseline è **14**. `flutter analyze` deve finire con lo stesso numero o meno. Uno in più
significa che hai introdotto qualcosa: si sistema prima di consegnare, non si spiega dopo.

**Il totale da solo non basta.** Confronta l'**elenco** con quello di `main`: due esecutori
hanno scambiato avvisi preesistenti per propri, e un calo puo venire dal codice che hai
riscritto — legittimo — oppure da un rifacimento fuori mandato, che non lo e.

### 2. I test passano tutti, e ne aggiungi

`flutter test` verde. Il piano dice quali test scrivere: un criterio di accettazione senza un test
che lo dimostri non è soddisfatto, è dichiarato.

### 3. Quello che non è verificabile si dichiara, non si spunta

È la regola che tiene in piedi tutto il resto. Se un criterio richiede un dispositivo, una misura o
un occhio umano, si scrive **«da confermare sull'APK»** e si lascia la casella vuota. Ogni review
del progetto ha una sezione sui limiti, ed è quella che rende credibile il resto.

### 4. Non esci dai file previsti dal piano

Un file in più è un segnale: o il piano era incompleto — e allora lo aggiorni spiegando perché — o
stai uscendo dallo scope. Quello che scopri strada facendo diventa una storia nuova, non
un'aggiunta silenziosa.

### 5. Non mergi in `main`

Lavori su un branch, lo pushi, e ti fermi. Il merge è una decisione umana, presa dopo la review.

---

## Convenzioni che l'analyzer non controlla

**Widget**
- Mai creare uno `Stream` o un `Future` dentro `build`: si ricrea a ogni ricostruzione.
- Nessun effetto collaterale in `build`.
- Ogni controller, sottoscrizione e timer va rilasciato in `dispose`.
- `const` ovunque il compilatore lo consenta.

**Interfaccia**
- Nessun colore letterale: i colori vengono dai ruoli del `ColorScheme`, e i valori stanno solo in
  `app_palette.dart`.
- Nessun valore numerico per spaziature, raggi e misure: vengono da `context.expressive`.
- Ogni stringa visibile passa dalla localizzazione, con la chiave **in EN e IT**. C'è un test che
  legge il sorgente e fallisce se ne aggiungi una senza tradurla.
- Niente `withOpacity`: è deprecato, si usa `withValues(alpha: …)`.

**Stato e dati**
- Riverpod è il sistema di riferimento. `package:provider` è in via di rimozione.
- Non istanziare i servizi nelle schermate: prendili dai provider.
- I provider si scrivono come **notifier di classe**, non come funzioni: il generatore, per le
  funzioni, emette un typedef deprecato e ti fa salire il baseline di due avvisi.
- Le query Firestore con `whereIn` reggono dieci elementi: si suddivide, non si tronca.
- Il database è `gymflow`, non quello predefinito.
- **Sulla collezione `exercises` il client scrive solo i propri esercizi.** Dopo US-018
  (`firestore.rules:107-112`) un utente può creare un documento che dichiara lui stesso come
  proprietario, e US-079 lo usa. Quello che resta negato è scriverci la **libreria curata**, che
  non appartiene a nessun utente: quella viaggia come asset e si fonde in lettura.

**Git**
- Un branch per storia, sempre da `main` aggiornato: `feature/US-XXX-slug-in-inglese`.
- Messaggi di commit **in italiano**, con il codice della storia in testa:
  `US-046: sposta lo stream fuori da build()`. Il corpo spiega **perché**, non cosa.
- **Nessuna attribuzione ad AI**: niente trailer `Co-Authored-By`, nessuna firma, nessun riferimento
  a come il codice è stato prodotto.

---

## Chiedi sempre prima di

- Aggiungere una dipendenza a `pubspec.yaml`
- Toccare le regole Firestore, i workflow CI o la configurazione Firebase
- Uscire dai file previsti dal piano
- Mergiare in `main`

---

## Da non toccare

- `gymflow-d5d09-*.json` — chiave di service account. Non committarla, non stamparne il contenuto.
- `lib/firebase_options.dart` — generato da FlutterFire CLI.
- `**/*.g.dart` — generati da build_runner. Si rigenerano, non si modificano.

---

## Cosa consegni

Un branch pushato, e un messaggio che riporta:

```
Storia:      US-XXX
Branch:      feature/US-XXX-slug
analyze:     <numero> avvisi (baseline 14)
test:        <numero> verdi
APK:         costruito / non costruito
Criteri:     quali soddisfatti, quali da confermare sul dispositivo e perché
Fuori piano: file toccati che il piano non prevedeva, con il motivo
Dubbi:       cosa non ti convince del tuo stesso lavoro
```

L'ultima riga è la più utile. Chi rivede sa già dove guardare se gliela scrivi.
