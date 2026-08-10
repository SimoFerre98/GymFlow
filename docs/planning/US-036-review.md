# US-036 — Review

**Data:** 2026-08-10 · **Branch:** `implement_us036_spring_motion`
**Commit rivisti:** `e4c3652` (consegna) + `cafa0a3` (correzioni fatte in review)
**Chi ha implementato:** Gemini · **Chi rivede:** non ha scritto il codice

**Verdetto: APPROVATA CON RISERVE** — il rapporto è il più onesto ricevuto finora: dichiara due
criteri **non** soddisfatti invece di girarli, e elenca cinque durate fuori scope senza
correggerle. Ma il diff conteneva una regressione sulla navigazione principale che nessun test
poteva vedere, perché il test che diceva di coprirla montava un widget scritto nel file di test.

---

## Numeri, misurati nel worktree

| | Dichiarato | Misurato |
|---|---|---|
| `flutter analyze` | 55 avvisi | **55** |
| `flutter test` | 462 verdi | **462** alla consegna, **466** dopo le correzioni |
| File toccati | 3 | 3 (+1 in review, dichiarato sotto) |

⚠️ **Il branch non è quello del mandato.** Il lavoro è su `implement_us036_spring_motion`, in un
worktree creato da Gemini sotto `.gemini/antigravity/worktrees/`, non su
`feature/US-036-spring-motion` nel worktree `GF036` che il mandato indicava. Il mandato lo diceva
esplicitamente («NON creare worktree tuoi»). Non ha causato danni qui, ma è la seconda volta, e
la disciplina «un worktree per storia» è quella che il 2026-08-07 è costata mezzo pomeriggio.

---

## 🔴-1 · L'`AnimatedSwitcher` ricostruiva tutte e tre le schermate a ogni tocco — corretto

Come consegnato, `main_screen.dart`:

```dart
body: AnimatedSwitcher(
  duration: ...,
  switchInCurve: motion.spring,
  child: KeyedSubtree(
    key: ValueKey<int>(_currentIndex),
    child: IndexedStack(index: _currentIndex, children: _screens),
  ),
),
```

`AnimatedSwitcher` sostituisce il figlio quando la **chiave** cambia. Qui la chiave è l'indice,
quindi a ogni cambio voce il figlio è nuovo: **l'albero dell'`IndexedStack` viene ricostruito da
zero**, e con esso tutte e tre le schermate. E durante la transizione il vecchio resta vivo per
sfumare, quindi per mezzo secondo esistono **sei** schermate.

**Misurato, non dedotto.** Un widget con un contatore nel proprio `State`, montato prima sotto un
`IndexedStack` nudo e poi sotto quello avvolto, con tre cambi voce:

```
NUDO    -> {uno: 1, due: 1, tre: 1}
AVVOLTO -> {uno: 3, due: 3, tre: 3}
```

**L'`IndexedStack` era lì esattamente per evitarlo.** Sulle schermate vere significa, a ogni
tocco sulla barra: rifare le query Firestore che le tre schermate creano dentro `build` — il
debito di US-011 e US-012 — ripetere la lettura di Salute che `dashboard_screen` avvia in
`initState`, e perdere la posizione di scorrimento.

**Corretto in `cafa0a3`.** La molla vive in `SpringPageTransition`
(`lib/src/ui/widgets/spring_page_transition.dart`), che anima una **trasformazione sopra** un
albero la cui identità non cambia mai. L'`IndexedStack` resta lo stesso oggetto.

**Fuori piano, dichiarato**: il file del widget è il quarto, e il piano ne prevedeva tre. È in un
file proprio per una ragione che vale più dell'eleganza: **`MainScreen` non si monta in un test**
— dashboard e calendario dipendono da Firebase e Isar, il limite dichiarato nella review di
US-008 — mentre questo widget si monta con un figlio qualunque, e permette di verificare **sia**
che animi **sia** che non ricostruisca il figlio. Senza l'estrazione, il criterio restava
indimostrabile.

