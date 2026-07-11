import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failure.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/achievement.dart';
import '../providers/child_providers.dart';

/// Manages the achievement summary for the currently selected child.
///
/// Reacts automatically when [currentChildIdProvider] changes.
final AsyncNotifierProvider<AchievementController, Achievement?>
    achievementControllerProvider =
    AsyncNotifierProvider<AchievementController, Achievement?>(
        AchievementController.new);

class AchievementController extends AsyncNotifier<Achievement?> {
  @override
  Future<Achievement?> build() async {
    final String childId = ref.watch(currentChildIdProvider);
    if (childId.isEmpty) return null;
    final Result<Achievement> result =
        await ref.watch(childServiceProvider).getAchievements(childId: childId);
    return result.when(
      success: (Achievement achievement) => achievement,
      failure: (Failure failure) => throw failure,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue<Achievement?>.loading();
    state = await AsyncValue.guard<Achievement?>(() async {
      final String childId = ref.read(currentChildIdProvider);
      if (childId.isEmpty) return null;
      final Result<Achievement> result = await ref
          .read(childServiceProvider)
          .getAchievements(childId: childId);
      return result.when(success: (a) => a, failure: (f) => throw f);
    });
  }
}
