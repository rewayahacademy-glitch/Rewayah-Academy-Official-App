// Faux du lot D, sous-paquet 3 : un service d'appairage qui relit ce qu'il
// revoque et sait echouer ou ne jamais repondre, et un service de l'appareil
// eleve dont l'ouverture de connexion se pilote.

import 'dart:async';

import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/appairage/service_enfant.dart';
import 'package:rewayah_academy/core/domain/enums.dart';

import '../../support/harnais.dart';

/// Un profil eleve du foyer.
EleveDuFoyer eleveDeTest({String id = 'e1', String prenom = 'Amina'}) =>
    EleveDuFoyer(
      id: id,
      prenom: prenom,
      identifiantImmuable: 'STUDENT-AD-$id',
      mode: InterfaceMode.enfant,
      camera: CameraPolicy.forbidden,
    );

/// Un appareil appaire.
AppareilAppaire appareilDeTest({
  String id = 'd1',
  String profilId = 'e1',
  String plateforme = 'android',
  DateTime? appaireA,
  DateTime? derniereUtilisation,
  DateTime? revoqueA,
}) => AppareilAppaire(
  id: id,
  profilId: profilId,
  prenom: 'Amina',
  plateforme: plateforme,
  appaireA: appaireA ?? DateTime(2026, 9, 1, 10),
  derniereUtilisation: derniereUtilisation,
  revoqueA: revoqueA,
);

/// Le service d'appairage du tuteur, pilote par le test.
///
/// Comme la base : un appareil revoque reste dans la vue, avec sa date de
/// revocation ; l'ecran relit et ne le montre plus.
class FauxAppairagePilote extends FauxServiceAppairage {
  /// Ce que la lecture des eleves doit jeter.
  Object? erreurLecture;

  /// Tant qu'il n'est pas complete, la lecture des eleves ne rend pas la main.
  Completer<void>? attenteLecture;

  /// Ce que le prochain retrait doit jeter.
  Object? erreurRetrait;

  /// Tant qu'il n'est pas complete, le retrait ne rend pas la main.
  Completer<void>? attenteRetrait;

  /// Nombre de lectures des eleves.
  int lectures = 0;

  @override
  Future<List<EleveDuFoyer>> eleves() async {
    lectures++;
    final Completer<void>? a = attenteLecture;
    if (a != null) {
      await a.future;
    }
    final Object? erreur = erreurLecture;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
    return elevesRendus;
  }

  @override
  Future<void> revoquer(String appareilId) async {
    final Completer<void>? a = attenteRetrait;
    if (a != null) {
      await a.future;
    }
    final Object? erreur = erreurRetrait;
    if (erreur != null) {
      // ignore: only_throw_errors
      throw erreur;
    }
    revocations.add(appareilId);
    appareilsRendus = <AppareilAppaire>[
      for (final AppareilAppaire a in appareilsRendus)
        if (a.id != appareilId)
          a
        else
          AppareilAppaire(
            id: a.id,
            profilId: a.profilId,
            prenom: a.prenom,
            plateforme: a.plateforme,
            appaireA: a.appaireA,
            derniereUtilisation: a.derniereUtilisation,
            revoqueA: DateTime(2026, 9, 24, 12),
          ),
    ];
  }
}

/// Le service de l'appareil eleve : appairage fixe, ouverture pilotee.
class FauxEnfantOuverture implements ServiceEnfant {
  /// Ce que le prochain appairage rendra.
  AppairageReussi reponse = const AppairageReussi(
    profilId: 'e3',
    prenom: 'Salam',
    jetonAppareil: 'jeton-e3',
  );

  /// Le refus a lever a l'ouverture, a la place du succes.
  Object? refusOuverture;

  /// Les codes d'appairage recus.
  final List<String> codesRecus = <String>[];

  /// Les jetons presentes a l'ouverture, dans l'ordre.
  final List<String> jetonsOuverts = <String>[];

  @override
  Future<AppairageReussi> appairer({
    required String code,
    required String empreinteAppareil,
    required String plateforme,
  }) async {
    codesRecus.add(code);
    return reponse;
  }

  /// Quand il est pose, [ouvrirSession] attend sa fin (jamais, s'il n'est
  /// jamais complete : serveur muet).
  Completer<void>? attenteOuverture;

  @override
  Future<void> ouvrirSession(String jetonAppareil) async {
    jetonsOuverts.add(jetonAppareil);
    final Completer<void>? attente = attenteOuverture;
    if (attente != null) {
      await attente.future;
    }
    final Object? refus = refusOuverture;
    if (refus != null) {
      // ignore: only_throw_errors
      throw refus;
    }
  }
}
