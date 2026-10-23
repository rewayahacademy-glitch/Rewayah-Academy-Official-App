// Le harnais d'`ADM-20` : la file des candidatures montee sur un routeur de
// test, avec le double du port de la direction (ou aucun port).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/recrutement/port_invitations_comptable.dart';
import 'package:rewayah_academy/core/recrutement/port_invitations_enseignant.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/admin_candidatures/candidatures_page.dart';
import 'package:rewayah_academy/features/demo/recrutement_demo.dart';

import '../../support/monter_recrutement.dart';

/// Monte la file des candidatures.
///
/// [port] nul : aucun port (la capacite indisponible). [ouvrir] et [agir]
/// sont les destinations d'`ADM-21` et d'`ADM-22` ; nulles, comme dans le
/// routeur d'aujourd'hui, la ligne ne s'ouvre pas et « Agir sur la selection »
/// n'est pas rendu. [invitations] pose le port des invitations
/// d'enseignant, [comptable] celui des invitations de comptable.
Future<void> monterCandidatures(
  WidgetTester tester, {
  PortCandidaturesDirection? port,
  bool horsLigne = false,
  double largeur = 390,
  double hauteur = 3000,
  double echelle = 1,
  TextDirection? direction,
  void Function(LigneCandidature ligne)? ouvrir,
  void Function(List<String> identifiants)? agir,
  bool invitations = false,
  bool comptable = false,
}) => monterRecrutement(
  tester,
  chemin: Routes.adminPersonnesCandidatures,
  ecran: (_) => CandidaturesPage(
    ouvrirCandidature: ouvrir,
    agirSurSelection: agir,
  ),
  autres: const <String>[Routes.adminPersonnesInvitations],
  surcharges: <Override>[
    portCandidaturesDirectionProvider.overrideWithValue(port),
    portInvitationsEnseignantProvider.overrideWithValue(
      invitations ? InvitationsDemo() : null,
    ),
    portInvitationsComptableProvider.overrideWithValue(
      comptable ? InvitationsDemo() : null,
    ),
  ],
  horsLigne: horsLigne,
  largeur: largeur,
  hauteur: hauteur,
  echelle: echelle,
  direction: direction,
);
