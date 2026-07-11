import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/validators/validators.dart';
import '../../../domain/entities/child_profile.dart';
import '../../controllers/child_profile_controller.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/app_text_field.dart';

/// Edit Child Profile screen.
///
/// Full name is required; all other fields are optional.
/// Avatar upload is a placeholder ("coming soon").
class EditChildProfileScreen extends ConsumerStatefulWidget {
  const EditChildProfileScreen({super.key});

  @override
  ConsumerState<EditChildProfileScreen> createState() =>
      _EditChildProfileScreenState();
}

class _EditChildProfileScreenState
    extends ConsumerState<EditChildProfileScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  static const List<String> _genderOptions = <String>['female', 'male', 'other'];
  static const int _bioMaxLength = 160;

  String? _gender;
  DateTime? _dateOfBirth;

  String? _fullNameError;
  String? _bioError;

  bool _isSubmitting = false;
  bool _initialized = false;

  void _hydrate(ChildProfile profile) {
    if (_initialized) return;
    _initialized = true;
    _fullNameController.text = profile.fullName;
    _schoolController.text = profile.school ?? '';
    _gradeController.text = profile.grade ?? '';
    _bioController.text = profile.bio ?? '';
    _gender =
        _genderOptions.contains(profile.gender) ? profile.gender : null;
    _dateOfBirth = profile.dateOfBirth;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _schoolController.dispose();
    _gradeController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 10),
      firstDate: DateTime(now.year - 20),
      lastDate: now,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  bool _validate() {
    final String? fullNameError =
        Validators.minLength(_fullNameController.text, 2, fieldName: 'Full name');
    final String? bioError =
        Validators.maxLength(_bioController.text, _bioMaxLength, fieldName: 'Bio');
    setState(() {
      _fullNameError = fullNameError;
      _bioError = bioError;
    });
    return fullNameError == null && bioError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _isSubmitting = true);

    final String? dobStr = _dateOfBirth == null
        ? null
        : '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}';

    final result =
        await ref.read(childProfileControllerProvider.notifier).updateProfile(
              fullName: _fullNameController.text.trim(),
              dateOfBirth: dobStr,
              gender: _gender,
              school: _schoolController.text.trim().isEmpty
                  ? null
                  : _schoolController.text.trim(),
              grade: _gradeController.text.trim().isEmpty
                  ? null
                  : _gradeController.text.trim(),
              bio: _bioController.text.trim().isEmpty
                  ? null
                  : _bioController.text.trim(),
            );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated')));
      },
      failure: (failure) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.toString())));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ChildProfile? profile =
        ref.watch(childProfileControllerProvider).valueOrNull;
    if (profile != null) _hydrate(profile);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Child Profile')),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                // Avatar placeholder
                Center(
                  child: Stack(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: profile.profilePhoto != null
                            ? NetworkImage(profile.profilePhoto!)
                            : null,
                        child: profile.profilePhoto == null
                            ? const Icon(Icons.child_care, size: 32)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: IconButton.filled(
                          icon: const Icon(Icons.camera_alt_outlined, size: 16),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Avatar upload is coming soon')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Full Name',
                  controller: _fullNameController,
                  errorText: _fullNameError,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(
                        value: 'female', child: Text('Female')),
                    DropdownMenuItem<String>(
                        value: 'male', child: Text('Male')),
                    DropdownMenuItem<String>(
                        value: 'other', child: Text('Other')),
                  ],
                  onChanged: (String? value) =>
                      setState(() => _gender = value),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDateOfBirth,
                  child: InputDecorator(
                    decoration:
                        const InputDecoration(labelText: 'Date of Birth'),
                    child: Text(
                      _dateOfBirth == null
                          ? 'Not set'
                          : '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                    label: 'School', controller: _schoolController),
                const SizedBox(height: 16),
                AppTextField(
                    label: 'Grade / Class', controller: _gradeController),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Bio',
                  controller: _bioController,
                  errorText: _bioError,
                  hintText: 'A short bio',
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Save Changes',
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
    );
  }
}
