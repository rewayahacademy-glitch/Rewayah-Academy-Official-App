// Captures de recette GESTES-POINTEUR (directeur, 11/11/2026, cahier de la
// salle §8) : le pointeur et son sillage sur la page, « Yasmine recite » chez
// l'enseignant et chez un camarade, « Votre enseignant vous appelle ».
// Telephone 390 et ordinateur 1440, clair et sombre, une en arabe.
//
// **Captures de test, pas de la vraie application** : la salle est montee avec
// les donnees de demonstration des tests (`DonneesSeanceDemo`), sans serveur ;
// l'annonce et le pointeur sont ceux du code livre.
// Saute sans CAPTURE_DIR. Nommage : gestes_<scene>_<largeur>_<mode>.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/annonce_geste.dart';
import 'package:rewayah_academy/features/salle_seance/ecriture_seance.dart'
    show pointeurDistantProvider;
import 'package:rewayah_academy/features/salle_seance/pointeur_salle.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/surface_page_fixe.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../support/demo/seance_demo.dart';
import 'outil_capture.dart';

const List<(Size, double, String)> _cadres = <(Size, double, String)>[
  (Size(390, 844), 3, '390'),
  (Size(1440, 900), 1, '1440'),
];

const List<ThemeMode> _modes = <ThemeMode>[ThemeMode.light, ThemeMode.dark];

Widget _salle(VueSeance vue, {AnnonceGeste? annonce, bool micro = true}) =>
    CoucheAnnonceGeste(
      annonce: annonce,
      child: SalleSeance(
        vue: vue,
        local: const EtatLocalSeance(microOuvert: false, cameraAllumee: false),
        actions: ActionsSeance(
          onRetour: () {},
          onQuitter: () {},
          onMicro: micro ? () {} : null,
          onEleves: () {},
          onSupports: () {},
          onRappeler: (EleveSeance _) {},
          onChoisirPourReciter: (EleveSeance _) {},
        ),
      ),
    );

Future<void> _prendre(
  WidgetTester tester,
  String nom,
  Widget salle, {
  required Size cadre,
  required double densite,
  ThemeMode mode = ThemeMode.light,
  List<Override> surcharges = const <Override>[],
  Future<void> Function()? avant,
}) async {
  fixerVueCapture(tester, cadre, densite);
  await tester.pumpWidget(
    hoteCapture(salle, themeMode: mode, surcharges: surcharges),
  );
  await stabiliser(tester);
  await avant?.call();
  expect(tester.takeException(), isNull);
  debugPrint('PNG ${await capturer(tester, nom)}');
}

