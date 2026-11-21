/// Bewusst einfache Prüfung (ein @, Domain mit Punkt, keine Leerzeichen),
/// gleiche Regel wie auf dem Server (`emailGueltig` in sync_typen.dart).
bool emailGueltig(String s) =>
    RegExp(r'^[^@\s,;<>]+@[^@\s,;<>]+\.[^@\s,;<>]+$').hasMatch(s);

/// Validator für optionale E-Mail-Felder: leer ist erlaubt.
String? optionaleEmailPruefen(String? v) {
  final t = v?.trim() ?? '';
  if (t.isEmpty || emailGueltig(t)) return null;
  return 'Keine gültige E-Mail-Adresse';
}
