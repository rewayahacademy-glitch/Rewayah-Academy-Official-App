// PROFILS P1 (directeur, 11/11/2026) : le gabarit commun du Compte, monte
// avec des lignes fictives. Ordre fixe des sections, section vide masquee,
// en-tete (photo touchable, matricule a copier), Preferences (theme en
// ligne, une seule ligne « Langue » qui ecrit la langue du compte et change
// l'interface), deconnexion rouge avec confirmation, version, et les etats.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_langues_communication.dart';
import 'package:rewayah_academy/core/compte/entete_compte.dart';
import 'package:rewayah_academy/core/compte/groupe_preferences.dart';
import 'package:rewayah_academy/core/compte/langue_compte.dart';
import 'package:rewayah_academy/core/compte/page_compte.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/groupe_reglages.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';

import '../../capture/outil_capture.dart' show hoteCapture;

/// La langue du compte, en memoire : ce qui est ecrit, et un echec voulu.
class FausseLangueCompte implements PortLanguesCommunication {
  FausseLangueCompte({this.code, this.echoue = false});

  String? code;
  bool echoue;
  final List<String> ecrits = <String>[];

  @override
  Future<List<LangueCommunication>> lister() async =>
      const <LangueCommunication>[];

  @override
  Future<String?> maLangue() async => code;

  @override
  Future<void> regler(String code) async {
    if (echoue) throw const LangueRefusee();
    ecrits.add(code);
    this.code = code;
  }
}

PageCompte _page({
  EtatPageCompte etat = EtatPageCompte.contenu,
  Map<SectionCompte, List<LigneRubrique>>? lignes,
  VoidCallback? onChangerPhoto,
  VoidCallback? onReessayer,
}) => PageCompte(
  titre: 'Compte',
  etat: etat,
  onReessayer: onReessayer,
  entete: EnteteCompte(
    avatar: const AvatarTile(prenom: 'Amina', diametre: 72),
    nom: 'Amina Test',
    role: 'Tuteur',
    matricule: 'RA-26-4817',
    onChangerPhoto: onChangerPhoto,
  ),
  version: 'Version 1.0.0',
  preferences: GroupePreferences(
    onNotifications: () {},
    onAccessibilite: () {},
  ),
  lignes:
      lignes ??
      <SectionCompte, List<LigneRubrique>>{
        SectionCompte.aideInformations: <LigneRubrique>[
          LigneRubrique(libelle: 'Aide', onPress: () {}),
        ],
        SectionCompte.monEspace: <LigneRubrique>[
          LigneRubrique(libelle: 'Mes informations', onPress: () {}),
        ],
        SectionCompte.paiements: const <LigneRubrique>[],
        SectionCompte.compteSecurite: <LigneRubrique>[
          LigneRubrique(libelle: 'Sécurité', onPress: () {}),
        ],
      },
);

Future<FausseLangueCompte> _monter(
  WidgetTester tester,
  Widget ecran, {
  FausseLangueCompte? langue,
  List<Override> autres = const <Override>[],
}) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final FausseLangueCompte port = langue ?? FausseLangueCompte();
  await tester.pumpWidget(
    hoteCapture(
      ecran,
      surcharges: <Override>[
        portLanguesCommunicationProvider.overrideWithValue(port),
        stockagePreferencesProvider.overrideWithValue(
          StockagePreferencesMemoire(),
        ),
        ...autres,
      ],
    ),
  );
  await tester.pumpAndSettle();
  return port;
}

