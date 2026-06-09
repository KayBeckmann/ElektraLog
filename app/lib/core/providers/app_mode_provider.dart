import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'einstellungen_provider.dart';

enum AppModus { solo, company }

class AppModusNotifier extends AsyncNotifier<AppModus> {
  @override
  Future<AppModus> build() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return token != null ? AppModus.company : AppModus.solo;
  }

  Future<void> setCompany(
    String token,
    String benutzerId,
    String firmaId,
    String name, {
    String? firmaName,
    bool istAdmin = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    await prefs.setString('benutzer_id', benutzerId);
    await prefs.setString('firma_id', firmaId);
    await prefs.setString('benutzer_name', name);
    await prefs.setBool('ist_admin', istAdmin);
    if (firmaName != null && firmaName.isNotEmpty) {
      await prefs.setString('firma_name', firmaName);
    }
    state = const AsyncData(AppModus.company);
    // Beide Provider neu laden damit Admin-Status und Firmendaten sofort stimmen
    ref.invalidate(currentUserProvider);
    ref.invalidate(einstellungenProvider);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('benutzer_id');
    await prefs.remove('firma_id');
    await prefs.remove('benutzer_name');
    await prefs.remove('firma_name');
    await prefs.remove('ist_admin');
    state = const AsyncData(AppModus.solo);
    ref.invalidate(currentUserProvider);
    ref.invalidate(einstellungenProvider);
  }
}

final appModusProvider =
    AsyncNotifierProvider<AppModusNotifier, AppModus>(AppModusNotifier.new);

final currentUserProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return {
    'token': prefs.getString('jwt_token'),
    'benutzerId': prefs.getString('benutzer_id'),
    'firmaId': prefs.getString('firma_id'),
    'name': prefs.getString('benutzer_name'),
    'firmaName': prefs.getString('firma_name'),
    'istAdmin': prefs.getBool('ist_admin') ?? false,
  };
});

/// Convenience-Provider: true wenn eingeloggt UND Firmenadmin
final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  return user['istAdmin'] as bool? ?? false;
});
