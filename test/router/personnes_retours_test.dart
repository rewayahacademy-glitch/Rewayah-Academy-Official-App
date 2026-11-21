// PERSONNES-UNE-PAGE, etape (e) (directeur, 20/11/2026 : « il faut les
// parcourir toi-meme et les comportements des pages tu verras comment ca fait
// tourner en rond ou fait sortir definitivement de la page mere »).
//
// Chaque page secondaire atteinte depuis la page « Personnes » est ouverte
// dans le VRAI routeur (l'application en demonstration de la direction), puis
// fermee par le retour : on doit retrouver la page mere, a la meme adresse
// (onglet, vue, filtres, personne). Le tableau « page -> retour attendu ->
// retour obtenu » est ecrit dans la sortie du test.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/port_fondateurs.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart'
    show DetailCandidature;
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart'
    show LigneCandidature;
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignants/modeles_enseignants.dart';
import 'package:rewayah_academy/core/enseignants/port_enseignants.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/features/admin_dossiers/revue_dossier.dart';
import 'package:rewayah_academy/features/admin_personnes/personnes_page.dart';

import '../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../fixtures/candidature/faux_candidatures_direction.dart';
import '../support/demo/mode_demonstration.dart';

late GoRouter _routeur;

final List<LigneCandidature> _candidats = <LigneCandidature>[
  ligneTest(id: 'c1', reference: 'CAND-10001', nom: 'Farid Essai'),
  ligneTest(id: 'c2', reference: 'CAND-10002', nom: 'Ghita Fictif'),
];

final List<CompteAdmin> _comptes = <CompteAdmin>[
  for (final (String id, String prenom, AppRole role)
      in <(String, String, AppRole)>[
        ('1', 'Amina', AppRole.student),
        ('2', 'Driss', AppRole.guardian),
        ('3', 'Zina', AppRole.guardian),
        ('4', 'Esma', AppRole.admin),
      ])
    CompteAdmin(
      profilId: 'p$id',
      identifiant: 'RA-26-410$id',
      prenom: prenom,
      nom: 'Essai',
      role: role,
      etat: AccountStatus.active,
      inscritLe: DateTime(2026, 11),
      accesJusquAu: null,
      foyerId: null,
      piece: EtatPiece.aucune,
      contrats: 0,
      aEnseignant: false,
      enfantsDuFoyer: role == AppRole.guardian ? 1 : 0,
      detailsServis: true,
    ),
];

class _Enseignants implements PortEnseignants {
  @override
  Future<PageEnseignants> lister({
    required FiltreEnseignants filtre,
    required TriEnseignants tri,
    required int page,
  }) async => const PageEnseignants(
    lignes: <LigneEnseignant>[],
    total: 0,
    page: 1,
    taillePage: 50,
    compteurs: CompteursEnseignants(),
  );
}

Future<void> _laisser(WidgetTester tester) async {
  for (int i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _monter(WidgetTester tester, String adresse, Size taille) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = taille;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesDemoAdmin(environnement: 'staging'),
        // Des personnes fictives dans chaque onglet.
        comptesProvider.overrideWith((Ref ref) async => _comptes),
        fondateursProvider.overrideWith((Ref ref) async => <String>{}),
        portEnseignantsProvider.overrideWithValue(_Enseignants()),
        portCandidaturesDirectionProvider.overrideWithValue(
          FauxCandidaturesDirection(
            capacitesRendues: capacitesGestes,
            lignes: _candidats,
            details: <DetailCandidature>[
              for (final LigneCandidature l in _candidats)
                detailTest(id: l.id, reference: l.reference, nom: l.nomComplet),
            ],
          ),
        ),
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? _) {
            _routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: _routeur,
            );
          },
        ),
      ),
    ),
  );
  await _laisser(tester);
  _routeur.go(adresse);
  await _laisser(tester);
  await _laisser(tester);
}

String get _adresse =>
    Uri.decodeFull(_routeur.routerDelegate.currentConfiguration.uri.toString());

