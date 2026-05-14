import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    String name,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    await prefs.setString('benutzer_id', benutzerId);
    await prefs.setString('firma_id', firmaId);
    await prefs.setString('benutzer_name', name);
    state = const AsyncData(AppModus.company);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('benutzer_id');
    await prefs.remove('firma_id');
    await prefs.remove('benutzer_name');
    state = const AsyncData(AppModus.solo);
  }
}

final appModusProvider =
    AsyncNotifierProvider<AppModusNotifier, AppModus>(AppModusNotifier.new);

final currentUserProvider = FutureProvider<Map<String, String?>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return {
    'token': prefs.getString('jwt_token'),
    'benutzerId': prefs.getString('benutzer_id'),
    'firmaId': prefs.getString('firma_id'),
    'name': prefs.getString('benutzer_name'),
  };
});
