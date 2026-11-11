// PROFILS P1 (pilote du 11/11/2026) : le gabarit unique du Compte, avec des
// lignes fictives (aucune page de role n'y est branchee). Ordre fixe des
// sections, section vide masquee, preferences sur la page, deconnexion en
// rouge avec confirmation, version ; etats chargement, contenu, vide, erreur,
// hors ligne ; 390 et 1440, clair, sombre, arabe, texte x2. Les captures
// (CAPTURE_DIR) montrent cette page de demonstration interne, donnees de test.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/version/ligne_version.dart';
import 'package:rewayah_academy/core/widgets/entete_compte.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/groupe_preferences.dart';
import 'package:rewayah_academy/core/widgets/groupe_reglages.dart';
import 'package:rewayah_academy/core/widgets/page_compte.dart';
import 'package:rewayah_academy/core/widgets/selecteur_theme.dart';

import '../../capture/outil_capture.dart';
import '../../teaching_core/a/faux/faux_reseau.dart';

const IdentiteCompte _identite = IdentiteCompte(
  nom: 'Amina Diallo',
  role: 'Élève',
  matricule: 'RA-26-4817',
  statut: 'Compte actif',
);

void _rien() {}

/// Les compteurs des gestes, relus par les tests.
class _Gestes {
  int deconnexions = 0;
  int reessais = 0;
  int photos = 0;
  int lignes = 0;
}

Map<SectionCompte, List<LigneRubrique>> _sections(_Gestes g) =>
    <SectionCompte, List<LigneRubrique>>{
      SectionCompte.aide: <LigneRubrique>[
        LigneRubrique(
          icone: AppIcons.info,
          libelle: 'Aide',
          onPress: () => g.lignes++,
        ),
      ],
      SectionCompte.monEspace: <LigneRubrique>[
        LigneRubrique(
          icone: AppIcons.classes,
          libelle: 'Ma classe',
          onPress: () => g.lignes++,
        ),
      ],
      // Paiements sans ligne : la section ne s'affiche pas.
      SectionCompte.paiements: const <LigneRubrique>[],
      SectionCompte.compteSecurite: <LigneRubrique>[
        LigneRubrique(
          icone: AppIcons.verrou,
          libelle: 'Connexion et sécurité',
          onPress: () => g.lignes++,
        ),
      ],
    };

const GroupePreferences _preferences = GroupePreferences(
  langue: LigneRubrique(
    icone: AppIcons.reglages,
    libelle: 'Langue',
    valeur: 'Français',
    onPress: _rien,
  ),
  notifications: LigneRubrique(
    icone: AppIcons.notifications,
    libelle: 'Notifications',
    onPress: _rien,
  ),
);

Future<_Gestes> _monter(
  WidgetTester tester, {
  AsyncValue<IdentiteCompte?> identite = const AsyncValue<IdentiteCompte?>.data(
    _identite,
  ),
  double largeur = 390,
  double hauteur = 1800,
  double echelle = 1,
  ThemeMode mode = ThemeMode.light,
  bool horsLigne = false,
  double densite = 1,
}) async {
  final _Gestes g = _Gestes();
  fixerVueCapture(tester, Size(largeur, hauteur), densite);
  await tester.pumpWidget(
    hoteCapture(
      PageCompte(
        identite: identite,
        onDeconnecter: () async => g.deconnexions++,
        onReessayer: () => g.reessais++,
        onChangerPhoto: () => g.photos++,
        preferences: _preferences,
        sections: _sections(g),
      ),
      themeMode: mode,
      echelleTexte: echelle,
      surcharges: <Override>[
        serviceReseauProvider.overrideWithValue(
          FauxServiceReseau(horsLigneMaintenant: horsLigne),
        ),
        // La LigneVersion lit `version.json` : une version de test.
        versionAppliProvider.overrideWith(
          (Ref _) async => (version: '1.0.0', build: null),
        ),
      ],
    ),
  );
  await stabiliser(tester);
  return g;
}

void _attendreOrdre(WidgetTester tester) {
  double haut(Finder f) => tester.getTopLeft(f).dy;
  final List<double> hauts = <double>[
    haut(find.byType(EnteteCompte)),
    haut(find.byKey(PageCompte.cleSection(SectionCompte.monEspace))),
    haut(find.byKey(PageCompte.cleSection(SectionCompte.preferences))),
    haut(find.byKey(PageCompte.cleSection(SectionCompte.compteSecurite))),
    haut(find.byKey(PageCompte.cleSection(SectionCompte.aide))),
    haut(find.byKey(PageCompte.deconnecterKey)),
    haut(find.byKey(PageCompte.versionKey)),
  ];
  for (int i = 1; i < hauts.length; i++) {
    expect(hauts[i], greaterThan(hauts[i - 1]), reason: 'rang $i');
  }
}

