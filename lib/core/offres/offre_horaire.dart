import 'package:flutter/foundation.dart';

/// Le public d'une offre ou d'un groupe.
///
/// Miroir de `offres_horaires.type_public` et de [TypePublicGroupe]. La
/// capacite ne s'en deduit **jamais** ici : elle vient de [ReglesAcademie],
/// qui la lit dans `app_config`. Un nombre ecrit dans ce fichier serait une
/// regle de l'academie recopiee dans le client, donc une regle qui divergerait
/// au premier changement.
enum PublicOffre {
  /// Enfants.
  enfants('enfant'),

  /// Adultes.
  adultes('adulte');

  const PublicOffre(this.valeurSql);

  /// La valeur telle que la base la connait.
  final String valeurSql;

  /// Lit un public depuis sa valeur SQL. Se replie sur [enfants], le public
  /// dont la capacite est la plus basse : un public mal lu ne doit jamais
  /// laisser entrer plus de monde que prevu.
  static PublicOffre depuisSql(String? valeur) =>
      valeur == 'adulte' ? PublicOffre.adultes : PublicOffre.enfants;
}

/// Le niveau que la famille declare elle-meme, avant tout diagnostic.
///
/// **Ce n'est pas le niveau officiel.** Le niveau officiel vit dans
/// `student_profiles.level`, il est attribue par l'academie apres diagnostic,
/// et le client n'a aucun droit d'ecriture dessus. Les deux sont deux colonnes
/// distinctes en base, ce qui rend l'erreur impossible plutot que deconseillee.
///
/// Les valeurs sont des codes serveur ; les libelles sont des cles i18n. Aucune
/// reponse visible ne s'appelle `F1`, `F2` ni `F3` : un code de referentiel
/// n'est pas une phrase qu'on montre a un parent.
enum NiveauDeclare {
  /// Je debute avec les lettres.
  debutLettres('debut_lettres'),

  /// Je reconnais les lettres, j'ai besoin d'aide.
  lettresAvecAide('lettres_avec_aide'),

  /// Je peux lire lentement.
  lectureLente('lecture_lente'),

  /// Je lis deja le Coran.
  lectureCourante('lecture_courante'),

  /// J'ai deja memorise une partie.
  memorisationPartielle('memorisation_partielle');

  const NiveauDeclare(this.valeurSql);

  /// La valeur telle que la base l'attend.
  final String valeurSql;

  /// Lit un niveau declare, ou `null` si la valeur est inconnue.
  static NiveauDeclare? depuisSql(String? valeur) => NiveauDeclare.values
      .where((NiveauDeclare n) => n.valeurSql == valeur)
      .firstOrNull;
}

/// Ce que la famille vient chercher.
enum ObjectifApprentissage {
  /// Apprendre a lire.
  apprendreALire('apprendre_a_lire'),

  /// Devenir plus fluide.
  devenirFluide('devenir_fluide'),

  /// Memoriser.
  memoriser('memoriser'),

  /// Je ne sais pas encore. **Une reponse legitime, pas un refus** : un parent
  /// qui decouvre l'academie n'a pas a inventer un objectif pour avancer.
  indecis('indecis');

  const ObjectifApprentissage(this.valeurSql);

  /// La valeur telle que la base l'attend.
  final String valeurSql;

  /// Lit un objectif, ou `null` si la valeur est inconnue.
  static ObjectifApprentissage? depuisSql(String? valeur) =>
      ObjectifApprentissage.values
          .where((ObjectifApprentissage o) => o.valeurSql == valeur)
          .firstOrNull;
}

/// Ou en est le diagnostic academique d'un apprenant.
///
/// L'ecran doit distinguer ces etats de l'etat de l'intention : une preference
/// horaire enregistree et un diagnostic fait sont deux choses, et c'est
/// precisement la confusion des deux qui ferait croire a une place reservee.
enum StatutDiagnostic {
  /// Aucun diagnostic n'est attendu pour cet apprenant.
  nonRequis('non_requis'),

