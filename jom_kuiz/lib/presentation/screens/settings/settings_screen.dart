import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/parent_profile.dart';
import '../../controllers/parent_controller.dart';

/// Settings screen -- language, dark mode, notifications, privacy, delete
/// account.
///
/// Dark mode and privacy are UI-only placeholders this prompt (no
/// persistence/business logic yet); language and notification toggles call
/// through to `PUT /parent/settings` via [ParentController.updateSettings].
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _darkModePlaceholder = false;

  Future<void> _confirmDeleteAccount() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and sign you out. This action cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await ref.read(parentControllerProvider.notifier).deleteAccount();
    if (!mounted) return;

    result.when(
      success: (_) {}, // RouteGuard redirects to /login once the session clears.
      failure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.toString())));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ParentProfile? profile = ref.watch(parentControllerProvider).valueOrNull;
    // Only bind to a known option; an unrecognized/legacy locale from the
    // server must not be handed to DropdownButton's `value`, which asserts
    // if it isn't one of `items`.
    final String currentLanguage = profile != null &&
            AppConstants.supportedLocaleCodes.contains(profile.language)
        ? profile.language
        : AppConstants.defaultLocaleCode;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('Language'),
            subtitle: Text(currentLanguage == 'ms' ? 'Bahasa Melayu' : 'English'),
            trailing: DropdownButton<String>(
              value: currentLanguage,
              underline: const SizedBox.shrink(),
              items: AppConstants.supportedLocaleCodes
                  .map(
                    (String code) => DropdownMenuItem<String>(
                      value: code,
                      child: Text(code == 'en' ? 'EN' : 'MS'),
                    ),
                  )
                  .toList(),
              onChanged: (String? value) {
                if (value == null) return;
                ref.read(parentControllerProvider.notifier).updateSettings(language: value).then(
                      (result) => result.when(
                        success: (_) {},
                        failure: (failure) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(failure.toString())));
                        },
                      ),
                    );
              },
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark Mode'),
            subtitle: const Text('Follows system setting today'),
            value: _darkModePlaceholder,
            onChanged: (bool value) => setState(() => _darkModePlaceholder = value),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            value: profile?.notificationEnabled ?? true,
            onChanged: (bool value) {
              ref
                  .read(parentControllerProvider.notifier)
                  .updateSettings(notificationEnabled: value)
                  .then(
                    (result) => result.when(
                      success: (_) {},
                      failure: (failure) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(failure.toString())));
                      },
                    ),
                  );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy'),
            subtitle: const Text('Coming soon'),
            onTap: () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Privacy settings are coming soon')));
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
            title: Text(
              'Delete Account',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: _confirmDeleteAccount,
          ),
        ],
      ),
    );
  }
}
