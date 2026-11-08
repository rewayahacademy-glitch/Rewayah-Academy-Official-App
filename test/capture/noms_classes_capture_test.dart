// Captures du lot NOMS-CLASSES (08/11/2026) : la feuille « Nouvelle classe »
// sans champ de nom (une phrase dit qu'il est choisi automatiquement), et la
// feuille « Changer le nom », en fr et en ar, a 390 et 1440.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.
// Donnees inventees (les doublures de test/features/support_form_l2.dart).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_creation_classe.dart';
import 'package:rewayah_academy/core/capacites/port_enseignants_classe.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart'
    show Creneau;
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/features/admin_groupes/groupes_page.dart';

import '../features/support_form_l2.dart';
import '../support/harnais.dart' show FauxServiceReseau;
import 'outil_capture.dart';

final List<EnseignantPropose> _enseignants = <EnseignantPropose>[
  const EnseignantPropose(
    id: 'f1',
    libelle: 'Enseignante Essai',
    identifiant: 'ENS-EE-103',
    genre: GenreEnseignant.femme,
    creneauxLibres: <Creneau>[
      Creneau(jour: 2, heure: 17, fuseau: 'Europe/Paris'),
    ],
    classesActives: 1,
    fuseauIana: 'Europe/Paris',
  ),
];

List<Override> _surcharges() => <Override>[
  ...surchargesFormL2(
    comptes: FauxComptesFormL2(comptesFormL2),
    groupes: FauxGroupesFormL2(),
  ),
  portEnseignantsClasseProvider.overrideWithValue(
    FauxEnseignantsClasse(_enseignants),
  ),
  portCreationClasseProvider.overrideWithValue(FauxCreationClasse()),
  serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
];

Future<void> _presser(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('Capture : NOMS-CLASSES', skip: sautSansCapture, () {
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Size vue in <Size>[
        const Size(390, 844),
        const Size(1440, 900),
      ]) {
        final String suffixe = '${langue.languageCode}_${vue.width.toInt()}';

        testWidgets('nouvelle classe sans champ de nom, $suffixe', (
          WidgetTester tester,
        ) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          fixerVueCapture(tester, vue, 1);
          await tester.pumpWidget(
            hoteCapture(const GroupesPage(), surcharges: _surcharges()),
          );
          await stabiliser(tester);
          await _presser(tester, find.byKey(GroupesPage.cleCreer));
          await _presser(
            tester,
            find.byKey(const ValueKey<String>('classe-genre-femmes')),
          );
          await tester.ensureVisible(
            find.byKey(const ValueKey<String>('classe-nom-automatique')),
          );
          await stabiliser(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'nouvelle_classe_nom_automatique_$suffixe')}',
          );
        });

        testWidgets('changer le nom, $suffixe', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          fixerVueCapture(tester, vue, 1);
          await tester.pumpWidget(
            hoteCapture(const GroupesPage(), surcharges: _surcharges()),
          );
          await stabiliser(tester);
          await _presser(tester, find.byType(MenuActions).first);
          await _presser(
            tester,
            find.text(t.admin.groupes.nomClasse.action).last,
          );
          await stabiliser(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'changer_le_nom_$suffixe')}',
          );
        });
      }
    }
  });
}
