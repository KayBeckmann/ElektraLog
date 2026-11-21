import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show Random;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart';
import 'package:pointycastle/export.dart';

/// SMTP-Zugang einer Firma (entschlüsselt, nur im Speicher).
class SmtpZugang {
  const SmtpZugang({
    required this.host,
    required this.port,
    required this.tlsModus,
    required this.absenderEmail,
    this.absenderName,
    this.benutzer,
    this.passwort,
  });

  final String host;
  final int port;

  /// `ssl` (direkt verschlüsselt, meist 465), `starttls` (meist 587,
  /// bricht ab, wenn der Server kein STARTTLS kann) oder `keine`.
  final String tlsModus;
  final String absenderEmail;
  final String? absenderName;
  final String? benutzer;
  final String? passwort;
}

class MailAnhang {
  const MailAnhang(this.dateiname, this.bytes, {this.mimeTyp = 'application/pdf'});
  final String dateiname;
  final Uint8List bytes;
  final String mimeTyp;
}

class MailNachricht {
  const MailNachricht({
    required this.an,
    this.cc = const [],
    required this.betreff,
    required this.text,
    this.anhaenge = const [],
  });

  final String an;
  final List<String> cc;
  final String betreff;
  final String text;
  final List<MailAnhang> anhaenge;
}

/// Fehler beim Versand mit verständlicher deutscher Meldung (ohne
/// Zugangsdaten — landet im Versandprotokoll und in der API-Antwort).
class MailVersandFehler implements Exception {
  MailVersandFehler(this.meldung);
  final String meldung;
  @override
  String toString() => meldung;
}

/// Versandweg, in Tests durch eine Attrappe ersetzt.
abstract class MailVersand {
  Future<void> senden(SmtpZugang zugang, MailNachricht nachricht);
}

class SmtpMailVersand implements MailVersand {
  const SmtpMailVersand({this.timeout = const Duration(seconds: 30)});
  final Duration timeout;

  @override
  Future<void> senden(SmtpZugang zugang, MailNachricht nachricht) async {
    final server = SmtpServer(
      zugang.host,
      port: zugang.port,
      ssl: zugang.tlsModus == 'ssl',
      allowInsecure: zugang.tlsModus == 'keine',
      username: zugang.benutzer,
      password: zugang.passwort,
    );
    final message = mailer.Message()
      ..from = mailer.Address(zugang.absenderEmail, zugang.absenderName)
      ..recipients.add(nachricht.an)
      ..ccRecipients.addAll(nachricht.cc)
      ..subject = nachricht.betreff
      ..text = nachricht.text
      ..attachments.addAll([
        for (final a in nachricht.anhaenge)
          mailer.StreamAttachment(Stream.value(a.bytes), a.mimeTyp, fileName: a.dateiname),
      ]);
    try {
      await mailer.send(message, server, timeout: timeout);
    } on mailer.SmtpClientAuthenticationException {
      throw MailVersandFehler('Anmeldung am SMTP-Server fehlgeschlagen — Benutzername/Passwort prüfen.');
    } on mailer.SmtpUnsecureException {
      throw MailVersandFehler('Der SMTP-Server bietet keine verschlüsselte Verbindung (STARTTLS) an.');
    } on mailer.SmtpNoGreetingException {
      throw MailVersandFehler('Der SMTP-Server antwortet nicht wie erwartet — Port und TLS-Modus prüfen.');
    } on mailer.MailerException catch (e) {
      throw MailVersandFehler('Versand abgelehnt: ${e.message}');
    } on SocketException catch (e) {
      throw MailVersandFehler('SMTP-Server nicht erreichbar (${zugang.host}:${zugang.port}): ${e.osError?.message ?? e.message}');
    } on HandshakeException {
      throw MailVersandFehler('TLS-Verbindung fehlgeschlagen — TLS-Modus und Port prüfen.');
    } on TimeoutException {
      throw MailVersandFehler('Zeitüberschreitung beim SMTP-Server.');
    }
  }
}

/// Verschlüsselt das SMTP-Passwort für die Datenbank (AES-256-GCM).
/// Schlüssel: `SMTP_SCHLUESSEL` aus der Umgebung, sonst aus dem
/// JWT-Secret abgeleitet. Wechselt der Schlüssel, ist das gespeicherte
/// Passwort nicht mehr lesbar und muss in den Firmeneinstellungen neu
/// eingegeben werden.
class SmtpGeheimnis {
  SmtpGeheimnis(String geheimnis)
      : _schluessel = Uint8List.fromList(sha256.convert(utf8.encode('elektralog-smtp|$geheimnis')).bytes);

  final Uint8List _schluessel;

  String verschluesseln(String klartext) {
    final nonce = _zufall(12);
    final daten = _gcm(true, nonce).process(Uint8List.fromList(utf8.encode(klartext)));
    return 'v1:${base64Encode(nonce)}:${base64Encode(daten)}';
  }

  /// `null`, wenn der Wert mit einem anderen Schlüssel verschlüsselt wurde.
  String? entschluesseln(String gespeichert) {
    final teile = gespeichert.split(':');
    if (teile.length != 3 || teile[0] != 'v1') return null;
    try {
      final klar = _gcm(false, base64Decode(teile[1])).process(base64Decode(teile[2]));
      return utf8.decode(klar);
    } on InvalidCipherTextException {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  GCMBlockCipher _gcm(bool verschluesseln, Uint8List nonce) =>
      GCMBlockCipher(AESEngine())..init(verschluesseln, AEADParameters(KeyParameter(_schluessel), 128, nonce, Uint8List(0)));

  static Uint8List _zufall(int laenge) {
    final r = Random.secure();
    return Uint8List.fromList([for (var i = 0; i < laenge; i++) r.nextInt(256)]);
  }
}
