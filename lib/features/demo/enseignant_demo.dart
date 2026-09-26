// Donnees de demonstration du role enseignant (EN-1b, vague Enseignant).
//
// Donnees fictives, jamais envoyees au serveur (K-28), sur le patron de
// classe_demo.dart. Conformes a `12_enseignant/V/00_MAQUETTES_ENSEIGNANT.md`
// section 3 (K-35, E20) :
// - l'enseignant est Sayyid Ibrahim, variante Sayyida conservee ;
// - quatre Classes : An-Nour (niveau 1, arabe, 4 eleves), Al-Fatiha (niveau 2,
//   en remplacement), Al-Badr (niveau 1, francais), Al-Ikhlas (sans prochaine
//   seance) ;
// - les eleves ont un prenom et une photo de demonstration non reelle, les
//   initiales en repli ; les dates sont en septembre et octobre 2026.
//
// **Aucune coordonnee ni donnee privee des familles** : ni nom de famille, ni
// telephone, ni adresse, ni courriel. Un eleve n'est ici qu'une projection
// pedagogique (R15). Les disponibilites sont hebdomadaires, sans date (E15).

import 'package:flutter/foundation.dart';

import '../../core/admin/service_groupes.dart' show TypePublicGroupe;
import '../../core/coran/service_coran.dart' show PositionLecture;
import '../../core/domain/enums.dart';
import '../../core/enseignant/modeles_enseignant.dart';
import '../../core/planning/service_planning.dart' show Creneau;
import '../../core/presence/service_presence.dart' show EtatPresence;
import '../../core/profil/service_profil_enseignant.dart';
import '../../core/tc_groupe/group_summary_vm.dart' show TitreEnseignant;

/// Un eleve de demonstration, vu par l'enseignant.
@immutable
class EleveEnseignantDemo {
  /// Cree l'eleve.
  const EleveEnseignantDemo({
    required this.id,
    required this.prenom,
    required this.pageReprise,
    this.photo,
  });

  /// Identifiant fictif.
  final String id;

  /// Prenom seul.
  final String prenom;

  /// Page de reprise, en texte.
  final String pageReprise;

  /// Cle d'une photo de demonstration non reelle, ou nul : les initiales
  /// sont alors rendues en repli. Aucun fichier n'est encore livre : le rendu
  /// (`PhotoEleve`, EN-4) retombe sur les initiales tant qu'il manque.
  final String? photo;

  /// Les initiales de repli (une lettre par mot du prenom, deux au plus).
  String get initiales {
    final List<String> mots = prenom
        .split(RegExp(r'[\s-]+'))
        .where((String m) => m.isNotEmpty)
        .toList();
    return mots.take(2).map((String m) => m[0].toUpperCase()).join();
  }
}

/// Une Classe de l'enseignant de demonstration.
@immutable
class ClasseEnseignantDemo {
  /// Cree la Classe.
  const ClasseEnseignantDemo({
    required this.id,
    required this.nom,
    required this.niveau,
    required this.langue,
    required this.eleves,
    this.prochaineSeance,
    this.remplacement = false,
    this.seuilMax = 6,
  });

  /// Identifiant fictif.
  final String id;

  /// Nom de la Classe.
  final String nom;

  /// Niveau (1, 2...).
  final int niveau;

  /// Langue d'enseignement, lisible.
  final String langue;

  /// Les eleves.
  final List<EleveEnseignantDemo> eleves;

  /// Debut de la prochaine seance, ou nul (Al-Ikhlas).
  final DateTime? prochaineSeance;

  /// Vrai quand l'enseignant assure cette Classe en remplacement.
  final bool remplacement;

  /// Taille maximale de la Classe.
  final int seuilMax;
}

/// L'etat d'un cahier de seance.
enum EtatCahierDemo {
  /// A remplir apres la seance.
  aRemplir,

  /// Valide.
  valide,
}

/// Un cahier de seance.
@immutable
class CahierDemo {
  /// Cree le cahier.
  const CahierDemo({
    required this.seanceId,
    required this.classeId,
    required this.etat,
  });

