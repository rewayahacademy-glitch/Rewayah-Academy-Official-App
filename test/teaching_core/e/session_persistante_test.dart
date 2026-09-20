import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_classe/port_session_persistante.dart';
import 'package:rewayah_academy/core/tc_classe/session_persistante.dart';
import 'package:rewayah_academy/core/tc_horloge/session_clock_vm.dart';
import 'package:rewayah_academy/core/video/service_video.dart';

import 'faux/faux_classe.dart';

/// La session persistante (spec section 9.4, decision D-24).
///
/// **Le shell ne possede pas la room.** Ce fichier mesure exactement cela :
/// personne ne quitte la salle sauf [ControleurSessionPersistante.quitter], et
/// [ControleurSessionPersistante.quitter] n'est atteint que par un geste
/// explicite.
void main() {
  const SessionEnCours cours = SessionEnCours(
    sessionId: 's1',
    groupeId: 'g1',
    libelleGroupe: 'Groupe Al-Fatiha',
  );

  _Banc monter({
    MotifRefusSalle? refus,
    bool microDisponible = true,
    Object? erreurEntree,
  }) {
    final List<String> journal = <String>[];
    final FauxMoteurClasse moteur = FauxMoteurClasse(journal: journal)
      ..erreurEntree = erreurEntree;
    final FauxServiceVideoClasse video = FauxServiceVideoClasse(
      acces0: accesDe('teacher'),
      motifARefuser: refus,
      journal: journal,
    );
    final FauxPreVolClasse preVol = FauxPreVolClasse(
      microDisponible: microDisponible,
    );
    final ControleurSessionPersistante controleur =
        ControleurSessionPersistante(
          moteur,
          video,
          // Aucune liaison de widgets dans un test purement Dart :
          // `addObserver` echouerait.
          observeLeCycleDeVie: false,
        );
    addTearDown(controleur.liberer);
    return _Banc(
      controleur: controleur,
      moteur: moteur,
      video: video,
      preVol: preVol,
      journal: journal,
    );
  }

  group('entree', () {
    test('les trois temps, dans l ordre : materiel, jeton, salle', () async {
      final _Banc t = monter();

      await t.controleur.ouvrir(cours: cours, preVol: t.preVol.verifier);

      expect(t.preVol.verifications, 1);
      expect(t.video.demandes, <String>['s1']);
      expect(t.moteur.entrees, hasLength(1));
      expect(t.controleur.etatCourant.cours, cours);
      expect(t.controleur.etatCourant.acces, isNotNull);
    });

    test('un materiel muet n obtient aucun jeton', () async {
      // Verifier le micro pendant qu'on est encore seul devant son ecran evite
      // qu'une salle echoue APRES que tout le groupe y soit entre.
      final _Banc t = monter(microDisponible: false);

      await t.controleur.ouvrir(cours: cours, preVol: t.preVol.verifier);

      expect(t.video.demandes, isEmpty);
      expect(t.moteur.entrees, isEmpty);
      expect(t.controleur.etatCourant.cours, isNull);
      expect(t.controleur.etatCourant.materielPret, isFalse);
    });

    test('un refus du backend n entre dans aucune salle', () async {
      final _Banc t = monter(refus: MotifRefusSalle.acces);

      await t.controleur.ouvrir(cours: cours, preVol: t.preVol.verifier);

      expect(t.moteur.entrees, isEmpty);
      expect(t.controleur.etatCourant.refus, MotifRefusSalle.acces);
      expect(t.controleur.etatCourant.cours, isNull);
    });

    test('un moteur qui echoue nomme le reseau, sans detail technique', () async {
      final _Banc t = monter(erreurEntree: StateError('ICE failed'));

      await t.controleur.ouvrir(cours: cours, preVol: t.preVol.verifier);

      expect(t.controleur.etatCourant.refus, MotifRefusSalle.reseau);
      expect(t.controleur.etatCourant.cours, isNull);
    });

    test('un second appel ne rejoint pas une seconde fois', () async {
      // **C'est le retour instantane depuis la barre « Cours en cours ».** Une
      // seconde entree redemanderait un jeton et ouvrirait une seconde `Room`,
      // ce que le socle interdit.
      final _Banc t = monter();

      await t.controleur.ouvrir(cours: cours, preVol: t.preVol.verifier);
      await t.controleur.ouvrir(cours: cours, preVol: t.preVol.verifier);

      expect(t.preVol.verifications, 1);
      expect(t.video.demandes, hasLength(1));
      expect(t.moteur.entrees, hasLength(1));
    });
  });

  group('sortie volontaire', () {
    test('l annonce precede la deconnexion', () async {
      // LiveKit emet le meme evenement `left` dans les deux cas ; seule cette
      // ecriture distingue une sortie voulue d'une perte de reseau, et le
      // webhook la deduplique dans une fenetre de 30 secondes. Annoncer apres
      // laisserait le webhook arriver le premier et inscrire une deconnexion.
      final _Banc t = monter();

      await t.controleur.ouvrir(cours: cours, preVol: t.preVol.verifier);
      t.journal.clear();
      await t.controleur.quitter();

      expect(t.journal, <String>['annonce', 'deconnexion']);
      expect(t.video.sorties, <String>['s1']);
      expect(t.moteur.departs, 1);
      expect(t.controleur.etatCourant.cours, isNull);
    });

    test('un second appui pendant l attente ne reannonce pas', () async {
      final _Banc t = monter();

      await t.controleur.ouvrir(cours: cours, preVol: t.preVol.verifier);
      await Future.wait(<Future<void>>[
        t.controleur.quitter(),
        t.controleur.quitter(),
      ]);

      // L'etat est pose AVANT les appels reseau : la seconde sortie ne trouve
      // plus de cours a annoncer.
      expect(t.video.sorties, <String>['s1']);
    });
  });

  group('navigation et arriere-plan', () {
    test('rien ne coupe la salle sans geste explicite', () async {
      final _Banc t = monter();

      await t.controleur.ouvrir(cours: cours, preVol: t.preVol.verifier);

      // Le systeme suspend l'application : un appel telephonique, un passage a
      // une autre application. **Rien n'est coupe.**
      t.controleur.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(t.controleur.etatCourant.enArrierePlan, isTrue);
      expect(t.moteur.departs, 0);
      expect(t.controleur.etatCourant.cours, cours);

      t.controleur.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(t.controleur.etatCourant.enArrierePlan, isFalse);
      expect(t.moteur.departs, 0);
      // **Le doute survit au retour.** On ne promet pas une connexion que la
      // plateforme ne permet pas : il faut que le moteur la redise.
      expect(t.controleur.etatCourant.retourDeSuspension, isTrue);

      t.controleur.confirmerLien();
      expect(t.controleur.etatCourant.retourDeSuspension, isFalse);
    });

    test('confirmer un lien jamais suspendu ne change rien', () async {
      final _Banc t = monter();
      await t.controleur.ouvrir(cours: cours, preVol: t.preVol.verifier);
      final EtatSessionPersistante avant = t.controleur.etatCourant;
      t.controleur.confirmerLien();
      expect(identical(t.controleur.etatCourant, avant), isTrue);
    });

    test('liberer le controleur ne quitte pas la salle', () async {
      // Le conteneur Riverpod se defait quand l'application se ferme ; le
      // moteur, lui, est libere par son propre `onDispose`.
      final List<String> journal = <String>[];
      final FauxMoteurClasse moteur = FauxMoteurClasse(journal: journal);
      final ControleurSessionPersistante controleur =
          ControleurSessionPersistante(
            moteur,
            FauxServiceVideoClasse(
              acces0: accesDe('teacher'),
              journal: journal,
            ),
            observeLeCycleDeVie: false,
          );
      await controleur.ouvrir(
        cours: cours,
        preVol: FauxPreVolClasse().verifier,
      );
      controleur.liberer();
      expect(moteur.departs, 0);
    });
  });

  group('projection sur le contrat', () {
    test('sans horloge, le port rend un SessionEnCours a horloge nulle', () async {
      // `SessionEnCours.horloge` est nullable depuis l'amendement §3 de
      // TC_CONTRACT_REQUEST_E.md : l'horloge serveur n'existe pas encore, et
      // fabriquer une horloge locale resterait interdit, mais taire tout le
      // cours privait la barre « Cours en cours » de tout retour possible.
      final _Banc t = monter();

      await t.controleur.ouvrir(cours: cours, preVol: t.preVol.verifier);

      expect(t.controleur.etatCourant.cours, isNotNull);
      final SessionEnCours? rendu = await t.controleur.courante();
      expect(rendu, isNotNull);
      expect(rendu!.horloge, isNull);
    });

    test('avec horloge, le port rend un SessionEnCours', () async {
      final _Banc t = monter();

      await t.controleur.ouvrir(cours: cours, preVol: t.preVol.verifier);
      t.controleur.rafraichirHorloge('s1', _horloge());

      final SessionEnCours? rendu = await t.controleur.courante();
      expect(rendu, isNotNull);
      expect(rendu!.sessionId, 's1');
      expect(rendu.libelleGroupe, 'Groupe Al-Fatiha');
      expect(rendu.horloge?.restant, const Duration(minutes: 47));
    });

    test('une horloge d une autre seance est ignoree', () async {
      final _Banc t = monter();

      await t.controleur.ouvrir(cours: cours, preVol: t.preVol.verifier);
      t.controleur.rafraichirHorloge('AUTRE', _horloge());

      expect(t.controleur.etatCourant.cours?.horloge, isNull);
    });
  });
}

