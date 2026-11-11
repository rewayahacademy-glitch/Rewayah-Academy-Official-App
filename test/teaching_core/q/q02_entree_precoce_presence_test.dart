// Q-02 : une entree a T-20 ne modifie pas la fenetre de presence academique.
//
// INVARIANT 8 de la Phase 6 (spec section 15 : « l'entree a T-20 ne fausse pas
// la presence academique »), decision D-13.
//
// DEUX TESTS DE NATURES DIFFERENTES COHABITENT ICI, ET C'EST VOULU.
// 1. Les tests de CONTRAT decrivent ce que le Teaching Core doit faire. Ils
//    s'appuient sur `dureeAcademique`, qui est la forme executable de la
//    correction demandee par D-13 : borner le depart a
//    `max(entreLe, debutSeance)`.
// 2. Le dernier test est un test de CARACTERISATION du depot actuel. Il
//    mesure le defaut latent de `VuePresence.depuis` -- aujourd'hui vert,
//    **et destine a devenir rouge** le jour ou la correction arrive. C'est son
//    role : signaler que la correction a eu lieu, pour qu'on ajuste le
//    contrat au lieu de la decouvrir six mois plus tard.

// Suppression du 08/11/2026 (feu vert du directeur) : le groupe sur
// `dureeAcademique` est retire avec le fichier ; le serveur fait foi
// (`etat_presence`).

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/presence/vue_presence.dart';
import 'package:rewayah_academy/core/tc_horloge/session_clock_vm.dart';

import '../fixtures/fixtures_horloge.dart';

void main() {
  group('Q-02 : la fenetre d acces est une donnee, jamais une constante', () {
    test('changer la fenetre deplace joinOpensAt d autant', () {
      // Si `fenetreAcces` etait codee en dur cote client, ce test ne bougerait
      // pas. C est la seule maniere de prouver qu elle vient du port.
      final SessionClockVM vingt = horlogeSeance(
        maintenant: instantDe(MomentSeance.tMoins30),
      );
      final SessionClockVM trente = horlogeSeance(
        maintenant: instantDe(MomentSeance.tMoins30),
        fenetreAcces: const Duration(minutes: 30),
      );

      expect(
        vingt.joinOpensAtUtc,
        vingt.debutUtc.subtract(const Duration(minutes: 20)),
      );
      expect(
        trente.joinOpensAtUtc,
        trente.debutUtc.subtract(const Duration(minutes: 30)),
      );
      // A T-30, une fenetre de 20 min laisse le bouton ferme, une fenetre de
      // 30 min vient juste de l ouvrir.
      expect(vingt.rejoindreOuvert, isFalse);
      expect(trente.rejoindreOuvert, isTrue);
    });

    test('les six moments d une seance donnent six phases distinctes', () {
      final Map<MomentSeance, PhaseSeance> attendu =
          <MomentSeance, PhaseSeance>{
            MomentSeance.tMoins30: PhaseSeance.avantFenetre,
            MomentSeance.tMoins20: PhaseSeance.salleOuverte,
            MomentSeance.t0: PhaseSeance.enCours,
            MomentSeance.enDirect: PhaseSeance.enCours,
            MomentSeance.depassement: PhaseSeance.prolongee,
            MomentSeance.terminee: PhaseSeance.terminee,
          };
      attendu.forEach((MomentSeance moment, PhaseSeance phase) {
        expect(
          horlogeSeance(maintenant: instantDe(moment)).phase,
          phase,
          reason: 'moment ${moment.name}',
        );
      });
    });

    test('aucun countdown negatif en depassement ni apres la fin', () {
      expect(
        horlogeSeance(maintenant: instantDe(MomentSeance.depassement)).restant,
        isNull,
      );
      expect(
        horlogeSeance(maintenant: instantDe(MomentSeance.terminee)).restant,
        isNull,
      );
      expect(
        horlogeSeance(maintenant: instantDe(MomentSeance.terminee))
            .rejoindreOuvert,
        isFalse,
      );
    });
  });

  group('Q-02 : caracterisation du defaut latent de VuePresence', () {
    test(
      'aujourd hui, une entree a T-20 affiche trente-huit minutes en salle',
      () {
        // DEFAUT CONNU, NON CORRIGE, HORS MISSION (decision D-13).
        // `lib/core/presence/vue_presence.dart` calcule la duree depuis
        // `entre_le` brut, sans la borner a `max(entreLe, debutSeance)`. Tant
        // que la fenetre vaut T-10 le decalage passe inapercu ; a T-20 il
        // devient visible.
        //
        // CE TEST DOIT DEVENIR ROUGE LE JOUR DE LA CORRECTION. C est sa
        // fonction : il n approuve pas le defaut, il le rend impossible a
        // corriger en silence.
        final DateTime debut = DateTime(2026, 10, 19, 18);
        final DateTime maintenant = debut.add(const Duration(minutes: 18));
        final VuePresence vue = VuePresence.depuis(
          ligne: PresenceParticipant(
            profilId: 'p1',
            role: 'student',
            prenom: 'Amina',
            identifiantImmuable: 'RA-AB0012',
            etat: EtatPresence.presente,
            consolide: false,
            entreLe: debut.subtract(const Duration(minutes: 20)),
            debutSeance: debut,
          ),
          maintenant: maintenant,
        );

        expect(vue.repere, RepereTemps.entree);
        expect(
          vue.ecoule,
          const Duration(minutes: 38),
          reason:
              'si cette valeur est devenue 18 min, la correction D-13 a ete '
              'appliquee : mettre a jour ce test et le rapport Q',
        );
      },
    );
  });
}