  /// La seance du cahier.
  final String seanceId;

  /// La Classe.
  final String classeId;

  /// Son etat.
  final EtatCahierDemo etat;
}

/// L'etat d'une offre de Classe (ENS-06, E15).
enum EtatOffreDemo {
  /// La Classe peut etre demandee.
  disponible,

  /// Demandee, l'academie n'a pas encore tranche.
  enAttenteValidation,

  /// La charge de l'enseignant est atteinte.
  limiteAtteinte,
}

/// Une Classe proposee a l'enseignant.
@immutable
class OffreClasseDemo {
  /// Cree l'offre.
  const OffreClasseDemo({
    required this.id,
    required this.nom,
    required this.niveau,
    required this.langue,
    required this.creneau,
    required this.etat,
    this.autresJours = const <int>[],
    this.dureeMinutes,
  });

  /// Identifiant fictif.
  final String id;

  /// Nom de la Classe.
  final String nom;

  /// Niveau.
  final int niveau;

  /// Langue.
  final String langue;

  /// Creneau hebdomadaire, sans date (E15).
  final Creneau creneau;

  /// Son etat.
  final EtatOffreDemo etat;

  /// Les autres jours du meme rendez-vous (1 = lundi), a la meme heure :
  /// l'enseignant accepte la Classe entiere (doc 04 §16.2, R-ENS-04).
  final List<int> autresJours;

  /// Duree d'une seance, `null` si la source ne la donne pas.
  final int? dureeMinutes;

  /// Tous les jours du rendez-vous hebdomadaire, dans l'ordre de la semaine.
  List<int> get jours => <int>{creneau.jour, ...autresJours}.toList()..sort();
}

/// Un remplacement propose ou assure.
@immutable
class RemplacementDemo {
  /// Cree le remplacement.
  const RemplacementDemo({
    required this.classeId,
    required this.debut,
    required this.enseignantAbsent,
  });

  /// La Classe remplacee.
  final String classeId;

  /// Debut de la seance a assurer.
  final DateTime debut;

  /// Titre et prenom de l'enseignant remplace (jamais le motif, E-regles).
  final String enseignantAbsent;
}

/// Les ecrans de la coquille enseignant proposes en demonstration.
enum EcranDemoEnseignant {
  /// Aujourd'hui (ENS-02).
  aujourdhui,

  /// Classes (ENS-09).
  classes,

  /// Disponibilites (ENS-06).
  disponibilites,

  /// Profil (ENS-05).
  profil,

  /// Premiers pas (ENS-01) : un flux d'activation, hors de la barre. Il
  /// reste le dernier : les quatre premiers suivent l'ordre des destinations.
  premiersPas,

  /// Cahier de seance (ENS-04, EN-7) : l'ecran de sortie de seance, hors de
  /// la barre (planche 4, R5).
  cahier,
}

/// Les situations proposees pour chaque ecran.
enum EtatDemoEnseignant {
  /// Une journee ordinaire, donnees completes.
  nominal,

  /// Aucune seance, aucune Classe a venir.
  vide,

  /// L'appareil est hors ligne.
  horsLigne,
}

/// Les donnees communes de la demonstration enseignant.
abstract final class DonneesEnseignantDemo {
  /// L'identifiant fictif de l'enseignant.
  static const String enseignantId = 'demo-enseignant-ibrahim';

  /// Le prenom de l'enseignant.
  static const String prenom = 'Ibrahim';

  /// L'identifiant public lisible.
  static const String identifiant = 'ENS-0421';

  /// Le nom affiche, selon le titre (Sayyid par defaut, Sayyida en variante).
  static String nomAffiche(TitreEnseignant titre) =>
      titre == TitreEnseignant.sayyida ? 'Sayyida Amina' : 'Sayyid Ibrahim';

  /// Le fuseau de l'enseignant.
  static const String fuseau = 'Europe/Paris';

