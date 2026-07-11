---
name: currentChildIdProvider pattern
description: How child module screens receive the child to display — via a StateProvider set before navigation.
---

All child controllers (`ChildProfileController`, `HomeworkController`, `QuizController`, `AchievementController`) watch `currentChildIdProvider` (a `StateProvider<String>`) to know which child to load.

**Pattern:**
```dart
// Before navigating to child screens:
ref.read(currentChildIdProvider.notifier).state = selectedChildId;
context.push(AppRoutes.childDashboard);

// Inside any child controller:
final String childId = ref.watch(currentChildIdProvider);
if (childId.isEmpty) return null; // or empty list
```

**In tests:**
```dart
currentChildIdProvider.overrideWith((ref) => 'c1'),  // seeds specific ID
currentChildIdProvider.overrideWith((ref) => ''),    // seeds empty (null-state)
```

**Why:** Avoids `Provider.family` complexity without codegen. All child controllers react automatically when the ID changes — navigating to a different child just updates the StateProvider.

**Future:** When the Children List module ships, the selection flow will set this provider before pushing to `/child/dashboard`. No child controller changes are needed.
