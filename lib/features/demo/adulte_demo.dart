// Donnees de demonstration de l'eleve adulte (EA-1b) : le foyer Diallo de
// 16_eleves_adultes/V/00_MAQUETTES section 3, ses variantes (titulaire femme,
// vue du second adulte) et un etat nomme pour chacun des 25 cas du doc
// section 18. Aucune valeur economique : ni solde, ni offre, ni remise, ni
// taux (F12). Les dates de fin de delai sont des DONNEES, jamais un calcul
// (F17). Aucun appel serveur (K-28) : chaque besoin est une ligne d'EA-BR.md.

import '../../core/appairage/service_appairage.dart' show EleveDuFoyer;
import '../../core/capacites/port_identite_titulaire.dart';
import '../../core/domain/enums.dart';
import '../../core/planning/service_planning.dart' show Seance;
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../accueil_adulte/accueil_adulte_page.dart';
import '../foyer/place_adulte.dart';
import '../ma_classe_adulte/ma_classe_adulte_page.dart';
import '../mon_espace_adulte/mon_espace_adulte_page.dart';
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

/// La ligne famille unique de Mon espace (UX_REVIEW_07 ligne 5 a) : celle de
/// la vraie page (EA-4), sous son nom du socle EA-1b.
typedef LigneFamilleDemo = LigneFamilleAdulte;

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

  /// Le prenom du titulaire selon la variante.
  static String prenomTitulaire(GenreTitulaireDemo genre) =>
      genre == GenreTitulaireDemo.homme ? 'Mamadou' : 'Mariama';

  /// Le prenom du second adulte selon la variante.
  static String prenomSecondAdulte(GenreTitulaireDemo genre) =>
      genre == GenreTitulaireDemo.homme ? 'Mariama' : 'Mamadou';

  /// Les enfants du foyer, tels que le Foyer du tuteur les lit. Aucune
  /// echeance d'acces : le cas ordinaire (`finAcces` nul), jamais une date
  /// sentinelle.
  static const List<EleveDuFoyer> enfants = <EleveDuFoyer>[
    EleveDuFoyer(
      id: aichaId,
      prenom: 'Aïcha',
      identifiantImmuable: 'DEMO-D1',
      mode: InterfaceMode.enfant,
      camera: CameraPolicy.forbidden,
    ),
    EleveDuFoyer(
      id: oumarId,
      prenom: 'Oumar',
      identifiantImmuable: 'DEMO-D2',
      mode: InterfaceMode.enfant,
      camera: CameraPolicy.forbidden,
    ),
  ];

  /// Vrai si, dans cet etat, le titulaire a un foyer. Seul l'adulte seul n'en
  /// a pas. Dans le cas 21 (l'adulte invite est deja dans un autre foyer), le
  /// titulaire qui a invite garde son foyer et ses enfants (revue d'EA-4c) :
  /// c'est l'invite qui ne peut pas le rejoindre (doc section 11).
  static bool aUnFoyer(EtatDemoAdulte etat) =>
      etat != EtatDemoAdulte.adulteSeul;

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

  /// La date de fin du delai en cours, rendue telle quelle, ou nulle. Un
  /// depart (quitte, retire, second depart) ouvre deja un delai (doc
  /// section 10) : la meme date de demonstration.
  static DateTime? finDelaiPour(EtatDemoAdulte etat) => switch (etat) {
    EtatDemoAdulte.conjointQuitte ||
    EtatDemoAdulte.conjointRetire ||
    EtatDemoAdulte.secondDepart ||
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

  /// L'accueil de la personne qui regarde, ou `null` quand la demonstration
  /// n'a pas sa Classe.
  ///
  /// Le second adulte est eleve d'une AUTRE Classe (EA-BR-13) : comme pour Ma
  /// classe, son accueil garde le fournisseur reel (indisponible) plutot que
  /// de montrer la Classe An-Nour du titulaire (EA-5, report d'EA-2).
  static AccueilAdulteVM? accueil(
    GenreTitulaireDemo genre,
    VueDemoAdulte vue,
  ) => vue == VueDemoAdulte.secondAdulte
      ? null
      : AccueilAdulteVM(
          prenom: prenomVue(genre, vue),
          groupeId: DonneesClasseDemo.groupeId,
          ligneParcours: ligneParcours,
          dernieresSeances: dernieresSeances(),
        );

  /// Les enfants que Ma famille montre : aucun sans foyer.
  static List<EleveDuFoyer> enfantsPour(EtatDemoAdulte etat) =>
      aUnFoyer(etat) ? enfants : const <EleveDuFoyer>[];

  /// L'etat de la place adulte vu par le titulaire (F21, EA-5, EA-BR-14).
  /// Une invitation expiree ou annulee rend la place libre, sans delai (F5).
  static EtatPlaceAdulte place(EtatDemoAdulte etat, GenreTitulaireDemo genre) {
    final DateTime? fin = finDelaiPour(etat);
    if (fin != null) return DelaiEnCours(fin);
    if (secondAdultePresent(etat)) {
      return PlaceOccupee(prenomSecondAdulte(genre));
    }
    return switch (etat) {
      // Cas 21 : la reponse a l'invitation reste neutre pour le titulaire
      // (F4) ; il ne sait pas que l'invite est deja ailleurs, sa place dit
      // l'invitation envoyee (EA-BR-17).
      EtatDemoAdulte.invitationEnAttente ||
      EtatDemoAdulte.dejaDansUnAutreFoyer => invitationEnvoyee(genre),
      EtatDemoAdulte.invitationExpiree => const PlaceDisponible(
        precedente: FinInvitation.expiree,
      ),
      // Reponse tardive apres annulation (doc section 5.2, EA-6c) : la
      // demonstration fait arriver l'acceptation de l'invitee APRES
      // l'annulation ; le serveur de demonstration ne rattache personne.
      EtatDemoAdulte.invitationAnnulee => acceptationRecue(
        const PlaceDisponible(precedente: FinInvitation.annulee),
        prenomSecondAdulte(genre),
      ),
      EtatDemoAdulte.validationEnAttente => const ValidationEnAttente(),
      EtatDemoAdulte.validationRefusee => const ValidationRefusee(),
      _ => const PlaceDisponible(),
    };
  }

  /// Le serveur de demonstration recoit l'acceptation de [prenom] (EA-BR-15) :
  /// seule une invitation encore envoyee rattache le second adulte ; une
  /// acceptation qui arrive apres l'annulation ou l'expiration (reponse
  /// tardive, doc section 5.2) ne rattache personne et la place reste telle
  /// quelle (EA-6c).
  static EtatPlaceAdulte acceptationRecue(
    EtatPlaceAdulte place,
    String prenom,
  ) => place is InvitationEnvoyee ? PlaceOccupee(prenom) : place;

  /// L'invitation envoyee au second adulte (EA-6, EA-BR-15) : le prenom et
  /// l'adresse fictive (RFC 2606) que le titulaire a saisis.
  static InvitationEnvoyee invitationEnvoyee(GenreTitulaireDemo genre) =>
      InvitationEnvoyee(
        prenom: prenomSecondAdulte(genre),
        courriel:
            '${prenomSecondAdulte(genre).toLowerCase()}.diallo@example.com',
      );

  /// Ma famille du titulaire (EA-5) : la place adulte selon son genre (F3),
  /// sans photo livree (initiales en repli, E5).
  static FoyerTitulaireVM foyerTitulaire(
    EtatDemoAdulte etat,
    GenreTitulaireDemo genre,
  ) => FoyerTitulaireVM(
    placeFeminine: genre == GenreTitulaireDemo.homme,
    place: place(etat, genre),
  );

  /// « A propos de cette classe », tel que le serveur le rendrait.
  static const String aProposClasse =
      'Lecture du Coran avec application des règles de tajwid.';

  /// La page de reprise du titulaire dans la Classe An-Nour, une donnee
  /// rendue telle quelle : la sienne, jamais celle d'un autre eleve.
  static const String pageRepriseTitulaire = 'Page 24';

  /// La progression du titulaire dans la Classe An-Nour, une ligne rendue :
  /// le chapitre de la demonstration de Classe et sa page de reprise.
  static String get ligneProgressionClasse =>
      '${DonneesClasseDemo.progression.chapitre} · $pageRepriseTitulaire';

  /// L'identifiant du titulaire selon la variante.
  static String idTitulaire(GenreTitulaireDemo genre) =>
      genre == GenreTitulaireDemo.homme ? mamadouId : mariamaId;

  /// Ma classe de la personne qui regarde, ou `null` quand la demonstration
  /// n'a pas sa Classe.
  ///
  /// Le titulaire est eleve de la Classe An-Nour : ses participants sont
  /// autant que l'effectif que le groupe rend (`DonneesClasseDemo.groupe`),
  /// lui d'abord, puis les premiers eleves de la demonstration de Classe. La
  /// liste est la meme quelle que soit la vue, puisqu'elle n'est rendue qu'a
  /// lui.
  ///
  /// Le second adulte est eleve d'une AUTRE Classe, dont le titulaire ne voit
  /// pas le nom (00_MAQUETTES section 3) : la demonstration n'en a aucune,
  /// donc `null`, et la page garde son fournisseur reel (indisponible), plutot
  /// que de le placer dans An-Nour. Aucune photo livree : les initiales en
  /// repli (E5).
  static MaClasseAdulteVM? maClasse(
    GenreTitulaireDemo genre,
    VueDemoAdulte vue,
  ) => vue == VueDemoAdulte.secondAdulte
      ? null
      : MaClasseAdulteVM(
          groupeId: DonneesClasseDemo.groupeId,
          aPropos: aProposClasse,
          ligneProgression: ligneProgressionClasse,
          participants: <ParticipantClasseAdulte>[
            ParticipantClasseAdulte(
              id: idTitulaire(genre),
              prenom: prenomTitulaire(genre),
              estMoi: true,
            ),
            for (final (int i, EleveProjectionDemo e)
                in DonneesClasseDemo.eleves
                    .take(DonneesClasseDemo.eleves.length - 1)
                    .indexed)
              ParticipantClasseAdulte(id: 'demo-eleve-$i', prenom: e.prenom),
          ],
        );

  /// Le nom de famille du foyer, porte par les deux adultes. 00_MAQUETTES
  /// section 3 nomme le foyer Diallo sans donner le nom de la conjointe : le
  /// lui donner aussi est un CHOIX DE DEMONSTRATION, note dans cette section.
  static const String nomFamille = 'Diallo';

  /// L'adresse de connexion fictive de la personne qui regarde, sur le
  /// domaine reserve aux exemples (RFC 2606) : jamais une vraie adresse.
  static String courrielVue(GenreTitulaireDemo genre, VueDemoAdulte vue) =>
      '${prenomVue(genre, vue).toLowerCase()}.diallo@example.com';

  /// L'identite de la personne qui regarde, telle que le port du Compte la
  /// rendrait (`identiteTitulaireProvider`, EA-4).
  static IdentiteTitulaire identite(
    GenreTitulaireDemo genre,
    VueDemoAdulte vue,
  ) => IdentiteTitulaire(
    prenom: prenomVue(genre, vue),
    nom: nomFamille,
    courriel: courrielVue(genre, vue),
    methodeConnexion: MethodeConnexion.lienCourriel,
    statut: AccountStatus.active,
  );

  /// Mon espace de la personne qui regarde (EA-4) : sa ligne famille, sans
  /// photo livree (initiales en repli, E5).
  static MonEspaceAdulteVM monEspace(
    EtatDemoAdulte etat,
    GenreTitulaireDemo genre,
    VueDemoAdulte vue,
  ) => MonEspaceAdulteVM(ligneFamille: ligneFamille(etat, vue));

  /// La ligne famille de Mon espace pour cet etat et cette vue, ou `null`
  /// pour aucune ligne.
  ///
  /// EA-4c (revue du 27/09, F6, F7) : « Ma famille », qui ouvre le Foyer du
  /// titulaire et ses enfants, n'est rendue QU'AU titulaire. Le second adulte
  /// rattache voit « Forfait famille », son espace, jamais les enfants. Le
  /// second adulte qui n'est pas (ou plus) rattache (invitation pas encore
  /// acceptee, depart, retrait, delai, validation en attente ou refusee) est
  /// un adulte autonome (spec sections 4 et 7.1) : « Ajouter ma famille ».
  /// Celui qui appartient deja a un autre foyer (section 11) n'a ici aucune
  /// ligne : la demonstration n'a pas cet autre foyer, rien n'est invente.
  ///
  /// Revue d'EA-4c, aucune ligne non plus pour le second adulte :
  /// - pendant la validation administrative, en attente ou refusee : il a
  ///   deja accepte l'invitation (section 10.4) ; lui proposer de creer une
  ///   famille pousserait a une double appartenance (section 11) ;
  /// - apres une reprise validee : il devient titulaire du foyer (section
  ///   12.6), pas un adulte a qui proposer une famille (un seul forfait
  ///   actif, section 11). La demonstration ne modelise pas la succession :
  ///   aucune ligne plutot qu'une ligne fausse.
  /// CHOIX PROVISOIRE, jusqu'a ce que le serveur rende la ligne de ces
  /// situations (EA-BR-17).
  static LigneFamilleDemo? ligneFamille(
    EtatDemoAdulte etat,
    VueDemoAdulte vue,
  ) {
    if (vue == VueDemoAdulte.titulaire) {
      return aUnFoyer(etat)
          ? LigneFamilleDemo.maFamille
          : LigneFamilleDemo.ajouterMaFamille;
    }
    if (secondAdultePresent(etat)) return LigneFamilleDemo.forfaitFamille;
    return switch (etat) {
      EtatDemoAdulte.dejaDansUnAutreFoyer ||
      EtatDemoAdulte.validationEnAttente ||
      EtatDemoAdulte.validationRefusee ||
      EtatDemoAdulte.repriseValidee => null,
      _ => LigneFamilleDemo.ajouterMaFamille,
    };
  }
}
