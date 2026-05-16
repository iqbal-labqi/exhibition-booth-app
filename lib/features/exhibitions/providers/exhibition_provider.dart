import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exhibition_model.dart';
import '../repositories/exhibition_repository.dart';
// ADDED MISSING IMPORT:
import '../../authentication/providers/auth_provider.dart';

// 1. THE GUEST/EXHIBITOR PROVIDER (This was accidentally deleted!)
final publishedExhibitionsProvider = StreamProvider<List<ExhibitionModel>>((ref) {
  final repo = ref.watch(exhibitionRepositoryProvider);
  return repo.getPublishedExhibitions();
});

// 2. THE ORGANIZER PROVIDER
final organizerExhibitionsProvider = StreamProvider<List<ExhibitionModel>>((ref) {
  final repo = ref.watch(exhibitionRepositoryProvider);
  final user = ref.watch(currentUserProvider); // Real logged-in user

  if (user == null) return Stream.value([]);
  return repo.getOrganizerExhibitions(user.uid);
});