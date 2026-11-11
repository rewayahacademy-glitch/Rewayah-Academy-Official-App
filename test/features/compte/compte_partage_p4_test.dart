// PROFILS P4 (pilote, 11/11/2026) : le Compte partage (eleve standard,
// controleur, comptable, administration) compose dans `PageCompte`.
//
// - Une seule ligne « Langue » : elle ecrit la langue du compte
//   (`ma_langue_communication_regler`, donc `langue_communication`) ET change
//   la langue de l'interface ; francais et arabe seulement ; un refus du
//   serveur est dit (garde-cap, 11/11/2026).
// - « 100 % operationnel » (directeur, 11/11/2026) : aucune ligne grisee,
//   aucune valeur « Non disponible », aucune ligne qui n'agit sur rien.
// - Le matricule de `LigneMatricule` ne se met plus deux fois a l'echelle.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope, Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_langues_communication.dart';
import 'package:rewayah_academy/core/capacites/port_support.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/identite/port_matricule.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/session/port_capacite_eleve.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/suivi/service_suivi.dart';
import 'package:rewayah_academy/core/version/ligne_version.dart';
import 'package:rewayah_academy/core/widgets/page_compte.dart';
import 'package:rewayah_academy/core/widgets/setting_row.dart';
import 'package:rewayah_academy/features/accueil_eleve/mon_espace_accessibilite.dart';
import 'package:rewayah_academy/features/compte/compte_page.dart';
import 'package:rewayah_academy/features/compte/ligne_matricule.dart';
import 'package:rewayah_academy/features/compte/lignes_compte.dart';
import 'package:rewayah_academy/features/demo/identite/matricule_demo.dart';
import 'package:rewayah_academy/features/suivi_eleve/suivi_eleve_page.dart';

import '../../capture/outil_capture.dart';
import '../../support/harnais.dart';

/// Retient chaque langue reglee au serveur ; refuse sur demande.
class _FauxLangues implements PortLanguesCommunication {
  _FauxLangues({this.refuse = false});

  final bool refuse;
  final List<String> reglees = <String>[];

  @override
  Future<List<LangueCommunication>> lister() async =>
      const <LangueCommunication>[];

  @override
  Future<String?> maLangue() async => null;

  @override
  Future<void> regler(String code) async {
    if (refuse) throw const LangueRefusee();
    reglees.add(code);
  }
}

List<Override> _surcharges(
  AppRole role, {
  PortLanguesCommunication? langues,
}) => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(
      SessionState(
        resolue: true,
        role: role,
        profileId: 'p1',
        accountStatus: AccountStatus.active,
      ),
    ),
  ),
  portLanguesCommunicationProvider.overrideWithValue(langues ?? _FauxLangues()),
  // La LigneVersion lit `version.json` : une version de test.
  versionAppliProvider.overrideWith(
    (Ref _) async => (version: '0.2.0', build: '423'),
  ),
];