/// Les couleurs portees par un texte et ses morceaux.
List<Color?> _couleurs(InlineSpan span) {
  final List<Color?> couleurs = <Color?>[];
  span.visitChildren((InlineSpan s) {
    couleurs.add(s.style?.color);
    return true;
  });
  return couleurs;
}

/// Aucun texte visible ne contient « groupe » (mots-rewayah : « Classe »).
void _sansMotGroupe(WidgetTester tester) {
  for (final Element e in find.byType(RichText).evaluate()) {
    final String texte = (e.widget as RichText).text.toPlainText();
    expect(texte.toLowerCase().contains('groupe'), isFalse, reason: texte);
  }
}

void main() {
  tearDown(() async => LocaleSettings.setLocale(AppLocale.fr));

  group('PROFILS P1 : le gabarit', () {
    for (final double largeur in <double>[390, 1440]) {
      for (final (String nomMode, ThemeMode mode) in <(String, ThemeMode)>[
        ('clair', ThemeMode.light),
        ('sombre', ThemeMode.dark),
      ]) {
        for (final String langue in <String>['fr', 'ar']) {
          for (final double echelle in <double>[1, 2]) {
            testWidgets(
              '$largeur, $nomMode, $langue, texte x${echelle.toInt()} : '
              'ordre fixe, section vide masquee, sans debordement',
              (WidgetTester tester) async {
                if (langue == 'ar') {
                  await tester.runAsync(
                    () => LocaleSettings.setLocale(AppLocale.ar),
                  );
                }
                await _monter(
                  tester,
                  largeur: largeur,
                  hauteur: echelle == 2 ? 3200 : 1800,
                  echelle: echelle,
                  mode: mode,
                );
                expect(tester.takeException(), isNull);
                _attendreOrdre(tester);
                expect(
                  find.byKey(PageCompte.cleSection(SectionCompte.paiements)),
                  findsNothing,
                );
                expect(find.byType(SelecteurTheme), findsOneWidget);
                expect(
                  find.descendant(
                    of: find.byKey(
                      PageCompte.cleSection(SectionCompte.preferences),
                    ),
                    matching: find.byType(SelecteurTheme),
                  ),
                  findsOneWidget,
                );
                expect(
                  find.descendant(
                    of: find.byKey(PageCompte.versionKey),
                    matching: find.textContaining('1.0.0'),
                  ),
                  findsOneWidget,
                );
                expect(
                  Directionality.of(tester.element(find.byType(EnteteCompte))),
                  langue == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                );
                _sansMotGroupe(tester);
              },
            );
          }
        }
      }
    }
  });

  group('PROFILS P1 : les gestes', () {
    testWidgets('Se deconnecter demande confirmation ; Annuler ne fait rien', (
      WidgetTester tester,
    ) async {
      final _Gestes g = await _monter(tester);
      await tester.tap(find.byKey(PageCompte.deconnecterKey));
      await stabiliser(tester);
      expect(find.text(t.compte.tuteur.deconnexion.question), findsWidgets);
      expect(g.deconnexions, 0);
      await tester.tap(find.text(t.commun.annuler).last);
      await stabiliser(tester);
      expect(g.deconnexions, 0);

      await tester.tap(find.byKey(PageCompte.deconnecterKey));
      await stabiliser(tester);
      await tester.tap(find.text(t.compte.tuteur.deconnexion.confirmer).last);
      await stabiliser(tester);
      expect(g.deconnexions, 1);
    });

    testWidgets('la ligne Se deconnecter est rouge (encre d alerte)', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      final Finder libelle = find.descendant(
        of: find.byKey(PageCompte.deconnecterKey),
        matching: find.text(t.compte.deconnexion),
      );
      expect(libelle, findsOneWidget);
      final RichText rendu = tester.widget<RichText>(
        find.descendant(of: libelle, matching: find.byType(RichText)),
      );
      final TextStyle attendu = AppPalette.of(tester.element(libelle)).inkAlert
          .applyTo(const TextStyle());
      expect(_couleurs(rendu.text), contains(attendu.color));
    });

    testWidgets('on touche la photo pour la changer', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      final _Gestes g = await _monter(tester);
      final SemanticsNode noeud = tester.getSemantics(
        find.byKey(EnteteCompte.photoKey),
      );
      expect(noeud.label, t.compte.page.changerPhoto);
      expect(noeud.flagsCollection.isButton, isTrue);
      await tester.tap(find.byKey(EnteteCompte.photoKey));
      await stabiliser(tester);
      expect(g.photos, 1);
      semantique.dispose();
    });

    testWidgets('Copier met le matricule seul dans le presse-papiers', (
      WidgetTester tester,
    ) async {
      String? copie;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall appel) async {
          if (appel.method == 'Clipboard.setData') {
            copie =
                (appel.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await _monter(tester);
      expect(find.text('RA-26-4817'), findsOneWidget);
      await tester.tap(find.byKey(EnteteCompte.copierKey));
      await stabiliser(tester);
      expect(copie, 'RA-26-4817');
      expect(find.text(t.compte.matriculeCopie), findsOneWidget);
    });
  });

  group('PROFILS P1 : les etats', () {
    testWidgets('chargement : squelette, deconnexion toujours la', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        identite: const AsyncValue<IdentiteCompte?>.loading(),
      );
      expect(find.byType(EnteteCompte), findsNothing);
      expect(find.byKey(PageCompte.deconnecterKey), findsOneWidget);
      expect(find.byType(SelecteurTheme), findsOneWidget);
    });

    testWidgets('vide : une phrase, sans bouton', (WidgetTester tester) async {
      await _monter(
        tester,
        identite: const AsyncValue<IdentiteCompte?>.data(null),
      );
      expect(find.text(t.compte.page.identiteVide), findsOneWidget);
      expect(find.byType(EnteteCompte), findsNothing);
      expect(find.byKey(PageCompte.deconnecterKey), findsOneWidget);
    });

    testWidgets('erreur : Reessayer relit l identite', (
      WidgetTester tester,
    ) async {
      final _Gestes g = await _monter(
        tester,
        identite: AsyncValue<IdentiteCompte?>.error(
          StateError('lecture refusee'),
          StackTrace.empty,
        ),
      );
      expect(find.text(t.compte.page.identiteEchec), findsOneWidget);
      await tester.tap(
        find.text(EtatSysteme.libelleActionPar(NatureEtat.echecServeur)).first,
      );
      await stabiliser(tester);
      expect(g.reessais, 1);
      expect(find.byKey(PageCompte.deconnecterKey), findsOneWidget);
    });

    testWidgets('hors ligne : le bandeau, le contenu reste', (
      WidgetTester tester,
    ) async {
      await _monter(tester, horsLigne: true);
      expect(find.text(t.reseau.horsLigne), findsOneWidget);
      expect(find.byType(EnteteCompte), findsOneWidget);
      expect(find.byKey(PageCompte.deconnecterKey), findsOneWidget);
    });
  });

  group('Capture : PROFILS P1', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final double largeur in <double>[390, 1440]) {
      for (final (String nomMode, ThemeMode mode) in <(String, ThemeMode)>[
        ('clair', ThemeMode.light),
        ('sombre', ThemeMode.dark),
      ]) {
        for (final String langue in <String>['fr', 'ar']) {
          for (final double echelle in <double>[1, 2]) {
            final String nom =
                'page_compte_${largeur.toInt()}_${nomMode}_${langue}_'
                'x${echelle.toInt()}';
            testWidgets(nom, (WidgetTester tester) async {
              if (langue == 'ar') {
                await tester.runAsync(
                  () => LocaleSettings.setLocale(AppLocale.ar),
                );
              }
              await _monter(
                tester,
                largeur: largeur,
                hauteur: echelle == 2 ? 3200 : 1800,
                echelle: echelle,
                mode: mode,
              );
              debugPrint('PNG ${await capturerVue(tester, nom)}');
            });
          }
        }
      }
    }
    for (final (String etat, AsyncValue<IdentiteCompte?> valeur, bool hl)
        in <(String, AsyncValue<IdentiteCompte?>, bool)>[
          ('chargement', const AsyncValue<IdentiteCompte?>.loading(), false),
          ('vide', const AsyncValue<IdentiteCompte?>.data(null), false),
          (
            'erreur',
            AsyncValue<IdentiteCompte?>.error(
              StateError('lecture refusee'),
              StackTrace.empty,
            ),
            false,
          ),
          (
            'hors_ligne',
            const AsyncValue<IdentiteCompte?>.data(_identite),
            true,
          ),
        ]) {
      testWidgets('page_compte_etat_$etat', (WidgetTester tester) async {
        await _monter(tester, identite: valeur, horsLigne: hl);
        debugPrint(
          'PNG ${await capturerVue(tester, 'page_compte_390_etat_$etat')}',
        );
      });
    }
  });
}
