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
import '../../core/domain/enums.dart';
import '../../core/enseignants/modeles_enseignants.dart';
import '../../core/i18n/strings.g.dart';
import '../admin_comptes/liste_comptes.dart';
import '../admin_enseignants/enseignants_page.dart' show libellePhase;
import 'personnes_page.dart';

/// Le parametre d'adresse de la recherche.
const String cleRecherchePersonnes = 'q';

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
  });

  /// Le parametre de l'adresse (`etat`, `classe`, `age`, ...).
  final String cle;

  /// Le nom du type, dans le menu et dans la puce.
  final String libelle;

  /// Les valeurs proposees.
  final List<ValeurFiltre> valeurs;

  /// Le libelle de [code], ou `null` si ce type ne le connait pas.
  String? libelleDe(String? code) {
    for (final ValeurFiltre v in valeurs) {
      if (v.code == code) return v.libelle;
    }
    return null;
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

/// Les types de filtre de [onglet], dans l'ordre du menu.
List<TypeFiltrePersonnes> typesDeFiltre(OngletPersonnes onglet) {
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
  return switch (onglet) {
    OngletPersonnes.eleves => <TypeFiltrePersonnes>[
      etat,
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
    OngletPersonnes.enseignants => <TypeFiltrePersonnes>[
      TypeFiltrePersonnes(
        cle: 'phase',
        libelle: t.admin.listeEnseignants.colonnes.phase,
        valeurs: <ValeurFiltre>[
          for (final PhaseEnseignant ph in PhaseEnseignant.values)
            if (ph != PhaseEnseignant.parti)
              (code: ph.valeurSql, libelle: libellePhase(ph)),
        ],
      ),
    ],
  };
}

/// Les filtres poses, lus dans [requete] : seuls les types de [onglet] et les
/// valeurs qu'ils connaissent sont gardes (une adresse ecrite a la main ne
/// pose jamais un filtre invisible).
Map<String, String> filtresDeLAdresse(
  OngletPersonnes onglet,
  Map<String, String> requete,
) => <String, String>{
  for (final TypeFiltrePersonnes type in typesDeFiltre(onglet))
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
            (!demande || c.admissionATraiter),
      )
      .toList(growable: false);
}

/// Le filtre du serveur pour l'onglet des enseignants.
FiltreEnseignants filtreEnseignantsDe(
  Map<String, String> filtres,
  String recherche,
) => FiltreEnseignants(
  recherche: recherche,
  phase: PhaseEnseignant.values
      .where((PhaseEnseignant p) => p.valeurSql == filtres['phase'])
      .firstOrNull,
);
