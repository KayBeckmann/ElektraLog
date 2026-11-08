import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_service.dart';
import 'app_mode_provider.dart';

/// Prüfmodule einer Firma (Roadmap Geräteprüfung M1). Ein abgeschaltetes
/// Modul wird nur ausgeblendet — Daten bleiben lokal und auf dem Server
/// erhalten und synchronisieren weiter.
class FirmenModule {
  const FirmenModule({
    required this.anlagenpruefung,
    required this.geraetepruefung,
  });

  /// Stand bestehender Installationen und Firmen: nur Anlagenprüfung
  /// (Kay, 2026-11-08). Neue Firmen legt der Server mit beiden an.
  static const bestand =
      FirmenModule(anlagenpruefung: true, geraetepruefung: false);

  final bool anlagenpruefung;
  final bool geraetepruefung;

  bool get beide => anlagenpruefung && geraetepruefung;
  bool get keines => !anlagenpruefung && !geraetepruefung;

  factory FirmenModule.fromJson(Map<String, dynamic> json) => FirmenModule(
        anlagenpruefung: json['anlagenpruefung'] as bool? ?? true,
        geraetepruefung: json['geraetepruefung'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      other is FirmenModule &&
      other.anlagenpruefung == anlagenpruefung &&
      other.geraetepruefung == geraetepruefung;

  @override
  int get hashCode => Object.hash(anlagenpruefung, geraetepruefung);
}

/// Server-Zugriff, in Tests ersetzbar.
abstract class ModuleApi {
  Future<FirmenModule?> laden();
  Future<FirmenModule> speichern(FirmenModule module);
}

class _ServerModuleApi implements ModuleApi {
  @override
  Future<FirmenModule?> laden() async {
    final module = (await ApiService.getFirma())['module'];
    // Älterer Server ohne Module → lokaler Stand bleibt.
    return module is Map<String, dynamic> ? FirmenModule.fromJson(module) : null;
  }

  @override
  Future<FirmenModule> speichern(FirmenModule module) async =>
      FirmenModule.fromJson(await ApiService.updateModule(
        anlagenpruefung: module.anlagenpruefung,
        geraetepruefung: module.geraetepruefung,
      ));
}

final moduleApiProvider = Provider<ModuleApi>((ref) => _ServerModuleApi());

// Getrennte Schlüssel: Solo-Einstellung und zuletzt bekannter Firmenstand
// (für offline) überschreiben sich nicht gegenseitig.
const _kSoloAnlagen = 'module.solo.anlagenpruefung';
const _kSoloGeraete = 'module.solo.geraetepruefung';
const _kFirmaAnlagen = 'module.firma.anlagenpruefung';
const _kFirmaGeraete = 'module.firma.geraetepruefung';

class ModuleNotifier extends AsyncNotifier<FirmenModule> {
  bool get _company => ref.read(appModusProvider).valueOrNull == AppModus.company;

  @override
  Future<FirmenModule> build() async {
    final modus = await ref.watch(appModusProvider.future);
    final prefs = await SharedPreferences.getInstance();
    if (modus == AppModus.solo) return _lesen(prefs, _kSoloAnlagen, _kSoloGeraete);

    final zwischengespeichert = _lesen(prefs, _kFirmaAnlagen, _kFirmaGeraete);
    try {
      final vomServer = await ref.read(moduleApiProvider).laden();
      if (vomServer == null) return zwischengespeichert;
      await _schreiben(prefs, _kFirmaAnlagen, _kFirmaGeraete, vomServer);
      return vomServer;
    } catch (_) {
      // Offline: zuletzt bekannter Firmenstand.
      return zwischengespeichert;
    }
  }

  /// Solo: lokal speichern. Firma: auf dem Server (nur Firmenadmin, der
  /// Server lehnt andere mit [ApiException] 403 ab) und danach lokal.
  Future<void> setzen(FirmenModule module) async {
    final prefs = await SharedPreferences.getInstance();
    if (_company) {
      final gespeichert = await ref.read(moduleApiProvider).speichern(module);
      await _schreiben(prefs, _kFirmaAnlagen, _kFirmaGeraete, gespeichert);
      state = AsyncData(gespeichert);
    } else {
      await _schreiben(prefs, _kSoloAnlagen, _kSoloGeraete, module);
      state = AsyncData(module);
    }
  }

  static FirmenModule _lesen(SharedPreferences prefs, String anlagen, String geraete) =>
      FirmenModule(
        anlagenpruefung: prefs.getBool(anlagen) ?? FirmenModule.bestand.anlagenpruefung,
        geraetepruefung: prefs.getBool(geraete) ?? FirmenModule.bestand.geraetepruefung,
      );

  static Future<void> _schreiben(
      SharedPreferences prefs, String anlagen, String geraete, FirmenModule m) async {
    await prefs.setBool(anlagen, m.anlagenpruefung);
    await prefs.setBool(geraete, m.geraetepruefung);
  }
}

final moduleProvider =
    AsyncNotifierProvider<ModuleNotifier, FirmenModule>(ModuleNotifier.new);

/// Bequemer synchroner Zugriff für die UI: solange noch geladen wird, gilt
/// der Bestandsstand (Anlagenprüfung sichtbar, nichts verschwindet kurz).
final aktiveModuleProvider = Provider<FirmenModule>(
  (ref) => ref.watch(moduleProvider).valueOrNull ?? FirmenModule.bestand,
);
