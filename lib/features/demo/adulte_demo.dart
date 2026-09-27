// Donnees de demonstration de l'eleve adulte (EA-1b) : le foyer Diallo de
// 16_eleves_adultes/V/00_MAQUETTES section 3, ses variantes (titulaire femme,
// vue du second adulte) et un etat nomme pour chacun des 25 cas du doc
// section 18. Aucune valeur economique : ni solde, ni offre, ni remise, ni
// taux (F12). Les dates de fin de delai sont des DONNEES, jamais un calcul
// (F17). Aucun appel serveur (K-28) : chaque besoin est une ligne d'EA-BR.md.

import '../../core/appairage/service_appairage.dart' show EleveDuFoyer;
import '../../core/domain/enums.dart';
import '../../core/planning/service_planning.dart' show Seance;
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../accueil_adulte/accueil_adulte_page.dart';
import 'classe_demo.dart';

/// Les 25 cas du doc section 18, dans son ordre.
enum EtatDemoAdulte {
  /// 1. Adulte seul, sans foyer.
  adulteSeul,

  /// 2. Titulaire sans conjoint.
  titulaireSansConjoint,

  /// 3. Invitation du conjoint en attente.
  invitationEnAttente,

  /// 4. Invitation expiree.
  invitationExpiree,

  /// 5. Invitation annulee.
  invitationAnnulee,

  /// 6. Conjoint actif.
  conjointActif,

  /// 7. Le conjoint quitte le foyer.
  conjointQuitte,

  /// 8. Le titulaire retire le conjoint.
  conjointRetire,

  /// 9. Delai de 60 jours.
  delai60,

  /// 10. Nouvelle demande apres 60 jours.
  nouvelleDemande,

  /// 11. Validation administrative en attente.
  validationEnAttente,

  /// 12. Validation administrative refusee.
  validationRefusee,

  /// 13. Second depart.
  secondDepart,

  /// 14. Delai de 120 jours.
  delai120,

  /// 15. Troisieme depart et suivants, toujours 120 jours.
  departsSuivants,

  /// 16. Demande de reprise du foyer.
  repriseDemandee,

  /// 17. Demande refusee par le titulaire.
  repriseRefuseeParTitulaire,

  /// 18. Jour 30 sans reponse, attente de l'administration.
  repriseSansReponse,

  /// 19. Reprise validee.
  repriseValidee,

  /// 20. Reprise refusee.
  repriseRefusee,

  /// 21. Adulte invite deja dans un autre foyer.
  dejaDansUnAutreFoyer,

  /// 22. Erreur reseau pendant une mutation.
  erreurReseau,

  /// 23. Double clic, double soumission.
  doubleSoumission,

  /// 24. Notification non delivrable en push, visible dans l'application.
  notificationDansLApplication,

  /// 25. Emancipation d'un eleve devenu adulte, sans perte de donnees.
  emancipation,
}

/// Le genre du titulaire : homme par defaut (Mamadou), femme en variante
/// (`&titulaire=femme`, place « conjoint »).
enum GenreTitulaireDemo { homme, femme }

/// La personne qui regarde : le titulaire, ou le second adulte
/// (`&vue=conjoint`).
enum VueDemoAdulte { titulaire, secondAdulte }

/// La ligne famille unique de Mon espace (UX_REVIEW_07 ligne 5 a) : jamais
/// deux a la fois.
enum LigneFamilleDemo {
  /// Adulte seul : « Ajouter ma famille ».
  ajouterMaFamille,

  /// Titulaire d'un foyer : « Ma famille ».
  maFamille,

  /// Second adulte : « Forfait famille ».
  forfaitFamille,
}

/// Le foyer Diallo, fige pour toute la vague (00_MAQUETTES section 3).
abstract final class DonneesAdulteDemo {
  /// L'identifiant du foyer.
  static const String foyerId = 'demo-foyer-diallo';

  /// Mamadou, titulaire par defaut, eleve de la Classe An-Nour.
  static const String mamadouId = 'demo-adulte-mamadou';

  /// Mariama, conjointe par defaut, eleve d'une autre Classe.
  static const String mariamaId = 'demo-adulte-mariama';

  /// Aicha, enfant du foyer.
  static const String aichaId = 'demo-enfant-aicha';

  /// Oumar, enfant du foyer.
  static const String oumarId = 'demo-enfant-oumar';

  /// La Classe du titulaire, la meme que la demonstration enseignant.
  static const String classeTitulaire = 'An-Nour';

  /// L'enseignant de la Classe An-Nour (demonstration enseignant).
  static const String enseignant = 'Sayyid Ibrahim';

  /// La fin de delai de la demonstration : l'exemple du doc section 10.4,
  /// une donnee rendue, jamais calculee dans Flutter (F17).
  static final DateTime finDelai = DateTime.utc(2026, 12, 18);

  /// La fin d'acces des enfants, fictive.
  static final DateTime finAcces = DateTime.utc(2099, 12, 31);

  /// Le prenom du titulaire selon la variante.
  static String prenomTitulaire(GenreTitulaireDemo genre) =>
      genre == GenreTitulaireDemo.homme ? 'Mamadou' : 'Mariama';

