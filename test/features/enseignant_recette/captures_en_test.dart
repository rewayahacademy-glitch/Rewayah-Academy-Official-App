// EN-1b a EN-11 : squelette des captures de la vague Enseignant, complete en
// EN-12 (recette) pour couvrir chaque ecran et ses cas particuliers. Jamais
// sans `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md). Modele :
// `captures_cl47_test.dart`. Sortie en un sous-dossier par ecran.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart';
import 'package:rewayah_academy/features/demo/demo_classe_page.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/fiche_groupe/fiche_eleve_enseignant.dart';
import 'package:rewayah_academy/features/profil_enseignant/photo_publique.dart';
import 'package:rewayah_academy/features/revue_groupe/anomalies_revue.dart';
import 'package:rewayah_academy/features/revue_groupe/revue_groupe_page.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';
import '../../support/harnais.dart';

const List<(String, Size)> _tailles = <(String, Size)>[
  ('390', Size(390, 1900)),
  ('768', Size(768, 1500)),
  ('1440', Size(1440, 1100)),
];

const List<ThemeMode> _themes = <ThemeMode>[ThemeMode.light, ThemeMode.dark];

/// Le depot de cahiers en memoire, pour chaque capture : sans ce faux, la
/// Journee et le Cahier ouvrent une vraie base drift (`baseLocaleProvider`),
/// qui appelle `path_provider` (absent en test) des que `capturer` passe par
/// `runAsync`. Meme fable que `depotRapportsProvider.overrideWithValue` dans
/// `rtl_echelle_texte_ecrans_test.dart` pour `CahierPage`.
List<Override> _surchargesBase() => <Override>[
  depotRapportsProvider.overrideWithValue(FauxDepotRapports()),
];

/// Monte [ecran] et ecrit son PNG ; [rtl] simule l'arabe (miroir de sens),
/// [echelle] simule le texte agrandi (200 % attendu par le directeur).
Future<void> _capturer(
  WidgetTester tester,
  String fichier,
  Widget ecran,
  Size taille, {
  ThemeMode mode = ThemeMode.light,
  bool rtl = false,
  double echelle = 1,
  List<Override> surcharges = const <Override>[],
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(
      rtl
          ? Directionality(textDirection: TextDirection.rtl, child: ecran)
          : ecran,
      themeMode: mode,
      echelleTexte: echelle,
      surcharges: <Override>[..._surchargesBase(), ...surcharges],
    ),
  );
  await stabiliser(tester);
  debugPrint('PNG ${await capturer(tester, fichier)}');
}

Future<void> _toucherEtAttendre(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
  // Les reponses de demonstration arrivent apres 600 ms.
  await tester.pump(const Duration(milliseconds: 700));
  await stabiliser(tester);
}

