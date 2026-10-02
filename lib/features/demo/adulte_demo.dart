// Donnees de demonstration de l'eleve adulte (EA-1b) : le foyer Diallo de
// 16_eleves_adultes/V/00_MAQUETTES section 3, ses variantes (titulaire femme,
// vue du second adulte) et un etat nomme pour chacun des 25 cas du doc
// section 18. Aucune valeur economique calculee par l'ecran : ni taux, ni
// remise (F12) ; les soldes (EA-9) sont des libelles de demonstration rendus
// tels quels (decision E2), les offres et le recapitulatif de la recharge
// (EA-10) aussi, arretes par le serveur de demonstration. Les dates de fin de delai sont des DONNEES,
// jamais un calcul (F17). Aucun appel serveur (K-28) : chaque besoin est
// une ligne d'EA-BR.md.

import '../../core/appairage/service_appairage.dart' show EleveDuFoyer;
import '../../core/capacites/port_identite_titulaire.dart';
import '../../core/capacites/port_paiements_foyer.dart';
import '../../core/capacites/port_recharge_foyer.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/planning/service_planning.dart' show Seance;
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../accueil_adulte/accueil_adulte_page.dart';
import '../foyer/invitation_conjoint.dart';
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

  /// La date de l'invitation recue par le second adulte (EA-7), une donnee
  /// de demonstration rendue telle quelle.
  static final DateTime dateInvitation = DateTime.utc(2026, 9, 26, 16);

  /// L'invitation que le second adulte lit dans son propre compte (EA-7,
  /// EA-BR-20), ou `null` quand cette situation n'en a pas.
  ///
  /// - en attente : a repondre ; annulee : la page lue AVANT l'annulation,
  ///   l'acceptation arrive trop tard (reponse tardive, doc section 5.2) ;
  ///   erreur reseau et double envoi : la reponse elle-meme ;
  /// - nouvelle demande apres le delai : un remplacement, le texte T2 ;
  /// - deja dans un autre foyer : la forme neutre (F4, doc section 11) ;
  /// - expiree : plus valable ;
  /// - validation en attente : deja acceptee, l'attente seule (section 10.4).
  static EtatInvitationRecue? invitationRecue(
    EtatDemoAdulte etat,
    GenreTitulaireDemo genre,
  ) {
    InvitationARepondre aRepondre({bool validation = false}) =>
        InvitationARepondre(
          prenomTitulaire: prenomTitulaire(genre),
          titulaireFeminin: genre == GenreTitulaireDemo.femme,
          validationRequise: validation,
        );
    return switch (etat) {
      EtatDemoAdulte.invitationEnAttente ||
      EtatDemoAdulte.invitationAnnulee ||
      EtatDemoAdulte.erreurReseau ||
      EtatDemoAdulte.doubleSoumission => aRepondre(),
      EtatDemoAdulte.nouvelleDemande => aRepondre(validation: true),
      EtatDemoAdulte.dejaDansUnAutreFoyer => const InvitationNonAcceptable(),
      EtatDemoAdulte.invitationExpiree => const InvitationPerimee(),
      EtatDemoAdulte.validationEnAttente => const InvitationEnValidation(),
      _ => null,
    };
  }

  /// Ce que le serveur de demonstration rend a une acceptation (EA-BR-20) :
  /// l'attente de validation pour un remplacement, rien pour une invitation
  /// annulee entre-temps (personne n'est rattache), la forme neutre pour un
  /// compte deja ailleurs, sinon le rattachement.
  static EtatInvitationRecue acceptationDe(
    EtatDemoAdulte etat,
    GenreTitulaireDemo genre,
  ) => switch (etat) {
    EtatDemoAdulte.nouvelleDemande => const InvitationEnValidation(),
    EtatDemoAdulte.invitationAnnulee => const InvitationPerimee(),
    EtatDemoAdulte.dejaDansUnAutreFoyer => const InvitationNonAcceptable(),
    _ => InvitationAcceptee(prenomTitulaire(genre)),
  };

  /// La situation que Mon espace (et toute page rouverte ensuite) lit apres
  /// la reponse, jamais l'invitation « a repondre » d'avant (revue EA-7) :
  /// - acceptee : le second adulte rattache ; remplacement : en attente de
  ///   validation ;
  /// - refusee : l'invitation n'existe plus, la place du titulaire est libre
  ///   (« Le foyer n'a pas de second adulte ») ;
  /// - reponse tardive : l'invitation n'est plus valable, comme une
  ///   invitation expiree (la demonstration n'a qu'une situation qui la
  ///   rende ainsi au second adulte) ;
  /// - forme neutre : rien ne change.
  static EtatDemoAdulte apresReponse(
    EtatDemoAdulte etat,
    EtatInvitationRecue suite,
  ) => switch (suite) {
    InvitationAcceptee() => EtatDemoAdulte.conjointActif,
    InvitationEnValidation() => EtatDemoAdulte.validationEnAttente,
    InvitationRefuseeParVous() => EtatDemoAdulte.titulaireSansConjoint,
    InvitationPerimee() => EtatDemoAdulte.invitationExpiree,
    _ => etat,
  };

  /// La date de la notification d'un depart (EA-8), une donnee de
  /// demonstration rendue telle quelle.
  static final DateTime dateDepart = DateTime.utc(2026, 9, 28, 9);

  /// La notification d'un depart, visible dans le centre de notifications de
  /// l'AUTRE adulte (F16, doc section 9.3, EA-BR-21), ou `null` :
  /// - le second adulte a quitte : le titulaire en est informe ;
  /// - le titulaire l'a retire : le second adulte en est informe, accorde a
  ///   son genre (« retiree », « retire »).
  /// Celui qui agit lit le resultat de son geste, pas une notification.
  static String? notificationDepart(
    EtatDemoAdulte etat,
    GenreTitulaireDemo genre,
    VueDemoAdulte vue,
  ) => switch ((etat, vue)) {
    (EtatDemoAdulte.conjointQuitte, VueDemoAdulte.titulaire) =>
      t.adulte.sortie.notificationQuitte(prenom: prenomSecondAdulte(genre)),
    (EtatDemoAdulte.conjointRetire, VueDemoAdulte.secondAdulte) =>
      genre == GenreTitulaireDemo.homme
          ? t.adulte.sortie.notificationRetiree(prenom: prenomTitulaire(genre))
          : t.adulte.sortie.notificationRetire(prenom: prenomTitulaire(genre)),
    _ => null,
  };

  /// La page Forfait famille du second adulte rattache (EA-8, EA-BR-22).
  static ForfaitFamilleVM forfaitFamille(GenreTitulaireDemo genre) =>
      ForfaitFamilleVM(prenomTitulaire: prenomTitulaire(genre));

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

  /// Les soldes du foyer vus par le titulaire (EA-9, EA-BR-23), tels que le
  /// serveur de demonstration les rendrait : le titulaire, le second adulte
  /// seulement s'il est rattache (ses initiales, aucune photo ni Classe, Q4,
  /// F6), puis les enfants.
  ///
  /// Les libelles reprennent les valeurs de la planche 4.1 (« 120 unités »),
  /// sans taux ni devise (decision E2, Q9) ; l'exception « Bientôt épuisé »
  /// est RENDUE par la demonstration, jamais deduite d'un seuil (F12). Le
  /// recapitulatif est une phrase rendue, ecrite ici pour chaque cas, jamais
  /// additionnee dans Flutter (F9). Oumar n'a pas la pastille « Inactif » de
  /// la planche : son acces, dans Ma famille, est sans echeance, et la
  /// demonstration ne se contredit pas d'un ecran a l'autre.
  static SoldesFoyer soldes(EtatDemoAdulte etat, GenreTitulaireDemo genre) {
    final bool second = secondAdultePresent(etat);
    return SoldesFoyer(
      beneficiaires: <SoldeBeneficiaire>[
        SoldeBeneficiaire(
          id: idTitulaire(genre),
          prenom: prenomTitulaire(genre),
          soldeRendu: '120 unités',
        ),
        if (second)
          SoldeBeneficiaire(
            id: genre == GenreTitulaireDemo.homme ? mariamaId : mamadouId,
            prenom: prenomSecondAdulte(genre),
            soldeRendu: '80 unités',
          ),
        const SoldeBeneficiaire(
          id: aichaId,
          prenom: 'Aïcha',
          soldeRendu: '15 unités',
          exception: ExceptionSolde.bientotEpuise,
        ),
        const SoldeBeneficiaire(
          id: oumarId,
          prenom: 'Oumar',
          soldeRendu: '0 unité',
        ),
      ],
      recapitulatif: second ? '215 unités au total' : '135 unités au total',
    );
  }

  /// L'identifiant de l'offre A de la demonstration.
  static const String offreA = 'demo-offre-a';

  /// L'identifiant de l'offre B de la demonstration.
  static const String offreB = 'demo-offre-b';

  /// Les offres de recharge de la demonstration (EA-10, EA-BR-24). Le prix
  /// reprend la planche 4.3 (« 5,00 € ») ; le solde attribue est un libelle
  /// de demonstration MARQUE comme tel, sans quantite d'unites : l'unite du
  /// solde n'est pas fixee (doc section 20.3, 00_MAQUETTES 4.1 C3) et une
  /// quantite a cote d'un prix ramenerait le taux retire (4.2 C2, E2). Ni
  /// taux ni formule (F12, 00_MAQUETTES section 3). Aucune remise n'est
  /// rendue : la planche la calcule (10 %), le doc ne la fixe pas (section 20).
  static const List<OffreRecharge> _offresRecharge = <OffreRecharge>[
    OffreRecharge(
      id: offreA,
      libelle: '5,00 €',
      detail: 'Solde de démonstration A',
    ),
    OffreRecharge(
      id: offreB,
      libelle: '10,00 €',
      detail: 'Solde de démonstration B',
    ),
  ];

  /// Le total que le serveur de demonstration arrete, une DONNEE fixee
  /// d'avance pour chaque combinaison possible (le nombre d'offres A et B
  /// choisies, quatre beneficiaires au plus), jamais une addition.
  static String _totalRecharge(int a, int b) => switch ((a, b)) {
    (1, 0) => '5,00 €',
    (0, 1) || (2, 0) => '10,00 €',
    (1, 1) || (3, 0) => '15,00 €',
    (0, 2) || (2, 1) || (4, 0) => '20,00 €',
    (1, 2) || (3, 1) => '25,00 €',
    (0, 3) || (2, 2) => '30,00 €',
    (1, 3) => '35,00 €',
    (0, 4) => '40,00 €',
    _ => throw StateError('combinaison absente de la demonstration'),
  };

  /// Le statut de l'attribution avant le paiement, tel que le serveur de
  /// demonstration le rend (F11).
  static const String statutAvantPaiement = 'En attente du paiement';

  /// Les beneficiaires de la recharge (EA-10, EA-BR-24) : ceux des soldes
  /// (EA-9), dans le meme ordre, chacun avec les offres que le serveur rend
  /// pour lui.
  static List<BeneficiaireRecharge> beneficiairesRecharge(
    EtatDemoAdulte etat,
    GenreTitulaireDemo genre,
  ) => <BeneficiaireRecharge>[
    for (final SoldeBeneficiaire s in soldes(etat, genre).beneficiaires)
      BeneficiaireRecharge(
        id: s.id,
        prenom: s.prenom,
        cleAvatar: s.cleAvatar,
        soldeRendu: s.soldeRendu,
        offres: _offresRecharge,
      ),
  ];

  /// Le recapitulatif que le SERVEUR de demonstration arrete pour ces choix
  /// (EA-10, EA-BR-24) : une ligne par beneficiaire choisi, dans l'ordre des
  /// beneficiaires, et le total. Le total est une donnee fixee d'avance par
  /// le serveur de demonstration ; l'ecran l'affiche tel quel, il
  /// n'additionne jamais rien (F12).
  static RecapitulatifRecharge recapitulatifRecharge(
    EtatDemoAdulte etat,
    GenreTitulaireDemo genre,
    List<ChoixRecharge> choix,
  ) {
    final Map<String, String> offreDe = <String, String>{
      for (final ChoixRecharge c in choix) c.beneficiaireId: c.offreId,
    };
    final Map<String, OffreRecharge> offreParId = <String, OffreRecharge>{
      for (final OffreRecharge o in _offresRecharge) o.id: o,
    };
    final List<LigneRecapitulatif> lignes = <LigneRecapitulatif>[
      for (final BeneficiaireRecharge b in beneficiairesRecharge(etat, genre))
        if (offreDe[b.id] case final String offreId)
          if (offreParId[offreId] case final OffreRecharge o)
            LigneRecapitulatif(
              beneficiaireId: b.id,
              prenom: b.prenom,
              cleAvatar: b.cleAvatar,
              montantPaye: o.libelle,
              soldeAttribue: o.detail ?? '',
              statut: statutAvantPaiement,
            ),
    ];
    final Iterable<String> offres = offreDe.values;
    return RecapitulatifRecharge(
      id: 'demo-recapitulatif',
      lignes: lignes,
      total: _totalRecharge(
        offres.where((String o) => o == offreA).length,
        offres.where((String o) => o == offreB).length,
      ),
    );
  }

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
