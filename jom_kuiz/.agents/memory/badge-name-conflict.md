---
name: Badge entity vs Flutter Material Badge widget
description: The domain Badge entity name conflicts with Flutter's Material 3 Badge widget; any screen importing both must hide Flutter's Badge.
---

Flutter's `material.dart` exports a `Badge` widget (notification indicator dot) since Flutter 3.7. The `Achievement` domain entity also contains a `Badge` class. In any screen that imports both `material.dart` and `achievement.dart`, this causes an ambiguity error.

**Fix:**
```dart
import 'package:flutter/material.dart' hide Badge;
import '../../../domain/entities/achievement.dart'; // Badge entity unambiguous
```

**Where this applies:**
- `achievement_screen.dart` (fixed)
- Any future screen that directly references the domain `Badge` entity

**Why:** Renaming the entity would break the clean domain model. Hiding Flutter's widget is the least-invasive fix and keeps the entity name natural in the domain layer.

**How to apply:** Whenever a new screen is created that references `Achievement.badges` or iterates `List<Badge>`, add `hide Badge` to the material import.
