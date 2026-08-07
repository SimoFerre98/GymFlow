# US-073 — Review

**Verdetto:** APPROVATA — le correzioni sono state applicate da chi rivede, vedi in fondo
**Diff esaminato:** `git diff main...feature/US-073-mockup-alignment` · 12 file, +386 / −159
**Verifica rifatta**, in un worktree separato: `flutter analyze` **63 avvisi** · `flutter test`
**302 verdi** sul branch, **315 una volta unito a `main`** — il branch è nato prima di US-049 e
l'integrazione è stata provata a parte, senza conflitti.

I 12 file toccati sono **esattamente** i 12 del mandato. Le rimozioni sono complete e pulite: le
sette tinte, `regionGlyph` e `tintDeep` spariscono da `app_palette` e da `BodyRegion` senza lasciare
riferimenti morti, e i test che le misuravano sono stati **riscritti** sui due estremi del gradiente
unico invece che cancellati.

---

## Copertura dei criteri

| # | Criterio | Esito | Prova |
|---|---|---|---|
| 1 | Segnaposto a gradiente unico, sagoma a tratto | ✅ | `outline → surfaceContainer`, che è `ink-600 → ink-800` del mockup. Sulle sagome vedi il limite dichiarato sotto |
| 2 | Indicatore video salmone | ✅ | `scheme.tertiary` / `onTertiary`, con contrasto misurato nei due temi |
| 3 | Card su `surfaceContainerHigh` con padding `spacing.md` | ✅ | Test aggiornato, non cancellato |
| 4 | `ExerciseRow` esiste | ✅ | 185 righe di test dedicati |
| 5 | Integrato nella libreria | ✅ | `Card` + `ListTile` sostituiti; `Dismissible` e i due gesti distinti conservati |
| 6 | Le tinte per regione sono rimosse | ✅ | `grep` su `region*`: nessun residuo |
| 7 | Nessuna misura scritta a mano | ⚠️ **non era rispettato** | Vedi i due rilievi sotto: corretti |

---

## 🔴 Il rilievo che conta: i pixel del mockup copiati invece che convertiti

`exercise_row.dart` usava `t.shape.cornerMd` — **16 dp** — per il raggio della riga.

Il mockup dice `border-radius: 16px`. Ma i pixel non si copiano: il telaio disegnato è largo 282 px
e il telefono 384 dp, quindi **16 × 1,36 = 22 dp**. Il token più vicino è `cornerLg` (24), non
`cornerMd` (16).

Il risultato sarebbe stato una riga con angoli **molto più squadrati** di quelli disegnati, sul
componente più usato dell'app. Ed è esattamente l'errore che `DESIGN-SPEC.md` esiste per impedire:
il mandato lo scriveva a chiare lettere — «raggio 16 px → **22 dp**» — e la coincidenza fra il
numero del mockup e il nome di un token (`cornerMd` = 16) ha reso la trappola più insidiosa del
solito.

Corretto in `cornerLg`, con il perché scritto accanto e il test rinominato: si chiamava «il raggio
angoli segue `cornerMd` dei token», cioè **il test certificava l'errore**.

## 🟡 La storia dei token reintroduce i letterali

`exercise_thumbnail.dart` **toglieva** l'uso di `t.sizing.badge` per mettere `width: 18, height: 18,
size: 13, right: 3, bottom: 3`. Il token esisteva e valeva 20; il mockup ne vuole 18.

La direzione era giusta, il modo no: quando il token ha il valore sbagliato **si cambia il token**,
non lo si aggira. Ora `sizing.badge` vale 18 — con la conversione scritta nel commento — e il widget
lo legge di nuovo. Il simbolo dentro deriva dalla stessa misura invece di essere un secondo numero
da tenere in accordo.

Stesso trattamento per `side: 56` in `ExerciseRow` (esisteva `sizing.thumbnailMd`, che vale 56) e
per i margini scritti a mano in `exercise_library_screen.dart`.

---

## ⚠️ Un limite verificato, non un difetto

Il rapporto dichiara «sagome Material outline». In realtà solo **due su sette** lo sono
(`fitness_center_outlined`, `monitor_heart_outlined`).

**Ho verificato nel set di icone di Flutter**: `rowing_outlined`, `sports_handball_outlined`,
`sports_martial_arts_outlined`, `directions_run_outlined` e `self_improvement_outlined` **non
esistono**. L'esecutore ha convertito tutte quelle convertibili: è il massimo possibile senza
disegnare sagome a mano, che sarebbe sproporzionato per questa storia.

Resta uno scarto dal mockup — le cinque sagome piene contro il tratto disegnato — e va **dichiarato**
invece che spuntato. Se conterà, servirà una storia con sagome proprie.

---

## 🔵 Osservazioni

- **`Colors.transparent`** in `ExerciseRow` per lo sfondo trasparente. È un letterale, ma qui non c'è
  una scelta di colore da fare: `Material` vuole un `Color` e serve la superficie per l'onda del
  tocco. Lasciato.
- **Il backlog non è stato toccato**: la storia è ancora `📋 PLANNED`. Anche qui manca la
  rivendicazione su `main` prima di iniziare, come in US-049.
- **Il gap fra miniatura e testo** è `spacing.md` (16) contro i 12 dp del mockup. Dentro la
  tolleranza della scala, non toccato.

---

## Limiti dichiarati

1. **Nessuna prova sul dispositivo.** Che i 28 esercizi senza video mostrino tutti lo stesso
   segnaposto e i 15 con video il pallino salmone è da guardare sull'APK.
2. **Cinque sagome su sette restano piene**, per assenza di alternative nel set di Flutter.
3. **Il tema chiaro non è stato guardato**: il gradiente `outline → surfaceContainer` lì è chiaro, e
   il contrasto della sagoma è misurato ma non visto.

---

## Correzioni applicate prima del merge

| Rilievo | Correzione |
|---|---|
| 🔴 Raggio della riga `cornerMd` (16) invece del convertito | `cornerLg`, con il calcolo nel commento e il test rinominato |
| 🟡 `width/height: 18`, `size: 13`, `right/bottom: 3` | `sizing.badge` passa da 20 a 18; il widget legge il token, il simbolo deriva dalla misura |
| 🟡 `side: 56` in `ExerciseRow` | `t.sizing.thumbnailMd` |
| 🟡 Margini a mano nella libreria | `spacing.md` / `spacing.xs` |
| Test che certificavano i letterali | Riscritti sui token, e uno rinominato perché il nome stesso era sbagliato |

**Verifica finale**: `analyze` 63, `flutter test` **302 verdi** sul branch, **315 unito a `main`**,
APK costruito.

---

_Review del 2026-08-07 · fase 5 del ciclo in [`WORKFLOW.md`](../WORKFLOW.md) · fatta in worktree separato: nella cartella principale altri due esecutori stavano lavorando a US-047 e US-050_
