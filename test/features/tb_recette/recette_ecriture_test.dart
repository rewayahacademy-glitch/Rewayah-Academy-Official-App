// TB-12, lot T1-ecriture : recette de l'ecriture (plan V2 §15 « Masquer,
// ecrire, reafficher », « Changer de page pendant un dessin », « Deux eleves
// autorises », « Retrait d'autorisation » ; §23 UX-03 et UX-20).
//
// Chaque scenario part de la VRAIE coquille (`/demo/salle`, lien de la
// situation, vrais boutons) quand une seule salle suffit. Quand le scenario
// met deux personnes dans la meme seance (enseignant et eleve, deux eleves),
// les deux salles sont montees cote a cote sur UN SEUL depot en memoire
// (`AnnotationsMemoire`), chacune avec son conteneur (outil, historique
// personnel) ; la diffusion du droit d'ecrire est jouee par le test, a la
// place du serveur (BR-1) : elle ne prouve aucun reseau. Les mesures portent
// sur le depot (traits pris, ancrage, points) et sur le rendu (widgets
// montes, traits peints par la couche).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/commandes_masquables.dart';
import 'package:rewayah_academy/core/appairage/service_avatar.dart'
    show avatarUrlProvider;
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_outils/annotation_layer.dart';
import 'package:rewayah_academy/core/tc_outils/etat_outils.dart';
import 'package:rewayah_academy/core/tc_outils/port_annotations.dart';
import 'package:rewayah_academy/core/tc_outils/port_dock_hote.dart'
    show OutilDock;
import 'package:rewayah_academy/core/widgets/controle_segmente.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/barre_support.dart'
    show PaginationSupport;
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/dock_seance.dart'
    show BoutonAppel;
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
final Finder _onglets = find.byKey(CommandesPedagogiques.cleOnglets);
final Finder _avis = find.byKey(CommandesEleve.cleAvis);
final Finder _reduire = find.byKey(PanneauSeance.cleReduire);

/// L'entree « Commandes » : le declencheur, ou le bouton de la palette.
final Finder _entreeCommandes = find.byWidgetPredicate(
  (Widget w) =>
      w.key == DeclencheurCommandes.cle || w.key == BarreStylet.cleCommandes,
);

Future<void> _attendre(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pump();
  await tester.tap(cible);
  await _attendre(tester);
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
  expect(find.byType(SalleSeance), findsOneWidget);
  expect(tester.takeException(), isNull);
}

/// Le depot de la salle de la coquille (celui de la demonstration).
AnnotationsMemoire _depotCoquille(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(SalleSeance)))
            .read(portAnnotationsProvider)
        as AnnotationsMemoire;

OutilDock? _outilCoquille(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(SalleSeance)))
        .read(etatOutilsProvider)
        .outilActif;

List<TraitVectoriel> _traitsDe(AnnotationsMemoire depot) => <TraitVectoriel>[
  for (final AnnotationLayer c in depot.couches) ...c.traits,
];

List<String> _ids(Iterable<TraitVectoriel> traits) => <String>[
  for (final TraitVectoriel x in traits) x.id,
];

/// Un point de la page [page] (coordonnees de la page, 0 a 1).
Offset _surPage(WidgetTester tester, Finder page, double x, double y) {
  final Rect r = tester.getRect(page);
  return r.topLeft + Offset(x * r.width, y * r.height);
}

/// Un doigt pose en [a] qui glisse jusqu'a [b], en [pas] mouvements ; le
/// doigt reste pose (le geste continue).
Future<TestPointer> _commencer(
  WidgetTester tester,
  int id,
  Offset a,
  Offset b, {
  int pas = 6,
}) async {
  final TestPointer doigt = TestPointer(id);
  await tester.sendEventToBinding(doigt.down(a));
  for (int i = 1; i <= pas; i++) {
    await tester.sendEventToBinding(doigt.move(Offset.lerp(a, b, i / pas)!));
    await tester.pump();
  }
  return doigt;
}

/// La suite d'un geste deja commence : de [a] a [b], puis le doigt se leve.
Future<void> _finir(
  WidgetTester tester,
  TestPointer doigt,
  Offset a,
  Offset b, {
  int pas = 6,
}) async {
  for (int i = 1; i <= pas; i++) {
    await tester.sendEventToBinding(doigt.move(Offset.lerp(a, b, i / pas)!));
    await tester.pump();
  }
  await tester.sendEventToBinding(doigt.up());
  await _attendre(tester);
}

