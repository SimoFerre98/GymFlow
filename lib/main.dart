import 'package:flutter/material.dart';

import 'package:gymflow/src/app.dart';
// import 'firebase_options.dart'; // Uncomment when generated

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Uncomment this when you have added the firebase_options.dart file
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  // For now, we will run the app without Firebase initialization to verify UI
  runApp(const GymFlowApp());
}
