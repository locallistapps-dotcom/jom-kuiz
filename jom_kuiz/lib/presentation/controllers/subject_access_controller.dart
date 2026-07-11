import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/result.dart';
import '../../domain/entities/subject.dart';
import '../../domain/entities/subject_access.dart';
import '../providers/subject_access_providers.dart';

/// Holds the parent's subject access list, keyed by [parentId].
final AutoDisposeAsyncNotifierProviderFamily<SubjectAccessController,
        List<SubjectAccess>, String> subjectAccessControllerProvider =
    AsyncNotifierProvider.autoDispose.family<SubjectAccessController,
        List<SubjectAccess>, String>(SubjectAccessController.new);

class SubjectAccessController
    extends AutoDisposeFamilyAsyncNotifier<List<SubjectAccess>, String> {
  @override
  Future<List<SubjectAccess>> build(String arg) async {
    // arg = parentId
    final Result<List<SubjectAccess>> result =
        await ref.read(subjectAccessServiceProvider).getParentAccess(arg);
    return result.when(
      success: (List<SubjectAccess> list) => list,
      failure: (f) => throw f,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue<List<SubjectAccess>>.loading();
    state = await AsyncValue.guard(() async {
      final Result<List<SubjectAccess>> result =
          await ref.read(subjectAccessServiceProvider).getParentAccess(arg);
      return result.when(
          success: (List<SubjectAccess> list) => list,
          failure: (f) => throw f);
    });
  }

  /// Returns the set of [subjectId]s the parent currently has valid access to.
  Set<String> get accessedSubjectIds {
    return (state.valueOrNull ?? <SubjectAccess>[])
        .where((SubjectAccess a) => a.isValid)
        .map((SubjectAccess a) => a.subjectId)
        .toSet();
  }

  /// Partitions [allSubjects] into (purchased, locked) pairs.
  ({List<Subject> purchased, List<Subject> locked}) partition(
      List<Subject> allSubjects) {
    final Set<String> ids = accessedSubjectIds;
    final List<Subject> purchased = <Subject>[];
    final List<Subject> locked = <Subject>[];
    for (final Subject s in allSubjects) {
      if (ids.contains(s.subjectId)) {
        purchased.add(s);
      } else {
        locked.add(s);
      }
    }
    return (purchased: purchased, locked: locked);
  }

  // ── Admin mutations ────────────────────────────────────────────────────────

  Future<Result<SubjectAccess>> grantAccess({
    required String subjectId,
    SubjectAccessSource source = SubjectAccessSource.manual,
  }) async {
    final Result<SubjectAccess> result = await ref
        .read(subjectAccessServiceProvider)
        .grantAccess(parentId: arg, subjectId: subjectId, source: source);
    result.when(
      success: (SubjectAccess access) {
        final List<SubjectAccess> current =
            List<SubjectAccess>.from(state.valueOrNull ?? <SubjectAccess>[]);
        final bool exists =
            current.any((SubjectAccess a) => a.id == access.id);
        if (!exists) {
          state = AsyncValue<List<SubjectAccess>>.data(
              <SubjectAccess>[...current, access]);
        }
      },
      failure: (_) {},
    );
    return result;
  }

  Future<Result<void>> revokeAccess(String accessId) async {
    final Result<void> result =
        await ref.read(subjectAccessServiceProvider).revokeAccess(accessId);
    result.when(
      success: (_) {
        final List<SubjectAccess> current =
            List<SubjectAccess>.from(state.valueOrNull ?? <SubjectAccess>[]);
        current.removeWhere((SubjectAccess a) => a.id == accessId);
        state = AsyncValue<List<SubjectAccess>>.data(current);
      },
      failure: (_) {},
    );
    return result;
  }
}

/// Admin-only provider for viewing ALL subject access records.
final AutoDisposeAsyncNotifierProvider<AdminSubjectAccessController,
        List<SubjectAccess>> adminSubjectAccessControllerProvider =
    AsyncNotifierProvider.autoDispose<AdminSubjectAccessController,
        List<SubjectAccess>>(AdminSubjectAccessController.new);

class AdminSubjectAccessController
    extends AutoDisposeAsyncNotifier<List<SubjectAccess>> {
  @override
  Future<List<SubjectAccess>> build() async {
    final Result<List<SubjectAccess>> result =
        await ref.read(subjectAccessServiceProvider).getAllAccess();
    return result.when(
      success: (List<SubjectAccess> list) => list,
      failure: (f) => throw f,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue<List<SubjectAccess>>.loading();
    state = await AsyncValue.guard(() async {
      final Result<List<SubjectAccess>> result =
          await ref.read(subjectAccessServiceProvider).getAllAccess();
      return result.when(
          success: (List<SubjectAccess> list) => list,
          failure: (f) => throw f);
    });
  }
}
