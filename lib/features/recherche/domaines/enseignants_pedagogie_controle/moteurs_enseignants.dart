import '../../../../core/enseignant/port_remplacements.dart';
import '../../../../core/i18n/strings.g.dart';
import '../../../../core/recherche/budgets_recherche.dart';
import '../../../../core/recherche/modeles_recherche.dart';
import '../../../../core/recherche/normalisation_recherche.dart';
import '../../../../core/recherche/port_recherche.dart';
import '../../../../core/tc_classe/port_roster_enseignant.dart';
import '../../../../core/tc_classe/teacher_student_projection.dart';
import '../../../../core/tc_groupe/group_summary_vm.dart';
import '../../../../core/tc_groupe/port_groupes.dart';
import '../classes_supports/pagination_domaine.dart';

/// Les moteurs de RECH-D3 filtrent des corpus **petits, entierement charges
/// par leur port propriétaire et deja autorises** (les enseignants de mes
/// classes, mes offres, mes eleves, ma mission). Ils ne balayent jamais une
/// base ; un domaine interdit est absent ; un corpus illisible est une panne,
/// jamais un vide. En production aucun n'est raccorde (moteurs seulement en
/// demonstration, jusqu'aux adaptateurs serveur de la ligne Contrats C-33).

/// Les enseignants de MES classes (spec RECH-03 §2, §3) : la famille et
/// l'eleve retrouvent le nom d'un enseignant qu'ils connaissent deja. Champs
/// cherches : le nom d'affichage ; rendus : le nom avec son titre et la classe.
/// Aucun annuaire : un enseignant qui n'enseigne aucune classe de la personne
/// n'existe pas pour elle. Aucune coordonnee, aucune pièce, aucun pays n'est lu.
class MoteurEnseignantsDesClasses implements MoteurRechercheDomaine {
  /// Cree le moteur sur [port].
  const MoteurEnseignantsDesClasses(this.port);

  /// Le port des classes de la personne.
  final PortGroupes port;

  static const Set<EspaceRecherche> _espaces = <EspaceRecherche>{
    EspaceRecherche.famille,
    EspaceRecherche.eleve,
    EspaceRecherche.eleveGuide,
  };

  @override
  DomaineRecherche get domaine => DomaineRecherche.enseignants;

  @override
  Future<bool> disponiblePour(ContexteRecherche contexte) async =>
      _espaces.contains(contexte.espace);

  @override
  Future<ReponseDomaine> rechercher({
    required String requete,
    required ContexteRecherche contexte,
    String? curseur,
    int limite = BudgetsRecherche.limiteCommune,
  }) async {
    if (!_espaces.contains(contexte.espace)) {
      return ReponseEchec(domaine, StatutRecherche.contexteRevoque);
    }
    final String cle = normaliserPourRecherche(requete);
    final List<GroupSummaryVM> groupes = await port.mesGroupes();
    final Set<String> vus = <String>{};
    final List<ResultatRecherche> trouves = <ResultatRecherche>[
      for (final GroupSummaryVM g in groupes)
        if (g.actif &&
            correspondTousLesTermes(
              normaliserPourRecherche(g.enseignant.nomAffichage),
              cle,
            ) &&
            vus.add(g.enseignant.enseignantId))
          ResultatRecherche(
            type: TypeResultat.enseignant,
            reference: g.enseignant.enseignantId,
            titre: g.enseignant.nomAffichage,
            contexte: t.recherche.contexte.enseignantDeClasse(
              classe: g.libelle,
            ),
            cible: CibleRecherche(
              kind: KindCible.enseignant,
              reference: g.enseignant.enseignantId,
            ),
          ),
    ];
    return pageDeResultats(
      domaine: domaine,
      contexte: contexte,
      requeteNormalisee: cle,
      trouves: trouves,
      curseur: curseur,
      limite: limite,
    );
  }
}

/// Les offres de remplacement de l'enseignant (REMPL-1) : lues sur
/// `PortRemplacements`. Une offre prise par un collegue n'est jamais trouvee
/// (elle n'est plus a lui). Champs cherches : le nom de la classe (distinct) ;
/// rendus : ce nom et l'etat. Ni motif d'absence, ni nom de l'absent : le
/// contrat ne les porte pas (REMPL-1).
class MoteurRemplacements implements MoteurRechercheDomaine {
  /// Cree le moteur sur [port].
  const MoteurRemplacements(this.port);

  /// Le port des remplacements.
  final PortRemplacements port;

  @override
  DomaineRecherche get domaine => DomaineRecherche.remplacements;

  @override
  Future<bool> disponiblePour(ContexteRecherche contexte) async =>
      contexte.espace == EspaceRecherche.enseignant;

