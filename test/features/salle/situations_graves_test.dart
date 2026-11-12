// SITUATIONS-GRAVES (directeur, 11/11/2026) : les defauts les plus graves du
// releve des situations de la salle (`docs/current/salle/SITUATIONS-DE-LA-SALLE.md`).
// Chaque groupe echoue sans la correction du lot.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/pause_seance/port_pause_seance.dart';
import 'package:rewayah_academy/core/router/billet_salle.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/salle_seance/actions_seance.dart';
import 'package:rewayah_academy/features/salle_seance/annonce_geste.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';
import '../../support/demo/seance_demo.dart';

const lk.MediaDevice _micro = lk.MediaDevice('m1', '', 'audioinput', null);

void main() {
  group('defaut n° 3 : micro refuse, pris ou absent', () {
    test('la permission refusee se lit AVANT l entree', () async {
      final ResultatPreVol r = await ServicePreVolLiveKit(
        enumerer: () async => <lk.MediaDevice>[_micro],
        lirePermission: () async => 'denied',
      ).verifier();
      expect(r.microDisponible, isTrue);
      expect(r.permissionRefusee, isTrue);
      expect(r.peutEntrer, isFalse);
    });

    test('permission accordee, a demander ou inconnue : on entre', () async {
      for (final String? etat in <String?>['granted', 'prompt', null]) {
        final ResultatPreVol r = await ServicePreVolLiveKit(
          enumerer: () async => <lk.MediaDevice>[_micro],
          lirePermission: () async => etat,
        ).verifier();
        expect(r.peutEntrer, isTrue, reason: '$etat');
      }
    });

    test('la cause est lue dans la phrase du navigateur', () {
      expect(
        causeEchecMicro('NotAllowedError: Permission denied'),
        CauseMicroBloque.refuse,
      );
      expect(
        causeEchecMicro('NotReadableError: Could not start audio source'),
        CauseMicroBloque.occupe,
      );
      expect(
        causeEchecMicro('NotFoundError: Requested device not found'),
        CauseMicroBloque.absent,
      );
      expect(causeEchecMicro('quelque chose'), CauseMicroBloque.autre);
    });

    test('l annonce de tete dit la cause et quoi faire', () {
      final AnnonceGeste a = annonceMicroBloque(CauseMicroBloque.occupe);
      expect(a.titre, "Le micro ne s'ouvre pas");
      expect(a.message, contains('autre application'));
      expect(a.message, contains('réessayez'));
    });

    testWidgets('la feuille micro bloque dit la vraie cause et propose de '
        'reessayer', (WidgetTester tester) async {
      int micro = 0;
      fixerVueCapture(tester, const Size(390, 844), 1);
      await tester.pumpWidget(
        hoteCapture(
          SalleSeance(
            vue: DonneesSeanceDemo.vue(
              RoleSeance.eleve,
              EtatDemoSalle.microBloque,
            ).copyWith(causeMicro: CauseMicroBloque.refuse),
            actions: ActionsSeance(
              onRetour: () {},
              onQuitter: () {},
              onMicro: () => micro++,
              onCamera: () {},
              onContinuerSansMicro: () {},
            ),
          ),
        ),
      );
      await stabiliser(tester);
      await tester.tap(find.byKey(const ValueKey<String>('bouton-micro')));
      await stabiliser(tester);
      expect(find.textContaining('refuse l\'accès au micro'), findsOneWidget);
      final Finder reessayer = find.byKey(
        const ValueKey<String>('micro-bloque-reessayer'),
      );
      expect(reessayer, findsOneWidget);
      await tester.tap(reessayer);
      await stabiliser(tester);
      expect(micro, 1);
    });
  });

  group('defaut n° 4 : rechargement de la page', () {
    final DateTime t = DateTime.utc(2026, 11, 11, 18);
    tearDown(RepriseSalle.oublier);

    test('la salle se retrouve apres un rechargement, sans aucun droit '
        'garde', () {
      RepriseSalle.retenir(
        BilletSalle(
          sessionId: 's1',
          emisA: t,
          groupeId: 'g1',
          eleveId: 'e1',
          interfaceGuidee: true,
          preparation: true,
        ),
        maintenant: t,
      );
      final BilletSalle? b = billetDe(
        null,
        chemin: Routes.salle,
        maintenant: t.add(const Duration(minutes: 47)),
      );
      expect(b, isNotNull);
      expect(b!.sessionId, 's1');
      expect(b.groupeId, 'g1');
      expect(b.eleveId, 'e1');
      expect(b.interfaceGuidee, isTrue);
      // Le retour ouvre la salle, jamais la preparation.
      expect(b.preparation, isFalse);
      expect(b.valideA(t.add(const Duration(minutes: 47))), isTrue);
    });

    test('la redirection garde la salle au lieu de renvoyer a l accueil', () {
      RepriseSalle.retenir(
        BilletSalle(sessionId: 's1', emisA: t),
        maintenant: t,
      );
      final DateTime plusTard = t.add(const Duration(minutes: 30));
      expect(
        deciderRedirection(
          session: const SessionState(
            resolue: true,
            profileId: 'p1',
            householdId: 'h1',
            role: AppRole.student,
            accountStatus: AccountStatus.active,
            lectureProfil: LectureProfil.presente,
          ),
          cheminDemande: Routes.salle,
          billet: billetDe(null, chemin: Routes.salle, maintenant: plusTard),
          maintenant: plusTard,
        ),
        isNull,
      );
    });

    test('hors de la salle, ou trop tard, ou apres une sortie : rien', () {
      RepriseSalle.retenir(
        BilletSalle(sessionId: 's1', emisA: t),
        maintenant: t,
      );
      expect(billetDe(null, chemin: Routes.racine, maintenant: t), isNull);
      expect(
        billetDe(
          null,
          chemin: Routes.salle,
          maintenant: t.add(const Duration(hours: 5)),
        ),
        isNull,
      );
      RepriseSalle.retenir(
        BilletSalle(sessionId: 's1', emisA: t),
        maintenant: t,
      );
      RepriseSalle.oublier();
      expect(billetDe(null, chemin: Routes.salle, maintenant: t), isNull);
    });
  });

  group('defauts n° 7 et 8 : chaque refus dit sa vraie raison', () {
    test('les nouveaux motifs du serveur sont lus', () {
      const Map<String, MotifServeurSalle> attendus =
          <String, MotifServeurSalle>{
            'non_inscrit': MotifServeurSalle.nonInscrit,
            'acces_suspendu': MotifServeurSalle.accesSuspendu,
            'sorti': MotifServeurSalle.sorti,
            'observation_terminee': MotifServeurSalle.observationTerminee,
            'compte_invalide': MotifServeurSalle.compteInvalide,
          };
      for (final MapEntry<String, MotifServeurSalle> e in attendus.entries) {
        expect(
          DetailRefusSalle.depuis(<String, Object?>{'motif': e.key})?.motif,
          e.value,
        );
      }
    });
  });

  group('defaut n° 2 : enseignant absent ou parti', () {
    test('pas encore arrive, puis la, puis parti : une annonce par '
        'changement', () {
      final VeilleEnseignant veille = VeilleEnseignant();
      final AnnonceGeste? attendu = veille.observer(enseignantPresent: false);
      expect(attendu?.titre, "Votre professeur n'est pas encore arrivé");
      // Pas en boucle.
      expect(veille.observer(enseignantPresent: false), isNull);
      expect(veille.observer(enseignantPresent: true), isNull);
      final AnnonceGeste? parti = veille.observer(enseignantPresent: false);
      expect(parti?.titre, "Votre enseignant n'est plus dans la salle");
      expect(veille.observer(enseignantPresent: false), isNull);
    });

    test('seul dans la salle, la scene d attente le dit deja : aucune annonce '
        'tant qu aucun camarade n est la ; parti, l annonce vient meme seul', () {
      final VeilleEnseignant veille = VeilleEnseignant();
      expect(veille.observer(enseignantPresent: false, seul: true), isNull);
      expect(veille.observer(enseignantPresent: false, seul: true), isNull);
      // Un camarade entre : l'annonce vient alors, une fois.
      expect(
        veille.observer(enseignantPresent: false)?.titre,
        "Votre professeur n'est pas encore arrivé",
      );
      expect(veille.observer(enseignantPresent: false), isNull);
      // L'enseignant est venu, puis parti : seul ou non, l'eleve le sait.
      expect(veille.observer(enseignantPresent: true), isNull);
      expect(
        veille.observer(enseignantPresent: false, seul: true)?.titre,
        "Votre enseignant n'est plus dans la salle",
      );
    });
  });

  group('defaut n° 6 : la pause vue par toute la classe', () {
    test('le relais de pause se relit a l identique, sans commande', () {
      final PauseSeance pause = PauseSeance(
        statut: StatutPause.enCours,
        dureePrevueMinutes: 10,
        debutUtc: DateTime.utc(2026, 11, 11, 18, 30),
        peutPiloter: true,
      );
      final PauseSeance? relue = pauseDepuisCharge(
        utf8.encode(jsonEncode(chargePause(pause))),
      );
      expect(relue?.statut, StatutPause.enCours);
      expect(relue?.repriseUtc, DateTime.utc(2026, 11, 11, 18, 40));
      expect(relue?.peutPiloter, isFalse);
      expect(pauseDepuisCharge(utf8.encode('{"statut":"x"}')), isNull);
      expect(annoncePause().message, 'La séance reprend dans un instant.');
    });
  });
}