  /// Le « maintenant » de la demonstration : lundi 28 septembre 2026, 16 h.
  static final DateTime maintenant = DateTime(2026, 9, 28, 16);

  static EleveEnseignantDemo _eleve(
    String id,
    String prenom,
    String page, {
    bool photo = true,
  }) => EleveEnseignantDemo(
    id: id,
    prenom: prenom,
    pageReprise: page,
    photo: photo ? 'demo/eleves/$id.png' : null,
  );

  /// Les quatre Classes, dans l'ordre de 00_MAQUETTES section 3.
  static final List<ClasseEnseignantDemo> classes = <ClasseEnseignantDemo>[
    ClasseEnseignantDemo(
      id: 'demo-classe-an-nour',
      nom: 'An-Nour',
      niveau: 1,
      langue: 'Arabe',
      prochaineSeance: DateTime(2026, 9, 28, 17, 30),
      eleves: <EleveEnseignantDemo>[
        _eleve('demo-eleve-yusuf', 'Yusuf', 'Page 12'),
        _eleve('demo-eleve-maryam', 'Maryam', 'Page 9'),
        _eleve('demo-eleve-adam', 'Adam', 'Page 14', photo: false),
        _eleve('demo-eleve-safiya', 'Safiya', 'Page 11'),
      ],
    ),
    ClasseEnseignantDemo(
      id: 'demo-classe-al-fatiha',
      nom: 'Al-Fatiha',
      niveau: 2,
      langue: 'Arabe',
      prochaineSeance: DateTime(2026, 9, 29, 18),
      remplacement: true,
      eleves: <EleveEnseignantDemo>[
        _eleve('demo-eleve-ilyas', 'Ilyas', 'Page 31'),
        _eleve('demo-eleve-hana', 'Hana', 'Page 28', photo: false),
        _eleve('demo-eleve-zakariya', 'Zakariya', 'Page 30'),
      ],
    ),
    ClasseEnseignantDemo(
      id: 'demo-classe-al-badr',
      nom: 'Al-Badr',
      niveau: 1,
      langue: 'Français',
      prochaineSeance: DateTime(2026, 10, 1, 17),
      eleves: <EleveEnseignantDemo>[
        _eleve('demo-eleve-nour', 'Nour', 'Page 6'),
        _eleve('demo-eleve-idris', 'Idris', 'Page 8'),
        _eleve('demo-eleve-aya', 'Aya', 'Page 5', photo: false),
      ],
    ),
    const ClasseEnseignantDemo(
      id: 'demo-classe-al-ikhlas',
      nom: 'Al-Ikhlas',
      niveau: 1,
      langue: 'Arabe',
      eleves: <EleveEnseignantDemo>[
        EleveEnseignantDemo(
          id: 'demo-eleve-bilal',
          prenom: 'Bilal',
          pageReprise: 'Page 3',
        ),
        EleveEnseignantDemo(
          id: 'demo-eleve-sumayya',
          prenom: 'Sumayya',
          pageReprise: 'Page 4',
        ),
      ],
    ),
  ];

  /// Les quatre Classes, telles que `mes_groupes_v` les rendrait (ENS-09).
  /// Al-Ikhlas, sans prochaine seance, garde son rendez-vous du vendredi.
  static List<GroupeEnseignant> groupes() => <GroupeEnseignant>[
    for (final ClasseEnseignantDemo c in classes)
      GroupeEnseignant(
        id: c.id,
        libelle: c.nom,
        type: TypePublicGroupe.enfant,
        seuilMax: c.seuilMax,
        creneau: Creneau(
          jour: c.prochaineSeance?.weekday ?? 5,
          heure: c.prochaineSeance?.hour ?? 17,
          fuseau: fuseau,
        ),
        nbMembres: c.eleves.length,
        creeLe: DateTime(2026, 9),
      ),
  ];

  /// Une Classe par son identifiant.
  static ClasseEnseignantDemo classe(String id) =>
      classes.firstWhere((ClasseEnseignantDemo c) => c.id == id);

