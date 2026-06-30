import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_mode_provider.dart';

/// Granulare Berechtigungen pro Rolle, abgeleitet aus der Obsidian-Inbox
/// "Rollen"-Notiz: Firmenadmin und Projektleiter haben vollen Zugriff auf
/// Stammdaten (Kunden/Standorte), Monteur darf anlegen, aber nur bearbeiten
/// und löschen wenn keine abhängigen Daten (Standorte/Messungen) dranhängen.
class Berechtigungen {
  final String rolle;
  const Berechtigungen(this.rolle);

  bool get istFirmenadmin => rolle == rolleFirmenadmin;
  bool get istProjektleiter => rolle == rolleProjektleiter;
  bool get istMonteur => rolle == rolleMonteur;

  /// Firmenadmin/Projektleiter dürfen Stammdaten uneingeschränkt verwalten.
  bool get hatVollzugriff => istFirmenadmin || istProjektleiter;

  /// Kunden/Standorte/Struktur anlegen dürfen alle drei Rollen.
  bool get kannAnlegen => true;

  /// Bearbeiten/Löschen: Firmenadmin/Projektleiter immer, Monteur nur wenn
  /// keine abhängigen Daten (Standorte unter dem Kunden, Messungen unter der
  /// Komponente, ...) existieren.
  bool kannBearbeitenOderLoeschen({required bool hatAbhaengigeDaten}) {
    if (hatVollzugriff) return true;
    return !hatAbhaengigeDaten;
  }

  /// Userverwaltung des Mandanten ist Firmenadmin vorbehalten.
  bool get kannUserVerwalten => istFirmenadmin;
}

final berechtigungenProvider = FutureProvider<Berechtigungen>((ref) async {
  final rolle = await ref.watch(rolleProvider.future);
  return Berechtigungen(rolle);
});
