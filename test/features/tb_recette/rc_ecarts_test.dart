// TB-RC (ecarts declares par l'auteur) : m20, m21, n.7, n.17, le volet du
// telephone couche. (« Quitter » lu une fois : `commande_salle_test.dart`.)
//
// - m20 : une coupure de la room (reconnexion, hors ligne, echec) suspend
//   l'ecriture de l'eleve et marque l'encre de l'enseignant « non partagee »,
//   meme quand le moteur du tableau ne l'a pas encore dit ;
// - m21 : l'outil Ecrire et l'historique d'Annuler sont ceux de CETTE salle :
//   une salle neuve s'ouvre sans Ecrire arme ;
// - n.7 : la phrase du tableau libre tient sur sa propre carte, jamais a
//   cheval sur la page et le fond de la surface, a x2 aussi ;
// - n.17 : le menu de rangement disparait d'un coup, la copie du support ne
//   vole pas sous lui ;
// - volet du telephone couche (844 x 390) : Commandes (et Participants)
//   prennent presque toute la hauteur, l'en-tete cede sa place, et revient
//   quand le volet est ferme. Mesures avec les polices du depot.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_outils/etat_outils.dart';
import 'package:rewayah_academy/core/tc_outils/port_dock_hote.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/chrome_seance.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_seance.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/surface_page_fixe.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';

VueSeance _vue(
  RoleSeance role, {
  ConnexionSeance connexion = ConnexionSeance.enLigne,
  SynchroTableau synchro = SynchroTableau.partage,
}) => VueSeance(
  role: role,
  nomClasse: 'Classe An-Nour',
  nomEnseignant: 'Sayyid Ibrahim',
  initialesEnseignant: 'SI',
  prenomEleve: role == RoleSeance.enseignant ? null : 'Mariam',
  eleves: const <EleveSeance>[
    EleveSeance(
      prenom: 'Mariam',
      statut: StatutEleveSeance.connecte,
      peutEcrire: true,
    ),
  ],
  connexion: connexion,
  synchroTableau: synchro,
);

