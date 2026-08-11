import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymflow/src/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Le due lingue che l'app offre nel proprio selettore, non una: chiamata
  // senza argomento inizializza solo la lingua **del telefono**, e un
  // `DateFormat('EEE', 'it')` — la lingua scelta *dentro* l'app, che puo
  // essere l'altra — sollevava `LocaleDataException` non appena qualcosa la
  // usava esplicitamente. Trovato scrivendo `health_detail_screen.dart`, che
  // e la prima volta che il progetto passa una lingua esplicita a
  // `DateFormat` invece di lasciarla implicita.
  await Future.wait([
    initializeDateFormatting('it'),
    initializeDateFormatting('en'),
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const ProviderScope(child: GymFlowApp()));
}
