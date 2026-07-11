import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/account_management_models.dart';
import '../../../domain/entities/education_level.dart';
import '../../controllers/child_management_controller.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/feedback/app_error_widget.dart';
import '../../widgets/feedback/loading_widget.dart';
import '../../widgets/inputs/app_text_field.dart';
import '../../widgets/inputs/password_field.dart';

/// Parent screen to edit an existing child's profile.
///
/// Student ID is displayed read-only — it cannot be changed.
/// Leaving the password fields blank leaves the existing password unchanged.
class EditChildScreen extends ConsumerStatefulWidget {
  const EditChildScreen({super.key, required this.childId});

  final String childId;

  @override
  ConsumerState<EditChildScreen> createState() => _EditChildScreenState();
}

class _EditChildScreenState extends ConsumerState<EditChildScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  EducationLevel? _educationLevel;
  String? _yearGrade;
  bool _initialized = false;
  bool _isSubmitting = false;
  bool _changePassword = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _hydrate(ChildManagementModel model) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = model.fullName;
    _usernameController.text = model.username;
    _educationLevel = EducationLevelHelper.fromString(model.educationLevel);
    _yearGrade = model.yearGrade;
  }

  void _onLevelChanged(EducationLevel? level) {
    if (level == null) return;
    setState(() {
      _educationLevel = level;
      _yearGrade = EducationLevelHelper.yearGradeOptions(level).first;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_educationLevel == null || _yearGrade == null) return;

    setState(() => _isSubmitting = true);

    String? newPassword;
    if (_changePassword && _passwordController.text.isNotEmpty) {
      newPassword = _passwordController.text;
    }

    final result = await ref
        .read(childManagementControllerProvider(widget.childId).notifier)
        .updateChild(
          fullName: _nameController.text.trim(),
          username: _usernameController.text.trim().toLowerCase(),
          password: newPassword,
          educationLevel: _educationLevel!,
          yearGrade: _yearGrade!,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Child profile updated')),
        );
        context.pop();
      },
      failure: (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.toString()))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ChildManagementModel> state =
        ref.watch(childManagementControllerProvider(widget.childId));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Child')),
      body: state.when(
        loading: () => const LoadingWidget(message: 'Loading...'),
        error: (Object err, _) => AppErrorWidget(
          message: err.toString(),
          onRetry: () => ref
              .read(childManagementControllerProvider(widget.childId).notifier)
              .refresh(),
        ),
        data: (ChildManagementModel model) {
          _hydrate(model);
          final List<String> yearGradeOptions =
              EducationLevelHelper.yearGradeOptions(
                  _educationLevel ?? EducationLevel.primary);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                // ── Student ID (read-only) ─────────────────────────────────
                _ReadOnlyField(
                  label: 'Student ID',
                  value: model.studentId,
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 16),

                // ── Name ────────────────────────────────────────────────────
                AppTextField(
                  label: 'Full Name *',
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  validator: (String? v) =>
                      (v == null || v.trim().length < 2)
                          ? 'Full name must be at least 2 characters'
                          : null,
                ),
                const SizedBox(height: 16),

                // ── Username ─────────────────────────────────────────────────
                AppTextField(
                  label: 'Username *',
                  controller: _usernameController,
                  textInputAction: TextInputAction.next,
                  validator: (String? v) =>
                      (v == null || v.trim().length < 3)
                          ? 'Username must be at least 3 characters'
                          : null,
                ),
                const SizedBox(height: 24),

                // ── Education Level ──────────────────────────────────────────
                Text('Education Level',
                    style: Theme.of(context).textTheme.titleSmall),
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
                  selected: <EducationLevel>{
                    _educationLevel ?? EducationLevel.primary
                  },
                  onSelectionChanged: (Set<EducationLevel> set) =>
                      _onLevelChanged(set.first),
                ),
                const SizedBox(height: 16),

                // ── Year / Grade ─────────────────────────────────────────────
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
                const SizedBox(height: 24),

                // ── Password change ───────────────────────────────────────────
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Change Password'),
                  value: _changePassword,
                  onChanged: (bool? v) =>
                      setState(() => _changePassword = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (_changePassword) ...<Widget>[
                  const SizedBox(height: 8),
                  PasswordField(
                    label: 'New Password *',
                    controller: _passwordController,
                    validator: (String? v) =>
                        (_changePassword && (v == null || v.length < 6))
                            ? 'Password must be at least 6 characters'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  PasswordField(
                    label: 'Confirm Password *',
                    controller: _confirmPasswordController,
                    validator: (String? v) =>
                        (_changePassword &&
                                v != _passwordController.text)
                            ? 'Passwords do not match'
                            : null,
                  ),
                ],
                const SizedBox(height: 32),

                PrimaryButton(
                  label: 'Save Changes',
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        helperText: 'Cannot be changed',
      ),
      child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}
