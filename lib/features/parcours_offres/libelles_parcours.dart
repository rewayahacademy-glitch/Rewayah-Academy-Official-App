import 'package:flutter/foundation.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/offres/offre_horaire.dart';

/// Un moment de la journee, tel qu'une famille le dit.
///
/// **Ce n'est pas un generateur d'horaire prive.** Ces trois reponses ne
/// filtrent rien et n'ecrivent rien : elles servent uniquement a mettre en
/// avant, parmi les offres que l'academie publie deja, celle qui tombe le mieux
/// (voir [classerOffres]). Toutes les autres restent visibles juste en dessous.
///
/// C'est la lecture retenue de l'etape « disponibilite generale » de la
/// mission. Poser la question sans s'en servir aurait ete une question
/// decorative ; s'en servir pour filtrer aurait cache des horaires ouverts ;
/// s'en servir pour promettre un creneau aurait viole l'interdiction du
/// sur-mesure. Classer est la seule lecture qui ne fasse aucun des trois.
enum MomentJournee {
  /// Avant midi.
  matin(6, 12),

  /// De midi a dix-huit heures.
  apresMidi(12, 18),

  /// A partir de dix-huit heures.
  soir(18, 24);

  const MomentJournee(this.premiereHeure, this.apresDerniereHeure);

  /// Premiere heure locale incluse.
  final int premiereHeure;

  /// Premiere heure locale exclue.
  final int apresDerniereHeure;

  /// Vrai quand [heure] tombe dans ce moment.
  bool contient(int heure) =>
      heure >= premiereHeure && heure < apresDerniereHeure;

  /// Le libelle affiche.
  String get libelle => switch (this) {
    MomentJournee.matin => t.parcours.momentMatin,
    MomentJournee.apresMidi => t.parcours.momentApresMidi,
    MomentJournee.soir => t.parcours.momentSoir,
  };
}

/// Classe les offres : celles qui tombent dans un [moments] retenu d'abord.
///
/// **Aucune offre n'est retiree.** Une offre hors des moments choisis descend,
/// elle ne disparait pas : l'academie publie peu d'horaires, et en cacher un
/// parce qu'il tombe a 14 h alors que la famille a coche « le soir » ferait
/// rater un cours qui aurait convenu.
///
/// L'ordre du serveur est conserve a l'interieur de chaque groupe, et le tri
/// est stable : deux offres egalement pertinentes restent dans l'ordre publie.
List<OffreHoraire> classerOffres(
  List<OffreHoraire> offres,
  Set<MomentJournee> moments,
) {
  if (moments.isEmpty || offres.length < 2) {
    return offres;
  }

  bool pertinente(OffreHoraire o) => o.creneaux.any(
    (CreneauVu c) => moments.any((MomentJournee m) => m.contient(c.heure)),
  );

  return <OffreHoraire>[
    ...offres.where(pertinente),
    ...offres.where((OffreHoraire o) => !pertinente(o)),
  ];
}

/// Un fuseau propose a la confirmation.
///
/// **Liste fermee, et c'est deliberé.** La question « ou etes-vous » se repond
/// au doigt, pas au clavier : un champ libre demanderait a un parent de taper
/// un identifiant IANA, ce qu'il n'a aucune raison de connaitre. Le serveur
/// refuse de toute facon tout fuseau qu'il ne connait pas.
///
/// [decalageStandard] est le decalage d'hiver, en heures. Il ne sert qu'a
/// **suggérer** la reponse la plus probable d'apres l'horloge de l'appareil ;
/// la personne confirme toujours.
///
/// `ponytail:` l'heure d'ete n'est pas modelisee ici, faute de base tz embarquee
/// (aucune dependance ajoutee pour cela). Plafond : entre mars et octobre, la
/// suggestion peut tomber sur le fuseau voisin. Consequence : un tap de plus, la
/// liste etant affichee en entier. Montee possible : `flutter_timezone`, le jour
/// ou une autre fonction en aura besoin.
@immutable
class FuseauPropose {
  /// Cree une proposition.
  const FuseauPropose({
    required this.iana,
    required this.libelle,
    required this.decalageStandard,
  });

