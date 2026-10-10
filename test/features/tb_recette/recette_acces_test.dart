// TB-12, lot T3-acces : recette de la sortie, des permissions, du clavier,
// du lecteur d'ecran, du mouvement reduit et des observateurs (plan V2 §15
// « Clavier et lecteur d'ecran », « Mouvement reduit », « Profil
// observateur » ; §23 UX-07, UX-09, UX-21, UX-22, UX-23 ; R-15, R-16).
//
// Chaque scenario part de la VRAIE coquille (`routeurProvider`) : /demo/salle,
// le lien de la situation, puis les vrais boutons, au doigt ou au clavier
// (K-07). Aucun serveur : la demonstration garde son etat en memoire. Ce qui
// exige un serveur (fin de la seance pour les autres, permission reelle du
// navigateur) reste « non verifiable sans BR-1 » dans le rapport.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/accessibilite/commandes_masquables.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/mouvement/envol_vers_cible.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/barre_precedent_suivant.dart';
import 'package:rewayah_academy/core/widgets/permanent_notice.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/salle_observateur_demo.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/barre_support.dart';
import 'package:rewayah_academy/features/salle_seance/bibliotheque_seance.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/outils_enseignement.dart';
import 'package:rewayah_academy/features/salle_seance/resultat_seance.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/surface_page_fixe.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/salle_seance/zone_support.dart';
import 'package:rewayah_academy/features/tc_catalogue/surface_bibliotheque.dart';
import 'package:rewayah_academy/features/tc_dock/barre_stylet.dart';

import '../../router/support_routeur.dart';

const Size _telephone = Size(390, 844);
const Size _bureau = Size(1440, 900);

final Finder _declencheur = find.byKey(DeclencheurCommandes.cle);
final Finder _contenu = find.byKey(CommandesPedagogiques.cle);
final Finder _bibliotheque = find.byKey(CommandesPedagogiques.cleBibliotheque);
final Finder _menu = find.byKey(CommandesPedagogiques.cleMenu);
final Finder _catalogue = find.byType(SurfaceBibliotheque);
final Finder _apercu = find.byKey(BibliothequeSeance.cleApercu);
final Finder _presenter = find.byKey(BibliothequeSeance.clePresenter);
final Finder _page = find.byKey(SurfacePageFixe.clePage);
final Finder _feuille = find.byKey(SurfacePageFixe.cleFeuille);
final Finder _copie = find.byKey(EnvolVersCible.cle);
final Finder _micro = find.byKey(const ValueKey<String>('bouton-micro'));
final Finder _texteMicroBloque = find.byKey(
  const ValueKey<String>('texte-micro-bloque'),
);
final Finder _continuerSansMicro = find.byKey(
  const ValueKey<String>('micro-bloque-continuer'),
);
final Finder _question = find.text(t.salle.seance.quitterQuestion);

/// Le bouton Quitter de la barre de l'appel.
final Finder _quitter = find.descendant(
  of: find.byKey(CommandesMasquables.commandesKey),
  matching: find.text(t.salle.quitter),
);

const String _titreInitial = 'Les bonnes manières';
const String _autre = 'Fiche de mémorisation';

/// Ouvre /demo/salle par le vrai routeur, puis tape le lien [cle].
Future<GoRouter> _ouvrirLien(
  WidgetTester tester,
  String cle, {
  Size taille = _telephone,
}) async {
  final GoRouter routeur = await monterRouteur(
    tester,
    Routes.demoSalle,
    taille: taille,
  );
  final Finder lien = find.byKey(ValueKey<String>(cle));
  await tester.ensureVisible(lien);
  await tester.pump();
  await tester.tap(lien);
  await stabiliser(tester);
  expect(tester.takeException(), isNull);
  return routeur;
}

/// Ouvre la salle de la situation Supports et tableau depuis la liste.
Future<GoRouter> _ouvrir(
  WidgetTester tester,
  RoleSeance role,
  SituationTb situation, {
  Size taille = _telephone,
}) async {
  final GoRouter routeur = await _ouvrirLien(
    tester,
    'lien-${role.name}-tb-${situation.name}',
    taille: taille,
  );
  expect(lieu(routeur), adresseDemoSalleTb(role, situation));
  return routeur;
}

