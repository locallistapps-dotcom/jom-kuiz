import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/login_preferences_service.dart';

/// Provides the [LoginPreferencesService] singleton.
///
/// Screens call [ref.read(loginPreferencesServiceProvider)] to load or save
/// remembered login identifiers (email / Student ID / username).
final Provider<LoginPreferencesService> loginPreferencesServiceProvider =
    Provider<LoginPreferencesService>((_) => LoginPreferencesService());