/// Un trait complet de [a] a [b].
Future<void> _tracer(WidgetTester tester, int id, Offset a, Offset b) async {
  final TestPointer doigt = await _commencer(tester, id, a, b);
  await tester.sendEventToBinding(doigt.up());
  await _attendre(tester);
}

/// Les traits peints par la couche de la page [dans].
List<TraitVectoriel> _peints(WidgetTester tester, Finder dans) => tester
    .widget<CoucheAnnotation>(
      find.descendant(
        of: dans,
        matching: find.byKey(SurfacePageFixe.cleCouche),
      ),
    )
    .traits;

/// Une personne de la seance, sa salle et son conteneur (outil, historique
/// personnel) ; le depot d'annotations est celui de la seance, partage.
ProviderContainer _conteneurPour(AnnotationsMemoire depot) => ProviderContainer(
  overrides: <Override>[
    portAnnotationsProvider.overrideWithValue(depot),
    // Comme la demonstration : aucune URL de photo demandee (K-28).
    avatarUrlProvider.overrideWith(
      (Ref _, String cle) =>
          Future<String>.error(StateError('demonstration : $cle')),
    ),
  ],
);

/// La salle d'une personne, a la taille d'un telephone : la vue vient du
/// test (la seance), les Commandes et le panneau Eleves s'ouvrent et se
/// reduisent localement, comme dans `SalleDemo`.
class _Poste extends StatefulWidget {
  const _Poste({
    required this.conteneur,
    required this.vue,
    this.onAutoriserEcrire,
    super.key,
  });

  final ProviderContainer conteneur;
  final VueSeance vue;
  final ValueChanged<EleveSeance>? onAutoriserEcrire;

  @override
  State<_Poste> createState() => _PosteState();
}

class _PosteState extends State<_Poste> {
  PanneauOuvert? _panneau;

  void _basculer(PanneauOuvert p) => setState(() {
    final PanneauOuvert actuel = _panneau ?? widget.vue.panneau;
    _panneau = actuel == p ? PanneauOuvert.aucun : p;
  });

  @override
  Widget build(BuildContext context) {
    final VueSeance vue = widget.vue.copyWith(
      panneau: _panneau ?? widget.vue.panneau,
    );
    final bool enseignant = vue.role == RoleSeance.enseignant;
    return SizedBox.fromSize(
      size: _telephone,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(size: _telephone),
        child: UncontrolledProviderScope(
          container: widget.conteneur,
          child: SalleSeance(
            vue: vue,
            actions: ActionsSeance(
              onCommandes: () => _basculer(PanneauOuvert.commandes),
              onEleves: enseignant
                  ? () => _basculer(PanneauOuvert.eleves)
                  : null,
              onOutil: (OutilEnseignement _) {},
              onAgrandir: () {},
              onAutoriserEcrire: widget.onAutoriserEcrire,
            ),
          ),
        ),
      ),
    );
  }
}

/// Deux postes cote a cote, dans un seul ecran de deux telephones.
Future<void> _monterDeux(WidgetTester tester, Widget deux) async {
  fixerVueCapture(tester, Size(_telephone.width * 2, _telephone.height), 1);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(hoteCapture(deux));
  await _attendre(tester);
  expect(tester.takeException(), isNull);
}

/// Commandes > Ecrire, puis Reduire, dans le poste [poste] (eleve autorise).
Future<void> _ecrireEleve(WidgetTester tester, Finder poste) async {
  await _taper(tester, find.descendant(of: poste, matching: _declencheur));
  await _taper(tester, find.descendant(of: poste, matching: _ecrire));
  await _taper(tester, find.descendant(of: poste, matching: _reduire));
  expect(find.descendant(of: poste, matching: _palette), findsOneWidget);
}