void main() {
  // -------------------------------------------------------------------
  // Coquille enseignant (EN-1b) : les 4 destinations (E10).
  // -------------------------------------------------------------------
  group('Capture EN-12 : coquille', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final EcranDemoEnseignant ecran in EcranDemoEnseignant.values) {
      for (final (String l, Size taille) in _tailles) {
        for (final ThemeMode mode in _themes) {
          testWidgets('coquille_${ecran.name}_${l}_${mode.name}', (
            WidgetTester tester,
          ) async {
            await _capturer(
              tester,
              'coquille/en12_coquille_${ecran.name}_${l}_${mode.name}',
              CoquilleEnseignantDemo(ecran: ecran),
              taille,
              mode: mode,
            );
          });
        }
      }
    }
  });

  // -------------------------------------------------------------------
  // Aujourd'hui (EN-2), plus vide et hors ligne, plus 200 % et RTL.
  // -------------------------------------------------------------------
  group('Capture EN-12 : aujourdhui', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String l, Size taille) in _tailles) {
      for (final ThemeMode mode in _themes) {
        testWidgets('aujourdhui_${l}_${mode.name}', (
          WidgetTester tester,
        ) async {
          await _capturer(
            tester,
            'aujourdhui/en12_aujourdhui_${l}_${mode.name}',
            const CoquilleEnseignantDemo(ecran: EcranDemoEnseignant.aujourdhui),
            taille,
            mode: mode,
          );
        });
      }
    }
    for (final EtatDemoEnseignant etat in <EtatDemoEnseignant>[
      EtatDemoEnseignant.vide,
      EtatDemoEnseignant.horsLigne,
    ]) {
      testWidgets('aujourdhui_${etat.name}_390_light', (
        WidgetTester tester,
      ) async {
        await _capturer(
          tester,
          'aujourdhui/en12_aujourdhui_${etat.name}_390_light',
          CoquilleEnseignantDemo(
            ecran: EcranDemoEnseignant.aujourdhui,
            etat: etat,
          ),
          const Size(390, 1500),
        );
      });
    }
    testWidgets('aujourdhui_200pct_390_light', (WidgetTester tester) async {
      await _capturer(
        tester,
        'aujourdhui/en12_aujourdhui_200pct_390_light',
        const CoquilleEnseignantDemo(ecran: EcranDemoEnseignant.aujourdhui),
        const Size(390, 3000),
        echelle: 2,
      );
    });
    testWidgets('aujourdhui_rtl_390_light', (WidgetTester tester) async {
      await _capturer(
        tester,
        'aujourdhui/en12_aujourdhui_rtl_390_light',
        const CoquilleEnseignantDemo(ecran: EcranDemoEnseignant.aujourdhui),
        const Size(390, 1500),
        rtl: true,
      );
    });
  });

  // -------------------------------------------------------------------
  // Mes Classes et Espace Classe (EN-3), plus 200 % et RTL sur Mes Classes.
  // -------------------------------------------------------------------
  group('Capture EN-12 : classes', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String nom, Widget ecran) in <(String, Widget)>[
      (
        'mes_classes',
        const CoquilleEnseignantDemo(ecran: EcranDemoEnseignant.classes),
      ),
      (
        'espace_classe',
        const EcranEnseignantDemo(etat: EtatDemoClasse.fenetreOuverte),
      ),
    ]) {
      for (final (String l, Size taille) in _tailles) {
        for (final ThemeMode mode in _themes) {
          testWidgets('classes_${nom}_${l}_${mode.name}', (
            WidgetTester tester,
          ) async {
            await _capturer(
              tester,
              'classes/en12_${nom}_${l}_${mode.name}',
              ecran,
              taille,
              mode: mode,
            );
          });
        }
      }
    }
    testWidgets('classes_mes_classes_200pct_390_light', (
      WidgetTester tester,
    ) async {
      await _capturer(
        tester,
        'classes/en12_mes_classes_200pct_390_light',
        const CoquilleEnseignantDemo(ecran: EcranDemoEnseignant.classes),
        const Size(390, 3000),
        echelle: 2,
      );
    });
    testWidgets('classes_mes_classes_rtl_390_light', (
      WidgetTester tester,
    ) async {
      await _capturer(
        tester,
        'classes/en12_mes_classes_rtl_390_light',
        const CoquilleEnseignantDemo(ecran: EcranDemoEnseignant.classes),
        const Size(390, 1900),
        rtl: true,
      );
    });
  });

  // -------------------------------------------------------------------
  // Fiche eleve (ENS-11) et Signaler un besoin (ENS-12) (EN-4).
  // -------------------------------------------------------------------
  group('Capture EN-12 : fiche_eleve', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    Future<void> ouvrir(
      WidgetTester tester,
      Size taille,
      ThemeMode mode, {
      bool rtl = false,
      double echelle = 1,
    }) async {
      fixerVueCapture(tester, taille, 1);
      const Widget ecran = EcranEnseignantDemo(
        etat: EtatDemoClasse.fenetreOuverte,
      );
      await tester.pumpWidget(
        hoteCapture(
          rtl
              ? const Directionality(
                  textDirection: TextDirection.rtl,
                  child: ecran,
                )
              : ecran,
          themeMode: mode,
          echelleTexte: echelle,
        ),
      );
      await stabiliser(tester);
      final Finder ligne = find.text('Mariam').last;
      await tester.ensureVisible(ligne);
      await stabiliser(tester);
      await tester.tap(ligne);
      await stabiliser(tester);
    }

    for (final (String l, Size taille) in _tailles) {
      for (final ThemeMode mode in _themes) {
        testWidgets('fiche_eleve_${l}_${mode.name}', (
          WidgetTester tester,
        ) async {
          await ouvrir(tester, taille, mode);
          debugPrint(
            'PNG ${await capturer(tester, 'fiche_eleve/en12_fiche_eleve_${l}_${mode.name}')}',
          );
        });
        testWidgets('signaler_besoin_${l}_${mode.name}', (
          WidgetTester tester,
        ) async {
          await ouvrir(tester, taille, mode);
          final Finder signaler = find.byKey(FicheEleveEnseignant.signalerKey);
          await _toucherEtAttendre(tester, signaler);
          debugPrint(
            'PNG ${await capturer(tester, 'fiche_eleve/en12_signaler_besoin_${l}_${mode.name}')}',
          );
        });
      }
    }
    testWidgets('fiche_eleve_200pct_390_light', (WidgetTester tester) async {
      await ouvrir(tester, const Size(390, 2200), ThemeMode.light, echelle: 2);
      debugPrint(
        'PNG ${await capturer(tester, 'fiche_eleve/en12_fiche_eleve_200pct_390_light')}',
      );
    });
    testWidgets('fiche_eleve_rtl_390_light', (WidgetTester tester) async {
      await ouvrir(tester, const Size(390, 1900), ThemeMode.light, rtl: true);
      debugPrint(
        'PNG ${await capturer(tester, 'fiche_eleve/en12_fiche_eleve_rtl_390_light')}',
      );
    });
  });

  // -------------------------------------------------------------------
  // Disponibilites (ENS-06) et detail d'une Classe disponible (EN-5).
  // -------------------------------------------------------------------
  group('Capture EN-12 : disponibilites', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    Future<void> monter(
      WidgetTester tester,
      Size taille,
      ThemeMode mode, {
      bool rtl = false,
      double echelle = 1,
    }) async {
      fixerVueCapture(tester, taille, 1);
      const Widget ecran = CoquilleEnseignantDemo(
        ecran: EcranDemoEnseignant.disponibilites,
      );
      await tester.pumpWidget(
        hoteCapture(
          rtl
              ? const Directionality(
                  textDirection: TextDirection.rtl,
                  child: ecran,
                )
              : ecran,
          themeMode: mode,
          echelleTexte: echelle,
        ),
      );
      await stabiliser(tester);
    }

    for (final (String l, Size taille) in _tailles) {
      for (final ThemeMode mode in _themes) {
        final String s = '${l}_${mode.name}';
        testWidgets('disponibilites_$s', (WidgetTester tester) async {
          await monter(tester, taille, mode);
          debugPrint(
            'PNG ${await capturer(tester, 'disponibilites/en12_disponibilites_$s')}',
          );
        });
        testWidgets('detail_classe_$s', (WidgetTester tester) async {
          await monter(tester, taille, mode);
          await _toucherEtAttendre(tester, find.text('Ar-Rahma'));
          debugPrint(
            'PNG ${await capturer(tester, 'disponibilites/en12_detail_classe_$s')}',
          );
        });
        testWidgets('confirmation_$s', (WidgetTester tester) async {
          await monter(tester, taille, mode);
          await _toucherEtAttendre(tester, find.text('Ar-Rahma'));
          await _toucherEtAttendre(
            tester,
            find.text(t.enseignant.creneaux.reserver),
          );
          debugPrint(
            'PNG ${await capturer(tester, 'disponibilites/en12_confirmation_$s')}',
          );
        });
      }
    }
    testWidgets('succes_390_light', (WidgetTester tester) async {
      await monter(tester, const Size(390, 1900), ThemeMode.light);
      await _toucherEtAttendre(tester, find.text('Ar-Rahma'));
      await _toucherEtAttendre(
        tester,
        find.text(t.enseignant.creneaux.reserver),
      );
      await _toucherEtAttendre(
        tester,
        find.text(t.enseignant.creneaux.confirmer),
      );
      debugPrint(
        'PNG ${await capturer(tester, 'disponibilites/en12_succes_390_light')}',
      );
    });
    testWidgets('disponibilites_200pct_390_light', (WidgetTester tester) async {
      await monter(tester, const Size(390, 3000), ThemeMode.light, echelle: 2);
      debugPrint(
        'PNG ${await capturer(tester, 'disponibilites/en12_disponibilites_200pct_390_light')}',
      );
    });
    testWidgets('disponibilites_rtl_390_light', (WidgetTester tester) async {
      await monter(tester, const Size(390, 1900), ThemeMode.light, rtl: true);
      debugPrint(
        'PNG ${await capturer(tester, 'disponibilites/en12_disponibilites_rtl_390_light')}',
      );
    });
  });

  // -------------------------------------------------------------------
  // Premiers pas (ENS-01) (EN-6).
  // -------------------------------------------------------------------
  group('Capture EN-12 : premiers_pas', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String l, Size taille) in _tailles) {
      for (final ThemeMode mode in _themes) {
        testWidgets('premiers_pas_${l}_${mode.name}', (
          WidgetTester tester,
        ) async {
          await _capturer(
            tester,
            'premiers_pas/en12_premiers_pas_${l}_${mode.name}',
            const CoquilleEnseignantDemo(
              ecran: EcranDemoEnseignant.premiersPas,
            ),
            taille,
            mode: mode,
          );
        });
      }
    }
    testWidgets('premiers_pas_200pct_390_light', (WidgetTester tester) async {
      await _capturer(
        tester,
        'premiers_pas/en12_premiers_pas_200pct_390_light',
        const CoquilleEnseignantDemo(ecran: EcranDemoEnseignant.premiersPas),
        const Size(390, 3000),
        echelle: 2,
      );
    });
    testWidgets('premiers_pas_rtl_390_light', (WidgetTester tester) async {
      await _capturer(
        tester,
        'premiers_pas/en12_premiers_pas_rtl_390_light',
        const CoquilleEnseignantDemo(ecran: EcranDemoEnseignant.premiersPas),
        const Size(390, 1900),
        rtl: true,
      );
    });
  });

  // -------------------------------------------------------------------
  // Profil (ENS-05) et photo publique (ENS-05A) (EN-6).
  // -------------------------------------------------------------------
  group('Capture EN-12 : profil', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    Future<void> monter(
      WidgetTester tester,
      Size taille,
      ThemeMode mode, {
      bool rtl = false,
      double echelle = 1,
    }) async {
      fixerVueCapture(tester, taille, 1);
      const Widget ecran = CoquilleEnseignantDemo(
        ecran: EcranDemoEnseignant.profil,
      );
      await tester.pumpWidget(
        hoteCapture(
          rtl
              ? const Directionality(
                  textDirection: TextDirection.rtl,
                  child: ecran,
                )
              : ecran,
          themeMode: mode,
          echelleTexte: echelle,
        ),
      );
      await stabiliser(tester);
    }

    Future<void> ouvrirPhoto(WidgetTester tester) =>
        _toucherEtAttendre(tester, find.text(t.enseignant.photo.choisir).first);

    for (final (String l, Size taille) in _tailles) {
      for (final ThemeMode mode in _themes) {
        final String s = '${l}_${mode.name}';
        testWidgets('profil_$s', (WidgetTester tester) async {
          await monter(tester, taille, mode);
          debugPrint('PNG ${await capturer(tester, 'profil/en12_profil_$s')}');
        });
        testWidgets('photo_$s', (WidgetTester tester) async {
          await monter(tester, taille, mode);
          await ouvrirPhoto(tester);
          debugPrint('PNG ${await capturer(tester, 'profil/en12_photo_$s')}');
        });
        testWidgets('photo_apercu_$s', (WidgetTester tester) async {
          await monter(tester, taille, mode);
          await ouvrirPhoto(tester);
          await _toucherEtAttendre(
            tester,
            find.byKey(EditeurPhotoPublique.choisirKey),
          );
          debugPrint(
            'PNG ${await capturer(tester, 'profil/en12_photo_apercu_$s')}',
          );
        });
        testWidgets('photo_succes_$s', (WidgetTester tester) async {
          await monter(tester, taille, mode);
          await ouvrirPhoto(tester);
          await _toucherEtAttendre(
            tester,
            find.byKey(EditeurPhotoPublique.choisirKey),
          );
          await tester.tap(find.byKey(EditeurPhotoPublique.utiliserKey));
          await tester.pump(const Duration(seconds: 1));
          await stabiliser(tester);
          debugPrint(
            'PNG ${await capturer(tester, 'profil/en12_photo_succes_$s')}',
          );
        });
      }
    }
    testWidgets('profil_200pct_390_light', (WidgetTester tester) async {
      await monter(tester, const Size(390, 3000), ThemeMode.light, echelle: 2);
      debugPrint(
        'PNG ${await capturer(tester, 'profil/en12_profil_200pct_390_light')}',
      );
    });
    testWidgets('profil_rtl_390_light', (WidgetTester tester) async {
      await monter(tester, const Size(390, 1900), ThemeMode.light, rtl: true);
      debugPrint(
        'PNG ${await capturer(tester, 'profil/en12_profil_rtl_390_light')}',
      );
    });
  });

  // -------------------------------------------------------------------
  // Cahier de seance (ENS-04) (EN-7).
  // -------------------------------------------------------------------
  group('Capture EN-12 : cahier', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    Future<void> monter(
      WidgetTester tester,
      Size taille,
      ThemeMode mode,
      EtatDemoEnseignant etat, {
      bool rtl = false,
      double echelle = 1,
    }) async {
      fixerVueCapture(tester, taille, 1);
      final Widget ecran = CoquilleEnseignantDemo(
        ecran: EcranDemoEnseignant.cahier,
        etat: etat,
      );
      await tester.pumpWidget(
        hoteCapture(
          rtl
              ? Directionality(textDirection: TextDirection.rtl, child: ecran)
              : ecran,
          themeMode: mode,
          echelleTexte: echelle,
          surcharges: _surchargesBase(),
        ),
      );
      await stabiliser(tester);
    }

    final Finder valider = find.byKey(const ValueKey<String>('cahier-valider'));
    final Finder corriger = find.byKey(
      const ValueKey<String>('cahier-corriger'),
    );

    for (final (String l, Size taille) in _tailles) {
      for (final ThemeMode mode in _themes) {
        final String s = '${l}_${mode.name}';
        testWidgets('cahier_a_remplir_$s', (WidgetTester tester) async {
          await monter(tester, taille, mode, EtatDemoEnseignant.nominal);
          await capturer(tester, 'cahier/en12_cahier_a_remplir_$s');
        });
        testWidgets('cahier_valide_$s', (WidgetTester tester) async {
          await monter(tester, taille, mode, EtatDemoEnseignant.nominal);
          await _toucherEtAttendre(tester, valider);
          await capturer(tester, 'cahier/en12_cahier_valide_$s');
        });
        testWidgets('cahier_corrige_$s', (WidgetTester tester) async {
          await monter(tester, taille, mode, EtatDemoEnseignant.nominal);
          await _toucherEtAttendre(tester, valider);
          await _toucherEtAttendre(tester, corriger);
          await _toucherEtAttendre(tester, valider);
          await capturer(tester, 'cahier/en12_cahier_corrige_$s');
        });
        testWidgets('cahier_en_attente_$s', (WidgetTester tester) async {
          await monter(tester, taille, mode, EtatDemoEnseignant.horsLigne);
          await _toucherEtAttendre(tester, valider);
          await capturer(tester, 'cahier/en12_cahier_en_attente_$s');
        });
      }
    }
    testWidgets('cahier_200pct_390_light', (WidgetTester tester) async {
      await monter(
        tester,
        const Size(390, 3400),
        ThemeMode.light,
        EtatDemoEnseignant.nominal,
        echelle: 2,
      );
      await capturer(tester, 'cahier/en12_cahier_a_remplir_200pct_390_light');
    });
    testWidgets('cahier_rtl_390_light', (WidgetTester tester) async {
      await monter(
        tester,
        const Size(390, 1900),
        ThemeMode.light,
        EtatDemoEnseignant.nominal,
        rtl: true,
      );
      await capturer(tester, 'cahier/en12_cahier_a_remplir_rtl_390_light');
    });
  });

  // -------------------------------------------------------------------
  // Absence (ENS-13) et offre de remplacement (ENS-13B) (EN-8).
  // -------------------------------------------------------------------
  group('Capture EN-12 : absence_remplacement', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    Future<void> monter(
      WidgetTester tester,
      Size taille,
      ThemeMode mode, {
      bool rtl = false,
      double echelle = 1,
    }) async {
      fixerVueCapture(tester, taille, 1);
      const Widget ecran = CoquilleEnseignantDemo(
        ecran: EcranDemoEnseignant.aujourdhui,
      );
      await tester.pumpWidget(
        hoteCapture(
          rtl
              ? const Directionality(
                  textDirection: TextDirection.rtl,
                  child: ecran,
                )
              : ecran,
          themeMode: mode,
          echelleTexte: echelle,
          surcharges: _surchargesBase(),
        ),
      );
      await stabiliser(tester);
    }

    final Finder declarer = find.byKey(
      const ValueKey<String>('journee-declarer-absence'),
    );
    final Finder declarerMonAbsence = find.byKey(
      const ValueKey<String>('absence-principale'),
    );
    final Finder offre = find.text('Assurer ce remplacement ?');
    final Finder assurer = find.byKey(
      const ValueKey<String>('remplacement-principale'),
    );

    for (final (String l, Size taille) in _tailles) {
      for (final ThemeMode mode in _themes) {
        final String s = '${l}_${mode.name}';
        testWidgets('alerte_offre_$s', (WidgetTester tester) async {
          await monter(tester, taille, mode);
          await capturer(tester, 'absence_remplacement/en12_alerte_offre_$s');
        });
        testWidgets('feuille_absence_$s', (WidgetTester tester) async {
          await monter(tester, taille, mode);
          await _toucherEtAttendre(tester, declarer);
          await capturer(
            tester,
            'absence_remplacement/en12_feuille_absence_$s',
          );
        });
        testWidgets('absence_etat_$s', (WidgetTester tester) async {
          await monter(tester, taille, mode);
          await _toucherEtAttendre(tester, declarer);
          await _toucherEtAttendre(tester, declarerMonAbsence);
          await capturer(tester, 'absence_remplacement/en12_absence_etat_$s');
        });
        testWidgets('confirmation_remplacement_$s', (
          WidgetTester tester,
        ) async {
          await monter(tester, taille, mode);
          await _toucherEtAttendre(tester, offre);
          await capturer(
            tester,
            'absence_remplacement/en12_confirmation_remplacement_$s',
          );
        });
        testWidgets('carte_remplacement_$s', (WidgetTester tester) async {
          await monter(tester, taille, mode);
          await _toucherEtAttendre(tester, offre);
          await _toucherEtAttendre(tester, assurer);
          await capturer(
            tester,
            'absence_remplacement/en12_carte_remplacement_$s',
          );
        });
      }
    }
    testWidgets('carte_remplacement_200pct_390_light', (
      WidgetTester tester,
    ) async {
      await monter(tester, const Size(390, 3000), ThemeMode.light, echelle: 2);
      await _toucherEtAttendre(tester, offre);
      await _toucherEtAttendre(tester, assurer);
      await capturer(
        tester,
        'absence_remplacement/en12_carte_remplacement_200pct_390_light',
      );
    });
    testWidgets('carte_remplacement_rtl_390_light', (
      WidgetTester tester,
    ) async {
      await monter(tester, const Size(390, 1500), ThemeMode.light, rtl: true);
      await _toucherEtAttendre(tester, offre);
      await _toucherEtAttendre(tester, assurer);
      await capturer(
        tester,
        'absence_remplacement/en12_carte_remplacement_rtl_390_light',
      );
    });
  });

  // -------------------------------------------------------------------
  // Salle A et B (EN-9, EN-10).
  // -------------------------------------------------------------------
  group('Capture EN-12 : salle', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    Future<void> monter(
      WidgetTester tester,
      Size taille,
      ThemeMode mode,
      RoleSeance role,
      EtatDemoSalle etat, {
      bool rtl = false,
      double echelle = 1,
    }) async {
      fixerVueCapture(tester, taille, 1);
      final Widget ecran = SalleDemo(role: role, etat: etat, onSortir: () {});
      await tester.pumpWidget(
        hoteCapture(
          rtl
              ? Directionality(textDirection: TextDirection.rtl, child: ecran)
              : ecran,
          themeMode: mode,
          echelleTexte: echelle,
        ),
      );
      await stabiliser(tester);
    }

    Future<void> ouvrirSelecteur(WidgetTester tester) async {
      // TB-4 : Commandes, puis la Bibliotheque (premiere entree).
      await _toucherEtAttendre(
        tester,
        find.byKey(const ValueKey<String>('declencheur-commandes')),
      );
      await _toucherEtAttendre(
        tester,
        find.byKey(const ValueKey<String>('commandes-bibliotheque')),
      );
      final Finder bureau = find.text(
        t.salle.seance.panneauSupports.voirBibliotheque,
      );
      final Finder voirTout = bureau.evaluate().isNotEmpty
          ? bureau
          : find.text(t.salle.seance.panneauSupports.voirTout).last;
      await _toucherEtAttendre(tester, voirTout);
    }

    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 844)),
      ('768', const Size(768, 1024)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in _themes) {
        final String s = '${l}_${mode.name}';
        testWidgets('salle_$s', (WidgetTester tester) async {
          await monter(
            tester,
            taille,
            mode,
            RoleSeance.enseignant,
            EtatDemoSalle.repos,
          );
          await capturer(tester, 'salle/en12_salle_$s');
        });
        testWidgets('eleves_fiche_$s', (WidgetTester tester) async {
          await monter(
            tester,
            taille,
            mode,
            RoleSeance.enseignant,
            EtatDemoSalle.eleves,
          );
          await capturer(tester, 'salle/en12_eleves_fiche_$s');
        });
        testWidgets('appel_eleve_$s', (WidgetTester tester) async {
          await monter(
            tester,
            taille,
            mode,
            RoleSeance.eleve,
            EtatDemoSalle.appel,
          );
          await capturer(tester, 'salle/en12_appel_eleve_$s');
        });
        testWidgets('notice_parent_$s', (WidgetTester tester) async {
          await monter(
            tester,
            taille,
            mode,
            RoleSeance.enseignant,
            EtatDemoSalle.visite,
          );
          await capturer(tester, 'salle/en12_notice_parent_$s');
        });
        testWidgets('selecteur_$s', (WidgetTester tester) async {
          await monter(
            tester,
            taille,
            mode,
            RoleSeance.enseignant,
            EtatDemoSalle.repos,
          );
          await ouvrirSelecteur(tester);
          await capturer(tester, 'salle/en12_selecteur_$s');
        });
      }
    }
    testWidgets('salle_200pct_390_light', (WidgetTester tester) async {
      await monter(
        tester,
        const Size(390, 1400),
        ThemeMode.light,
        RoleSeance.enseignant,
        EtatDemoSalle.repos,
        echelle: 2,
      );
      await capturer(tester, 'salle/en12_salle_200pct_390_light');
    });
    testWidgets('salle_rtl_390_light', (WidgetTester tester) async {
      await monter(
        tester,
        const Size(390, 844),
        ThemeMode.light,
        RoleSeance.enseignant,
        EtatDemoSalle.repos,
        rtl: true,
      );
      await capturer(tester, 'salle/en12_salle_rtl_390_light');
    });
  });

  // -------------------------------------------------------------------
  // Revue de Classe (ENS-08) (EN-11).
  // -------------------------------------------------------------------
  group('Capture EN-12 : revue_classe', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    const String classe = 'demo-classe-an-nour';
    final List<MembreSeance> eleves = <MembreSeance>[
      const MembreSeance(
        studentId: 'demo-eleve-yusuf',
        identifiantImmuable: 'RA-YU-000001',
        prenom: 'Yusuf',
      ),
      const MembreSeance(
        studentId: 'demo-eleve-mariam',
        identifiantImmuable: 'RA-MA-000002',
        prenom: 'Mariam',
      ),
      const MembreSeance(
        studentId: 'demo-eleve-aicha',
        identifiantImmuable: 'RA-AI-000003',
        prenom: 'Aïcha',
      ),
    ];
    final List<AnomalieRevue> anomalies = <AnomalieRevue>[
      const AnomalieRevue(
        type: TypeAnomalieRevue.gateAVenir,
        studentId: 'demo-eleve-yusuf',
        eleve: 'Yusuf',
        detail: 'Palier de fin de cycle dans deux semaines.',
      ),
      const AnomalieRevue(
        type: TypeAnomalieRevue.horsCorridor,
        studentId: 'demo-eleve-mariam',
        eleve: 'Mariam',
      ),
      const AnomalieRevue(
        type: TypeAnomalieRevue.transfertPropose,
        studentId: 'demo-eleve-aicha',
        eleve: 'Aïcha',
      ),
    ];

    List<Override> surcharges(List<AnomalieRevue> a) => <Override>[
      serviceEnseignantProvider.overrideWithValue(
        FauxServiceEnseignant()
          ..membresRendus = <String, List<MembreSeance>>{classe: eleves},
      ),
      anomaliesGroupeProvider.overrideWith(
        (Ref ref, String groupeId) async => a,
      ),
    ];

    for (final (String l, Size taille) in <(String, Size)>[
      ('390', const Size(390, 900)),
      ('768', const Size(768, 900)),
      ('1440', const Size(1440, 900)),
    ]) {
      for (final ThemeMode mode in _themes) {
        testWidgets('avec_anomalies_${l}_${mode.name}', (
          WidgetTester tester,
        ) async {
          await _capturer(
            tester,
            'revue_classe/en12_avec_anomalies_${l}_${mode.name}',
            const RevueGroupePage(groupeId: classe),
            taille,
            mode: mode,
            surcharges: surcharges(anomalies),
          );
        });
        testWidgets('vide_${l}_${mode.name}', (WidgetTester tester) async {
          await _capturer(
            tester,
            'revue_classe/en12_vide_${l}_${mode.name}',
            const RevueGroupePage(groupeId: classe),
            taille,
            mode: mode,
            surcharges: surcharges(const <AnomalieRevue>[]),
          );
        });
      }
    }
    testWidgets('avec_anomalies_200pct_390_light', (WidgetTester tester) async {
      await _capturer(
        tester,
        'revue_classe/en12_avec_anomalies_200pct_390_light',
        const RevueGroupePage(groupeId: classe),
        const Size(390, 1800),
        echelle: 2,
        surcharges: surcharges(anomalies),
      );
    });
    testWidgets('avec_anomalies_rtl_390_light', (WidgetTester tester) async {
      await _capturer(
        tester,
        'revue_classe/en12_avec_anomalies_rtl_390_light',
        const RevueGroupePage(groupeId: classe),
        const Size(390, 900),
        rtl: true,
        surcharges: surcharges(anomalies),
      );
    });
  });
}
