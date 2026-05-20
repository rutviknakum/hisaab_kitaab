import 'package:flutter/material.dart';
import '../main.dart';

class ProfileProvider extends ChangeNotifier {
  Map<String, dynamic>? _profile;

  Map<String, dynamic>? get profile => _profile;

  bool get setupCompleted => (_profile?['setup_completed'] as bool?) ?? false;

  String get fullName => (_profile?['full_name'] as String?) ?? '';

  Future<void> loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _profile = null;
      notifyListeners();
      return;
    }

    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      _profile = data;
      notifyListeners();
    } catch (_) {
      _profile = null;
      notifyListeners();
    }
  }

  Future<void> completeSetup() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('profiles').update({
      'setup_completed': true,
    }).eq('id', user.id);

    await loadProfile();
  }
}