  /// A faire. C'est le defaut.
  aPlanifier('a_planifier'),

  /// Un rendez-vous existe.
  planifie('planifie'),

  /// Fait. Le niveau officiel peut alors etre attribue.
  fait('fait');

  const StatutDiagnostic(this.valeurSql);

  /// La valeur telle que la base l'attend.
  final String valeurSql;

  /// Lit un statut. Se replie sur [aPlanifier] : un statut illisible doit
  /// laisser croire qu'il reste du travail, jamais qu'il n'y en a plus.
  static StatutDiagnostic depuisSql(String? valeur) =>
      StatutDiagnostic.values
          .where((StatutDiagnostic s) => s.valeurSql == valeur)
          .firstOrNull ??
      StatutDiagnostic.aPlanifier;
}

/// Ou en est la preference horaire d'un apprenant.
enum EtatIntention {
  /// Enregistree. **Aucun groupe, aucun enseignant, aucune place.**
  enregistree('enregistree'),

  /// Un diagnostic est pose au calendrier.
  diagnosticPlanifie('diagnostic_planifie'),

  /// Le vivier n'atteint pas encore le minimum de lancement.
  enFormation('en_formation'),

  /// Un vrai groupe existe et cet apprenant y est.
  affectee('affectee'),

  /// La famille a renonce.
  retiree('retiree');

  const EtatIntention(this.valeurSql);

  /// La valeur telle que la base l'attend.
  final String valeurSql;

  /// Lit un etat, ou `null` quand il n'y a pas d'intention.
  static EtatIntention? depuisSql(String? valeur) => EtatIntention.values
      .where((EtatIntention e) => e.valeurSql == valeur)
      .firstOrNull;
}

/// Une langue d'enseignement, telle que le serveur la publie.
///
/// **La langue du cours n'est pas la langue de l'interface.** ADR-015 a retire
/// le poular des locales de l'application, et cette decision tient. Le poular
/// est ici une langue d'ENSEIGNEMENT : une famille peut lire l'application en
/// francais et suivre son cours en poular (ADR-029).
@immutable
class LangueCours {
  /// Cree une langue.
  const LangueCours({required this.code, required this.nom});

  /// Lit une ligne de `langues_cours`.
  factory LangueCours.depuisJson(Map<String, dynamic> json) => LangueCours(
    code: json['code'] as String,
    nom: json['nom_humain'] as String? ?? '',
  );

  /// Le code serveur.
  final String code;

  /// Le nom tel qu'il s'affiche. Rendu par le serveur, jamais traduit : le nom
  /// d'une langue s'ecrit dans cette langue.
  final String nom;
}

/// Une tranche d'age, et ce qu'elle deduit.
///
/// L'onboarding demande une tranche, **jamais une date de naissance**. Sur un
/// telephone tenu d'une main, une reponse au doigt bat un clavier de date ; et
/// le produit n'a besoin de rien de plus precis, donc il ne collecte rien de
/// plus.
///
/// [typePublic] et les deductions serveur ne sont pas recalcules ici : ils
/// viennent de `cohortes_age`. Un client qui deciderait qui est mineur
/// pourrait se declarer adulte autonome.
@immutable
class CohorteAge {
  /// Cree une cohorte.
  const CohorteAge({
    required this.code,
    required this.nom,
    required this.typePublic,
  });

  /// Lit une ligne de `cohortes_age`.
  factory CohorteAge.depuisJson(Map<String, dynamic> json) => CohorteAge(
    code: json['code'] as String,
    nom: json['nom_humain'] as String? ?? '',
    typePublic: PublicOffre.depuisSql(json['type_public'] as String?),
  );

  /// Le code serveur.
  final String code;

  /// Le libelle affiche, rendu par le serveur.
  final String nom;

  /// Le public que cette tranche designe.
  final PublicOffre typePublic;
}

