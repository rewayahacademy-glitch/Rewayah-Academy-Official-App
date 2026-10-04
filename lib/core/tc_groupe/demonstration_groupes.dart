import '../tc_horloge/demonstration_horloge.dart';
import '../tc_horloge/port_horloge_seance.dart';
import '../tc_horloge/session_clock_vm.dart';
import 'group_summary_vm.dart';
import 'port_groupes.dart';

/// Le double local des groupes.
///
/// **Ce n'est pas une implementation de production, et il ne doit pas le
/// devenir.** Cinq manques serveur, tous mesures, l'empechent d'en etre une :
///
/// 1. `public.sessions` n'a **aucune colonne `groupe_id`** : le Groupe et la
///    Classe Live ne sont relies par rien ;
/// 2. `materialiser_seances()` prend un identifiant d'affectation 1-a-1, donc
///    **un groupe cree ne produit aucune seance** ;
/// 3. `groupes.timezone_iana` existe mais **n'est ecrite par aucune RPC, lue
///    par aucune RPC**, et `GroupeAdmin.depuisJson` la recode en dur ;
/// 4. `groupes` n'a **ni couleur, ni cours, ni niveau** ;
/// 5. `teacher_profiles` n'a **aucune colonne de photo ni de titre**.
///
/// Chacun est chiffre dans `docs/archive/2026-09-pre-remise-a-plat/teaching-core/TC_CONTRACT_REQUEST_A.md`.
/// Les donnees ci-dessous sont coherentes avec `seancesDemonstration()` : le
/// meme identifiant de groupe y porte la meme occurrence.
class GroupesDemonstrationLocale implements PortGroupes {
  /// Cree le double.
  GroupesDemonstrationLocale({PortHorlogeSeance? horloges})
    : _horloges = horloges ?? HorlogeSeanceDemonstration();

  final PortHorlogeSeance _horloges;

