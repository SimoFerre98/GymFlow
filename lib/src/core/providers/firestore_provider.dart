import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../services/firestore_service.dart' as svc;

part 'firestore_provider.g.dart';

@riverpod
class FirestoreService extends _$FirestoreService {
  @override
  svc.FirestoreService build() {
    return svc.FirestoreService();
  }
}
