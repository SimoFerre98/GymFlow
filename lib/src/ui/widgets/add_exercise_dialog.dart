import 'package:flutter/material.dart';

import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';
import 'package:gymflow/src/models/exercise.dart';
import 'package:gymflow/src/ui/screens/exercise_library_screen.dart';
import 'package:gymflow/src/ui/widgets/toast_utils.dart';

/// Il dialogo «Nuovo esercizio».
///
/// Esiste come widget con un `State` proprio per una ragione misurata, non per
/// gusto di ordine: prima il `TextEditingController` viveva nella funzione che
/// apriva il dialogo e veniva rilasciato subito dopo `await showDialog`. Ma
/// quella `Future` si completa quando la rotta viene **chiusa**, non quando ha
/// finito di sfumare: per la durata dell'animazione il `TextField` e ancora
/// nell'albero e usa il controller. Riprodotto in un test — «A
/// TextEditingController was used after being disposed», seguita da altre due
/// eccezioni a cascata, cioe schermata rossa in debug.
///
/// Con il controller dentro un `State`, Flutter lo rilascia quando il
/// sottoalbero sparisce davvero, che e l'unico momento giusto.
///
/// Il secondo guadagno e che **questo si monta in un test**: la schermata della
/// libreria no, perche istanzia `FirestoreService` nel proprio `State` — il
/// debito di US-008 — e la review di US-079 aveva dovuto dichiarare come limite
/// che la catena «errore → il dialogo resta aperto» era letta e non eseguita.
/// Ora si esegue.
class AddExerciseDialog extends StatefulWidget {
  const AddExerciseDialog({
    super.key,
    required this.loc,
    required this.userId,
    required this.saveExercise,
  });

  final Localization loc;

  /// Chi sta creando l'esercizio. Finisce in `userId` sul documento, ed e cio
  /// che le regole Firestore controllano per consentire la scrittura.
  final String? userId;

  /// Iniettata invece di essere presa da un servizio: e cio che rende questo
  /// dialogo provabile con un doppio che solleva.
  final Future<void> Function(Exercise exercise) saveExercise;

  @override
  State<AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<AddExerciseDialog> {
  final TextEditingController _nameController = TextEditingController();
  ExerciseType _selectedType = ExerciseType.strength;
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _salva() async {
    final result = await handleAddExerciseSubmit(
      rawName: _nameController.text,
      type: _selectedType,
      userId: widget.userId,
      saveExercise: widget.saveExercise,
    );

    if (!mounted) return;

    if (result.shouldCloseDialog) {
      Navigator.of(context).pop();
      return;
    }

    if (result.outcome == AddExerciseOutcome.validationError) {
      setState(() => _nameError = widget.loc.t(result.errorKey!));
    } else if (result.outcome == AddExerciseOutcome.saveError) {
      ToastUtils.showError(context, widget.loc.t(result.errorKey!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;

    return AlertDialog(
      title: Text(loc.t('add_exercise_title')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: loc.t('add_exercise_name_label'),
              errorText: _nameError,
            ),
            onChanged: (_) {
              // L'errore si pulisce appena si ricomincia a scrivere: restare
              // col messaggio rosso mentre si corregge non aiuta nessuno.
              if (_nameError != null) setState(() => _nameError = null);
            },
          ),
          SizedBox(height: context.expressive.spacing.md),
          DropdownButton<ExerciseType>(
            value: _selectedType,
            isExpanded: true,
            onChanged: (val) => setState(() => _selectedType = val!),
            items: ExerciseType.values.map((type) {
              // I nomi dei tipi restano non tradotti: sono di US-027, e questa
              // storia corregge un ciclo di vita, non le stringhe.
              return DropdownMenuItem(
                value: type,
                child: Text(type.name.toUpperCase()),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.t('cancel')),
        ),
        TextButton(
          onPressed: _salva,
          child: Text(loc.t('save')),
        ),
      ],
    );
  }
}
