# GymFlow — passaggio di consegne

**Aggiornato:** 2026-08-06 · **Commit:** `0e4bbfd` su `main` e `dev`

Questo documento serve a chi riprende il lavoro in una sessione nuova, con un altro modello o senza la cronologia della conversazione. Contiene **ciò che non si deduce leggendo il repository**: decisioni prese a voce, trappole dell'ambiente, e il livello di rigore atteso.

Da leggere in quest'ordine:

1. **Questo file** — stato, decisioni, trappole
2. [`../CLAUDE.md`](../CLAUDE.md) — regole operative, caricate automaticamente
3. [`WORKFLOW.md`](WORKFLOW.md) — il processo per ogni storia
4. [`BACKLOG.md`](BACKLOG.md) — le 69 storie con dipendenze e stati
5. [`adr/001-material-3-expressive.md`](adr/001-material-3-expressive.md) — la decisione sul design system

---

## 1. Dove siamo

**12 storie completate su 69** · 29 punti su 220 · tag `v0.1.0` marca la fine del risanamento tecnico.

| Fatto | Effetto misurato |
|---|---|
| US-001 | Il branch `dev` non compilava: errore di compilazione risolto |
| US-039 | Deploy web sospeso: la pipeline non fallisce più per un target rimandato |
| US-014 | 20 controller rilasciati, nessuno squilibrio in `lib/` |
| US-024 | Avvisi analyzer **da 172 a 66** |
| US-005, US-006, US-007 | Migrazione completa a Riverpod, `package:provider` rimosso |
| US-029 | CI attiva, primi test reali del progetto |
| US-040 | Build release ripristinata: 25,9 MB contro i 101 del debug |
| US-033, US-034 | Design system Expressive e palette Indigo |
| US-041 | Modello esercizio con foto e video |

**Stato di salute:** 66 avvisi, **zero errori**, **102 test verdi**, CI verde su entrambi i branch.

I 66 avvisi sono debito preesistente tracciato in **US-030**. Il baseline va rispettato: una storia che lo alza ha introdotto qualcosa, e va sistemato prima del merge.

---

## 2. Ambiente: quello che non funziona come ti aspetti

Queste cose costano mezz'ora se le scopri da solo.

### Flutter non è nel PATH

```
C:\Users\s.ferrero\Flutter\bin
```

Va anteposto al PATH in ogni comando PowerShell:

```powershell
$env:PATH = "C:\Users\s.ferrero\Flutter\bin;" + $env:PATH
```

Flutter 3.38.7, Dart 3.10.7.

### Piattaforme

| Target | Stato |
|---|---|
| **Android** | ✅ L'unico attivo |
| Web | ❌ Isar genera interi a 64 bit non rappresentabili in JavaScript. Accantonato in **EP-008** |
| Windows desktop | ❌ Visual Studio non installato |

### Dispositivi

- **Telefono**: Samsung S26 Ultra, `RFGL10YZ5RX`, Android 16. Si scollega spesso: verificare con `adb devices` prima di `flutter install`.
- **Emulatore**: `Medium_Phone_API_36.1`, avviabile da `%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe`
- **adb**: `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`

Il ciclo **non esegue l'app**: produce un APK che l'utente prova sul telefono. Con il telefono collegato conviene `flutter install -d RFGL10YZ5RX --debug`.

### Trappole degli strumenti

| Trappola | Cosa succede | Come si evita |
|---|---|---|
| **Heredoc doppio in bash** | `python3 - <<'EOF'` con fallback su `python` apre una REPL interattiva che va in timeout | Scrivere lo script in un file e lanciarlo |
| **Percorso 8.3 dello scratchpad** | `C:\Users\SE4AB~1.FER\...` funziona in bash ma **non** in PowerShell | In PowerShell usare `C:\Users\s.ferrero\AppData\Local\Temp\...` |
| **`sleep` in bash** | Bloccato dall'ambiente | `run_in_background: true`, oppure un ciclo di attesa in PowerShell |
| **`git merge --squash`** | Non marca il branch come merged | Cancellare con `git branch -D`, non `-d` |
| **Redirect binario in PowerShell** | `adb exec-out screencap > file.png` corrompe il file con un BOM | `adb shell screencap -p /sdcard/x.png` poi `adb pull` |
| **Amend fuori dai comandi** | Un commit su `main` è stato amendato senza che nessuno lo chiedesse, creando divergenza con `origin` | Verificare `git rev-list --left-right --count main...origin/main` prima di pushare |
| **Screenshot dell'emulatore** | Può catturare un'app di sistema in primo piano | Verificare `adb shell dumpsys window \| grep mCurrentFocus` |

