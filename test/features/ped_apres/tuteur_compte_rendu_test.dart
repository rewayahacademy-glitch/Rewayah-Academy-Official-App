// PED-APRES-1, TUT-PED-APR-01 : le compte rendu pedagogique du detail de
// seance du tuteur (spec V1 du 11/10/2026, section 3 et scenarios A01 a A14,
// A17, A19, A22 cote famille).
//
// L'application se monte sur son VRAI routeur et sa vraie coquille Tuteur
// (foyer fictif A). Le serveur est un simulateur (`FauxPartagePedagogique`)
// qui applique la priorite du contrat : la direction decide, la famille lit.
// Aucun reseau, aucun Supabase.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/capacites/port_partage_pedagogique.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart'
    show DisqueRetour;
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/lien_fleche.dart';
import 'package:rewayah_academy/features/suivi_foyer/bloc_compte_rendu.dart';
import 'package:rewayah_academy/features/suivi_foyer/detail_seance_page.dart';
import 'package:rewayah_academy/features/suivi_foyer/suivi_foyer_page.dart';

import '../../fixtures/ped_apres/faux_partage_pedagogique.dart';
import '../../router/support_routeur.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart' show FausseSourceSession, FauxServiceReseau;
import '../historique/support_historique.dart';

const String _a1 = 'foyer-a-eleve-1';
const String _a2 = 'foyer-a-eleve-2';

const CompteRenduFamille _contenuA1 = CompteRenduFamille(
  etat: EtatCompteRendu.partage,
  travaille: 'Sourate Al-Baqara, versets 20 a 30',
  appreciation: 'Tres bonne implication de Yusuf.',
  aRenforcer: <String>['Regles du madd', 'Certaines liaisons'],
  aPreparer: <String>['Reviser les versets 31 a 40'],
  commentairePartage: 'Belle regularite dans son travail.',
);

const CompteRenduFamille _contenuA2 = CompteRenduFamille(
  etat: EtatCompteRendu.partage,
  travaille: 'TRAVAIL PROPRE A A2 : sourate An-Naba',
  appreciation: 'APPRECIATION PROPRE A A2',
);

FauxPartagePedagogique _serveur() => FauxPartagePedagogique()
  ..rapports[('s-presente', _a1)] = RapportSim(contenu: _contenuA1)
  ..rapports[('s-retard', _a1)] = RapportSim(contenu: _contenuA1)
  ..rapports[('s-a2', _a2)] = RapportSim(contenu: _contenuA2);

Future<GoRouter> _monter(
  WidgetTester tester,
  PortPartagePedagogique? port, {
  Size taille = const Size(390, 1800),
  bool horsLigne = false,
  ThemeMode mode = ThemeMode.light,
}) => monterHistorique(
  tester,
  taille: taille,
  horsLigne: horsLigne,
  mode: mode,
  autres: <Override>[
    if (port != null) portPartagePedagogiqueProvider.overrideWithValue(port),
  ],
);

Future<void> _aller(
  WidgetTester tester,
  GoRouter routeur,
  String seanceId, {
  String eleve = _a1,
}) async {
  routeur.go('${Routes.seancePour(seanceId)}?eleve=$eleve');
  await stabiliser(tester);
}

final l = t.historique.compteRendu;

Finder _titre() => find.text(l.titre);

