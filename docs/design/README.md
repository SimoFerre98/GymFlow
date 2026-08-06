# Riferimenti visivi

Mockup approvati dal prodotto il 2026-08-06, prima dell'inizio del ridisegno. Sono **pagine HTML autonome**: si aprono con un doppio clic, senza server né dipendenze.

Servono a rispondere alla domanda "come deve venire questa schermata" senza doverla ricostruire a memoria o dipendere da un servizio esterno.

| File | Contenuto |
|---|---|
| [`01-direzione-visiva.html`](01-direzione-visiva.html) | Sei schermate sulla palette Indigo: home, sessione, statistiche, serie, riepilogo, scheda esercizio. Catena delle immagini e contrasti misurati |
| [`02-schermate-app.html`](02-schermate-app.html) | Nove schermate: libreria, nuovo esercizio, tipi di allenamento, timer, pillola, notifica, calendario, obiettivi, traguardi, peso, impostazioni, scheda |
| [`03-timer-e-movimento.html`](03-timer-e-movimento.html) | **Timer funzionante**: si avvia, si mette in pausa, cambia modalità. Più il repertorio delle micro-interazioni e l'integrazione con la Now Bar |

## Come leggerli

Ogni schermata ha sotto una didascalia che spiega **la decisione** che incorpora, non solo cosa mostra. È quella la parte che serve durante l'implementazione: il layout si può dedurre guardando, il motivo no.

Il terzo file è interattivo di proposito. Le animazioni del timer — cifre che rotolano, pulsante che muta forma, onde concentriche — si giudicano provandole, non descrivendole. Le curve usate sono le stesse dei token di US-033: `Easing.standard`, `Easing.emphasizedDecelerate`, più una curva elastica per i cambi di forma.

## Cosa non sono

**Non sono specifiche vincolanti al pixel.** Le sagome degli esercizi sono segnaposto, i dati sono esempi realistici ma inventati, e le proporzioni valgono per uno schermo da 340 px.

Dove il mockup e il design system divergono, **vince il design system** (`lib/src/core/theme/`): i token sono la fonte di verità, i mockup sono l'intenzione.

## Storie che li realizzano

| Mockup | Storie |
|---|---|
| Home, sessione, statistiche | EP-010, EP-014 |
| Serie a cursori, riepilogo, record | US-046, US-049, US-050 |
| Scheda esercizio con progressione | US-068 |
| Libreria e nuovo esercizio | US-065, US-043 |
| Tipi di allenamento | EP-013 |
| Timer, pillola, notifica, Now Bar | EP-011 |
| Calendario, obiettivi, traguardi, peso, impostazioni | US-064, EP-012, US-066, US-067 |

Sono anche pubblicati come artifact su claude.ai, ma quei link sono privati e possono scadere: **la copia autorevole è questa**.