/// Les regles de l'academie que la vitrine doit connaitre.
///
/// Toutes viennent d'`app_config` par la RPC `regles_academie()`. **Aucune
/// n'est ecrite dans un widget** : le minimum de lancement, les capacites et
/// la pause changent par decision d'exploitation, pas par livraison.
@immutable
class ReglesAcademie {
  /// Cree un jeu de regles.
  const ReglesAcademie({
    required this.capaciteEnfant,
    required this.capaciteAdulte,
    required this.minimumLancement,
    required this.seancesParSemaine,
    required this.dureeMinutesEnfant,
    required this.dureeMinutesAdulte,
    required this.pauseMinutesEnfant,
    required this.pauseMinutesAdulte,
  });

  /// Lit le jsonb rendu par `regles_academie()`.
  factory ReglesAcademie.depuisJson(Map<String, dynamic> json) {
    int entier(String cle, int defaut) =>
        (json[cle] as num?)?.toInt() ?? defaut;

    return ReglesAcademie(
      capaciteEnfant: entier('capacite_enfant', 5),
      capaciteAdulte: entier('capacite_adulte', 6),
      minimumLancement: entier('minimum_lancement', 3),
      seancesParSemaine: entier('seances_par_semaine', 3),
      dureeMinutesEnfant: entier('duree_minutes_enfant', 60),
      dureeMinutesAdulte: entier('duree_minutes_adulte', 90),
      pauseMinutesEnfant: entier('pause_minutes_enfant', 6),
      pauseMinutesAdulte: entier('pause_minutes_adulte', 0),
    );
  }

  /// Nombre maximal d'enfants par groupe.
  final int capaciteEnfant;

  /// Nombre maximal d'adultes par groupe.
  final int capaciteAdulte;

  /// Nombre d'eleves a partir duquel un groupe se lance.
  final int minimumLancement;

  /// Nombre de seances hebdomadaires annoncees par une offre.
  final int seancesParSemaine;

  /// Duree d'une seance enfant, en minutes.
  final int dureeMinutesEnfant;

  /// Duree d'une seance adulte, en minutes.
  final int dureeMinutesAdulte;

  /// Pause centrale d'une seance enfant, en minutes.
  final int pauseMinutesEnfant;

  /// Pause centrale d'une seance adulte, en minutes.
  final int pauseMinutesAdulte;

  /// La capacite du public donne.
  int capacitePour(PublicOffre public) =>
      public == PublicOffre.adultes ? capaciteAdulte : capaciteEnfant;
}

/// Un creneau d'une offre, tel que l'utilisateur le voit.
///
/// **Un jour ET son heure**, parce que les deux peuvent differer d'un creneau a
/// l'autre de la meme offre. Une semaine de changement d'heure decale certains
/// jours et pas d'autres : une offre de 18:00 a Paris se lit 19:00 le lundi et
/// 20:00 le mercredi depuis un autre fuseau. Une heure unique pour toute
/// l'offre aurait donc menti un jour sur trois, deux fois par an.
@immutable
class CreneauVu {
  /// Cree un creneau vu.
  const CreneauVu({required this.jourIso, required this.heure})
    : assert(jourIso >= 1 && jourIso <= 7, 'un jour ISO va de 1 a 7'),
      assert(heure >= 0 && heure <= 23, 'une heure locale va de 0 a 23');

  /// Le jour ISO, 1 pour lundi, 7 pour dimanche.
  final int jourIso;

  /// L'heure locale pleine, dans le fuseau de l'utilisateur.
  final int heure;

  @override
  bool operator ==(Object other) =>
      other is CreneauVu && other.jourIso == jourIso && other.heure == heure;

  @override
  int get hashCode => Object.hash(jourIso, heure);
}

