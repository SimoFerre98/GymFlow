import 'package:flutter/material.dart';
import 'package:gymflow/src/models/body_measurement.dart';
import 'package:gymflow/src/services/auth_service.dart';
import 'package:gymflow/src/services/firestore_service.dart';
import 'package:gymflow/src/ui/widgets/toast_utils.dart';
import 'package:intl/intl.dart';

class BodyMeasurementsScreen extends StatefulWidget {
  const BodyMeasurementsScreen({super.key});

  @override
  State<BodyMeasurementsScreen> createState() => _BodyMeasurementsScreenState();
}

class _BodyMeasurementsScreenState extends State<BodyMeasurementsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _userId = AuthService().currentUser?.uid ?? '';

  bool _isAdding = false;

  // Controllers for the input form
  final _weightController = TextEditingController();
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipsController = TextEditingController();
  final _bicepsController = TextEditingController();
  final _thighsController = TextEditingController();
  final _calvesController = TextEditingController();
  final _shouldersController = TextEditingController();
  final _neckController = TextEditingController();
  final _bodyFatController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _weightController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    _hipsController.dispose();
    _bicepsController.dispose();
    _thighsController.dispose();
    _calvesController.dispose();
    _shouldersController.dispose();
    _neckController.dispose();
    _bodyFatController.dispose();
    super.dispose();
  }

  void _showAddMeasurementSheet() {
    // Reset controllers
    _weightController.clear();
    _chestController.clear();
    _waistController.clear();
    _hipsController.clear();
    _bicepsController.clear();
    _thighsController.clear();
    _calvesController.clear();
    _shouldersController.clear();
    _neckController.clear();
    _bodyFatController.clear();
    setState(() {
      _selectedDate = DateTime.now();
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Measurement',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Date Picker
              ListTile(
                title: Text(
                  'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: const Icon(Icons.calendar_today, color: Colors.blue),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                    // Rebuild only the sheet if needed, strict state management might need stateful builder
                    // but since _selectedDate is in parent state, simple setState in parent won't update sheet w/o navigator pop/push or stateful builder
                    Navigator.pop(context);
                    _showAddMeasurementSheet(); // Re-open to refresh date (simple hack) or use StatefulBuilder next time
                  }
                },
              ),

              const SizedBox(height: 10),
              _buildNumberField(_weightController, 'Weight (kg)'),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(_chestController, 'Chest (cm)'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildNumberField(_waistController, 'Waist (cm)'),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(_hipsController, 'Hips (cm)'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildNumberField(
                      _shouldersController,
                      'Shoulders (cm)',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(_bicepsController, 'Biceps (cm)'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildNumberField(_thighsController, 'Thighs (cm)'),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(_calvesController, 'Calves (cm)'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildNumberField(_neckController, 'Neck (cm)'),
                  ),
                ],
              ),
              _buildNumberField(_bodyFatController, 'Body Fat %'),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveMeasurement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Save Entry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[400]),
          filled: true,
          fillColor: Colors.grey[800],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Future<void> _saveMeasurement() async {
    try {
      final measurement = BodyMeasurement(
        id: '', // Will be generated
        userId: _userId,
        date: _selectedDate,
        weight: double.tryParse(_weightController.text),
        chest: double.tryParse(_chestController.text),
        waist: double.tryParse(_waistController.text),
        hips: double.tryParse(_hipsController.text),
        biceps: double.tryParse(_bicepsController.text),
        thighs: double.tryParse(_thighsController.text),
        calves: double.tryParse(_calvesController.text),
        shoulders: double.tryParse(_shouldersController.text),
        neck: double.tryParse(_neckController.text),
        bodyFatPercentage: double.tryParse(_bodyFatController.text),
      );

      await _firestoreService.addBodyMeasurement(_userId, measurement);
      Navigator.pop(context); // Close sheet
      ToastUtils.showSuccess(context, 'Measurement saved');
    } catch (e) {
      Navigator.pop(context);
      ToastUtils.showError(context, 'Error saving: $e');
    }
  }

  Future<void> _deleteMeasurement(String id) async {
    try {
      await _firestoreService.deleteBodyMeasurement(_userId, id);
      ToastUtils.showSuccess(context, 'Measurement deleted');
    } catch (e) {
      ToastUtils.showError(context, 'Error deleting: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId.isEmpty) {
      return const Center(child: Text('User not logged in'));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Body Measurements',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMeasurementSheet,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<BodyMeasurement>>(
        stream: _firestoreService.getBodyMeasurements(_userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final measurements = snapshot.data ?? [];

          if (measurements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.monitor_weight_outlined,
                    size: 64,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No measurements yet',
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                  TextButton(
                    onPressed: _showAddMeasurementSheet,
                    child: const Text('Add your first entry'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: measurements.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final m = measurements[index];
              return Dismissible(
                key: Key(m.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red.withOpacity(0.8),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Colors.grey[900],
                      title: const Text(
                        'Delete Entry?',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        'This action cannot be undone.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      actions: [
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.of(ctx).pop(false),
                        ),
                        TextButton(
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(true),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) => _deleteMeasurement(m.id),
                child: Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Text(
                      DateFormat('MMM d, yyyy').format(m.date),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: m.weight != null
                        ? Text(
                            '${m.weight} kg',
                            style: const TextStyle(color: Colors.blueAccent),
                          )
                        : null,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Wrap(
                          spacing: 20,
                          runSpacing: 10,
                          children: [
                            if (m.chest != null)
                              _statItem('Chest', '${m.chest} cm'),
                            if (m.waist != null)
                              _statItem('Waist', '${m.waist} cm'),
                            if (m.hips != null)
                              _statItem('Hips', '${m.hips} cm'),
                            if (m.shoulders != null)
                              _statItem('Shoulders', '${m.shoulders} cm'),
                            if (m.biceps != null)
                              _statItem('Biceps', '${m.biceps} cm'),
                            if (m.thighs != null)
                              _statItem('Thighs', '${m.thighs} cm'),
                            if (m.calves != null)
                              _statItem('Calves', '${m.calves} cm'),
                            if (m.neck != null)
                              _statItem('Neck', '${m.neck} cm'),
                            if (m.bodyFatPercentage != null)
                              _statItem('Body Fat', '${m.bodyFatPercentage}%'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
