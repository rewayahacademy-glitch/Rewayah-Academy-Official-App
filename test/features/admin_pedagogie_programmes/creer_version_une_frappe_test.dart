import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_programme.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_pedagogie_programmes/programmes_page.dart';

import '../../support/harnais.dart';

/// Un service de programme en memoire, sans aucune version.
class _FauxProgramme implements ServiceProgramme {
  int creations = 0;

  @override
  Future<List<VersionProgramme>> versions() async => const <VersionProgramme>[];

  @override
  Future<List<NiveauProgramme>> niveaux(String versionId) async =>
      const <NiveauProgramme>[];

  @override
  Future<String> creerVersion({String? versionSourceId}) async {
    creations++;
    return 'v1';
  }

  @override
  Future<String> ajouterNiveau({
    required String versionId,
    required String codeTechnique,
    required String nomHumain,
    required String cycle,
    required int ordre,
    String? description,
  }) async => 'n1';

  @override
  Future<void> modifierNiveau({
    required String niveauId,
    required String nomHumain,
    required String cycle,
    required int ordre,
    String? description,
  }) async {}

  @override
  Future<void> supprimerNiveau({
    required String niveauId,
    required String motif,
  }) async {}

  @override
  Future<void> publierVersion({
    required String versionId,
    required String motif,
  }) async {}
}

/// BUG-PROG-1 (revue du directeur) : « il faut cliquer deux fois sur
/// « Créer une version » pour ouvrir la feuille ». La feuille reprenait le
/// meme libelle pour son bouton d'envoi : apres la premiere frappe, le
/// directeur voyait encore « Créer une version » et croyait devoir recliquer.
void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  for (final Size cadre in <Size>[
    const Size(390, 844), // telephone : feuille de bas d'ecran
    const Size(1400, 1000), // bureau, PWA Chrome : boite de dialogue
  ]) {
    testWidgets('une seule frappe ouvre la feuille, dont le bouton d envoi '
        'ne reprend pas le libelle « Créer une version » '
        '(${cadre.width.toInt()})', (WidgetTester tester) async {
      tester.view.physicalSize = cadre;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final _FauxProgramme service = _FauxProgramme();
      await tester.pumpWidget(
        hote(
          const ProgrammesPage(),
          surcharges: <Override>[
            serviceProgrammeProvider.overrideWithValue(service),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final String creer = t.admin.programmes.creerVersion;
      expect(find.text(creer), findsOneWidget);

      // Une seule frappe.
      await tester.tap(find.text(creer));
      await tester.pumpAndSettle();

      // La feuille est ouverte : son titre est visible.
      expect(find.text(t.admin.programmes.creerVersionVide), findsOneWidget);
      // Son bouton d'envoi dit ce qu'il fait, et ne ressemble plus au bouton
      // qui l'a ouverte : un seul « Créer une version » a l'ecran.
      expect(find.text(t.admin.programmes.enregistrerVersion), findsOneWidget);
      expect(find.text(creer), findsOneWidget);
      expect(service.creations, 0);

      // L'envoi cree bien la version et referme la feuille.
      await tester.tap(find.text(t.admin.programmes.enregistrerVersion));
      await tester.pumpAndSettle();
      expect(service.creations, 1);
      expect(find.text(t.admin.programmes.creerVersionVide), findsNothing);
    });
  }
}