  /// Les seances de la demonstration, septembre et octobre 2026 : une passee
  /// (cahier a remplir), une passee validee, et les prochaines.
  static List<SeanceEnseignant> seances(EtatDemoEnseignant etat) {
    if (etat == EtatDemoEnseignant.vide) return const <SeanceEnseignant>[];
    SeanceEnseignant seance(
      String id,
      ClasseEnseignantDemo c,
      DateTime debut,
      StatutSeance statut, {
      bool cahier = false,
    }) => SeanceEnseignant(
      id: id,
      debut: debut,
      fin: debut.add(const Duration(minutes: 45)),
      statut: statut,
      nbParticipants: c.eleves.length,
      cahierDepose: cahier,
      groupeId: c.id,
      groupeLibelle: c.nom,
      typePublic: TypePublicGroupe.enfant,
      seuilMax: c.seuilMax,
    );
    return <SeanceEnseignant>[
      seance(
        'demo-seance-an-nour-2409',
        classes[0],
        DateTime(2026, 9, 24, 17, 30),
        StatutSeance.terminee,
        cahier: true,
      ),
      seance(
        'demo-seance-al-badr-2609',
        classes[2],
        DateTime(2026, 9, 26, 17),
        StatutSeance.terminee,
      ),
      seance(
        'demo-seance-an-nour-2809',
        classes[0],
        DateTime(2026, 9, 28, 17, 30),
        StatutSeance.planifiee,
      ),
      seance(
        'demo-seance-al-fatiha-2909',
        classes[1],
        DateTime(2026, 9, 29, 18),
        StatutSeance.planifiee,
      ),
      seance(
        'demo-seance-al-badr-0110',
        classes[2],
        DateTime(2026, 10, 1, 17),
        StatutSeance.planifiee,
      ),
    ];
  }

  /// Les cahiers : un a remplir (Al-Badr, 26 septembre), un valide.
  static const List<CahierDemo> cahiers = <CahierDemo>[
    CahierDemo(
      seanceId: 'demo-seance-al-badr-2609',
      classeId: 'demo-classe-al-badr',
      etat: EtatCahierDemo.aRemplir,
    ),
    CahierDemo(
      seanceId: 'demo-seance-an-nour-2409',
      classeId: 'demo-classe-an-nour',
      etat: EtatCahierDemo.valide,
    ),
  ];

  /// Les cahiers a terminer, tels que `mes_rapports_en_attente()` les rendrait.
  static List<CahierEnRetard> cahiersEnRetard(EtatDemoEnseignant etat) {
    if (etat == EtatDemoEnseignant.vide) return const <CahierEnRetard>[];
    final ClasseEnseignantDemo c = classes[2];
    final DateTime debut = DateTime(2026, 9, 26, 17);
    return <CahierEnRetard>[
      CahierEnRetard(
        seanceId: 'demo-seance-al-badr-2609',
        debut: debut,
        fin: debut.add(const Duration(minutes: 45)),
        nbParticipants: c.eleves.length,
        heuresDeRetard: 47,
        groupeId: c.id,
        groupeLibelle: c.nom,
      ),
    ];
  }

  /// Les disponibilites hebdomadaires, sans date (E15) : lundi, mardi,
  /// mercredi et samedi. `jour` suit la convention de [Creneau] (1 = lundi).
  static const List<Creneau> disponibilites = <Creneau>[
    Creneau(jour: 1, heure: 17, fuseau: fuseau),
    Creneau(jour: 1, heure: 18, fuseau: fuseau),
    Creneau(jour: 2, heure: 18, fuseau: fuseau),
    Creneau(jour: 3, heure: 17, fuseau: fuseau),
    Creneau(jour: 6, heure: 10, fuseau: fuseau),
    Creneau(jour: 6, heure: 11, fuseau: fuseau),
  ];