/// Un geste, puis le cadre du retour du focus et l'animation.
Future<void> _attendre(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Vrai si le focus clavier est sur [cible] ou dans l'un de ses descendants.
bool _focusDans(Finder cible) {
  final BuildContext? c = FocusManager.instance.primaryFocus?.context;
  if (c == null) return false;
  final Set<Element> elements = cible.evaluate().toSet();
  if (elements.contains(c)) return true;
  bool dedans = false;
  c.visitAncestorElements((Element e) {
    if (elements.contains(e)) {
      dedans = true;
      return false;
    }
    return true;
  });
  return dedans;
}

/// Tab jusqu'a [cible] (au plus [max] appuis) ; echoue sinon.
Future<void> _tabVers(
  WidgetTester tester,
  Finder cible,
  String quoi, {
  int max = 120,
}) async {
  for (int i = 0; i < max && !_focusDans(cible); i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  expect(
    _focusDans(cible),
    isTrue,
    reason:
        '$quoi atteint au clavier (focus : '
        '${FocusManager.instance.primaryFocus?.debugLabel})',
  );
}

/// Le nom lu de la commande qui a le focus : le noeud semantique le plus
/// proche qui porte un libelle, en remontant depuis le focus.
String _nomLu(WidgetTester tester, Finder cible) {
  final SemanticsNode noeud = tester.getSemantics(cible);
  SemanticsNode? n = noeud;
  while (n != null && n.label.trim().isEmpty) {
    n = n.parent;
  }
  return n?.label.trim() ?? '';
}

/// Un nom lu « comprehensible » : non vide, au moins une lettre, ni un
/// identifiant technique (cle `mot-mot`, `mot_mot`, camelCase, nom de type).
void _nomComprehensible(String nom, String quoi) {
  expect(nom, isNotEmpty, reason: '$quoi sans nom lu');
  expect(RegExp(r'\p{L}', unicode: true).hasMatch(nom), isTrue, reason: nom);
  expect(
    RegExp(r'[a-z0-9]+[-_][a-z0-9]').hasMatch(nom),
    isFalse,
    reason: '$quoi : identifiant technique lu « $nom »',
  );
  expect(
    RegExp(r'\b[a-z]+[A-Z][A-Za-z]*\b').hasMatch(nom),
    isFalse,
    reason: '$quoi : nom de code lu « $nom »',
  );
  for (final String interdit in <String>['null', 'Key', 'Widget', 'cle']) {
    expect(
      nom.contains(interdit),
      isFalse,
      reason: '$quoi : « $interdit » lu dans « $nom »',
    );
  }
}

/// Le titre ecrit sur la page presentee a la classe.
Finder _pageAvecTitre(String titre) =>
    find.descendant(of: _page, matching: find.text(titre));

/// Les noms lus de toutes les commandes activables de l'ecran (noeuds
/// semantiques qui acceptent « toucher »), tries : la signature des
/// commandes que voit le lecteur d'ecran.
List<String> _commandes(WidgetTester tester) {
  final List<String> noms = <String>[];
  void visiter(SemanticsNode n) {
    final SemanticsData d = n.getSemanticsData();
    if (d.hasAction(SemanticsAction.tap) && !d.flagsCollection.isHidden) {
      noms.add(d.label);
    }
    n.visitChildren((SemanticsNode c) {
      visiter(c);
      return true;
    });
  }

  visiter(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return noms..sort();
}

void main() {
  // --- UX-07 : panneau ouvert, reveler, Quitter, confirmer ------------------

  group(
    'UX-07 : panneau pedagogique ouvert, la sortie personnelle aboutit',
    () {
      testWidgets('enseignant 390 : Commandes ouvertes, barre revelee, '
          'Quitter confirme, le routeur quitte la salle', (
        WidgetTester tester,
      ) async {
        final GoRouter routeur = await _ouvrir(
          tester,
          RoleSeance.enseignant,
          SituationTb.cmd01,
        );
        expect(_contenu, findsOneWidget, reason: 'CMD-01 : Commandes ouvertes');
        // Reveler la barre : un doigt sur le contenu si elle s'est masquee.
        await tester.pump(CommandesMasquables.delaiParDefaut);
        await _attendre(tester);
        if (_quitter.hitTestable().evaluate().isEmpty) {
          await tester.tapAt(tester.getCenter(find.byType(ZoneSupport).first));
          await _attendre(tester);
        }
        expect(_quitter.hitTestable(), findsOneWidget);
        expect(_contenu, findsOneWidget, reason: 'le panneau reste ouvert');
        await tester.tap(_quitter);
        await _attendre(tester);
        expect(_question, findsOneWidget);
        // Sortie personnelle : deux actions, « Rester » et « Quitter et ouvrir
        // le cahier » ; aucune action sur la classe (ni terminer, ni
        // prolonger).
        expect(find.text(t.salle.seance.rester), findsOneWidget);
        expect(find.text(t.salle.seance.quitterCahier), findsOneWidget);
        expect(
          find.text(t.salle.seance.quitterCahierConsequence),
          findsOneWidget,
        );
        expect(find.textContaining('erminer'), findsNothing);
        expect(find.textContaining('rolonger'), findsNothing);
        await tester.tap(find.text(t.salle.seance.quitterCahier));
        await stabiliser(tester);
        expect(tester.takeException(), isNull);
        // La demonstration n'a pas de cahier : la sortie ramene a la liste.
        expect(lieu(routeur), Routes.demoSalle);
        expect(find.byType(ZoneSupport), findsNothing);
        expect(_question, findsNothing);
        expect(
          find.byKey(const ValueKey<String>('lien-enseignant-tb-cmd01')),
          findsOneWidget,
        );
      });

      testWidgets('enseignant 390 : « Rester » garde la salle, le panneau et '
          'la page', (WidgetTester tester) async {
        final GoRouter routeur = await _ouvrir(
          tester,
          RoleSeance.enseignant,
          SituationTb.cmd01,
        );
        await tester.tap(_quitter);
        await _attendre(tester);
        await tester.tap(find.text(t.salle.seance.rester));
        await stabiliser(tester);
        expect(_question, findsNothing);
        expect(
          lieu(routeur),
          adresseDemoSalleTb(RoleSeance.enseignant, SituationTb.cmd01),
        );
        expect(_contenu, findsOneWidget);
        expect(find.byType(ZoneSupport), findsWidgets);
      });

      for (final RoleSeance role in <RoleSeance>[
        RoleSeance.eleve,
        RoleSeance.guidee,
      ]) {
        testWidgets('${role.name} 390 : Commandes ouvertes, Quitter confirme, '
            'ecran de sortie personnel puis retour', (
          WidgetTester tester,
        ) async {
          final GoRouter routeur = await _ouvrir(
            tester,
            role,
            SituationTb.ped03,
          );
          if (_contenu.evaluate().isEmpty) {
            await tester.tap(_declencheur);
            await _attendre(tester);
          }
          expect(_contenu, findsOneWidget, reason: 'Commandes ouvertes');
          await tester.pump(CommandesMasquables.delaiParDefaut);
          await _attendre(tester);
          if (_quitter.hitTestable().evaluate().isEmpty) {
            await tester.tapAt(
              tester.getCenter(find.byType(ZoneSupport).first),
            );
            await _attendre(tester);
          }
          await tester.tap(_quitter);
          await _attendre(tester);
          expect(_question, findsOneWidget);
          expect(find.text(t.salle.seance.quitterConsequence), findsOneWidget);
          expect(find.textContaining('erminer'), findsNothing);
          // La confirmation est le dernier « Quitter » monte (la feuille).
          await tester.tap(find.text(t.salle.quitter).last);
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          // Sortie volontaire : CLV-09, l'issue « quittee », pas la fin de
          // la seance.
          final ResultatSeance resultat = tester.widget(
            find.byType(ResultatSeance),
          );
          expect(resultat.issue, IssueSeance.quittee);
          expect(find.byType(ZoneSupport), findsNothing);
          expect(lieu(routeur), adresseDemoSalleTb(role, SituationTb.ped03));
          // Le retour de l'ecran de sortie ramene a la liste.
          final Finder retour = find.descendant(
            of: find.byType(ResultatSeance),
            matching: find.byType(Pressable),
          );
          expect(retour, findsWidgets);
          await tester.tap(retour.first);
          await stabiliser(tester);
          expect(lieu(routeur), Routes.demoSalle);
        });
      }
    },
  );

  // --- UX-23 : micro bloque, feuille, Continuer sans micro ------------------

  group('UX-23 : permission micro refusee, chemin de recuperation, aucun '
      'faux micro actif', () {
    for (final RoleSeance role in RoleSeance.values) {
      testWidgets('${role.name} 390', (WidgetTester tester) async {
        final GoRouter routeur = await _ouvrirLien(
          tester,
          'lien-${role.name}-${EtatDemoSalle.microBloque.name}',
        );
        expect(
          lieu(routeur),
          adresseDemoSalle(role, EtatDemoSalle.microBloque),
        );
        // Etat reel : coupe avant tout geste.
        expect(find.text(t.salle.microOuvert), findsNothing);
        await tester.tap(_micro);
        await stabiliser(tester);
        expect(_texteMicroBloque, findsOneWidget);
        expect(
          find.descendant(
            of: _continuerSansMicro,
            matching: find.text(t.salle.secours.continuerSansMicro),
          ),
          findsOneWidget,
        );
        // Le geste n'a rien bascule.
        expect(find.text(t.salle.microOuvert), findsNothing);
        await tester.tap(_continuerSansMicro);
        await stabiliser(tester);
        expect(_texteMicroBloque, findsNothing);
        // Focus rendu au bouton Micro, toujours coupe : a l'ecran ET dans
        // l'etat local que la salle donnerait au moteur.
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'bouton-micro');
        expect(find.text(t.salle.microOuvert), findsNothing);
        expect(
          tester
              .widget<SalleSeance>(find.byType(SalleSeance))
              .local
              .microOuvert,
          isFalse,
          reason: 'Continuer sans micro laisse le micro coupe',
        );
        if (role != RoleSeance.guidee) {
          expect(find.text(t.salle.microCoupe), findsWidgets);
        }
        // Un second geste rouvre l'explication : jamais un micro actif.
        await tester.tap(_micro);
        await stabiliser(tester);
        expect(_texteMicroBloque, findsOneWidget);
        expect(find.text(t.salle.microOuvert), findsNothing);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await stabiliser(tester);
        expect(_texteMicroBloque, findsNothing);
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'bouton-micro');
        expect(find.text(t.salle.microOuvert), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  });

  // --- UX-09 / R-15 : lecteur d'ecran, texte x2, clavier --------------------

  testWidgets('UX-09 / R-15 : lecteur d\'ecran et texte x2, au clavier : '
      'Commandes > Bibliotheque > apercu > Presenter > Ranger, chaque '
      'commande nommee', (WidgetTester tester) async {
    // Revue TB-R 10/10, n16 : la poignee est liberee meme si une assertion
    // echoue avant la fin (`finally`) ; `addTearDown` passerait apres la
    // verification de fin de test, qui la trouverait encore active.
    final SemanticsHandle semantique = tester.ensureSemantics();
    try {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await _ouvrir(
        tester,
        RoleSeance.enseignant,
        SituationTb.ped03,
        taille: _bureau,
      );
      expect(_pageAvecTitre(_titreInitial), findsOneWidget);
      // Lecteur d'ecran : la barre ne se masque jamais d'elle-meme.
      await tester.pump(CommandesMasquables.delaiParDefaut * 2);
      await _attendre(tester);
      expect(_quitter.hitTestable(), findsOneWidget);
      final List<String> lus = <String>[];

      // Commandes : Tab, nom lu, Entree ouvre ; Echap referme.
      await _tabVers(tester, _declencheur, 'Commandes');
      lus.add(_nomLu(tester, _declencheur));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _attendre(tester);
      expect(_contenu, findsOneWidget, reason: 'Entree ouvre les Commandes');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _attendre(tester);
      expect(_contenu, findsNothing, reason: 'Echap referme les Commandes');
      // Le focus revient au declencheur (ou reste atteignable a Tab).
      await _tabVers(tester, _declencheur, 'Commandes apres Echap');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _attendre(tester);
      expect(_contenu, findsOneWidget);

      // Bibliotheque.
      await _tabVers(tester, _bibliotheque, 'Bibliotheque');
      lus.add(_nomLu(tester, _bibliotheque));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        _catalogue,
        findsOneWidget,
        reason: 'Entree ouvre la Bibliotheque',
      );

      // Apercu : la carte d'un autre support.
      final Finder carte = find.ancestor(
        of: find.descendant(of: _catalogue, matching: find.text(_autre)),
        matching: find.byType(Pressable),
      );
      await _tabVers(tester, carte, 'la carte « $_autre »');
      lus.add(_nomLu(tester, carte.first));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(_apercu, findsOneWidget, reason: 'Entree ouvre l\'apercu');
      // L'apercu est personnel : la classe garde sa page (UX-17).
      expect(_pageAvecTitre(_titreInitial), findsOneWidget);

      // Presenter.
      await _tabVers(tester, _presenter, 'Presenter');
      lus.add(_nomLu(tester, _presenter));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_pageAvecTitre(_autre), findsOneWidget, reason: 'presente');
      expect(_pageAvecTitre(_titreInitial), findsNothing);

      // Ranger : Commandes > menu du support > « Ranger dans la
      // bibliotheque ».
      if (_contenu.evaluate().isEmpty) {
        await _tabVers(tester, _declencheur, 'Commandes (rangement)');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await _attendre(tester);
      }
      await _tabVers(tester, _menu, 'menu du support');
      lus.add(_nomLu(tester, _menu));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      final Finder ranger = find.ancestor(
        of: find.text(t.salle.seance.rangement.ranger).last,
        matching: find.byWidgetPredicate((Widget w) => w is PopupMenuItem),
      );
      expect(ranger, findsOneWidget, reason: 'le menu est ouvert');
      for (int i = 0; i < 12 && !_focusDans(ranger); i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
      }
      expect(_focusDans(ranger), isTrue, reason: 'Ranger atteint au clavier');
      lus.add(_nomLu(tester, ranger));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_page, findsNothing, reason: 'range');
      expect(_feuille, findsOneWidget, reason: 'tableau libre distinct');

      // Chaque commande atteinte a un nom lu comprehensible.
      expect(lus, hasLength(6));
      final List<String> attendus = <String>[
        'Commandes',
        'Bibliotheque',
        'carte',
        'Presenter',
        'menu',
        'Ranger',
      ];
      for (int i = 0; i < lus.length; i++) {
        _nomComprehensible(lus[i], attendus[i]);
      }
      // Les noms exacts du §20 : ce que dit le lecteur d'ecran.
      expect(lus[0], t.salle.seance.commandes.declencheurSemantique);
      expect(lus[1], t.salle.seance.commandes.bibliotheque);
      // `startsWith` tolere la double lecture connue de la carte du catalogue
      // (TB_RAPPORT §d n. 22) ; passer a `equals` une fois ce doublon corrige.
      expect(lus[2], startsWith(_autre));
      expect(lus[3], t.salle.seance.bibliotheque.presenter);
      expect(lus[4], t.salle.seance.rangement.menuSupport);
      expect(lus[5], t.salle.seance.rangement.ranger);
    } finally {
      semantique.dispose();
    }
  });

  // --- UX-22 / R-16 : mouvement reduit ---------------------------------------

  group('UX-22 / R-16 : mouvement reduit, memes fonctions sans animation '
      'obligatoire', () {
    // Revue TB-R 10/10, n13 : le panneau n'a aucune animation, meme sans
    // mouvement reduit ; « sans glissement » est une garde de
    // non-regression, pas une preuve du mouvement reduit. La partie
    // rangement (aucune copie animee) depend, elle, du reglage.
    testWidgets('enseignant 390 : Commandes sans glissement (garde de '
        'non-regression), rangement complet sans copie animee, reprise', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await _ouvrir(tester, RoleSeance.enseignant, SituationTb.ped03);
      // Le panneau s'ouvre en UN cadre : sa place ne change plus ensuite.
      await tester.tap(_declencheur);
      await tester.pump();
      await tester.pump();
      expect(_contenu, findsOneWidget);
      final Rect ouvert = tester.getRect(_contenu);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.getRect(_contenu), ouvert, reason: 'aucun glissement');
      // Ranger : aucune copie montee, a aucun moment.
      await tester.ensureVisible(_menu);
      await tester.pumpAndSettle();
      await tester.tap(_menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.salle.seance.rangement.ranger).last);
      await tester.pump();
      expect(_copie, findsNothing);
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        expect(_copie, findsNothing, reason: 'cadre $i');
      }
      expect(_page, findsNothing);
      expect(_feuille, findsOneWidget);
      // Meme fonction : Bibliotheque > carte rangee > Presenter.
      await tester.pumpAndSettle();
      if (_bibliotheque.evaluate().isEmpty) {
        await tester.tap(_declencheur);
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(_bibliotheque);
      await tester.pumpAndSettle();
      await tester.tap(_bibliotheque);
      await tester.pumpAndSettle();
      final Finder reprise = find.descendant(
        of: _catalogue,
        matching: find.textContaining(
          t.salle.seance.rangement.reprise(page: 1, total: 1).split(' ').first,
        ),
      );
      expect(reprise, findsWidgets);
      await tester.ensureVisible(reprise.first);
      await tester.pumpAndSettle();
      await tester.tap(reprise.first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(_presenter);
      await tester.pumpAndSettle();
      await tester.tap(_presenter);
      await tester.pumpAndSettle();
      expect(_page, findsOneWidget, reason: 'repris');
      expect(_pageAvecTitre(_titreInitial), findsOneWidget);
      expect(_copie, findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('eleve, visite : point d\'enregistrement fixe, sans '
        'clignotement', (WidgetTester tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await _ouvrirLien(
        tester,
        'lien-${RoleSeance.eleve.name}-${EtatDemoSalle.visite.name}',
      );
      final Finder point = find.byType(PointEnregistrement);
      expect(point, findsWidgets, reason: 'la mention de visite est montree');
      final Finder clignote = find.byWidgetPredicate(
        (Widget w) => w is PointEnregistrement && w.clignote,
      );
      expect(clignote, findsWidgets, reason: 'le point clignoterait');
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 250));
        // Aucun fondu dans le point : il est peint fixe (le fondu est
        // construit dans PointEnregistrement, donc cherche en descendant).
        expect(
          find.descendant(of: clignote, matching: find.byType(FadeTransition)),
          findsNothing,
          reason: 'instant $i',
        );
      }
    });

    testWidgets('temoin : sans mouvement reduit, le meme point clignote', (
      WidgetTester tester,
    ) async {
      await _ouvrirLien(
        tester,
        'lien-${RoleSeance.eleve.name}-${EtatDemoSalle.visite.name}',
      );
      final Finder clignote = find.byWidgetPredicate(
        (Widget w) => w is PointEnregistrement && w.clignote,
      );
      expect(
        find.descendant(of: clignote, matching: find.byType(FadeTransition)),
        findsWidgets,
      );
    });

    testWidgets('controleur : « En direct » sans battement (point fixe)', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await _ouvrirLien(
        tester,
        'lien-obs-${ObservateurDemo.controleur.name}-tb-'
        '${SituationTb.ped03.name}',
        taille: _bureau,
      );
      expect(find.text(t.etat.enDirect), findsWidgets);
      expect(
        find.byKey(const ValueKey<String>('pastille-direct-point')),
        findsWidgets,
      );
      for (int i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        // Le halo qui bat n'est jamais peint.
        expect(
          find.byKey(const ValueKey<String>('pastille-direct-halo')),
          findsNothing,
          reason: 'instant $i',
        );
      }
    });
  });

  testWidgets('UX-22 temoin : sans mouvement reduit, le halo de « En '
      'direct » bat', (WidgetTester tester) async {
    await _ouvrirLien(
      tester,
      'lien-obs-${ObservateurDemo.controleur.name}-tb-'
      '${SituationTb.ped03.name}',
      taille: _bureau,
    );
    bool vu = false;
    for (int i = 0; i < 8 && !vu; i++) {
      vu = find
          .byKey(const ValueKey<String>('pastille-direct-halo'))
          .evaluate()
          .isNotEmpty;
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(vu, isTrue, reason: 'le temoin doit voir le battement');
    await tester.pump(const Duration(seconds: 6));
  });

  // --- UX-21 : observateurs ---------------------------------------------------

  group('UX-21 : observateur, droits inchanges, notices du role', () {
    for (final ObservateurDemo o in ObservateurDemo.values) {
      for (final Size taille in <Size>[_telephone, _bureau]) {
        testWidgets('${o.name} ${taille.width.toInt()} : aucune commande de '
            'dessin, page, rangement ni focus ; medias inchanges', (
          WidgetTester tester,
        ) async {
          // Reference : la meme salle sans presentation (SAL-00).
          await _ouvrirLien(
            tester,
            'lien-obs-${o.name}-tb-${SituationTb.sal00.name}',
            taille: taille,
          );
          final List<String> reference = _commandes(tester);
          expect(reference, isNotEmpty, reason: 'Quitter au moins');

          final GoRouter routeur = await _ouvrirLien(
            tester,
            'lien-obs-${o.name}-tb-${SituationTb.ped03.name}',
            taille: taille,
          );
          expect(
            lieu(routeur),
            adresseDemoSalleObservateur(o, SituationTb.ped03),
          );
          final Finder presentation = find.byKey(
            const ValueKey<String>('presentation-lue'),
          );
          expect(presentation, findsOneWidget);
          // Aucune commande d'agrandissement ou de focus proposee.
          for (final Key cle in <Key>[
            const ValueKey<String>('bouton-agrandir'),
            const ValueKey<String>('bouton-agrandir-barre'),
            CommandesPedagogiques.cleFocus,
          ]) {
            expect(find.byKey(cle), findsNothing, reason: '$cle');
          }
          // Un double toucher sur la page (geste d'agrandissement) ne
          // change rien aux droits.
          final Offset centre = tester.getCenter(presentation);
          await tester.tapAt(centre);
          await tester.pump(const Duration(milliseconds: 80));
          await tester.tapAt(centre);
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          for (final Type interdit in <Type>[
            PaginationSupport,
            BarrePrecedentSuivant,
            ZoomLocal,
            DeclencheurCommandes,
            CommandesPedagogiques,
            OutilsEnseignement,
            BarreStylet,
            BibliothequeSeance,
          ]) {
            expect(find.byType(interdit), findsNothing, reason: '$interdit');
          }
          for (final String mot in <String>[
            t.salle.seance.commandes.declencheur,
            t.salle.seance.commandes.bibliotheque,
            t.salle.seance.commandes.focus,
            t.salle.seance.rangement.ranger,
          ]) {
            expect(find.text(mot), findsNothing, reason: mot);
          }
          // Micro et Camera : exactement les commandes du role sans
          // presentation (aucune ajoutee, aucune retiree).
          final List<String> commandes = _commandes(tester);
          expect(commandes, reference);
          // Chaque commande est un noeud propre, lu seul : jamais l'ecran
          // entier fondu en un « bouton » (contre-epreuve du repere de
          // demonstration, TB-12).
          for (final String nom in commandes) {
            expect(
              nom.contains(t.commun.demonstration.repereLu),
              isFalse,
              reason: nom,
            );
            expect(
              nom.contains(DonneesSeanceDemo.supportPageFixe.titre),
              isFalse,
              reason: nom,
            );
            expect(nom, contains(t.salle.quitter), reason: 'seule Quitter');
          }
          expect(commandes, hasLength(1), reason: 'Quitter, seule commande');
          // Notices du role.
          if (o == ObservateurDemo.controleur) {
            expect(find.byType(PermanentNotice), findsNothing);
            expect(find.text(t.salle.bandeauPermanent), findsNothing);
            expect(
              find.textContaining(t.salle.bandeauControleTitre),
              findsWidgets,
            );
          } else {
            expect(find.byType(PermanentNotice), findsOneWidget);
            expect(
              find.textContaining(t.salle.observationMuetteTitre),
              findsWidgets,
            );
          }
        });
      }
    }
  });
}