  /// Le prenom du second adulte selon la variante.
  static String prenomSecondAdulte(GenreTitulaireDemo genre) =>
      genre == GenreTitulaireDemo.homme ? 'Mariama' : 'Mamadou';

  /// Les enfants du foyer, tels que le Foyer du tuteur les lit.
  static final List<EleveDuFoyer> enfants = <EleveDuFoyer>[
    EleveDuFoyer(
      id: aichaId,
      prenom: 'Aïcha',
      identifiantImmuable: 'DEMO-D1',
      mode: InterfaceMode.enfant,
      camera: CameraPolicy.forbidden,
      finAcces: finAcces,
    ),
    EleveDuFoyer(
      id: oumarId,
      prenom: 'Oumar',
      identifiantImmuable: 'DEMO-D2',
      mode: InterfaceMode.enfant,
      camera: CameraPolicy.forbidden,
      finAcces: finAcces,
    ),
  ];

  /// Vrai si, dans cet etat, la personne a un foyer (titulaire ou second
  /// adulte). Seuls l'adulte seul et l'adulte deja ailleurs n'en ont pas ici.
  static bool aUnFoyer(EtatDemoAdulte etat) => switch (etat) {
    EtatDemoAdulte.adulteSeul || EtatDemoAdulte.dejaDansUnAutreFoyer => false,
    _ => true,
  };

  /// Vrai si le second adulte est encore rattache au foyer dans cet etat :
  /// ce qui ouvre sa vue (`&vue=conjoint`).
  static bool secondAdultePresent(EtatDemoAdulte etat) => switch (etat) {
    EtatDemoAdulte.conjointActif ||
    EtatDemoAdulte.repriseDemandee ||
    EtatDemoAdulte.repriseRefuseeParTitulaire ||
    EtatDemoAdulte.repriseSansReponse ||
    EtatDemoAdulte.repriseRefusee ||
    EtatDemoAdulte.erreurReseau ||
    EtatDemoAdulte.doubleSoumission ||
    EtatDemoAdulte.notificationDansLApplication => true,
    _ => false,
  };

  /// La date de fin du delai en cours, rendue telle quelle, ou nulle.
  static DateTime? finDelaiPour(EtatDemoAdulte etat) => switch (etat) {
    EtatDemoAdulte.delai60 ||
    EtatDemoAdulte.delai120 ||
    EtatDemoAdulte.departsSuivants => finDelai,
    _ => null,
  };

  /// Le prenom de la personne qui regarde.
  static String prenomVue(GenreTitulaireDemo genre, VueDemoAdulte vue) =>
      vue == VueDemoAdulte.titulaire
      ? prenomTitulaire(genre)
      : prenomSecondAdulte(genre);

  /// « Mon parcours », tel que le serveur le rendrait : le cours, le niveau
  /// et le chapitre de la Classe An-Nour de la demonstration de Classe.
  static String get ligneParcours => <String>[
    DonneesClasseDemo.cours,
    DonneesClasseDemo.niveau,
    DonneesClasseDemo.progression.chapitre,
  ].join(' · ');

  /// Les trois dernieres seances de la Classe An-Nour, les plus recentes
  /// d'abord, a l'heure de la demonstration de Classe (lundi, 18:00, 45 min).
  /// Une seule absence, pour montrer sa pastille.
  static List<SeancePasseeAdulte> dernieresSeances() => <SeancePasseeAdulte>[
    for (final (int i, (int jour, String date, bool absence))
        in <(int, String, bool)>[
          (21, 'Lundi 21 septembre', false),
          (14, 'Lundi 14 septembre', true),
          (7, 'Lundi 7 septembre', false),
        ].indexed)
      SeancePasseeAdulte(
        dateRendue: date,
        absence: absence,
        seance: Seance(
          id: 'demo-seance-passee-$i',
          debut: DateTime(2026, 9, jour, 18),
          fin: DateTime(2026, 9, jour, 18, 45),
          statut: null,
          eleveId: '',
          elevePrenom: DonneesClasseDemo.classe,
          eleveIdentifiant: LibellesGroupe.enseignantNomme(
            DonneesClasseDemo.enseignant,
          ),
          enseignantId: DonneesClasseDemo.enseignant.enseignantId,
          enseignantPrenom: DonneesClasseDemo.enseignant.nomAffichage,
          enseignantIdentifiant: '',
        ),
      ),
  ];

  /// L'accueil de la personne qui regarde.
  static AccueilAdulteVM accueil(GenreTitulaireDemo genre, VueDemoAdulte vue) =>
      AccueilAdulteVM(
        prenom: prenomVue(genre, vue),
        groupeId: DonneesClasseDemo.groupeId,
        ligneParcours: ligneParcours,
        dernieresSeances: dernieresSeances(),
      );

  /// La ligne famille de Mon espace pour cet etat et cette vue.
  static LigneFamilleDemo ligneFamille(EtatDemoAdulte etat, VueDemoAdulte vue) {
    if (!aUnFoyer(etat)) return LigneFamilleDemo.ajouterMaFamille;
    if (vue == VueDemoAdulte.secondAdulte && secondAdultePresent(etat)) {
      return LigneFamilleDemo.forfaitFamille;
    }
    return LigneFamilleDemo.maFamille;
  }
}
