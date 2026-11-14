// SUPPRIMER-PRENOM (pilote et garde-cap, 07/11/2026) : la feuille de
// suppression d'un profil d'enfant fait ecrire son prenom. Deux etats, FR et
// AR, 390 et 1440 : la feuille ouverte, puis apres un appui sans le bon
// prenom (champ en rouge, message). Prefixe des PNG : `suppression_prenom_`.
// Saute sans CAPTURE_DIR.
//
// Ce ne sont pas les captures du robot de la pile locale (R3).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_retraits_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/foyer/selection_eleve.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/features/foyer/supprimer_profil_eleve.dart';

import '../support/harnais.dart' show FauxServiceReseau;
import 'outil_capture.dart';

class _Port implements PortRetraitsComptes {
  @override
  Future<ResultatSuppressionEnfant> supprimerProfilEnfant(
    String eleveId,
  ) async => ResultatSuppressionEnfant.retire;

  @override
  Future<PageRetraits> lister({
    EtatRetraits etat = EtatRetraits.enCours,
    CurseurRetraits? apres,
  }) => throw UnimplementedError();

  @override
  Future<List<ResultatRestauration>> restaurer(List<String> ids) =>
      throw UnimplementedError();

  @override
  Future<List<ResultatRetrait>> retirer(
    List<String> ids, {
    String? motif,
    bool anonymiserMaintenant = false,
  }) => throw UnimplementedError();
}

const ProfilEleveFoyer _yasmine = ProfilEleveFoyer(
  eleveId: 'e1',
  prenom: 'Yasmine',
  nature: NatureProfilEleve.membreDuFoyer,
  mode: InterfaceMode.standard,
  camera: CameraPolicy.allowed,
);

void main() {
  group('Capture : SUPPRIMER-PRENOM', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await LocaleSettings.setLocale(AppLocale.ar);
      await LocaleSettings.setLocale(AppLocale.en);
      await LocaleSettings.setLocale(AppLocale.fr);
    });

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Size taille in <Size>[
        const Size(390, 844),
        const Size(1440, 900),
      ]) {
        final String suffixe = '${taille.width.toInt()}_${langue.languageCode}';
        testWidgets('suppression_prenom_$suffixe', (WidgetTester tester) async {
          LocaleSettings.setLocaleSync(langue);
          addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
          fixerVueCapture(tester, taille, 1);
          await tester.pumpWidget(
            hoteCapture(
              const Scaffold(
                body: Padding(
                  padding: EdgeInsets.all(16),
                  child: SupprimerProfilEleve(profil: _yasmine),
                ),
              ),
              surcharges: <Override>[
                portRetraitsComptesProvider.overrideWithValue(_Port()),
                serviceReseauProvider.overrideWithValue(
                  FauxServiceReseau(horsLigneRendu: false),
                ),
              ],
            ),
          );
          await stabiliser(tester);
          final s = t.ficheEleve.supprimer;
          await tester.tap(
            find.text(s.ligne(dePrenom: deDevant(_yasmine.prenom))),
          );
          await stabiliser(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'suppression_prenom_1_ouverte_$suffixe')}',
          );
          await tester.tap(find.text(s.confirmer(prenom: _yasmine.prenom)));
          await stabiliser(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'suppression_prenom_2_prenom_faux_$suffixe')}',
          );
        });
      }
    }
  });
}