  /// L'identifiant IANA, envoye au serveur.
  final String iana;

  /// Ce qui s'affiche : un lieu, jamais un identifiant technique.
  final String libelle;

  /// Le decalage d'hiver par rapport a UTC, en heures.
  final int decalageStandard;
}

/// Les lieux proposes, dans un ordre stable.
///
/// Stable, et non trie par proximite : une liste qui se reorganise a chaque
/// ouverture casse la memoire du geste. C'est la suggestion qui bouge, pas
/// l'ordre.
const List<FuseauPropose> fuseauxProposes = <FuseauPropose>[
  FuseauPropose(
    iana: 'Europe/Paris',
    libelle: 'France, Belgique, Espagne',
    decalageStandard: 1,
  ),
  FuseauPropose(
    iana: 'Europe/London',
    libelle: 'Royaume-Uni, Irlande',
    decalageStandard: 0,
  ),
  FuseauPropose(
    iana: 'Africa/Conakry',
    libelle: 'Guinée, Sénégal, Mali, Mauritanie',
    decalageStandard: 0,
  ),
  FuseauPropose(
    iana: 'Africa/Casablanca',
    libelle: 'Maroc',
    decalageStandard: 1,
  ),
  FuseauPropose(
    iana: 'Africa/Abidjan',
    libelle: "Côte d'Ivoire, Burkina Faso, Togo",
    decalageStandard: 0,
  ),
  FuseauPropose(
    iana: 'Africa/Lagos',
    libelle: 'Nigéria, Niger, Tchad, Cameroun',
    decalageStandard: 1,
  ),
  FuseauPropose(
    iana: 'America/Toronto',
    libelle: 'Canada et États-Unis, côte est',
    decalageStandard: -5,
  ),
  FuseauPropose(
    iana: 'America/Los_Angeles',
    libelle: 'Canada et États-Unis, côte ouest',
    decalageStandard: -8,
  ),
];

/// Le fuseau a pre-cocher.
///
/// [fuseauConnu] gagne toujours : si le foyer a deja dit ou il est, le lui
/// redemander en proposant autre chose serait le contredire. Sinon, le plus
/// proche du [decalageAppareil] mesure, arrondi a l'heure.
///
/// Rend `null` quand rien ne ressemble : mieux vaut aucune case cochee qu'une
/// case fausse que la personne validerait sans la lire.
FuseauPropose? fuseauSuggere({
  String? fuseauConnu,
  required Duration decalageAppareil,
}) {
  final FuseauPropose? connu = fuseauxProposes
      .where((FuseauPropose f) => f.iana == fuseauConnu)
      .firstOrNull;
  if (connu != null) {
    return connu;
  }

  final int heures = (decalageAppareil.inMinutes / 60).round();
  FuseauPropose? meilleur;
  int ecartMin = 1 << 30;
  for (final FuseauPropose f in fuseauxProposes) {
    final int ecart = (f.decalageStandard - heures).abs();
    if (ecart < ecartMin) {
      ecartMin = ecart;
      meilleur = f;
    }
  }
  // Au-dela de deux heures d'ecart, la suggestion n'en est plus une.
  return ecartMin <= 2 ? meilleur : null;
}

/// Le libelle d'un niveau auto-declare.
///
/// **Aucune de ces phrases ne contient `F1`, `F2` ni `F3`.** Un code de
/// referentiel n'est pas une reponse qu'on montre a un parent.
String libelleNiveau(NiveauDeclare niveau) => switch (niveau) {
  NiveauDeclare.debutLettres => t.parcours.niveauDebutLettres,
  NiveauDeclare.lettresAvecAide => t.parcours.niveauLettresAvecAide,
  NiveauDeclare.lectureLente => t.parcours.niveauLectureLente,
  NiveauDeclare.lectureCourante => t.parcours.niveauLectureCourante,
  NiveauDeclare.memorisationPartielle => t.parcours.niveauMemorisationPartielle,
};

