// TB-RC, lot L4-semantique : corrections de la revue TB-R (M1, m7, m10,
// m11, m12, m23, m27, m28) et des defauts de TB_RAPPORT §d (n. 8, 13, 14,
// 22, 23 ; reste a de TB-10), cote eleve, guidee, observateurs et
// semantique. Chaque test mesure le RENDU ; M1 est rejoue depuis la vraie
// coquille (K-07) : /demo/salle, lien de la situation, vrais boutons.

import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart'
    show TitreEnseignant;
import 'package:rewayah_academy/core/tc_telechargement/port_etat_offline.dart'
    show EtatOffline;
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';
import 'package:rewayah_academy/features/demo/salle_observateur_demo.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart'
    show OutilEnseignement;
import 'package:rewayah_academy/features/salle_seance/capsule_seance.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/outils_enseignement.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/surface_page_fixe.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/tc_catalogue/carte_ressource.dart';
import 'package:rewayah_academy/features/tc_catalogue/surface_bibliotheque.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../router/support_routeur.dart';

const Size _telephone = Size(390, 844);
const Size _bureau = Size(1440, 900);

final Finder _page = find.byKey(SurfacePageFixe.clePage);
final Finder _etatRecu = find.byKey(SurfacePageFixe.cleSupportRecu);
final Finder _reessayer = find.byKey(SurfacePageFixe.cleReessayer);
final Finder _enAttente = find.byKey(SurfacePageFixe.cleEnAttente);

/// K-07 : la salle de [situation], ouverte depuis la liste de /demo/salle.
Future<GoRouter> _ouvrir(
  WidgetTester tester,
  RoleSeance role,
  SituationTb situation, {
  Size taille = _telephone,
}) async {
  final GoRouter routeur = await monterRouteur(
    tester,
    Routes.demoSalle,
    taille: taille,
  );
  final Finder lien = find.byKey(
    ValueKey<String>('lien-${role.name}-tb-${situation.name}'),
  );
  await tester.ensureVisible(lien);
  await tester.pump();
  await tester.tap(lien);
  await stabiliser(tester);
  expect(lieu(routeur), adresseDemoSalleTb(role, situation));
  expect(find.byType(SalleSeance), findsOneWidget);
  return routeur;
}

/// Une page de demonstration montee seule (captures, semantique).
Future<void> _monter(
  WidgetTester tester,
  Widget page, {
  Size taille = _telephone,
  double texte = 1,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          builder: (BuildContext contexte, Widget? app) => MediaQuery(
            data: MediaQuery.of(contexte)
                .copyWith(textScaler: TextScaler.linear(texte)),
            child: app!,
          ),
          home: page,
        ),
      ),
    ),
  );
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Le nom lu du noeud qui porte [cible].
SemanticsNode _noeud(WidgetTester tester, Finder cible) =>
    tester.getSemantics(cible);