---

## 3. Il processo, e il suo spirito

Le fasi sono in [`WORKFLOW.md`](WORKFLOW.md). Qui c'è **perché** sono così, che è ciò che serve per applicarle a casi nuovi.

**Un solo agente esegue tutte le fasi.** Nessuna delega: su storie da 2-5 punti costa più tempo di quanto ne risparmi.

**La review è un'autoverifica, e questo è un limite noto.** Chi ha scritto il codice rilegge ciò che *intendeva* scrivere. Il processo compensa in due modi: la fase 5 impone di ripartire dal diff con una checklist adversariale, e il controllo reale è l'approvazione dell'utente. La review **non è una formalità**: in 12 storie ha trovato difetti reali in 5 di esse, incluso un bug di sicurezza.

**Niente pull request.** Branch locale, `merge --squash` in `main`, push, allineamento di `dev`. Il branch non si pusha mai.

**`dev` è uno specchio di `main`**, non un branch di integrazione. Dopo ogni merge va riportato in fast-forward. Se il fast-forward fallisce, fermarsi: significa che qualcuno ha committato su `dev`.

**I commit non attribuiscono nulla ad assistenti AI.** Nessun trailer `Co-Authored-By`, nessuna firma. In italiano, con il codice storia in testa.

### Il livello di rigore atteso

Questo è il punto che si perde più facilmente cambiando sessione. Esempi concreti di cosa ha significato "verificato" nelle storie fatte:

- **US-040**: il fix della build release è stato provato **disattivandolo** e ricostruendo da `flutter clean`, per dimostrare che era il fix a funzionare e non il clean. Un fix di build che funziona per motivi diversi da quelli creduti è peggio di nessun fix.
- **US-029**: il gate CI è stato verificato **introducendo un errore di sintassi di proposito** e controllando l'exit code, poi rimuovendolo. Non dedotto: provato.
- **US-034**: i contrasti WCAG sono stati **misurati** prima di scrivere il tema, e sono diventati 35 test che impediscono la regressione.
- **US-041**: i test hanno trovato che `endsWith('youtube.com')` accetta `notyoutube.com`. Il bug non era ipotetico.
- **US-014**: il criterio sulla memoria non era misurabile con gli strumenti disponibili. È stato **dichiarato come limite** nella review, con la prova strutturale che era possibile fornire, invece di essere spuntato senza verifica.

**La regola che ne deriva**: quando un criterio non è verificabile, si dichiara. Non si spunta e non si nasconde. Ogni review fatta ha una sezione sui limiti, ed è quella che rende il resto credibile.

---

## 4. Decisioni prese, e perché

Queste sono state prese in conversazione con l'utente. Non si deducono dal codice.

### Direzione visiva: palette Indigo

Scelta dall'utente con riferimenti visivi (immagini Pinterest di app fitness e commerce).

| Ruolo | Colore | Significato |
|---|---|---|
| Sfondo app | `#221E3A` | |
| Superfici | `#312C51` | Le card |
| Superfici sollevate | `#48426D` | Card dentro card |
| **Azione** | `#F0C38E` ambra | **Un solo significato: cosa fare adesso** |
| **Dati vitali** | `#F1AA9B` salmone | Battito, sforzo. Mai per le azioni |

**L'app è scura per impostazione predefinita.** La separazione ambra/salmone è deliberata: se l'ambra compare su qualcosa che non è un'azione, l'occhio impara a ignorarlo.

La palette **supera WCAG AA su ogni coppia di testo**, quattro in AAA. È verificato da `test/contrast_test.dart` e ha di fatto risolto US-028.

### Material 3 Expressive: non esiste in Flutter

Verificato sull'issue ufficiale: Flutter **non lo sviluppa** e non accetta contributi sul tema. Del set esistono nativamente solo `DynamicSchemeVariant.expressive`, `Durations` ed `Easing`.