/// Le banc d'essai d'un test : le controleur et ses trois doubles.
class _Banc {
  const _Banc({
    required this.controleur,
    required this.moteur,
    required this.video,
    required this.preVol,
    required this.journal,
  });

  final ControleurSessionPersistante controleur;
  final FauxMoteurClasse moteur;
  final FauxServiceVideoClasse video;
  final FauxPreVolClasse preVol;

  /// Les gestes dans l'ordre : c'est lui qui prouve que l'annonce precede la
  /// deconnexion.
  final List<String> journal;
}

/// Une horloge de seance deja rendue par le serveur.
///
/// **Rien n'est calcule ici** : `restant` vient du port d'Agent A, derive de
/// l'instant serveur de reference.
SessionClockVM _horloge() => SessionClockVM(
  sessionId: 's1',
  debutUtc: DateTime.utc(2026, 9, 20, 16),
  finPrevueUtc: DateTime.utc(2026, 9, 20, 17),
  joinOpensAtUtc: DateTime.utc(2026, 9, 20, 15, 40),
  fenetreAcces: const Duration(minutes: 20),
  graceApresFin: const Duration(minutes: 15),
  horlogeUtilisateur: const HorlogeAffichee(
    fuseauIana: 'Europe/Paris',
    libelleVille: 'Paris',
    heureLocaleRendue: '18:00',
    dateLocaleRendue: 'Dimanche 20 septembre',
  ),
  phase: PhaseSeance.enCours,
  restant: const Duration(minutes: 47),
  rejoindreOuvert: true,
  calculeeAUtc: DateTime.utc(2026, 9, 20, 16, 13),
);
