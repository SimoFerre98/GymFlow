# GymFlow — audit delle schermate: cosa c'è, come sta, cosa manca

**Letto il codice reale di tutte le 27 schermate** (`lib/src/ui/screens/`, più `main_screen.dart` come
guscio di navigazione), 18 anche viste in funzione sul telefono (screenshot in
[`docs/design/06-inventario-app.html`](design/06-inventario-app.html)), le altre 9 lette dal
sorgente. Obiettivo: prima **sistemare quello che c'è**, poi — solo dopo — pensare ad aggiungere.

**Legenda valutazione**

| Simbolo | Significato |
|---|---|
| ✅ | Fatta bene: stile Immersivo coerente, funzionalmente completa per quello che promette |
| 🟡 | Esiste e funziona, ma con un gap chiaro (stile non aggiornato, o contenuto più povero del previsto) |
| 🔴 | Problema serio: schermata non aggiornata allo stile, o difficile da raggiungere/collegare male |

---

## 1. Autenticazione

| Schermata | File | Valutazione |
|---|---|---|
| Accesso | `login_screen.dart` | ✅ Stile Immersivo completo, campo con accento a sinistra coerente col resto dell'app |
| Registrazione | `register_screen.dart` | ✅ Come sopra, più la scelta del ruolo (Atleta/Trainer/Entrambi) |

Non riviste di persona sul telefono (per non disconnettere la sessione), ma il codice è pulito e
coerente con lo stile delle altre schermate secondarie.

---

## 2. Il ciclo principale: allenarsi

Questo è il cuore dell'app, ed è dove il redesign Immersivo è più completo e coerente.

| Schermata | File | Valutazione |
|---|---|---|
| Home | `dashboard_screen.dart` | ✅ |
| Sessione attiva | `active_session_screen.dart` | ✅ La schermata più usata, ben fatta |
| Dialogo scarta/lascia sessione | (dentro active_session) | ✅ |
| Libreria esercizi | `exercise_library_screen.dart` | ✅ con un'eccezione, vedi sotto |
| Dettaglio esercizio | `exercise_detail_screen.dart` | ✅ Tabs Tecnica/Storico/Record, grafico di progressione |
| Riepilogo fine allenamento | `workout_summary_screen.dart` | ✅ con un'eccezione, vedi sotto |
| Nuovo giorno (creazione allenamento) | `workout_creator_screen.dart` | ✅ |
| Schede (elenco programmi) | `program_list_screen.dart` | ✅ |

**🟡 Libreria esercizi — il filtro "Recenti" è un guscio vuoto.** Nel codice,
`ExerciseSegmentFilter.recent => false` — qualunque cosa tu tocchi, "Recenti" mostra sempre la lista
vuota. Non è un difetto introdotto ora: era già così prima del redesign Immersivo (`DESIGN-SPEC.md`
lo segnalava). **Decisione da prendere:** implementarlo (serve tracciare "ultimo usato" da qualche
parte, oggi non esiste) o toglierlo dal segmentato.

**🟡 Riepilogo fine allenamento — la card del record ha perso informazioni.** `_RecordBar` mostra
"Record · nome esercizio", il nuovo peso, e "il massimo precedente era X kg" — ma **non più** le
ripetizioni della serie nuova né la data del vecchio massimale (che la versione precedente mostrava).
Già segnalato nel commit di recupero: **decisione di prodotto da prendere**, non un bug.

### 🔴 Modifica scheda — la vera eccezione

`program_creator_screen.dart` è l'unica schermata di questo gruppo **rimasta al vecchio stile**:
componenti Material standard (bordi arrotondati, niente font Anton nei titoli di sezione, swatch
colore generici) invece del linguaggio Immersivo (angoli vivi, filetto, tipografia condensata) usato
ovunque altro. Guardando l'atlante (`18-modifica-scheda.png`) si vede a colpo d'occhio: stona.
**Prima candidata per un lavoro di coerenza visiva**, prima di aggiungere qualunque cosa nuova.

---

## 3. Progressi

