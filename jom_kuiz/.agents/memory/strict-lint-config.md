---
name: Strict lint config
description: The project uses strict Dart analysis options plus specific flutter_lints rules that affect how widgets and local variables are written.
---

`analysis_options.yaml` enables:
- `strict-casts: true`
- `strict-inference: true`
- `strict-raw-types: true`

Plus these linter rules:
- `always_declare_return_types` — all functions/methods need explicit return types
- `prefer_const_constructors` — use const where possible
- `prefer_final_locals` — local variables must be `final`
- `use_key_in_widget_constructors` — ALL Widget subclasses (including private `_Foo`) need a constructor that accepts `super.key`
- `prefer_single_quotes`
- `sort_child_properties_last`

**Critical rules for new Widget classes:**
Every private widget class needs `super.key` even if it's internal to a file:
```dart
// WRONG:
class _MyCard extends StatelessWidget {
  const _MyCard({required this.data});

// CORRECT:
class _MyCard extends StatelessWidget {
  const _MyCard({super.key, required this.data});
```

**Why:** `use_key_in_widget_constructors` is included in `package:flutter_lints/flutter.yaml` and applies to all Widget subclasses regardless of visibility.

**How to apply:** Before writing any new StatelessWidget, StatefulWidget, or ConsumerWidget subclass (public or private), add `super.key` to its primary constructor.