  @override
  Future<ReponseDomaine> rechercher({
    required String requete,
    required ContexteRecherche contexte,
    String? curseur,
    int limite = BudgetsRecherche.limiteCommune,
  }) async {
    if (contexte.espace != EspaceRecherche.enseignant) {
      return ReponseEchec(domaine, StatutRecherche.contexteRevoque);
    }
    final String cle = normaliserPourRecherche(requete);
    final List<OffreCommune> offres = await port.suivre().first;
    final List<ResultatRecherche> trouves = <ResultatRecherche>[
      for (final OffreCommune o in offres)
        // A3 : la preparation (pre-alerte, pret) n'est pas une offre a
        // assurer ; seules l'offre ouverte et la sienne se cherchent.
        if ((o.etat == EtatOffreCommune.ouverte ||
                o.etat == EtatOffreCommune.priseParMoi) &&
            correspondTousLesTermes(
              normaliserPourRecherche(o.offre.classeDistincte),
              cle,
            ))
          ResultatRecherche(
            type: TypeResultat.remplacement,
            reference: o.offre.seanceId,
            titre: o.offre.classeDistincte,
            contexte: o.etat == EtatOffreCommune.priseParMoi
                ? t.recherche.contexte.remplacementMien
                : t.recherche.contexte.remplacementOuvert,
            cible: CibleRecherche(
              kind: KindCible.remplacement,
              reference: o.offre.seanceId,
            ),
          ),
    ];
    return pageDeResultats(
      domaine: domaine,
      contexte: contexte,
      requeteNormalisee: cle,
      trouves: trouves,
      curseur: curseur,
      limite: limite,
    );
  }
}

/// Les eleves de MES classes, en **projection pedagogique** (spec RECH-03 §2,
/// §3 « Eleves pour enseignant ») : `PortRosterEnseignant.rosterDeGroupe` sur
/// chacune de mes classes, rien d'autre.
///
/// Champs cherches : le prenom et le niveau, **rien d'autre**. Ni les notes
/// pedagogiques, ni les objectifs, ni la derniere seance, ni les devoirs :
/// un mot present seulement dans une note privee ne fait jamais remonter un
/// eleve (SEC-R02, REC-03). Champs rendus : le prenom et la classe ; aucun
/// identifiant d'academie, aucune coordonnee. Un eleve d'une classe qui n'est
/// pas la mienne n'existe pas ici.
class MoteurPedagogieEleves implements MoteurRechercheDomaine {
  /// Cree le moteur sur mes classes et leurs rosters.
  const MoteurPedagogieEleves(this.groupes, this.roster);

  /// Mes classes.
  final PortGroupes groupes;

  /// Le roster pedagogique d'une classe.
  final PortRosterEnseignant roster;

  @override
  DomaineRecherche get domaine => DomaineRecherche.pedagogie;

  @override
  Future<bool> disponiblePour(ContexteRecherche contexte) async =>
      contexte.espace == EspaceRecherche.enseignant;

  @override
  Future<ReponseDomaine> rechercher({
    required String requete,
    required ContexteRecherche contexte,
    String? curseur,
    int limite = BudgetsRecherche.limiteCommune,
  }) async {
    if (contexte.espace != EspaceRecherche.enseignant) {
      return ReponseEchec(domaine, StatutRecherche.contexteRevoque);
    }
    final String cle = normaliserPourRecherche(requete);
    final List<GroupSummaryVM> mesClasses = <GroupSummaryVM>[
      for (final GroupSummaryVM g in await groupes.mesGroupes())
        if (g.actif) g,
    ];
    final List<ResultatRecherche> trouves = <ResultatRecherche>[];
    for (final GroupSummaryVM g in mesClasses) {
      final List<TeacherStudentProjection> eleves = await roster.rosterDeGroupe(
        g.groupeId,
      );
      for (final TeacherStudentProjection e in eleves) {
        final String champs = normaliserPourRecherche(
          <String>[e.firstName, ?e.level].join(' '),
        );
        if (!correspondTousLesTermes(champs, cle)) continue;
        trouves.add(
          ResultatRecherche(
            type: TypeResultat.eleveClasse,
            reference: '${g.groupeId}/${e.academyId}',
            titre: e.firstName,
            contexte: t.recherche.contexte.eleveDeClasse(classe: g.libelle),
            cible: CibleRecherche(
              kind: KindCible.eleve,
              reference: e.academyId,
            ),
          ),
        );
      }
    }
    return pageDeResultats(
      domaine: domaine,
      contexte: contexte,
      requeteNormalisee: cle,
      trouves: trouves,
      curseur: curseur,
      limite: limite,
    );
  }
}