void main() {
  // ---------------------------------------------------------------------
  // UX-20 / R-09 (§15 « Retrait d'autorisation ») : de bout en bout.
  // ---------------------------------------------------------------------
  group('UX-20 / R-09 : l enseignant retire le droit pendant le trait', () {
    testWidgets('meme depot, deux salles : aucun point apres le retrait, '
        'palette et Ecrire retires chez Mariam, « Sayyid reprend le '
        'tableau. »', (WidgetTester tester) async {
      final AnnotationsMemoire depot = AnnotationsMemoire(
        DonneesSeanceDemo.groupeDemo,
      );
      addTearDown(depot.liberer);
      final ProviderContainer prof = _conteneurPour(depot);
      addTearDown(prof.dispose);
      final ProviderContainer eleve = _conteneurPour(depot);
      addTearDown(eleve.dispose);
      // Le droit de Mariam, tel que le serveur le diffuserait (BR-1).
      final ValueNotifier<bool> droit = ValueNotifier<bool>(true);
      addTearDown(droit.dispose);
      const Key posteProf = ValueKey<String>('poste-enseignant');
      const Key posteEleve = ValueKey<String>('poste-eleve');
      final VueSeance baseProf = DonneesSeanceDemo.vueTb(
        RoleSeance.enseignant,
        SituationTb.autorisationEcrire,
      );
      await _monterDeux(
        tester,
        ValueListenableBuilder<bool>(
          valueListenable: droit,
          builder: (BuildContext _, bool peut, Widget? _) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Poste(
                key: posteProf,
                conteneur: prof,
                vue: baseProf.copyWith(
                  eleves: <EleveSeance>[
                    for (final EleveSeance e in baseProf.eleves)
                      EleveSeance(
                        prenom: e.prenom,
                        statut: e.statut,
                        fiche: e.fiche,
                        cleAvatar: e.cleAvatar,
                        peutEcrire: e.prenom == DonneesSeanceDemo.eleveCourant
                            ? peut
                            : e.peutEcrire,
                      ),
                  ],
                ),
                onAutoriserEcrire: (EleveSeance e) {
                  if (e.prenom == DonneesSeanceDemo.eleveCourant) {
                    droit.value = !e.peutEcrire;
                  }
                },
              ),
              _Poste(
                key: posteEleve,
                conteneur: eleve,
                vue: DonneesSeanceDemo.vueTb(
                  RoleSeance.eleve,
                  peut
                      ? SituationTb.autorisationEcrire
                      : SituationTb.droitRetire,
                ),
              ),
            ],
          ),
        ),
      );
      final Finder chezProf = find.byKey(posteProf);
      final Finder chezEleve = find.byKey(posteEleve);
      final Finder pageEleve = find.descendant(of: chezEleve, matching: _page);
      final Finder retirer = find.descendant(
        of: chezProf,
        matching: find.byKey(const ValueKey<String>('autoriser-ecrire-Mariam')),
      );
      // Avant : la ligne de Mariam dit « Peut ecrire », le bouton
      // « Retirer l'autorisation d'ecrire ».
      await tester.ensureVisible(retirer);
      await _attendre(tester);
      expect(
        find.descendant(
          of: chezProf,
          matching: find.byKey(const ValueKey<String>('peut-ecrire-Mariam')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: retirer,
          matching: find.text(t.salle.seance.ecriture.retirer),
        ),
        findsOneWidget,
      );
      // Mariam choisit Ecrire par ses vrais boutons.
      await _ecrireEleve(tester, chezEleve);
      expect(eleve.read(etatOutilsProvider).outilActif, OutilDock.stylet);
      expect(prof.read(etatOutilsProvider).outilActif, isNull);
      // Mariam trace ; le doigt reste pose.
      final Offset a = _surPage(tester, pageEleve, 0.2, 0.2);
      final Offset b = _surPage(tester, pageEleve, 0.4, 0.2);
      final Offset c = _surPage(tester, pageEleve, 0.8, 0.3);
      final TestPointer doigt = await _commencer(tester, 81, a, b);
      // L'enseignant tape « Retirer » pendant le trait (autre doigt, autre
      // salle).
      await tester.tap(retirer);
      await tester.pump();
      expect(droit.value, isFalse, reason: 'le retrait est parti');
      await _finir(tester, doigt, b, c);
      await _attendre(tester);
      // Le depot de la seance : un trait, resolu sur ses points d'avant.
      final List<TraitVectoriel> traits = _traitsDe(depot);
      expect(traits, hasLength(1), reason: 'le trait commence est resolu');
      expect(
        traits.single.points.last.x,
        lessThanOrEqualTo(0.4 + 1e-6),
        reason: 'aucun point pose apres le retrait',
      );
      expect(
        traits.single.ancrage,
        DonneesSeanceDemo.traitDemonstration.ancrage,
        reason: 'aucun trait applique a un autre contexte',
      );
      // Chez Mariam : outils retires, information du retrait, lecture.
      expect(find.descendant(of: chezEleve, matching: _palette), findsNothing);
      expect(eleve.read(etatOutilsProvider).outilActif, isNull);
      expect(
        find.descendant(
          of: chezEleve,
          matching: find.descendant(
            of: _avis,
            matching: find.text(t.salle.seance.ecriture.repriseSayyid),
          ),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<CoucheAnnotation>(
              find.descendant(
                of: chezEleve,
                matching: find.byKey(SurfacePageFixe.cleCouche),
              ),
            )
            .saisie,
        isFalse,
      );
      await _taper(
        tester,
        find.descendant(of: chezEleve, matching: _declencheur),
      );
      expect(
        find.descendant(
          of: chezEleve,
          matching: find.byKey(CommandesPedagogiques.cleEcritureEleve),
        ),
        findsNothing,
      );
      expect(find.descendant(of: chezEleve, matching: _ecrire), findsNothing);
      await _taper(tester, find.descendant(of: chezEleve, matching: _reduire));
      // Chez l'enseignant : plus de « Peut ecrire », le bouton redevient
      // « Autoriser a ecrire » ; le trait resolu se voit sur sa page.
      expect(
        find.descendant(
          of: chezProf,
          matching: find.byKey(const ValueKey<String>('peut-ecrire-Mariam')),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: retirer,
          matching: find.text(t.salle.seance.ecriture.autoriser),
        ),
        findsOneWidget,
      );
      expect(
        _ids(_peints(tester, chezProf)),
        contains(traits.single.id),
        reason: 'la page de l enseignant peint le trait resolu',
      );
      // Un nouveau geste de Mariam ne laisse rien.
      await _tracer(
        tester,
        82,
        _surPage(tester, pageEleve, 0.2, 0.6),
        _surPage(tester, pageEleve, 0.8, 0.65),
      );
      expect(_ids(_traitsDe(depot)), <String>[traits.single.id]);
      expect(tester.takeException(), isNull);
    });
  });

  // ---------------------------------------------------------------------
  // R-03 (§15 « Masquer, ecrire, reafficher »).
  // ---------------------------------------------------------------------
  testWidgets('R-03 : en Support (calque cache), Ecrire puis tracer ; le '
      'nouveau trait a l ancrage du cercle et les deux sont peints ensemble '
      'en « Avec notes »', (WidgetTester tester) async {
    await _ouvrir(tester, RoleSeance.enseignant, SituationTb.ped02);
    final Finder calque = find.byKey(SurfacePageFixe.cleCalque);
    // Support : le cercle de la seance est la, cache, jamais efface.
    expect(tester.widget<Visibility>(calque).visible, isFalse);
    expect(
      _ids(_peints(tester, find.byType(SalleSeance))),
      contains(DonneesSeanceDemo.traitDemonstration.id),
    );
    // Commandes > Outils > Ecrire, puis Reduire.
    await _taper(tester, _entreeCommandes);
    await _taper(
      tester,
      find.descendant(
        of: _onglets,
        matching: find.text(t.salle.seance.commandes.ongletOutils),
      ),
    );
    await _taper(tester, _ecrire);
    expect(_outilCoquille(tester), OutilDock.stylet);
    await _taper(tester, _reduire);
    expect(_palette, findsOneWidget);
    await _tracer(
      tester,
      83,
      _surPage(tester, _page, 0.2, 0.2),
      _surPage(tester, _page, 0.6, 0.25),
    );
    final TraitVectoriel nouveau = _traitsDe(_depotCoquille(tester)).single;
    final ContentPosition cercle = DonneesSeanceDemo.traitDemonstration.ancrage;
    expect(nouveau.ancrage, cercle, reason: 'meme ressource, meme page');
    expect(nouveau.ancrage.resourceId, DonneesSeanceDemo.chapitre1.id);
    expect(nouveau.ancrage.page, 1);
    // Reaffiche : « Avec notes », le cercle et le nouveau trait peints
    // ensemble sur la meme page.
    expect(tester.widget<Visibility>(calque).visible, isTrue);
    await _taper(tester, _entreeCommandes);
    await _taper(
      tester,
      find.descendant(
        of: _onglets,
        matching: find.text(t.salle.seance.commandes.ongletSupport),
      ),
    );
    // Ecrire a fait passer l'affichage partage a « Avec notes » (une note
    // ecrite se voit) : le segment le dit, sans autre clic.
    expect(
      tester
          .widget<ControleSegmente<AffichagePartage>>(
            find.descendant(
              of: find.byKey(CommandesPedagogiques.cleAffichages),
              matching: find.byType(ControleSegmente<AffichagePartage>),
            ),
          )
          .valeur,
      AffichagePartage.avecNotes,
    );
    await _taper(tester, _reduire);
    expect(tester.widget<Visibility>(calque).visible, isTrue);
    expect(
      _ids(_peints(tester, find.byType(SalleSeance))),
      containsAll(<String>[
        DonneesSeanceDemo.traitDemonstration.id,
        nouveau.id,
      ]),
    );
    expect(tester.takeException(), isNull);
  });

  // ---------------------------------------------------------------------
  // R-08 (§15 « Deux eleves autorises »).
  // ---------------------------------------------------------------------
  testWidgets('R-08 : deux eleves autorises sur un meme depot ; traits '
      'distincts, Annuler et Gomme de chacun ne touchent que les siens', (
    WidgetTester tester,
  ) async {
    final AnnotationsMemoire depot = AnnotationsMemoire(
      DonneesSeanceDemo.groupeDemo,
    );
    addTearDown(depot.liberer);
    final ProviderContainer mariam = _conteneurPour(depot);
    addTearDown(mariam.dispose);
    final ProviderContainer zaynab = _conteneurPour(depot);
    addTearDown(zaynab.dispose);
    const Key cleMariam = ValueKey<String>('poste-mariam');
    const Key cleZaynab = ValueKey<String>('poste-zaynab');
    await _monterDeux(
      tester,
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Poste(
            key: cleMariam,
            conteneur: mariam,
            vue: DonneesSeanceDemo.vueTb(
              RoleSeance.eleve,
              SituationTb.autorisationEcrire,
            ),
          ),
          _Poste(
            key: cleZaynab,
            conteneur: zaynab,
            vue: DonneesSeanceDemo.vueTb(
              RoleSeance.eleve,
              SituationTb.autorisationEcrire,
              prenomEleve: DonneesSeanceDemo.eleveAutorisee,
            ),
          ),
        ],
      ),
    );
    final Finder chezM = find.byKey(cleMariam);
    final Finder chezZ = find.byKey(cleZaynab);
    final Finder pageM = find.descendant(of: chezM, matching: _page);
    final Finder pageZ = find.descendant(of: chezZ, matching: _page);
    Finder annulerDe(Finder poste) => find.descendant(
      of: poste,
      matching: find.descendant(
        of: _palette,
        matching: find.byKey(BarreStylet.cleAnnuler),
      ),
    );
    await _ecrireEleve(tester, chezM);
    await _ecrireEleve(tester, chezZ);
    // Mariam trace en haut, Zaynab en bas.
    await _tracer(
      tester,
      84,
      _surPage(tester, pageM, 0.2, 0.2),
      _surPage(tester, pageM, 0.8, 0.2),
    );
    await _tracer(
      tester,
      85,
      _surPage(tester, pageZ, 0.2, 0.6),
      _surPage(tester, pageZ, 0.8, 0.6),
    );
    final List<TraitVectoriel> deux = _traitsDe(depot);
    expect(deux, hasLength(2));
    final String m1 = deux
        .firstWhere((TraitVectoriel x) => x.points.first.y < 0.4)
        .id;
    final String z1 = deux
        .firstWhere((TraitVectoriel x) => x.points.first.y > 0.4)
        .id;
    expect(m1, isNot(z1), reason: 'traits distincts');
    // Chaque salle peint les deux traits de la seance.
    for (final Finder poste in <Finder>[chezM, chezZ]) {
      expect(_ids(_peints(tester, poste)), containsAll(<String>[m1, z1]));
    }
    // Zaynab a ecrit en dernier ; Annuler de Mariam retire SON trait.
    await _taper(tester, annulerDe(chezM));
    expect(_ids(_traitsDe(depot)), <String>[z1]);
    expect(annulerDe(chezM), findsNothing, reason: 'plus rien a annuler');
    expect(annulerDe(chezZ), findsOneWidget);
    // Mariam trace de nouveau, sur la ligne de Zaynab aussi (en bas).
    await _tracer(
      tester,
      86,
      _surPage(tester, pageM, 0.2, 0.62),
      _surPage(tester, pageM, 0.8, 0.62),
    );
    final String m2 = _ids(_traitsDe(depot))
        .firstWhere((String id) => id != z1);
    // Zaynab prend la Gomme et passe sur les deux traits du bas.
    await _taper(
      tester,
      find.descendant(of: chezZ, matching: _entreeCommandes),
    );
    await _taper(
      tester,
      find.descendant(
        of: chezZ,
        matching: find.byKey(BarreStylet.cleOutil(OutilTrait.gomme)),
      ),
    );
    expect(zaynab.read(etatOutilsProvider).outilTrait, OutilTrait.gomme);
    expect(mariam.read(etatOutilsProvider).outilTrait, OutilTrait.stylet);
    await _taper(tester, find.descendant(of: chezZ, matching: _reduire));
    await _tracer(
      tester,
      87,
      _surPage(tester, pageZ, 0.5, 0.5),
      _surPage(tester, pageZ, 0.5, 0.72),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await _attendre(tester);
    expect(_ids(_traitsDe(depot)), <String>[
      m2,
    ], reason: 'la gomme de Zaynab retire son trait, pas celui de Mariam');
    // Annuler de Zaynab rend son trait gomme ; celui de Mariam reste.
    await _taper(tester, annulerDe(chezZ));
    expect(_ids(_traitsDe(depot)).toSet(), <String>{m2, z1});
    // Annuler de Mariam retire son second trait, rien de Zaynab.
    await _taper(tester, annulerDe(chezM));
    expect(_ids(_traitsDe(depot)), <String>[z1]);
    expect(tester.takeException(), isNull);
  });

  // ---------------------------------------------------------------------
  // R-06 (§15 « Changer de page pendant un dessin »), en coquille.
  // ---------------------------------------------------------------------
  testWidgets('R-06 : trait en cours, Page suivante touchee d un second '
      'doigt ; rien n est ancre sur la page 2', (WidgetTester tester) async {
    await _ouvrir(
      tester,
      RoleSeance.enseignant,
      SituationTb.ped03,
      taille: _bureau,
    );
    await _taper(tester, _entreeCommandes);
    await _taper(
      tester,
      find.descendant(
        of: _onglets,
        matching: find.text(t.salle.seance.commandes.ongletOutils),
      ),
    );
    await _taper(tester, _ecrire);
    expect(_outilCoquille(tester), OutilDock.stylet);
    // « Page suivante » est dans les Commandes (onglet Support) : au
    // bureau, le volet reste ouvert a cote de la page, Ecrire arme.
    await _taper(
      tester,
      find.descendant(
        of: _onglets,
        matching: find.text(t.salle.seance.commandes.ongletSupport),
      ),
    );
    expect(_outilCoquille(tester), OutilDock.stylet);
    final Finder suivante = find.descendant(
      of: find.byKey(const ValueKey<String>('pagination-support')),
      matching: find.byKey(const ValueKey<String>('nav-suivant')),
    );
    expect(suivante, findsOneWidget);
    await tester.ensureVisible(suivante);
    await _attendre(tester);
    expect(
      tester.getRect(_page).overlaps(tester.getRect(suivante)),
      isFalse,
      reason: 'la page et Page suivante sont toutes deux atteignables',
    );
    final ContentPosition page1 = DonneesSeanceDemo.traitDemonstration.ancrage;
    final Offset a = _surPage(tester, _page, 0.2, 0.2);
    final Offset b = _surPage(tester, _page, 0.4, 0.2);
    final Offset c = _surPage(tester, _page, 0.7, 0.3);
    final TestPointer doigt = await _commencer(tester, 88, a, b);
    // Second doigt : Page suivante.
    await tester.tap(suivante);
    await tester.pump();
    await tester.pump();
    await _finir(tester, doigt, b, c);
    // La page 2 est montree.
    expect(
      tester.widget<PaginationSupport>(find.byType(PaginationSupport)).page,
      2,
      reason: 'Page suivante a bien agi',
    );
    expect(
      tester
          .widget<SurfacePageFixe>(find.byType(SurfacePageFixe))
          .vue
          .ancrageSurface
          ?.page,
      2,
      reason: 'la page montree est la page 2',
    );
    final List<TraitVectoriel> traits = _traitsDe(_depotCoquille(tester));
    expect(traits, hasLength(1), reason: 'un seul trait, sur la page 1');
    expect(traits.single.ancrage, page1);
    expect(
      traits.single.points.last.x,
      lessThanOrEqualTo(0.4 + 1e-6),
      reason: 'aucun point pose apres le changement de page',
    );
    expect(
      traits.where((TraitVectoriel x) => x.ancrage.page == 2),
      isEmpty,
      reason: 'rien n est ancre sur la page 2',
    );
    expect(
      _peints(tester, find.byType(SalleSeance)),
      isEmpty,
      reason: 'la page 2 ne peint ni le cercle ni le trait de la page 1',
    );
    expect(tester.takeException(), isNull);
  });

  // ---------------------------------------------------------------------
  // UX-03 avec Ecrire arme.
  // ---------------------------------------------------------------------
  testWidgets('UX-03 : Ecrire arme, un trait commence sur la page glisse '
      'jusque sous la barre de l appel masquee ; trait complet, aucune '
      'question Quitter', (WidgetTester tester) async {
    await _ouvrir(tester, RoleSeance.eleve, SituationTb.autorisationEcrire);
    await _taper(tester, _declencheur);
    await _taper(tester, _ecrire);
    await _taper(tester, _reduire);
    expect(_palette, findsOneWidget);
    expect(_outilCoquille(tester), OutilDock.stylet);
    // La barre de l'appel se masque apres le delai.
    final Finder fondu = find.ancestor(
      of: find.byKey(CommandesMasquables.commandesKey),
      matching: find.byType(AnimatedOpacity),
    );
    await tester.pump(CommandesMasquables.delaiParDefaut);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.widget<AnimatedOpacity>(fondu).opacity, 0);
    final Finder quitter = find.byWidgetPredicate(
      (Widget w) => w is BoutonAppel && w.libelle == t.salle.quitter,
    );
    final Offset sousQuitter = tester.getCenter(quitter);
    final Offset a = _surPage(tester, _page, 0.3, 0.6);
    final Offset b = _surPage(tester, _page, 0.4, 0.95);
    // Le doigt part de la page, la quitte vers le bas, finit ou Quitter
    // va apparaitre, s'y leve.
    final TestPointer doigt = await _commencer(tester, 89, a, b);
    // Le contact a revele la barre pendant le trait (UX-01) ; le trait
    // continue.
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      tester.widget<AnimatedOpacity>(fondu).opacity,
      1,
      reason: 'barre revelee pendant le trait',
    );
    await _finir(tester, doigt, b, sousQuitter, pas: 8);
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text(t.salle.seance.quitterQuestion),
      findsNothing,
      reason: 'Quitter ne s active pas au relachement',
    );
    final List<TraitVectoriel> traits = _traitsDe(_depotCoquille(tester));
    expect(traits, hasLength(1), reason: 'le trait est pris');
    final TraitVectoriel trait = traits.single;
    expect(trait.ancrage, DonneesSeanceDemo.traitDemonstration.ancrage);
    expect(trait.points.first.y, closeTo(0.6, 0.02));
    expect(
      trait.points.last.y,
      greaterThanOrEqualTo(0.95 - 0.02),
      reason: 'le trait continue jusqu au bord de la page',
    );
    expect(_ids(_peints(tester, find.byType(SalleSeance))), contains(trait.id));
    expect(find.byType(SalleSeance), findsOneWidget, reason: 'toujours la');
    // Temoin : au meme endroit, un toucher neuf atteint bien Quitter (la
    // question s'ouvre) ; le trait n'a rien laisse de plus.
    await tester.tapAt(sousQuitter);
    await _attendre(tester);
    expect(find.text(t.salle.seance.quitterQuestion), findsOneWidget);
    expect(_traitsDe(_depotCoquille(tester)), hasLength(1));
    expect(tester.takeException(), isNull);
  });
}
