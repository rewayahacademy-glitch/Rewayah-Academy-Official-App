// TB-12 (recette, K-07) : les preuves qui n'existaient que sur
// DemoSallePage montee seule, rejouees depuis la VRAIE coquille.
//
// Chaque test monte l'application sur son vrai routeur (`routeurProvider`),
// ouvre /demo/salle, tape le lien de la situation (lien-<role>-tb-<sit>),
// puis les vrais boutons, comme une personne. Couverts : R-05 (support non
// charge), UX-18 (Tableau puis Avec notes), UX-13 (mesures au bureau 1440),
// UX-15 (Commandes en focus puis Reduire), R-02 (un clic par affichage, le
// cercle garde), R-18 (support arabe en interface arabe, annote) et UX-02
// (la souris revele la barre sans monter les Commandes).
//
// Limite : la demonstration n'a ni serveur ni second appareil. Ce qui
// exige la diffusion (R-18 vu par un eleve distant) reste « non
// verifiable sans BR-1 » ; la preuve ici porte sur le depot d'annotations
// de la salle (AnnotationsMemoire) et la vue rendue.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/accessibilite/commandes_masquables.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/tc_outils/annotation_layer.dart';
import 'package:rewayah_academy/core/tc_outils/port_annotations.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/controle_segmente.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/bibliotheque_seance.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_eleves.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_seance.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/surface_page_fixe.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/salle_seance/zone_support.dart';
import 'package:rewayah_academy/features/tc_catalogue/surface_bibliotheque.dart';
import 'package:rewayah_academy/features/tc_dock/couche_annotation.dart';

import '../../router/support_routeur.dart';
import '../../support/harnais.dart' show FausseSourceSession;

const Size _telephone = Size(390, 844);
const Size _bureau = Size(1440, 900);

final Finder _declencheur = find.byKey(DeclencheurCommandes.cle);
final Finder _commandes = find.byKey(CommandesPedagogiques.cle);
final Finder _bibliotheque = find.byKey(CommandesPedagogiques.cleBibliotheque);
final Finder _affichages = find.byKey(CommandesPedagogiques.cleAffichages);
final Finder _onglets = find.byKey(CommandesPedagogiques.cleOnglets);
final Finder _focus = find.byKey(CommandesPedagogiques.cleFocus);
final Finder _reduire = find.byKey(PanneauSeance.cleReduire);
final Finder _reduireDock = find.byKey(
  const ValueKey<String>('bouton-agrandir'),
);
final Finder _participants = find.byType(PanneauEleves);
final Finder _page = find.byKey(SurfacePageFixe.clePage);
final Finder _catalogue = find.byType(SurfaceBibliotheque);
final Finder _presenter = find.byKey(BibliothequeSeance.clePresenter);
final Finder _revenir = find.byKey(BibliothequeSeance.cleRevenir);
final Finder _echec = find.byKey(BibliothequeSeance.cleEchec);
final Finder _suivant = find.byKey(const ValueKey<String>('nav-suivant'));
final Finder _precedent = find.byKey(const ValueKey<String>('nav-precedent'));
final Finder _pagination = find.byKey(
  const ValueKey<String>('pagination-support'),
);
final Finder _ecrire = find.byKey(const ValueKey<String>('outil-ecrire'));

/// La croix d'un panneau sans « Reduire » (la Bibliotheque).
final Finder _fermerPanneau = find.byWidgetPredicate(
  (Widget w) =>
      w is Pressable && w.libelleSemantique == t.salle.seance.fermerPanneau,
);

const String _cercle = 'demo-trait-cercle';
const String _titreInitial = 'Les bonnes manières';
const String _indisponible = "Cahier d'écriture";

/// K-07 : la salle de [situation], ouverte depuis la liste de /demo/salle.
Future<GoRouter> _ouvrir(
  WidgetTester tester,
  RoleSeance role,
  SituationTb situation, {
  Size taille = _bureau,
}) async {
  final GoRouter routeur = await monterRouteur(
    tester,
    Routes.demoSalle,
    taille: taille,
  );
  await _taperLien(tester, routeur, role, situation);
  return routeur;
}

Future<void> _taperLien(
  WidgetTester tester,
  GoRouter routeur,
  RoleSeance role,
  SituationTb situation,
) async {
  final Finder lien = find.byKey(
    ValueKey<String>('lien-${role.name}-tb-${situation.name}'),
  );
  await tester.ensureVisible(lien);
  await tester.pump();
  await tester.tap(lien);
  await stabiliser(tester);
  expect(lieu(routeur), adresseDemoSalleTb(role, situation));
  expect(find.byType(SalleSeance), findsOneWidget);
  expect(tester.takeException(), isNull);
}

