// Captures du socle partage des listes (LISTES-1, 23/10/2026), lot 1 :
//
//   * le menu du bouton d'action (le defaut critique du directeur), sur une
//     page de test isolee et sur la VRAIE fiche d'une candidature, ferme,
//     survole, a l'ouverture et ouvert, clair et sombre, 1440 et 390 ;
//   * la table dense avec sa colonne de cases, son en-tete triable, son menu
//     par ligne, ses filtres actifs, sa barre de selection compacte et son
//     pied de liste, clair et sombre, 1440 (table) et 390 (cartes) ;
//   * le menu d'une ligne ouvert, et la case d'en-tete a ses trois etats.
//
// Les memes noms que les captures « avant » (`menu_a1_...`, `menu_r2_...`,
// `menu_r3_...`, `menu_r6_...`) : les deux dossiers se comparent fichier a
// fichier. Saute sans CAPTURE_DIR (`test/capture/LISEZ-MOI.md`). Donnees
// fictives uniquement.

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/pays_iso.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/theme/app_typography.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/barre_selection.dart';
import 'package:rewayah_academy/core/widgets/bouton_icone.dart';
import 'package:rewayah_academy/core/widgets/case_a_cocher.dart';
import 'package:rewayah_academy/core/widgets/champ_date.dart';
import 'package:rewayah_academy/core/widgets/data_collection.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/core/widgets/menu_filtre.dart';
import 'package:rewayah_academy/core/widgets/pays_enseignant.dart';
import 'package:rewayah_academy/core/widgets/pied_de_liste.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/core/widgets/puce_filtre_actif.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/admin_candidature/blocs_candidature.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

import '../fixtures/candidature/faux_candidatures_direction.dart';
import 'outil_capture.dart';

const Size _telephone = Size(390, 844);
const Size _bureau = Size(1440, 900);
const EdgeInsets _zoneSure = EdgeInsets.only(top: 47, bottom: 34);

// ---------------------------------------------------------------------------
// Le menu, sur une page isolee.
// ---------------------------------------------------------------------------

const Key _cleFiltre = ValueKey<String>('t-filtre');
const Key _clePoints = ValueKey<String>('t-points');

class _PageMenu extends StatelessWidget {
  const _PageMenu({this.survolForce = false});

