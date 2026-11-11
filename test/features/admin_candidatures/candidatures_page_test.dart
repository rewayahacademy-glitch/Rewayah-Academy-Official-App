// ADM-20 : la file des candidatures de la direction.
//
// Ce que le test prouve :
// - les cinq etats (chargement, contenu, vide, erreur, hors ligne) et les
//   etats propres de la fiche : capacite indisponible, recherche sans
//   resultat (filtres rappeles), acces refuse, genre du lecteur inconnu,
//   exception du super-admin, alertes a zero, compteur non servi ;
// - rien de ce que la fiche interdit ne se voit : ni courriel, ni telephone,
//   ni code d'etat brut, ni code de dependance ;
// - tout est lu au serveur : le filtre, le tri et la page partent au port, une
//   seule page de 50 est demandee a la fois, le total est celui du filtre ;
// - « Gardees pour suivi » n'existe que si le serveur l'ouvre ;
// - zero bouton plein sans selection, un seul avec ; un bouton qui ne peut pas
//   aboutir n'est pas rendu (hors ligne, destination absente) ;
// - 320 px a texte x2, en francais et en arabe (droite a gauche), et 1440.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/modeles_lot_candidatures.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/etat_sans_donnees.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/barre_selection.dart';
import 'package:rewayah_academy/core/widgets/data_collection.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_candidatures/candidatures_page.dart';
import 'package:rewayah_academy/features/admin_candidatures/carte_alertes.dart';
import 'package:rewayah_academy/features/admin_candidatures/libelles_candidatures.dart';
import 'package:rewayah_academy/features/admin_candidatures/ligne_candidature.dart';

import '../../fixtures/candidature/faux_candidatures_direction.dart';
import '../../support/garde_interface.dart';
import '../../support/monter_recrutement.dart';
import '../../support/rangee_plus.dart';
import 'hote_candidatures.dart';

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

/// Six candidatures qui couvrent chaque etape, chaque etat de la fiche et les
/// marques d'informations manquantes.
List<LigneCandidature> _lignes() => <LigneCandidature>[
  ligneTest(
    id: 'a1',
    nom: 'Amina Diallo',
    courrielAObtenir: true,
    indicatifAConfirmer: true,
    derniereActivite: DateTime.utc(2026, 10, 20, 9),
  ),
  ligneTest(
    id: 'b2',
    nom: 'Bilal Haddad',
    etape: EtapeCandidature.verifications,
    etat: EtatCandidature.entretienAPlanifier,
    paysResidence: 'FR',
    paiement: EtatVersement.aVerifier,
    derniereActivite: DateTime.utc(2026, 10, 19, 9),
  ),
  ligneTest(
    id: 'c3',
    nom: 'Carla Mendes',
    etape: EtapeCandidature.confirmee,
    etat: null,
    indisponible: true,
    indisponibleJusquAu: DateTime.utc(2026, 11, 3),
    paysResidence: 'PT',
    derniereActivite: DateTime.utc(2026, 10, 18, 9),
  ),
  ligneTest(
    id: 'd4',
    nom: 'Dina Saidi',
    etape: EtapeCandidature.invitee,
    etat: null,
    paiement: EtatVersement.inconnu,
    paysResidence: null,
    derniereActivite: DateTime.utc(2026, 10, 17, 9),
  ),
  ligneTest(
    id: 'e5',
    nom: 'Emna Gharbi',
    etat: EtatCandidature.aCompleter,
    enPause: true,
    repriseLe: DateTime.utc(2026, 11, 10),
    paiement: EtatVersement.incompatible,
    paysResidence: 'TN',
    derniereActivite: DateTime.utc(2026, 10, 16, 9),
  ),
  ligneTest(
    id: 'f6',
    nom: 'Farah Nasser',
    etape: EtapeCandidature.prequalification,
    etat: EtatCandidature.paiementNonDisponible,
    issue: IssueCandidature.refusee,
    paysResidence: 'EG',
    derniereActivite: DateTime.utc(2026, 10, 15, 9),
  ),
];

/// Les mots de code que la direction ne lit jamais a l'ecran.
const List<String> _codesBruts = <String>[
  'a_completer',
  'en_examen',
  'paiement_non_disponible',
  'entretien_a_planifier',
  'entretien_planifie',
  'decision_en_attente',
  'prequalification',
  'verifications',
  'confirmee',
  'en_cours',
  'a_verifier',
  'compatible',
  'incompatible',
  'CAND-BR',
  'CAPACITE',
];

/// Touche la fleche « page suivante » apres l'avoir amenee dans la vue.
Future<void> _pageSuivante(WidgetTester tester) async {
  final Finder fleche = find.byKey(const ValueKey<String>('nav-suivant'));
  await tester.ensureVisible(fleche);
  await tester.pump();
  await tester.tap(fleche);
  await laisser(tester);
}

