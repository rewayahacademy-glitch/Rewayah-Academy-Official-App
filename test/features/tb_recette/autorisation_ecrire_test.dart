// TB-10 (plan V2 §5, §12 « Autorisation de dessin » et « Droit retire »,
// §19.3, §20 ; UX-20 ; MA-CMD-1) : l'eleve, le Mode Accessibilite et
// l'autorisation d'ecrire.
//
// Les parcours partent de la VRAIE coquille (`/demo/salle`, K-07) et passent
// par les vrais boutons : Commandes, Ecrire, Reduire, « Autoriser a ecrire ».
// Les mesures portent sur le rendu : traits pris par le depot, widgets
// montes, rectangles, outil retenu de l'appareil.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart'
    show TitreEnseignant;
import 'package:rewayah_academy/core/tc_outils/annotation_layer.dart';
import 'package:rewayah_academy/core/tc_outils/etat_outils.dart';
import 'package:rewayah_academy/core/tc_outils/port_annotations.dart';
import 'package:rewayah_academy/core/tc_outils/port_dock_hote.dart'
    show OutilDock;
import 'package:rewayah_academy/core/widgets/bouton_icone.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/barre_support.dart'
    show PaginationSupport, ZoomLocal;
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/dock_seance.dart';
import 'package:rewayah_academy/features/salle_seance/ecriture_seance.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_eleves.dart'
    show libelleStatutEleve;
import 'package:rewayah_academy/features/salle_seance/panneau_seance.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/surface_page_fixe.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/salle_seance/zone_support.dart'
    show ZoneSupport;
import 'package:rewayah_academy/features/tc_dock/barre_stylet.dart';
import 'package:rewayah_academy/features/tc_dock/couche_annotation.dart';

import '../../capture/outil_capture.dart'
    show chargerPolicesDuDepot, fixerVueCapture, hoteCapture;
import '../../router/support_routeur.dart';
import '../../support/aucun_mot_coupe.dart';

const Size _telephone = Size(390, 844);
const Size _bureau = Size(1440, 900);

final Finder _page = find.byKey(SurfacePageFixe.clePage);
final Finder _declencheur = find.byKey(DeclencheurCommandes.cle);
final Finder _palette = find.byKey(PaletteEcriture.cle);
final Finder _ecrire = find.byKey(const ValueKey<String>('outil-ecrire'));
final Finder _sectionEcrire = find.byKey(
  CommandesPedagogiques.cleEcritureEleve,
);
final Finder _avis = find.byKey(CommandesEleve.cleAvis);

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pump();
  await tester.tap(cible);
  await stabiliser(tester);
}

/// K-07 : la salle de la situation, ouverte depuis la liste de /demo/salle.
Future<void> _ouvrir(
  WidgetTester tester,
  RoleSeance role,
  SituationTb situation, {
  Size taille = _telephone,
}) async {
  await monterRouteur(tester, Routes.demoSalle, taille: taille);
  final Finder lien = find.byKey(
    ValueKey<String>('lien-${role.name}-tb-${situation.name}'),
  );
  await tester.ensureVisible(lien);
  await tester.pump();
  await tester.tap(lien);
  await stabiliser(tester);
  expect(tester.takeException(), isNull);
}

ProviderContainer _conteneur(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(SalleSeance)));

List<TraitVectoriel> _traits(WidgetTester tester) => <TraitVectoriel>[
  for (final AnnotationLayer c in (_conteneur(
    tester,
  ).read(portAnnotationsProvider) as AnnotationsMemoire).couches)
    ...c.traits,
];

OutilDock? _outil(WidgetTester tester) =>
    _conteneur(tester).read(etatOutilsProvider).outilActif;

Offset _surPage(WidgetTester tester, double x, double y) {
  final Rect r = tester.getRect(_page);
  return r.topLeft + Offset(x * r.width, y * r.height);
}

/// Un doigt glisse sur la page, de gauche a droite.
Future<void> _glisser(WidgetTester tester, int id) async {
  final TestPointer doigt = TestPointer(id);
  final Offset a = _surPage(tester, 0.2, 0.3);
  final Offset b = _surPage(tester, 0.8, 0.35);
  await tester.sendEventToBinding(doigt.down(a));
  for (int i = 1; i <= 6; i++) {
    await tester.sendEventToBinding(doigt.move(Offset.lerp(a, b, i / 6)!));
    await tester.pump();
  }
  await tester.sendEventToBinding(doigt.up());
  await stabiliser(tester);
}

