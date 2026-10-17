// TB-12, lot T2-synchro (plan V2 §15 R-07, R-10, R-11, R-12 ; §23 UX-17,
// UX-24) : la synchronisation prouvee sur un VRAI flux de demonstration.
//
// Ce qui tourne ici est le code de production du flux :
// `ServiceEtatPartage` (etat partage par revision, restauration au
// retablissement), `ServiceRealtimePedagogique` (canaux fiable et ephemere,
// doublons ecartes), `DiffusionOutils` et `CoucheAnnotation` (le trait pose
// au doigt). Seul le transport est un double : `TransportMemoire` sur un
// `BusMemoire`, qui sait perdre, dupliquer et reordonner un paquet.
//
// LIMITES ecrites (aucune n'est masquee par un faux succes) :
// - la salle de demonstration (`DemoSallePage`) ne se branche pas sur ce
//   flux : ses pages, affichages, « Presenter » et « Effacer les notes »
//   restent locaux (demo_salle_page.dart, `_changerPage`, `_presenter`,
//   `_effacerNotes` : « rien n'est diffuse »). Les preuves sur l'ancienne
//   Classe Live (`/tc/classe`) sont parties avec elle le 17/10/2026
//   (`docs/current/DECISION-ENTREE-2026-10-17.md`) ;
// - aucun recepteur d'encre n'existe dans lib/ : les evenements
//   `tc.outils.*` sont emis (CoucheAnnotation -> DiffusionOutils) mais aucun
//   code ne les applique chez l'eleve. R-07 et R-10 se prouvent donc au
//   niveau du protocole (ce que l'eleve RECOIT), pas a l'ecran de l'eleve ;
// - l'ordre du canal fiable et l'absence de perte y sont des garanties de
//   LiveKit (canal fiable ordonne) : non verifiable sans BR-1.

import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_etat_partage/etat_partage_memoire.dart';
import 'package:rewayah_academy/core/tc_etat_partage/service_etat_partage.dart';
import 'package:rewayah_academy/core/tc_etat_partage/shared_content_state.dart';
import 'package:rewayah_academy/core/tc_outils/annotation_layer.dart';
import 'package:rewayah_academy/core/tc_outils/etat_outils.dart';
import 'package:rewayah_academy/core/tc_outils/evenements_outils.dart';
import 'package:rewayah_academy/core/tc_outils/port_annotations.dart';
import 'package:rewayah_academy/core/tc_outils/port_dock_hote.dart';
import 'package:rewayah_academy/core/tc_realtime/codec_message_pedagogique.dart';
import 'package:rewayah_academy/core/tc_realtime/port_realtime_pedagogique.dart';
import 'package:rewayah_academy/core/tc_realtime/port_transport_donnees.dart';
import 'package:rewayah_academy/core/tc_realtime/service_realtime_pedagogique.dart';
import 'package:rewayah_academy/core/tc_realtime/transport_memoire.dart';
import 'package:rewayah_academy/core/widgets/barre_precedent_suivant.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart'
    show RoleSeance;
import 'package:rewayah_academy/features/tc_dock/barre_stylet.dart';
import 'package:rewayah_academy/features/tc_dock/couche_annotation.dart';

import '../../router/support_routeur.dart';
import '../../teaching_core/d/support/hote_d.dart'
    show hoteSansScope, supportTest;

const String _seance = 'seance-t2';
const String _prof = 'prof-1';
const String _eleve = 'eleve-1';

const CapacitesTransport _capProf = CapacitesTransport(
  identiteLocale: _prof,
  peutPublier: true,
  peutPublierDonnees: true,
  invisible: false,
);

const CapacitesTransport _capEleve = CapacitesTransport(
  identiteLocale: _eleve,
  peutPublier: true,
  peutPublierDonnees: false,
  invisible: false,
);

/// Un etat partage : ressource, page, affichage, a une revision.
SharedContentState _etat({
  required int revision,
  required int page,
  ModeAffichagePartage mode = ModeAffichagePartage.page,
  String ressource = 'res-1',
  String auteur = _prof,
}) => SharedContentState(
  sessionId: _seance,
  resourceId: ressource,
  contentPosition: ContentPosition.page(resourceId: ressource, page: page),
  displayMode: mode,
  hiddenRanges: const [],
  semanticMarkers: const [],
  revision: revision,
  updatedBy: auteur,
  updatedAtUtc: DateTime.utc(2026, 10, 10, 9, revision),
);

