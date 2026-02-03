import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../services/firestore_service.dart';

part 'firestore_provider.g.dart';

@riverpod
FirestoreService firestoreService(FirestoreServiceRef ref) {
  return FirestoreService();
}