  /// Les six groupes, choisis pour couvrir six etats et non pour faire nombre.
  ///
  /// `Sabil` n'a volontairement **aucune occurrence** : c'est l'etat reel de la
  /// base aujourd'hui, et une demonstration qui le cacherait mentirait sur ce
  /// qui reste a construire.
  static List<GroupSummaryVM> gabarits() => <GroupSummaryVM>[
    const GroupSummaryVM(
      groupeId: GroupesDemonstration.alFatiha,
      libelle: 'Groupe Al-Fatiha',
      couleurJeton: JetonCouleurGroupe(index: 0, codeStable: 'g04'),
      enseignant: EnseignantVM(
        enseignantId: 'demo-ens-youssouf',
        titre: TitreEnseignant.sayyid,
        nomAffichage: 'Youssouf',
        pays: 'Guinée',
        photoUrlOuCle: 'demo/photos/youssouf.jpg',
      ),
      nomCours: 'Lecture du Coran',
      niveauHumain: 'Niveau 2',
      nombreMembres: 4,
      seuilMax: 5,
      typePublic: TypePublicGroupeVM.enfant,
      actif: true,
    ),
    // Seuil 4 et non 5 : la capacite vient de la donnee, et l'interface doit
    // savoir ecrire « 3 / 4 » aussi bien que « 4 / 5 ».
    // Photo absente : etat d'erreur explicite, jamais un avatar generique.
    const GroupSummaryVM(
      groupeId: GroupesDemonstration.anNour,
      libelle: 'Groupe An-Nour',
      couleurJeton: JetonCouleurGroupe(index: 1, codeStable: 'g11'),
      enseignant: EnseignantVM(
        enseignantId: 'demo-ens-amina',
        titre: TitreEnseignant.sayyida,
        nomAffichage: 'Amina',
        pays: 'Sénégal',
      ),
      nomCours: 'Regles de lecture',
      niveauHumain: 'Niveau 1',
      nombreMembres: 3,
      seuilMax: 4,
      typePublic: TypePublicGroupeVM.adulte,
      actif: true,
    ),
    const GroupSummaryVM(
      groupeId: GroupesDemonstration.alIhsan,
      libelle: 'Groupe Al-Ihsan',
      couleurJeton: JetonCouleurGroupe(index: 6, codeStable: 'g14'),
      enseignant: EnseignantVM(
        enseignantId: 'demo-ens-fatima',
        titre: TitreEnseignant.sayyida,
        nomAffichage: 'Fatima',
        pays: "Côte d'Ivoire",
        photoUrlOuCle: 'demo/photos/fatima.jpg',
      ),
      nomCours: 'Lecture du Coran',
      niveauHumain: 'Niveau 2',
      nombreMembres: 4,
      seuilMax: 6,
      typePublic: TypePublicGroupeVM.adulte,
      actif: true,
    ),
    const GroupSummaryVM(
      groupeId: GroupesDemonstration.alBaqara,
      libelle: 'Groupe Al-Baqara',
      couleurJeton: JetonCouleurGroupe(index: 2, codeStable: 'g21'),
      enseignant: EnseignantVM(
        enseignantId: 'demo-ens-ibrahim',
        titre: TitreEnseignant.sayyid,
        nomAffichage: 'Ibrahim',
        pays: 'France',
        photoUrlOuCle: 'demo/photos/ibrahim.jpg',
      ),
      nomCours: 'Memorisation',
      niveauHumain: 'Niveau 3',
      nombreMembres: 5,
      seuilMax: 5,
      typePublic: TypePublicGroupeVM.enfant,
      actif: true,
    ),
    const GroupSummaryVM(
      groupeId: GroupesDemonstration.alHikma,
      libelle: 'Groupe Al-Hikma',
      couleurJeton: JetonCouleurGroupe(index: 3, codeStable: 'g27'),
      enseignant: EnseignantVM(
        enseignantId: 'demo-ens-khadija',
        titre: TitreEnseignant.sayyida,
        nomAffichage: 'Khadija',
        photoUrlOuCle: 'demo/photos/khadija.jpg',
      ),
      nomCours: 'Sciences du Coran',
      niveauHumain: 'Niveau 4',
      nombreMembres: 2,
      seuilMax: 6,
      typePublic: TypePublicGroupeVM.adulte,
      actif: true,
    ),
    const GroupSummaryVM(
      groupeId: GroupesDemonstration.arRahma,
      libelle: 'Groupe Ar-Rahma',
      couleurJeton: JetonCouleurGroupe(index: 4, codeStable: 'g33'),
      enseignant: EnseignantVM(
        enseignantId: 'demo-ens-moussa',
        titre: TitreEnseignant.sayyid,
        nomAffichage: 'Moussa',
        pays: 'Mali',
        photoUrlOuCle: 'demo/photos/moussa.jpg',
      ),
      nomCours: 'Lecture du Coran',
      niveauHumain: 'Niveau 1',
      nombreMembres: 2,
      seuilMax: 6,
      typePublic: TypePublicGroupeVM.adulte,
      actif: true,
    ),
    // Ni cours, ni niveau, ni occurrence : un groupe que l'administration vient
    // de creer, et que la base actuelle laisse exactement dans cet etat.
    const GroupSummaryVM(
      groupeId: GroupesDemonstration.sabil,
      libelle: 'Groupe Sabil',
      couleurJeton: JetonCouleurGroupe(index: 5, codeStable: 'g08'),
      enseignant: EnseignantVM(
        enseignantId: 'demo-ens-youssouf',
        titre: TitreEnseignant.sayyid,
        nomAffichage: 'Youssouf',
        pays: 'Guinée',
        photoUrlOuCle: 'demo/photos/youssouf.jpg',
      ),
      nombreMembres: 0,
      seuilMax: 5,
      typePublic: TypePublicGroupeVM.enfant,
      actif: true,
    ),
  ];

  Future<GroupSummaryVM> _avecHorloge(GroupSummaryVM gabarit) async {
    final SessionClockVM? horloge = await _horloges.horlogeDe(
      groupeId: gabarit.groupeId,
    );
    return horloge == null ? gabarit : gabarit.avecHorloge(horloge);
  }

  @override
  Future<List<GroupSummaryVM>> mesGroupes() async {
    final List<GroupSummaryVM> resultat = <GroupSummaryVM>[];
    for (final GroupSummaryVM gabarit in gabarits()) {
      resultat.add(await _avecHorloge(gabarit));
    }
    return resultat;
  }

  @override
  Future<GroupSummaryVM?> groupe(String groupeId) async {
    for (final GroupSummaryVM gabarit in gabarits()) {
      if (gabarit.groupeId == groupeId) {
        return _avecHorloge(gabarit);
      }
    }
    return null;
  }
}
