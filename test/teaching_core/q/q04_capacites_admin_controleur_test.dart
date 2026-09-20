// Q-04 : les capacites de l Admin (incognito / visible) et du Controleur
// (incognito seul) sont correctes.
//
// INVARIANT 6 de la Phase 6 (spec section 15 : « aucun Admin/Controleur
// incognito n apparait chez les participants ») et section 15 encore
// (« aucun participant visible ne peut obtenir des capacites superieures a
// son token »). Decisions D-15 et D-16.
//
// OU EST LA VERITE. Les capacites viennent du jeton serveur
// (`autoriser_jeton_video`), derivees du SEUL role. Ce test ne les applique
// pas : il verifie que la table des roles dit la bonne chose, pour qu Agent Z
// la confronte au SQL. C est une specification executable, pas une barriere.

import 'package:flutter_test/flutter_test.dart';

import '../fixtures/contrats/contrats_f_etat_partage.dart';
import '../fixtures/contrats/contrats_g_observation.dart';
import '../fixtures/fixtures_observation.dart';
import 'faux/faux_serveur_observation.dart';

final DateTime _t0 = DateTime.utc(2026, 10, 19, 16);

void main() {
  group('Q-04 : la table des capacites par role', () {
    test('le tuteur observe, muet et sans camera, et l enseignant le sait', () {
      final CapacitesObservateur c = capacitesDe(RoleObservateur.tuteur);

      expect(c.micro, isFalse);
      expect(c.camera, isFalse);
      expect(c.publicationData, isFalse);
      expect(c.visibleDesParticipants, isFalse);
      // « Tuteur d Amina observe » : l enseignant est prevenu de l entree.
      expect(c.annonceFaite, isTrue);
      expect(c.auditee, isTrue);
    });

    test('l Admin incognito est invisible aux participants, sans annonce', () {
      final CapacitesObservateur c = capacitesDe(RoleObservateur.adminIncognito);

      expect(c.visibleDesParticipants, isFalse);
      expect(c.annonceFaite, isFalse);
      expect(c.micro, isFalse);
      expect(c.camera, isFalse);
      expect(c.publicationData, isFalse);
    });

    test('l Admin visible parle, sous un nom institutionnel, et est annonce', () {
      final CapacitesObservateur c = capacitesDe(RoleObservateur.adminVisible);

      expect(c.visibleDesParticipants, isTrue);
      expect(c.annonceFaite, isTrue);
      expect(c.micro, isTrue);
      expect(c.camera, isTrue);
      expect(nomInstitutionnelAdmin, 'Administration Rewayah');
    });

    test('le Controleur est incognito, et ce chantier ne lui offre pas le choix', () {
      final CapacitesObservateur c = capacitesDe(RoleObservateur.controleur);

      expect(c.visibleDesParticipants, isFalse);
      expect(c.annonceFaite, isFalse);
      expect(c.micro, isFalse);
      expect(c.camera, isFalse);
      expect(c.publicationData, isFalse);

      // Decision D-16 : aucune variante visible n existe. L enumeration porte
      // quatre roles, dont un SEUL est visible, et ce n est pas le Controleur.
      final List<RoleObservateur> visibles = RoleObservateur.values
          .where((RoleObservateur r) => capacitesDe(r).visibleDesParticipants)
          .toList();
      expect(visibles, <RoleObservateur>[RoleObservateur.adminVisible]);
      expect(
        RoleObservateur.values.map((RoleObservateur r) => r.name),
        isNot(contains('controleurVisible')),
      );
    });

    test('l incognito est invisible aux participants, jamais a l audit', () {
      // La phrase non negociable de D-15, verifiee sur les quatre roles :
      // aucun d eux n echappe au journal.
      for (final RoleObservateur role in RoleObservateur.values) {
        expect(
          capacitesDe(role).auditee,
          isTrue,
          reason: '${role.name} doit etre journalise',
        );
      }
    });

    test('personne, sauf l Admin visible, ne publie de donnees', () {
      final List<RoleObservateur> publiants = RoleObservateur.values
          .where((RoleObservateur r) => capacitesDe(r).publicationData)
          .toList();
      expect(publiants, <RoleObservateur>[RoleObservateur.adminVisible]);
    });

    test('un observateur silencieux n a aucune capacite pedagogique', () {
      // Le tuteur ne voit ni roster, ni fiche, ni outil : ses capacites
      // pedagogiques sont toutes fausses, sauf celle d etre observateur.
      const CapacitesPedagogiques tuteur = CapacitesPedagogiques(
        peutPiloterSupport: false,
        peutAnnoter: false,
        peutEmettreNudge: false,
        estObservateurSilencieux: true,
      );
      expect(tuteur.peutPiloterSupport, isFalse);
      expect(tuteur.peutAnnoter, isFalse);
      expect(tuteur.peutEmettreNudge, isFalse);
      expect(tuteur.estObservateurSilencieux, isTrue);
    });
  });

  group('Q-04 : le role est porte par la visite journalisee', () {
    test('une visite Admin incognito est auditee comme les autres', () {
      final FauxServeurObservation serveur = FauxServeurObservation(
        politique: politiquePersonnalisee,
      );
      serveur.entrer(
        sessionId: 'seance-1',
        groupeId: 'grp-plein',
        observateurProfilId: 'admin-1',
        role: RoleObservateur.adminIncognito,
        maintenantUtc: _t0,
      );
      final GuardianSessionVisit? fermee = serveur.sortir(
        maintenantUtc: _t0.add(const Duration(seconds: 60)),
      );

      expect(fermee?.role, RoleObservateur.adminIncognito);
      expect(fermee?.durationSeconds, const Duration(seconds: 60));
      expect(fermee?.policyVersion, politiquePersonnalisee.policyVersion);
      // Un Admin n observe pas « un enfant » : il observe une seance.
      expect(fermee?.enfantConcerneId, isNull);
      expect(serveur.journal, hasLength(1));
    });
  });
}
