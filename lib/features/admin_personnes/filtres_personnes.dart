// PERSONNES-UNE-PAGE, etape (c) : le filtre unique de la page « Personnes »
// (directeur, 20/11/2026 : des filtres « comme du loto », « je vois juste
// quelque chose bouger »).
//
// Un seul geste, toujours le meme : « Filtrer par », puis le type, puis la
// valeur ; le filtre pose devient une puce qu'on retire. Ce fichier ne porte
// que la description des types par onglet et leur application ; il ne decide
// rien. Les comptes (eleves, familles, equipe) sont filtres sur la liste
// deja lue ; les enseignants le sont par le serveur (`lister_enseignants`,
// `FiltreEnseignants`).
//
// Les filtres vivent dans l'adresse (un parametre par type) : recharger rend
// la meme liste.
library;

import 'package:flutter/foundation.dart';

import '../../core/admin/service_comptes.dart';
import '../../core/candidature/modeles_autres_competences.dart'
    show CatalogueCompetences;
import '../../core/candidature/modeles_candidatures_direction.dart'
    show FiltreCandidatures;
import '../../core/domain/enums.dart';
import '../../core/enseignants/modeles_enseignants.dart';
import '../../core/i18n/strings.g.dart';
import '../admin_candidatures/adresse_candidatures.dart';
import '../admin_comptes/liste_comptes.dart';
import '../admin_enseignants/enseignants_page.dart' show libellePhase;
import 'filtres_candidats.dart';
import 'personnes_page.dart';

/// Le parametre d'adresse de la recherche.
const String cleRecherchePersonnes = 'q';

/// PERSONNES-UNE-PAGE (d) : les vues de l'onglet des enseignants (directeur,
/// 20/11/2026 : « dans "enseignant" tu sais qu'il y a des candidats, et
/// ensuite les vrais enseignants, a toi de voir comment classer cela »).
enum VueEnseignants {
  /// Les candidatures (`lister_candidatures`, les 26 filtres de la file).
  candidats('candidats'),

  /// Confirmes, il leur manque encore quelque chose.
  accueil('accueil'),

  /// Les enseignants qui peuvent enseigner ou enseignent ([phasesActives]).
  actifs('actifs'),

  /// Les comptes supprimes.
  partis('partis'),

  /// Les pieces d'identite a verifier.
  pieces('pieces');

  const VueEnseignants(this.cle);

  /// La valeur ecrite dans l'adresse (`vue=`).
  final String cle;

  /// La vue de l'adresse ; sans valeur lisible, les candidats.
  static VueEnseignants depuis(String? cle) => values.firstWhere(
    (VueEnseignants v) => v.cle == cle,
    orElse: () => VueEnseignants.candidats,
  );
}

/// Les phases que la vue « Actifs » rassemble, dans l'ordre d'affichage. Un
/// rangement d'ecran, pas une regle : chaque phase reste decidee par le
/// serveur.
const List<PhaseEnseignant> phasesActives = <PhaseEnseignant>[
  PhaseEnseignant.enPoste,
  PhaseEnseignant.absent,
  PhaseEnseignant.disponible,
  PhaseEnseignant.pause,
  PhaseEnseignant.suspendu,
];

/// Une valeur d'un type de filtre.
typedef ValeurFiltre = ({String code, String libelle});

/// Un type de filtre : son parametre d'adresse, son nom, ses valeurs.
@immutable
class TypeFiltrePersonnes {
  /// Cree le type.
  const TypeFiltrePersonnes({
    required this.cle,
    required this.libelle,
    required this.valeurs,
    this.famille,
    this.multiple = false,
  });

  /// La famille du type (premier niveau du menu), ou `null` : le menu n'a
  /// alors que deux niveaux.
  final String? famille;

  /// Vrai : plusieurs valeurs a la fois, separees par des virgules dans
  /// l'adresse (les jours disponibles).
  final bool multiple;

  /// Le parametre de l'adresse (`etat`, `classe`, `age`, ...).
  final String cle;

  /// Le nom du type, dans le menu et dans la puce.
  final String libelle;

  /// Les valeurs proposees.
  final List<ValeurFiltre> valeurs;

  /// Le libelle de [code], ou `null` si ce type ne le connait pas.
  String? libelleDe(String? code) {
    if (code == null || code.isEmpty) return null;
    if (multiple) {
      final List<String> libelles = <String>[];
      for (final String c in code.split(',')) {
        final String? l = _libelleSimple(c);
        if (l == null) return null;
        libelles.add(l);
      }
      return libelles.join(', ');
    }
    return _libelleSimple(code);
  }

