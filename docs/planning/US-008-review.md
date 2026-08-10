# US-008 — Review

**Data:** 2026-08-10 · **Branch:** `refactor/US-008-inject-services-main-screens`
**Commit rivisti:** `c229d7f` (consegna) + `dd042e2` (correzione fatta in review)
**Chi ha implementato:** Gemini · **Chi rivede:** non ha scritto il codice

**Verdetto: APPROVATA CON RISERVE** — un rilievo, ed è esattamente quello che il piano
annunciava nella tabella dei rischi. Corretto in review. Per il resto è la consegna
tecnicamente migliore ricevuta finora: **il test di montaggio fa lavoro vero**, e l'ho
dimostrato.

---

## Numeri, misurati nel worktree

| | Dichiarato | Misurato |
|---|---|---|
| `flutter analyze` | 55 avvisi | **55** |
| `flutter test` | 450 verdi | **450** |
| File toccati | 4 | 4, tutti previsti dal piano (+1 in review, dichiarato sotto) |

### Il calo di un avviso è spiegato, e legittimo

Il baseline è 56 e la consegna ne dichiara 55. **Un calo va spiegato quanto un aumento**, e si
spiega solo confrontando l'elenco. Fatto: la differenza è una riga sola.

```
warning - Unused import: '../../core/providers/auth_provider.dart'
          - lib\src\ui\screens\dashboard_screen.dart:17:8 - unused_import
```

`dashboard_screen.dart` **importava già** `auth_provider.dart` senza usarlo — l'import era stato
lasciato lì da una storia precedente, con il commento «Use AuthService directly to avoid provider
generation issues» a spiegare perché non se ne faceva niente. Questa storia lo usa, quindi
l'avviso sparisce.

**Viene dal codice che la storia riscriveva davvero**, non da un rifacimento fuori mandato: è la
distinzione che in US-047 e US-066 ha diviso un calo legittimo da uno sospetto. Tutte le altre
differenze fra i due elenchi sono scorrimenti di numero di riga. **Nessun avviso nuovo.**

Il baseline del progetto scende a **55**.

---

## 🟡-1 · Il saluto della dashboard mostrava «Atleta» per un frame — corretto

Il piano dedicava a questo un rischio contrassegnato con la stella, e la consegna vi è finita
dentro. Non per distrazione: il rapporto dichiara la scelta e la motiva.

> **Utente:** `currentUserIdProvider` in tutte e tre le schermate […]; `currentUserProvider` in
> `dashboard_screen.dart` per recuperare `displayName` ed email della stringa di benvenuto,
> gestendo il null iniziale con il fallback preesistente `loc.t('athlete')`.

Il ripiego `loc.t('athlete')` **è** il difetto, non la sua soluzione. `dashboard_screen.dart:71-73`:

```dart
final user = ref.watch(currentUserProvider);
final userName = user?.displayName ?? user?.email?.split('@')[0] ?? loc.t('athlete');
```

`currentUserProvider` era `ref.watch(authStateProvider).value`, e `authStateProvider` è uno
**stream**: al primo build non ha ancora emesso, quindi `.value` è `null` **anche a utente
autenticato**. Prima la dashboard leggeva `AuthService().currentUser`, che risponde subito dal
client Firebase già inizializzato. Dopo, il saluto dice «Ciao, Atleta» e un istante più tardi il
nome vero — sulla prima schermata che si vede aprendo l'app.

Va detta la proporzione: **è un frame, forse pochi**, non una schermata rotta. Ma è una
regressione visibile introdotta da un refactoring che non doveva cambiare niente, e non c'è test
che la prenda.

**Corretto in `dd042e2`**, e non nella dashboard: nel provider. `currentUserIdProvider`, **tre
righe più sotto nello stesso file**, ha sempre avuto il ripiego sincrono —

```dart
return asyncUser.value?.uid ?? AuthService().currentUser?.uid;
```

— e l'asimmetria fra i due non aveva motivo. Ora `currentUserProvider` fa la stessa cosa, quindi
il difetto è chiuso per chiunque legga quel provider e non solo per la dashboard. Oggi la
dashboard è l'unico consumatore (`grep` su `lib/`), quindi il rischio di regressione altrove è
nullo.

**Fuori piano, dichiarato**: `lib/src/core/providers/auth_provider.dart` non era fra i quattro
file del piano. È una riga, **non aggiunge nessun provider** — quindi il baseline non si muove — e
non richiede di rigenerare il `.g.dart`, perché la firma della funzione non cambia.

---

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| Nessuna istanziazione diretta nelle tre schermate | ✅ | Nove test sul sorgente, tre per file. **Provato** rimettendo `FirestoreService()` in `_confirmDelete`: rosso |
| ⭐ Un servizio finto sostituisce quello vero | ✅ | `ProgramListScreen` montata con `firestoreServiceProvider.overrideWithValue`, e il finto **risulta chiamato**. Vedi sotto: l'ho verificato io |
| Il comportamento non è cambiato | ✅ *dopo la correzione* | I 440 test preesistenti restano verdi e nessuno è stato modificato. Il saluto della dashboard **era** cambiato: 🟡-1 |
| La grafica non è cambiata | ✅ | `design_system_usage_test.dart` verde, e `program_list_screen.dart` è fra le schermate che sorveglia |

### Il test di montaggio non è di facciata, e l'ho dimostrato

È la prima volta che una delega consegna un test che monta il widget vero con un doppio, invece
di un test sul sorgente. Quindi la domanda che conta è se fa lavoro o se decora. Due mutazioni,
applicate al file vero e verificate presenti prima di lanciare:

| Mutazione | Test sul sorgente | Test di montaggio |
|---|---|---|
| Lo `StreamBuilder` smette di chiamare il servizio: `stream: Stream.value(const [])` | ✅ **verde** — nessun `FirestoreService()` da trovare | 🔴 **rosso**: «il servizio finto non è stato chiamato — l'iniezione non funziona» |
| `_confirmDelete` torna a `FirestoreService().deleteProgram(...)` | 🔴 **rosso** | ✅ verde — quel percorso il montaggio non lo tocca |

**Le due guardie sono complementari, e nessuna delle due basta da sola.** La prima mutazione è
quella che conta: un aggiramento invisibile a qualunque ricerca sul sorgente, preso solo dal
montaggio. È il tipo di prova che in questo progetto mancava.

### Il limite dichiarato dall'esecutore, e verificato

Il rapporto dice che `DashboardScreen` e `CalendarScreen` non si montano perché dipendono da
`isarDatabaseProvider` e `sessionSyncProvider`. **È vero e va tenuto**: dichiarare un ostacolo con
il nome del provider che lo causa vale più di un test in meno, ed è ciò che il piano chiedeva
esplicitamente («se una schermata non si monta nemmeno così, dillo»).

Conseguenza da mettere agli atti: **due schermate su tre restano coperte solo da test sul
sorgente.** L'iniezione lì è verificata come *scrittura*, non come *funzionamento*. Renderle
montabili è lavoro per US-009 o per una storia sua.

---

## 🔵 Rilievi minori, nessuno bloccante

| | Dove | Cosa |
|---|---|---|
| 1 | `calendar_screen.dart:41` | `ref.watch(firestoreServiceProvider)` dentro `_getCalendarEvents`, che non è `build`. Funziona perché il metodo è chiamato **da** `build`, ma se un domani venisse chiamato da un gestore solleverebbe. `read` sarebbe più robusto: il provider del servizio non cambia mai |
| 2 | `calendar_screen.dart:350` | `bool isMine = ownerId == ref.read(currentUserIdProvider);` è una lettura di stato in un percorso di disegno: con `read` non si ridisegna se l'utente cambia. Equivalente al `_auth.currentUser?.uid` di prima, quindi non è una regressione |
| 3 | `calendar_screen.dart:291` | `ref.read(currentUserIdProvider)!` con il punto esclamativo. Identico al `_auth.currentUser!.uid` precedente, e `build` esce prima se l'id è nullo |
| 4 | `service_injection_test.dart:34` | `noSuchMethod(invocation) => super.noSuchMethod(invocation)` solleva per qualunque metodo non stubbato. Va bene per questo test, ma chi lo estenderà si troverà un `NoSuchMethodError` invece di un messaggio utile |
| 5 | `dashboard_screen.dart:69` | Resta il commento «Legacy provider» sopra `localizationNotifierProvider`, che non è legacy. Preesistente |

---

## Checklist adversariale

| Voce | Esito |
|---|---|
| È stato creato un provider nuovo? | **No** — era il rischio con la stella nel piano: uno scritto come funzione avrebbe aggiunto un typedef deprecato e sfondato il baseline |
| Servivano modifiche ai `.g.dart`? | No, e non sono stati toccati |
| Gli stream sono stati spostati fuori da `build`? | **No**, e va bene: sono US-011 e US-012. Il diff resta leggibile come «da dove viene il servizio», che era il mandato |
| `active_session_screen.dart` è stato aperto? | No — era il vincolo per non collidere con US-082 |
| `localization_provider.dart` è stato aperto? | No — era il vincolo per non collidere con US-027 |
| `HealthService.configure()` precede ancora la lettura? | Sì, `dashboard_screen.dart:45-47`: l'ordine è conservato, e le **tre** istanze diverse sono diventate una |
| Le tre schermate erano già `Consumer`? | Sì, come il piano aveva verificato: nessun widget convertito, nessuna firma cambiata |
| Risorse non rilasciate? | Nessun controller o sottoscrizione nel diff |
| Segreti, percorsi locali, avanzi di Gradle nei commit? | Nessuno |

---

## Limiti dichiarati di questa review

1. **Non ho aperto l'app.** Che il saluto della dashboard mostri il nome dal primo frame dopo la
   correzione è dedotto dal codice, non visto: `AuthService().currentUser` risponde in modo
   sincrono, quindi il ripiego copre il buco — ma un frame si giudica guardandolo.
2. **Due schermate su tre non sono montate da nessun test**, e la loro iniezione è verificata solo
   come testo del sorgente. È il limite dichiarato dall'esecutore, e resta aperto.
3. **Non ho verificato che il calendario funzioni ancora.** È la schermata col diff più grosso —
   37 righe, quattro stream combinati — e nessun test la monta. Se qualcosa si è rotto lì, si vede
   solo sull'APK: aprire il calendario, vedere gli eventi, programmare un allenamento, cancellarlo
   con lo scorrimento.
4. **Non ho misurato se qualcosa è diventato più lento.** `ref.watch(firestoreServiceProvider)`
   dentro `build` ricostruisce la sottostruttura quando il provider cambia; il provider non cambia
   mai, quindi in teoria è gratis. In teoria.
5. **I 55 avvisi** non sono stati esaminati: sono il debito di US-030, che ora ne ha uno in meno.

---

_Review di fase 5 · US-008 · su codice non scritto da chi rivede_