Decisione: **approccio ibrido per categoria**, documentato in [`adr/001-material-3-expressive.md`](adr/001-material-3-expressive.md) con i dati di pub.dev che l'hanno determinata. In sintesi: `motor` per il motion a molla (238 like, 77k download), tutto il resto interno, perché la famiglia `m3e_*` è `0.x` e `m3e_buttons` richiede un SDK superiore a quello del progetto.

**Tutti i token passano da `ExpressiveTokens`**, letta con `context.expressive`. I widget non sanno da dove viene un token: è ciò che rende la migrazione futura un lavoro su un file solo.

### Contenuti degli esercizi: misto

Foto curate dal team, caricabili dall'utente, con **miniatura YouTube come terzo anello** e segnaposto generato come ultimo.

### Timer fuori dall'app

Via **Live Updates di Android 16** (`Notification.ProgressStyle`), che One UI 8 porta nella Now Bar. Verificato da fonti Samsung: **nessuna API proprietaria necessaria**. Richiede però codice nativo Kotlin: US-053 e US-054 sono **le uniche due storie del backlog che escono da Dart**.

### Verifica tramite APK

Il ciclo non esegue l'app su emulatore. Produce un APK, l'utente prova sul telefono. I criteri che richiedono interazione vanno marcati **"da confermare sull'APK"**, mai spuntati.

---

## 5. Il materiale ricevuto, e i suoi limiti

`SchedePalestra.md` nella radice del repository contiene 43 esercizi e 4 schede reali.

### Estratto e utilizzabile

`assets/data/exercises_seed.json` — 43 esercizi, 12 gruppi muscolari normalizzati. **Nessuno lo legge ancora**: lo importerà US-045.

### ⚠️ Nessun URL è un video

**43 su 43 sono ricerche YouTube** (`youtube.com/results?search_query=`). Conseguenza: la miniatura si ricava dall'identificativo del video, e una ricerca non ne ha, quindi **il terzo anello della catena di ripiego non produce nulla** per la libreria curata.

Gestito con il campo `videoSearchQuery`: l'app apre la ricerca, e `hasSpecificVideo` permette all'interfaccia di dire la verità invece di promettere un video che non c'è. **Sostituire le ricerche con video scelti è incrementale e non richiede modifiche al codice.**

### ⚠️ Le schede non sono importabili con il modello attuale

I formati reali dell'utente chiedono più di quanto il modello sappia esprimere:

| Formato | Significato |
|---|---|
| `4x10/6` | 4 serie, ripetizioni da 10 a 6 |
| `2x6 + 2x12` | Due blocchi diversi |
| `4x(15-12-10-8)` con pesi `45-50-55-60` | Piramide con carichi |
| `1x10 + 1x10 + Max + Max` | Serie a cedimento |
| `3x12 (4 iso 3" + 4 negativa 4" + 4)` | Tecnica speciale |
| `Superserie: Crunch + Crunch inversi` | Due esercizi accoppiati |
| `10 kg per parte` | Manubri, carico per lato |
| Recuperi `90s`, `1'`, `1:30'` | Formati diversi |

**Non è stato inventato un modello**: produrrebbe qualcosa che non regge le schede reali. Serve una decisione dell'utente — vedi domande aperte.

---

## 6. Domande aperte che richiedono l'utente

Nessuna di queste si può decidere da soli.

1. **Quanto strutturare il modello delle serie?** Un modello che copre tutti i formati sopra è complesso; uno che copre l'80% e conserva il resto come testo è più semplice ma non permette di calcolare i volumi correttamente. **Blocca l'importazione delle schede.**

2. **Chi scegli i 43 video?** Sostituire le ricerche con video specifici richiede di guardarli per giudicarne la qualità. Se lo fa un assistente, va detto che la selezione non è verificata visivamente.

3. **Colore personalizzato e contrasti.** I preset sono filtrati a valori che superano AA, ma se l'utente scegliesse un colore libero potrebbe violarli. Va deciso se limitare, calcolare una variante accessibile a runtime, o accettare il rischio.

4. **Impostazione per ridurre il movimento.** Material 3 Expressive spinge su animazioni pronunciate. Oggi si rispetta solo l'impostazione di sistema. Serve un controllo dedicato?