  String? _libelleSimple(String code) {
    for (final ValeurFiltre v in valeurs) {
      if (v.code == code) return v.libelle;
    }
    return null;
  }

  /// La valeur d'adresse apres le choix de [code] : pour un type [multiple],
  /// [code] s'ajoute a [courante] ou s'en retire (`null` quand il n'en reste
  /// aucun), dans l'ordre des valeurs ; sinon [code] remplace.
  String? apresChoix(String? courante, String code) {
    if (!multiple) return code;
    final Set<String> retenus = <String>{
      ...?courante?.split(',').where((String c) => c.isNotEmpty),
    };
    if (!retenus.remove(code)) retenus.add(code);
    final List<String> ordonnes = <String>[
      for (final ValeurFiltre v in valeurs)
        if (retenus.contains(v.code)) v.code,
    ];
    return ordonnes.isEmpty ? null : ordonnes.join(',');
  }
}

/// Les etats de compte qu'on filtre (l'etat inconnu ne se choisit pas).
const List<EtatAffiche> _etats = <EtatAffiche>[
  EtatAffiche.attente,
  EtatAffiche.sansDecision,
  EtatAffiche.actif,
  EtatAffiche.provisoire,
  EtatAffiche.suspendu,
];

/// Les roles de l'onglet « Direction et equipe ».
const List<AppRole> _rolesEquipe = <AppRole>[
  AppRole.admin,
  AppRole.accountant,
  AppRole.controller,
  AppRole.associe,
];

/// Les types de filtre de [onglet], dans l'ordre du menu. Pour les
/// enseignants, [vue] choisit : les 26 filtres de la file des candidatures
/// (rangees en familles), la phase pour les actifs, rien pour les autres.
List<TypeFiltrePersonnes> typesDeFiltre(
  OngletPersonnes onglet, {
  VueEnseignants vue = VueEnseignants.candidats,
  CatalogueCompetences? catalogue,
  bool garderPourSuivi = false,
}) {
  final k = t.admin.comptes;
  final p = t.admin.personnesPage;
  final TypeFiltrePersonnes etat = TypeFiltrePersonnes(
    cle: 'etat',
    libelle: k.colonneEtat,
    valeurs: <ValeurFiltre>[
      for (final EtatAffiche e in _etats)
        (code: e.name, libelle: libelleEtatAffiche(e)),
    ],
  );
  // DASH-ADM-ECHUS : les acces provisoires dont la date est passee (le filtre
  // « Acces echus » de la page Comptes).
  final TypeFiltrePersonnes acces = TypeFiltrePersonnes(
    cle: 'acces',
    libelle: p.typeAcces,
    valeurs: <ValeurFiltre>[(code: 'echus', libelle: t.admin.tableau.comptes)],
  );
  return switch (onglet) {
    OngletPersonnes.eleves => <TypeFiltrePersonnes>[
      etat,
      acces,
      TypeFiltrePersonnes(
        cle: 'classe',
        libelle: k.colonneClasse,
        valeurs: <ValeurFiltre>[
          (code: 'avec', libelle: p.classeAvec),
          (code: 'sans', libelle: k.classeAucune),
        ],
      ),
      TypeFiltrePersonnes(
        cle: 'age',
        libelle: k.colonneTranche,
        valeurs: <ValeurFiltre>[
          (code: TrancheAge.enfant.name, libelle: k.trancheEnfant),
          (code: TrancheAge.adulte.name, libelle: k.trancheAdulte),
        ],
      ),
    ],
    OngletPersonnes.familles => <TypeFiltrePersonnes>[
      etat,
      acces,
      TypeFiltrePersonnes(
        cle: 'demande',
        libelle: p.typeDemande,
        valeurs: <ValeurFiltre>[
          (code: 'a_traiter', libelle: p.demandeATraiterCourt),
        ],
      ),
    ],
    OngletPersonnes.equipe => <TypeFiltrePersonnes>[
      etat,
      TypeFiltrePersonnes(
        cle: 'role',
        libelle: k.colonneRole,
        valeurs: <ValeurFiltre>[
          for (final AppRole r in _rolesEquipe)
            (code: r.name, libelle: nomDuRole(r)),
        ],
      ),
    ],
    OngletPersonnes.enseignants => switch (vue) {
      VueEnseignants.candidats => typesFiltreCandidats(
        catalogue: catalogue,
        garderPourSuivi: garderPourSuivi,
      ),
      VueEnseignants.actifs => <TypeFiltrePersonnes>[
        TypeFiltrePersonnes(
          cle: 'phase',
          libelle: t.admin.listeEnseignants.colonnes.phase,
          valeurs: <ValeurFiltre>[
            for (final PhaseEnseignant ph in phasesActives)
              (code: ph.valeurSql, libelle: libellePhase(ph)),
          ],
        ),
      ],
      VueEnseignants.accueil ||
      VueEnseignants.partis ||
      VueEnseignants.pieces => const <TypeFiltrePersonnes>[],
    },
  };
}

