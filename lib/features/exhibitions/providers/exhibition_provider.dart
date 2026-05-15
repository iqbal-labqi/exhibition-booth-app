import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exhibition_model.dart';
import '../repositories/exhibition_repository.dart';

// StreamProvider automatically handles loading and error states!
final publishedExhibitionsProvider = StreamProvider<List<ExhibitionModel>>((ref) {
  final repo = ref.watch(exhibitionRepositoryProvider);
  return repo.getPublishedExhibitions();
});

// ADD THIS BELOW YOUR EXISTING publishedExhibitionsProvider

final organizerExhibitionsProvider = StreamProvider<List<ExhibitionModel>>((ref) {
  final repo = ref.watch(exhibitionRepositoryProvider);
  // For now, we query the exact ID we hardcoded in the create form.
  // We will link this dynamically to the logged-in user later!
  return repo.getOrganizerExhibitions('current_user_id');
});