// Le harnais d'`ADM-21` : la candidature ouverte sur un routeur de test, avec
// le double du port de la direction (ou aucun port).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/champ_date.dart';
import 'package:rewayah_academy/features/admin_candidature/candidature_page.dart';
import 'package:rewayah_academy/features/admin_candidature/dossier_trois_etages.dart';
import 'package:rewayah_academy/features/admin_candidature/plan_dossier.dart';

import '../../support/monter_recrutement.dart';

/// La reference des dossiers de test (`detailTest(id: 'c1')`).
const String referenceTest = 'CAND-0000C1';

/// Le jour que lisent les formulaires des feuilles : fixe, pour que les bornes
/// des calendriers ne bougent pas avec le jour du test.
final DateTime jourDuTest = DateTime.utc(2026, 10, 22, 12);

/// Ouvre toutes les rubriques du dossier (BE-DOSSIER) : un test qui lit le
/// contenu d'une rubrique la voit ouverte, comme dans l'ancienne page. Une
/// rubrique deja ouverte (c'est elle qui bloque) le reste.
Future<void> ouvrirToutesLesRubriques(WidgetTester tester) async {
  for (final RubriqueDossierCode c in RubriqueDossierCode.values) {
    if (find.byKey(RubriqueDossier.cleContenu(c)).evaluate().isNotEmpty) {
      continue;
    }
    final Finder entete = find.byKey(RubriqueDossier.cleEntete(c));
    if (entete.evaluate().isEmpty) continue;
    await tester.ensureVisible(entete);
    await laisser(tester, fois: 2);
    await tester.tap(entete, warnIfMissed: false);
    await laisser(tester);
  }
}

/// Monte la candidature [reference].
///
/// [ouvrirRubriques] : vrai (par defaut), toutes les rubriques sont ouvertes
/// apres le montage ; faux, le dossier reste tel qu'il s'ouvre (replie).
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
  bool ouvrirRubriques = true,
}) async {
  await monterRecrutement(
    tester,
    chemin: Routes.adminPersonnesCandidature,
    depart: Routes.adminPersonnesCandidaturePour(reference),
    ecran: (_) => CandidatureDirectionPage(
      reference: reference,
      identifiant: identifiant,
    ),
    autres: const <String>[
      Routes.adminPersonnesCandidatures,
      Routes.adminPersonnesDossiers,
      // VISION-RECRUTEMENT : « Rejoindre l'entretien » y mene, billet en extra.
      Routes.salle,
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
  if (ouvrirRubriques) await ouvrirToutesLesRubriques(tester);
}