bool get _surPersonnes =>
    find.byKey(PersonnesPage.cleOnglets).hitTestable().evaluate().isNotEmpty;

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  for (final Size taille in const <Size>[Size(1440, 900), Size(390, 844)]) {
    final String largeur = '${taille.width.toInt()}';

    testWidgets('$largeur : chaque entree du menu « Outils » s\'ouvre, et son '
        'retour ramene a Personnes, meme onglet', (WidgetTester tester) async {
      const String depart = '/admin/personnes?onglet=familles';
      await _monter(tester, depart, taille);
      expect(_surPersonnes, isTrue);
      final List<String> entrees = <String>[
        for (final EntreeAction e
            in tester
                .widget<MenuActions>(find.byKey(PersonnesPage.cleAutresPages))
                .actions)
          e.libelle,
      ];
      expect(entrees.length, greaterThanOrEqualTo(10));
      final List<String> tableau = <String>[];
      // Deux fois chaque page : le retour du systeme, puis la fleche a
      // l'ecran.
      for (final String entree in entrees) {
        for (final bool fleche in <bool>[false, true]) {
          await tester.tap(find.byKey(PersonnesPage.cleAutresPages));
          await _laisser(tester);
          await tester.tap(find.text(entree).last);
          await _laisser(tester);
          await _laisser(tester);
          final bool ailleurs = !_surPersonnes;
          String moyen = 'retour du systeme';
          if (fleche) {
            final Finder disque = find.byType(DisqueRetour).hitTestable();
            if (disque.evaluate().isEmpty) {
              moyen = 'PAS DE FLECHE (retour du systeme)';
              await tester.binding.handlePopRoute();
            } else {
              moyen = 'fleche';
              await tester.tap(disque.first);
            }
          } else {
            await tester.binding.handlePopRoute();
          }
          await _laisser(tester);
          await _laisser(tester);
          final bool revenu = _surPersonnes && _adresse == depart;
          tableau.add(
            'RETOUR $largeur | $entree | $moyen | attendu $depart | '
            'obtenu $_adresse | ${ailleurs ? 'page' : 'feuille'} | '
            '${revenu ? 'OK' : 'ECHEC'}',
          );
          expect(revenu, isTrue, reason: tableau.last);
          expect(tester.takeException(), isNull, reason: entree);
        }
      }
      tableau.forEach(debugPrint);
    });

    testWidgets('$largeur : le dossier d\'un candidat, puis la revue d\'une '
        'piece : le retour ramene a Personnes, la vue et la personne', (
      WidgetTester tester,
    ) async {
      // Le dossier, ouvert par le menu de la premiere ligne.
      const String candidats =
          '/admin/personnes?onglet=enseignants&vue=candidats';
      await _monter(tester, candidats, taille);
      final Finder menus = find.descendant(
        of: find.byKey(PersonnesPage.cleListe),
        matching: find.byWidgetPredicate(
          (Widget w) => w is MenuActions && w.points,
        ),
      );
      expect(menus, findsWidgets);
      await tester.tap(menus.first);
      await _laisser(tester);
      await tester.tap(
        find.text(t.admin.candidatures.liste.ouvrirDossier).last,
      );
      await _laisser(tester);
      await _laisser(tester);
      expect(_surPersonnes, isFalse);
      await tester.binding.handlePopRoute();
      await _laisser(tester);
      await _laisser(tester);
      debugPrint(
        'RETOUR $largeur | Dossier d\'un candidat | retour du systeme | '
        'attendu $candidats | '
        'obtenu $_adresse | page | '
        '${_surPersonnes && _adresse == candidats ? 'OK' : 'ECHEC'}',
      );
      expect(_surPersonnes, isTrue);
      expect(_adresse, candidats);
      // La meme chose par la fleche a l'ecran.
      await tester.tap(menus.first);
      await _laisser(tester);
      await tester.tap(
        find.text(t.admin.candidatures.liste.ouvrirDossier).last,
      );
      await _laisser(tester);
      await _laisser(tester);
      final Finder flecheDossier = find.byType(DisqueRetour).hitTestable();
      final bool aFlecheDossier = flecheDossier.evaluate().isNotEmpty;
      if (aFlecheDossier) {
        await tester.tap(flecheDossier.first);
      } else {
        await tester.binding.handlePopRoute();
      }
      await _laisser(tester);
      await _laisser(tester);
      debugPrint(
        'RETOUR $largeur | Dossier d\'un candidat | '
        '${aFlecheDossier ? 'fleche' : 'PAS DE FLECHE (retour du systeme)'} | '
        'attendu $candidats | obtenu $_adresse | page | '
        '${_surPersonnes && _adresse == candidats ? 'OK' : 'ECHEC'}',
      );
      expect(_surPersonnes, isTrue);
      expect(_adresse, candidats);

      // La revue d'une piece : pendant qu'elle est ouverte, la barre laterale
      // n'allume plus « Dossiers a valider » (il n'y est plus).
      const String pieces = '/admin/personnes?onglet=enseignants&vue=pieces';
      _routeur.go(pieces);
      await _laisser(tester);
      await _laisser(tester);
      await tester.tap(find.text('Omar Haddad').first);
      await _laisser(tester);
      if (taille.width >= 1024) {
        await tester.tap(find.byKey(PersonnesPage.cleVerifierPiece));
        await _laisser(tester);
      }
      await _laisser(tester);
      expect(find.byType(RevueDossier), findsOneWidget);
      if (taille.width >= 1024) {
        expect(
          find.descendant(
            of: find.byKey(AdminShell.barreLateraleKey),
            matching: find.text(t.dossiers.titre),
          ),
          findsNothing,
        );
      }
      final Finder flechePiece = find.byType(DisqueRetour).hitTestable();
      final bool aFlechePiece = flechePiece.evaluate().isNotEmpty;
      if (aFlechePiece) {
        await tester.tap(flechePiece.first);
      } else {
        await tester.binding.handlePopRoute();
      }
      await _laisser(tester);
      await _laisser(tester);
      debugPrint(
        'RETOUR $largeur | Revue d\'une piece | '
        '${aFlechePiece ? 'fleche' : 'PAS DE FLECHE (retour du systeme)'} | '
        'attendu vue=pieces | '
        'obtenu $_adresse | page | '
        '${_surPersonnes && _adresse.contains('vue=pieces') ? 'OK' : 'ECHEC'}',
      );
      expect(_surPersonnes, isTrue);
      expect(_adresse, contains('vue=pieces'));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('1440 : la barre laterale ne montre plus, sous Personnes, que '
      'Importer et Suppressions', (WidgetTester tester) async {
    await _monter(tester, '/admin/personnes', const Size(1440, 900));
    final Finder barre = find.byKey(AdminShell.barreLateraleKey);
    Finder dans(String libelle) =>
        find.descendant(of: barre, matching: find.text(libelle));
    expect(dans(t.admin.importInscriptions.onglet), findsOneWidget);
    expect(dans(t.admin.suppressions.onglet), findsOneWidget);
    for (final String retire in <String>[
      t.dossiers.titre,
      t.admin.comptes.titre,
      t.admin.candidatures.titre,
      t.reprisesAdmin.onglet,
      t.admin.listeEnseignants.titre,
      t.recrutement.invitations.onglet,
      t.admin.equipe.titre,
      t.nav.admin.sousLiens.admissions,
    ]) {
      expect(dans(retire), findsNothing, reason: retire);
    }
  });
}