/// Le libelle d'un objectif.
String libelleObjectif(ObjectifApprentissage objectif) => switch (objectif) {
  ObjectifApprentissage.apprendreALire => t.parcours.objectifApprendreALire,
  ObjectifApprentissage.devenirFluide => t.parcours.objectifDevenirFluide,
  ObjectifApprentissage.memoriser => t.parcours.objectifMemoriser,
  ObjectifApprentissage.indecis => t.parcours.objectifIndecis,
};

/// Les jours d'une offre, ecrits en toutes lettres et separes par des virgules.
///
/// Reutilise `t.disponibilites.joursLongs`, deja traduit et deja indexe de
/// lundi a dimanche : une seconde liste de jours aurait fini par diverger.
String libelleJours(List<CreneauVu> creneaux) {
  final List<String> noms = <String>[
    for (final CreneauVu c in creneaux)
      if (c.jourIso >= 1 && c.jourIso <= 7)
        t.disponibilites.joursLongs[c.jourIso - 1],
  ];
  return noms.join(', ');
}

/// Les heures d'une offre, telles qu'elles se lisent chez l'utilisateur.
///
/// Une heure par creneau quand elles different, une seule quand elles
/// coincident : une semaine de changement d'heure peut decaler un jour et pas
/// un autre, et ecrire « 18:00 » pour les trois serait alors faux.
String libelleHeures(List<CreneauVu> creneaux) {
  final Set<int> heures = <int>{for (final CreneauVu c in creneaux) c.heure};
  final List<int> triees = heures.toList()..sort();
  return triees.map(_heure).join(' / ');
}

String _heure(int h) => '${h.toString().padLeft(2, '0')}:00';

/// Le titre de l'etat d'un apprenant.
String titreEtape(EtapeParcours etape) => switch (etape) {
  EtapeParcours.aPersonnaliser => t.parcours.etatAPersonnaliser,
  EtapeParcours.horaireAChoisir => t.parcours.etatHoraireAChoisir,
  EtapeParcours.offreIndisponible => t.parcours.etatOffreIndisponible,
  EtapeParcours.diagnosticRequis => t.parcours.etatDiagnosticRequis,
  EtapeParcours.diagnosticEnAttente => t.parcours.etatDiagnosticEnAttente,
  EtapeParcours.groupeEnFormation => t.parcours.etatClasseEnFormation,
  EtapeParcours.groupeConfirme => t.parcours.etatClasseConfirmee,
};

/// Le detail de l'etat d'un apprenant.
///
/// **Aucune de ces phrases ne dit qu'une place est reservee.** « Preference
/// enregistree » et « groupe en cours de constitution » sont dits tels quels,
/// parce que c'est ce qui est vrai : annoncer une classe reservee avant qu'un
/// groupe existe serait le mensonge que la mission interdit nommement.
String detailEtape(
  EtapeParcours etape, {
  required String prenom,
  required int? minimumLancement,
}) => switch (etape) {
  EtapeParcours.aPersonnaliser => t.parcours.etatAPersonnaliserDetail(
    prenom: prenom,
  ),
  EtapeParcours.horaireAChoisir => t.parcours.etatHoraireAChoisirDetail(
    prenom: prenom,
  ),
  EtapeParcours.offreIndisponible => t.parcours.etatOffreIndisponibleDetail(
    prenom: prenom,
  ),
  EtapeParcours.diagnosticRequis => t.parcours.etatDiagnosticRequisDetail(
    prenom: prenom,
  ),
  EtapeParcours.diagnosticEnAttente => t.parcours.etatDiagnosticEnAttenteDetail(
    prenom: prenom,
  ),
  // Le minimum vient d'`app_config` par `regles_academie()`, jamais d'une
  // constante ecrite ici : il change par decision d'exploitation. Tant que
  // la regle n'est pas encore chargee, ne rien affirmer sur un chiffre
  // (LA-F, constat honnetete : 0 serait une information fausse).
  EtapeParcours.groupeEnFormation =>
    minimumLancement == null
        ? t.parcours.etatClasseEnFormationDetailSansMinimum
        : t.parcours.etatClasseEnFormationDetail(minimum: minimumLancement),
  EtapeParcours.groupeConfirme => t.parcours.etatClasseConfirmeeDetail(
    prenom: prenom,
  ),
};
