import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:rewayah_academy/core/appairage/lecteur_qr.dart';
import 'package:rewayah_academy/core/appairage/service_enfant.dart';

/// Le lecteur de QR, sans camera (tests du lot D uniquement).
class FauxLecteurQr implements LecteurQr {
  /// Cree le lecteur ; [reponses] sont rendues dans l'ordre, puis [defaut].
  FauxLecteurQr({
    this.defaut = EtatCamera.pret,
    List<EtatCamera>? reponses,
  }) : _reponses = <EtatCamera>[...?reponses];

  /// La cle de la fausse vue de camera.
  static const Key apercuKey = ValueKey<String>('faux-apercu-camera');

  /// Ce que [demarrer] rend une fois [_reponses] epuisees.
  EtatCamera defaut;
  final List<EtatCamera> _reponses;

  /// Tant qu'il n'est pas complete, [demarrer] ne rend pas la main.
  Completer<void>? attente;

  /// Nombre de demarrages demandes.
  int demarrages = 0;

  /// Nombre d'arrets demandes.
  int arrets = 0;

  /// Vrai une fois la camera rendue.
  bool libere = false;

  /// Vrai quand la camera tourne.
  bool enMarche = false;

  final StreamController<String> _lectures =
      StreamController<String>.broadcast();

  /// Simule la detection d'un QR code de contenu [brut].
  void lire(String brut) => _lectures.add(brut);

  @override
  Stream<String> get lectures => _lectures.stream;

  @override
  Widget apercu() => const SizedBox.expand(key: apercuKey);

  @override
  Future<EtatCamera> demarrer() async {
    demarrages++;
    final Completer<void>? a = attente;
    if (a != null) {
      await a.future;
    }
    final EtatCamera etat = _reponses.isNotEmpty
        ? _reponses.removeAt(0)
        : defaut;
    enMarche = etat == EtatCamera.pret;
    return etat;
  }

  @override
  Future<void> arreter() async {
    arrets++;
    enMarche = false;
  }

  @override
  Future<void> liberer() async {
    libere = true;
    enMarche = false;
    await _lectures.close();
  }
}

/// Le service d'appairage de l'appareil eleve, pilote par le test.
class FauxServiceEnfantPilote implements ServiceEnfant {
  /// Ce que le prochain appairage rendra.
  AppairageReussi reponse = const AppairageReussi(
    profilId: 'e1',
    prenom: 'Amina',
    jetonAppareil: 'jeton-test',
  );

  /// Le refus a lever a la place de [reponse].
  MotifRefusAppairage? refus;

  /// Tant qu'il n'est pas complete, [appairer] ne rend pas la main.
  Completer<void>? attente;

  /// Les codes recus, dans l'ordre.
  final List<String> codesRecus = <String>[];

  /// Nombre de sessions ouvertes.
  int sessionsOuvertes = 0;

  @override
  Future<AppairageReussi> appairer({
    required String code,
    required String empreinteAppareil,
    required String plateforme,
  }) async {
    codesRecus.add(code);
    final Completer<void>? a = attente;
    if (a != null) {
      await a.future;
    }
    final MotifRefusAppairage? motif = refus;
    if (motif != null) {
      throw AppairageRefuse(motif);
    }
    return reponse;
  }

  @override
  Future<void> ouvrirSession(String jetonAppareil) async {
    sessionsOuvertes++;
  }
}