/// Le flux de demonstration complet : un bus, deux appareils, un backend.
class _Flux {
  _Flux() {
    prof = TransportMemoire(bus: bus, capacites: _capProf);
    eleve = TransportMemoire(bus: bus, capacites: _capEleve);
    realtimeProf = ServiceRealtimePedagogique(prof);
    realtimeEleve = ServiceRealtimePedagogique(eleve);
    chezLeProf = ServiceEtatPartage(
      realtime: realtimeProf,
      persistance: backend,
      etatsTransport: prof.etats(),
    );
    chezLEleve = ServiceEtatPartage(
      realtime: realtimeEleve,
      persistance: backend,
      etatsTransport: eleve.etats(),
    );
  }

  final BusMemoire bus = BusMemoire();
  final EtatPartageMemoire backend = EtatPartageMemoire();
  late final TransportMemoire prof;
  late final TransportMemoire eleve;
  late final ServiceRealtimePedagogique realtimeProf;
  late final ServiceRealtimePedagogique realtimeEleve;
  late final ServiceEtatPartage chezLeProf;
  late final ServiceEtatPartage chezLEleve;

  /// Coupe (ou retablit) le lien de l'eleve : plus rien ne lui parvient.
  bool eleveCoupe = false;

  /// Coupe le lien de l'enseignant : rien de ce qu'il emet ne sort.
  bool profCoupe = false;

  void brancherCoupures() {
    bus.jeter = (PaquetRealtime p) =>
        (profCoupe && p.emetteurIdentite == _prof) || eleveCoupe;
  }

  Future<void> liberer() async {
    await chezLeProf.liberer();
    await chezLEleve.liberer();
    await prof.liberer();
    await eleve.liberer();
  }
}