/// Une offre horaire vitrine.
///
/// **Ce que cette classe ne porte pas, et ne portera pas** : aucun enseignant,
/// aucun nombre d'inscrits, aucune place restante, aucun identifiant de groupe.
/// Ce ne sont pas des champs oublies. A ce stade aucun vrai groupe n'est
/// garanti, et les montrer serait une promesse que l'academie n'a pas faite.
/// La contrainte est tenue en base : `offres_horaires` n'a pas ces colonnes.
///
/// [id] existe parce qu'il faut bien poster un choix, et il ne s'affiche
/// jamais.
@immutable
class OffreHoraire {
  /// Cree une offre.
  const OffreHoraire({
    required this.id,
    required this.public,
    required this.langueCode,
    required this.langueNom,
    required this.creneaux,
    required this.heureSource,
    required this.fuseauSource,
    required this.dureeMinutes,
    required this.pauseMinutes,
    required this.capacite,
    required this.dejaChoisie,
  });

  /// Lit une ligne rendue par `offres_compatibles()`.
  factory OffreHoraire.depuisJson(Map<String, dynamic> json) {
    List<int> entiers(String cle) =>
        ((json[cle] as List<dynamic>?) ?? const <dynamic>[])
            .map((dynamic v) => (v as num).toInt())
            .toList(growable: false);

    final List<int> jours = entiers('jours_locaux');
    final List<int> heures = entiers('heures_locales');

    return OffreHoraire(
      id: json['offre_id'] as String,
      public: PublicOffre.depuisSql(json['type_public'] as String?),
      langueCode: json['langue_code'] as String? ?? '',
      langueNom: json['langue_nom'] as String? ?? '',
      creneaux: <CreneauVu>[
        for (int i = 0; i < jours.length; i++)
          CreneauVu(
            jourIso: jours[i],
            // Les deux tableaux sont paralleles cote serveur. Si l'un etait
            // plus court, mieux vaut retomber sur l'heure de reference que
            // lever : une offre affichee a la mauvaise heure se corrige, une
            // exception vide l'ecran.
            heure: i < heures.length
                ? heures[i]
                : (json['heure_source'] as num?)?.toInt() ?? 0,
          ),
      ],
      heureSource: (json['heure_source'] as num?)?.toInt() ?? 0,
      fuseauSource: json['fuseau_source'] as String? ?? '',
      dureeMinutes: (json['duree_minutes'] as num?)?.toInt() ?? 0,
      pauseMinutes: (json['pause_minutes'] as num?)?.toInt() ?? 0,
      capacite: (json['capacite'] as num?)?.toInt() ?? 0,
      dejaChoisie: json['deja_choisie'] as bool? ?? false,
    );
  }

  /// L'identifiant de l'offre. Jamais affiche.
  final String id;

  /// Le public de l'offre.
  final PublicOffre public;

  /// Le code de la langue d'enseignement.
  final String langueCode;

  /// Le nom affichable de la langue d'enseignement.
  final String langueNom;

  /// Les creneaux, dans le fuseau de l'utilisateur, dans l'ordre de l'offre.
  final List<CreneauVu> creneaux;

  /// L'heure de reference de l'offre, dans son fuseau d'origine.
  final int heureSource;

  /// Le fuseau de reference de l'offre.
  final String fuseauSource;

  /// La duree d'une seance, en minutes.
  final int dureeMinutes;

  /// La pause centrale, en minutes. Zero quand il n'y en a pas.
  final int pauseMinutes;

  /// La capacite du groupe qui naitra de cette offre.
  final int capacite;

  /// Vrai quand cet apprenant a deja choisi cette offre.
  final bool dejaChoisie;

  /// Vrai quand l'heure vue differe de l'heure de reference, c'est-a-dire
  /// quand l'utilisateur n'est pas dans le fuseau de l'offre. L'ecran s'en sert
  /// pour expliquer l'ecart plutot que de le laisser surprendre.
  bool get heureTraduite =>
      creneaux.any((CreneauVu c) => c.heure != heureSource);
}

