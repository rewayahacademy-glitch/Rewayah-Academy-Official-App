import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_groupe/demonstration_groupes.dart';
import 'package:rewayah_academy/core/tc_groupe/group_home_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/tc_horloge/demonstration_horloge.dart';

GroupSummaryVM _groupe({
  int membres = 4,
  int seuil = 5,
  String? photo = 'demo/photos/youssouf.jpg',
  TitreEnseignant titre = TitreEnseignant.sayyid,
}) => GroupSummaryVM(
  groupeId: 'g-1',
  libelle: 'Classe Al-Fatiha',
  couleurJeton: const JetonCouleurGroupe(index: 0, codeStable: 'g04'),
  enseignant: EnseignantVM(
    enseignantId: 'e-1',
    titre: titre,
    nomAffichage: 'Youssouf',
    photoUrlOuCle: photo,
  ),
  nomCours: 'Lecture du Coran',
  niveauHumain: 'Niveau 2',
  nombreMembres: membres,
  seuilMax: seuil,
  typePublic: TypePublicGroupeVM.enfant,
  actif: true,
);

void main() {
  group('GroupSummaryVM : la capacite', () {
    test('elle se lit de la donnee, jamais d un plafond ecrit en dur', () {
      expect(LibellesGroupe.capacite(membres: 4, seuil: 5), '4 / 5');
      expect(LibellesGroupe.capacite(membres: 3, seuil: 4), '3 / 4');
      // Un groupe d'adultes va jusqu'a six : aucune de ces valeurs n'est
      // supposee par le client.
      expect(LibellesGroupe.capacite(membres: 2, seuil: 6), '2 / 6');
    });

    test('complet et places libres derivent du seuil serveur', () {
      expect(_groupe(membres: 4, seuil: 5).complet, isFalse);
      expect(_groupe(membres: 4, seuil: 5).placesLibres, 1);
      expect(_groupe(membres: 4, seuil: 4).complet, isTrue);
      expect(_groupe(membres: 4, seuil: 4).placesLibres, 0);
      // Un effectif au dela du seuil ne produit jamais un nombre negatif.
      expect(_groupe(membres: 7, seuil: 5).placesLibres, 0);
    });

    test('le jeu de demonstration couvre 4/5 et 3/4', () {
      final List<GroupSummaryVM> gabarits =
          GroupesDemonstrationLocale.gabarits();
      final Set<String> capacites = <String>{
        for (final GroupSummaryVM g in gabarits)
          LibellesGroupe.capacite(membres: g.nombreMembres, seuil: g.seuilMax),
      };
      expect(capacites, contains('4 / 5'));
      expect(capacites, contains('3 / 4'));
    });
  });

  group('GroupSummaryVM : l enseignant', () {
    test('le titre est Sayyid ou Sayyida, jamais Ustaz', () {
      expect(
        LibellesGroupe.enseignantNomme(_groupe().enseignant),
        'Sayyid Youssouf',
      );
      expect(
        LibellesGroupe.enseignantNomme(
          _groupe(titre: TitreEnseignant.sayyida).enseignant,
        ),
        'Sayyida Youssouf',
      );
      for (final GroupSummaryVM g in GroupesDemonstrationLocale.gabarits()) {
        expect(
          LibellesGroupe.enseignantNomme(g.enseignant).toLowerCase(),
          isNot(contains('ustaz')),
        );
      }
    });

    test('la photo absente est une absence, pas un avatar', () {
      expect(_groupe().enseignant.photoManquante, isFalse);
      expect(_groupe(photo: null).enseignant.photoManquante, isTrue);
      // Une chaine vide est une absence au meme titre qu'un nul.
      expect(_groupe(photo: '   ').enseignant.photoManquante, isTrue);
    });

    test('le titre se lit de sa valeur SQL, et rend nul si inconnue', () {
      expect(TitreEnseignant.depuisSql('sayyida'), TitreEnseignant.sayyida);
      expect(TitreEnseignant.depuisSql('ustaz'), isNull);
      expect(TitreEnseignant.depuisSql(null), isNull);
    });
  });

  group('GroupSummaryVM : le cours et le niveau', () {
    test('ils se composent en langage humain', () {
      expect(
        LibellesGroupe.coursEtNiveau(
          cours: 'Lecture du Coran',
          niveau: 'Niveau 2',
        ),
        'Lecture du Coran · Niveau 2',
      );
    });

    test('un niveau absent ne laisse pas de separateur orphelin', () {
      expect(
        LibellesGroupe.coursEtNiveau(cours: 'Lecture du Coran'),
        'Lecture du Coran',
      );
      expect(LibellesGroupe.coursEtNiveau(), isEmpty);
    });
  });

  group('GroupSummaryVM : le temps', () {
    test('sans horloge, aucun bouton ne s ouvre', () {
      expect(_groupe().rejoindreOuvert, isFalse);
    });

    test('avec horloge, la decision vient d elle', () async {
      final GroupesDemonstrationLocale port = GroupesDemonstrationLocale(
        horloges: HorlogeSeanceDemonstration(cadence: Duration.zero),
      );
      final GroupSummaryVM? ouvert = await port.groupe(
        GroupesDemonstration.anNour,
      );
      final GroupSummaryVM? ferme = await port.groupe(
        GroupesDemonstration.alFatiha,
      );
      expect(ouvert!.rejoindreOuvert, isTrue);
      expect(ferme!.rejoindreOuvert, isFalse);
    });

    test('un groupe sans occurrence reste un groupe', () async {
      final GroupesDemonstrationLocale port = GroupesDemonstrationLocale(
        horloges: HorlogeSeanceDemonstration(cadence: Duration.zero),
      );
      final GroupSummaryVM? sabil = await port.groupe(
        GroupesDemonstration.sabil,
      );
      expect(sabil, isNotNull);
      expect(sabil!.prochaineSeance, isNull);
      expect(sabil.horloge, isNull);
      expect(sabil.libelle, isNotEmpty);
    });

    test('un groupe inconnu rend nul, pas une carte vide', () async {
      final GroupesDemonstrationLocale port = GroupesDemonstrationLocale(
        horloges: HorlogeSeanceDemonstration(cadence: Duration.zero),
      );
      expect(await port.groupe('inexistant'), isNull);
    });
  });

  group('GroupHomeVM : la composition par role', () {
    test('le roster n est ouvert qu au cote pedagogique', () {
      for (final RoleEspaceGroupe role in RoleEspaceGroupe.values) {
        final GroupHomeVM espace = GroupHomeVM.pourRole(
          identite: _groupe(),
          role: role,
        );
        final bool attenduNonNul =
            role == RoleEspaceGroupe.enseignant ||
            role == RoleEspaceGroupe.admin;
        expect(espace.roster != null, attenduNonNul, reason: role.name);
      }
    });

    test('l eleve et le tuteur sont du cote famille', () {
      expect(
        GroupHomeVM.pourRole(
          identite: _groupe(),
          role: RoleEspaceGroupe.eleve,
        ).estCoteFamille,
        isTrue,
      );
      expect(
        GroupHomeVM.pourRole(
          identite: _groupe(),
          role: RoleEspaceGroupe.enseignant,
        ).estCoteFamille,
        isFalse,
      );
    });

    test('la bibliotheque est une enveloppe, jamais un contenu', () {
      final GroupHomeVM espace = GroupHomeVM.pourRole(
        identite: _groupe(),
        role: RoleEspaceGroupe.eleve,
      );
      expect(espace.bibliotheque.groupeId, 'g-1');
    });

    test('plus de trois actions est un defaut, pas une troncature', () {
      expect(
        () => GroupHomeVM.pourRole(
          identite: _groupe(),
          role: RoleEspaceGroupe.eleve,
          actions: const <SlotAction>[
            SlotAction(id: '1', libelle: 'a'),
            SlotAction(id: '2', libelle: 'b'),
            SlotAction(id: '3', libelle: 'c'),
            SlotAction(id: '4', libelle: 'd'),
          ],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('trois actions passent', () {
      final GroupHomeVM espace = GroupHomeVM.pourRole(
        identite: _groupe(),
        role: RoleEspaceGroupe.eleve,
        actions: const <SlotAction>[
          SlotAction(id: '1', libelle: 'a'),
          SlotAction(id: '2', libelle: 'b'),
          SlotAction(id: '3', libelle: 'c'),
        ],
      );
      expect(espace.avantProchainCours, hasLength(3));
    });
  });

  group('Les libelles de duree et de compte a rebours', () {
    test('la duree se lit en heures et minutes', () {
      expect(
        LibellesGroupe.dureeLisible(const Duration(hours: 1, minutes: 30)),
        '1\u00A0h\u00A030',
      );
      expect(LibellesGroupe.dureeLisible(const Duration(hours: 1)), '1\u00A0h');
      expect(
        LibellesGroupe.dureeLisible(const Duration(minutes: 45)),
        '45\u00A0min',
      );
    });

    test('le compte a rebours coupe a une heure, comme ELV-02', () {
      expect(
        LibellesGroupe.compteARebours(const Duration(hours: 3, minutes: 28)),
        'Cours dans 3\u00A0h\u00A028',
      );
      expect(
        LibellesGroupe.compteARebours(const Duration(minutes: 28)),
        'Cours dans 28\u00A0min',
      );
      expect(
        LibellesGroupe.compteARebours(Duration.zero),
        LibellesGroupe.imminent,
      );
    });

    test('le temps restant ne descend jamais sous zero', () {
      expect(
        LibellesGroupe.tempsRestant(const Duration(minutes: -5)),
        'Reste 0\u00A0min',
      );
    });
  });
}