void main() {
  group('A01 : partage actif, cahier valide', () {
    testWidgets('le tuteur lit uniquement le compte rendu de son enfant', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique serveur = _serveur();
      final GoRouter routeur = await _monter(tester, serveur);
      await _aller(tester, routeur, 's-presente');

      expect(find.byType(DetailSeancePage), findsOneWidget);
      // L'ordre de la spec : travaille, appreciation, a renforcer, a preparer,
      // commentaire partage.
      expect(_titre(), findsOneWidget);
      final List<String> ordre = <String>[
        l.travaille,
        l.appreciation,
        l.aRenforcer,
        l.aPreparer,
        l.commentaire,
      ];
      double precedent = -1;
      for (final String libelle in ordre) {
        expect(find.text(libelle), findsOneWidget, reason: libelle);
        final double y = tester.getTopLeft(find.text(libelle)).dy;
        expect(y, greaterThan(precedent), reason: 'ordre : $libelle');
        precedent = y;
      }
      expect(find.text('Sourate Al-Baqara, versets 20 a 30'), findsOneWidget);
      expect(find.text('Regles du madd'), findsOneWidget);
      expect(find.text('Certaines liaisons'), findsOneWidget);
      // Lecture seule : aucun bouton de modification, aucun bouton plein.
      verifierUnSeulBoutonPlein(tester, maximum: 0);
      // Le serveur n'a ete interroge que pour cet eleve et cette seance.
      expect(serveur.appels, <String>['compteRenduFamille']);
      // Jamais l'enfant d'un autre : ni son contenu...
      expect(find.textContaining('TRAVAIL PROPRE A A2'), findsNothing);
      // ... et les deux cartes existantes restent la.
      expect(find.text(t.historique.seance.blocSeance), findsOneWidget);
      expect(find.text(t.historique.seance.presence), findsWidgets);
    });

    testWidgets('les liens vers le travail et la progression existent '
        'pour la meme classe et le meme eleve', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(tester, _serveur());
      await _aller(tester, routeur, 's-presente');
      await tester.ensureVisible(find.text(l.voirTravail));
      expect(find.text(l.voirTravail), findsOneWidget);
      expect(find.text(l.voirProgression), findsOneWidget);
      await tester.tap(find.text(l.voirProgression));
      await stabiliser(tester);
      expect(lieu(routeur), contains('/progression'));
      expect(lieu(routeur), contains('eleve=$_a1'));
    });
  });

  group('A02 : la regle de classe passe a « Desactive »', () {
    testWidgets('rechargement, retour et lien direct : plus de compte rendu, '
        'les informations generales restent lisibles', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique serveur = _serveur();
      final GoRouter routeur = await _monter(tester, serveur);
      await _aller(tester, routeur, 's-presente');
      expect(find.text('Sourate Al-Baqara, versets 20 a 30'), findsOneWidget);

      // La direction desactive. Le tuteur recharge : sort puis revient.
      serveur.classeActive = false;
      routeur.go(Routes.tuteurSuivi);
      await stabiliser(tester);
      expect(find.byType(SuiviFoyerPage), findsOneWidget);
      await _aller(tester, routeur, 's-presente');

      expect(find.text('Sourate Al-Baqara, versets 20 a 30'), findsNothing);
      expect(find.text(l.nonDisponibleTitre), findsOneWidget);
      expect(find.text(l.nonPartagePhrase), findsOneWidget);
      // Les informations generales (seance, presence) restent lisibles.
      expect(find.text(t.historique.seance.blocSeance), findsOneWidget);
      expect(find.text('18:00 - 19:00'), findsOneWidget);
      expect(find.text(t.historique.seance.presence), findsWidgets);
      // Aucune demande d'acces artificielle.
      expect(find.byType(LienFleche), findsNothing);

      // Un lien direct (adresse collee) donne la meme chose.
      routeur.go('${Routes.seancePour('s-retard')}?eleve=$_a1');
      await stabiliser(tester);
      expect(find.text(l.nonPartagePhrase), findsOneWidget);
    });
  });

  group('A03 et A04 : exceptions d eleve', () {
    testWidgets('A03 : classe desactivee, eleve force actif : seul cet eleve '
        'beneficie de l exception', (WidgetTester tester) async {
      final FauxPartagePedagogique serveur = _serveur()
        ..classeActive = false
        ..regles[_a1] = ReglePartageEleve.toujours;
      final GoRouter routeur = await _monter(tester, serveur);
      await _aller(tester, routeur, 's-presente');
      expect(find.text('Sourate Al-Baqara, versets 20 a 30'), findsOneWidget);

      // L'autre eleve du foyer, meme classe : pas d'exception, pas de compte
      // rendu.
      await _aller(tester, routeur, 's-a2', eleve: _a2);
      expect(find.textContaining('TRAVAIL PROPRE A A2'), findsNothing);
      expect(find.text(l.nonPartagePhrase), findsOneWidget);
    });

    testWidgets('A04 : classe activee, eleve force inactif : le bloc est '
        'masque sans bloquer l Historique', (WidgetTester tester) async {
      final FauxPartagePedagogique serveur = _serveur()
        ..regles[_a1] = ReglePartageEleve.jamais;
      final GoRouter routeur = await _monter(tester, serveur);
      await _aller(tester, routeur, 's-presente');
      expect(find.text(l.nonPartagePhrase), findsOneWidget);
      expect(find.text('Sourate Al-Baqara, versets 20 a 30'), findsNothing);
      // L'Historique, lui, reste atteignable et complet.
      await tester.tap(find.byType(DisqueRetour));
      await stabiliser(tester);
      expect(find.byType(SuiviFoyerPage), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('seance-s-presente-$_a1')),
        findsOneWidget,
      );
    });
  });

  group('A06 et A07 : revocation', () {
    testWidgets('A07 : rapport revoque, classe activee : masque malgre '
        'l activation automatique', (WidgetTester tester) async {
      final FauxPartagePedagogique serveur = _serveur();
      serveur.rapports[('s-presente', _a1)]!.decision =
          DecisionManuelle.revoque;
      final GoRouter routeur = await _monter(tester, serveur);
      await _aller(tester, routeur, 's-presente');
      expect(serveur.classeActive, isTrue);
      expect(find.text(l.nonPartagePhrase), findsOneWidget);
      expect(find.text('Sourate Al-Baqara, versets 20 a 30'), findsNothing);
      // Le compte rendu voisin, non revoque, reste lisible.
      await _aller(tester, routeur, 's-retard');
      expect(find.text('Sourate Al-Baqara, versets 20 a 30'), findsOneWidget);
    });

    testWidgets('A06 : apres revocation, ni lien direct ni cache : la '
        'relecture donne le masque', (WidgetTester tester) async {
      final FauxPartagePedagogique serveur = _serveur();
      serveur.rapports[('s-presente', _a1)]!.decision = DecisionManuelle.publie;
      serveur.classeActive = false;
      final GoRouter routeur = await _monter(tester, serveur);
      await _aller(tester, routeur, 's-presente');
      expect(find.text('Sourate Al-Baqara, versets 20 a 30'), findsOneWidget);

      serveur.rapports[('s-presente', _a1)]!.decision =
          DecisionManuelle.revoque;
      // Retour arriere puis lien direct : une nouvelle lecture, jamais la
      // precedente.
      await tester.tap(find.byType(DisqueRetour));
      await stabiliser(tester);
      expect(find.text('Sourate Al-Baqara, versets 20 a 30'), findsNothing);
      await _aller(tester, routeur, 's-presente');
      expect(find.text('Sourate Al-Baqara, versets 20 a 30'), findsNothing);
      expect(find.text(l.nonPartagePhrase), findsOneWidget);
      expect(
        serveur.appels.where((String a) => a == 'compteRenduFamille'),
        hasLength(2),
        reason: 'chaque ouverture relit le serveur',
      );
    });

    testWidgets('A06 : hors ligne, un compte rendu deja affiche disparait '
        'au lieu d etre garde comme autorise', (WidgetTester tester) async {
      final FauxPartagePedagogique serveur = _serveur();
      final GoRouter routeur = await _monter(tester, serveur);
      await _aller(tester, routeur, 's-presente');
      expect(find.text('Sourate Al-Baqara, versets 20 a 30'), findsOneWidget);

      // La connexion se perd : plus aucune valeur gardee n'est montree.
      final ProviderContainer conteneur = conteneurDe(tester);
      (conteneur.read(
        serviceReseauProvider,
      ) as FauxServiceReseau).horsLigneRendu = true;
      conteneur.invalidate(horsLigneProvider);
      await stabiliser(tester);
      expect(find.text('Sourate Al-Baqara, versets 20 a 30'), findsNothing);
      expect(find.text(l.horsLignePhrase), findsOneWidget);
      expect(find.text(t.historique.seance.blocSeance), findsOneWidget);
    });
  });

  group('A08 : cahier non confirme', () {
    testWidgets('pas de compte rendu presente comme valide', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique serveur = _serveur();
      serveur.rapports[('s-presente', _a1)]!.confirme = false;
      final GoRouter routeur = await _monter(tester, serveur);
      await _aller(tester, routeur, 's-presente');
      expect(find.text(l.enAttentePhrase), findsOneWidget);
      expect(find.text('Sourate Al-Baqara, versets 20 a 30'), findsNothing);
      expect(find.text(t.historique.seance.blocSeance), findsOneWidget);
    });

    testWidgets('aucune ligne de rapport du tout : meme attente', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(tester, FauxPartagePedagogique());
      await _aller(tester, routeur, 's-presente');
      expect(find.text(l.enAttentePhrase), findsOneWidget);
    });
  });

  group('A09 : cours annule ou non tenu', () {
    testWidgets('aucun bloc, aucun faux constat d absence', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique serveur = _serveur();
      final GoRouter routeur = await _monter(tester, serveur);
      await _aller(tester, routeur, 's-annulee');
      expect(find.text(t.historique.seance.annulePhrase), findsOneWidget);
      expect(_titre(), findsNothing);
      expect(find.text(l.nonDisponibleTitre), findsNothing);
      await _aller(tester, routeur, 's-non-tenue');
      expect(find.text(t.historique.seance.nonTenuPhrase), findsOneWidget);
      expect(_titre(), findsNothing);
      // Le serveur n'a meme pas ete interroge : aucun jugement possible.
      expect(serveur.appels, isEmpty);
      // Jamais une absence de l'enfant.
      expect(find.textContaining('bsent'), findsNothing);
      expect(find.textContaining('bsence'), findsNothing);
    });
  });

  group('A10 : rapport partiel', () {
    testWidgets('seulement les champs presents, aucune rubrique vide', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique serveur = FauxPartagePedagogique()
        ..rapports[('s-presente', _a1)] = RapportSim(
          contenu: const CompteRenduFamille(
            etat: EtatCompteRendu.partage,
            travaille: 'Lecture de la sourate Al-Mulk',
            aPreparer: <String>['Reviser le premier verset'],
          ),
        );
      final GoRouter routeur = await _monter(tester, serveur);
      await _aller(tester, routeur, 's-presente');
      expect(find.text(l.travaille), findsOneWidget);
      expect(find.text(l.aPreparer), findsOneWidget);
      expect(find.text(l.appreciation), findsNothing);
      expect(find.text(l.aRenforcer), findsNothing);
      expect(find.text(l.commentaire), findsNothing);
      expect(find.text(l.corrigeLe(date: '')), findsNothing);
    });

    testWidgets('confirme mais aucun champ partageable : la phrase dediee, '
        'jamais une carte vide ni un pourcentage', (WidgetTester tester) async {
      final FauxPartagePedagogique serveur = FauxPartagePedagogique()
        ..rapports[('s-presente', _a1)] = RapportSim(
          contenu: const CompteRenduFamille(etat: EtatCompteRendu.partage),
        );
      final GoRouter routeur = await _monter(tester, serveur);
      await _aller(tester, routeur, 's-presente');
      expect(find.text(l.aucunChampPhrase), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
    });
  });

  group('A11 : notes internes, autres eleves, paie', () {
    testWidgets('rien de tout cela n atteint l ecran', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique serveur = _serveur();
      final RapportSim rapport = serveur.rapports[('s-presente', _a1)]!;
      // Le serveur garde bien du contenu interne ...
      expect(rapport.interne, isNotEmpty);
      final GoRouter routeur = await _monter(tester, serveur);
      await _aller(tester, routeur, 's-presente');
      // ... qui ne sort jamais de la projection.
      final String tout = <String>[
        for (final Text w in tester.widgetList<Text>(find.byType(Text)))
          w.data ?? w.textSpan?.toPlainText() ?? '',
      ].join('\n');
      for (final String secret in rapport.interne) {
        expect(tout, isNot(contains(secret)));
      }
      expect(tout, isNot(contains('INTERNE')));
      expect(tout, isNot(contains('PAIE')));
      expect(tout, isNot(contains('Ibrahim')));
      expect(tout.toLowerCase(), isNot(contains('rémunération')));
    });
  });

  group('A12 : cahier corrige apres partage', () {
    testWidgets('la version autorisee et le marqueur « Corrige le » '
        'sont affiches', (WidgetTester tester) async {
      final FauxPartagePedagogique serveur = _serveur();
      serveur.rapports[('s-presente', _a1)]!.contenu = CompteRenduFamille(
        etat: EtatCompteRendu.partage,
        travaille: 'Version autorisee corrigee',
        corrigeLe: DateTime(2026, 10, 9),
      );
      final GoRouter routeur = await _monter(tester, serveur);
      await _aller(tester, routeur, 's-presente');
      expect(find.text('Version autorisee corrigee'), findsOneWidget);
      expect(
        find.text(l.corrigeLe(date: dateCourteAttendue(DateTime(2026, 10, 9)))),
        findsOneWidget,
      );
    });
  });

  group('A13 : changement d eleve, de foyer, deconnexion', () {
    testWidgets('jamais un flash du compte rendu de l autre eleve', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique serveur = _serveur();
      // La lecture de l'eleve 2 est lente : pendant ce temps, rien de l'eleve 1.
      final Completer<void> porte = Completer<void>();
      final GoRouter routeur = await _monter(tester, serveur);
      await _aller(tester, routeur, 's-presente');
      expect(find.text('Sourate Al-Baqara, versets 20 a 30'), findsOneWidget);

      serveur.portes['compteRenduFamille'] = porte;
      routeur.go('${Routes.seancePour('s-a2')}?eleve=$_a2');
      await tester.pump();
      // La transition de page se termine ; la lecture, elle, attend sa porte.
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.text('Sourate Al-Baqara, versets 20 a 30'),
        findsNothing,
        reason: 'l ancienne projection a ete videe',
      );
      expect(find.textContaining('TRAVAIL PROPRE A A2'), findsNothing);
      porte.complete();
      await stabiliser(tester);
      expect(find.textContaining('TRAVAIL PROPRE A A2'), findsOneWidget);
      expect(find.text('Sourate Al-Baqara, versets 20 a 30'), findsNothing);
    });

    testWidgets('la deconnexion vide la projection (provider lie a la '
        'session)', (WidgetTester tester) async {
      final FauxPartagePedagogique serveur = _serveur();
      final GoRouter routeur = await _monter(tester, serveur);
      await _aller(tester, routeur, 's-presente');
      final ProviderContainer c = conteneurDe(tester);
      const CleCompteRendu cle = (seanceId: 's-presente', eleveId: _a1);
      expect(c.read(compteRenduFamilleProvider(cle)).hasValue, isTrue);
      // Quitter l'ecran libere la projection : aucune copie ne survit.
      routeur.go(Routes.tuteurSuivi);
      await stabiliser(tester);
      expect(
        c.exists(compteRenduFamilleProvider(cle)),
        isFalse,
        reason: 'autoDispose : rien a servir apres la sortie',
      );
    });
  });

  group('A14 : l eleve a quitte la classe', () {
    testWidgets('une ancienne seance reste celle de sa vraie classe, la '
        'lecture est reevaluee par le serveur', (WidgetTester tester) async {
      final FauxPartagePedagogique serveur = _serveur();
      final GoRouter routeur = await _monter(tester, serveur);
      await _aller(tester, routeur, 's-presente');
      expect(find.text('Sourate Al-Baqara, versets 20 a 30'), findsOneWidget);
      // L'eleve est retire et sa regle devient « jamais » : la meme ancienne
      // seance est relue a la nouvelle regle, pas depuis une copie.
      serveur.retires.add(_a1);
      serveur.regles[_a1] = ReglePartageEleve.jamais;
      routeur.go(Routes.tuteurSuivi);
      await stabiliser(tester);
      await _aller(tester, routeur, 's-presente');
      expect(find.text(l.nonPartagePhrase), findsOneWidget);
      expect(find.text(classeA.libelle), findsWidgets);
    });
  });

  group('A17 : aucun contrat ne fournit le compte rendu', () {
    testWidgets('en production : « indisponible », jamais un mock, sans '
        'Reessayer', (WidgetTester tester) async {
      // Aucune surcharge : le port est celui de production.
      final GoRouter routeur = await _monter(tester, null);
      await _aller(tester, routeur, 's-presente');
      expect(find.text(l.illisiblePhrase), findsOneWidget);
      expect(find.text('Sourate Al-Baqara, versets 20 a 30'), findsNothing);
      expect(find.text(t.commun.reessayer), findsNothing);
      final EtatSysteme etat = tester.widget(find.byType(EtatSysteme));
      expect(etat.nature, NatureEtat.indisponible);
      // La dependance n'est jamais affichee.
      expect(find.textContaining('PED-APRES-BACK'), findsNothing);
      expect(find.text(t.historique.seance.blocSeance), findsOneWidget);
    });

    testWidgets('un echec reseau, lui, se reessaie', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique serveur = _serveur()
        ..erreurs['compteRenduFamille'] = StateError('reseau');
      final GoRouter routeur = await _monter(tester, serveur);
      await _aller(tester, routeur, 's-presente');
      expect(find.text(l.illisiblePhrase), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsOneWidget);
      serveur.erreurs.clear();
      await tester.tap(find.text(t.commun.reessayer));
      await stabiliser(tester);
      expect(find.text('Sourate Al-Baqara, versets 20 a 30'), findsOneWidget);
    });

    testWidgets('le port de production lui-meme leve CapaciteIndisponible', (
      WidgetTester tester,
    ) async {
      final PortPartagePedagogique p = portPartagePedagogiqueSelon(demo: false);
      expect(p, isA<PartagePedagogiqueIndisponible>());
      expect(
        p.compteRenduFamille(seanceId: 's', eleveId: 'e'),
        throwsA(isA<CapaciteIndisponible>()),
      );
    });
  });

  group('A19 : acces hors permission', () {
    testWidgets('le serveur refuse : message neutre, aucune extension de '
        'permission, pas de Reessayer', (WidgetTester tester) async {
      final FauxPartagePedagogique serveur = _serveur()
        ..erreurs['compteRenduFamille'] = const PermissionInsuffisante(
          'compte_rendu',
        );
      final GoRouter routeur = await _monter(tester, serveur);
      await _aller(tester, routeur, 's-presente');
      expect(find.text(l.illisiblePhrase), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsNothing);
      expect(find.text('Sourate Al-Baqara, versets 20 a 30'), findsNothing);
    });

    for (final AppRole role in <AppRole>[AppRole.controller, AppRole.teacher]) {
      testWidgets('un ${role.name} qui colle le lien d un detail de seance '
          'du tuteur est renvoye chez lui', (WidgetTester tester) async {
        final FauxPartagePedagogique serveur = _serveur();
        final GoRouter routeur = await monterRouteur(
          tester,
          '${Routes.seancePour('s-presente')}?eleve=$_a1',
          source: FausseSourceSession(sessionActive(role)),
          surcharges: <Override>[
            portPartagePedagogiqueProvider.overrideWithValue(serveur),
          ],
        );
        expect(find.byType(DetailSeancePage), findsNothing);
        expect(lieu(routeur), isNot(startsWith(Routes.tuteurSeances)));
        expect(serveur.appels, isEmpty);
      });
    }
  });

  group('A22 : suite de seances pendant le partage desactive', () {
    testWidgets('pas de rattrapage retroactif : seules les anciennes '
        'publications automatiques redeviennent lisibles', (
      WidgetTester tester,
    ) async {
      final FauxPartagePedagogique serveur = _serveur();
      // s-presente a ete partagee tant que la regle etait active ;
      // s-retard a ete validee pendant la desactivation : non partagee.
      serveur.rapports[('s-retard', _a1)]!.autoPartage = false;
      serveur.classeActive = false;
      final GoRouter routeur = await _monter(tester, serveur);
      await _aller(tester, routeur, 's-presente');
      expect(find.text(l.nonPartagePhrase), findsOneWidget);
      await _aller(tester, routeur, 's-retard');
      expect(find.text(l.nonPartagePhrase), findsOneWidget);

      // Reactivation.
      serveur.classeActive = true;
      await _aller(tester, routeur, 's-presente');
      expect(find.text('Sourate Al-Baqara, versets 20 a 30'), findsOneWidget);
      await _aller(tester, routeur, 's-retard');
      expect(find.text('Sourate Al-Baqara, versets 20 a 30'), findsNothing);
      expect(find.text(l.nonPartagePhrase), findsOneWidget);
    });
  });
}

/// La date courte attendue, par la meme fonction que l'ecran.
String dateCourteAttendue(DateTime d) => t.historique.dateCourte(
  jour: d.day,
  mois: t.historique.moisCourts[d.month - 1],
  annee: d.year,
);
