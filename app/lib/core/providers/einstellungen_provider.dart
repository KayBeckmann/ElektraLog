import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Modell ────────────────────────────────────────────────────────────────────

class Einstellungen {
  const Einstellungen({
    this.prueferName,
    this.firma,
    this.pruefgeraet,
  });

  final String? prueferName;
  final String? firma;
  final String? pruefgeraet;
}

// ── Keys ──────────────────────────────────────────────────────────────────────

const _kPruefer = 'einstellungen.pruefer';
const _kFirma = 'einstellungen.firma';
const _kPruefgeraet = 'einstellungen.pruefgeraet';

// ── Notifier ──────────────────────────────────────────────────────────────────

class EinstellungenNotifier extends AsyncNotifier<Einstellungen> {
  @override
  Future<Einstellungen> build() async {
    final prefs = await SharedPreferences.getInstance();
    return Einstellungen(
      prueferName: prefs.getString(_kPruefer),
      firma: prefs.getString(_kFirma),
      pruefgeraet: prefs.getString(_kPruefgeraet),
    );
  }

  Future<void> save(
    String prueferName,
    String firma,
    String pruefgeraet,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPruefer, prueferName);
    await prefs.setString(_kFirma, firma);
    await prefs.setString(_kPruefgeraet, pruefgeraet);
    state = AsyncData(
      Einstellungen(
        prueferName: prueferName.isEmpty ? null : prueferName,
        firma: firma.isEmpty ? null : firma,
        pruefgeraet: pruefgeraet.isEmpty ? null : pruefgeraet,
      ),
    );
  }
}

final einstellungenProvider =
    AsyncNotifierProvider<EinstellungenNotifier, Einstellungen>(
  EinstellungenNotifier.new,
);