int _boutonsPleins(WidgetTester tester) => find
    .byWidgetPredicate(
      (Widget w) =>
          w is ActionPrincipale && w.niveau == NiveauAction.principale,
    )
    .evaluate()
    .length;

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('etats', () {
    testWidgets('capacite indisponible : une phrase, ni liste ni donnee', (
      tester,
    ) async {
      await monterCandidatures(
        tester,
        port: const CandidaturesDirectionIndisponible(),
      );
      expect(_cle('candidatures-indisponible'), findsOneWidget);
      expect(find.text(t.commun.etats.branchementServeur), findsOneWidget);
      expect(_cle('candidatures-recherche'), findsNothing);
      expect(find.byType(CarteAlertes), findsNothing);
      expect(find.byType(ActionPrincipale), findsNothing);
      for (final String code in _codesBruts) {
        expect(find.textContaining(code), findsNothing, reason: code);
      }
    });

    testWidgets(
      'sans port (production avant le lot serveur) : la meme phrase',
      (tester) async {
        await monterCandidatures(tester);
        expect(_cle('candidatures-indisponible'), findsOneWidget);
        expect(find.text(t.commun.etats.branchementServeur), findsOneWidget);
        expect(find.byType(EmptyState), findsNothing);
      },
    );

    testWidgets('chargement : un squelette, pas de fausse donnee', (
      tester,
    ) async {
      final Completer<void> jamais = Completer<void>();
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(lignes: _lignes(), attente: jamais),
      );
      expect(find.byType(Skeleton), findsOneWidget);
      expect(find.text('Amina Diallo'), findsNothing);
      expect(_cle('candidatures-recherche'), findsNothing);
      jamais.complete();
      await laisser(tester);
    });

    testWidgets(
      'contenu : nom, reference, salle, etat en mots, jamais un code',
      (tester) async {
        await monterCandidatures(
          tester,
          port: FauxCandidaturesDirection(lignes: _lignes()),
        );
        final r = t.admin.candidatures;
        final s = t.recrutement.salles;
        for (final String nom in <String>[
          'Amina Diallo',
          'Bilal Haddad',
          'Carla Mendes',
          'Dina Saidi',
          'Emna Gharbi',
          'Farah Nasser',
        ]) {
          expect(find.text(nom), findsOneWidget, reason: nom);
        }
        // La reference ne se montre qu'a la direction, a traits d'union
        // insecables.
        expect(find.text('CAND‑0000A1'), findsOneWidget);
        // Les noms de salle s'ecrivent en entier, dans les cartes comme dans les
        // puces de filtre.
        Finder dansCartes(String texte) => find.descendant(
          of: find.byType(CarteCandidature),
          matching: find.text(texte),
        );
        expect(dansCartes(s.examen), findsNWidgets(3));
        expect(dansCartes(s.verification), findsOneWidget);
        expect(dansCartes(s.prets), findsOneWidget);
        // Chaque etat par son mot.
        expect(find.text(r.etats.enExamen), findsOneWidget);
        expect(find.text(r.etats.entretienAPlanifier), findsOneWidget);
        expect(find.text(r.etats.indisponible), findsOneWidget);
        expect(find.text(r.etats.invitee), findsOneWidget);
        expect(find.text(r.etats.enPause), findsOneWidget);
        expect(find.text(r.etats.refusee), findsOneWidget);
        // Le versement et la derniere activite, avec leur mot.
        expect(
          find.text(r.ligne.versement(etat: r.etats.versement.aVerifier)),
          findsOneWidget,
        );
        expect(find.text(r.ligne.courrielAObtenir), findsOneWidget);
        expect(find.text(r.ligne.indicatifAConfirmer), findsOneWidget);
        expect(find.textContaining('20 oct. 2026'), findsOneWidget);
        // Le total reel du filtre.
        expect(find.text(r.total(n: 6)), findsOneWidget);
        for (final String code in _codesBruts) {
          expect(find.textContaining(code), findsNothing, reason: code);
        }
      },
    );

    testWidgets('aucun courriel, telephone ni genre dans le rendu', (
      tester,
    ) async {
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(lignes: _lignes()),
      );
      expect(find.textContaining('@'), findsNothing);
      expect(find.textContaining(RegExp(r'\+\d')), findsNothing);
      expect(find.textContaining(RegExp(r'\d{9,}')), findsNothing);
    });

    testWidgets('vide : un constat, ni alertes, ni recherche, ni filtres', (
      tester,
    ) async {
      await monterCandidatures(tester, port: FauxCandidaturesDirection());
      expect(_cle('candidatures-vide'), findsOneWidget);
      expect(find.text(t.admin.candidatures.vide), findsOneWidget);
      expect(find.byType(CarteAlertes), findsNothing);
      expect(_cle('candidatures-recherche'), findsNothing);
      expect(_boutonsPleins(tester), 0);
    });

    testWidgets('erreur : « Reessayer » relit la liste', (tester) async {
      final FauxCandidaturesDirection port = FauxCandidaturesDirection(
        lignes: _lignes(),
        erreurLister: (int appel) => appel == 1 ? StateError('panne') : null,
      );
      await monterCandidatures(tester, port: port);
      expect(_cle('candidatures-erreur'), findsOneWidget);
      expect(find.text(t.admin.candidatures.lectureEchec), findsOneWidget);
      // Aucune cause affirmee cote service.
      expect(find.textContaining('hors ligne'), findsNothing);
      expect(find.textContaining('connexion'), findsNothing);
      await tester.tap(find.text(t.commun.reessayer));
      await laisser(tester);
      expect(find.text('Amina Diallo'), findsOneWidget);
      expect(port.appels, hasLength(2));
    });

    testWidgets(
      'hors ligne, rien de lu : ce qui manque, sans redire le reseau',
      (tester) async {
        await monterCandidatures(
          tester,
          horsLigne: true,
          port: FauxCandidaturesDirection(
            erreurLister: (int _) => StateError('hors ligne'),
          ),
        );
        expect(find.byType(EtatSansDonnees), findsOneWidget);
        expect(find.text(t.admin.candidatures.sansDonnees), findsOneWidget);
      },
    );

    testWidgets('hors ligne, liste lue : elle reste, aucune action proposee', (
      tester,
    ) async {
      await monterCandidatures(
        tester,
        horsLigne: true,
        port: FauxCandidaturesDirection(
          lignes: _lignes(),
          capacitesRendues: capacitesQuiDecide,
        ),
      );
      expect(find.text('Amina Diallo'), findsOneWidget);
      expect(find.byType(EtatSansDonnees), findsNothing);
      await tester.tap(_cle('candidatures-selectionner'));
      await laisser(tester);
      await tester.tap(_cle('candidature-a1'));
      await laisser(tester);
      expect(
        find.text(t.admin.candidatures.selection.horsLigne),
        findsOneWidget,
      );
      expect(find.byKey(BarreSelection.cleAction), findsNothing);
      expect(_boutonsPleins(tester), 0);
    });

    testWidgets('acces refuse : une phrase, aucune reprise', (tester) async {
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(
          erreurLister: (int _) => const PermissionInsuffisante('lister'),
        ),
      );
      expect(_cle('candidatures-acces-refuse'), findsOneWidget);
      expect(find.text(t.admin.candidatures.accesRefuse), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsNothing);
    });

    testWidgets('genre du lecteur inconnu : quoi faire', (tester) async {
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(
          erreurLister: (int _) => const GenreLecteurInconnu(),
        ),
      );
      expect(_cle('candidatures-genre-inconnu'), findsOneWidget);
      expect(find.text(t.admin.candidatures.genreInconnuTitre), findsOneWidget);
      expect(find.text(t.admin.candidatures.genreInconnu), findsOneWidget);
      expect(find.byType(CarteAlertes), findsNothing);
    });

    testWidgets('exception du super-admin : un bandeau en tete, sinon rien', (
      tester,
    ) async {
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(
          lignes: _lignes(),
          capacitesRendues: const CapacitesCandidatures(
            peutLire: true,
            peutLireHorsGenre: true,
          ),
        ),
      );
      expect(_cle('candidatures-exception'), findsOneWidget);
      expect(find.text(t.admin.candidatures.exception.titre), findsOneWidget);
      expect(find.text(t.admin.candidatures.exception.message), findsOneWidget);
    });

    testWidgets('sans exception : aucun bandeau', (tester) async {
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(lignes: _lignes()),
      );
      expect(_cle('candidatures-exception'), findsNothing);
    });
  });

  group('alertes : seules celles que le serveur sert (REPRISE-CAND-3)', () {
    testWidgets('deux alertes servies, deux nulles jamais affichees', (
      tester,
    ) async {
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(lignes: _lignes()),
      );
      expect(find.byType(CarteAlertes), findsOneWidget);
      final s = t.admin.candidatures.liste.synthese;
      // Servies : une candidature a completer en cours, hors pause (celle de
      // Emna est en pause : elle n'entre dans aucune alerte) -> 0 ici.
      expect(
        find.byKey(CarteAlertes.cleAlerte('informationsManquantes')),
        findsOneWidget,
      );
      expect(
        find.byKey(CarteAlertes.cleAlerte('confirmeesIndisponibles')),
        findsOneWidget,
      );
      expect(find.text(s.informationsManquantes(n: 0)), findsOneWidget);
      // Nulles cote serveur (lister_candidatures rend NULL) : ni mot, ni
      // « Disponible au branchement serveur », ni zero invente.
      final a = t.admin.candidatures.alertes;
      expect(find.byKey(CarteAlertes.cleAlerte('bloquees')), findsNothing);
      expect(
        find.byKey(CarteAlertes.cleAlerte('entretiensEnRetard')),
        findsNothing,
      );
      expect(find.text(a.bloquees), findsNothing);
      expect(find.text(a.entretiensEnRetard), findsNothing);
      expect(find.text(t.commun.etats.branchementServeur), findsNothing);
      expect(find.text(a.rien), findsNothing);
    });

    testWidgets('quatre alertes servies a zero : « Rien a traiter » seul', (
      tester,
    ) async {
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(
          lignes: _lignes(),
          alertes: const CompteursAlertes(
            bloquees: 0,
            entretiensEnRetard: 0,
            informationsManquantes: 0,
            confirmeesIndisponibles: 0,
          ),
        ),
      );
      expect(find.byKey(CarteAlertes.cleRien), findsOneWidget);
      expect(find.text(t.admin.candidatures.alertes.rien), findsOneWidget);
      expect(
        find.byKey(CarteAlertes.cleAlerte('informationsManquantes')),
        findsNothing,
      );
    });

    testWidgets('les nombres sont ceux du serveur, jamais recalcules', (
      tester,
    ) async {
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(
          lignes: _lignes(),
          alertes: const CompteursAlertes(
            informationsManquantes: 12,
            confirmeesIndisponibles: 2,
          ),
        ),
      );
      final s = t.admin.candidatures.liste.synthese;
      expect(find.text(s.informationsManquantes(n: 12)), findsOneWidget);
      expect(find.text(s.confirmeesIndisponibles(n: 2)), findsOneWidget);
      expect(find.byKey(CarteAlertes.cleRien), findsNothing);
    });

    testWidgets('le jour ou le serveur sert « Bloquees », elle s\'affiche', (
      tester,
    ) async {
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(
          lignes: _lignes(),
          alertes: const CompteursAlertes(
            bloquees: 7,
            entretiensEnRetard: 3,
            informationsManquantes: 12,
            confirmeesIndisponibles: 2,
          ),
        ),
      );
      final a = t.admin.candidatures.alertes;
      expect(find.text(a.bloquees), findsOneWidget);
      expect(find.text(a.entretiensEnRetard), findsOneWidget);
      for (final String n in <String>['7', '3']) {
        expect(
          find.descendant(
            of: find.byType(CarteAlertes),
            matching: find.text(n),
          ),
          findsOneWidget,
          reason: n,
        );
      }
    });

    testWidgets('une alerte n\'est pas pressable', (tester) async {
      final FauxCandidaturesDirection port = FauxCandidaturesDirection(
        lignes: _lignes(),
        alertes: const CompteursAlertes(
          informationsManquantes: 12,
          confirmeesIndisponibles: 2,
        ),
      );
      await monterCandidatures(tester, port: port);
      final int avant = port.appels.length;
      await tester.tap(
        find.byKey(CarteAlertes.cleAlerte('informationsManquantes')),
        warnIfMissed: false,
      );
      await laisser(tester);
      expect(port.appels, hasLength(avant));
    });
  });

  group('filtres, tri, pages : tout part au serveur', () {
    testWidgets('puces des salles avec compteurs, rendus par le serveur', (
      tester,
    ) async {
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(lignes: _lignes()),
      );
      int? compteur(String cle) =>
          tester.widget<FilterPill>(_cle(cle)).compteur;
      // En cours seulement : Farah (refusee) n'est pas comptee.
      expect(compteur('candidatures-filtre-examen'), 2);
      expect(compteur('candidatures-filtre-verification'), 1);
      expect(compteur('candidatures-filtre-prets'), 1);
      expect(compteur('candidatures-filtre-invitees'), 1);
      expect(
        tester.widget<FilterPill>(_cle('candidatures-filtre-toutes')).compteur,
        isNull,
      );
    });

    testWidgets('« Gardees pour suivi » : ni puce ni mot sans le serveur', (
      tester,
    ) async {
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(lignes: _lignes()),
      );
      expect(_cle('candidatures-filtre-gardees'), findsNothing);
      expect(find.text(t.admin.candidatures.filtres.gardees), findsNothing);
    });

    testWidgets('« Gardees pour suivi » : rendu quand le serveur l\'ouvre', (
      tester,
    ) async {
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(
          lignes: _lignes(),
          capacitesRendues: const CapacitesCandidatures(
            peutLire: true,
            gestes: <String, bool>{'garderPourSuivi': true},
          ),
        ),
        largeur: 1440,
      );
      expect(
        find.text(t.admin.candidatures.filtres.gardees).hitTestable(),
        findsWidgets,
      );
    });

    testWidgets(
      'une puce de salle filtre au serveur, la retoucher la relache',
      (tester) async {
        final FauxCandidaturesDirection port = FauxCandidaturesDirection(
          lignes: _lignes(),
        );
        await monterCandidatures(tester, port: port);
        await toucherFiltre(tester, _cle('candidatures-filtre-examen'));
        await laisser(tester);
        expect(
          port.appels.last.filtre.etape,
          EtapeCandidature.prequalification,
        );
        expect(port.appels.last.page, 1);
        expect(find.text('Bilal Haddad'), findsNothing);
        expect(find.text('Amina Diallo'), findsOneWidget);
        await toucherFiltre(tester, _cle('candidatures-filtre-examen'));
        await laisser(tester);
        expect(port.appels.last.filtre.etape, isNull);
        expect(find.text('Bilal Haddad'), findsOneWidget);
      },
    );

    testWidgets('la recherche part 300 ms apres la derniere frappe', (
      tester,
    ) async {
      final FauxCandidaturesDirection port = FauxCandidaturesDirection(
        lignes: _lignes(),
      );
      await monterCandidatures(tester, port: port);
      final int avant = port.appels.length;
      await tester.enterText(_cle('candidatures-recherche'), 'bil');
      await tester.pump(const Duration(milliseconds: 100));
      expect(port.appels, hasLength(avant));
      await tester.pump(const Duration(milliseconds: 300));
      await laisser(tester);
      expect(port.appels.last.filtre.recherche, 'bil');
      expect(find.text('Bilal Haddad'), findsOneWidget);
      expect(find.text('Amina Diallo'), findsNothing);
      expect(find.text(t.admin.candidatures.total(n: 1)), findsOneWidget);
    });

    testWidgets('recherche sans resultat : filtres rappeles, « Effacer »', (
      tester,
    ) async {
      final FauxCandidaturesDirection port = FauxCandidaturesDirection(
        lignes: _lignes(),
      );
      await monterCandidatures(tester, port: port);
      await tester.enterText(_cle('candidatures-recherche'), 'zzz');
      await laisser(tester);
      expect(_cle('candidatures-aucun-resultat'), findsOneWidget);
      expect(find.text(t.admin.candidatures.aucunResultat), findsOneWidget);
      // Les filtres posés sont rappeles, avec la recherche.
      expect(
        find.text(
          t.admin.candidatures.rappel.filtres(
            filtres: t.admin.candidatures.rappel.recherche(texte: 'zzz'),
          ),
        ),
        findsOneWidget,
      );
      // La recherche et les commandes restent : on peut corriger.
      expect(_cle('candidatures-recherche'), findsOneWidget);
      await tester.tap(find.text(t.admin.journal.effacerFiltres));
      await laisser(tester);
      expect(port.appels.last.filtre.estVide, isTrue);
      expect(find.text('Amina Diallo'), findsOneWidget);
    });

    testWidgets('un menu « Plus » filtre au serveur : l\'etat', (tester) async {
      final FauxCandidaturesDirection port = FauxCandidaturesDirection(
        lignes: _lignes(),
      );
      await monterCandidatures(tester, port: port);
      await ouvrirMenuFiltre(tester, _cle('candidatures-filtre-etat'));
      await tester.tap(
        find.text(t.admin.candidatures.etats.entretienAPlanifier).last,
      );
      await tester.pumpAndSettle();
      await fermerPlus(tester);
      await laisser(tester);
      expect(port.appels.last.filtre.etat, EtatCandidature.entretienAPlanifier);
      expect(find.text('Bilal Haddad'), findsOneWidget);
      expect(find.text('Amina Diallo'), findsNothing);
    });

    testWidgets('le tri part au serveur et revient a la page 1', (
      tester,
    ) async {
      final FauxCandidaturesDirection port = FauxCandidaturesDirection(
        lignes: lignesEnMasse(120),
      );
      await monterCandidatures(tester, port: port);
      expect(port.appels.last.tri, TriCandidatures.activite);
      // Page 2 d'abord : un tri qui change revient a la page 1.
      await _pageSuivante(tester);
      expect(port.appels.last.page, 2);
      final Finder tri = find.descendant(
        of: _cle('candidatures-tri'),
        matching: find.text(t.admin.candidatures.tri.reception),
      );
      await tester.ensureVisible(tri);
      await tester.pump();
      await tester.tap(tri);
      await laisser(tester);
      expect(port.appels.last.tri, TriCandidatures.recente);
      expect(port.appels.last.page, 1);
    });

    testWidgets('1 000 lignes : une page de 50 a la fois, total reel', (
      tester,
    ) async {
      final FauxCandidaturesDirection port = FauxCandidaturesDirection(
        lignes: lignesEnMasse(1000),
      );
      await monterCandidatures(tester, port: port);
      expect(port.appels, hasLength(1));
      expect(port.appels.single.page, 1);
      expect(find.byType(CarteCandidature), findsNWidgets(50));
      expect(find.text(t.admin.candidatures.total(n: 1000)), findsOneWidget);
      expect(
        find.text(
          t.admin.candidatures.resume(debut: '1', fin: '50', total: '1000'),
        ),
        findsOneWidget,
      );
      expect(
        find.text(t.commun.formats.pageSur(page: '1', total: '20')),
        findsOneWidget,
      );
      // Page suivante : une seule page de plus est demandee.
      await _pageSuivante(tester);
      await laisser(tester);
      expect(port.appels, hasLength(2));
      expect(port.appels.last.page, 2);
      expect(find.byType(CarteCandidature), findsNWidgets(50));
      expect(find.text('Personne 0050'), findsOneWidget);
      expect(find.text('Personne 0000'), findsNothing);
      expect(
        find.text(t.commun.formats.pageSur(page: '2', total: '20')),
        findsOneWidget,
      );
      // Un changement de filtre revient a la page 1.
      await toucherFiltre(tester, _cle('candidatures-filtre-prets'));
      await laisser(tester);
      expect(port.appels.last.page, 1);
    });
  });

  group('selection', () {
    testWidgets(
      'un filtre change : la selection est retiree, et la page le dit',
      (tester) async {
        final FauxCandidaturesDirection port = FauxCandidaturesDirection(
          lignes: _lignes(),
          capacitesRendues: capacitesGestes,
        );
        await monterCandidatures(tester, port: port);
        await tester.tap(_cle('candidatures-selectionner'));
        await laisser(tester);
        await tester.tap(_cle('candidature-a1'));
        await laisser(tester);
        expect(find.byKey(CandidaturesPage.cleBarreLot), findsOneWidget);
        await toucherFiltre(tester, _cle('candidatures-filtre-examen'));
        await laisser(tester);
        expect(find.byKey(CandidaturesPage.cleBarreLot), findsNothing);
        expect(
          find.text(t.admin.candidatures.lot.selectionRetiree),
          findsOneWidget,
        );
      },
    );

    testWidgets('le tri change : la selection est gardee, aucun message', (
      tester,
    ) async {
      final FauxCandidaturesDirection port = FauxCandidaturesDirection(
        lignes: _lignes(),
        capacitesRendues: capacitesGestes,
      );
      await monterCandidatures(tester, port: port);
      await tester.tap(_cle('candidatures-selectionner'));
      await laisser(tester);
      await tester.tap(_cle('candidature-a1'));
      await laisser(tester);
      final Finder reception = find.text(t.admin.candidatures.tri.reception);
      await tester.ensureVisible(reception.first);
      await tester.tap(reception.first);
      await laisser(tester);
      expect(find.byKey(CandidaturesPage.cleBarreLot), findsOneWidget);
      expect(
        find.text(t.admin.candidatures.lot.selectionRetiree),
        findsNothing,
      );
    });

    Future<FauxCandidaturesDirection> monter(
      WidgetTester tester, {
      bool horsLigne = false,
      double largeur = 390,
      double hauteur = 3000,
      CapacitesCandidatures caps = capacitesQuiDecide,
    }) async {
      final FauxCandidaturesDirection port = FauxCandidaturesDirection(
        lignes: _lignes(),
        capacitesRendues: caps,
      );
      await monterCandidatures(
        tester,
        port: port,
        horsLigne: horsLigne,
        largeur: largeur,
        hauteur: hauteur,
      );
      return port;
    }

    testWidgets('sans le droit d\'agir en lot : aucun lien « Selectionner »', (
      tester,
    ) async {
      await monter(tester, caps: capacitesQuiLit);
      expect(_cle('candidatures-selectionner'), findsNothing);
      expect(_boutonsPleins(tester), 0);
    });

    testWidgets('zero bouton plein sans selection, un seul avec', (
      tester,
    ) async {
      await monter(tester);
      expect(_cle('candidatures-selectionner'), findsOneWidget);
      expect(_boutonsPleins(tester), 0);
      await tester.tap(_cle('candidatures-selectionner'));
      await laisser(tester);
      // En mode selection sans ligne retenue : pas de barre, pas de bouton.
      expect(find.byKey(BarreSelection.cleBarre), findsNothing);
      expect(_boutonsPleins(tester), 0);
      await tester.tap(_cle('candidature-a1'));
      await laisser(tester);
      await tester.tap(_cle('candidature-b2'));
      await laisser(tester);
      expect(find.byKey(CandidaturesPage.cleBarreLot), findsOneWidget);
      expect(
        find.text(t.admin.candidatures.lot.selectionnees(n: 2)),
        findsOneWidget,
      );
      // REPRISE-CAND-1 : la barre compacte du lot ; ses operations ne sont
      // pas des boutons pleins (K-56).
      expect(_boutonsPleins(tester), 0);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets(
      'une operation du lot ouvre l\'apercu avec les identifiants retenus',
      (tester) async {
        final FauxCandidaturesDirection port = FauxCandidaturesDirection(
          lignes: _lignes(),
          capacitesRendues: capacitesGestes,
        );
        await monterCandidatures(tester, port: port);
        await tester.tap(_cle('candidatures-selectionner'));
        await laisser(tester);
        await tester.tap(_cle('candidature-c3'));
        await laisser(tester);
        await tester.tap(_cle('candidature-a1'));
        await laisser(tester);
        await tester.tap(
          find.byKey(CandidaturesPage.cleOperationLot(GesteLot.mettreEnPause)),
        );
        await laisser(tester);
        expect(port.appelsApercuLot, hasLength(1));
        expect(port.appelsApercuLot.single.geste, GesteLot.mettreEnPause);
        expect(
          port.appelsApercuLot.single.ids,
          unorderedEquals(<String>['a1', 'c3']),
        );
      },
    );

    testWidgets('une operation que les capacites ferment n\'est pas rendue', (
      tester,
    ) async {
      // capacitesQuiDecide ouvre l'action en lot, mais aucun des trois gestes.
      await monter(tester);
      await tester.tap(_cle('candidatures-selectionner'));
      await laisser(tester);
      await tester.tap(_cle('candidature-a1'));
      await laisser(tester);
      expect(find.byKey(CandidaturesPage.cleBarreLot), findsOneWidget);
      for (final GesteLot g in GesteLot.values) {
        expect(find.byKey(CandidaturesPage.cleOperationLot(g)), findsNothing);
      }
    });

    testWidgets(
      'toucher une ligne retenue la relache, « Tout relacher » sort du mode',
      (tester) async {
        await monter(tester);
        await tester.tap(_cle('candidatures-selectionner'));
        await laisser(tester);
        await tester.tap(_cle('candidature-a1'));
        await laisser(tester);
        expect(find.byKey(BarreSelection.cleBarre), findsOneWidget);
        await tester.tap(_cle('candidature-a1'));
        await laisser(tester);
        expect(find.byKey(BarreSelection.cleBarre), findsNothing);
        await tester.tap(_cle('candidature-a1'));
        await laisser(tester);
        await tester.tap(find.byKey(BarreSelection.cleRelacher));
        await laisser(tester);
        expect(find.byKey(BarreSelection.cleBarre), findsNothing);
        expect(find.byType(IndicateurCase), findsNothing);
        expect(
          find.text(t.admin.candidatures.selection.selectionner),
          findsOneWidget,
        );
      },
    );

    testWidgets('la selection se garde d\'une page a l\'autre', (tester) async {
      final FauxCandidaturesDirection port = FauxCandidaturesDirection(
        lignes: lignesEnMasse(120),
        capacitesRendues: capacitesQuiDecide,
      );
      await monterCandidatures(tester, port: port);
      await tester.tap(_cle('candidatures-selectionner'));
      await laisser(tester);
      await tester.tap(_cle('candidature-m0'));
      await laisser(tester);
      await _pageSuivante(tester);
      await laisser(tester);
      await tester.tap(_cle('candidature-m50'));
      await laisser(tester);
      final lot = t.admin.candidatures.lot;
      expect(
        find.text(
          lot.avecDont(
            selection: lot.selectionnees(n: 2),
            dont: lot.dontPage(n: 1),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('1440 : le tableau coche aussi sa case, une seule barre', (
      tester,
    ) async {
      await monter(tester, largeur: 1440, hauteur: 1800);
      expect(find.byType(DataCollection<LigneCandidature>), findsOneWidget);
      await tester.tap(_cle('candidatures-selectionner'));
      await laisser(tester);
      await tester.tap(_cle('candidature-a1'));
      await laisser(tester);
      expect(
        find.text(t.admin.candidatures.lot.selectionnees(n: 1)),
        findsOneWidget,
      );
      expect(
        tester.widget<Checkbox>(_cle('candidature-case-a1')).value,
        isTrue,
      );
      expect(
        tester.widget<Checkbox>(_cle('candidature-case-b2')).value,
        isFalse,
      );
      verifierUnSeulBoutonPlein(tester);
    });
  });

  group('ouvrir une candidature', () {
    testWidgets(
      'sans destination (ADM-21 pas construit) : la ligne ne se touche pas',
      (tester) async {
        await monterCandidatures(
          tester,
          port: FauxCandidaturesDirection(lignes: _lignes()),
        );
        expect(tester.widget<AppCard>(_cle('candidature-a1')).onPress, isNull);
      },
    );

    testWidgets('avec une destination : la ligne entiere ouvre', (
      tester,
    ) async {
      LigneCandidature? ouverte;
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(lignes: _lignes()),
        ouvrir: (LigneCandidature l) => ouverte = l,
      );
      await tester.tap(_cle('candidature-b2'));
      await laisser(tester);
      expect(ouverte?.id, 'b2');
    });

    testWidgets('en selection, la ligne coche au lieu d\'ouvrir', (
      tester,
    ) async {
      LigneCandidature? ouverte;
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(
          lignes: _lignes(),
          capacitesRendues: capacitesQuiDecide,
        ),
        ouvrir: (LigneCandidature l) => ouverte = l,
      );
      await tester.tap(_cle('candidatures-selectionner'));
      await laisser(tester);
      await tester.tap(_cle('candidature-b2'));
      await laisser(tester);
      expect(ouverte, isNull);
    });
  });

  group('invitations (CAND-F01)', () {
    testWidgets('sans port d\'invitation : aucun lien', (tester) async {
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(lignes: _lignes()),
      );
      expect(_cle('candidatures-invitations'), findsNothing);
    });

    testWidgets('avec un port : le lien mene a la page des invitations', (
      tester,
    ) async {
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(lignes: _lignes()),
        invitations: true,
      );
      await tester.ensureVisible(_cle('candidatures-invitations'));
      await tester.tap(_cle('candidatures-invitations'));
      await laisser(tester);
      expect(find.text('temoin:/admin/personnes/invitations'), findsOneWidget);
    });

    testWidgets('le comptable seul suffit au lien', (tester) async {
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(lignes: _lignes()),
        comptable: true,
      );
      expect(_cle('candidatures-invitations'), findsOneWidget);
    });

    testWidgets('le lien est en tete, avant les alertes', (tester) async {
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(lignes: _lignes()),
        invitations: true,
      );
      expect(
        tester.getTopLeft(_cle('candidatures-invitations')).dy,
        lessThan(tester.getTopLeft(find.byType(CarteAlertes)).dy),
      );
    });

    // La page des invitations n'a plus d'onglet : ce lien est le seul chemin
    // vers elle, il doit rester dans tous les etats de la file.
    group('le lien reste dans tous les etats', () {
      testWidgets('file vide', (tester) async {
        await monterCandidatures(
          tester,
          port: FauxCandidaturesDirection(),
          invitations: true,
        );
        expect(_cle('candidatures-vide'), findsOneWidget);
        expect(_cle('candidatures-invitations'), findsOneWidget);
      });

      testWidgets('serveur pas encore branche (port absent)', (tester) async {
        await monterCandidatures(tester, invitations: true);
        expect(_cle('candidatures-indisponible'), findsOneWidget);
        expect(_cle('candidatures-invitations'), findsOneWidget);
      });

      testWidgets('capacite indisponible', (tester) async {
        await monterCandidatures(
          tester,
          port: const CandidaturesDirectionIndisponible(),
          invitations: true,
        );
        expect(_cle('candidatures-invitations'), findsOneWidget);
      });

      testWidgets('lecture en erreur', (tester) async {
        await monterCandidatures(
          tester,
          port: FauxCandidaturesDirection(
            lignes: _lignes(),
            erreurLister: (int _) => StateError('panne'),
          ),
          invitations: true,
        );
        expect(_cle('candidatures-erreur'), findsOneWidget);
        expect(_cle('candidatures-invitations'), findsOneWidget);
      });

      testWidgets('acces refuse', (tester) async {
        await monterCandidatures(
          tester,
          port: FauxCandidaturesDirection(
            lignes: _lignes(),
            erreurLister: (int _) => const PermissionInsuffisante('lister'),
          ),
          invitations: true,
        );
        expect(_cle('candidatures-acces-refuse'), findsOneWidget);
        expect(_cle('candidatures-invitations'), findsOneWidget);
      });
    });
  });

  group('gabarits', () {
    testWidgets('1440 : un tableau dense, ses colonnes nommees', (
      tester,
    ) async {
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(lignes: _lignes()),
        largeur: 1440,
        hauteur: 1800,
      );
      expect(find.byType(DataCollection<LigneCandidature>), findsOneWidget);
      expect(find.byType(CarteCandidature), findsNothing);
      final c = t.admin.candidatures.colonnes;
      for (final String titre in <String>[
        c.nom,
        c.salle,
        c.etat,
        c.pays,
        c.versement,
        c.activite,
      ]) {
        expect(
          find.descendant(
            of: find.byType(DataCollection<LigneCandidature>),
            matching: find.text(titre),
          ),
          findsOneWidget,
          reason: titre,
        );
      }
      expect(tester.takeException(), isNull);
      expect(_boutonsPleins(tester), 0);
    });

    testWidgets('390 : une carte par candidature, pas de tableau', (
      tester,
    ) async {
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(lignes: _lignes()),
      );
      expect(find.byType(CarteCandidature), findsNWidgets(6));
      expect(find.byType(DataCollection<LigneCandidature>), findsNothing);
    });

    testWidgets('1440 a texte x2 : le tableau cede aux cartes', (tester) async {
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(lignes: _lignes()),
        largeur: 1440,
        hauteur: 2400,
        echelle: 2,
      );
      expect(find.byType(CarteCandidature), findsNWidgets(6));
      expect(find.byType(DataCollection<LigneCandidature>), findsNothing);
      expect(tester.takeException(), isNull);
    });

    // Le rendu des mots, avec les vraies polices, est dans
    // `candidatures_lisibilite_test.dart` : ici le texte de test (Ahem) est
    // plus large que n'importe quelle police du produit.
    for (final TextDirection direction in <TextDirection>[
      TextDirection.ltr,
      TextDirection.rtl,
    ]) {
      testWidgets('320 px, texte x2, $direction : aucun debordement', (
        tester,
      ) async {
        if (direction == TextDirection.rtl) {
          await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
        }
        await monterCandidatures(
          tester,
          port: FauxCandidaturesDirection(
            lignes: _lignes(),
            capacitesRendues: capacitesQuiDecide,
          ),
          largeur: 320,
          hauteur: 6000,
          echelle: 2,
          direction: direction,
        );
        expect(tester.takeException(), isNull);
        verifierUnSeulBoutonPlein(tester);
        await tester.tap(_cle('candidatures-selectionner'));
        await laisser(tester);
        await tester.tap(_cle('candidature-a1'));
        await laisser(tester);
        expect(tester.takeException(), isNull);
        expect(_boutonsPleins(tester), 0);
        verifierUnSeulBoutonPlein(tester);
      });
    }

    testWidgets('en arabe : les mots du module, pas le francais', (
      tester,
    ) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await monterCandidatures(
        tester,
        port: FauxCandidaturesDirection(lignes: _lignes()),
        direction: TextDirection.rtl,
      );
      final r = t.admin.candidatures;
      expect(r.titre, isNot('Candidatures'));
      expect(find.text(r.titre), findsWidgets);
      // REPRISE-CAND-3 : l'alerte servie se dit en arabe.
      expect(
        find.text(r.liste.synthese.informationsManquantes(n: 0)),
        findsOneWidget,
      );
      expect(find.text(t.recrutement.salles.verification), findsWidgets);
      expect(find.textContaining('Candidatures'), findsNothing);
      expect(find.textContaining('Rechercher'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets(
    'en arabe, la date garde l\'ordre de sa langue, sans isolat interne',
    (tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      final String date = dateCourteCandidature(DateTime.utc(2026, 10, 22, 12));
      // Un isolat dans un isolat ne voit aucune lettre forte : la date se lisait
      // « 2026 أكتوبر 22 ». Le texte qui la porte l'isole deja une fois.
      expect(date.contains('\u2068'), isFalse);
      expect(date.contains('\u2069'), isFalse);
      expect(date, contains('22'));
      expect(date, contains('2026'));
      expect(date.indexOf('22'), lessThan(date.indexOf('2026')));
      final String phrase = t.admin.candidatures.ligne.activite(date: date);
      expect(RegExp('[\u0600-\u06FF]').hasMatch(phrase), isTrue);
    },
  );

  test('capacites : une cle absente vaut faux, jamais un droit suppose', () {
    final CapacitesCandidatures c = CapacitesCandidatures.depuisJson(
      const <String, dynamic>{'peutLire': true, 'peutDecider': true},
    );
    expect(c.peutLire, isTrue);
    expect(c.peutAgirEnLot, isFalse);
    expect(c.peutGarderPourSuivi, isFalse);
    expect(c.peutLireHorsGenre, isFalse);
    expect(c.peutImporter, isFalse);
  });

  test('un compteur non servi reste nul', () {
    final CompteursAlertes a = CompteursAlertes.depuisJson(
      const <String, dynamic>{'informationsManquantes': 4, 'bloquees': null},
    );
    expect(a.informationsManquantes, 4);
    expect(a.bloquees, isNull);
    expect(a.tousServis, isFalse);
    expect(a.rienATraiter, isFalse);
  });

  test('capacite indisponible : la dependance est celle de la file', () {
    expect(
      const CapaciteIndisponible(dependanceFileCandidatures).dependance,
      'CAND-BR-02',
    );
  });
}