void main() {
  // ---------------------------------------------------------------- R-11 --
  group('R-11 : arrivee tardive et reconnexion, flux reel', () {
    test('service : la page ET l\'affichage publies avant l\'arrivee sont '
        'recus sans aucun message realtime ; la coupure est rattrapee au '
        'retablissement', () async {
      final _Flux flux = _Flux()..brancherCoupures();
      addTearDown(flux.liberer);
      await flux.chezLeProf.publier(_etat(revision: 0, page: 3));
      await flux.chezLeProf.publier(
        _etat(revision: 1, page: 12, mode: ModeAffichagePartage.focus),
      );
      // L'eleve arrive : le reseau realtime ne lui livre plus rien. Ce qu'il
      // obtient ne peut venir que de l'etat courant (backend).
      flux.eleveCoupe = true;
      final List<SharedContentState> recus = <SharedContentState>[];
      final StreamSubscription<SharedContentState> a = flux.chezLEleve
          .suivre(_seance)
          .listen(recus.add);
      addTearDown(a.cancel);
      await pumpEventQueue();
      expect(recus, hasLength(1));
      expect(recus.single.contentPosition.page, 12);
      expect(recus.single.displayMode, ModeAffichagePartage.focus);
      expect(recus.single.updatedBy, _prof);
      // Toujours coupe : deux revisions manquees.
      flux.eleve.poserEtat(EtatTransport.interrompu);
      await flux.chezLeProf.publier(_etat(revision: 2, page: 13));
      await flux.chezLeProf.publier(
        _etat(revision: 3, page: 14, mode: ModeAffichagePartage.verse),
      );
      await pumpEventQueue();
      expect(recus.last.revision, 1, reason: 'coupe : rien de nouveau');
      // Contre-epreuve : `interrompu` ne restaure rien.
      expect(recus, hasLength(1));
      flux.eleveCoupe = false;
      flux.eleve.poserEtat(EtatTransport.retabli);
      await pumpEventQueue();
      expect(recus.last.revision, 3);
      expect(recus.last.contentPosition.page, 14);
      expect(recus.last.displayMode, ModeAffichagePartage.verse);
      // Jamais de recul : les revisions vues croissent strictement.
      for (int i = 1; i < recus.length; i++) {
        expect(recus[i].revision, greaterThan(recus[i - 1].revision));
      }
    });
  });

  // ---------------------------------------------------------- R-07, R-10 --
  group('R-07 / R-10 : l\'encre sous pertes, doublons et desordre', () {
    late AnnotationsMemoire depot;
    late _Flux flux;
    late List<MessagePedagogique> fiables;
    late List<MessagePedagogique> ephemeres;

    /// Temoin brut (contre-epreuve) : ce que le transport de l'eleve livre
    /// AVANT le protocole, doublons compris. Si le protocole n'ecartait rien,
    /// les listes ci-dessus auraient la meme longueur que celle-ci.
    late List<PaquetRealtime> brutsFiables;

    setUp(() {
      depot = AnnotationsMemoire(_prof);
      flux = _Flux();
      fiables = <MessagePedagogique>[];
      ephemeres = <MessagePedagogique>[];
      brutsFiables = <PaquetRealtime>[];
    });

    tearDown(() async {
      await depot.liberer();
      await flux.liberer();
    });

    /// Monte la vraie couche d'annotation de l'enseignant, stylet arme, dont
    /// les evenements partent par `DiffusionOutils` sur le transport memoire.
    Future<void> monterCouche(WidgetTester tester) async {
      final DiffusionOutils diffusion = DiffusionOutils(
        flux.realtimeProf,
        sessionId: _seance,
        emetteurProfilId: _prof,
        maintenant: () => DateTime.utc(2026, 10, 10, 9),
      );
      final ProviderContainer conteneur = ProviderContainer(
        overrides: <Override>[portAnnotationsProvider.overrideWithValue(depot)],
      );
      addTearDown(conteneur.dispose);
      conteneur
          .read(etatOutilsProvider.notifier)
          .choisirOutil(OutilDock.stylet);
      final StreamSubscription<MessagePedagogique> f = flux.realtimeEleve
          .messagesFiables(_seance)
          .listen(fiables.add);
      final StreamSubscription<MessagePedagogique> e = flux.realtimeEleve
          .messagesEphemeres(_seance)
          .listen(ephemeres.add);
      final StreamSubscription<PaquetRealtime> b = flux.eleve.paquets().listen((
        PaquetRealtime p,
      ) {
        if (p.canal == CanalFiabilite.fiable) brutsFiables.add(p);
      });
      addTearDown(f.cancel);
      addTearDown(e.cancel);
      addTearDown(b.cancel);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: conteneur,
          child: hoteSansScope(
            SizedBox(
              width: 200,
              height: 400,
              child: CoucheAnnotation(
                support: supportTest(mode: ModeAffichagePartage.page),
                traits: const <TraitVectoriel>[],
                contexte: const ContexteDock(
                  groupeId: 'g1',
                  sessionId: _seance,
                  profilId: _prof,
                ),
                onEvenement: (EvenementOutil ev) =>
                    unawaited(diffusion.emettre(ev)),
              ),
            ),
          ),
        ),
      );
    }

    /// Trace un trait de 12 points au stylet ; chaque deplacement envoie un
    /// paquet ephemere.
    Future<void> tracer(WidgetTester tester) async {
      final TestPointer stylet = TestPointer(1, PointerDeviceKind.stylus);
      const Offset depart = Offset(20, 10);
      await tester.sendEventToBinding(stylet.down(depart));
      for (int i = 1; i <= 12; i++) {
        await tester.sendEventToBinding(
          stylet.move(depart + Offset(i * 8.0, (i.isEven ? 1 : -1) * 6.0)),
        );
        await tester.pump();
      }
      await tester.sendEventToBinding(stylet.up());
      await tester.pumpAndSettle();
    }

    TraitVectoriel traitDuProf() => depot.couches.single.traits.single;

    List<(double, double)> pointsDe(TraitVectoriel t) => <(double, double)>[
      for (final PointNormalise p in t.points) (p.x, p.y),
    ];

    List<PaquetRealtime> emisPar(CanalFiabilite canal) => <PaquetRealtime>[
      for (final PaquetRealtime p in flux.prof.emis)
        if (p.canal == canal) p,
    ];

    testWidgets('R-07 : la moitie des paquets du geste perdue, le reste '
        'duplique et a l\'envers ; le trait final recu est identique a celui '
        'de l\'enseignant, une seule fois', (WidgetTester tester) async {
      int numero = 0;
      // Un paquet ephemere sur deux est perdu ; le fiable passe toujours.
      flux.bus.jeter = (PaquetRealtime p) =>
          p.canal == CanalFiabilite.ephemere && (numero++).isOdd;
      await monterCouche(tester);
      await tracer(tester);
      await tester.runAsync(pumpEventQueue);
      final List<PaquetRealtime> geste = emisPar(CanalFiabilite.ephemere);
      expect(geste.length, greaterThanOrEqualTo(4), reason: 'le geste emet');
      expect(
        ephemeres.length,
        lessThan(geste.length),
        reason: 'des paquets du geste sont bien perdus',
      );
      // Le reseau livre a nouveau le geste, a l'envers, et le fiable deux
      // fois de plus (duplicata).
      for (final PaquetRealtime p in geste.reversed) {
        flux.eleve.recevoir(p);
      }
      final PaquetRealtime termine = emisPar(CanalFiabilite.fiable).single;
      flux.eleve
        ..recevoir(termine)
        ..recevoir(termine);
      await tester.runAsync(pumpEventQueue);
      // Le canal ephemere laisse passer doublons et desordre (par contrat) :
      // il ne fait pas foi.
      expect(ephemeres.length, greaterThan(geste.length ~/ 2));
      // Le fiable fait foi : une seule fois, et c'est le trait entier.
      final List<MessagePedagogique> traits = fiables
          .where((MessagePedagogique m) => m.type == 'tc.outils.trait_termine')
          .toList();
      expect(traits, hasLength(1), reason: 'doublons du fiable ecartes');
      // Contre-epreuve : le transport, lui, l'a bien livre trois fois.
      expect(brutsFiables, hasLength(3));
      final Map<String, dynamic> recu =
          traits.single.charge['trait'] as Map<String, dynamic>;
      final TraitVectoriel chezLeProf = traitDuProf();
      expect(recu['id'], chezLeProf.id);
      expect(
        <(double, double)>[
          for (final Map<String, dynamic> p
              in (recu['points'] as List<Object?>).cast<Map<String, dynamic>>())
            ((p['x']! as num).toDouble(), (p['y']! as num).toDouble()),
        ],
        pointsDe(chezLeProf),
        reason: 'trait final identique, malgre les pertes du geste',
      );
      expect(recu['outil'], chezLeProf.outil.valeurSql);
    });

    testWidgets('R-10 : apres le retrait du trait, son paquet fiable retarde '
        'ne le rend pas une seconde fois (doublon ecarte)', (
      WidgetTester tester,
    ) async {
      await monterCouche(tester);
      await tracer(tester);
      await tester.runAsync(pumpEventQueue);
      final TraitVectoriel trait = traitDuProf();
      final PaquetRealtime termine = emisPar(CanalFiabilite.fiable).single;
      // « Effacer les notes » : en demonstration, il ne diffuse rien
      // (`_effacerNotes`) ; au reseau, c'est le retrait fiable du trait,
      // emis par le meme chemin que la gomme.
      await tester.runAsync(
        () =>
            DiffusionOutils(
              flux.realtimeProf,
              sessionId: _seance,
              emetteurProfilId: _prof,
            ).emettre(
              EvenementTraitRetire(
                coucheId: depot.couches.single.id,
                traitId: trait.id,
              ),
            ),
      );
      await tester.runAsync(pumpEventQueue);
      expect(fiables.last.type, 'tc.outils.trait_retire');
      final int avant = fiables.length;
      final int brutsAvant = brutsFiables.length;
      // Le paquet du trait, retarde, arrive apres le retrait.
      flux.eleve.recevoir(termine);
      await tester.runAsync(pumpEventQueue);
      expect(
        brutsFiables,
        hasLength(brutsAvant + 1),
        reason: 'contre-epreuve : le paquet retarde arrive bien',
      );
      expect(
        fiables.length,
        avant,
        reason: 'le trait retire n\'est pas rendu une seconde fois',
      );
      expect(fiables.last.type, 'tc.outils.trait_retire');
    });

    test('R-10 (limite ecrite) : un apercu ephemere retarde passe le '
        'protocole ; seul un recepteur d\'encre (absent, BR-1) peut '
        'l\'ignorer', () async {
      final List<MessagePedagogique> recus = <MessagePedagogique>[];
      final StreamSubscription<MessagePedagogique> a = flux.realtimeEleve
          .messagesEphemeres(_seance)
          .listen(recus.add);
      addTearDown(a.cancel);
      final DiffusionOutils diffusion = DiffusionOutils(
        flux.realtimeProf,
        sessionId: _seance,
        emetteurProfilId: _prof,
        maintenant: () => DateTime.utc(2026, 10, 10, 9),
      );
      await diffusion.emettre(
        const EvenementTraitEnCours(
          traitId: 't-1',
          ancrage: ContentPosition.page(resourceId: 'res-1', page: 1),
          pointsNouveaux: <PointNormalise>[PointNormalise(0.1, 0.1)],
          outil: OutilTrait.stylet,
        ),
      );
      final PaquetRealtime apercu = flux.prof.emis.single;
      await diffusion.emettre(
        const EvenementTraitRetire(coucheId: 'c-1', traitId: 't-1'),
      );
      flux.eleve.recevoir(apercu);
      await pumpEventQueue();
      // Par contrat, l'ephemere ne retient aucune empreinte : le duplicata
      // retarde est livre. Rien a l'ecran ne le rend aujourd'hui (aucun
      // recepteur d'encre dans lib/), mais le futur recepteur devra tenir
      // les traits retires (TB-BR, ci-dessous).
      expect(recus, hasLength(2));
      expect(recus.last.type, 'tc.outils.trait_en_cours');
      expect(recus.last.charge['trait_id'], 't-1');
      expect(
        messageVersJson(recus.last),
        messageVersJson(recus.first),
        reason: 'le meme apercu, livre une seconde fois apres le retrait',
      );
    });
  });

  // ---------------------------------------------------------------- R-12 --
  group('R-12 : coupure de l\'enseignant (ERR-01), aucune capacite '
      'enseignant chez l\'eleve', () {
    // Revue TB-R 10/10, m34 : la coupure joue un role. Sans elle, la
    // publication de l'enseignant pendant la coupure parviendrait a l'eleve.
    // Ce test est une BORNE d'ERR-01 (pas de nouveau maitre cote capacites,
    // l'eleve garde le dernier etat recu), pas sa preuve entiere : « l'etat
    // partage ne change pas d'emetteur » cote serveur reste a BR-1 (TB-BR-44).
    test('service : l\'eleve n\'obtient aucun droit de pilotage, avant comme '
        'apres la coupure (borne d\'ERR-01) ; rien de l\'enseignant coupe ne '
        'lui parvient ; son envoi est refuse et l\'etat garde son '
        'emetteur', () async {
      final _Flux flux = _Flux()..brancherCoupures();
      addTearDown(flux.liberer);
      await flux.chezLeProf.publier(_etat(revision: 0, page: 7));
      final List<SharedContentState> recus = <SharedContentState>[];
      final StreamSubscription<SharedContentState> a = flux.chezLEleve
          .suivre(_seance)
          .listen(recus.add);
      addTearDown(a.cancel);
      await pumpEventQueue();
      expect(recus.map((SharedContentState e) => e.revision), <int>[0]);

      // Avant la coupure : les droits signes de chacun.
      final CapacitesPedagogiques eleveAvant = await flux.realtimeEleve
          .capacites(_seance);
      final CapacitesPedagogiques profAvant = await flux.realtimeProf.capacites(
        _seance,
      );
      expect(eleveAvant.peutPiloterSupport, isFalse);
      expect(profAvant.peutPiloterSupport, isTrue);

      // ERR-01 : l'enseignant est coupe.
      flux.profCoupe = true;
      flux.prof.poserEtat(EtatTransport.interrompu);
      await pumpEventQueue();

      // La coupure est reelle : la page 8 que l'enseignant publie pendant
      // la coupure ne parvient pas a l'eleve, qui garde la page 7.
      await flux.chezLeProf.publier(_etat(revision: 1, page: 8));
      await pumpEventQueue();
      expect(
        recus.map((SharedContentState e) => e.contentPosition.page),
        <int?>[7],
        reason: 'rien de l\'enseignant coupe ne passe',
      );

      // Aucun nouveau maitre : l'eleve a exactement les memes capacites
      // qu'avant la coupure, aucune d'enseignant.
      final CapacitesPedagogiques eleveApres = await flux.realtimeEleve
          .capacites(_seance);
      expect(eleveApres, eleveAvant);
      expect(eleveApres.peutPiloterSupport, isFalse);
      expect(eleveApres.peutAnnoter, isFalse);
      expect(eleveApres.peutEmettreNudge, isFalse);
      // Contre-epreuve : l'enseignant, lui, garde ses droits signes.
      expect(await flux.realtimeProf.capacites(_seance), profAvant);

      // Un paquet de revision forge par l'eleve ne sort pas de son appareil.
      await expectLater(
        flux.realtimeEleve.emettre(
          MessagePedagogique(
            type: 'tc.etat_partage.revision',
            sessionId: _seance,
            emetteurProfilId: _eleve,
            charge: const <String, dynamic>{},
            emisLeUtc: DateTime.utc(2026, 10, 10, 9),
          ),
          canal: CanalFiabilite.fiable,
        ),
        throwsA(
          isA<EchecTransport>().having(
            (EchecTransport e) => e.motif,
            'motif',
            MotifEchecTransport.droitRefuse,
          ),
        ),
      );
      expect(flux.eleve.emis, isEmpty);
      await pumpEventQueue();
      expect(recus, hasLength(1));
      expect(recus.single.updatedBy, _prof);
      // Le seul ecrivain du durable reste l'enseignant.
      expect((await flux.backend.lire(_seance))!.updatedBy, _prof);
    });

    testWidgets('coquille /demo/salle : eleve et guidee en ERR-01, ni page, '
        'ni affichage, ni Bibliotheque, ni ranger ; l\'enseignant en ERR-01 '
        'les garde (contre-epreuve)', (WidgetTester tester) async {
      for (final RoleSeance role in <RoleSeance>[
        RoleSeance.eleve,
        RoleSeance.guidee,
        RoleSeance.enseignant,
      ]) {
        final GoRouter routeur = await monterRouteur(
          tester,
          Routes.demoSalle,
          taille: const Size(1440, 900),
        );
        final Finder lien = find.byKey(
          ValueKey<String>('lien-${role.name}-tb-${SituationTb.err01.name}'),
        );
        await tester.ensureVisible(lien);
        await tester.pump();
        await tester.tap(lien);
        await tester.pumpAndSettle();
        expect(lieu(routeur), adresseDemoSalleTb(role, SituationTb.err01));
        final ActionsSeance actions = tester
            .widget<SalleSeance>(find.byType(SalleSeance))
            .actions;
        final bool prof = role == RoleSeance.enseignant;
        final Map<String, Object?> capacites = <String, Object?>{
          'page precedente': actions.onPagePrecedente,
          'page suivante': actions.onPageSuivante,
          'affichage': actions.onAffichage,
          'bibliotheque': actions.onBibliotheque,
          'presenter': actions.onPresenter,
          'ranger': actions.onRanger,
          'effacer les notes': actions.onEffacerNotes,
          'autoriser a ecrire': actions.onAutoriserEcrire,
        };
        capacites.forEach((String nom, Object? rappel) {
          expect(rappel != null, prof, reason: '${role.name} ERR-01 : $nom');
        });
        // A l'ecran : les Commandes ouvertes ne proposent rien de cela.
        final Finder entree =
            find.byKey(DeclencheurCommandes.cle).evaluate().isNotEmpty
            ? find.byKey(DeclencheurCommandes.cle)
            : find.byKey(BarreStylet.cleCommandes);
        await tester.ensureVisible(entree.first);
        await tester.tap(entree.first);
        await tester.pumpAndSettle();
        expect(find.byKey(CommandesPedagogiques.cle), findsOneWidget);
        for (final Finder f in <Finder>[
          find.byKey(CommandesPedagogiques.cleBibliotheque),
          find.byKey(CommandesPedagogiques.cleAffichages),
          find.byKey(CommandesPedagogiques.cleMenu),
          find.byType(BarrePrecedentSuivant),
        ]) {
          expect(
            f.evaluate().isNotEmpty,
            prof,
            reason: '${role.name} ERR-01 : ${f.describeMatch(Plurality.one)}',
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    });
  });
}
