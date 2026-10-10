// TB-1b : le socle du chantier Supports et tableau.
//
// 1. Chaque situation `SituationTb` s'ouvre depuis la liste de /demo/salle,
//    atteinte par le VRAI routeur de l'application (`routeurProvider`) : le
//    test tape le lien, jamais une page montee seule (K-07).
// 2. Les donnees : une seule source (Classe An-Nour, Sayyid par defaut,
//    quatre inscrits avec photo, une seule « Peut ecrire »), le support a
//    page fixe et son ratio fournis par les donnees, les trois affichages,
//    et `ModeAffichagePartage` inchange.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_etat_partage/shared_content_state.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart'
    show TitreEnseignant;
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../router/support_routeur.dart';

Finder _lien(RoleSeance role, SituationTb s) =>
    find.byKey(ValueKey<String>('lien-${role.name}-tb-${s.name}'));

void main() {
  group('Donnees du socle (une seule source)', () {
    test('Classe An-Nour, Sayyid par defaut, quatre inscrits avec photo', () {
      for (final RoleSeance role in RoleSeance.values) {
        for (final SituationTb s in situationsTb(role)) {
          final VueSeance v = DonneesSeanceDemo.vueTb(role, s);
          expect(v.nomClasse, 'Classe An-Nour');
          expect(v.nomEnseignant, startsWith('Sayyid '));
          expect(v.eleves, hasLength(4));
          expect(
            v.eleves.every((EleveSeance e) => e.cleAvatar != null),
            isTrue,
            reason: 'K-44 : ${role.name} ${s.name}',
          );
          expect(v.elevesAutorisesAEcrire, hasLength(1));
          expect(v.tableauLibre, isNotNull);
          expect(v.enregistrement, EtatEnregistrement.actif);
        }
      }
    });

    test('les trois inscrits de la salle sont repris, Zaynab ecrit', () {
      final VueSeance v = DonneesSeanceDemo.vueTb(
        RoleSeance.enseignant,
        SituationTb.per01,
      );
      expect(v.eleves.map((EleveSeance e) => e.prenom).toList(), <String>[
        ...DonneesSeanceDemo.eleves.map((EleveSeance e) => e.prenom),
        'Zaynab',
      ]);
      expect(v.elevesAutorisesAEcrire.single.prenom, 'Zaynab');
      expect(v.compteurEleves, isNotNull);
      expect(v.connectes, 2);
      // Meme cle de photo que la Classe de l'Espace enseignant.
      expect(v.eleves.first.cleAvatar, 'demo/eleves/demo-eleve-mariam.png');
      expect(v.panneau, PanneauOuvert.eleves);
    });

    test('Sayyida quand la demonstration le demande', () {
      final VueSeance v = DonneesSeanceDemo.vueTb(
        RoleSeance.eleve,
        SituationTb.sal00,
        titre: TitreEnseignant.sayyida,
      );
      expect(v.nomEnseignant, startsWith('Sayyida '));
    });

    test('support a page fixe : celui du panneau, ratio des donnees', () {
      final SupportPageFixe p = DonneesSeanceDemo.supportPageFixe;
      final SupportDisponible chapitre = DonneesSeanceDemo.supports.firstWhere(
        (SupportDisponible s) => s.id == p.id,
      );
      expect(chapitre.rubrique, RubriqueSupport.reprendre);
      expect(chapitre.detail, endsWith(' · ${p.version}'));
      expect(p.titre, chapitre.titre);
      expect(p.total, chapitre.contenu!.pages);
      expect(p.total, DonneesSeanceDemo.support.pages);
      expect(p.page, 1);
      expect(p.ratio, closeTo(1240 / 1754, 1e-9));
      expect(p.mention, 'Support illustratif');
      expect(p.cleImage, isNull);
      expect(p.aLaPage(3).page, 3);
      expect(p.aLaPage(3).ratio, p.ratio);
      // Le tableau libre : une seule valeur, celle de la page (choix
      // provisoire, UX_REVIEW_TB n. 15).
      expect(DonneesSeanceDemo.tableauLibre.ratio, p.ratio);
    });

    test('trois affichages et vues de surface PED-01 a PED-04', () {
      VueSurface surface(SituationTb s) =>
          DonneesSeanceDemo.vueTb(RoleSeance.enseignant, s).vueSurface;
      expect(surface(SituationTb.ped01), VueSurface.tableauLibre);
      expect(surface(SituationTb.ped02), VueSurface.supportSeul);
      expect(surface(SituationTb.ped03), VueSurface.supportAvecNotes);
      expect(surface(SituationTb.ped04), VueSurface.tableauSupportMasque);
      expect(
        DonneesSeanceDemo.vueTb(
          RoleSeance.enseignant,
          SituationTb.effacementTableau,
        ).tableauLibre!.aDesNotes,
        isTrue,
      );
    });

    test('ecrire : l\'enseignant toujours, l\'eleve sur autorisation', () {
      expect(
        DonneesSeanceDemo.vueTb(
          RoleSeance.enseignant,
          SituationTb.sal00,
        ).peutEcrire,
        isTrue,
      );
      for (final RoleSeance r in <RoleSeance>[
        RoleSeance.eleve,
        RoleSeance.guidee,
      ]) {
        expect(
          DonneesSeanceDemo.vueTb(r, SituationTb.sal00).peutEcrire,
          isFalse,
        );
        expect(
          DonneesSeanceDemo.vueTb(r, SituationTb.droitRetire).peutEcrire,
          isFalse,
        );
        final VueSeance autorise = DonneesSeanceDemo.vueTb(
          r,
          SituationTb.autorisationEcrire,
        );
        expect(autorise.peutEcrire, isTrue);
        expect(autorise.elevesAutorisesAEcrire.single.prenom, 'Mariam');
      }
    });

    test('peutEcrire : sans eleve courant, personne n\'ecrit cote eleve', () {
      // Une ligne autorisee existe : seul le prenom manquant doit fermer.
      final VueSeance base = DonneesSeanceDemo.vueTb(
        RoleSeance.eleve,
        SituationTb.autorisationEcrire,
      );
      expect(base.peutEcrire, isTrue);
      final VueSeance sansEleve = VueSeance(
        role: RoleSeance.eleve,
        nomClasse: base.nomClasse,
        nomEnseignant: base.nomEnseignant,
        initialesEnseignant: base.initialesEnseignant,
        eleves: base.eleves,
      );
      expect(sansEleve.prenomEleve, isNull);
      expect(sansEleve.elevesAutorisesAEcrire, hasLength(1));
      expect(sansEleve.peutEcrire, isFalse);
      // L'enseignant ecrit toujours, meme sans eleve courant.
      expect(
        VueSeance(
          role: RoleSeance.enseignant,
          nomClasse: base.nomClasse,
          nomEnseignant: base.nomEnseignant,
          initialesEnseignant: base.initialesEnseignant,
        ).peutEcrire,
        isTrue,
      );
    });

    test('hors situation TB, la salle garde ses donnees d\'avant', () {
      final VueSeance v = DonneesSeanceDemo.vue(
        RoleSeance.enseignant,
        EtatDemoSalle.repos,
      );
      expect(v.eleves, hasLength(3));
      expect(v.supportPresente, isNull);
      expect(v.tableauLibre, isNull);
      expect(v.affichage, AffichagePartage.avecNotes);
      expect(v.enregistrement, EtatEnregistrement.inconnu);
      expect(v.eleves.every((EleveSeance e) => !e.peutEcrire), isTrue);
    });

    test('ModeAffichagePartage, contrat de base, est inchange', () {
      expect(
        ModeAffichagePartage.values.map((ModeAffichagePartage m) => m.name),
        <String>['page', 'verse', 'focus'],
      );
    });

    test('roles : une commande d\'un autre role n\'est jamais proposee', () {
      for (final SituationTb s in <SituationTb>[
        SituationTb.lib01,
        SituationTb.lib02,
        SituationTb.lib03,
        SituationTb.lib04,
        SituationTb.per01,
        SituationTb.dlg01,
        SituationTb.err03,
        SituationTb.effacementTableau,
      ]) {
        expect(situationsTb(RoleSeance.eleve), isNot(contains(s)));
        expect(situationsTb(RoleSeance.guidee), isNot(contains(s)));
        expect(situationsTb(RoleSeance.enseignant), contains(s));
      }
      expect(
        situationsTb(RoleSeance.enseignant),
        isNot(contains(SituationTb.supportArrive)),
      );
      // Toutes les vues du §17 (24) ont une situation.
      expect(
        SituationTb.values.where((SituationTb s) => s.reference != '§12'),
        hasLength(24),
      );
    });
  });

  group('Chaque situation s\'ouvre depuis la liste, par le vrai routeur', () {
    for (final RoleSeance role in RoleSeance.values) {
      for (final SituationTb s in situationsTb(role)) {
        testWidgets('${role.name} ${s.name}', (WidgetTester tester) async {
          final GoRouter routeur = await monterRouteur(
            tester,
            Routes.demoSalle,
            taille: const Size(1440, 900),
          );
          expect(lieu(routeur), Routes.demoSalle);
          final Finder lien = _lien(role, s);
          await tester.ensureVisible(lien);
          await tester.pump();
          await tester.tap(lien);
          await stabiliser(tester);
          expect(tester.takeException(), isNull);
          final Uri adresse = Uri.parse(lieu(routeur));
          expect(adresse.path, Routes.demoSalle);
          expect(adresse.queryParameters['role'], role.name);
          expect(adresse.queryParameters['tb'], s.name);
          expect(lieu(routeur), adresseDemoSalleTb(role, s));
          expect(
            find.byKey(ValueKey<String>('${role.name}-tb-${s.name}')),
            findsOneWidget,
          );
        });
      }
    }
  });

  group('Les donnees de la situation arrivent a l\'ecran', () {
    // Telephone pour les panneaux : sur bureau, le panneau Eleves est ouvert
    // d'office (EN-9) et ne distinguerait pas la situation.
    Future<void> ouvrir(
      WidgetTester tester,
      RoleSeance role,
      SituationTb s, {
      Size taille = const Size(390, 844),
    }) async {
      final GoRouter routeur = await monterRouteur(
        tester,
        adresseDemoSalleTb(role, s),
        taille: taille,
      );
      expect(lieu(routeur), adresseDemoSalleTb(role, s));
      expect(tester.takeException(), isNull);
    }

    testWidgets('SAL-00 enseignant : compteur des quatre inscrits', (
      WidgetTester tester,
    ) async {
      await ouvrir(
        tester,
        RoleSeance.enseignant,
        SituationTb.sal00,
        taille: const Size(1440, 900),
      );
      // vueTb : quatre inscrits dont deux connectes ; la salle d'avant TB-1b
      // n'en a que trois.
      expect(find.text('Élèves 2/4'), findsWidgets);
      expect(find.textContaining('/3'), findsNothing);
    });

    testWidgets('PER-01 enseignant : panneau Eleves ouvert', (
      WidgetTester tester,
    ) async {
      await ouvrir(tester, RoleSeance.enseignant, SituationTb.per01);
      expect(
        find.byKey(const ValueKey<String>('panneau-eleves')),
        findsOneWidget,
      );
    });

    testWidgets('LIB-01 enseignant : panneau Supports ouvert', (
      WidgetTester tester,
    ) async {
      await ouvrir(tester, RoleSeance.enseignant, SituationTb.lib01);
      final Finder panneau = find.byKey(
        const ValueKey<String>('panneau-supports'),
      );
      expect(panneau, findsOneWidget);
      expect(
        find.descendant(
          of: panneau,
          matching: find.text(DonneesSeanceDemo.supports.first.titre),
        ),
        findsWidgets,
      );
    });
  });

  group('Garde de la demonstration (/demo/salle?tb=...)', () {
    test('la route n\'existe pas en production', () {
      expect(routesDemoSalle('production'), isEmpty);
      expect(routesDemoSalle(' Production '), isEmpty);
      expect(routesDemoSalle(''), isEmpty);
      expect(routesDemoSalle('development'), hasLength(1));
    });

    test('la porte ne laisse passer la situation que hors production', () {
      final String adresse = adresseDemoSalleTb(
        RoleSeance.enseignant,
        SituationTb.ped03,
      );
      String? decider(String environnement) => deciderRedirection(
        session: const SessionState.deconnecte(),
        cheminDemande: Routes.demoSalle,
        cheminComplet: adresse,
        maintenant: DateTime.utc(2026, 10, 4),
        environnement: environnement,
      );
      expect(decider('production'), isNotNull);
      expect(decider('development'), isNull);
    });
  });

  testWidgets('une situation sans objet pour le role ramene a la liste', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await monterRouteur(
      tester,
      adresseDemoSalleTb(RoleSeance.eleve, SituationTb.lib01),
      taille: const Size(1440, 900),
    );
    expect(lieu(routeur), contains('tb=lib01'));
    expect(find.byKey(const ValueKey<String>('eleve-tb-lib01')), findsNothing);
    expect(_lien(RoleSeance.eleve, SituationTb.sal00), findsOneWidget);
  });
}
