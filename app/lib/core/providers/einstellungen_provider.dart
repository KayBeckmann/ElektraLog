import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';

// ── Modell ────────────────────────────────────────────────────────────────────

class Einstellungen {
  const Einstellungen({
    this.prueferName,
    this.firma,
    this.firmaStrasse,
    this.firmaPlz,
    this.firmaOrt,
    this.pruefgeraet,
    this.serverUrl,
  });

  final String? prueferName;
  final String? firma;
  final String? firmaStrasse;
  final String? firmaPlz;
  final String? firmaOrt;
  final String? pruefgeraet;
  /// Backend-URL für die Android-App (z.B. https://meinserver.de:8080)
  final String? serverUrl;

  /// Vollständige Adresse als einzeiligen String (leer wenn keine Daten)
  String get firmaAdresse {
    final parts = <String>[];
    if (firmaStrasse?.isNotEmpty == true) parts.add(firmaStrasse!);
    final ort = [
      if (firmaPlz?.isNotEmpty == true) firmaPlz!,
      if (firmaOrt?.isNotEmpty == true) firmaOrt!,
    ].join(' ');
    if (ort.isNotEmpty) parts.add(ort);
    return parts.join(', ');
  }
}

// ── Keys ──────────────────────────────────────────────────────────────────────

const _kPruefer    = 'einstellungen.pruefer';
const _kFirma      = 'einstellungen.firma';
const _kStrasse    = 'einstellungen.firmaStrasse';
const _kPlz        = 'einstellungen.firmaPlz';
const _kOrt        = 'einstellungen.firmaOrt';
const _kPruefgeraet = 'einstellungen.pruefgeraet';
const _kServerUrl  = 'einstellungen.serverUrl';

// ── Notifier ──────────────────────────────────────────────────────────────────

class EinstellungenNotifier extends AsyncNotifier<Einstellungen> {
  @override
  Future<Einstellungen> build() async {
    final prefs = await SharedPreferences.getInstance();
    final serverUrl = prefs.getString(_kServerUrl);
    ApiService.setServerUrl(serverUrl);
    return Einstellungen(
      prueferName: prefs.getString(_kPruefer),
      firma:       prefs.getString(_kFirma),
      firmaStrasse: prefs.getString(_kStrasse),
      firmaPlz:    prefs.getString(_kPlz),
      firmaOrt:    prefs.getString(_kOrt),
      pruefgeraet: prefs.getString(_kPruefgeraet),
      serverUrl:   serverUrl,
    );
  }

  Future<void> save({
    required String prueferName,
    required String firma,
    required String firmaStrasse,
    required String firmaPlz,
    required String firmaOrt,
    required String pruefgeraet,
    required String serverUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPruefer, prueferName);
    await prefs.setString(_kFirma, firma);
    await prefs.setString(_kStrasse, firmaStrasse);
    await prefs.setString(_kPlz, firmaPlz);
    await prefs.setString(_kOrt, firmaOrt);
    await prefs.setString(_kPruefgeraet, pruefgeraet);
    await prefs.setString(_kServerUrl, serverUrl);
    ApiService.setServerUrl(serverUrl.isEmpty ? null : serverUrl);
    state = AsyncData(Einstellungen(
      prueferName:  prueferName.isEmpty  ? null : prueferName,
      firma:        firma.isEmpty        ? null : firma,
      firmaStrasse: firmaStrasse.isEmpty ? null : firmaStrasse,
      firmaPlz:     firmaPlz.isEmpty     ? null : firmaPlz,
      firmaOrt:     firmaOrt.isEmpty     ? null : firmaOrt,
      pruefgeraet:  pruefgeraet.isEmpty  ? null : pruefgeraet,
      serverUrl:    serverUrl.isEmpty    ? null : serverUrl,
    ));
  }
}

final einstellungenProvider =
    AsyncNotifierProvider<EinstellungenNotifier, Einstellungen>(
  EinstellungenNotifier.new,
);