/// La coquille comme `lib/app.dart` la monte : vrai routeur, locale et
/// delegues de l'application (le sens RTL vient de la locale arabe, jamais
/// d'un `Directionality` pose par le test).
Future<GoRouter> _monterAvecLocale(WidgetTester tester, Size taille) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
        ),
        portClassesFoyerProvider.overrideWithValue(
          const ClassesFoyerIndisponible(),
        ),
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              routerConfig: routeur,
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(Routes.demoSalle);
  await stabiliser(tester);
  return routeur;
}

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

/// Un seul toucher, puis deux cadres : ce qu'une personne voit aussitot.
Future<void> _unClic(WidgetTester tester, Finder cible) async {
  await tester.tap(cible);
  await tester.pump();
  await tester.pump();
}

/// Les identifiants des traits passes au calque de la surface.
List<String> _traitsPeints(WidgetTester tester) => <String>[
  for (final TraitVectoriel trait
      in tester
          .widget<CoucheAnnotation>(find.byKey(SurfacePageFixe.cleCouche))
          .traits)
    trait.id,
];

/// La vue lue par la surface (page presentee, affichage, notes).
VueSeance _vue(WidgetTester tester) =>
    tester.widget<SurfacePageFixe>(find.byType(SurfacePageFixe)).vue;

/// L'affichage selectionne dans le choix groupe des Commandes.
AffichagePartage _affichageChoisi(WidgetTester tester) => tester
    .widget<ControleSegmente<AffichagePartage>>(
      find.descendant(
        of: _affichages,
        matching: find.byType(ControleSegmente<AffichagePartage>),
      ),
    )
    .valeur;

Finder _dans(Finder parent, String texte) =>
    find.descendant(of: parent, matching: find.text(texte));

Finder _pageAvecTitre(String titre) => _dans(_page, titre);

/// Le catalogue defile en slivers : descend jusqu'a la carte.
Future<Finder> _versCarte(WidgetTester tester, String titre) async {
  await tester.scrollUntilVisible(
    _dans(_catalogue, titre),
    120,
    scrollable: find
        .descendant(of: _catalogue, matching: find.byType(Scrollable))
        .first,
  );
  await tester.pumpAndSettle();
  return _dans(_catalogue, titre).first;
}

AnnotationsMemoire _depot(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(SalleSeance)))
            .read(portAnnotationsProvider)
        as AnnotationsMemoire;

Rect _zone(WidgetTester tester) => tester.getRect(find.byType(ZoneSupport));

bool _chevauche(Rect a, Rect b) =>
    a.intersect(b).width > 0.5 && a.intersect(b).height > 0.5;

/// Un geste de [a] a [b] au doigt, en huit pas.
Future<void> _glisser(WidgetTester tester, Offset a, Offset b) async {
  final TestPointer p = TestPointer(51, PointerDeviceKind.touch);
  await tester.sendEventToBinding(p.down(a));
  for (int i = 1; i <= 8; i++) {
    await tester.sendEventToBinding(p.move(Offset.lerp(a, b, i / 8)!));
    await tester.pump();
  }
  await tester.sendEventToBinding(p.up());
  await tester.pumpAndSettle();
}

Offset _surPage(WidgetTester tester, double x, double y) {
  final Rect r = tester.getRect(_page);
  return r.topLeft + Offset(x * r.width, y * r.height);
}