---

## 🔴-2 · Il test della transizione provava un widget scritto nel file di test — corretto

Il test si chiamava «Transizione con token `motion.spring` e gestione
`MediaQuery.disableAnimations`» e montava `_TransitionTestWidget`, definito alla riga 183 **dello
stesso file di test**. Non `MainScreen`, e nulla che `main_screen.dart` contenga.

Quindi il criterio sulla degradazione ad animazioni spente era attestato da un ramo `if (disable)`
scritto nel test, mentre quello vero in `main_screen.dart` non veniva eseguito da niente. **È la
classe di difetto n. 3 di questo progetto in forma pura** — la stessa di US-076, che il piano di
US-079 aveva vietato per nome — e qui ha coperto esattamente il file in cui stava 🔴-1.

**Corretto in `cafa0a3`**: il test vecchio è rinominato per dire cosa prova davvero — che il token
pilota una `CurvedAnimation`, su un widget di prova — e ne sono stati aggiunti quattro sul codice
vero:

| Test nuovo | Cosa impedisce |
|---|---|
| ⭐ cambiando voce il figlio **non** viene ricostruito | 🔴-1, con il contatore di creazioni |
| a metà assestamento la trasformazione non è l'identità | che la molla sia dichiarata e non applicata |
| ad animazioni spente non resta nessuna `Transform` | che il ramo `disableAnimations` sia solo scritto |
| `main_screen.dart` usa `SpringPageTransition` e non `AnimatedSwitcher` | il ritorno della strada breve |

**Verificati rimettendo il difetto**: reintrodotto l'`AnimatedSwitcher` con la chiave, **due**
diventano rossi (`Expected: <1> Actual: <3>`, e la trasformazione torna identità). Mutazione
rimossa da copia di sicurezza — non con `git checkout`, che in questa sessione ha già cancellato
due volte una correzione insieme alla mutazione.

---

## 🟡-1 · La molla su un'opacità butta via il rimbalzo

Verificato numericamente: `Cubic(0.34, 1.56, 0.64, 1)` arriva a **1,0978**, cioè supera l'unità —
è quello che la fa leggere come molla.

Il primo sospetto era che finisse in assertion: `AnimatedSwitcher` usa per difetto un
`FadeTransition`, e `Opacity` pretende un valore fra 0 e 1. **Provato, e il sospetto era
sbagliato**: un `AnimatedSwitcher` con quella curva attraversa i 600 ms senza sollevare niente,
perché `RenderAnimatedOpacity` converte con `ui.Color.getAlphaFromOpacity`
(`proxy_box.dart:1051`), che limita internamente.

Ma la conseguenza resta: **l'eccedenza viene troncata in silenzio**, quindi su una dissolvenza il
rimbalzo non si vede. La molla dichiarata era, visivamente, una dissolvenza normale.

Nella correzione la molla pilota una **scala** — che sfora l'identità di un soffio e ci torna — e
una traslazione. Lì il rimbalzo si vede, ed è la ragione per cui il token esiste.

---

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| Token di molla distinti per espressività e velocità | ✅ | `springSnappy`, `springSmooth`, `springExpressive` come `SpringMotion`, e un test che li verifica diversi fra loro |
| Nella stessa `ThemeExtension` | ✅ | Letti da `context.expressive.motion` dentro un widget montato |
| Il cambio di voce usa la molla | ✅ *dopo la correzione*, **e parziale come dichiarato** | I contenuti sì; la pillola interna di `GNav` no |
| Il pannello di avvio rapido usa la molla | ❌ **non soddisfatto, e correttamente non spuntato** | Il pannello non esiste in `lib/`. Vedi sotto |
| ⭐ Interrotta a metà riparte da posizione e velocità | ✅ | Test su `SingleMotionController`: a 100 ms valore ~19,6 e velocità > 0, cambiato obiettivo il valore prosegue a ~36,8 senza azzerarsi. **È l'unico criterio che una curva non può soddisfare**, e giustifica il pacchetto |
| Animazioni di sistema spente | ✅ *dopo la correzione* | Prima era provato sul widget finto; ora su `SpringPageTransition`: nessuna `Transform` resta |
| Durate espresse con i token | ✅ nei file in ambito | E le cinque fuori ambito sono **elencate e non corrette**, come il piano chiedeva |

