import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_groupe/demonstration_groupes.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/groupes_supabase.dart';
import 'package:rewayah_academy/core/tc_groupe/port_groupes.dart';
import 'package:rewayah_academy/core/tc_horloge/demonstration_horloge.dart';
import 'package:rewayah_academy/core/tc_horloge/horloge_supabase.dart';
import 'package:rewayah_academy/core/tc_horloge/port_horloge_seance.dart';
import 'package:rewayah_academy/core/tc_horloge/session_clock_vm.dart';

/// Une ligne telle que `mes_groupes_famille_v` la rend (migration 0033).
Map<String, dynamic> _ligne({
  int? seuil = 4,
  int? couleur = 7,
  String? titre = 'sayyida',
  String? prenom = 'Amina',
  String? photo = 'teachers/amina.jpg',
}) => <String, dynamic>{
  'groupe_id': '4f2c1b9e-0000-4000-8000-000000000001',
  'libelle': 'Classe An-Nour',
  'type_public': 'adulte',
  'seuil_max': seuil,
  'weekday': 2,
  'hour_local': '18:00:00',
  'timezone_iana': 'Europe/Paris',
  'couleur_jeton': couleur,
  'nom_cours': 'Regles de lecture',
  'programme_niveau_id': null,
  'teacher_id': 'a1b2c3d4-0000-4000-8000-000000000002',
  'teacher_prenom': prenom,
  'teacher_titre': titre,
  'teacher_photo_cle': photo,
  'nb_membres': 3,
};

void main() {
  group('V0 : la production ne sert plus de groupes fictifs', () {
    test('hors Playground, le port des groupes n est pas le double', () {
      // Sans Supabase initialise, l'adaptateur reel ne peut pas etre
      // construit dans un test : on prouve seulement que le choix ne retombe
      // jamais sur la demonstration quand `demo` est faux.
      expect(portGroupesSelon(demo: true), isA<GroupesDemonstrationLocale>());
      expect(
        () => portGroupesSelon(demo: false),
        // `Supabase.instance` leve tant que `Supabase.initialize` n'a pas
        // tourne : c'est la preuve que le chemin production ne passe pas par
        // le double.
        throwsA(isNot(isA<GroupesDemonstrationLocale>())),
      );
      expect(portHorlogeSelon(demo: true), isA<HorlogeSeanceDemonstration>());
      expect(
        () => portHorlogeSelon(demo: false),
        throwsA(isNot(isA<HorlogeSeanceDemonstration>())),
      );
    });
  });

  group('groupeDepuisLigne', () {
    test('lit la vue sans inventer de valeur', () {
      final GroupSummaryVM g = groupeDepuisLigne(_ligne());

      expect(g.groupeId, '4f2c1b9e-0000-4000-8000-000000000001');
      expect(g.libelle, 'Classe An-Nour');
      expect(g.typePublic, TypePublicGroupeVM.adulte);
      expect(g.seuilMax, 4);
      expect(g.nombreMembres, 3);
      expect(g.placesLibres, 1);
      expect(g.couleurJeton.index, 7);
      expect(g.couleurJeton.codeStable, 'g07');
      expect(g.nomCours, 'Regles de lecture');
      expect(g.niveauHumain, isNull);
      expect(g.enseignant.titre, TitreEnseignant.sayyida);
      expect(g.enseignant.nomAffichage, 'Amina');
      expect(g.enseignant.photoManquante, isFalse);
      expect(g.actif, isTrue);
      // Aucune occurrence dans la vue : aucun compte a rebours fabrique.
      expect(g.prochaineSeance, isNull);
      expect(g.horloge, isNull);
      expect(g.rejoindreOuvert, isFalse);
    });

    test('un seuil absent est une ligne invalide, jamais un 5 par defaut', () {
      expect(
        () => groupeDepuisLigne(_ligne(seuil: null)),
        throwsA(isA<FormatException>()),
      );
    });

    test('couleur absente : index 0 ; photo absente : etat manquant', () {
      final GroupSummaryVM g = groupeDepuisLigne(
        _ligne(couleur: null, photo: null, prenom: null),
      );
      expect(g.couleurJeton.index, 0);
      expect(g.enseignant.photoManquante, isTrue);
      expect(etatPhoto(g.enseignant), EtatPhotoEnseignant.manquante);
      expect(g.enseignant.nomAffichage, '');
    });
  });

  group('horlogeDepuisLigne', () {
    Map<String, dynamic> ligneHorloge({
      required String maintenant,
    }) => <String, dynamic>{
      'session_id': 's-1',
      'debut_utc': '2026-09-28T15:00:00+00:00',
      'fin_prevue_utc': '2026-09-28T16:00:00+00:00',
      'join_opens_at_utc': '2026-09-28T14:40:00+00:00',
      'fenetre_minutes': 20,
      'grace_minutes': 15,
      'maintenant_utc': maintenant,
      'tz_utilisateur': 'Europe/Paris',
      'heure_utilisateur': '17:00',
      'jour_iso_utilisateur': 1,
      'date_utilisateur': '2026-09-28',
      'tz_groupe': 'Africa/Conakry',
      'heure_groupe': '15:00',
      'jour_iso_groupe': 1,
      'date_groupe': '2026-09-28',
    };

    test('les heures arrivent rendues, la phase vient de l instant serveur', () {
      final SessionClockVM h = horlogeDepuisLigne(
        ligneHorloge(maintenant: '2026-09-28T14:45:00+00:00'),
      );
      expect(h.phase, PhaseSeance.salleOuverte);
      expect(h.rejoindreOuvert, isTrue);
      expect(h.restant, const Duration(minutes: 15));
      expect(h.horlogeUtilisateur.heureLocaleRendue, '17:00');
      expect(h.horlogeUtilisateur.dateLocaleRendue, 'Lundi 28 septembre');
      expect(h.horlogeUtilisateur.libelleVille, 'Paris');
      expect(h.horlogeContrepartie?.libelleVille, 'Conakry');
      expect(h.horlogeContrepartie?.heureLocaleRendue, '15:00');
    });

    test('apres la fin prevue, jamais de temps negatif', () {
      final SessionClockVM h = horlogeDepuisLigne(
        ligneHorloge(maintenant: '2026-09-28T16:05:00+00:00'),
      );
      expect(h.phase, PhaseSeance.prolongee);
      expect(h.restant, isNull);
    });

    test('fuseaux identiques : une seule horloge', () {
      final Map<String, dynamic> l = ligneHorloge(
        maintenant: '2026-09-28T10:00:00+00:00',
      );
      l['tz_groupe'] = 'Europe/Paris';
      expect(horlogeDepuisLigne(l).horlogeContrepartie, isNull);
    });

    test('jours et mois viennent des libelles, accents compris', () {
      expect(
        dateRendue(jourIso: 6, dateIso: '2027-02-06'),
        'Samedi 6 février',
      );
      expect(dateRendue(jourIso: 7, dateIso: '2027-08-01'), 'Dimanche 1 août');
      expect(
        dateRendue(jourIso: 5, dateIso: '2026-12-25'),
        'Vendredi 25 décembre',
      );
    });

    test('villeDeFuseau ne rend jamais un decalage', () {
      expect(villeDeFuseau('America/New_York'), 'New York');
      expect(villeDeFuseau('Asia/Riyadh'), 'Riyadh');
    });
  });
}
