// TB-10 (plan V2 §5, §12 « Autorisation de dessin » et « Droit retire »,
// §19.3, §20 ; UX-20 ; MA-CMD-1) : l'eleve, le Mode Accessibilite et
// l'autorisation d'ecrire.
//
// Les parcours partent de la VRAIE coquille (`/demo/salle`, K-07) et passent
// par les vrais boutons : Commandes, Ecrire, Reduire, « Autoriser a ecrire ».
// Les mesures portent sur le rendu : traits pris par le depot, widgets
// montes, rectangles, outil retenu de l'appareil.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
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
    show PaginationSupport;
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/ecriture_seance.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_seance.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/surface_page_fixe.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/tc_dock/barre_stylet.dart';
import 'package:rewayah_academy/features/tc_dock/couche_annotation.dart';

import '../../capture/outil_capture.dart' show fixerVueCapture, hoteCapture;
import '../../router/support_routeur.dart';

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
      expect(_palette, findsNothing);
      await _taper(tester, _declencheur);
      expect(_sectionEcrire, findsNothing);
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
}
