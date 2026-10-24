// Le harnais d'`ADM-21` : la candidature ouverte sur un routeur de test, avec
// le double du port de la direction (ou aucun port).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/champ_date.dart';
import 'package:rewayah_academy/features/admin_candidature/candidature_page.dart';

import '../../support/monter_recrutement.dart';

/// La reference des dossiers de test (`detailTest(id: 'c1')`).
const String referenceTest = 'CAND-0000C1';

/// Le jour que lisent les formulaires des feuilles : fixe, pour que les bornes
/// des calendriers ne bougent pas avec le jour du test.
final DateTime jourDuTest = DateTime.utc(2026, 10, 22, 12);

/// Monte la candidature [reference].
///
/// [port] nul : aucun port (la capacite indisponible). [identifiant] nul :
/// l'adresse a ete tapee, la reference est resolue par la file. [maintenant] :
/// l'heure que lisent les formulaires des feuilles (par defaut [jourDuTest]).
Future<void> monterCandidature(
  WidgetTester tester, {
  PortCandidaturesDirection? port,
  String reference = referenceTest,
  String? identifiant = 'c1',
  bool horsLigne = false,
  double largeur = 390,
  double hauteur = 3000,
  double echelle = 1,
  TextDirection? direction,
  DateTime? maintenant,
  List<Override> surcharges = const <Override>[],
}) => monterRecrutement(
  tester,
  chemin: Routes.adminPersonnesCandidature,
  depart: Routes.adminPersonnesCandidaturePour(reference),
  ecran: (_) =>
      CandidatureDirectionPage(reference: reference, identifiant: identifiant),
  autres: const <String>[
    Routes.adminPersonnesCandidatures,
    Routes.adminPersonnesDossiers,
  ],
  surcharges: <Override>[
    portCandidaturesDirectionProvider.overrideWithValue(port),
    horlogeFormulairesProvider.overrideWithValue(
      () => maintenant ?? jourDuTest,
    ),
    ...surcharges,
  ],
  horsLigne: horsLigne,
  largeur: largeur,
  hauteur: hauteur,
  echelle: echelle,
  direction: direction,
);
