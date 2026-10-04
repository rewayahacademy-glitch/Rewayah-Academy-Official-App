// Captures de recette FORM-L6 (Foyer : nom prerempli, age choisi en puces ;
// invitation du conjoint : nom prerempli). Vrais ecrans, ouverts par de vrais
// tap ; l'identite du titulaire vient d'un double du port du Compte, la
// creation d'un faux port (aucun serveur).
//
// Saute sans CAPTURE_DIR (voir `test/capture/LISEZ-MOI.md`). Nommage :
// forml6_<etat>_<largeur>_x<echelle>_<mode>.png.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/port_identite_titulaire.dart';
import 'package:rewayah_academy/core/foyer/port_creation_profil_eleve.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/compte/donnees_compte.dart'
    show identiteTitulaireProvider;
import 'package:rewayah_academy/features/foyer/formulaire_profil_eleve.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';

import '../fixtures/tuteur/faux_creation_profil_eleve.dart';
import 'outil_capture.dart';

List<Override> _surcharges() => <Override>[
  identiteTitulaireProvider.overrideWith(
    (Ref _) async => const IdentiteTitulaire(
      prenom: 'Awa',
      nom: 'Diallo',
      methodeConnexion: MethodeConnexion.lienCourriel,
    ),
  ),
  porteAjoutProfilProvider.overrideWithValue(PorteAcces.actif),
  portCreationProfilEleveProvider.overrideWithValue(FauxCreationProfilEleve()),
  elevesDuFoyerProvider.overrideWith((Ref _) async => <EleveDuFoyer>[]),
  horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
];

const List<(Size, double, String)> _cadres = <(Size, double, String)>[
  (Size(390, 844), 2, '390'),
  (Size(1440, 900), 1, '1440'),
  (Size(320, 700), 2, '320'),
];

void main() {
  group('Capture : FORM-L6 nom prerempli et age choisi', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final (Size taille, double densite, String nom) in _cadres) {
        for (final double echelle in <double>[1, if (nom == '320') 2]) {
          final String suffixe = '${nom}_x${echelle.toInt()}_${mode.name}';

          Future<void> ouvrirIdentite(WidgetTester tester) async {
            fixerVueCapture(
              tester,
              echelle == 2 ? const Size(320, 1500) : taille,
              densite,
            );
            await tester.pumpWidget(
              hoteCapture(
                FormulaireProfilEleve(
                  onAbandon: () {},
                  onCree: (String? _) {},
                  onVoirFoyer: () {},
                ),
                themeMode: mode,
                echelleTexte: echelle,
                surcharges: _surcharges(),
              ),
            );
            await stabiliser(tester);
            await tester.tap(find.text(t.foyer.ajout.pourQui.enfantTitre));
            await stabiliser(tester);
            await tester.tap(find.byKey(FormulaireProfilEleve.actionKey));
            await stabiliser(tester);
          }

          testWidgets('profil age choisi $suffixe', (
            WidgetTester tester,
          ) async {
            await ouvrirIdentite(tester);
            await tester.scrollUntilVisible(
              find.byKey(FormulaireProfilEleve.prenomKey),
              100,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.enterText(
              find.byKey(FormulaireProfilEleve.prenomKey),
              'Aya',
            );
            await tester.scrollUntilVisible(
              find.byKey(FormulaireProfilEleve.ageChoixKey(9)),
              100,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.tap(find.byKey(FormulaireProfilEleve.ageChoixKey(9)));
            FocusManager.instance.primaryFocus?.unfocus();
            await stabiliser(tester);
            expect(tester.takeException(), isNull);
            // ignore: avoid_print
            print(
              'PNG ${await capturer(tester, 'forml6_profil_age_$suffixe')}',
            );
          });

          testWidgets('profil age manquant $suffixe', (
            WidgetTester tester,
          ) async {
            await ouvrirIdentite(tester);
            await tester.scrollUntilVisible(
              find.byKey(FormulaireProfilEleve.prenomKey),
              100,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.enterText(
              find.byKey(FormulaireProfilEleve.prenomKey),
              'Aya',
            );
            await tester.tap(find.byKey(FormulaireProfilEleve.actionKey));
            FocusManager.instance.primaryFocus?.unfocus();
            await stabiliser(tester);
            expect(find.text(t.foyer.ajout.erreurs.ageRequis), findsOneWidget);
            expect(tester.takeException(), isNull);
            // ignore: avoid_print
            print(
              'PNG ${await capturer(tester, 'forml6_profil_erreur_$suffixe')}',
            );
          });

          testWidgets('invitation nom prerempli $suffixe', (
            WidgetTester tester,
          ) async {
            fixerVueCapture(
              tester,
              echelle == 2 ? const Size(320, 1500) : taille,
              densite,
            );
            await tester.pumpWidget(
              hoteCapture(
                InviterConjointPage(
                  placeFeminine: true,
                  onAbandon: () {},
                  onTerminee: () {},
                ),
                themeMode: mode,
                echelleTexte: echelle,
                surcharges: _surcharges(),
              ),
            );
            await stabiliser(tester);
            expect(find.text('Diallo'), findsOneWidget);
            expect(tester.takeException(), isNull);
            // ignore: avoid_print
            print(
              'PNG ${await capturer(tester, 'forml6_invitation_$suffixe')}',
            );
          });
        }
      }
    }
  });
}
