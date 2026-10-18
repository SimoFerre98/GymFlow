# Review US-089

**Verdetto: APPROVATA CON RISERVE** — nessun rilievo bloccante sul codice. La riserva è una sola, ed è
grossa: **non l'ho vista girare su un telefono**. L'APK è costruito ma non installato (`adb` ha perso il
dispositivo), e la schermata non si è mai vista con dati veri né con due account.

La review è un'**autoverifica**: chi ha scritto il codice è anche chi lo rivede. Per compensare sono
partito dal diff (`git diff main...HEAD`, 17 file) e ho **rotto di proposito** il codice e le regole.

## Copertura dei criteri

| Criterio | Esito | Prova |
|---|---|---|
| L'elenco mostra i clienti con un legame accettato e attivo | ✅ funzione · ⬜ dati veri | `client_overview_test.dart`: ignora amici, legami dove il trainer non sono io, inviti in sospeso/rifiutati/sciolti; un cliente invitato due volte compare una volta (con il legame più recente, **anche se nella lista viene prima**) |
| Per ciascuno si vede quando si è allenato l'ultima volta | ✅ funzione e schermata · ⬜ dati veri | oggi / ieri / N giorni, in italiano e inglese (`clients_screen_test.dart`); la query `limit(1)` con `orderBy` passa al trainer con consenso e **è negata** senza (emulatore) |
| Chi non si allena da troppo tempo si distingue a colpo d'occhio | ✅ funzione e schermata | soglia provata sul confine (7 giorni no, 8 sì); in cima all'elenco; bordo, striscia, frase e numero nel colore `error`; **non solo colore**: la frase dice «Fermo da N giorni» |
| *(riscritto)* L'elenco regge dieci e venticinque clienti senza troncare | ✅ | `client_overview_loader_test.dart`: 25 clienti = 25 letture e 25 righe; le letture partono **tutte insieme** (massimo 25 in volo, non 1); chi non condivide non si legge |
| Un trainer senza clienti vede come invitarne uno | ✅ schermata | stato vuoto con spiegazione e pulsante che apre Connetti; si può «tirare per aggiornare» anche vuoto |
| *(trasversale)* Un atleta non vede il riquadro | ✅ | `home_shortcut_clients_test.dart`: atleta → 5 riquadri, nessun «CLIENTI»; anche con profilo in caricamento, assente o in errore |
| *(trasversale)* Chi non condivide non mostra una data | ✅ | `notShared`: nessun numero, nessun «OGGI»; nessuna lettura delle sue sessioni |

## Una correzione che devo dichiarare

Il piano, e la domanda che ti ho fatto per decidere il criterio 4, dicevano che **le regole negano una
`whereIn` su più clienti**. **Era falso e non l'avevo verificato.** L'ho scoperto scrivendo la prova
sull'emulatore: la query passa quando tutti i clienti hanno concesso gli allenamenti. Resta **negata**,
e ora c'è la prova, se anche uno solo non ha concesso (la sicurezza è intatta).

La decisione presa — una lettura per cliente — **regge comunque**, ma per una sola ragione e non per due:
una query unica con ordine e limite restituisce le sessioni più recenti *di tutti*, e il cliente fermo da
più tempo, cioè proprio quello che il trainer cerca, non compare (provato: «una whereIn … perde il più
fermo»). Senza il limite si scaricherebbe tutto lo storico di tutti. Piano, backlog e commenti sono
corretti, con la correzione scritta e non fatta sparire.

## Cosa ha trovato la rottura di proposito

Rotti uno alla volta soglia, filtri sul ruolo/stato/tipo, vincolo del consenso, ordine, blocco dei giorni
negativi, tetto a dieci, letture in fila, errori ingoiati, gating del riquadro: ogni volta un test è
diventato rosso. Due **buchi nei test** sono usciti da lì (il codice era giusto):
- il legame doppio passava per coincidenza, perché il più recente era anche l'ultimo della lista;
- un cliente che non condivide poteva mostrare un «OGGI» finto: nessun test guardava quel caso.
Entrambi chiusi, e riprovati.

