// T-S1 du lot CL-7 (ecrans de secours) : le modele, les textes et la
// demonstration. Un test pur par ligne des tableaux de
// `10_classe/07_SECOURS.md` section 2, puis les boutons des etats qui ont
// deja un rendu (acces retire, cote eleve et enseignant).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle/vue_salle.dart';
import 'package:rewayah_academy/features/salle_seance/depuis_salle.dart';
import 'package:rewayah_academy/features/salle_seance/resultat_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';

VueSeance _vue(RoleSeance r, EtatDemoSalle e) => DonneesSeanceDemo.vue(r, e);

VueSeance _cnx(RoleSeance r, ConnexionSeance c) =>
    _vue(r, EtatDemoSalle.repos).copyWith(connexion: c);

const List<RoleSeance> _adultes = <RoleSeance>[
  RoleSeance.eleve,
  RoleSeance.enseignant,
];

void main() {
  group('P05 reconnexion', () {
    test('bandeau : texte exact par role', () {
      for (final RoleSeance r in _adultes) {
        expect(
          _cnx(r, ConnexionSeance.reconnexion).texteBandeau,
          'Connexion interrompue. Reconnexion en cours…',
        );
      }
      expect(
        _cnx(RoleSeance.guidee, ConnexionSeance.reconnexion).texteBandeau,
        'Reconnexion de la séance…',
      );
    });

    test('pastille « Reconnexion » et commandes de publication coupees', () {
      for (final RoleSeance r in RoleSeance.values) {
        final VueSeance v = _cnx(r, ConnexionSeance.reconnexion);
        expect(v.texteConnexion, 'Reconnexion');
        expect(v.commandesPublicationActives, isFalse);
        expect(
          v.libelleIndisponible('Micro'),
          'Micro. Indisponible pendant la reconnexion.',
        );
        expect(v.voitBlocEchec, isFalse);
      }
    });

    test('retablie : retour bref, pastille « En ligne », sans bandeau', () {
      for (final RoleSeance r in RoleSeance.values) {
        final VueSeance v = _cnx(r, ConnexionSeance.retablie);
        expect(v.texteRetabli, 'Connexion rétablie.');
        expect(v.texteBandeau, isNull);
        expect(v.texteConnexion, 'En ligne');
        expect(v.commandesPublicationActives, isTrue);
        expect(v.libelleIndisponible('Micro'), isNull);
      }
    });

    test('reconnexion impossible : titre par role, sortie offerte', () {
      for (final RoleSeance r in _adultes) {
        final VueSeance v = _cnx(r, ConnexionSeance.echec);
        expect(v.voitBlocEchec, isTrue);
        expect(v.titreEchec, 'Impossible de rétablir la connexion.');
        expect(v.echecPermetQuitter, isTrue);
        expect(v.libelleQuitterEchec, 'Quitter la séance');
        expect(v.texteBandeau, isNull);
        expect(v.commandesPublicationActives, isFalse);
      }
      final VueSeance g = _cnx(RoleSeance.guidee, ConnexionSeance.echec);
      expect(g.titreEchec, 'La connexion ne revient pas.');
      expect(g.libelleQuitterEchec, 'Quitter');
      expect(g.echecPermetQuitter, isTrue);
      expect(t.salle.secours.reessayer, 'Réessayer');
    });

    test('hors ligne confirme : Reessayer seul (ES, EN), Quitter en IG', () {
      for (final RoleSeance r in _adultes) {
        final VueSeance v = _cnx(r, ConnexionSeance.horsLigne);
        expect(
          v.titreEchec,
          'Vous êtes hors ligne. La séance nécessite une connexion.',
        );
        expect(v.echecPermetQuitter, isFalse);
      }
      final VueSeance g = _cnx(RoleSeance.guidee, ConnexionSeance.horsLigne);
      expect(g.titreEchec, 'La connexion ne revient pas.');
      expect(g.echecPermetQuitter, isTrue);
    });

    test('en ligne : aucun texte de secours', () {
      for (final RoleSeance r in RoleSeance.values) {
        final VueSeance v = _cnx(r, ConnexionSeance.enLigne);
        expect(v.texteBandeau, isNull);
        expect(v.sousTexteBandeau, isNull);
        expect(v.texteRetabli, isNull);
        expect(v.titreEchec, isNull);
        expect(v.commandesPublicationActives, isTrue);
      }
    });
  });

  group('P06 reseau faible', () {
    test('texte exact par role, sous-texte en guidee seulement', () {
      for (final RoleSeance r in _adultes) {
        final VueSeance v = _cnx(r, ConnexionSeance.reseauFaible);
        expect(v.texteBandeau, "Réseau faible. L'audio est prioritaire.");
        expect(v.sousTexteBandeau, isNull);
      }
      final VueSeance g = _cnx(RoleSeance.guidee, ConnexionSeance.reseauFaible);
      expect(g.texteBandeau, 'Le réseau est faible.');
      expect(g.sousTexteBandeau, 'Le son reste prioritaire.');
    });

    test('jamais « hors ligne », pastille « En ligne », commandes actives', () {
      for (final RoleSeance r in RoleSeance.values) {
        final VueSeance v = _cnx(r, ConnexionSeance.reseauFaible);
        expect(v.texteConnexion, 'En ligne');
        expect(v.commandesPublicationActives, isTrue);
        expect(v.voitBlocEchec, isFalse);
        for (final String? s in <String?>[
          v.texteBandeau,
          v.sousTexteBandeau,
          v.texteConnexion,
        ]) {
          expect(s?.toLowerCase().contains('hors ligne') ?? false, isFalse);
        }
      }
    });
  });

  group('P09 micro bloque', () {
    test('texte exact par role', () {
      expect(
        _vue(RoleSeance.eleve, EtatDemoSalle.microBloque).texteMicroBloque,
        'Le micro est bloqué dans les réglages de cet appareil.',
      );
      expect(
        _vue(RoleSeance.enseignant, EtatDemoSalle.microBloque).texteMicroBloque,
        'Le micro est bloqué dans les réglages de cet appareil.',
      );
      expect(
        _vue(RoleSeance.guidee, EtatDemoSalle.microBloque).texteMicroBloque,
        'Le micro est bloqué sur cet appareil.',
      );
      expect(t.salle.secours.continuerSansMicro, 'Continuer sans micro');
      expect(t.salle.secours.ouvrirReglages, 'Ouvrir les réglages');
    });
  });

  group('P10 camera interdite', () {
    test('eleve standard : pas de bouton, statut non interactif', () {
      final VueSeance v = _vue(RoleSeance.eleve, EtatDemoSalle.cameraInterdite);
      expect(v.commandesDock, isNot(contains(CommandeDock.camera)));
      expect(v.texteCameraInterdite, 'Caméra désactivée pour ce profil.');
      expect(VueSeance.optionQS1, isTrue);
    });

    test('guidee : ni bouton ni explication', () {
      final VueSeance v = _vue(
        RoleSeance.guidee,
        EtatDemoSalle.cameraInterdite,
      );
      expect(v.commandesDock, isNot(contains(CommandeDock.camera)));
      expect(v.texteCameraInterdite, isNull);
    });

    test('enseignant : camera toujours la, aucun statut', () {
      final VueSeance v = _vue(
        RoleSeance.enseignant,
        EtatDemoSalle.cameraInterdite,
      );
      expect(v.commandesDock, contains(CommandeDock.camera));
      expect(v.texteCameraInterdite, isNull);
    });
  });

  group('P11 seance prolongee', () {
    test('ES et EN : « La séance se poursuit. », IG : rien', () {
      expect(
        _vue(RoleSeance.eleve, EtatDemoSalle.prolongee).ligneEtat,
        endsWith('La séance se poursuit.'),
      );
      expect(
        _vue(RoleSeance.enseignant, EtatDemoSalle.prolongee).ligneEtat,
        endsWith('La séance se poursuit.'),
      );
      expect(_vue(RoleSeance.guidee, EtatDemoSalle.prolongee).ligneEtat, null);
    });

    test('minutes jamais negatives', () {
      // Le moteur refuse deja un restant negatif (SessionClockVM) ; la vue
      // le refuse aussi : apres l'heure de fin, c'est HorlogeDepassee.
      expect(() => HorlogeRestante(-1), throwsAssertionError);
      expect(const HorlogeRestante(0).minutes, 0);
    });
  });

  group('P12 acces retire', () {
    test('issue eleve et fin enseignant dans la demonstration', () {
      expect(
        DonneesSeanceDemo.issueEleve(EtatDemoSalle.accesRetire),
        IssueSeance.accesRetire,
      );
      expect(
        _vue(RoleSeance.enseignant, EtatDemoSalle.accesRetire).estFinie,
        isTrue,
      );
      expect(
        t.salle.fin.accesRetireTitre,
        'Votre accès à cette séance a pris fin.',
      );
    });

    testWidgets('ES : titre exact, sans phrase ; Retour a la Classe', (
      WidgetTester tester,
    ) async {
      int retours = 0;
      fixerVueCapture(tester, const Size(390, 844), 1);
      await tester.pumpWidget(
        hoteCapture(
          ResultatSeance(
            issue: IssueSeance.accesRetire,
            onRetour: () => retours++,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Votre accès à cette séance a pris fin.'), findsOne);
      expect(find.text(t.salle.fin.phrase), findsNothing);
      await tester.tap(find.text('Retour à la Classe'));
      expect(retours, 1);
    });

    testWidgets('demonstration ES : l\'etat ouvre la fin, le bouton sort', (
      WidgetTester tester,
    ) async {
      int sorties = 0;
      fixerVueCapture(tester, const Size(1440, 900), 1);
      await tester.pumpWidget(
        hoteCapture(
          SalleDemo(
            role: RoleSeance.eleve,
            etat: EtatDemoSalle.accesRetire,
            onSortir: () => sorties++,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Votre accès à cette séance a pris fin.'), findsOne);
      await tester.tap(find.text('Retour à la Classe'));
      expect(sorties, 1);
    });

    testWidgets('demonstration EN : fin CLV-10, Ouvrir le cahier', (
      WidgetTester tester,
    ) async {
      int sorties = 0;
      fixerVueCapture(tester, const Size(1440, 900), 1);
      await tester.pumpWidget(
        hoteCapture(
          SalleDemo(
            role: RoleSeance.enseignant,
            etat: EtatDemoSalle.accesRetire,
            onSortir: () => sorties++,
          ),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('fin-seance-enseignant')),
        findsOne,
      );
      await tester.tap(find.text('Ouvrir le cahier'));
      expect(sorties, 1);
    });
  });

  group('adaptateurs : seulement les phases deja connues', () {
    test('instable, reconnexion, retabli', () {
      expect(
        DepuisSalle.connexionDe(PhaseSalle.instable),
        ConnexionSeance.reseauFaible,
      );
      expect(
        DepuisSalle.connexionDe(PhaseSalle.reconnexion),
        ConnexionSeance.reconnexion,
      );
      expect(
        DepuisSalle.connexionDe(PhaseSalle.retabli),
        ConnexionSeance.retablie,
      );
      expect(
        DepuisSalle.connexionDe(PhaseSalle.enSalle),
        ConnexionSeance.enLigne,
      );
    });
  });

  group('demonstration', () {
    testWidgets('chaque etat de secours s\'ouvre sans erreur, Quitter repond', (
      WidgetTester tester,
    ) async {
      for (final EtatDemoSalle e in <EtatDemoSalle>[
        EtatDemoSalle.reseauFaible,
        EtatDemoSalle.reconnexion,
        EtatDemoSalle.retablie,
        EtatDemoSalle.echec,
        EtatDemoSalle.horsLigne,
        EtatDemoSalle.microBloque,
        EtatDemoSalle.prolongee,
      ]) {
        int sorties = 0;
        fixerVueCapture(tester, const Size(1440, 900), 1);
        await tester.pumpWidget(
          hoteCapture(
            SalleDemo(
              key: ValueKey<EtatDemoSalle>(e),
              role: RoleSeance.enseignant,
              etat: e,
              onSortir: () => sorties++,
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: e.name);
        await tester.tap(find.text(t.salle.quitter).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.salle.seance.quitterCahier));
        await tester.pumpAndSettle();
        expect(sorties, 1, reason: e.name);
        expect(
          DonneesSeanceDemo.vue(RoleSeance.enseignant, e).connexion,
          DonneesSeanceDemo.connexion(e),
        );
      }
    });
  });
}