Future<void> _monter(
  WidgetTester tester,
  Size taille, {
  RoleSeance role = RoleSeance.enseignant,
  SituationTb situation = SituationTb.ped01,
  double texte = 1,
  double densite = 1,
}) async {
  fixerVueCapture(tester, taille, densite);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    hoteCapture(
      DemoSallePage(role: role, situation: situation),
      echelleTexte: texte,
    ),
  );
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('m20 : la coupure de la room suspend le tableau', () {
    test('la room coupee rend le tableau au moins interrompu', () {
      for (final ConnexionSeance coupee in <ConnexionSeance>[
        ConnexionSeance.reconnexion,
        ConnexionSeance.horsLigne,
        ConnexionSeance.echec,
      ]) {
        expect(
          _vue(RoleSeance.enseignant, connexion: coupee).synchroEffective,
          SynchroTableau.interrompue,
          reason: coupee.name,
        );
      }
    });

    test('lien sain, reseau faible, coupure refermee : rien ne change', () {
      for (final ConnexionSeance saine in <ConnexionSeance>[
        ConnexionSeance.enLigne,
        ConnexionSeance.reseauFaible,
        ConnexionSeance.retablie,
      ]) {
        expect(
          _vue(RoleSeance.enseignant, connexion: saine).synchroEffective,
          SynchroTableau.partage,
          reason: saine.name,
        );
      }
    });

    test('la reprise reste la reprise, le signal du moteur est gardé', () {
      expect(
        _vue(
          RoleSeance.eleve,
          connexion: ConnexionSeance.reconnexion,
          synchro: SynchroTableau.reprise,
        ).synchroEffective,
        SynchroTableau.reprise,
      );
      expect(
        _vue(
          RoleSeance.enseignant,
          synchro: SynchroTableau.interrompue,
        ).synchroEffective,
        SynchroTableau.interrompue,
      );
    });

    test('l eleve n ecrit plus pendant la coupure, l enseignant marque son '
        'encre non partagee', () {
      final VueSeance eleve = _vue(RoleSeance.eleve);
      expect(eleve.ecritPossible, isTrue);
      final VueSeance eleveCoupe = _vue(
        RoleSeance.eleve,
        connexion: ConnexionSeance.horsLigne,
      );
      expect(eleveCoupe.ecritureSuspendue, isTrue);
      expect(eleveCoupe.ecritPossible, isFalse);
      final VueSeance prof = _vue(
        RoleSeance.enseignant,
        connexion: ConnexionSeance.reconnexion,
      );
      expect(prof.encreNonPartagee, isTrue);
      // L'enseignant ecrit encore (en local) : seule son encre est marquee.
      expect(prof.ecritPossible, isTrue);
      expect(
        _vue(RoleSeance.enseignant).encreNonPartagee,
        isFalse,
        reason: 'lien sain',
      );
    });
  });

  group('m21 : les outils sont ceux de cette salle', () {
    testWidgets('une salle neuve s ouvre sans Ecrire arme', (
      WidgetTester tester,
    ) async {
      await _monter(tester, const Size(1440, 900));
      ProviderContainer salle() =>
          ProviderScope.containerOf(tester.element(find.byType(SalleSeance)));
      expect(salle().read(etatOutilsProvider).outilActif, isNull);
      salle().read(etatOutilsProvider.notifier).choisirOutil(OutilDock.stylet);
      expect(salle().read(etatOutilsProvider).outilActif, OutilDock.stylet);
      // La racine (l'hote) n'a rien vu : l'outil n'est pas a l'appareil.
      final ProviderContainer racine = ProviderScope.containerOf(
        tester.element(find.byType(DemoSallePage)),
      );
      expect(racine.read(etatOutilsProvider).outilActif, isNull);

      // Une AUTRE salle (autre montage) : Ecrire n'est pas arme.
      await _monter(tester, const Size(1440, 900));
      expect(salle().read(etatOutilsProvider).outilActif, isNull);
    });
  });

  group('n.7 : la phrase du tableau libre sur sa carte', () {
    for (final (Size taille, double texte) in <(Size, double)>[
      (const Size(390, 844), 2),
      (const Size(320, 700), 2),
      (const Size(1440, 900), 1),
    ]) {
      testWidgets('${taille.width.toInt()} x${texte.toInt()} : la phrase est '
          'entiere dans une carte', (WidgetTester tester) async {
        await _monter(tester, taille, texte: texte);
        final Finder phrase = find.byKey(SurfacePageFixe.cleConsigne);
        expect(phrase, findsOneWidget);
        // Son premier cadre decore est la carte : elle contient la phrase,
        // avec de l'air autour.
        final Finder carte = find
            .ancestor(of: phrase, matching: find.byType(DecoratedBox))
            .first;
        final Rect r = tester.getRect(phrase);
        final Rect c = tester.getRect(carte);
        // La carte est CELLE de la phrase (pas le fond de toute la
        // surface) : un peu plus grande qu'elle, de son air seulement.
        expect(c.width - r.width, inInclusiveRange(16, 32));
        expect(c.height - r.height, inInclusiveRange(16, 32));
        expect(c.contains(r.topLeft) && c.contains(r.bottomRight), isTrue);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('n.17 : le menu de rangement disparait d un coup', () {
    testWidgets('quelques instants apres le choix, le menu n est plus la', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const Size(1440, 900),
        situation: SituationTb.ped03,
      );
      await tester.tap(find.byKey(DeclencheurCommandes.cle));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CommandesPedagogiques.cleMenu));
      await tester.pumpAndSettle();
      final Finder ranger = find.text(t.salle.seance.rangement.ranger);
      expect(ranger, findsOneWidget);
      await tester.tap(ranger);
      await tester.pump();
      // Un instant plus tard, pendant le vol : plus de menu par-dessus.
      await tester.pump(const Duration(milliseconds: 40));
      expect(ranger, findsNothing);
    });
  });

  group('volet du telephone couche (844 x 390)', () {
    const Size couche = Size(844, 390);
    for (final double texte in <double>[1, 2]) {
      testWidgets('x${texte.toInt()} : Commandes prend la hauteur, l en-tete '
          'revient a la fermeture', (WidgetTester tester) async {
        await _monter(
          tester,
          couche,
          situation: SituationTb.cmd01,
          texte: texte,
          densite: 2,
        );
        final Finder volet = find.byKey(CommandesPedagogiques.cle);
        expect(volet, findsOneWidget);
        final Rect r = tester.getRect(
          find.ancestor(of: volet, matching: find.byType(PanneauSeance)).first,
        );
        // Il part du haut de la salle et laisse la barre de l'appel.
        expect(r.top, lessThanOrEqualTo(8));
        expect(r.height, greaterThanOrEqualTo(couche.height * 0.55));
        expect(r.bottom, lessThanOrEqualTo(couche.height));
        // L'en-tete a cede sa place au volet (comme en focus).
        expect(find.byType(ChromeSeance), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Commandes fermees : l en-tete est la', (
      WidgetTester tester,
    ) async {
      await _monter(tester, couche, situation: SituationTb.ped03, densite: 2);
      expect(find.byType(ChromeSeance), findsOneWidget);
      expect(find.byKey(CommandesPedagogiques.cle), findsNothing);
    });

    testWidgets('portrait (390 x 844) : l en-tete reste avec le panneau', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const Size(390, 844),
        situation: SituationTb.cmd01,
        densite: 2,
      );
      expect(find.byKey(CommandesPedagogiques.cle), findsOneWidget);
      expect(find.byType(ChromeSeance), findsOneWidget);
    });
  });
}