  /// Pose l'etat de survol sur le declencheur : `flutter test` ne sait pas
  /// survoler (le survol vient d'une vraie souris), `PressionForcee` le
  /// montre comme le fait la galerie.
  final bool survolForce;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final List<EntreeAction> actions = <EntreeAction>[
      EntreeAction(
        libelle: 'Ouvrir le dossier',
        icone: AppIcons.dossiers,
        onChoix: () {},
      ),
      EntreeAction(
        libelle: 'Planifier un entretien',
        icone: AppIcons.horloge,
        onChoix: () {},
      ),
      EntreeAction(
        libelle: 'Admettre en Salle de vérification et d’entretien',
        icone: AppIcons.verrou,
        onChoix: () {},
      ),
      EntreeAction(
        libelle: 'Refuser la candidature',
        destructif: true,
        icone: AppIcons.interdit,
        onChoix: () {},
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('Page de test (liste)', style: textes.headlineSmall),
              Ecart.vLg,
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: MenuFiltre<String>(
                  key: _cleFiltre,
                  libelle: 'État',
                  valeur: null,
                  entrees: const <EntreeFiltre<String>>[
                    EntreeFiltre<String>(valeur: null, libelle: 'Tous'),
                    EntreeFiltre<String>(
                      valeur: 'examen',
                      libelle: 'En examen',
                      compteur: 4,
                    ),
                    EntreeFiltre<String>(
                      valeur: 'inv',
                      libelle: 'Entretien à planifier',
                      compteur: 1,
                    ),
                  ],
                  onChoix: (String? _) {},
                ),
              ),
              Ecart.vLg,
              AppCard(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Amina Diallo  CAND-0000A1',
                        style: palette.inkStrong.applyTo(
                          textes.titleMedium ?? const TextStyle(),
                        ),
                      ),
                    ),
                    PressionForcee(
                      etat: EtatPression(survole: survolForce),
                      child: MenuActions(
                        key: _clePoints,
                        points: true,
                        objet: 'Amina Diallo',
                        actions: actions,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// La table complete.
// ---------------------------------------------------------------------------

class _Cand {
  const _Cand(
    this.id,
    this.nom,
    this.reference,
    this.pays,
    this.salle,
    this.etat,
    this.ton,
    this.versement,
    this.date, {
    this.alerte,
  });

  final String id;
  final String nom;
  final String reference;
  final String? pays;
  final String salle;
  final String etat;
  final TonEtat ton;
  final String versement;
  final String date;
  final String? alerte;
}

const List<_Cand> _cands = <_Cand>[
  _Cand(
    'a1',
    'Amina Diallo',
    'CAND-0000A1',
    'SN',
    "Salle d'examen",
    'En examen',
    TonEtat.accent,
    'Confirmé',
    '22 oct. 2026',
    alerte: 'Courriel à obtenir',
  ),
  _Cand(
    'b2',
    'Bilal Haddad',
    'CAND-0000B2',
    'FR',
    'Salle de vérification',
    'Entretien à planifier',
    TonEtat.avertissement,
    'À vérifier',
    '21 oct. 2026',
  ),
  _Cand(
    'c3',
    'Mariam Camara',
    'CAND-0000C3',
    'GN',
    "Salle d'examen",
    'En examen',
    TonEtat.accent,
    'Confirmé',
    '20 oct. 2026',
  ),
  _Cand(
    'd4',
    'Youssef Bah',
    'CAND-0000D4',
    'CI',
    'Salle de vérification',
    'Entretien à planifier',
    TonEtat.avertissement,
    'À vérifier',
    '19 oct. 2026',
  ),
  _Cand(
    'e5',
    'Fatoumata Barry',
    'CAND-0000E5',
    'ML',
    "Salle d'examen",
    'En examen',
    TonEtat.accent,
    'Confirmé',
    '18 oct. 2026',
  ),
  _Cand(
    'f6',
    'Ibrahim Sylla',
    'CAND-0000F6',
    'US',
    'Salle de vérification',
    'Entretien à planifier',
    TonEtat.avertissement,
    'À vérifier',
    '17 oct. 2026',
  ),
  _Cand(
    'g7',
    'Khadija Sow',
    'CAND-0000G7',
    'CA',
    "Salle d'examen",
    'En examen',
    TonEtat.accent,
    'Confirmé',
    '16 oct. 2026',
  ),
  _Cand(
    'h8',
    'Moussa Diallo',
    'CAND-0000H8',
    'MA',
    'Informations manquantes',
    'Informations manquantes',
    TonEtat.alerte,
    'Aucun moyen déclaré',
    '15 oct. 2026',
    alerte: 'Indicatif à confirmer',
  ),
  _Cand(
    'i9',
    'Sara Baldé',
    'CAND-0000I9',
    'GN',
    "Salle d'examen",
    'En examen',
    TonEtat.accent,
    'Confirmé',
    '14 oct. 2026',
  ),
  _Cand(
    'j10',
    'Amadou Bah',
    'CAND-0000J10',
    'SN',
    'Salle de vérification',
    'Entretien à planifier',
    TonEtat.avertissement,
    'À vérifier',
    '13 oct. 2026',
  ),
  _Cand(
    'k11',
    'Lina Touré',
    'CAND-0000K11',
    'MA',
    "Salle d'examen",
    'En examen',
    TonEtat.accent,
    'Confirmé',
    '12 oct. 2026',
  ),
  _Cand(
    'l12',
    'Omar Kane',
    'CAND-0000L12',
    'KZ',
    "Salle d'examen",
    'En examen',
    TonEtat.accent,
    'Confirmé',
    '11 oct. 2026',
  ),
  _Cand(
    'm13',
    'Hawa Keita',
    'CAND-0000M13',
    'DZ',
    'Salle de vérification',
    'Entretien à planifier',
    TonEtat.avertissement,
    'À vérifier',
    '10 oct. 2026',
  ),
  _Cand(
    'n14',
    'Idriss Ndiaye',
    'CAND-0000N14',
    'SA',
    "Salle d'examen",
    'En examen',
    TonEtat.accent,
    'Confirmé',
    '9 oct. 2026',
  ),
];

/// La page de demonstration du socle : ce que Candidatures assemblera au lot 2,
/// ici avec des donnees locales.
class _PageTable extends StatefulWidget {
  const _PageTable({this.coches = const <String>{'b2', 'd4'}});

  final Set<String> coches;

  @override
  State<_PageTable> createState() => _EtatPageTable();
}

class _EtatPageTable extends State<_PageTable> {
  late final Set<String> _coches = <String>{...widget.coches};
  bool _croissant = false;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final bool bureau = DataCollection.enTableau(context);
    final Widget contenu = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: bureau ? MainAxisSize.max : MainAxisSize.min,
      children: <Widget>[
        Text('Candidatures', style: textes.headlineMedium),
        Ecart.vMd,
        FiltresActifs(
          filtres: <FiltreActif>[
            FiltreActif(libelle: 'État : En examen', onRetirer: () {}),
            FiltreActif(libelle: 'Pays : Guinée', onRetirer: () {}),
          ],
          onToutEffacer: () {},
        ),
        Ecart.vSm,
        if (_coches.isNotEmpty) ...<Widget>[
          BarreSelection.compacte(
            titre: '${_coches.length} sélectionnées',
            onRelacher: () => setState(_coches.clear),
            operations: <Widget>[
              ActionPrincipale(
                libelle: 'Mettre en pause',
                niveau: NiveauAction.secondaire,
                compacte: true,
                pleineLargeur: false,
                onPress: () {},
              ),
              ActionPrincipale(
                libelle: 'Refuser',
                niveau: NiveauAction.destructive,
                compacte: true,
                pleineLargeur: false,
                onPress: () {},
              ),
            ],
          ),
          Ecart.vSm,
        ],
        Text(
          '614 candidatures',
          style: palette.inkStrong.applyTo(
            textes.titleSmall ?? const TextStyle(),
          ),
        ),
        Ecart.vSm,
        PlaceCollection(child: _collection(palette, textes, bureau)),
      ],
    );
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(bureau ? AppSpacing.xxxl : AppSpacing.lg),
          child: bureau ? contenu : SingleChildScrollView(child: contenu),
        ),
      ),
    );
  }

  Widget _collection(AppPalette palette, TextTheme textes, bool bureau) {
    final TextStyle corps = palette.inkStrong.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    return DataCollection<_Cand>(
      lignes: _cands,
      cle: (_Cand c) => ValueKey<String>('cand-${c.id}'),
      defileAvecLaPage: !bureau,
      onSelectionner: (_Cand _) {},
      selection: SelectionCollection<_Cand>(
        estCochee: (_Cand c) => _coches.contains(c.id),
        onBasculer: (_Cand c) => setState(() {
          if (!_coches.remove(c.id)) _coches.add(c.id);
        }),
        onBasculerPage: (bool cocher) => setState(() {
          if (cocher) {
            _coches.addAll(_cands.map((_Cand c) => c.id));
          } else {
            _coches.clear();
          }
        }),
        libelleLigne: (_Cand c) => c.nom,
      ),
      actionsLigne: (BuildContext _, _Cand c) => MenuActions(
        points: true,
        objet: c.nom,
        actions: <EntreeAction>[
          EntreeAction(
            libelle: 'Ouvrir le dossier',
            icone: AppIcons.dossiers,
            onChoix: () {},
          ),
          EntreeAction(
            libelle: 'Planifier un entretien',
            icone: AppIcons.horloge,
            onChoix: () {},
          ),
          EntreeAction(
            libelle: 'Mettre en pause',
            icone: AppIcons.pause,
            onChoix: () {},
          ),
          EntreeAction(
            libelle: 'Refuser la candidature',
            destructif: true,
            icone: AppIcons.interdit,
            onChoix: () {},
          ),
        ],
      ),
      colonnes: <ColonneDonnees<_Cand>>[
        ColonneDonnees<_Cand>(
          titre: 'Nom',
          texte: (_Cand c) => c.nom,
          role: RoleColonne.identifiante,
          flex: 4,
          tri: TriColonne(onTrier: () {}),
          rendu: (BuildContext _, _Cand c) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                c.nom,
                style: palette.inkStrong.applyTo(
                  textes.labelLarge ?? const TextStyle(),
                ),
              ),
              Text(
                c.reference,
                style: palette.inkMuted.applyTo(
                  textes.bodySmall ?? const TextStyle(),
                ),
              ),
              if (c.alerte != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: StatusPill(
                    libelle: c.alerte!,
                    ton: TonEtat.avertissement,
                  ),
                ),
            ],
          ),
        ),
        ColonneDonnees<_Cand>(
          titre: 'Salle',
          texte: (_Cand c) => c.salle,
          flex: 3,
          tri: TriColonne(onTrier: () {}),
          rendu: (BuildContext _, _Cand c) => Text(c.salle, style: corps),
        ),
        ColonneDonnees<_Cand>(
          titre: 'État',
          texte: (_Cand c) => c.etat,
          flex: 3,
          // Aligne au debut : la cellule donne sa largeur entiere, la pastille
          // garde la sienne.
          rendu: (BuildContext _, _Cand c) => Align(
            alignment: AlignmentDirectional.centerStart,
            child: StatusPill(libelle: c.etat, ton: c.ton),
          ),
        ),
        ColonneDonnees<_Cand>(
          titre: 'Pays',
          texte: (_Cand c) => nomDuPays(c.pays ?? ''),
          flex: 3,
          tri: TriColonne(onTrier: () {}),
          rendu: (BuildContext _, _Cand c) =>
              PaysEnseignant.parCode(codeIso: c.pays, style: corps),
        ),
        ColonneDonnees<_Cand>(
          titre: 'Versement',
          texte: (_Cand c) => c.versement,
          flex: 3,
          rendu: (BuildContext _, _Cand c) => Text(c.versement, style: corps),
        ),
        ColonneDonnees<_Cand>(
          titre: 'Activité',
          texte: (_Cand c) => c.date,
          flex: 2,
          tabulaire: true,
          rendu: (BuildContext _, _Cand c) =>
              Text(c.date, style: AppTypography.tabulaire(corps)),
          tri: TriColonne(
            sens: _croissant ? SensTri.croissant : SensTri.decroissant,
            onTrier: () => setState(() => _croissant = !_croissant),
          ),
        ),
      ],
      piedCollant: PiedDeListe(
        debut: 1,
        fin: 25,
        total: 614,
        onSuivant: () {},
        taillePage: 25,
        taillesProposees: const <int>[25, 50, 100],
        onTaillePage: (int _) {},
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Outils.
// ---------------------------------------------------------------------------

Future<void> _monterRouteur(
  WidgetTester tester,
  PortCandidaturesDirection port, {
  required String route,
  Object? extra,
  ThemeMode mode = ThemeMode.light,
}) async {
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: <Override>[
        ...surchargesDemoAdmin(environnement: 'staging'),
        portCandidaturesDirectionProvider.overrideWithValue(port),
        horlogeFormulairesProvider.overrideWithValue(
          () => DateTime.utc(2026, 10, 22, 12),
        ),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              routeur = ref.read(routeurProvider);
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                darkTheme: AppTheme.pour(
                  InterfaceMode.standard,
                  Brightness.dark,
                ),
                themeMode: mode,
                locale: TranslationProvider.of(context).flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                routerConfig: routeur,
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  if (extra == null) {
    routeur.go(route);
  } else {
    unawaited(routeur.push<void>(route, extra: extra));
  }
  await stabiliser(tester);
  await stabiliser(tester);
}

Future<void> _photo(WidgetTester tester, String nom) async {
  debugPrint('PNG ${await capturer(tester, nom)}');
}

/// Laisse le decodage des images (les drapeaux) se terminer : il tourne hors
/// du temps simule des tests.
Future<void> _chargerImages(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final Element e in find.byType(Image).evaluate()) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  await tester.pump();
}

Finder _popup() => find.byWidgetPredicate(
  (Widget w) => w.runtimeType.toString().startsWith('_PopupMenu<'),
);

void main() {
  setUpAll(chargerPolicesDuDepot);
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('LISTES-1 socle : captures', skip: sautSansCapture, () {
    testWidgets('garde-fou : les vraies polices sont actives', (
      WidgetTester tester,
    ) async {
      expect(
        largeurSonde('PlusJakartaSans'),
        lessThan(largeurSonde('FamilleInexistante') * 0.6),
      );
    });

    for (final (String nom, Size taille, double densite)
        in <(String, Size, double)>[
          ('1440', _bureau, 1),
          ('390', _telephone, 2),
        ]) {
      final EdgeInsets zone = taille == _telephone
          ? _zoneSure
          : EdgeInsets.zero;
      for (final ThemeMode mode in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        final String suf = '${nom}_${mode.name}';

        testWidgets('menu isole : ferme, survole, ouvert $suf', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, densite, zoneSure: zone);
          await tester.pumpWidget(
            hoteCapture(const _PageMenu(survolForce: true), themeMode: mode),
          );
          await stabiliser(tester);
          // Survol (force : `flutter test` n'a pas de vraie souris) : un disque
          // doux, et AUCUNE infobulle, meme apres un long moment.
          for (int i = 0; i < 8; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          await _photo(tester, 'menu_c1_survol_tooltip_$suf');
          await tester.pumpWidget(
            hoteCapture(const _PageMenu(), themeMode: mode),
          );
          await stabiliser(tester);
          // Le clic : le menu s'ouvre, nette, sans infobulle ni voile.
          await tester.tap(find.byKey(_clePoints));
          await tester.pumpAndSettle();
          expect(_popup(), findsOneWidget);
          await _photo(tester, 'menu_a1_actions_ouvert_tap_$suf');
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          expect(_popup(), findsNothing);
          // Au clavier : le focus du declencheur se voit.
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          await _photo(tester, 'menu_e0_focus_declencheur_$suf');
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pump();
          await _photo(tester, 'menu_e1_focus_entree_$suf');
        });

        testWidgets('menu du filtre ouvert $suf', (WidgetTester tester) async {
          fixerVueCapture(tester, taille, densite, zoneSure: zone);
          await tester.pumpWidget(
            hoteCapture(const _PageMenu(), themeMode: mode),
          );
          await stabiliser(tester);
          await tester.tap(find.byKey(_cleFiltre));
          await tester.pumpAndSettle();
          await _photo(tester, 'menu_b_filtre_ouvert_$suf');
        });

        testWidgets('fiche reelle : survol, clic, ouvert $suf', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, 1, zoneSure: zone);
          await _monterRouteur(
            tester,
            FauxCandidaturesDirection(
              capacitesRendues: capacitesGestes,
              details: <DetailCandidature>[detailTest()],
            ),
            route: Routes.adminPersonnesCandidaturePour('CAND-0000C1'),
            extra: 'c1',
            mode: mode,
          );
          final Finder menu = find.byKey(BlocProchaineAction.cleMenu);
          expect(menu, findsOneWidget);
          await Scrollable.ensureVisible(tester.element(menu), alignment: 0.3);
          await stabiliser(tester);
          final Offset c = tester.getCenter(menu);
          final TestGesture g = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await g.addPointer(location: Offset.zero);
          addTearDown(g.removePointer);
          await g.moveTo(c);
          await tester.pump(const Duration(milliseconds: 100));
          for (int i = 0; i < 6; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          await _photo(tester, 'menu_r2_fiche_survol_$suf');
          await g.down(c);
          await tester.pump(const Duration(milliseconds: 40));
          await g.up();
          await tester.pump(const Duration(milliseconds: 40));
          await _photo(tester, 'menu_r3_fiche_clic_t80_$suf');
          await tester.pump(const Duration(milliseconds: 60));
          await _photo(tester, 'menu_r4_fiche_clic_t140_$suf');
          await tester.pumpAndSettle();
          expect(_popup(), findsOneWidget);
          await _photo(tester, 'menu_r6_fiche_menu_ouvert_$suf');
        });

        testWidgets('table dense : cases, tri, menu, pied $suf', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, taille, densite, zoneSure: zone);
          await tester.pumpWidget(
            hoteCapture(const _PageTable(), themeMode: mode),
          );
          await stabiliser(tester);
          await _chargerImages(tester);
          await _photo(tester, 'table_dense_$suf');
          if (taille == _bureau) {
            // Le menu de la deuxieme ligne, ouvert.
            await tester.tap(find.byType(MenuActions).at(1));
            await tester.pumpAndSettle();
            await _photo(tester, 'table_menu_ligne_ouvert_$suf');
          }
        });
      }
    }

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('table dense en arabe (de droite a gauche) ${mode.name}', (
        WidgetTester tester,
      ) async {
        await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
        fixerVueCapture(tester, _bureau, 1);
        await tester.pumpWidget(
          hoteCapture(const _PageTable(), themeMode: mode),
        );
        await stabiliser(tester);
        await _chargerImages(tester);
        await _photo(tester, 'table_dense_ar_1440_${mode.name}');
        await tester.tap(find.byType(MenuActions).at(1));
        await tester.pumpAndSettle();
        await _photo(tester, 'table_menu_ligne_ouvert_ar_1440_${mode.name}');
      });
    }

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('infobulle opaque et lente ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, _bureau, 1);
        await tester.pumpWidget(
          hoteCapture(
            Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxxl),
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: BoutonIcone(
                    icone: AppIcons.fermer,
                    libelle: 'Fermer ce panneau',
                    onPress: () {},
                  ),
                ),
              ),
            ),
            themeMode: mode,
          ),
        );
        await stabiliser(tester);
        final TestGesture souris = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await souris.addPointer(location: Offset.zero);
        addTearDown(souris.removePointer);
        await souris.moveTo(tester.getCenter(find.byType(BoutonIcone)));
        // Avant son delai : rien. Un clic court ne montre jamais l'infobulle.
        await tester.pump(const Duration(milliseconds: 120));
        await _photo(tester, 'infobulle_avant_delai_1440_${mode.name}');
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 200));
        await _photo(tester, 'infobulle_apres_delai_1440_${mode.name}');
      });
    }

    testWidgets('table dense : aucune ligne cochee, puis toute la page', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, _bureau, 1);
      await tester.pumpWidget(
        hoteCapture(
          const _PageTable(coches: <String>{}),
          themeMode: ThemeMode.light,
        ),
      );
      await stabiliser(tester);
      await _chargerImages(tester);
      await _photo(tester, 'table_dense_aucune_1440_light');
      await tester.tap(find.byType(CaseACocher).first);
      await tester.pumpAndSettle();
      await _photo(tester, 'table_dense_page_cochee_1440_light');
    });
  });
}