void main() {
  group('R-05 : un support non charge ne remplace jamais l\'ancien', () {
    for (final Size taille in <Size>[_telephone, _bureau]) {
      testWidgets('Commandes > Bibliotheque > echec, puis Page suivante '
          '(${taille.width.toInt()})', (WidgetTester tester) async {
        await _ouvrir(
          tester,
          RoleSeance.enseignant,
          SituationTb.ped03,
          taille: taille,
        );
        final SupportPageFixe avant = _vue(tester).supportPresente!;
        expect(avant.page, 1);
        expect(_pageAvecTitre(_titreInitial), findsOneWidget);
        expect(_traitsPeints(tester), <String>[_cercle]);

        await _taper(tester, _declencheur);
        await _taper(tester, _bibliotheque);
        await _taper(tester, await _versCarte(tester, _indisponible));
        await _taper(tester, _presenter);
        expect(tester.takeException(), isNull);
        // Erreur ciblee : le message nomme le fichier non ouvert, avec
        // « Reessayer » sur le meme bouton.
        expect(_echec, findsOneWidget);
        expect(find.text(t.salle.seance.bibliotheque.echec), findsOneWidget);
        expect(_dans(_presenter, t.commun.reessayer), findsOneWidget);
        // L'ancien support reste, meme page, memes notes.
        expect(_pageAvecTitre(_titreInitial), findsOneWidget);
        expect(_pageAvecTitre(_indisponible), findsNothing);
        expect(_vue(tester).supportPresente!.id, avant.id);
        expect(_vue(tester).supportPresente!.version, avant.version);
        expect(_vue(tester).supportPresente!.page, 1);
        expect(_traitsPeints(tester), <String>[_cercle]);

        // ... et reste utilisable : retour, Reduire, Commandes, Page
        // suivante.
        await _taper(tester, _revenir);
        expect(_catalogue, findsOneWidget);
        await _taper(tester, _fermerPanneau);
        expect(_catalogue, findsNothing);
        expect(_commandes, findsNothing);
        await _taper(tester, _declencheur);
        await _taper(tester, _suivant);
        expect(tester.takeException(), isNull);
        expect(_vue(tester).supportPresente!.id, avant.id);
        expect(_vue(tester).supportPresente!.page, 2);
        expect(
          _dans(
            _pagination,
            t.salle.seance.pageSemantique(page: 2, pages: avant.total),
          ),
          findsOneWidget,
        );
        // Le cercle est ancre a la page 1 : absent de la page 2, revenu a
        // la page 1.
        expect(_traitsPeints(tester), isEmpty);
        await _taper(tester, _precedent);
        expect(_vue(tester).supportPresente!.page, 1);
        expect(_traitsPeints(tester), <String>[_cercle]);
      });
    }
  });

  group('R-02 : un clic par affichage, aucune annotation supprimee', () {
    for (final Size taille in <Size>[_telephone, _bureau]) {
      testWidgets('Tableau, Support, Avec notes (${taille.width.toInt()})', (
        WidgetTester tester,
      ) async {
        await _ouvrir(
          tester,
          RoleSeance.enseignant,
          SituationTb.ped03,
          taille: taille,
        );
        expect(_traitsPeints(tester), <String>[_cercle]);
        await _taper(tester, _declencheur);
        expect(_affichageChoisi(tester), AffichagePartage.avecNotes);
        for (final (String libelle, AffichagePartage attendu, bool page)
            in <(String, AffichagePartage, bool)>[
              (
                t.salle.seance.commandes.affichageTableau,
                AffichagePartage.tableau,
                false,
              ),
              (
                t.salle.seance.commandes.affichageSupport,
                AffichagePartage.support,
                true,
              ),
              (
                t.salle.seance.commandes.affichageAvecNotes,
                AffichagePartage.avecNotes,
                true,
              ),
            ]) {
          final Finder choix = _dans(_affichages, libelle);
          await tester.ensureVisible(choix);
          await tester.pumpAndSettle();
          // UN toucher, deux cadres : l'affichage a deja change.
          await _unClic(tester, choix);
          expect(_affichageChoisi(tester), attendu, reason: libelle);
          expect(_vue(tester).affichage, attendu, reason: libelle);
          expect(_page, page ? findsOneWidget : findsNothing, reason: libelle);
          // Le cercle reste au calque (cache en Support, jamais demonte).
          expect(_traitsPeints(tester), <String>[
            _cercle,
          ], reason: 'apres $libelle');
          expect(find.byKey(SurfacePageFixe.cleCalque), findsOneWidget);
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('UX-18 : Tableau, puis Avec notes : meme page, memes traits, '
      'un clic', (WidgetTester tester) async {
    await _ouvrir(tester, RoleSeance.enseignant, SituationTb.ped03);
    await _taper(tester, _declencheur);
    // Une autre page que la premiere : la page retenue est verifiee, pas
    // seulement la page par defaut.
    await _taper(tester, _suivant);
    await _taper(tester, _precedent);
    final SupportPageFixe retenue = _vue(tester).supportPresente!;
    expect(_traitsPeints(tester), <String>[_cercle]);
    await _taper(
      tester,
      _dans(_affichages, t.salle.seance.commandes.affichageTableau),
    );
    expect(_page, findsNothing);
    expect(_traitsPeints(tester), <String>[_cercle]);
    // Fermer puis rouvrir les Commandes.
    await _taper(tester, _reduire);
    expect(_commandes, findsNothing);
    await _taper(tester, _declencheur);
    final Finder avecNotes = _dans(
      _affichages,
      t.salle.seance.commandes.affichageAvecNotes,
    );
    await tester.ensureVisible(avecNotes);
    await tester.pumpAndSettle();
    await _unClic(tester, avecNotes);
    expect(_page, findsOneWidget);
    expect(_vue(tester).supportPresente!.id, retenue.id);
    expect(_vue(tester).supportPresente!.page, retenue.page);
    expect(_vue(tester).supportPresente!.version, retenue.version);
    expect(_traitsPeints(tester), <String>[_cercle]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('UX-13 : bureau 1440, Participants a gauche, surface '
      'dominante, Commandes a droite', (WidgetTester tester) async {
    await _ouvrir(tester, RoleSeance.enseignant, SituationTb.cmd01);
    expect(_participants, findsOneWidget);
    expect(_commandes, findsOneWidget);
    final Rect zone = _zone(tester);
    final Rect gauche = tester.getRect(_participants);
    final Rect droite = tester.getRect(_commandes);
    expect(gauche.right, lessThan(zone.left));
    expect(droite.left, greaterThan(zone.right));
    expect(_chevauche(gauche, zone), isFalse);
    expect(_chevauche(droite, zone), isFalse);
    expect(zone.width, greaterThan(gauche.width));
    expect(zone.width, greaterThan(droite.width));
    // Les trois tiennent dans l'ecran, sans defilement horizontal.
    final Rect ecran = Offset.zero & _bureau;
    expect(gauche.left, greaterThanOrEqualTo(ecran.left));
    expect(droite.right, lessThanOrEqualTo(ecran.right));
    // La page presentee est dans la surface.
    final Rect page = tester.getRect(_page);
    expect(zone.contains(page.topLeft), isTrue);
    expect(zone.contains(page.bottomRight - const Offset(1, 1)), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('UX-15 : Commandes en focus puis Reduire, la gauche ne revient '
      'pas', (WidgetTester tester) async {
    await _ouvrir(tester, RoleSeance.enseignant, SituationTb.cmd01);
    expect(_participants, findsOneWidget);
    await _taper(tester, _focus);
    expect(_participants, findsNothing);
    expect(_commandes, findsNothing);
    await _taper(tester, _declencheur);
    expect(_commandes, findsOneWidget);
    expect(_participants, findsNothing);
    await _taper(tester, _reduire);
    expect(_commandes, findsNothing);
    expect(_participants, findsNothing);
    // Toujours en focus : la sortie est la, la surface garde la largeur.
    expect(_reduireDock, findsOneWidget);
    expect(_zone(tester).width, greaterThan(_bureau.width - 64));
    expect(tester.takeException(), isNull);
  });

  group('UX-02 : la souris revele la barre sans monter les Commandes', () {
    for (final RoleSeance role in RoleSeance.values) {
      testWidgets(role.name, (WidgetTester tester) async {
        final GoRouter routeur = await monterRouteur(
          tester,
          Routes.demoSalle,
          taille: _bureau,
        );
        await _taperLien(tester, routeur, role, SituationTb.vis01);
        final Finder barre = find.ancestor(
          of: find.byKey(CommandesMasquables.commandesKey),
          matching: find.byType(AnimatedOpacity),
        );
        bool visible() => tester.widget<AnimatedOpacity>(barre).opacity == 1;
        final TestGesture souris = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await souris.addPointer(location: const Offset(700, 200));
        await tester.pump(CommandesMasquables.delaiParDefaut);
        await tester.pump(const Duration(milliseconds: 500));
        expect(visible(), isFalse);
        expect(find.byType(CommandesPedagogiques), findsNothing);
        await souris.moveTo(const Offset(720, 260));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(visible(), isTrue);
        // Aucun panneau pedagogique monte, aucune question de sortie.
        expect(find.byType(CommandesPedagogiques), findsNothing);
        expect(_commandes, findsNothing);
        expect(find.text(t.salle.seance.quitterQuestion), findsNothing);
        expect(lieu(routeur), adresseDemoSalleTb(role, SituationTb.vis01));
        await souris.removePointer();
      });
    }
  });

  group('R-18 : support arabe, interface arabe', () {
    setUp(() => LocaleSettings.setLocale(AppLocale.ar));
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    for (final Size taille in <Size>[_telephone, _bureau]) {
      testWidgets('presenter, tourner les pages, annoter '
          '(${taille.width.toInt()})', (WidgetTester tester) async {
        final GoRouter routeur = await _monterAvecLocale(tester, taille);
        await _taperLien(
          tester,
          routeur,
          RoleSeance.enseignant,
          SituationTb.ped03,
        );
        expect(
          Directionality.of(tester.element(find.byType(SalleSeance))),
          TextDirection.rtl,
        );
        final LibraryResource ressource = DonneesSeanceDemo.ressourcesTb
            .singleWhere(
              (LibraryResource r) => r.id == DonneesSeanceDemo.idSupportArabe,
            );
        const String titre = DonneesSeanceDemo.titreSupportArabe;

        // Commandes > Bibliotheque > le support arabe > Presenter.
        await _taper(tester, _declencheur);
        await _taper(tester, _bibliotheque);
        await _taper(tester, await _versCarte(tester, titre));
        await _taper(tester, _presenter);
        expect(tester.takeException(), isNull);
        expect(_pageAvecTitre(titre), findsOneWidget);
        final SupportPageFixe presente = _vue(tester).supportPresente!;
        expect(presente.id, ressource.id);
        expect(presente.version, ressource.currentVersionId);
        expect(presente.total, DonneesSeanceDemo.pagesSupportArabe);

        // La page est un document arabe : de droite a gauche, titre cale
        // au bord droit de la page, aucun signe coupe.
        final Finder texteTitre = _pageAvecTitre(titre);
        expect(
          Directionality.of(tester.element(texteTitre)),
          TextDirection.rtl,
        );
        final Rect laPage = tester.getRect(_page);
        final Rect leTitre = tester.getRect(texteTitre);
        expect(
          laPage.right - leTitre.right,
          lessThanOrEqualTo(leTitre.left - laPage.left),
          reason: 'titre $leTitre dans la page $laPage',
        );
        expect(laPage.contains(leTitre.topLeft), isTrue);
        expect(laPage.contains(leTitre.bottomRight), isTrue);
        final RenderParagraph rendu = tester.renderObject(texteTitre);
        expect(rendu.didExceedMaxLines, isFalse);
        expect(rendu.text.toPlainText(), titre);

        // Les pages, en RTL : « precedente » a droite, glyphe miroir.
        await _taper(tester, _declencheur);
        expect(_precedent, findsNothing);
        await _taper(tester, _suivant);
        expect(_vue(tester).supportPresente!.page, 2);
        expect(
          _dans(
            _pagination,
            t.salle.seance.pageSemantique(
              page: 2,
              pages: DonneesSeanceDemo.pagesSupportArabe,
            ),
          ),
          findsOneWidget,
        );
        expect(
          tester.getCenter(_precedent).dx,
          greaterThan(tester.getCenter(_suivant).dx),
        );
        bool retourne(Finder f) =>
            tester
                .widget<Transform>(
                  find
                      .descendant(of: f, matching: find.byType(Transform))
                      .first,
                )
                .transform
                .storage[0] <
            0;
        expect(retourne(_suivant), isTrue);
        expect(retourne(_precedent), isFalse);

        // Annoter : Outils > Ecrire, un trait sur la page 2.
        await _taper(
          tester,
          _dans(_onglets, t.salle.seance.commandes.ongletOutils),
        );
        await _taper(tester, _ecrire);
        await _taper(tester, _reduire);
        expect(
          _depot(tester).couches.expand((AnnotationLayer c) => c.traits),
          isEmpty,
        );
        await _glisser(
          tester,
          _surPage(tester, 0.7, 0.4),
          _surPage(tester, 0.3, 0.45),
        );
        expect(tester.takeException(), isNull);
        final List<AnnotationLayer> couches = _depot(tester).couches.toList();
        final List<TraitVectoriel> traits = <TraitVectoriel>[
          for (final AnnotationLayer c in couches) ...c.traits,
        ];
        expect(traits, hasLength(1));
        final TraitVectoriel trait = traits.single;
        expect(trait.ancrage.resourceId, ressource.id);
        expect(trait.ancrage.resourceVersionId, presente.version);
        expect(trait.ancrage.page, 2);
        // La couche reference la ressource ; elle ne porte aucune autre
        // version que celle presentee (q06).
        for (final AnnotationLayer c in couches) {
          expect(c.resourceId, ressource.id);
          expect(c.resourceVersionId, anyOf(isNull, presente.version));
        }
        expect(_traitsPeints(tester), contains(trait.id));
        // La source est intacte : meme version presentee, meme version au
        // catalogue de la classe, aucune copie du support.
        expect(_vue(tester).supportPresente!.version, presente.version);
        expect(_vue(tester).supportPresente!.id, ressource.id);
        expect(
          DonneesSeanceDemo.ressourcesTb
              .singleWhere((LibraryResource r) => r.id == ressource.id)
              .currentVersionId,
          ressource.currentVersionId,
        );
        // Le titre se lit toujours entier, sans debordement.
        expect(
          tester.renderObject<RenderParagraph>(texteTitre).didExceedMaxLines,
          isFalse,
        );
      });
    }
  });
}