| Schermata | File | Valutazione |
|---|---|---|
| Statistiche (Dati) | `statistics_screen.dart` | ✅ |
| Gamification (badge, sfide, streak) | `gamification_screen.dart` | ✅ |
| Cronometro / Timer | `time_tools_screen.dart` | ✅ con lo sfondo "aura" |
| Calendario | `calendar_screen.dart` | ✅ |

### 🔴 Obiettivi personali — funzione reale, ma quasi introvabile e sovrapposta nel nome

**Scoperta durante l'audit, non nell'atlante**: esiste una schermata `goals_screen.dart`, **diversa**
da `gamification_screen.dart`, per obiettivi liberi che l'utente si dà da solo (es. "panca 100 kg",
con valore attuale/target/unità). Il commento in testa al file lo dice esplicitamente: *"'Obiettivi'
nel mockup è `gamification_screen.dart`... un concetto diverso da questi obiettivi liberi"*. Due
funzioni reali e distinte, entrambe implementate. Due problemi concreti:

1. **Il nome si sovrappone.** Sulla Home, la riga "Sfida del mese" (che suona come una sfida di
   gamification) in realtà **apre `GoalsScreen`**, l'obiettivo personale — non la schermata di badge
   e sfide. Un utente non ha modo di capire che sta guardando due sistemi diversi.
2. **Non è raggiungibile per un utente nuovo.** L'unico punto d'ingresso trovato nel codice
   (`dashboard_screen.dart:231`) è quella riga sulla Home, e compare **solo se esiste già un
   obiettivo** (`if (bestGoal != null)`). Chi non ne ha ancora uno non ha nessun modo — nessuna voce
   in Impostazioni, nessuna tessera rapida — per crearne il primo.

**Questo è probabilmente il problema di collegamento più concreto trovato in questo audit.** Va
deciso: un punto d'ingresso proprio (una tessera sulla Home accanto a Dati/Schede/Obiettivi/
Cronometro, o una voce in Impostazioni), e un nome che non si confonda con la gamification.

---

## 4. Profilo & Impostazioni

| Schermata | File | Valutazione |
|---|---|---|
| Impostazioni · indice | `settings_screen.dart` | ✅ |
| Il mio profilo | `profile_screen.dart` | ✅ |
| Misure corporee | `body_measurements_screen.dart` | ✅ |
| Aspetto (tema/palette/accento) | `appearance_settings_screen.dart` | ✅ La più fedele al mockup di tutte |
| Crediti foto | `image_credits_screen.dart` | ✅ Semplice ma completa |

**🟡 Palestra** (`gym_settings_screen.dart`) — stile Immersivo corretto, ma **molto più semplice**
del mockup "Turno 3": niente mappa reale (solo un placeholder "tocca per impostare"), niente orari
di apertura, niente promemoria all'arrivo, niente "amici in questa palestra", niente statistiche
sessioni/ore. Solo nome, indirizzo, salva.

**🟡 Recupero** (`timer_settings_screen.dart`) — stile corretto, ma senza recupero per tipo di serie
(Forza/Ipertrofia/Resistenza previsto dal mockup), senza schermo-sempre-acceso, senza conto alla
rovescia vocale.

**🟡 Generali** (`general_settings_screen.dart`) — stile corretto, ma manca: unità di misura (kg/lb,
cm/in), stato sincronizzazione, esportazione dati, privacy/permessi, eliminazione account. Lingua
limitata a IT/EN (il mockup ne mostrava tre, con Español).

**Nota comune alle tre sopra:** tutte e tre sembrano essere state "spezzate" dal vecchio
`settings_screen.dart` monolitico mantenendo solo il **contenuto che già esisteva**, senza aggiungere
quanto il mockup "Turno 3" aggiungeva di nuovo. È una spiegazione plausibile del perché sono più
semplici: non è stato dimenticato uno stile, è probabile che quella parte del lavoro non sia stata
completata.

---

## 5. Sociale (amici)

| Schermata | File | Valutazione |
|---|---|---|
| Connetti amici | `connect_friend_screen.dart` | 🟡 |
| Dettaglio amico | `friend_detail_screen.dart` | 🟡 |