void main() {
  group('Capture : GESTES-POINTEUR', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    for (final (Size cadre, double densite, String largeur) in _cadres) {
      for (final ThemeMode mode in _modes) {
        final String suffixe = '${largeur}_${mode.name}';

        testWidgets('gestes_pointeur_eleve_$suffixe', (
          WidgetTester tester,
        ) async {
          final ValueNotifier<Offset?> pointeur = ValueNotifier<Offset?>(
            const Offset(0.25, 0.3),
          );
          addTearDown(pointeur.dispose);
          await _prendre(
            tester,
            'gestes_pointeur_eleve_$suffixe',
            _salle(
              // Une page du support partage : le pointeur vit sur la page.
              DonneesSeanceDemo.vue(
                RoleSeance.eleve,
                EtatDemoSalle.repos,
              ).copyWith(supportPresente: DonneesSeanceDemo.supportPageFixe),
            ),
            cadre: cadre,
            densite: densite,
            mode: mode,
            surcharges: <Override>[
              pointeurDistantProvider.overrideWithValue(pointeur),
            ],
            // L'enseignant deplace son pointeur : six positions, une image
            // entre deux. La capture est prise en plein mouvement.
            avant: () async {
              for (int i = 1; i <= 6; i++) {
                pointeur.value = Offset(0.25 + i * 0.07, 0.3 + i * 0.015);
                await tester.pump(const Duration(milliseconds: 33));
              }
              expect(
                find.byKey(SurfacePageFixe.clePointeurDistant),
                findsOneWidget,
              );
            },
          );
          // Le pointeur se leve : le sillage finit de s'effacer.
          pointeur.value = null;
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          await tester.pump(const Duration(milliseconds: 16));
        });

        testWidgets('gestes_recitation_enseignant_$suffixe', (
          WidgetTester tester,
        ) async {
          await _prendre(
            tester,
            'gestes_recitation_enseignant_$suffixe',
            _salle(
              DonneesSeanceDemo.vue(
                RoleSeance.enseignant,
                EtatDemoSalle.eleves,
              ),
              annonce: AnnonceGeste(
                // Mariam : l'eleve qui recite dans les donnees de
                // demonstration (le panneau et l'annonce disent le meme nom).
                titre: t.salle.gestes.recitationOuverteTitre(prenom: 'Mariam'),
                message: t.salle.gestes.recitationOuverte(prenom: 'Mariam'),
              ),
            ),
            cadre: cadre,
            densite: densite,
            mode: mode,
          );
        });

        testWidgets('gestes_recitation_camarade_$suffixe', (
          WidgetTester tester,
        ) async {
          await _prendre(
            tester,
            'gestes_recitation_camarade_$suffixe',
            _salle(
              DonneesSeanceDemo.vue(
                RoleSeance.eleve,
                EtatDemoSalle.repos,
              ).copyWith(microEnAttente: true, recitantPrenom: 'Yasmine'),
              micro: false,
              annonce: AnnonceGeste(
                titre: t.salle.gestes.autreReciteTitre(prenom: 'Yasmine'),
                message: t.salle.gestes.autreRecite,
              ),
            ),
            cadre: cadre,
            densite: densite,
            mode: mode,
          );
        });

        testWidgets('gestes_appel_eleve_$suffixe', (WidgetTester tester) async {
          await _prendre(
            tester,
            'gestes_appel_eleve_$suffixe',
            _salle(
              DonneesSeanceDemo.vue(RoleSeance.eleve, EtatDemoSalle.repos),
              annonce: AnnonceGeste(
                titre: t.salle.gestes.appelRecuTitre,
                message: t.salle.gestes.appelRecu,
              ),
            ),
            cadre: cadre,
            densite: densite,
            mode: mode,
          );
        });
      }
    }

    // POINTEUR (directeur, 12/11/2026) : l'anneau creux pose SUR un mot, au
    // telephone, clair et sombre. Le mot doit rester lisible dans l'anneau.
    for (final ThemeMode mode in _modes) {
      testWidgets('gestes_pointeur_anneau_sur_texte_390_${mode.name}', (
        WidgetTester tester,
      ) async {
        final ValueNotifier<Offset?> pointeur = ValueNotifier<Offset?>(
          const Offset(0.5, 0.3),
        );
        addTearDown(pointeur.dispose);
        await _prendre(
          tester,
          'gestes_pointeur_anneau_sur_texte_390_${mode.name}',
          Builder(
            builder: (BuildContext c) => ColoredBox(
              color: Theme.of(c).colorScheme.surface,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Align(
                    alignment: const Alignment(0, -0.4),
                    child: Text(
                      'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
                      textDirection: TextDirection.rtl,
                      style: Theme.of(c).textTheme.displaySmall,
                    ),
                  ),
                  PointeurSalle(source: pointeur),
                ],
              ),
            ),
          ),
          cadre: const Size(390, 844),
          densite: 3,
          mode: mode,
        );
      });
    }

    testWidgets('gestes_recitation_camarade_390_light_ar', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _prendre(
        tester,
        'gestes_recitation_camarade_390_light_ar',
        _salle(
          DonneesSeanceDemo.vue(
            RoleSeance.eleve,
            EtatDemoSalle.repos,
          ).copyWith(microEnAttente: true, recitantPrenom: 'ياسمين'),
          micro: false,
          annonce: AnnonceGeste(
            titre: t.salle.gestes.autreReciteTitre(prenom: 'ياسمين'),
            message: t.salle.gestes.autreRecite,
          ),
        ),
        cadre: const Size(390, 844),
        densite: 3,
      );
    });

    testWidgets('gestes_appel_enseignant_retour_1440_light', (
      WidgetTester tester,
    ) async {
      await _prendre(
        tester,
        'gestes_appel_enseignant_retour_1440_light',
        _salle(
          DonneesSeanceDemo.vue(RoleSeance.enseignant, EtatDemoSalle.eleves),
          annonce: AnnonceGeste(
            titre: t.salle.gestes.appelEnvoyeTitre(prenom: 'Ilyes'),
            message: t.salle.gestes.appelEnvoye,
          ),
        ),
        cadre: const Size(1440, 900),
        densite: 1,
      );
    });
  });
}