/// Ou en est un apprenant du foyer dans son parcours.
///
/// Une ligne de `v_parcours_onboarding`. Deux champs sont **deduits** par la
/// vue et non stockes, parce que stockes ils deviendraient faux en silence :
/// [offreIndisponible] et [fuseauChange].
@immutable
class ParcoursApprenant {
  /// Cree un etat de parcours.
  const ParcoursApprenant({
    required this.eleveId,
    required this.prenom,
    required this.diagnostic,
    this.dateNaissance,
    this.cohorteCode,
    this.cohorteNom,
    this.public,
    this.langueCode,
    this.langueNom,
    this.niveauDeclare,
    this.objectif,
    this.placementBasis,
    this.onboardingFaitLe,
    this.fuseauFoyer,
    this.intentionEtat,
    this.offreId,
    this.fuseauAffiche,
    this.heureAffichee,
    this.joursAffiches = const <int>[],
    this.groupeId,
    this.offreIndisponible = false,
    this.fuseauChange = false,
  });

  /// Lit une ligne de `v_parcours_onboarding`.
  factory ParcoursApprenant.depuisJson(
    Map<String, dynamic> json,
  ) => ParcoursApprenant(
    eleveId: json['eleve_id'] as String,
    prenom: json['prenom'] as String? ?? '',
    diagnostic: StatutDiagnostic.depuisSql(
      json['diagnostic_statut'] as String?,
    ),
    dateNaissance: DateTime.tryParse(json['date_naissance'] as String? ?? ''),
    cohorteCode: json['cohorte'] as String?,
    cohorteNom: json['cohorte_nom'] as String?,
    public: json['type_public'] == null
        ? null
        : PublicOffre.depuisSql(json['type_public'] as String?),
    langueCode: json['langue_code'] as String?,
    langueNom: json['langue_nom'] as String?,
    niveauDeclare: NiveauDeclare.depuisSql(json['niveau_declare'] as String?),
    objectif: ObjectifApprentissage.depuisSql(json['objectif'] as String?),
    placementBasis: json['placement_basis'] as String?,
    onboardingFaitLe: DateTime.tryParse(
      json['onboarding_fait_le'] as String? ?? '',
    )?.toLocal(),
    fuseauFoyer: json['fuseau_foyer'] as String?,
    intentionEtat: EtatIntention.depuisSql(json['intention_etat'] as String?),
    offreId: json['offre_id'] as String?,
    fuseauAffiche: json['fuseau_affiche'] as String?,
    heureAffichee: (json['heure_affichee'] as num?)?.toInt(),
    joursAffiches:
        ((json['jours_affiches'] as List<dynamic>?) ?? const <dynamic>[])
            .map((dynamic v) => (v as num).toInt())
            .toList(growable: false),
    groupeId: json['groupe_id'] as String?,
    offreIndisponible: json['offre_indisponible'] as bool? ?? false,
    fuseauChange: json['fuseau_change'] as bool? ?? false,
  );

  /// L'identifiant du profil de l'apprenant.
  final String eleveId;

  /// Son prenom.
  final String prenom;

  /// Date de naissance confiee par le tuteur, source serveur du calcul d'age.
  /// Elle n'est jamais saisie par le profil eleve lui-meme.
  final DateTime? dateNaissance;

  /// Ou en est son diagnostic academique.
  final StatutDiagnostic diagnostic;

  /// Le code de sa cohorte, nul avant l'onboarding.
  final String? cohorteCode;

  /// Le libelle de sa cohorte.
  final String? cohorteNom;

  /// Son public, deduit de la cohorte par le serveur.
  final PublicOffre? public;

  /// Le code de sa langue de cours.
  final String? langueCode;

  /// Le nom de sa langue de cours.
  final String? langueNom;

  /// Son niveau auto-declare. **Jamais son niveau officiel.**
  final NiveauDeclare? niveauDeclare;

  /// Son objectif.
  final ObjectifApprentissage? objectif;

  /// Base explicable du placement initial, jamais un faux diagnostic termine.
  final String? placementBasis;