/// Rien de l'enseignant dans les Commandes de l'eleve (plan V2 §5, TB14).
void _rienDeLEnseignant() {
  expect(find.byKey(CommandesPedagogiques.cleOnglets), findsNothing);
  expect(find.byKey(CommandesPedagogiques.cleBibliotheque), findsNothing);
  expect(find.byKey(CommandesPedagogiques.cleAffichages), findsNothing);
  expect(find.byKey(CommandesPedagogiques.cleMenu), findsNothing);
  expect(find.byType(PaginationSupport), findsNothing);
  expect(find.byKey(const ValueKey<String>('outil-pointeur')), findsNothing);
}

/// La salle montee seule, avec un depot et un conteneur fournis.
Widget _salle(ProviderContainer conteneur, VueSeance vue, ActionsSeance a) =>
    UncontrolledProviderScope(
      container: conteneur,
      child: hoteCapture(SalleSeance(vue: vue, actions: a)),
    );

void main() {
  group('K-07 : l eleve autorise depuis /demo/salle', () {
    testWidgets('l information courte, puis Ecrire choisi par l eleve : '
        'avant, un doigt lit la page et ne laisse aucun trait', (
      WidgetTester tester,
    ) async {
      await _ouvrir(tester, RoleSeance.eleve, SituationTb.autorisationEcrire);
      // L'information courte, variante adulte (eleve standard sans age).
      expect(_avis, findsOneWidget);
      expect(
        find.descendant(
          of: _avis,
          matching: find.text(t.salle.seance.ecriture.vousPouvezEcrire),
        ),
        findsOneWidget,
      );
      expect(_declencheur, findsOneWidget);
      expect(_outil(tester), isNull, reason: 'rien n est arme a l arrivee');
      // Les gestes de lecture ne deviennent jamais des traits.
      await _glisser(tester, 61);
      expect(_traits(tester), isEmpty);
      // Commandes : Ecrire d'abord, puis la lecture ; rien de l'enseignant.
      await _taper(tester, _declencheur);
      expect(_sectionEcrire, findsOneWidget);
      expect(_avis, findsNothing, reason: 'l information est lue');
      expect(find.byKey(CommandesPedagogiques.cleLecture), findsOneWidget);
      expect(find.byKey(CommandesPedagogiques.cleFocus), findsOneWidget);
      _rienDeLEnseignant();
      expect(
        tester.getRect(_sectionEcrire).top,
        lessThan(
          tester.getRect(find.byKey(CommandesPedagogiques.cleLecture)).top,
        ),
      );
      await _taper(tester, _ecrire);
      expect(_outil(tester), OutilDock.stylet);
      // Stylo, Gomme, Annuler (apres un trait), Terminer ; ni Surligner, ni
      // options de couleur ou d'epaisseur.
      expect(
        find.byKey(BarreStylet.cleOutil(OutilTrait.stylet)),
        findsOneWidget,
      );
      expect(
        find.byKey(BarreStylet.cleOutil(OutilTrait.gomme)),
        findsOneWidget,
      );
      expect(
        find.byKey(BarreStylet.cleOutil(OutilTrait.surligneur)),
        findsNothing,
      );
      expect(find.byKey(BarreStylet.cleTerminer), findsOneWidget);
      expect(find.byKey(EcritureSeance.cleCouleur), findsNothing);
      expect(find.byKey(EcritureSeance.cleEpaisseur), findsNothing);
      await _taper(tester, find.byKey(PanneauSeance.cleReduire));
      expect(_palette, findsOneWidget, reason: 'la palette prend la place');
      expect(_declencheur, findsNothing);
      await _glisser(tester, 62);
      expect(_traits(tester), hasLength(1));
      // Terminer : retour a la lecture, l'encre demeure.
      await _taper(
        tester,
        find.descendant(
          of: _palette,
          matching: find.byKey(BarreStylet.cleTerminer),
        ),
      );
      expect(_outil(tester), isNull);
      expect(_declencheur, findsOneWidget);
      await _glisser(tester, 63);
      expect(_traits(tester), hasLength(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('sans autorisation : Commandes sans Ecrire, aucun trait', (
      WidgetTester tester,
    ) async {
      await _ouvrir(tester, RoleSeance.eleve, SituationTb.ped03);
      expect(_avis, findsNothing);
      await _taper(tester, _declencheur);
      expect(_sectionEcrire, findsNothing);
      expect(_ecrire, findsNothing);
      expect(find.byKey(CommandesPedagogiques.cleLecture), findsOneWidget);
      _rienDeLEnseignant();
      await _taper(tester, find.byKey(PanneauSeance.cleReduire));
      await _glisser(tester, 64);
      expect(_traits(tester), isEmpty);
    });

    testWidgets('Echap reduit les Commandes de l eleve, le focus revient au '
        'declencheur ; l appel reste', (WidgetTester tester) async {
      await _ouvrir(
        tester,
        RoleSeance.eleve,
        SituationTb.autorisationEcrire,
        taille: _bureau,
      );
      await _taper(tester, _declencheur);
      expect(find.byKey(CommandesPedagogiques.cle), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await stabiliser(tester);
      expect(find.byKey(CommandesPedagogiques.cle), findsNothing);
      expect(find.byType(SalleSeance), findsOneWidget);
      final FocusNode? focus = FocusManager.instance.primaryFocus;
      expect(
        focus?.context == null
            ? false
            : find
                  .descendant(
                    of: _declencheur,
                    matching: find.byElementPredicate(
                      (Element e) => identical(e, focus!.context),
                    ),
                  )
                  .evaluate()
                  .isNotEmpty,
        isTrue,
        reason: 'le focus revient au declencheur',
      );
    });

    testWidgets('droit retire (§12) : « Sayyid reprend le tableau. », ni '
        'Ecrire ni palette', (WidgetTester tester) async {
      await _ouvrir(tester, RoleSeance.eleve, SituationTb.droitRetire);
      expect(
        find.descendant(
          of: _avis,
          matching: find.text(t.salle.seance.ecriture.repriseSayyid),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('professeur'), findsNothing);
      // Verification TB-10 : le retrait ne porte pas le crayon de
      // « Vous pouvez ecrire » ; aucune icone peinte dans l'information.
      expect(
        find.descendant(of: _avis, matching: find.byType(Icon)),
        findsNothing,
      );
      expect(_palette, findsNothing);
      await _taper(tester, _declencheur);
      expect(_sectionEcrire, findsNothing);
    });

    testWidgets('verification TB-10 : l\'autorisation garde son crayon, le '
        'retrait n\'en a pas', (WidgetTester tester) async {
      await _ouvrir(tester, RoleSeance.eleve, SituationTb.autorisationEcrire);
      final Finder icone = find.descendant(
        of: _avis,
        matching: find.byType(Icon),
      );
      expect(icone, findsOneWidget);
      expect(tester.widget<Icon>(icone).icon, AppIcons.annoter.repos);
      expect(tester.getSize(icone).width, greaterThan(0));
    });
  });

  group('Mode Accessibilite (guidee, MA-CMD-1)', () {
    testWidgets('tutoiement, declencheur et palette en icones seules, nom '
        'lu et en infobulle', (WidgetTester tester) async {
      await _ouvrir(tester, RoleSeance.guidee, SituationTb.autorisationEcrire);
      expect(
        find.descendant(
          of: _avis,
          matching: find.text(t.salle.seance.ecriture.tuPeuxEcrire),
        ),
        findsOneWidget,
      );
      // Le declencheur : une icone seule, nommee, sans mot visible.
      expect(
        find.descendant(of: _declencheur, matching: find.byType(BoutonIcone)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _declencheur,
          matching: find.text(t.salle.seance.commandes.declencheur),
        ),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel(t.salle.seance.commandes.declencheurSemantique),
        findsOneWidget,
      );
      await _taper(tester, _declencheur);
      expect(find.byKey(CommandesPedagogiques.cleLecture), findsOneWidget);
      // Guidee : jamais de zoom (« Agrandir », « Voir toute la page »).
      expect(
        find.descendant(
          of: find.byKey(CommandesPedagogiques.cle),
          matching: find.byKey(const ValueKey<String>('zoom-local')),
        ),
        findsNothing,
      );
      _rienDeLEnseignant();
      await _taper(tester, _ecrire);
      await _taper(tester, find.byKey(PanneauSeance.cleReduire));
      expect(_palette, findsOneWidget);
      // Palette : icones seules, les mots en infobulle.
      expect(
        find.descendant(
          of: _palette,
          matching: find.text(t.salle.seance.ecriture.terminer),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: _palette, matching: find.byType(Tooltip)),
        findsWidgets,
      );
      await _glisser(tester, 65);
      expect(_traits(tester), hasLength(1));
      expect(tester.takeException(), isNull);
    });
  });

  group('Enseignant (UX-20) : Autoriser et Retirer sur la ligne', () {
    for (final Size taille in <Size>[_telephone, _bureau]) {
      testWidgets('${taille.width.toInt()} : la fiche porte l action, la '
          'ligne dit « Peut ecrire »', (WidgetTester tester) async {
        await _ouvrir(
          tester,
          RoleSeance.enseignant,
          SituationTb.per01,
          taille: taille,
        );
        // PER-01 : Zaynab seule autorisee (quatrieme ligne, la liste
        // defile jusqu'a elle) ; Mariam (depliee) non.
        final Finder zaynab = find.byKey(
          const ValueKey<String>('peut-ecrire-Zaynab'),
        );
        await tester.scrollUntilVisible(
          zaynab,
          80,
          scrollable: find
              .descendant(
                of: find.byKey(const ValueKey<String>('panneau-eleves')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await stabiliser(tester);
        expect(zaynab, findsOneWidget);
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey<String>('eleve-Mariam')),
          -80,
          scrollable: find
              .descendant(
                of: find.byKey(const ValueKey<String>('panneau-eleves')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await stabiliser(tester);
        expect(
          find.byKey(const ValueKey<String>('peut-ecrire-Mariam')),
          findsNothing,
        );
        final Finder bouton = find.byKey(
          const ValueKey<String>('autoriser-ecrire-Mariam'),
        );
        expect(
          find.descendant(
            of: bouton,
            matching: find.text(t.salle.seance.ecriture.autoriser),
          ),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(
            t.salle.seance.ecriture.autoriserSemantique(prenom: 'Mariam'),
          ),
          findsOneWidget,
        );
        await _taper(tester, bouton);
        expect(
          find.byKey(const ValueKey<String>('peut-ecrire-Mariam')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: bouton,
            matching: find.text(t.salle.seance.ecriture.retirer),
          ),
          findsOneWidget,
        );
        await _taper(tester, bouton);
        expect(
          find.byKey(const ValueKey<String>('peut-ecrire-Mariam')),
          findsNothing,
        );
        // Le bouton tient dans l'ecran et dans sa carte.
        final Rect r = tester.getRect(bouton);
        expect((Offset.zero & taille).intersect(r), r);
        expect(
          find.byKey(const ValueKey<String>('eleve-Mariam')),
          findsOneWidget,
        );
        final Rect carte = tester.getRect(
          find.byKey(const ValueKey<String>('eleve-Mariam')),
        );
        expect(carte.intersect(r), r);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Droit retire pendant l ecriture (§19.3 point 7)', () {
    late AnnotationsMemoire depot;
    late ProviderContainer conteneur;
    final VueSeance autorisee = DonneesSeanceDemo.vueTb(
      RoleSeance.eleve,
      SituationTb.autorisationEcrire,
    );
    final VueSeance retiree = DonneesSeanceDemo.vueTb(
      RoleSeance.eleve,
      SituationTb.ped03,
    );
    ActionsSeance actions() => ActionsSeance(
      onCommandes: () {},
      onOutil: (OutilEnseignement _) {},
      onAgrandir: () {},
    );

    setUp(() {
      depot = AnnotationsMemoire('eleve');
      conteneur = ProviderContainer(
        overrides: <Override>[portAnnotationsProvider.overrideWithValue(depot)],
      );
    });
    tearDown(() async {
      conteneur.dispose();
      await depot.liberer();
    });

    testWidgets('le trait en cours se resout sur ses points, la suite du '
        'geste n ecrit rien ; outils retires ; aucun retour automatique', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, _telephone, 1);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_salle(conteneur, autorisee, actions()));
      await stabiliser(tester);
      // L'eleve choisit Ecrire (l'etat de l'appareil, comme la tuile).
      conteneur
          .read(etatOutilsProvider.notifier)
          .choisirOutil(OutilDock.stylet);
      await stabiliser(tester);
      expect(_palette, findsOneWidget);
      final Offset a = _surPage(tester, 0.2, 0.2);
      final Offset b = _surPage(tester, 0.4, 0.2);
      final Offset c = _surPage(tester, 0.8, 0.3);
      final TestPointer doigt = TestPointer(66);
      await tester.sendEventToBinding(doigt.down(a));
      for (int i = 1; i <= 6; i++) {
        await tester.sendEventToBinding(doigt.move(Offset.lerp(a, b, i / 6)!));
        await tester.pump();
      }
      // L'enseignant retire le droit pendant le trait.
      await tester.pumpWidget(_salle(conteneur, retiree, actions()));
      await tester.pump();
      for (int i = 1; i <= 6; i++) {
        await tester.sendEventToBinding(doigt.move(Offset.lerp(b, c, i / 6)!));
        await tester.pump();
      }
      await tester.sendEventToBinding(doigt.up());
      await stabiliser(tester);
      final List<TraitVectoriel> traits = <TraitVectoriel>[
        for (final AnnotationLayer x in depot.couches) ...x.traits,
      ];
      expect(traits, hasLength(1), reason: 'le trait commence est resolu');
      expect(
        traits.single.points.last.x,
        lessThanOrEqualTo(0.4 + 1e-6),
        reason: 'aucun point pose apres le retrait',
      );
      // Outils retires, information du retrait, couche en lecture.
      expect(_palette, findsNothing);
      expect(conteneur.read(etatOutilsProvider).outilActif, isNull);
      expect(
        find.descendant(
          of: _avis,
          matching: find.text(t.salle.seance.ecriture.repriseSayyid),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<CoucheAnnotation>(find.byKey(SurfacePageFixe.cleCouche))
            .saisie,
        isFalse,
      );
      // Une nouvelle autorisation n'arme rien : l'eleve choisit Ecrire.
      await tester.pumpWidget(_salle(conteneur, autorisee, actions()));
      await stabiliser(tester);
      expect(conteneur.read(etatOutilsProvider).outilActif, isNull);
      expect(_palette, findsNothing);
      expect(_declencheur, findsOneWidget);
      expect(
        find.descendant(
          of: _avis,
          matching: find.text(t.salle.seance.ecriture.vousPouvezEcrire),
        ),
        findsOneWidget,
      );
      await _glisser(tester, 67);
      expect(
        <TraitVectoriel>[
          for (final AnnotationLayer x in depot.couches) ...x.traits,
        ],
        hasLength(1),
        reason: 'le doigt lit, rien de plus',
      );
    });

    testWidgets('la surface seule (outil encore retenu) : le droit retire '
        'resout le trait en cours, la suite du geste n ecrit rien', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, _bureau, 1);
      addTearDown(tester.view.reset);
      conteneur
          .read(etatOutilsProvider.notifier)
          .choisirOutil(OutilDock.stylet);
      Widget surface(VueSeance vue) => UncontrolledProviderScope(
        container: conteneur,
        child: hoteCapture(SurfacePageFixe(vue: vue, surface: vue.vueSurface)),
      );
      await tester.pumpWidget(surface(autorisee));
      await stabiliser(tester);
      final Offset a = _surPage(tester, 0.2, 0.2);
      final Offset b = _surPage(tester, 0.4, 0.2);
      final Offset c = _surPage(tester, 0.8, 0.3);
      final TestPointer doigt = TestPointer(69);
      await tester.sendEventToBinding(doigt.down(a));
      for (int i = 1; i <= 6; i++) {
        await tester.sendEventToBinding(doigt.move(Offset.lerp(a, b, i / 6)!));
        await tester.pump();
      }
      await tester.pumpWidget(surface(retiree));
      await tester.pump();
      expect(conteneur.read(etatOutilsProvider).outilActif, OutilDock.stylet);
      for (int i = 1; i <= 6; i++) {
        await tester.sendEventToBinding(doigt.move(Offset.lerp(b, c, i / 6)!));
        await tester.pump();
      }
      await tester.sendEventToBinding(doigt.up());
      await stabiliser(tester);
      final List<TraitVectoriel> traits = <TraitVectoriel>[
        for (final AnnotationLayer x in depot.couches) ...x.traits,
      ];
      expect(traits, hasLength(1));
      expect(traits.single.points.last.x, lessThanOrEqualTo(0.4 + 1e-6));
    });

    testWidgets('tour 2 : l entree recreee au moment du retrait (bascule, '
        'gabarit) repose quand meme l outil retenu', (
      WidgetTester tester,
    ) async {
      // La guidee : au telephone la salle MA-CMD-1, au bureau la salle de
      // l'eleve ; l'entree change de place dans l'arbre.
      final VueSeance autoriseeG = DonneesSeanceDemo.vueTb(
        RoleSeance.guidee,
        SituationTb.autorisationEcrire,
      );
      final VueSeance retireeG = DonneesSeanceDemo.vueTb(
        RoleSeance.guidee,
        SituationTb.ped03,
      );
      fixerVueCapture(tester, _telephone, 1);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_salle(conteneur, autoriseeG, actions()));
      await stabiliser(tester);
      conteneur
          .read(etatOutilsProvider.notifier)
          .choisirOutil(OutilDock.stylet);
      await stabiliser(tester);
      expect(_palette, findsOneWidget);
      // Le gabarit change (telephone vers bureau) en meme temps que le
      // retrait : l'entree des Commandes est recreee ailleurs dans l'arbre
      // avec la vue du retrait, le passage de vrai a faux n'est jamais vu
      // par elle.
      final Element avant = tester.element(find.byType(CommandesEleve));
      fixerVueCapture(tester, _bureau, 1);
      await tester.pumpWidget(_salle(conteneur, retireeG, actions()));
      expect(
        identical(tester.element(find.byType(CommandesEleve)), avant),
        isFalse,
        reason: 'l entree est bien recreee',
      );
      await stabiliser(tester);
      expect(conteneur.read(etatOutilsProvider).outilActif, isNull);
      expect(_palette, findsNothing);
    });

    testWidgets('« Sayyida reprend le tableau. » ; sans titre, le nom', (
      WidgetTester tester,
    ) async {
      final VueSeance sayyida = DonneesSeanceDemo.vueTb(
        RoleSeance.eleve,
        SituationTb.droitRetire,
        titre: TitreEnseignant.sayyida,
      );
      expect(sayyida.avisRetrait, t.salle.seance.ecriture.repriseSayyida);
      const VueSeance inconnu = VueSeance(
        role: RoleSeance.eleve,
        nomClasse: 'Classe An-Nour',
        nomEnseignant: 'Ibrahim',
        initialesEnseignant: 'I',
        ecritureRetiree: true,
      );
      expect(
        inconnu.avisRetrait,
        t.salle.seance.ecriture.repriseNom(nom: 'Ibrahim'),
      );
      fixerVueCapture(tester, _telephone, 1);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_salle(conteneur, sayyida, actions()));
      await stabiliser(tester);
      expect(
        find.descendant(
          of: _avis,
          matching: find.text(t.salle.seance.ecriture.repriseSayyida),
        ),
        findsOneWidget,
      );
    });
  });

  group('Par role : capacites lues de la vue', () {
    test('ecrire n ouvre aucun droit de page ni de support', () {
      for (final RoleSeance role in <RoleSeance>[
        RoleSeance.eleve,
        RoleSeance.guidee,
      ]) {
        final VueSeance v = DonneesSeanceDemo.vueTb(
          role,
          SituationTb.autorisationEcrire,
        );
        expect(v.voitEcriture, isTrue, reason: role.name);
        expect(v.voitPaginationCommandes, isFalse);
        expect(v.voitAffichagesPartages, isFalse);
        expect(v.voitRanger, isFalse);
        expect(v.voitEffacerNotes, isFalse);
        expect(v.voitOutils, isFalse);
        expect(v.gereToutesLesNotes, isFalse);
        expect(v.voitAutorisationEcrire, isFalse);
        expect(v.outilsEcriture, <OutilTrait>[
          OutilTrait.stylet,
          OutilTrait.gomme,
        ]);
        expect(v.voitOptionsEcriture, isFalse);
      }
      final VueSeance prof = DonneesSeanceDemo.vueTb(
        RoleSeance.enseignant,
        SituationTb.per01,
      );
      expect(prof.voitAutorisationEcrire, isTrue);
      expect(prof.outilsEcriture, OutilTrait.values);
      expect(prof.avisEcriture, isNull);
      expect(
        DonneesSeanceDemo.vueTb(
          RoleSeance.eleve,
          SituationTb.ped03,
        ).voitEcriture,
        isFalse,
      );
    });
  });

  testWidgets('K-07 : l eleve autorise ecrit depuis le lien de la page '
      'servie (DemoSallePage)', (WidgetTester tester) async {
    fixerVueCapture(tester, _telephone, 1);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      hoteCapture(
        const DemoSallePage(
          role: RoleSeance.eleve,
          situation: SituationTb.autorisationEcrire,
        ),
      ),
    );
    await stabiliser(tester);
    await _taper(tester, _declencheur);
    await _taper(tester, _ecrire);
    await _taper(tester, find.byKey(PanneauSeance.cleReduire));
    await _glisser(tester, 68);
    expect(_traits(tester), hasLength(1));
  });

  group('Tour 2 : 320 a 200 % et 1440, mesures sur le rendu', () {
    setUpAll(chargerPolicesDuDepot);
    const Size etroit = Size(320, 700);

    Future<void> monter(
      WidgetTester tester,
      RoleSeance role,
      Size taille,
      double texte,
    ) async {
      fixerVueCapture(tester, taille, 1);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hoteCapture(
          DemoSallePage(role: role, situation: SituationTb.autorisationEcrire),
          echelleTexte: texte,
        ),
      );
      await stabiliser(tester);
      expect(tester.takeException(), isNull);
    }

    for (final RoleSeance role in <RoleSeance>[
      RoleSeance.eleve,
      RoleSeance.guidee,
    ]) {
      testWidgets('${role.name} : Commandes ouvertes, aucun mot coupe dans '
          'le panneau (titre et Reduire)', (WidgetTester tester) async {
        await monter(tester, role, etroit, 2);
        await _taper(tester, _declencheur);
        expect(find.byType(PanneauSeance), findsOneWidget);
        expect(tester.takeException(), isNull);
        verifierAucunMotCoupe(tester, find.byType(PanneauSeance));
        final Rect reduire = tester.getRect(
          find.byKey(PanneauSeance.cleReduire),
        );
        expect(reduire.left, greaterThanOrEqualTo(0));
        expect(reduire.right, lessThanOrEqualTo(etroit.width));
      });

      testWidgets('${role.name} : l information courte garde la page '
          '(au moins les trois quarts de sa hauteur sans elle), entiere '
          'au-dessus de la barre de l appel', (WidgetTester tester) async {
        await monter(tester, role, etroit, 2);
        expect(_avis, findsOneWidget);
        final double avecAvis = tester.getRect(_page).height;
        final Rect avis = tester.getRect(_avis);
        final Rect declencheur = tester.getRect(_declencheur);
        final Rect dock = tester.getRect(find.byType(DockSeance));
        verifierAucunMotCoupe(tester, _avis);
        for (final Rect r in <Rect>[avis, declencheur]) {
          expect(r.left, greaterThanOrEqualTo(0));
          expect(r.right, lessThanOrEqualTo(etroit.width));
          expect(r.bottom, lessThanOrEqualTo(dock.top + 0.5));
          expect(r.top, greaterThanOrEqualTo(tester.getRect(_page).bottom));
        }
        // La meme salle, l'information lue (Commandes ouvertes puis
        // reduites) : seule l'entree reste sous la page.
        await _taper(tester, _declencheur);
        await _taper(tester, find.byKey(PanneauSeance.cleReduire));
        expect(_avis, findsNothing);
        final double sansAvis = tester.getRect(_page).height;
        expect(
          avecAvis,
          greaterThanOrEqualTo(sansAvis * 0.75),
          reason: 'avec $avecAvis, sans $sansAvis',
        );
      });
    }

    testWidgets('1440, eleve : le volet des Commandes ne couvre pas la '
        'barre basse (page, zoom local, Agrandir)', (
      WidgetTester tester,
    ) async {
      await monter(tester, RoleSeance.eleve, _bureau, 1);
      await _taper(tester, _declencheur);
      final Rect volet = tester.getRect(
        find.byKey(const ValueKey<String>('panneau-seance-volet')),
      );
      final Iterable<Element> zooms = find
          .byType(ZoomLocal)
          .evaluate()
          .where(
            (Element e) =>
                e.findAncestorWidgetOfExactType<PanneauSeance>() == null,
          );
      expect(zooms, hasLength(1), reason: 'le zoom local de la barre basse');
      final RenderBox boite = zooms.single.renderObject! as RenderBox;
      final Rect zoom = boite.localToGlobal(Offset.zero) & boite.size;
      expect(
        volet.overlaps(zoom),
        isFalse,
        reason: 'volet $volet, barre basse $zoom',
      );
      // Verification TB-10 : une seule commande de zoom visible (la barre
      // basse), et le volet dans le cadre de la surface.
      expect(
        find.byType(ZoomLocal).hitTestable(),
        findsOneWidget,
        reason: 'le zoom local paraissait aussi dans la Lecture du volet',
      );
      final Rect surface = tester.getRect(find.byType(ZoneSupport));
      expect(volet.left, greaterThanOrEqualTo(surface.left - 0.5));
      expect(
        volet.right,
        lessThanOrEqualTo(surface.right + 0.5),
        reason: 'volet $volet, surface $surface',
      );
    });

    // Verification TB-10 : Commandes ouvertes apres « Ecrire », a 320 x2
    // (eleve et guidee, fr et ar) et 390 x2 en guidee, la tuile n'avait que
    // son icone et Stylo, Gomme, Terminer ne s'atteignaient qu'en defilant,
    // sans aucun signe. La tuile garde son mot ; le fondu du bas dit la
    // suite tant qu'il en reste ; au bout, Terminer est dans la vue.
    for (final (RoleSeance role, Size taille, AppLocale langue)
        in <(RoleSeance, Size, AppLocale)>[
          (RoleSeance.eleve, etroit, AppLocale.fr),
          (RoleSeance.eleve, etroit, AppLocale.ar),
          (RoleSeance.guidee, etroit, AppLocale.fr),
          (RoleSeance.guidee, etroit, AppLocale.ar),
          (RoleSeance.guidee, _telephone, AppLocale.fr),
        ]) {
      testWidgets('${role.name} ${taille.width.toInt()} x2 '
          '${langue.languageCode} : apres Ecrire, la tuile dit son mot et la '
          'suite du volet est signalee', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        await monter(tester, role, taille, 2);
        await _taper(tester, _declencheur);
        await _taper(tester, _ecrire);
        final Finder mot = find.descendant(
          of: _ecrire,
          matching: find.text(t.salle.seance.outils.ecrire),
        );
        expect(mot, findsOneWidget, reason: 'la tuile Ecrire sans son mot');
        expect(tester.getSize(mot).height, greaterThan(0));
        final Finder colonne = find.byKey(CommandesPedagogiques.cleDefilement);
        final ScrollableState defile = tester.state<ScrollableState>(
          find.descendant(of: colonne, matching: find.byType(Scrollable)),
        );
        expect(
          find.byKey(CommandesPedagogiques.cleFonduBas).evaluate().isNotEmpty,
          defile.position.extentAfter > 0.5,
          reason: 'le fondu du bas suit ce qui reste a lire',
        );
        final Finder fin = find.descendant(
          of: colonne,
          matching: find.byKey(BarreStylet.cleTerminer),
        );
        final Rect vue = tester.getRect(colonne);
        final Rect avant = tester.getRect(fin);
        if (avant.bottom > vue.bottom + 0.5) {
          expect(
            find.byKey(CommandesPedagogiques.cleFonduBas),
            findsOneWidget,
            reason: 'Terminer $avant sous le bord de $vue, sans signe',
          );
        }
        await tester.runAsync(
          () => Scrollable.ensureVisible(tester.element(fin), alignment: 1),
        );
        await tester.pumpAndSettle();
        final Rect terminer = tester.getRect(fin);
        expect(
          terminer.top,
          greaterThanOrEqualTo(vue.top - 0.5),
          reason: 'Terminer $terminer, vue $vue',
        );
        expect(
          terminer.bottom,
          lessThanOrEqualTo(vue.bottom + 0.5),
          reason: 'Terminer $terminer, vue $vue',
        );
        expect(tester.takeException(), isNull);
      });
    }

    // Verification TB-10 : en arabe a 320 x2, « الكتابة مسموحة » etait
    // tronque en « الكتاب… » sur la ligne de Mariam. Les mentions d'etat de
    // la ligne (statut, droit d'ecrire) se lisent entieres, dans la carte.
    for (final AppLocale langue in <AppLocale>[AppLocale.ar, AppLocale.fr]) {
      testWidgets('320 x2 ${langue.languageCode}, enseignant : les mentions '
          'd etat de la ligne de l eleve ne sont jamais tronquees', (
        WidgetTester tester,
      ) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        fixerVueCapture(tester, etroit, 1);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          hoteCapture(
            const DemoSallePage(
              role: RoleSeance.enseignant,
              situation: SituationTb.per01,
            ),
            echelleTexte: 2,
          ),
        );
        await stabiliser(tester);
        await _taper(
          tester,
          find.byKey(const ValueKey<String>('autoriser-ecrire-Mariam')),
        );
        final Finder ligne = find.byKey(const ValueKey<String>('eleve-Mariam'));
        await tester.ensureVisible(ligne);
        await stabiliser(tester);
        final Finder mention = find.descendant(
          of: ligne,
          matching: find.text(t.salle.seance.ecriture.peutEcrire),
        );
        expect(mention, findsOneWidget);
        final Rect carte = tester.getRect(ligne);
        final List<Element> mentions = <Element>[
          ...mention.evaluate(),
          ...find
              .descendant(
                of: ligne,
                matching: find.text(
                  libelleStatutEleve(StatutEleveSeance.connecte),
                ),
              )
              .evaluate(),
        ];
        expect(mentions, hasLength(2));
        for (final Element e in mentions) {
          final RenderParagraph p = e.renderObject! as RenderParagraph;
          expect(
            p.didExceedMaxLines,
            isFalse,
            reason: '« ${p.text.toPlainText()} » tronque',
          );
          final Rect r = p.localToGlobal(Offset.zero) & p.size;
          expect(r.left, greaterThanOrEqualTo(carte.left - 0.5));
          expect(r.right, lessThanOrEqualTo(carte.right + 0.5));
        }
        verifierAucunMotCoupe(tester, mention);
        expect(tester.takeException(), isNull);
      });
    }

    test('W-253 (WCAG 2.5.3) : le nom lu commence par le libelle visible, '
        'd un seul tenant', () {
      final e = t.salle.seance.ecriture;
      expect(e.autoriserSemantique(prenom: 'Mariam'), startsWith(e.autoriser));
      expect(
        e.retirerSemantique(dePrenom: deDevant('Mariam')),
        startsWith(e.retirer),
      );
    });

    testWidgets('Echap, contexte deplie et Commandes ouvertes : le contexte '
        'se ferme d abord', (WidgetTester tester) async {
      final List<String> appels = <String>[];
      final VueSeance vue =
          DonneesSeanceDemo.vueTb(
            RoleSeance.eleve,
            SituationTb.autorisationEcrire,
          ).copyWith(
            contexte: ContexteOuvert.enseignant,
            panneau: PanneauOuvert.commandes,
          );
      expect(vue.contexteOuvert, isTrue);
      fixerVueCapture(tester, _bureau, 1);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hoteCapture(
          SalleSeance(
            vue: vue,
            actions: ActionsSeance(
              onCommandes: () => appels.add('commandes'),
              onContexte: (ContexteOuvert c) =>
                  appels.add('contexte ${c.name}'),
              onOutil: (OutilEnseignement _) {},
            ),
          ),
        ),
      );
      await stabiliser(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(appels, <String>['contexte aucun']);
    });
  });
}
