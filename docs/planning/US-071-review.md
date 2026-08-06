# US-071 — Review

**Verdetto:** APPROVATA
**Diff esaminato:** `git diff main...HEAD` · 7 file, +330 / −20
**Verifica:** `flutter analyze` **63 avvisi** (erano 66), zero errori · `flutter test` **282 test verdi** (erano 273) · `flutter build apk --debug` **riuscita** e installata

---

## Copertura dei criteri

| # | Criterio | Esito | Prova |
|---|---|---|---|
| 1 | Le 11 chiavi mancanti esistono in EN e IT, con traduzioni pertinenti | ✅ | Due test verificano che nessuna delle 11 restituisca sé stessa, in entrambe le lingue. **La pertinenza è un giudizio**: le 11 stringhe sono da leggere sul telefono |
| 2 | Un test verifica che ogni chiave usata esista in entrambe le lingue, e fallisce se qualcuno ne aggiunge una senza tradurla | ✅ **provato al contrario** | Il test legge `lib/**/*.dart` ed estrae ogni `t('...')`. Rimossa `'cancel'` dalla tabella italiana, **il test è fallito** nominando anche i due file che la usano; ripristinata, è tornato verde |
| 3 | Un test verifica che le due tabelle contengano le stesse chiavi | ✅ | Confronto nei due versi, più un test che verifica che le traduzioni non siano la stessa parola — un copia-incolla dall'inglese passerebbe tutto il resto |
| 4 | Gli aggiramenti scritti a mano sono rimossi | ✅ | Il ternario su `cancel` e le sue cinque righe di commento, e i due `??` morti. **Il conteggio degli avvisi scende da 66 a 63** |
| 5 | Nessuna stringa visibile introdotta al posto di una chiave | ✅ | Il diff non aggiunge letterali nell'interfaccia: toglie i tre che c'erano (`'Cancel'`, `'Volume'`, `'Intensity'`) |

---

## Cosa ha trovato la review

### 🟡 Gli avvisi scendono a 63, non a 64 come previsto nel piano

I due `??` non erano due avvisi ma **tre**: `dead_null_aware_expression` su entrambi, più un
`dead_code` che dipendeva dal primo. Il piano prevedeva 64.

`CLAUDE.md` e `HANDOFF.md` sono aggiornati nello stesso commit, altrimenti la prossima sessione
legge «baseline 66», ne conta 63 e non sa se sia un bene o un male.

### 🟡 La pertinenza delle traduzioni non è verificabile con un test

`rpe_label` → «Sforzo medio» è una decisione: il valore accanto viene da
`calculateAverageRPE`, quindi **sforzo percepito**, non intensità. C'è un test che verifica almeno
che sia *diverso* da `avg_intensity_label`, così i due non collassano nella stessa parola. Ma che
«Sforzo medio» sia la parola giusta lo dice solo chi guarda la schermata.

Le altre dieci sono brevi e meccaniche (`cancel` → «Annulla»), con due decisioni di tono:
`login_required` → «Accedi per continuare» invece di un messaggio che spiega perché, e
`friend_label` → «(amico)» fra parentesi, perché si appende a un sottotitolo esistente.

### 🔵 Il commento cancellato raccontava una storia

Le cinque righe rimosse da `program_list_screen.dart` erano un ragionamento ad alta voce lasciato
nel codice: *«I'll assume 'Cancel' is English… I'll use 'Annulla' hardcoded if 'it'… add key later
if I can»*. Il «later» non è mai arrivato, e nel frattempo la stessa chiave mancava in altri cinque
punti. È il motivo per cui questa storia mette un test invece di aggiungere solo undici righe.

### 🔵 Il test non copre le chiavi costruite a runtime

`t('badge_name_${badge.id}')` in `gamification_screen.dart` non è verificabile staticamente: il test
salta le chiavi che contengono `$`. I nomi dei badge **sono** tradotti (`badge_name_first_step` e
compagnia esistono in entrambe le tabelle), ma se un badge nuovo arrivasse senza traduzione, questo
test non lo direbbe. Limite dichiarato.

---

## Fuori scope rilevato nel diff

`CLAUDE.md` non era nell'elenco iniziale dei file toccati — lo è diventato quando il conteggio degli
avvisi è cambiato. È dichiarato nel piano ed è la conseguenza diretta del criterio 4.

---

## Checklist adversariale

| Domanda | Risposta |
|---|---|
| Il test è fragile? | Legge da `lib/` con percorso relativo alla radice, come già fa `exercise_seed_test.dart` con l'asset. Ha un controllo di sanità: se trovasse meno di 50 chiavi, l'espressione regolare si è rotta e il test lo dice invece di passare su un insieme vuoto |
| Il test passa perché non trova niente? | No: è la domanda a cui risponde il controllo di sanità, e la prova al contrario |
| Comportamento cambiato dove ho tolto i ripieghi? | No: `t` non restituisce mai `null`, quindi i `??` non si eseguivano mai. Il ternario su `cancel` sceglieva sempre il ramo `'Cancel'` finché la chiave mancava, e ora la chiave c'è |
| Convenzioni? | Nessuna stringa nuova nell'interfaccia; le 11 chiavi sono in entrambe le tabelle |
| Può rompere qualcosa di non testato? | Il calendario mostra sei stringhe nuove al posto di sei codici. Se una traduzione fosse sbagliata, si legge male: non si rompe |
| Segreti nel diff? | Nessuno |

---

## Limiti dichiarati

1. **La pertinenza delle 11 traduzioni è da leggere sul telefono**, non da un test.
2. **Le chiavi dinamiche non sono coperte.**
3. **Le decine di stringhe scritte direttamente nel codice** (`'Exercises'`, `'Please log in'`,
   `'Add at least one exercise'`…) **restano**: sono US-022 e US-023. Questa storia chiude solo le
   chiavi già usate e mai tradotte.
4. **La conferma a schermo non è stata fatta**: il telefono si è bloccato durante la verifica.

---

## Da confermare sul telefono

1. **Dashboard**: sotto il valore accanto a Volume si deve leggere «Sforzo medio», non `rpe_label`.
2. **Calendario**: è la schermata che ne aveva sei. Un evento deve mostrare «Completato alle …» o
   «Programmato per le …», e il dialogo di eliminazione deve avere «Annulla».
3. **Menu**: chi non ha un nome profilo deve leggere «Utente GymFlow».

---

_Review del 2026-08-06 · fase 5 del ciclo in [`WORKFLOW.md`](../WORKFLOW.md)_