Future<void> _monter(
  WidgetTester tester,
  AppRole role, {
  PortLanguesCommunication? langues,
}) async {
  tester.view
    ..physicalSize = const Size(390, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(const ComptePage(), surcharges: _surcharges(role, langues: langues)),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() async => LocaleSettings.setLocale(AppLocale.fr));
  capturesP4();

  group('Langue : une seule ligne, langue du compte', () {
    testWidgets('changer la Langue ecrit langue_communication et '
        'l interface', (WidgetTester tester) async {
      final _FauxLangues langues = _FauxLangues();
      await _monter(tester, AppRole.student, langues: langues);
      // Une seule ligne de langue : jamais « Langue des e-mails ».
      expect(find.text(t.compte.langue), findsOneWidget);
      expect(find.textContaining('e-mails et des messages'), findsNothing);

      await tester.tap(find.text(t.compte.langue));
      await tester.pumpAndSettle();
      // Francais et arabe, rien d'autre.
      expect(find.text(t.commun.langue.francais), findsWidgets);
      expect(find.text(t.commun.langue.arabe), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(FeuilleLangueCompte),
          matching: find.text(t.commun.langue.systeme),
        ),
        findsNothing,
      );

      await tester.tap(find.text(t.commun.langue.arabe));
      await tester.pumpAndSettle();
      expect(langues.reglees, <String>['ar']);
      final ProviderContainerLecture lecture = ProviderContainerLecture(
        tester,
        find.byType(ComptePage),
      );
      expect(lecture.langue, PreferenceLangue.arabe);
      expect(find.byKey(FeuilleLangueCompte.refusKey), findsNothing);
    });

    testWidgets('la ligne dit la langue affichee, meme quand la preference '
        'suit l appareil', (WidgetTester tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _monter(tester, AppRole.student);
      expect(find.text(t.commun.langue.arabe), findsOneWidget);
      expect(find.text(t.commun.langue.francais), findsNothing);
    });

    testWidgets('refus du serveur : l ecran le dit', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        AppRole.student,
        langues: _FauxLangues(refuse: true),
      );
      await tester.tap(find.text(t.compte.langue));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.commun.langue.arabe));
      await tester.pumpAndSettle();
      expect(find.byKey(FeuilleLangueCompte.refusKey), findsOneWidget);
    });
  });

  group('100 % operationnel : aucune ligne qui ne marche pas', () {
    for (final AppRole role in <AppRole>[
      AppRole.student,
      AppRole.controller,
      AppRole.accountant,
      AppRole.admin,
    ]) {
      testWidgets('${role.name} : gabarit commun, rien d inerte', (
        WidgetTester tester,
      ) async {
        await _monter(tester, role);
        expect(find.byType(PageCompte), findsOneWidget);
        expect(find.byType(SettingRow), findsNothing);
        for (final String inerte in <String>[
          t.compte.nonDisponible,
          t.compte.confidentialiteDetail,
          t.compte.fuseau,
          t.compte.habilitation,
          t.compte.notificationsCours,
          t.compte.profilDetail,
          t.compte.reglagesDetail,
        ]) {
          expect(find.text(inerte), findsNothing, reason: inerte);
        }
        // Les lignes qui marchent pour tous : Langue, Accessibilite,
        // Informations legales, Se deconnecter.
        expect(find.text(t.compte.langue), findsOneWidget);
        expect(find.text(t.compte.accessibilite), findsOneWidget);
        expect(find.text(t.compte.tuteur.aide.legal), findsOneWidget);
        expect(find.byKey(PageCompte.deconnecterKey), findsOneWidget);
        // La ligne de version, pour chaque role (directeur, 11/11/2026).
        expect(
          find.descendant(
            of: find.byKey(PageCompte.versionKey),
            matching: find.text('Version 0.2.0 (423)'),
          ),
          findsOneWidget,
        );
      });
    }

    testWidgets('Accessibilite : les trois reglages qui agissent', (
      WidgetTester tester,
    ) async {
      await _monter(tester, AppRole.student);
      await tester.tap(find.text(t.compte.accessibilite));
      await tester.pumpAndSettle();
      expect(find.byKey(FeuilleAccessibiliteCompte.animationsKey), findsOne);
      expect(find.byKey(FeuilleAccessibiliteCompte.raccourcisKey), findsOne);
      expect(find.byKey(FeuilleAccessibiliteCompte.effetsKey), findsOne);
      await tester.tap(find.byKey(FeuilleAccessibiliteCompte.animationsKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(FeuilleAccessibiliteCompte.effetsKey));
      await tester.pumpAndSettle();
      final ProviderContainerLecture lecture = ProviderContainerLecture(
        tester,
        find.byType(ComptePage),
      );
      expect(lecture.animationsReduites, isTrue);
      expect(lecture.effetsReduits, isTrue);
    });
  });

  group('Lignes conditionnelles, cas positif', () {
    testWidgets('Notifications : le serveur les autorise, la ligne est la et '
        'ouvre la feuille PUSH-1', (WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(390, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hote(
          const ComptePage(),
          surcharges: <Override>[
            ..._surcharges(AppRole.student),
            notificationsAutoriseesProvider.overrideWith((Ref _) async => true),
          ],
        ),
      );
      await tester.pumpAndSettle();
      final Finder ligne = find.text(
        t.compte.tuteur.pagePreferences.notifications,
      );
      expect(ligne, findsOneWidget);
      await tester.tap(ligne);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(t.push1.reglages.titre), findsWidgets);
    });

    testWidgets('Aide : un canal publie, la ligne l affiche', (
      WidgetTester tester,
    ) async {
      tester.view
        ..physicalSize = const Size(390, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hote(
          const ComptePage(),
          surcharges: <Override>[
            ..._surcharges(AppRole.controller),
            canalAideCompteProvider.overrideWith(
              (Ref _) async => const CanalSupport(
                nature: NatureCanalSupport.lien,
                adresse: 'https://aide.exemple.invalid',
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.compte.tuteur.pageAide.canalLien), findsOneWidget);
      expect(find.text('https://aide.exemple.invalid'), findsOneWidget);
    });

    testWidgets('sans canal publie ni autorisation : aucune des deux lignes', (
      WidgetTester tester,
    ) async {
      await _monter(tester, AppRole.controller);
      expect(find.text(t.compte.tuteur.pageAide.canalLien), findsNothing);
      expect(find.text(t.compte.tuteur.pageAide.canalCourriel), findsNothing);
      expect(
        find.text(t.compte.tuteur.pagePreferences.notifications),
        findsNothing,
      );
    });
  });

  testWidgets('Interface guidee (Mon espace) : la ligne de version', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      hote(
        MonEspaceAccessibilite(
          prenom: 'Hakim',
          modeActif: true,
          onAide: () {},
          personneId: 'p1',
        ),
        surcharges: _surcharges(AppRole.student),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(MonEspaceAccessibilite.versionKey),
        matching: find.text('Version 0.2.0 (423)'),
      ),
      findsOneWidget,
    );
  });

  group('LigneMatricule : une seule mise a l echelle', () {
    Future<double> hauteurValeur(WidgetTester tester, double echelle) async {
      tester.view
        ..physicalSize = const Size(390, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = echelle;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        hote(
          const Scaffold(body: LigneMatricule(profileId: 'p1')),
          surcharges: <Override>[
            portMatriculeProvider.overrideWithValue(
              const MatriculeDemo(<String, Matricule>{
                'p1': Matricule(valeur: 'RA-26-4817', role: RoleAffiche.eleve),
              }),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      // La hauteur a l'ecran, transformation du WidgetSpan comprise.
      return tester.getRect(find.byKey(LigneMatricule.valeurKey)).height;
    }

    testWidgets('a x2, la valeur est deux fois plus grande, pas quatre', (
      WidgetTester tester,
    ) async {
      final double h1 = await hauteurValeur(tester, 1);
      final double h2 = await hauteurValeur(tester, 2);
      expect(h2 / h1, inInclusiveRange(1.6, 2.4));
      // Le rapport borne a 2,4 prouve aussi une seule ligne : coupee dans
      // le mot, la valeur ferait au moins quatre fois la hauteur de x1.
    });
  });
}

/// Lit les preferences dans le conteneur de la page.
class ProviderContainerLecture {
  /// Lit depuis l'element de [cible].
  ProviderContainerLecture(WidgetTester tester, Finder cible)
    : _preferences = ProviderScope.containerOf(tester.element(cible))
          .read(preferencesLocalesProvider);

  final PreferencesLocales _preferences;

  /// La langue de l'interface.
  PreferenceLangue get langue => _preferences.langue;

  /// Le mouvement reduit.
  bool get animationsReduites => _preferences.animationsReduites;

  /// Les effets reduits.
  bool get effetsReduits => _preferences.effetsReduits;
}

/// Captures R3 de P4 : la vraie `ComptePage` de chaque role (eleve,
/// controleur, comptable, direction) et l'Interface guidee (Mon espace), a
/// 390 et 1440, en clair, sombre, arabe et texte x2 (garde-cap, 11/11/2026).
/// Donnees de test seulement. Jamais sans `CAPTURE_DIR`.
void capturesP4() {
  group('Capture : PROFILS P4', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);

    const List<(String, ThemeMode, String, double)> variantes =
        <(String, ThemeMode, String, double)>[
          ('clair', ThemeMode.light, 'fr', 1),
          ('sombre', ThemeMode.dark, 'fr', 1),
          ('arabe', ThemeMode.light, 'ar', 1),
          ('texte2', ThemeMode.light, 'fr', 2),
        ];
    final List<(String, Widget, AppRole)> ecrans = <(String, Widget, AppRole)>[
      ('eleve', const ComptePage(), AppRole.student),
      ('controleur', const ComptePage(), AppRole.controller),
      ('comptable', const ComptePage(), AppRole.accountant),
      ('direction', const ComptePage(), AppRole.admin),
      // La Bibliotheque en tete de « Ma classe » (garde-cap, 11/11/2026).
      (
        'ma_classe',
        SuiviElevePage(horloge: () => DateTime(2026, 11, 11, 10)),
        AppRole.student,
      ),
      // L'eleve adulte : la meme page s'intitule « Suivi », comme son onglet.
      (
        'ma_classe_adulte',
        SuiviElevePage(horloge: () => DateTime(2026, 11, 11, 10)),
        AppRole.student,
      ),
      (
        'interface_guidee',
        MonEspaceAccessibilite(
          prenom: 'Hakim',
          modeActif: true,
          onAide: () {},
          personneId: 'p1',
        ),
        AppRole.student,
      ),
    ];
    for (final (String role, Widget ecran, AppRole appRole) in ecrans) {
      for (final double largeur in <double>[390, 1440]) {
        for (final (String v, ThemeMode mode, String langue, double echelle)
            in variantes) {
          final String nom = '${role}_${largeur.toInt()}_$v';
          testWidgets(nom, (WidgetTester tester) async {
            if (langue == 'ar') {
              await tester.runAsync(
                () => LocaleSettings.setLocale(AppLocale.ar),
              );
            }
            fixerVueCapture(
              tester,
              Size(largeur, echelle == 2 ? 3400 : 1900),
              1,
            );
            await tester.pumpWidget(
              hoteCapture(
                ecran,
                themeMode: mode,
                echelleTexte: echelle,
                surcharges: <Override>[
                  ..._surcharges(appRole),
                  if (role == 'ma_classe_adulte')
                    portCapaciteEleveProvider.overrideWithValue(
                      const PortCapaciteEleveFactice(autonomes: <String>{'p1'}),
                    ),
                  // « Ma classe » : aucune seance passee (donnees de test).
                  seancesDeMonSuiviProvider.overrideWith(
                    (Ref _) async => const <Seance>[],
                  ),
                  presenceDuSuiviProvider.overrideWith(
                    (Ref _) async => const <PresenceParticipant>[],
                  ),
                  notificationsAutoriseesProvider.overrideWith(
                    (Ref _) async => true,
                  ),
                  portMatriculeProvider.overrideWithValue(
                    const MatriculeDemo(<String, Matricule>{
                      'p1': Matricule(
                        valeur: 'RA-26-4817',
                        role: RoleAffiche.eleve,
                      ),
                    }),
                  ),
                ],
              ),
            );
            await stabiliser(tester);
            debugPrint('PNG ${await capturerVue(tester, nom)}');
          });
        }
      }
    }
    for (final (String nom, String ligne) in <(String, String)>[
      ('feuille_langue_390', 'langue'),
      ('feuille_accessibilite_390', 'accessibilite'),
    ]) {
      testWidgets(nom, (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(390, 1000), 1);
        await tester.pumpWidget(
          hoteCapture(
            const ComptePage(),
            surcharges: _surcharges(AppRole.student),
          ),
        );
        await stabiliser(tester);
        await tester.tap(
          find.text(
            ligne == 'langue' ? t.compte.langue : t.compte.accessibilite,
          ),
        );
        await stabiliser(tester);
        debugPrint('PNG ${await capturerVue(tester, nom)}');
      });
    }
  });
}