5. **Firma di produzione.** La release è firmata con la chiave di debug. Serve una chiave vera solo per distribuire sugli store.

---

## 7. Cosa fare adesso

**17 storie eseguibili** (dipendenze soddisfatte). Le più sensate come prossimo passo:

| Storia | Perché adesso |
|---|---|
| **US-042** Catena di ripiego dell'immagine | Rende visibile US-041: senza, il modello ha i campi ma nessuno li mostra |
| **US-043** Miniature nelle liste | Il primo cambiamento che l'utente vede sul telefono |
| **US-021** Componenti condivisi | Sblocca US-022 e US-023, che sistemano i grigi ereditati |
| **US-030** Azzerare gli avvisi | 66 avvisi sono rumore che nasconde i problemi nuovi |

### ⚠️ Debito visibile introdotto da US-034

L'app è passata da chiara a scura, ma le schermate contengono ancora **decine di `Colors.grey[...]` e `Colors.white` scritti a mano**, ereditati dal fondo chiaro. **Su indigo alcuni testi secondari appaiono sbiaditi.**

Era previsto e dichiarato nella review di US-034. Lo sistemano **US-022** e **US-023**, sostituendoli con i ruoli del `ColorScheme`. Se l'utente segnala schermate sbiadite, è questo: non un difetto nuovo.

Il **catalogo del design system** (menu → Design system, solo in debug) mostra la palette applicata correttamente ed è il punto migliore per giudicare la direzione visiva.

---

## 8. Riferimenti visivi pubblicati

Tre pagine con i mockup approvati dall'utente. Contengono le decisioni di layout che il codice deve realizzare:

| Pagina | Contenuto |
|---|---|
| [Direzione visiva Indigo](https://claude.ai/code/artifact/e3b27bb3-d15e-487c-a5db-aa26a210b68a) | 6 schermate, catena delle immagini, confronto con lo stato attuale |
| [Il resto dell'app](https://claude.ai/code/artifact/92fd6e40-38f1-4242-85a9-3eefd1e7d949) | 9 schermate: libreria, tipi di allenamento, calendario, obiettivi, traguardi, peso, impostazioni |
| [Timer e movimento](https://claude.ai/code/artifact/1400f94f-73b6-42cf-992f-9b9dd34ec091) | Timer **funzionante**, repertorio delle micro-interazioni, Now Bar |

Sono privati dell'utente: se non sono raggiungibili, le decisioni di layout sono comunque riassunte nelle storie di EP-010, EP-011 e EP-014.

---

## 9. Convenzioni di scrittura

Valgono per codice, documentazione e commit.

- **Italiano** per commenti, documentazione, commit e artefatti di processo. Il codice resta in inglese.
- **I commenti spiegano il perché**, non il cosa. Un commento che ripete la riga sotto è rumore.
- **Nessun riferimento ad AI** nei commit o nel codice.
- **Le storie e i piani citano file e riga** quando parlano di codice esistente.
- **Le review dichiarano i limiti.** Una review senza sezione sui limiti è sospetta: significa che non si è guardato abbastanza.
- **Niente stringhe hardcoded nell'interfaccia**: tutto passa dalla localizzazione, con la chiave in EN e IT.
- **Niente colori letterali** fuori da `app_palette.dart`.
- **Niente valori numerici** per spaziature e raggi: vengono da `context.expressive`.

---

## 10. Verifica rapida dello stato

Da eseguire all'inizio di una sessione nuova, per capire dove si è:

```bash
git log --oneline -5
git rev-list --left-right --count origin/main...origin/dev
```

Il secondo comando deve dare `0	0`. Per lo stato del backlog, cercare `**Status:**` in `docs/BACKLOG.md`: le storie `✅ DONE` sono fatte, le `⬜ TODO` no, e una `🔵 IN PROGRESS` significa che qualcuno ha lasciato un lavoro a metà.

Per sapere quali storie sono eseguibili, servono le dipendenze: una storia è pronta quando **tutte** quelle nel suo campo `Depends on` sono `✅ DONE`.

---

_Documento di passaggio · GymFlow · 2026-08-06 · commit `0e4bbfd`_
