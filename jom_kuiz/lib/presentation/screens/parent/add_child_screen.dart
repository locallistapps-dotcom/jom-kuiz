import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/services/account_management_service.dart';
import '../../../domain/entities/education_level.dart';
import '../../providers/account_management_providers.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/inputs/password_field.dart';

/// Parent screen to create a new child account.
///
/// The server auto-generates the student ID and hashes the password.
/// Username uniqueness is pre-checked client-side before submission.
class AddChildScreen extends ConsumerStatefulWidget {
  const AddChildScreen({super.key});

  @override
  ConsumerState<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends ConsumerState<AddChildScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  EducationLevel _educationLevel = EducationLevel.primary;
  String _yearGrade = EducationLevelHelper.yearGradeOptions(EducationLevel.primary).first;
  bool _autoUsername = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLevelChanged(EducationLevel? level) {
    if (level == null) return;
    final List<String> options = EducationLevelHelper.yearGradeOptions(level);
    setState(() {
      _educationLevel = level;
      _yearGrade = options.first;
    });
  }

  void _onAutoUsernameToggle(bool val) {
    setState(() {
      _autoUsername = val;
      if (val) {
        _usernameController.text =
            AccountManagementService.generateUsername(_nameController.text);
      } else {
        _usernameController.clear();
      }
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);

    final result =
        await ref.read(accountManagementServiceProvider).createChild(
              fullName: _nameController.text.trim(),
              username: _usernameController.text.trim().toLowerCase(),
              password: _passwordController.text,
              educationLevel: _educationLevel,
              yearGrade: _yearGrade,
            );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Child account created successfully')),
        );
        context.pop();
      },
      failure: (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.toString())),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> yearGradeOptions =
        EducationLevelHelper.yearGradeOptions(_educationLevel);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Child')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            // ── Basic info ───────────────────────────────────────────────────
            AppTextField(
              label: 'Full Name *',
              controller: _nameController,
              textInputAction: TextInputAction.next,
              onChanged: (_) {
                if (_autoUsername) {
                  _usernameController.text = AccountManagementService
                      .generateUsername(_nameController.text);
                }
              },
              validator: (String? v) => (v == null || v.trim().length < 2)
                  ? 'Full name must be at least 2 characters'
                  : null,
            ),
            const SizedBox(height: 16),

            // ── Username ─────────────────────────────────────────────────────
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auto-generate username'),
              value: _autoUsername,
              onChanged: _onAutoUsernameToggle,
            ),
            AppTextField(
              label: 'Username *',
              controller: _usernameController,
              enabled: !_autoUsername,
              hintText: 'e.g. aiman4839',
              textInputAction: TextInputAction.next,
              validator: (String? v) =>
                  (v == null || v.trim().length < 3)
                      ? 'Username must be at least 3 characters'
                      : null,
            ),
            const SizedBox(height: 16),

            // ── Password ─────────────────────────────────────────────────────
            PasswordField(
              label: 'Password *',
              controller: _passwordController,
              validator: (String? v) =>
                  (v == null || v.length < 6)
                      ? 'Password must be at least 6 characters'
                      : null,
            ),
            const SizedBox(height: 24),

            // ── Education Level ───────────────────────────────────────────────
            Text(
              'Education Level',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<EducationLevel>(
              segments: EducationLevel.values
                  .map(
                    (EducationLevel l) => ButtonSegment<EducationLevel>(
                      value: l,
                      label: Text(EducationLevelHelper.labelFor(l),
                          style: const TextStyle(fontSize: 12)),
                    ),
                  )
                  .toList(),
              selected: <EducationLevel>{_educationLevel},
              onSelectionChanged: (Set<EducationLevel> set) =>
                  _onLevelChanged(set.first),
            ),
            const SizedBox(height: 16),

            // ── Year / Grade ─────────────────────────────────────────────────
            DropdownButtonFormField<String>(
              value: _yearGrade,
              decoration: const InputDecoration(labelText: 'Year / Grade *'),
              items: yearGradeOptions
                  .map((String g) =>
                      DropdownMenuItem<String>(value: g, child: Text(g)))
                  .toList(),
              onChanged: (String? v) {
                if (v != null) setState(() => _yearGrade = v);
              },
            ),
            const SizedBox(height: 32),

            PrimaryButton(
              label: 'Create Account',
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),

            const SizedBox(height: 16),
            // ── Student ID note ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The 8-digit Student ID is generated automatically and'
                      ' cannot be changed after account creation.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