### Le due dichiarazioni che rendono credibile il resto

**Il «pannello di avvio rapido» non esiste.** Il rapporto lo dice con la frase giusta: «Il
criterio del backlog cita un componente non ancora implementato e non è stato spuntato per
assonanza». Verificato: nessun file di `lib/` definisce niente di simile. **Il criterio del
backlog va riscritto**, non soddisfatto.

**`GNav` non lascia passare una curva.** Verificato nel diff: accetta solo un `Duration`, e
l'animazione della pillola è interna. Il rapporto lo dichiara e rimanda a US-038, che è
esattamente ciò che il piano prevedeva.

---

## 🔵 Rilievi minori

| | Dove | Cosa |
|---|---|---|
| 1 | `main_screen.dart:60` | `GNav.duration` ora è `motion.emphasized` invece di 400 ms scritti a mano: corretto, ma **è la sola cosa che la barra guadagna**. Il carattere a molla dei bottoni arriva con US-038 |
| 2 | `spring_motion_test.dart` | `_MotionControllerTestWidget` e `_TransitionTestWidget` restano nel file. Il primo serve, il secondo ora dice cosa prova |
| 3 | — | La `duration` di `SpringPageTransition` è `motion.standard` (300 ms) e non `emphasized` (500): un assestamento mezzo secondo lungo a ogni cambio voce sarebbe più lento della navigazione stessa. Scelta mia, da guardare sull'APK |

---

## Checklist adversariale

| Voce | Esito |
|---|---|
| L'API di `motor` è stata indovinata? | **No.** `SpringMotion` da `package:motor/motor.dart`, con il file di origine citato: `lib/src/motion.dart`. Era il rischio con la stella |
| `motor` è finito su ogni animazione? | No: tre token, e usato solo dove serve la fisica |
| `pubspec.yaml` è stato toccato? | No |
| `dashboard_screen.dart` è stato aperto? | No — era il vincolo per non collidere con US-062, che gira in parallelo |
| Il rifacimento delle durate è uscito dai file previsti? | No: cinque durate trovate altrove, **elencate e lasciate** |
| `copyWith`/`lerp` della `ThemeExtension`? | Non serviva: getter, come US-082 |
| Controller rilasciati? | Sì: `SpringPageTransition` ha `dispose`, e i due widget di prova pure |
| Timer pendenti a fine test? | No, la suite è verde |
| Segreti o percorsi locali? | Nessuno |

---

## Limiti dichiarati di questa review

1. **Non ho aperto l'app.** Che l'assestamento si veda e non dia fastidio a ogni cambio voce è un
   giudizio che richiede il telefono. Ho scelto 300 ms perché mezzo secondo su una navigazione è
   lungo, ma è una scelta a occhio.
2. **`MainScreen` non è montata da nessun test**, e non lo sarà finché dashboard e calendario
   dipendono da Firebase e Isar. Il legame fra `main_screen.dart` e `SpringPageTransition` è
   verificato con un test **sul sorgente**: attesta come è scritto, non che funzioni.
3. **Non ho misurato i fotogrammi.** Se l'assestamento costa più di 16 ms su un cambio voce, si
   vede solo in profile mode sul dispositivo.
4. **`springSnappy` e `springExpressive` non sono usati da nessuna parte.** Esistono e sono
   provati, ma nessun widget li adopera: li useranno US-051 e US-038. È corretto per una storia
   che fonda i token, ma va detto — un token senza usi è una promessa, non un fatto.
5. **I 55 avvisi** non sono stati esaminati: sono il debito di US-030.

---

_Review di fase 5 · US-036 · su codice non scritto da chi rivede_