double _haut(WidgetTester tester, SectionCompte s) =>
    tester.getTopLeft(find.byKey(PageCompte.sectionKey(s))).dy;

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  testWidgets('les sections suivent l ordre fixe ; une section vide ne s '
      'affiche pas', (WidgetTester tester) async {
    await _monter(tester, _page());
    expect(
      find.byKey(PageCompte.sectionKey(SectionCompte.paiements)),
      findsNothing,
    );
    final List<double> ordre = <double>[
      _haut(tester, SectionCompte.monEspace),
      _haut(tester, SectionCompte.preferences),
      _haut(tester, SectionCompte.compteSecurite),
      _haut(tester, SectionCompte.aideInformations),
    ];
    expect(ordre, List<double>.of(ordre)..sort());
    expect(find.text(t.compte.page.monEspace), findsOneWidget);
    expect(find.text(t.compte.page.paiements), findsNothing);
    // La deconnexion, puis la version, en dernier.
    expect(
      tester.getTopLeft(find.byKey(PageCompte.deconnexionKey)).dy,
      greaterThan(_haut(tester, SectionCompte.aideInformations)),
    );
    expect(
      tester.getTopLeft(find.byKey(PageCompte.versionKey)).dy,
      greaterThan(tester.getTopLeft(find.byKey(PageCompte.deconnexionKey)).dy),
    );
    // « 100 % operationnel » : aucun « Non disponible ».
    expect(find.text(t.compte.nonDisponible), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('en-tete : toucher la photo la change ; « Copier » copie le '
      'matricule', (WidgetTester tester) async {
    int changements = 0;
    String? copie;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall appel) async {
        if (appel.method == 'Clipboard.setData') {
          copie = (appel.arguments as Map<Object?, Object?>)['text'] as String?;
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
    await _monter(tester, _page(onChangerPhoto: () => changements++));
    await tester.tap(find.byKey(EnteteCompte.photoKey));
    expect(changements, 1);
    await tester.tap(find.byKey(EnteteCompte.copierKey));
    await tester.pump();
    expect(copie, 'RA-26-4817');
    expect(find.text(t.compte.matriculeCopie), findsOneWidget);
  });

  testWidgets('sans capacite de photo, la photo ne se touche pas', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _page());
    expect(find.byKey(EnteteCompte.photoKey), findsNothing);
  });

  testWidgets('theme en ligne : le choix est instantane', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _page());
    await tester.tap(find.text(t.compte.themeSombre));
    await tester.pump();
    final ProviderContainer c = ProviderScope.containerOf(
      tester.element(find.byType(GroupePreferences)),
    );
    expect(c.read(modeThemeProvider), ThemeMode.dark);
  });

  testWidgets('une seule ligne « Langue », fr et ar seulement ; changer la '
      'langue ecrit langue_communication et change l interface', (
    WidgetTester tester,
  ) async {
    final FausseLangueCompte port = await _monter(tester, _page());
    expect(find.text(t.compte.langue), findsOneWidget);
    await tester.tap(find.text(t.compte.langue));
    await tester.pumpAndSettle();
    expect(find.text(t.commun.langue.francais), findsWidgets);
    expect(find.text(t.commun.langue.arabe), findsOneWidget);
    // « Systeme » n'est pas une langue proposee : le seul « Systeme » a
    // l'ecran est celui du theme, sous la feuille.
    expect(find.text(t.commun.langue.systeme), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text(t.commun.langue.systeme),
      ),
      findsNothing,
    );
    await tester.tap(find.text(t.commun.langue.arabe));
    await tester.pumpAndSettle();
    expect(port.ecrits, <String>['ar']);
    final ProviderContainer c = ProviderScope.containerOf(
      tester.element(find.byType(GroupePreferences)),
    );
    expect(c.read(preferencesLocalesProvider).langue, PreferenceLangue.arabe);
    expect(find.byKey(GroupePreferences.langueNonEnregistreeKey), findsNothing);
  });

  testWidgets('le serveur refuse : l interface garde la langue choisie et l '
      'ecran le dit', (WidgetTester tester) async {
    await _monter(tester, _page(), langue: FausseLangueCompte(echoue: true));
    await tester.tap(find.text(t.compte.langue));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.commun.langue.arabe));
    await tester.pumpAndSettle();
    expect(
      find.byKey(GroupePreferences.langueNonEnregistreeKey),
      findsOneWidget,
    );
  });

  testWidgets('se deconnecter : une confirmation d abord', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _page());
    await tester.ensureVisible(find.byKey(PageCompte.deconnexionKey));
    await tester.tap(find.text(t.compte.deconnexion).last);
    await tester.pumpAndSettle();
    expect(find.text(t.compte.tuteur.deconnexion.question), findsOneWidget);
  });

  testWidgets('etats : chargement, erreur avec « Reessayer », hors ligne', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _page(etat: EtatPageCompte.chargement));
    expect(find.byType(Skeleton), findsWidgets);
    int relectures = 0;
    await _monter(
      tester,
      _page(etat: EtatPageCompte.erreur, onReessayer: () => relectures++),
    );
    await tester.tap(find.text(t.compte.page.reessayer));
    expect(relectures, 1);
    await _monter(tester, _page(etat: EtatPageCompte.horsLigne));
    expect(find.byType(EtatSysteme), findsOneWidget);
  });

  test('langue du compte : codes fr et ar seulement', () {
    expect(languesDuCompte, <PreferenceLangue>[
      PreferenceLangue.francais,
      PreferenceLangue.arabe,
    ]);
    expect(langueCompteDepuis('ar'), PreferenceLangue.arabe);
    expect(langueCompteDepuis('fr'), PreferenceLangue.francais);
    expect(langueCompteDepuis('es'), isNull);
    expect(codeLangueCompte(PreferenceLangue.arabe), 'ar');
  });

  test('au demarrage, la langue du compte prime ; un choix de la session '
      'n est jamais ecrase', () async {
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        stockagePreferencesProvider.overrideWithValue(
          StockagePreferencesMemoire(),
        ),
      ],
    );
    addTearDown(c.dispose);
    final PreferencesLocalesControleur controleur = c.read(
      preferencesLocalesProvider.notifier,
    );
    controleur.adopterLangueDuCompte(PreferenceLangue.arabe);
    expect(c.read(preferencesLocalesProvider).langue, PreferenceLangue.arabe);
    controleur
      ..langue(PreferenceLangue.francais)
      ..adopterLangueDuCompte(PreferenceLangue.arabe);
    expect(
      c.read(preferencesLocalesProvider).langue,
      PreferenceLangue.francais,
    );
  });
}