  /// Les Classes proposees, une par etat (ENS-06).
  static const List<OffreClasseDemo> offres = <OffreClasseDemo>[
    OffreClasseDemo(
      id: 'demo-offre-ar-rahma',
      nom: 'Ar-Rahma',
      niveau: 1,
      langue: 'Arabe',
      creneau: Creneau(jour: 3, heure: 18, fuseau: fuseau),
      etat: EtatOffreDemo.disponible,
      // Lundi, mercredi, vendredi : l'exemple de R-ENS-04 (doc 04).
      autresJours: <int>[1, 5],
      // La duree des seances de demonstration (45 min, voir `seances`).
      dureeMinutes: 45,
    ),
    OffreClasseDemo(
      id: 'demo-offre-as-salam',
      nom: 'As-Salam',
      niveau: 2,
      langue: 'Français',
      creneau: Creneau(jour: 6, heure: 10, fuseau: fuseau),
      etat: EtatOffreDemo.enAttenteValidation,
    ),
    OffreClasseDemo(
      id: 'demo-offre-al-huda',
      nom: 'Al-Huda',
      niveau: 1,
      langue: 'Arabe',
      creneau: Creneau(jour: 4, heure: 17, fuseau: fuseau),
      etat: EtatOffreDemo.limiteAtteinte,
    ),
  ];

  /// Le remplacement : Al-Fatiha, mardi 29 septembre 2026 a 18 h. Le motif
  /// de l'absence n'est jamais montre.
  static final RemplacementDemo remplacement = RemplacementDemo(
    classeId: 'demo-classe-al-fatiha',
    debut: DateTime(2026, 9, 29, 18),
    enseignantAbsent: 'Sayyid Harun',
  );

  /// Le profil de l'enseignant, tel que le service le rendrait.
  static const ProfilEnseignant profil = ProfilEnseignant(
    prenom: prenom,
    identifiant: identifiant,
    langues: <String>['Arabe', 'Français'],
    plafondHeures: 12,
    statutCompte: AccountStatus.active,
  );

  /// Le brouillon du cahier d'Al-Badr, 26 septembre 2026, tel que
  /// `brouillon_cahier()` le rendrait (ENS-04, EN-7) : Nour presente, Idris en
  /// retard, Aya absente. Nour et Idris se sont arretes au meme verset, ce qui
  /// donne la proposition de reprise. [deja] rend le cahier deja valide.
  static BrouillonCahier brouillonCahier({bool deja = false}) {
    final ClasseEnseignantDemo c = classes[2];
    final DateTime debut = DateTime(2026, 9, 26, 17);
    const PositionLecture position = PositionLecture(
      page: 582,
      sourate: 78,
      verset: 12,
    );
    ParticipantBrouillon eleve(
      EleveEnseignantDemo e,
      EtatPresence presence, {
      int retard = 0,
      bool lu = true,
    }) => ParticipantBrouillon(
      membre: MembreSeance(
        studentId: e.id,
        identifiantImmuable: 'RA-${e.id.substring(11).toUpperCase()}',
        prenom: e.prenom,
      ),
      presence: presence,
      entreLe: presence == EtatPresence.absente
          ? null
          : debut.add(Duration(minutes: retard)),
      derniereTraceLe: presence == EtatPresence.absente
          ? null
          : debut.add(const Duration(minutes: 45)),
      position: lu ? position : null,
    );
    return BrouillonCahier(
      seanceId: cahierDemoSeanceId,
      debut: debut,
      fin: debut.add(const Duration(minutes: 45)),
      statut: StatutSeance.terminee,
      dureeMinutes: 45,
      minutesInterruption: 0,
      dejaDepose: deja,
      groupeId: c.id,
      participants: <ParticipantBrouillon>[
        eleve(c.eleves[0], EtatPresence.presente),
        eleve(c.eleves[1], EtatPresence.enRetard, retard: 7),
        eleve(c.eleves[2], EtatPresence.absente, lu: false),
      ],
      evenements: const <EvenementSeance>[],
    );
  }

  /// La seance du cahier de demonstration.
  static const String cahierDemoSeanceId = 'demo-seance-al-badr-2609';
}
