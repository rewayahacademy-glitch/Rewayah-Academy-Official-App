import 'package:flutter/foundation.dart';

/// D'ou vient la politique d'observation qui s'applique a un groupe.
///
/// Trois valeurs, et ce sont exactement les trois choix offerts a
/// l'administration : heriter de l'Academie, personnaliser pour ce groupe,
/// desactiver. `desactivee` n'est donc pas l'absence de politique : c'est une
/// politique, celle qui ferme la porte, et elle se journalise comme les autres.
enum SourcePolitique {
  /// La politique de l'Academie s'applique telle quelle.
  academie('academie'),

  /// Le groupe porte ses propres valeurs.
  groupe('groupe'),

  /// L'observation est fermee pour ce groupe.
  desactivee('desactivee');

  const SourcePolitique(this.valeurSql);

  /// La valeur telle qu'elle existe en base.
  final String valeurSql;

  /// Lit une source depuis sa valeur SQL.
  ///
  /// Rend `null` sur une valeur inconnue, jamais un repli : une politique
  /// illisible ne doit pas se lire « heritee de l'Academie », ce qui ouvrirait
  /// une porte que l'administration croyait fermee.
  static SourcePolitique? depuisSql(String? valeur) {
    for (final SourcePolitique source in SourcePolitique.values) {
      if (source.valeurSql == valeur) {
        return source;
      }
    }
    return null;
  }
}

/// La politique d'observation applicable a un groupe (spec section 11.1).
///
/// **Elle est resolue cote serveur**, par une fonction unique analogue a
/// `regle_effective()`, jamais recalculee a l'ecran : deux ecrans qui
/// resoudraient l'heritage chacun de leur cote finiraient par afficher deux
/// budgets differents pour la meme seance.
///
/// Les trois interdictions de media sont portees ici pour etre **lisibles**,
/// pas pour etre appliquees : la barriere reelle est le jeton signe emis par
/// `autoriser_jeton_video()`. Un client qui mettrait `microAutorise` a vrai
/// n'obtiendrait pas un micro pour autant.
@immutable
class GuardianObservationPolicy {
  /// Cree une politique.
  const GuardianObservationPolicy({
    required this.policyVersion,
    required this.source,
    required this.observationActivee,
    required this.maxVisitsPerSession,
    required this.maxTotalObservationTime,
    this.maxParVisite,
    this.microAutorise = false,
    this.cameraAutorisee = false,
    this.publicationDataAutorisee = false,
    this.admissionEnseignantRequise = false,
  });

  /// Les valeurs normatives de la specification, section 11.1.
  ///
  /// **Ce n'est pas la valeur applicable.** La valeur applicable vient toujours
  /// du serveur : les defauts de l'Academie appartiennent a `app_config`, la
  /// surcharge appartient au groupe. Ce constructeur existe pour deux usages,
  /// et pour aucun autre : servir de reference ecrite a la specification, et
  /// alimenter les doubles de test. Aucun ecran ne l'appelle -- un ecran qui
  /// l'appellerait afficherait 120 secondes a un groupe qui en a 300.
  const GuardianObservationPolicy.defautsNormatifs({
    required this.policyVersion,
    this.source = SourcePolitique.academie,
  }) : observationActivee = true,
       maxVisitsPerSession = 1,
       maxTotalObservationTime = const Duration(seconds: 120),
       maxParVisite = null,
       microAutorise = false,
       cameraAutorisee = false,
       publicationDataAutorisee = false,
       admissionEnseignantRequise = false;

  /// Lit la politique rendue par le serveur.
  ///
  /// Les trois media et l'admission enseignante ne sont **pas** lus depuis la
  /// reponse : la specification les fixe a l'interdiction, et les lire
  /// laisserait croire qu'une reponse mal formee pourrait les ouvrir.
  factory GuardianObservationPolicy.depuisJson(Map<String, dynamic> json) {
    final int? plafondVisite = (json['max_seconds_per_visit'] as num?)?.toInt();
    return GuardianObservationPolicy(
      policyVersion: json['policy_version'] as String? ?? '',
      source:
          SourcePolitique.depuisSql(json['source'] as String?) ??
          SourcePolitique.desactivee,
      observationActivee: json['observation_activee'] as bool? ?? false,
      maxVisitsPerSession: (json['max_visits_per_session'] as num?)?.toInt() ?? 0,
      maxTotalObservationTime: Duration(
        seconds:
            (json['max_total_observation_seconds'] as num?)?.toInt() ?? 0,
      ),
      maxParVisite: plafondVisite == null
          ? null
          : Duration(seconds: plafondVisite),
    );
  }

  /// La version de politique, journalisee avec chaque visite.
  ///
  /// Obligatoire : sans elle, une visite de 120 secondes lue six mois plus tard
  /// ne dit pas si la regle du jour en autorisait 120 ou 300.
  final String policyVersion;

  /// D'ou vient la politique appliquee.
  final SourcePolitique source;

  /// L'observation est ouverte. Defaut normatif : vrai.
  final bool observationActivee;

  /// Nombre de visites autorisees par seance. Defaut normatif : 1.
  final int maxVisitsPerSession;

  /// Temps total autorise par seance. Defaut normatif : 120 secondes.
  final Duration maxTotalObservationTime;

  /// Plafond facultatif par visite.
  ///
  /// Il **ne contourne jamais** le plafond total : voir [plafondDeVisite], qui
  /// retient toujours le plus petit des deux.
  final Duration? maxParVisite;

  /// Toujours faux. Le tuteur observe, il ne parle pas.
  final bool microAutorise;

  /// Toujours faux.
  final bool cameraAutorisee;

  /// Toujours faux. Ni chat, ni annotation, ni pilotage du support.
  final bool publicationDataAutorisee;

  /// Toujours faux : l'entree est automatique apres validation serveur, sans
  /// acceptation de l'enseignant (decision D-14).
  final bool admissionEnseignantRequise;

  /// Vrai quand une visite est envisageable du point de vue de la politique.
  ///
  /// Ne dit rien du quota deja consomme : cela, seul le serveur le sait, et il
  /// le dit par `BudgetObservation`.
  bool get observationPossible =>
      observationActivee && source != SourcePolitique.desactivee;

  /// Le plafond applicable a la prochaine visite, budget total restant compris.
  ///
  /// **Le minimum des deux, toujours.** C'est la seule ecriture possible de
  /// l'invariant « un plafond par visite ne contourne jamais le plafond
  /// total » : si le plafond par visite valait 300 secondes et qu'il restait
  /// 40 secondes au total, rendre 300 donnerait au client un compte a rebours
  /// qui promet sept fois le temps reellement accorde.
  Duration plafondDeVisite(Duration restantTotal) {
    final Duration? parVisite = maxParVisite;
    if (parVisite == null) {
      return restantTotal;
    }
    return parVisite < restantTotal ? parVisite : restantTotal;
  }

  /// La meme politique, avec d'autres valeurs de quota.
  GuardianObservationPolicy copieAvec({
    String? policyVersion,
    SourcePolitique? source,
    bool? observationActivee,
    int? maxVisitsPerSession,
    Duration? maxTotalObservationTime,
  }) => GuardianObservationPolicy(
    policyVersion: policyVersion ?? this.policyVersion,
    source: source ?? this.source,
    observationActivee: observationActivee ?? this.observationActivee,
    maxVisitsPerSession: maxVisitsPerSession ?? this.maxVisitsPerSession,
    maxTotalObservationTime:
        maxTotalObservationTime ?? this.maxTotalObservationTime,
    maxParVisite: maxParVisite,
  );
}
