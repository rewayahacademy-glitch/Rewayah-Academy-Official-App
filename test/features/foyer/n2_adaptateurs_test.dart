// N2 (03/11/2026) : la lecture des reponses du serveur pour le second adulte
// du foyer. `mon_invitation_en_cours` / `repondre_invitation_conjoint`
// (0053), `etat_reprise_foyer` (0098) et `mon_role_foyer` (20261106700000).
// Formes rendues par les fonctions, telles qu'ecrites dans les migrations.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';
import 'package:rewayah_academy/features/foyer/reponse_invitation_supabase.dart';
import 'package:rewayah_academy/features/foyer/reprise_foyer_supabase.dart';
import 'package:rewayah_academy/features/foyer/role_foyer.dart';

void main() {
  group('invitation recue', () {
    test('a_repondre : prenom, genre du titulaire, sans duree inventee', () {
      final EtatInvitationRecue e = etatInvitationDepuis(<String, Object?>{
        'etat': 'a_repondre',
        'prenom_titulaire': 'Amina',
        'titulaire_feminin': true,
        'validation_requise': false,
        'duree_conservation': null,
      });
      expect(e, isA<InvitationARepondre>());
      final InvitationARepondre a = e as InvitationARepondre;
      expect(a.prenomTitulaire, 'Amina');
      expect(a.titulaireFeminin, isTrue);
      expect(a.dureeConservation, isNull);
    });

    test('acceptee et refusee : la date rendue, jamais calculee', () {
      final EtatInvitationRecue acceptee = etatInvitationDepuis(
        <String, Object?>{
          'etat': 'acceptee',
          'prenom_titulaire': 'Amina',
          'enregistree_le': '2026-11-03T10:00:00Z',
        },
      );
      expect(acceptee, isA<InvitationAcceptee>());
      expect((acceptee as InvitationAcceptee).enregistreeLe, isNotNull);
      final EtatInvitationRecue refusee = etatInvitationDepuis(
        <String, Object?>{'etat': 'refusee', 'enregistree_le': null},
      );
      expect(refusee, isA<InvitationRefuseeParVous>());
      expect((refusee as InvitationRefuseeParVous).enregistreeLe, isNull);
    });

    test('perimee, non_acceptable et toute forme inconnue', () {
      expect(
        etatInvitationDepuis(<String, Object?>{'etat': 'perimee'}),
        isA<InvitationPerimee>(),
      );
      expect(
        etatInvitationDepuis(<String, Object?>{'etat': 'non_acceptable'}),
        isA<InvitationNonAcceptable>(),
      );
      // Forme neutre, sans motif (F4) : jamais un etat devine.
      expect(etatInvitationDepuis(null), isA<InvitationNonAcceptable>());
      expect(
        etatInvitationDepuis(<String, Object?>{'etat': 'a_repondre'}),
        isA<InvitationNonAcceptable>(),
      );
    });
  });

  group('reprise du foyer', () {
    test('cote second adulte : statut et dates rendus', () {
      final EtatReprise e = etatRepriseDepuis(<String, Object?>{
        'type': 'demande',
        'statut': 'attente_administration',
        'deposee_le': '2026-11-01T08:00:00Z',
        'examen_possible_le': '2026-11-08T08:00:00Z',
        'redepot_possible_le': null,
      });
      expect(e, isA<RepriseDemande>());
      final RepriseDemande d = e as RepriseDemande;
      expect(d.statut, StatutReprise.attenteAdministration);
      expect(d.deposeeLe, isNotNull);
      expect(d.redepotPossibleLe, isNull);
      for (final (String brut, StatutReprise attendu)
          in <(String, StatutReprise)>[
            ('deposee', StatutReprise.deposee),
            ('refusee_par_titulaire', StatutReprise.refuseeParTitulaire),
            ('validee', StatutReprise.validee),
            ('refusee', StatutReprise.refusee),
          ]) {
        expect(
          (etatRepriseDepuis(<String, Object?>{
            'type': 'demande',
            'statut': brut,
          }) as RepriseDemande).statut,
          attendu,
        );
      }
    });

    test('aucune demande, ou la vue du titulaire : rien a deposer de lu', () {
      expect(
        etatRepriseDepuis(<String, Object?>{'type': 'aucune'}),
        isA<RepriseAucune>(),
      );
      expect(
        etatRepriseDepuis(<String, Object?>{
          'type': 'titulaire',
          'statut': 'a_refuser',
        }),
        isA<RepriseAucune>(),
      );
    });

    test('cote titulaire : a refuser, refusee par vous, sinon rien', () {
      expect(
        demandeRepriseDepuis(<String, Object?>{
          'type': 'titulaire',
          'statut': 'a_refuser',
        }),
        isA<RepriseARefuser>(),
      );
      expect(
        demandeRepriseDepuis(<String, Object?>{
          'type': 'titulaire',
          'statut': 'refusee_par_vous',
        }),
        isA<RepriseRefuseeParVous>(),
      );
      expect(demandeRepriseDepuis(<String, Object?>{'type': 'aucune'}), isNull);
      expect(
        demandeRepriseDepuis(<String, Object?>{
          'type': 'demande',
          'statut': 'deposee',
        }),
        isNull,
      );
    });
  });

  group('role dans le foyer', () {
    test('titulaire, second adulte, aucun ; genre ou forme neutre', () {
      final RoleFoyerLu titulaire = roleFoyerDepuis(<String, Object?>{
        'role': 'titulaire',
        'genre': 'male',
      });
      expect(titulaire.role, RoleFoyer.titulaire);
      // Un titulaire homme invite une conjointe.
      expect(titulaire.placeFeminine, isTrue);
      expect(
        roleFoyerDepuis(<String, Object?>{
          'role': 'titulaire',
          'genre': 'female',
        }).placeFeminine,
        isFalse,
      );
      final RoleFoyerLu sansGenre = roleFoyerDepuis(<String, Object?>{
        'role': 'second_adulte',
        'genre': null,
      });
      expect(sansGenre.role, RoleFoyer.secondAdulte);
      expect(sansGenre.placeFeminine, isNull);
      expect(roleFoyerDepuis(null).role, RoleFoyer.aucun);
      expect(
        roleFoyerDepuis(<String, Object?>{'role': 'autre'}).role,
        RoleFoyer.aucun,
      );
    });
  });
}