/// Tous les noeuds de l'arbre semantique.
List<SemanticsNode> _tous(WidgetTester tester) {
  final List<SemanticsNode> noeuds = <SemanticsNode>[];
  void visiter(SemanticsNode n) {
    noeuds.add(n);
    n.visitChildren((SemanticsNode e) {
      visiter(e);
      return true;
    });
  }

  visiter(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return noeuds;
}

void main() {
  // Les vraies polices du depot : les mesures de mots (tuiles, panneau)
  // sont celles de l'application, pas celles de la police de test.
  setUpAll(chargerPolicesDuDepot);

  // --- M1 : les deux etats de l'eleve du §12 ---------------------------------

  group('M1 (§12) : le support recu chez l\'eleve, depuis la coquille', () {
    testWidgets('eleve, « Le support arrive » : la phrase exacte, le dernier '
        'contenu marque en attente, aucune commande pour quitter', (
      WidgetTester tester,
    ) async {
      await _ouvrir(tester, RoleSeance.eleve, SituationTb.supportArrive);
      expect(_etatRecu, findsOneWidget);
      expect(
        find.descendant(
          of: _etatRecu,
          matching: find.text(t.salle.seance.surface.supportArrive),
        ),
        findsOneWidget,
      );
      expect(t.salle.seance.surface.supportArrive, 'Le support arrive…');
      // Le dernier contenu reste a l'ecran, marque en attente.
      expect(_page, findsOneWidget);
      expect(_enAttente, findsOneWidget);
      expect(tester.widget<Opacity>(_enAttente).opacity, lessThan(1));
      // Rien a reessayer pendant le chargement.
      expect(_reessayer, findsNothing);
      // L'etat est sur la page, dans la surface (rien ne la quitte).
      final Rect zone = tester.getRect(find.byType(SurfacePageFixe));
      final Rect etat = tester.getRect(_etatRecu);
      expect(
        zone.contains(etat.topLeft) && zone.contains(etat.bottomRight),
        isTrue,
        reason: 'etat $etat dans la surface $zone',
      );
      expect(tester.takeException(), isNull);
    });

    for (final (RoleSeance role, Size taille) in <(RoleSeance, Size)>[
      (RoleSeance.eleve, _telephone),
      (RoleSeance.guidee, _bureau),
    ]) {
      testWidgets('${role.name} ${taille.width.toInt()}, « Le support ne '
          's\'affiche pas. » : cause et Reessayer, sans quitter la seance', (
        WidgetTester tester,
      ) async {
        final GoRouter routeur = await _ouvrir(
          tester,
          role,
          SituationTb.ressourceIndisponible,
          taille: taille,
        );
        final String adresse = lieu(routeur);
        expect(
          t.salle.seance.surface.supportIndisponible,
          "Le support ne s'affiche pas.",
        );
        expect(
          find.descendant(
            of: _etatRecu,
            matching: find.text(t.salle.seance.surface.supportIndisponible),
          ),
          findsOneWidget,
        );
        // K-59 : la cause probable et quoi faire.
        expect(
          find.descendant(
            of: _etatRecu,
            matching: find.text(
              t.salle.seance.surface.supportIndisponibleDetail,
            ),
          ),
          findsOneWidget,
        );
        expect(_reessayer.hitTestable(), findsOneWidget);
        expect(
          tester.getSemantics(_reessayer).label,
          t.salle.seance.surface.reessayerSemantique,
        );
        // Reessayer : le support revient, la salle reste la meme.
        await tester.tap(_reessayer);
        await stabiliser(tester);
        expect(_etatRecu, findsNothing);
        expect(_enAttente, findsNothing);
        expect(_page, findsOneWidget);
        expect(lieu(routeur), adresse);
        expect(find.byType(SalleSeance), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    test('l\'enseignant ne recoit pas ces etats : ni situation, ni phrase', () {
      for (final SituationTb s in <SituationTb>[
        SituationTb.supportArrive,
        SituationTb.ressourceIndisponible,
      ]) {
        expect(situationsTb(RoleSeance.enseignant), isNot(contains(s)));
        expect(situationsTb(RoleSeance.eleve), contains(s));
        expect(situationsTb(RoleSeance.guidee), contains(s));
        final VueSeance prof = DonneesSeanceDemo.vueTb(
          RoleSeance.enseignant,
          s,
        );
        expect(prof.texteSupportRecu, isNull);
        expect(prof.supportEnAttente, isFalse);
      }
      // Hors des deux situations, l'eleve ne voit rien.
      expect(
        DonneesSeanceDemo.vueTb(
          RoleSeance.eleve,
          SituationTb.ped03,
        ).texteSupportRecu,
        isNull,
      );
    });
  });

  // --- m7, m11 : la page, noeud propre et region vivante ---------------------

  group('m7 et m11 : la page a son propre noeud, annonce a qui la recoit', () {
    for (final RoleSeance role in RoleSeance.values) {
      testWidgets(role.name, (WidgetTester tester) async {
        await _monter(
          tester,
          DemoSallePage(role: role, situation: SituationTb.ped03),
        );
        final SupportPageFixe page = DonneesSeanceDemo.supportPageFixe;
        final String nom = t.salle.seance.surface.page(
          titre: page.titre,
          page: page.page,
          pages: page.total,
        );
        final SemanticsNode noeud = _noeud(tester, _page);
        // Le noeud de la page ne porte QUE la page (rien de l'en-tete).
        expect(noeud.label, nom);
        expect(noeud.flagsCollection.isImage, isTrue);
        expect(noeud.flagsCollection.isHeader, isFalse);
        // Aucun autre noeud ne recopie la page (ni l'en-tete, ni l'ecran).
        final List<SemanticsNode> avecPage = <SemanticsNode>[
          for (final SemanticsNode n in _tous(tester))
            if (n.label.contains(nom)) n,
        ];
        expect(avecPage, hasLength(1), reason: '$avecPage');
        // m11 : annonce discretement a l'eleve et a la guidee, jamais a
        // l'enseignant qui la change.
        expect(
          noeud.flagsCollection.isLiveRegion,
          role != RoleSeance.enseignant,
        );
      });
    }

    testWidgets('la vignette video est un noeud propre', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const DemoSallePage(
          role: RoleSeance.eleve,
          situation: SituationTb.ped01,
        ),
      );
      final Finder video = find.byKey(const ValueKey<String>('vignette-video'));
      expect(video, findsOneWidget);
      expect(
        _noeud(tester, video).label,
        t.salle.seance.videoDe(
          nom: DonneesSeanceDemo.enseignantPour(TitreEnseignant.sayyid),
        ),
      );
    });
  });

  // --- m10 : FilterPill ------------------------------------------------------

  group('m10 : FilterPill, nom lu une fois, etat choisi sur le meme noeud', () {
    for (final bool retenue in <bool>[true, false]) {
      testWidgets('retenue: $retenue', (WidgetTester tester) async {
        await _monter(
          tester,
          Scaffold(
            body: Center(
              child: FilterPill(
                libelle: 'À revoir',
                compteur: 3,
                retenue: retenue,
                onPress: () {},
              ),
            ),
          ),
        );
        final SemanticsNode noeud = _noeud(tester, find.byType(FilterPill));
        expect(noeud.label, 'À revoir, 3');
        expect(noeud.flagsCollection.isButton, isTrue);
        expect(noeud.flagsCollection.isSelected, isNot(Tristate.none));
        expect(
          noeud.flagsCollection.isSelected,
          retenue ? Tristate.isTrue : Tristate.isFalse,
        );
        // Aucun second noeud ne porte l'etat sans nom, ni le nom en double.
        final List<SemanticsNode> boutons = <SemanticsNode>[
          for (final SemanticsNode n in _tous(tester))
            if (n.flagsCollection.isButton) n,
        ];
        expect(boutons, hasLength(1));
        expect(
          _tous(tester)
              .where((SemanticsNode n) => n.label.contains('À revoir')),
          hasLength(1),
        );
      });
    }
  });

  // --- m12 : doublons de noms ------------------------------------------------

  group('m12 : chaque nom lu une fois', () {
    testWidgets('« Ecrire » seul n\'est pas lu « Outils d\'enseignement, '
        'Ecrire »', (WidgetTester tester) async {
      await _monter(
        tester,
        Scaffold(
          body: Center(
            child: OutilsEnseignement(
              onOutil: (_) {},
              forme: FormeOutils.rangee,
              outils: const <OutilEnseignement>[OutilEnseignement.ecrire],
            ),
          ),
        ),
      );
      final Finder ecrire = find.byKey(const ValueKey<String>('outil-ecrire'));
      expect(ecrire, findsOneWidget);
      final String nom = _noeud(tester, ecrire).label;
      expect(nom, isNot(contains(t.salle.seance.outils.titre)));
      expect(
        _tous(tester).where(
          (SemanticsNode n) => n.label.contains(t.salle.seance.outils.titre),
        ),
        isEmpty,
      );
    });

    testWidgets('plusieurs outils : le groupe reste nomme', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        Scaffold(
          body: Center(
            child: OutilsEnseignement(
              onOutil: (_) {},
              forme: FormeOutils.rangee,
            ),
          ),
        ),
      );
      expect(
        _tous(tester)
            .where((SemanticsNode n) => n.label == t.salle.seance.outils.titre),
        hasLength(1),
      );
    });

    testWidgets('observateur : titre et page lus une fois, pas trois', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const DemoSallePage(
          observateur: ObservateurDemo.tuteur,
          situation: SituationTb.ped03,
        ),
        taille: _bureau,
      );
      final String titre = DonneesSeanceDemo.supportPageFixe.titre;
      final List<SemanticsNode> lus = <SemanticsNode>[
        for (final SemanticsNode n in _tous(tester))
          if (n.label.contains(titre)) n,
      ];
      expect(lus, hasLength(1), reason: '$lus');
      // Le titre reste ecrit a l'ecran.
      expect(find.text(titre), findsWidgets);
    });

    testWidgets('l\'aide « Autoriser a ecrire » : son noeud, juste avant le '
        'bouton, jamais avant le prenom', (WidgetTester tester) async {
      await _monter(
        tester,
        const DemoSallePage(
          role: RoleSeance.enseignant,
          situation: SituationTb.per01,
        ),
        taille: _bureau,
      );
      final String aide = t.salle.seance.ecriture.autoriserAide(
        prenom: 'Mariam',
      );
      final Finder texte = find.text(aide);
      expect(texte, findsOneWidget);
      final SemanticsNode noeud = _noeud(tester, texte);
      expect(noeud.label, aide);
      // Le noeud est celui du texte, pas celui de la carte : aucun enfant,
      // sa hauteur est celle de l'aide.
      expect(noeud.childrenCount, 0);
      expect(
        noeud.rect.height,
        lessThanOrEqualTo(tester.getSize(texte).height + 1),
      );
      // L'en-tete de la fiche dit le prenom une fois, dans son seul nom.
      final Finder entete = find.ancestor(
        of: find.text('Mariam').first,
        matching: find.byWidgetPredicate(
          (Widget w) => w is Semantics && w.properties.expanded != null,
        ),
      );
      final String nomEntete = _noeud(tester, entete.first).label;
      expect(
        nomEntete,
        '${t.salle.seance.replierFiche(prenom: 'Mariam')}, '
        '${t.salle.seance.statut.connecte}',
      );
      // La carte (et l'en-tete du prenom) ne recopient pas l'aide.
      expect(
        _tous(tester).where((SemanticsNode n) => n.label.contains(aide)),
        hasLength(1),
      );
    });
  });

  // --- m23 -------------------------------------------------------------------

  test('m23 : la capacite « meneLaSeance » remplace la lecture du role', () {
    for (final RoleSeance role in RoleSeance.values) {
      expect(
        DonneesSeanceDemo.vue(role, EtatDemoSalle.repos).meneLaSeance,
        role == RoleSeance.enseignant,
      );
    }
  });

  // --- m27 : infobulles de la capsule ----------------------------------------

  testWidgets('m27 : l\'avatar et l\'oeil de la capsule ont leur infobulle, '
      'muette au lecteur d\'ecran', (WidgetTester tester) async {
    await _monter(
      tester,
      const DemoSallePage(role: RoleSeance.eleve, situation: SituationTb.ctx02),
      taille: _bureau,
    );
    for (final Key cle in <Key>[
      CapsuleSeance.cleAvatar,
      CapsuleSeance.cleOeil,
    ]) {
      final Finder bulle = find.ancestor(
        of: find.byKey(cle),
        matching: find.byType(Tooltip),
      );
      expect(bulle, findsOneWidget, reason: '$cle');
      final Tooltip t0 = tester.widget<Tooltip>(bulle);
      expect(t0.message, isNotEmpty);
      expect(t0.excludeFromSemantics, isTrue);
    }
    // L'infobulle se montre a l'appui long, au texte du nom lu.
    await tester.longPress(find.byKey(CapsuleSeance.cleAvatar));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text(
        t.salle.seance.capsule.avatar(
          nom: DonneesSeanceDemo.enseignantPour(TitreEnseignant.sayyid),
        ),
      ),
      findsOneWidget,
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  // --- m28 -------------------------------------------------------------------

  test(
    'm28 : l\'echec d\'ouverture dit la cause probable (fr et ar)',
    () async {
      expect(t.salle.seance.bibliotheque.echecDetail, contains('indisponible'));
      expect(t.salle.seance.bibliotheque.echecDetail, contains('Réessayez'));
      final Traductions ar = await AppLocale.ar.build();
      expect(ar.salle.seance.bibliotheque.echecDetail, contains('غير متاح'));
      expect(
        ar.salle.seance.surface.supportIndisponible,
        isNot(t.salle.seance.surface.supportIndisponible),
      );
      expect(
        ar.salle.seance.surface.supportArrive,
        isNot(t.salle.seance.surface.supportArrive),
      );
    },
  );

  // --- n. 8 : « Autoriser a ecrire » entier au bas du panneau ---------------

  group(
    'n. 8 : « Autoriser a ecrire » entier dans le panneau Eleves, 1440',
    () {
      for (final bool arabe in <bool>[false, true]) {
        testWidgets(arabe ? 'arabe' : 'francais', (WidgetTester tester) async {
          if (arabe) {
            await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
            addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
          }
          await _monter(
            tester,
            const DemoSallePage(
              role: RoleSeance.enseignant,
              situation: SituationTb.ped03,
            ),
            taille: _bureau,
          );
          await tester.tap(find.byKey(DeclencheurCommandes.cle));
          await tester.pumpAndSettle();
          final Finder bouton = find.byKey(
            const ValueKey<String>('autoriser-ecrire-Mariam'),
          );
          expect(bouton, findsOneWidget);
          final Finder liste = find.byKey(
            const ValueKey<String>('panneau-eleves'),
          );
          final Rect vue = tester.getRect(liste);
          final Rect b = tester.getRect(bouton);
          expect(
            vue.contains(b.topLeft) && vue.contains(b.bottomRight),
            isTrue,
            reason: 'bouton $b dans la liste $vue',
          );
          expect(bouton.hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    },
  );

  // --- n. 13 : la mention de la page traduite ---------------------------------

  testWidgets('n. 13 : « Support illustratif » traduit en arabe', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
    await _monter(
      tester,
      const DemoSallePage(role: RoleSeance.eleve, situation: SituationTb.ped03),
    );
    expect(find.text('Support illustratif'), findsNothing);
    expect(
      find.descendant(
        of: _page,
        matching: find.text(t.salle.seance.surface.supportIllustratif),
      ),
      findsOneWidget,
    );
    expect(t.salle.seance.surface.supportIllustratif, 'مادة توضيحية');
  });

  // --- n. 14 : le ruban de demonstration --------------------------------------

  group('n. 14 : ruban « Demonstration »', () {
    testWidgets('controleur 1440 : il ne recouvre pas « Quitter »', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const DemoSallePage(
          observateur: ObservateurDemo.controleur,
          situation: SituationTb.ped01,
        ),
        taille: _bureau,
      );
      final Finder quitter = find.ancestor(
        of: find.text(t.salle.quitter),
        matching: find.byType(ActionPrincipale),
      );
      final Rect q = tester.getRect(quitter.first);
      // Le ruban occupe le coin de fin : la diagonale x + y = emprise
      // (40 racine de 2) plus sa demi-epaisseur ; « Quitter » reste en deca.
      final double coinX = _bureau.width - q.right;
      final double coinY = q.top;
      expect(
        coinX + coinY,
        greaterThan(empriseRepereDemonstration + 12),
        reason: 'Quitter $q',
      );
    });

    testWidgets('arabe : le ruban est en arabe', (WidgetTester tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
      await _monter(
        tester,
        const DemoSallePage(
          observateur: ObservateurDemo.tuteur,
          situation: SituationTb.ped01,
        ),
      );
      final Banner ruban = tester.widget<Banner>(find.byType(Banner).first);
      expect(ruban.message, 'عرض توضيحي');
      expect(libelleRepereDemonstration, isNot('Démonstration'));
    });
  });

  // --- n. 22 ----------------------------------------------------------------

  group('n. 22', () {
    testWidgets('la carte du catalogue est lue une fois', (
      WidgetTester tester,
    ) async {
      final LibraryResource r = DonneesSeanceDemo.ressourcesTb.first;
      final CarteRessource carte = CarteRessource(
        ressource: r,
        etatOffline: EtatOffline.aTelecharger,
        onPress: () {},
      );
      await _monter(
        tester,
        Scaffold(body: ListView(children: <Widget>[carte])),
      );
      final SemanticsNode noeud = _noeud(tester, find.byType(CarteRessource));
      expect(noeud.label, carte.libelleSemantique);
      expect(
        _tous(tester).where((SemanticsNode n) => n.label.contains(r.title)),
        hasLength(1),
      );
    });

    testWidgets('presenter le support arabe : la diapositive suit (capsule '
        'et lecture), plus celle du support precedent', (
      WidgetTester tester,
    ) async {
      await _ouvrir(
        tester,
        RoleSeance.enseignant,
        SituationTb.ped03,
        taille: _bureau,
      );
      Future<void> taper(Finder f) async {
        await tester.ensureVisible(f);
        await tester.pumpAndSettle();
        await tester.tap(f);
        await tester.pumpAndSettle();
      }

      await taper(find.byKey(DeclencheurCommandes.cle));
      await taper(find.byKey(CommandesPedagogiques.cleBibliotheque));
      const String titre = DonneesSeanceDemo.titreSupportArabe;
      final Finder catalogue = find.byType(SurfaceBibliotheque);
      final Finder carte = find.descendant(
        of: catalogue,
        matching: find.text(titre),
      );
      await tester.scrollUntilVisible(
        carte,
        120,
        scrollable: find
            .descendant(of: catalogue, matching: find.byType(Scrollable))
            .first,
      );
      await taper(carte.first);
      await taper(find.text(t.salle.seance.bibliotheque.presenter).last);
      final VueSeance vue = tester
          .widget<SalleSeance>(find.byType(SalleSeance))
          .vue;
      expect(vue.supportPresente?.id, DonneesSeanceDemo.idSupportArabe);
      expect(vue.support?.ressourceId, DonneesSeanceDemo.idSupportArabe);
      expect(vue.support?.titre, titre);
      expect(vue.support?.pages, DonneesSeanceDemo.pagesSupportArabe);
      expect(find.byKey(CapsuleSeance.cle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // --- TB-10 reste a, n. 23 : aucun mot coupe dans les tuiles --------------

  group('TB-10 reste a : les tuiles d\'action ne coupent aucun mot', () {
    for (final (String nom, Size taille, double texte)
        in <(String, Size, double)>[
          ('768 x1', const Size(768, 1024), 1),
          ('1440 x2', _bureau, 2),
          ('1440 x1', _bureau, 1),
          ('390 x1', _telephone, 1),
        ]) {
      testWidgets(nom, (WidgetTester tester) async {
        await _monter(
          tester,
          const DemoSallePage(
            role: RoleSeance.enseignant,
            situation: SituationTb.per01,
          ),
          taille: taille,
          texte: texte,
        );
        for (final String libelle in <String>[
          t.salle.seance.faireReciter,
          t.salle.seance.rappeler,
          t.tc.classe.action.noter,
          t.salle.seance.signalerBesoin,
        ]) {
          final Finder f = find.text(libelle);
          expect(f, findsOneWidget, reason: libelle);
          final RenderParagraph p = tester.renderObject(f);
          expect(p.didExceedMaxLines, isFalse, reason: libelle);
          // Chaque mot sur une seule ligne : ses boites ont le meme haut.
          int debut = 0;
          for (final String mot in libelle.split(' ')) {
            final List<TextBox> boites = p.getBoxesForSelection(
              TextSelection(
                baseOffset: debut,
                extentOffset: debut + mot.length,
              ),
            );
            final Set<double> hauts = <double>{
              for (final TextBox b in boites) b.top.roundToDouble(),
            };
            expect(hauts, hasLength(1), reason: '« $mot » coupe ($nom)');
            debut += mot.length + 1;
          }
        }
        expect(tester.takeException(), isNull);
      });
    }
  });
}