/// Les filtres poses, lus dans [requete] : seuls les types de [onglet] et les
/// valeurs qu'ils connaissent sont gardes (une adresse ecrite a la main ne
/// pose jamais un filtre invisible).
Map<String, String> filtresDeLAdresse(
  List<TypeFiltrePersonnes> types,
  Map<String, String> requete,
) => <String, String>{
  for (final TypeFiltrePersonnes type in types)
    if (type.libelleDe(requete[type.cle]) != null) type.cle: requete[type.cle]!,
};

/// La recherche de [requete], sans les blancs de bord.
String rechercheDeLAdresse(Map<String, String> requete) =>
    (requete[cleRecherchePersonnes] ?? '').trim();

/// Les comptes de [tous] qui passent [filtres] et [recherche]. Pure.
List<CompteAdmin> filtrerComptes(
  List<CompteAdmin> tous, {
  required Map<String, String> filtres,
  required String recherche,
  required DateTime maintenant,
}) {
  final String? etat = filtres['etat'];
  final String? classe = filtres['classe'];
  final String? age = filtres['age'];
  final String? role = filtres['role'];
  final bool demande = filtres['demande'] == 'a_traiter';
  final bool echus = filtres['acces'] == 'echus';
  // La recherche et l'ordre sont ceux de la page Comptes (une seule regle).
  return FiltreComptes(recherche: recherche)
      .appliquer(tous, maintenant)
      .where(
        (CompteAdmin c) =>
            (etat == null || EtatAffiche.de(c).name == etat) &&
            (classe == null ||
                (nomClasseEleve(c) != null) == (classe == 'avec')) &&
            (age == null || c.tranche?.name == age) &&
            (role == null || c.role?.name == role) &&
            (!demande || c.admissionATraiter) &&
            (!echus || c.accesEchu(maintenant)),
      )
      .toList(growable: false);
}

/// Le filtre du serveur pour une vue des enseignants (hors candidats et
/// pieces). Pour « Actifs » sans phase choisie, la phase reste `null` : la page
/// lit alors chaque phase de [phasesActives].
FiltreEnseignants filtreEnseignantsDe(
  VueEnseignants vue,
  Map<String, String> filtres,
  String recherche,
) => FiltreEnseignants(
  recherche: recherche,
  phase: switch (vue) {
    VueEnseignants.accueil => PhaseEnseignant.accueil,
    VueEnseignants.partis => PhaseEnseignant.parti,
    VueEnseignants.actifs =>
      phasesActives
          .where((PhaseEnseignant p) => p.valeurSql == filtres['phase'])
          .firstOrNull,
    VueEnseignants.candidats || VueEnseignants.pieces => null,
  },
  partis: vue == VueEnseignants.partis,
);

/// Le filtre du serveur pour la vue « Candidats » : les memes cles d'adresse
/// que l'ancienne liste des candidatures (`requeteDepuisAdresse`).
FiltreCandidatures filtreCandidatsDe(
  Map<String, String> filtres,
  String recherche,
) => requeteDepuisAdresse(filtres).filtre.avec(recherche: recherche);

/// La file que le dossier complet recoit dans son adresse, pour passer au
/// suivant dans la meme liste (`FileDuDossier`). [phaseDeLaLigne] : la phase
/// de la personne ouverte, pour « Actifs » sans phase choisie (sa file est
/// alors celle de sa phase).
Map<String, String> fileDeLaVue(
  VueEnseignants vue,
  Map<String, String> filtres, {
  PhaseEnseignant? phaseDeLaLigne,
}) => switch (vue) {
  VueEnseignants.candidats => <String, String>{'vue': vue.cle, ...filtres},
  VueEnseignants.pieces => <String, String>{'vue': vue.cle},
  _ => <String, String>{
    'file': 'enseignants',
    'vue': vue.cle,
    // Le filtre pose (« Actifs » filtre par phase) revient dans l'adresse de
    // la page ; la phase que la vue impose, non (`phase_file`).
    if (filtres['phase'] case final String posee
        when vue == VueEnseignants.actifs)
      'phase': posee
    else if (filtreEnseignantsDe(vue, filtres, '').phase ?? phaseDeLaLigne
        case final PhaseEnseignant p)
      'phase_file': p.valeurSql,
    if (vue == VueEnseignants.partis) 'partis': 'oui',
  },
};