  /// Quand l'onboarding a ete rempli.
  final DateTime? onboardingFaitLe;

  /// Le fuseau courant du foyer.
  final String? fuseauFoyer;

  /// L'etat de sa preference horaire, nul quand il n'en a pas.
  final EtatIntention? intentionEtat;

  /// L'offre choisie.
  final String? offreId;

  /// Le fuseau dans lequel l'horaire a ete montre au moment du choix.
  final String? fuseauAffiche;

  /// L'heure montree au moment du choix.
  final int? heureAffichee;

  /// Les jours montres au moment du choix.
  final List<int> joursAffiches;

  /// Le groupe, quand il existe enfin.
  final String? groupeId;

  /// Vrai quand l'offre choisie n'est plus publiee.
  final bool offreIndisponible;

  /// Vrai quand le fuseau du foyer n'est plus celui qui etait affiche.
  final bool fuseauChange;

  /// Vrai quand les questions de personnalisation sont repondues.
  bool get profilRempli =>
      cohorteCode != null &&
      langueCode != null &&
      onboardingFaitLe != null &&
      (public != PublicOffre.enfants || dateNaissance != null);

  /// Vrai quand une preference horaire vit.
  bool get aUnePreference =>
      intentionEtat != null && intentionEtat != EtatIntention.retiree;
}

/// L'etape a laquelle un apprenant est arrive, pour l'affichage.
///
/// Fonction pure et testable sans monter d'ecran, sur le modele de
/// `phaseEnfant` (`lib/features/accueil_famille/`). Elle existe pour qu'un
/// seul endroit decide de ce qui s'affiche : la carte de l'accueil et la
/// derniere page du parcours disent ainsi la meme chose du meme apprenant.
///
/// **L'ordre compte, et il est deliberé.** Une offre devenue indisponible passe
/// devant tout le reste : continuer a montrer « groupe en formation » sur une
/// offre retiree serait le mensonge le plus couteux du parcours.
enum EtapeParcours {
  /// Les questions de personnalisation restent a repondre.
  aPersonnaliser,

  /// Personnalise, aucun horaire choisi.
  horaireAChoisir,

  /// L'offre choisie n'est plus publiee.
  offreIndisponible,

  /// Preference enregistree, diagnostic a faire.
  diagnosticRequis,

  /// Un diagnostic est au calendrier.
  diagnosticEnAttente,

  /// Le vivier n'atteint pas le minimum de lancement.
  groupeEnFormation,

  /// Le groupe existe et l'apprenant y est.
  groupeConfirme,
}

/// L'etape d'un apprenant.
EtapeParcours etapeParcours(ParcoursApprenant p) {
  if (!p.profilRempli) {
    return EtapeParcours.aPersonnaliser;
  }
  if (!p.aUnePreference) {
    return EtapeParcours.horaireAChoisir;
  }
  if (p.offreIndisponible) {
    return EtapeParcours.offreIndisponible;
  }
  return switch (p.intentionEtat) {
    EtatIntention.affectee => EtapeParcours.groupeConfirme,
    EtatIntention.enFormation => EtapeParcours.groupeEnFormation,
    EtatIntention.diagnosticPlanifie => EtapeParcours.diagnosticEnAttente,
    // « Je débute » saute D0 sans fabriquer un diagnostic termine. Le serveur
    // porte `diagnostic_statut = non_requis` et `placement_basis` l'explique.
    EtatIntention.enregistree when p.diagnostic == StatutDiagnostic.nonRequis =>
      EtapeParcours.groupeEnFormation,
    // Une preference enregistree renvoie a ce qu'il reste a faire, et ce qu'il
    // reste a faire est le diagnostic : c'est lui qui debloque l'affectation.
    _ =>
      p.diagnostic == StatutDiagnostic.planifie
          ? EtapeParcours.diagnosticEnAttente
          : EtapeParcours.diagnosticRequis,
  };
}