Entrambe hanno l'intestazione coerente (pillola indietro + titolo Anton + filetto), ma il **corpo**
di entrambe usa testo e componenti Material standard (`titleMedium`, `bodyLarge` di default) invece
dei token Immersivo (`t.typography.*`) usati sistematicamente altrove. Il dialogo di controllo
privacy dentro `connect_friend_screen.dart` (`_AccessControlDialog`) è un `AlertDialog` completamente
di sistema, per nulla ristilizzato. Il codice di `friend_detail_screen.dart` contiene commenti che
ammettono lavoro non finito ("For now assuming static permissions for this session").

**Funzionalmente sono complete e non banali**: codice amico univoco, condivisione selettiva di
calendario e schede, importazione di una scheda condivisa. È lo strato visivo che è rimasto indietro,
insieme alle impostazioni profonde del punto 4 — stesso pattern.

### 🔴 Dettaglio salute

`health_detail_screen.dart` (si apre dalla schermata Dati, toccando una metrica) usa ancora
`ExpressiveCard` ed `ExpressiveSegmentedControl` — **i nomi dei widget della direzione precedente**
(Material 3 Expressive), non i loro equivalenti Immersivo. L'`AppBar` è quella di sistema, con
`Text(widget.title)` semplice: nessuna delle intestazioni custom (pillola+titolo+filetto) che ogni
altra schermata secondaria usa. Funzionalmente è completa (grafico settimana/mese, media/totale,
gestisce bene l'assenza di permessi Health Connect), ma visivamente è la più indietro di tutte
insieme a "Modifica scheda".

---

## 6. Il quadro d'insieme: un pattern chiaro

Mettendo insieme tutte le valutazioni, emerge una linea netta:

**Il ciclo centrale (Home → libreria/dettaglio esercizio → sessione attiva → riepilogo, più Schede,
Statistiche, Timer, Calendario, Aspetto, Auth) ha ricevuto il trattamento Immersivo per intero ed è
solido.** È presumibilmente quello su cui si è lavorato per primo e con più cura.

**Tutto ciò che sta "attorno" — impostazioni profonde (Palestra/Recupero/Generali), sociale
(amici), dettaglio salute, e la modifica scheda — è rimasto a metà: o più semplice del previsto, o
visivamente non aggiornato, o (nel caso degli obiettivi personali) mal collegato.**

Non sembra un caso: è la firma di un lavoro fatto per priorità, dove il tempo è finito prima di
arrivare alla periferia. Utile saperlo perché **la priorità per continuare è ovvia**: chiudere il
cerchio su queste sei schermate (Palestra, Recupero, Generali, Connetti amici, Dettaglio amico,
Dettaglio salute) e risolvere il collegamento di Obiettivi personali, prima di disegnare qualsiasi
schermata nuova.

---

## 7. Cosa NON esiste (e potrebbe mancare davvero)

Verificato nel backlog e nel codice, non nei mockup:

- **Gestione clienti per il trainer** (EP-017): il ruolo "Trainer" esiste nel profilo (US-086), ma
  non c'è nessuna schermata per un trainer per vedere/gestire i propri clienti. Coerente con il
  backlog: EP-017 risulta ancora da fare.
- **US-083 lato scheda** (serie pianificate una per una, superset) è segnata `✅ DONE` nel backlog,
  ma non è stata verificata in questo audit se `program_creator_screen.dart` (che comunque abbiamo
  già segnato 🔴 per lo stile) espone davvero quell'interfaccia o solo il modello sotto.

---

## 8. Cosa aggiungere — solo dopo aver chiuso quanto sopra

Nessuna proposta qui: per esplicita richiesta, prima si sistema quello che c'è. Quando si arriva a
questo punto, i candidati naturali sono i pezzi di mockup mai costruiti già elencati in
`DESIGN-SPEC.md` (anello di avanzamento, ventaglio di carte per le schede) e in `docs/BACKLOG.md`
(EP-017 trainer/clienti).

---

_Scritto il 2026-09-09, leggendo il sorgente reale di tutte le 27 schermate (18 anche verificate a
schermo). Non sostituisce una prova umana sull'APK — è un audit di codice, dichiarato come tale._
