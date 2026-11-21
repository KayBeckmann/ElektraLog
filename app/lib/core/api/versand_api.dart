import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_service.dart';

/// SMTP-Zugang und Protokollversand (Roadmap 20./21.11.2026). Eigene
/// Schnittstelle, damit Widget-Tests sie per Provider ersetzen können.
class VersandApi {
  const VersandApi();

  Future<Map<String, dynamic>> getSmtp() => ApiService.getSmtp();

  Future<Map<String, dynamic>> putSmtp({
    required String host,
    required int port,
    required String tlsModus,
    required String absenderEmail,
    String? absenderName,
    String? benutzer,
    String? passwort,
  }) =>
      ApiService.putSmtp(
        host: host,
        port: port,
        tlsModus: tlsModus,
        absenderEmail: absenderEmail,
        absenderName: absenderName,
        benutzer: benutzer,
        passwort: passwort,
      );

  Future<void> deleteSmtp() => ApiService.deleteSmtp();

  Future<void> testSmtp(String empfaenger) => ApiService.testSmtp(empfaenger);

  Future<Map<String, dynamic>> info(String protokollId) => ApiService.getVersandInfo(protokollId);

  Future<Map<String, dynamic>> senden({
    required String protokollId,
    required String anfrageId,
    required String empfaenger,
    List<String> cc = const [],
    required String pdfHash,
  }) =>
      ApiService.sendeProtokoll(
        protokollId: protokollId,
        anfrageId: anfrageId,
        empfaenger: empfaenger,
        cc: cc,
        pdfHash: pdfHash,
      );

  Future<Uint8List> pdf(String protokollId) => ApiService.getProtokollPdf(protokollId);
}

final versandApiProvider = Provider<VersandApi>((ref) => const VersandApi());