Due mie mutazioni erano malfatte (una non compilava, l'altra equivaleva al codice vero): le ho rifatte
invece di contarle come «prese».

## Rilievi

### 🔴 Bloccanti
Nessuno sul codice.

### 🟡 Da valutare
1. **Il nome mostrato è quello del giorno dell'invito.** Viene da `invite.toDisplayName`, copiato quando
   il trainer ha invitato (per non leggere il profilo di un altro utente). Se il cliente cambia nome, il
   trainer vede quello vecchio. Non l'ho sistemato.
2. **L'«oggi» si calcola al caricamento.** Con la schermata aperta oltre mezzanotte i giorni restano
   quelli di prima fino al successivo «tira per aggiornare».
3. **Costo: 2 + N letture a ogni apertura** (due per i legami e i consensi, una per cliente che condivide).
   Il provider non resta in memoria uscendo dalla schermata. Dieci clienti = 12 letture; non l'ho misurato
   su dati veri.
4. **Fuso orario.** L'ultimo allenamento è salvato senza fuso (`toIso8601String` su ora locale del
   cliente) e confrontato per giorni di calendario con l'ora del trainer: a cavallo della mezzanotte e con
   fusi diversi può differire di un giorno.
5. **Il tocco su un cliente apre solo «Connesso dal …»**, il dettaglio di US-087. È provvisorio e
   dichiarato: la scheda cliente vera è US-090/091.

### 🔵 Suggerimenti
6. `profile_provider.dart` nasce con `AuthService()` istanziato dentro il provider, come
   `auth_provider.dart`: è il debito noto (US-008/009), non nuovo. Quando esisterà un `authServiceProvider`
   andrà portato lì.
7. Gli indici Firestore non sono versionati (`firestore.indexes.json` non esiste): questa storia usa
   quello già in produzione per `getUserSessions`, ma chi ricrea il progetto da zero lo perde.

## Deviazioni dal piano

- Il provider dell'elenco sta in un file nuovo, `clients_provider.dart`, e non in `invite_provider.dart`.
- Il servizio ha tre metodi di lettura singola (`getAcceptedRelationships`, `getConsentsOfTrainer`,
  `getLastSessionStart`) e non due: il piano non prevedeva quello dei legami, perché il provider
  esistente è un ascolto continuo e qui serve una lettura.
- `_ShortcutRow` è diventata pubblica (`HomeShortcutRow`) **solo per poterla provare**: era l'unico modo di
  verificare che un atleta non veda il riquadro. Nessun cambio di comportamento.
- La composizione (chi leggere, cosa fare se le regole negano) sta dietro un'interfaccia
  (`ClientOverviewSource`) per poterla provare senza Firebase: non prevista nel piano.

## Fuori scope rilevato
Nessuno nuovo. Restano quelli già noti: scheda cliente (US-090/091), indici non versionati, `secondary`
del tema chiaro.

## Regressioni sospette
Nessuna trovata. `HomeShortcutRow` è lo stesso widget con un riquadro condizionale in più;
`home_destinations_back_test.dart` ora controlla anche che `ClientsScreen` abbia il tasto indietro; le
regole non sono cambiate (42 prove, le 8 mutazioni di US-092 ancora tutte prese).

## Limiti dichiarati
- **Autoverifica**, non giudizio indipendente.
- **Mai visto su un telefono.** Aspetto della riga, della striscia, dello stato vuoto, e il giro vero
  (trainer con clienti reali, un cliente che revoca) sono da confermare sull'APK, con due account.
- **Il codice che parla con Firestore non gira in nessun test.** `getLastSessionStart` e gli altri due
  metodi sono provati solo nella *forma delle query* sull'emulatore, e la composizione con una sorgente
  finta. L'adattatore (`_FirestoreClientSource`) non ha un test suo.
- Il comportamento **offline** di queste letture (dati di un altro utente, non in cache) non è provato:
  il caso peggiore previsto è la schermata d'errore con «Riprova».
- Costo e fuso orario: dichiarati sopra, non misurati.
