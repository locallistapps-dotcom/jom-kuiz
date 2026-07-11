import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/validators/validators.dart';
import '../../controllers/parent_controller.dart';
import '../../controllers/session_controller.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/password_field.dart';

/// Security screen -- change password + logout.
class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final String? currentError = Validators.required(
      _currentPasswordController.text,
      fieldName: 'Current password',
    );
    final String? newError = Validators.password(_newPasswordController.text);
    final String? confirmError = Validators.confirmPassword(
      _confirmPasswordController.text,
      _newPasswordController.text,
    );

    setState(() {
      _currentPasswordError = currentError;
      _newPasswordError = newError;
      _confirmPasswordError = confirmError;
    });

    return currentError == null && newError == null && confirmError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() => _isSubmitting = true);
    final result = await ref.read(parentControllerProvider.notifier).updatePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (_) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Password updated')));
      },
      failure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.toString())));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('Change Password', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          PasswordField(
            label: 'Current Password',
            controller: _currentPasswordController,
            errorText: _currentPasswordError,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          PasswordField(
            label: 'New Password',
            controller: _newPasswordController,
            errorText: _newPasswordError,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          PasswordField(
            label: 'Confirm New Password',
            controller: _confirmPasswordController,
            errorText: _confirmPasswordError,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Update Password',
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
          const SizedBox(height: 32),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text(
              'Log Out',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => ref.read(sessionControllerProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}
