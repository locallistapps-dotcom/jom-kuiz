import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/validators/validators.dart';
import '../../../domain/entities/parent_profile.dart';
import '../../controllers/parent_controller.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/app_text_field.dart';

/// Edit Profile screen. Email is shown read-only per the module's
/// validation rules -- it is only ever changed through the Auth module.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  static const List<String> _genderOptions = <String>['female', 'male', 'other'];

  String? _gender;
  DateTime? _dateOfBirth;
  String _language = 'en';

  String? _fullNameError;
  String? _phoneError;
  String? _bioError;

  bool _isSubmitting = false;
  bool _initialized = false;

  static const int _bioMaxLength = 280;

  void _hydrate(ParentProfile profile) {
    if (_initialized) return;
    _initialized = true;
    _fullNameController.text = profile.fullName;
    _phoneController.text = profile.phoneNumber ?? '';
    _countryController.text = profile.country ?? '';
    _stateController.text = profile.state ?? '';
    _cityController.text = profile.city ?? '';
    _bioController.text = profile.bio ?? '';
    _emailController.text = profile.email;
    // Only bind to a known dropdown option; an unrecognized/legacy value
    // from the server must not be handed to DropdownButtonFormField's
    // `value`, which asserts if it isn't one of `items`.
    _gender = _genderOptions.contains(profile.gender) ? profile.gender : null;
    _dateOfBirth = profile.dateOfBirth;
    _language = AppConstants.supportedLocaleCodes.contains(profile.language)
        ? profile.language
        : AppConstants.defaultLocaleCode;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  void _showAvatarPlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avatar upload is coming soon')),
    );
  }

  bool _validate() {
    final String? fullNameError = Validators.minLength(
      _fullNameController.text,
      2,
      fieldName: 'Full name',
    );
    final String? phoneError = Validators.phone(_phoneController.text);
    final String? bioError = Validators.maxLength(
      _bioController.text,
      _bioMaxLength,
      fieldName: 'Bio',
    );

    setState(() {
      _fullNameError = fullNameError;
      _phoneError = phoneError;
      _bioError = bioError;
    });

    return fullNameError == null && phoneError == null && bioError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() => _isSubmitting = true);
    final result = await ref.read(parentControllerProvider.notifier).updateProfile(
          fullName: _fullNameController.text.trim(),
          phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
          state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
          city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
          gender: _gender,
          dateOfBirth: _dateOfBirth,
          language: _language,
          bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (_) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile updated')));
      },
      failure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.toString())));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ParentProfile?> profileState = ref.watch(parentControllerProvider);
    final ParentProfile? profile = profileState.valueOrNull;
    if (profile != null) _hydrate(profile);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Center(
                  child: Stack(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 40,
                        backgroundImage:
                            profile.profilePhoto != null ? NetworkImage(profile.profilePhoto!) : null,
                        child: profile.profilePhoto == null
                            ? const Icon(Icons.person_outline, size: 32)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: IconButton.filled(
                          icon: const Icon(Icons.camera_alt_outlined, size: 16),
                          onPressed: _showAvatarPlaceholder,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Email',
                  controller: _emailController,
                  enabled: false,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Full Name',
                  controller: _fullNameController,
                  errorText: _fullNameError,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Phone Number',
                  controller: _phoneController,
                  errorText: _phoneError,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                AppTextField(label: 'Country', controller: _countryController),
                const SizedBox(height: 16),
                AppTextField(label: 'State', controller: _stateController),
                const SizedBox(height: 16),
                AppTextField(label: 'City', controller: _cityController),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(value: 'female', child: Text('Female')),
                    DropdownMenuItem<String>(value: 'male', child: Text('Male')),
                    DropdownMenuItem<String>(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (String? value) => setState(() => _gender = value),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDateOfBirth,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date of Birth'),
                    child: Text(
                      _dateOfBirth == null
                          ? 'Not set'
                          : '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _language,
                  decoration: const InputDecoration(labelText: 'Language'),
                  items: AppConstants.supportedLocaleCodes
                      .map(
                        (String code) => DropdownMenuItem<String>(
                          value: code,
                          child: Text(code == 'en' ? 'English' : 'Bahasa Melayu'),
                        ),
                      )
                      .toList(),
                  onChanged: (String? value) {
                    if (value != null) setState(() => _language = value);
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Bio',
                  controller: _bioController,
                  errorText: _bioError,
                  hintText: 'Tell us a little about yourself',
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
