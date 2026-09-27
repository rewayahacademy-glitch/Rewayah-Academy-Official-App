// Mes Classes (ENS-09, EN-3) : la deuxieme destination de la coquille
// enseignant (E10). Une ligne par Classe, dans une seule carte groupee
// (K-42 point 4), triee comme le demande le doc 04 §12.2. Aucun filtre, aucun
// « + Nouvelle classe » (E18) : le tri suffit, et l'enseignant ne cree rien
// d'administratif.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/enums.dart';
import '../../core/enseignant/modeles_enseignant.dart';
import '../../core/enseignant/service_enseignant.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/point_rappel.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../journee/journee_page.dart' show maintenantJourneeProvider;

/// Ce que `mes_groupes_v` ne porte pas encore d'une Classe : son niveau, sa
/// langue, et le fait que l'enseignant l'assure en remplacement.
///
/// **Aucune source serveur a ce jour** (backend reporte a BR-1) : la
/// demonstration surcharge [detailsClassesProvider]. Sans detail, la ligne
/// n'affiche simplement pas ces mots ; rien n'est invente (DESIGN-GOV §1).
@immutable
class DetailClasse {
  /// Cree le detail.
  const DetailClasse({this.niveau, this.langue, this.remplacement = false});

  /// Le niveau de la Classe, s'il est connu.
  final int? niveau;

  /// La langue d'enseignement, lisible.
  final String? langue;

  /// Vrai quand l'enseignant assure cette Classe en remplacement. Un
  /// remplacement modifie une seance, jamais le titulaire (E1).
  final bool remplacement;
}

/// Les details des Classes, par identifiant de groupe. Vide tant que la
/// source n'est pas branchee (BR-1).
final Provider<Map<String, DetailClasse>> detailsClassesProvider =
    Provider<Map<String, DetailClasse>>(
      (Ref _) => const <String, DetailClasse>{},
    );

/// Une Classe telle que la liste la montre.
@immutable
class ClasseListee {
  /// Cree la ligne.
  const ClasseListee({
    required this.groupe,
    this.prochaine,
    this.detail = const DetailClasse(),
    this.cahierAValider = false,
  });

  /// Le groupe, tel que `mes_groupes_v` le rend.
  final GroupeEnseignant groupe;

  /// Le debut de la prochaine seance, ou nul.
  final DateTime? prochaine;

  /// Niveau, langue, remplacement.
  final DetailClasse detail;

  /// Vrai quand un cahier de seance de cette Classe n'est pas valide (K-45).
  final bool cahierAValider;
}

/// Compose les lignes et les trie selon le doc 04 §12.2 :
/// 1. la Classe dont la seance est la plus proche, puis les suivantes dans
///    l'ordre de leur prochaine seance ;
/// 2. les autres Classes actives, sans prochaine seance, par nom.
///
/// `mes_groupes_v` ne rend que les groupes actifs de l'enseignant : une Classe
/// sans prochaine seance y reste donc pertinente. Quand le serveur fournira un
/// ordre metier, il remplacera celui-ci.
List<ClasseListee> classesTriees({
  required List<GroupeEnseignant> groupes,
  required List<SeanceEnseignant> seances,
  required List<CahierEnRetard> cahiers,
  required Map<String, DetailClasse> details,
  required DateTime maintenant,
}) {
  final Map<String, DateTime> prochaines = <String, DateTime>{};
  for (final SeanceEnseignant s in seances) {
    final String? id = s.groupeId;
    if (id == null) continue;
    final bool aVenir =
        (s.statut == StatutSeance.planifiee ||
            s.statut == StatutSeance.enCours) &&
        s.fin.isAfter(maintenant);
    if (!aVenir) continue;
    final DateTime? deja = prochaines[id];
    if (deja == null || s.debut.isBefore(deja)) prochaines[id] = s.debut;
  }
  final Set<String?> aValider = <String?>{
    for (final CahierEnRetard c in cahiers) c.groupeId,
  };

  final List<ClasseListee> lignes = <ClasseListee>[
    for (final GroupeEnseignant g in groupes)
      ClasseListee(
        groupe: g,
        prochaine: prochaines[g.id],
        detail: details[g.id] ?? const DetailClasse(),
        cahierAValider: aValider.contains(g.id),
      ),
  ];
  lignes.sort((ClasseListee a, ClasseListee b) {
    final DateTime? pa = a.prochaine;
    final DateTime? pb = b.prochaine;
    if (pa != null && pb != null) return pa.compareTo(pb);
    if (pa != null) return -1;
    if (pb != null) return 1;
    return a.groupe.libelle.compareTo(b.groupe.libelle);
  });
  return lignes;
}

/// `ENS-09` : les Classes de l'enseignant.
class MesClassesPage extends ConsumerWidget {
  /// Cree la page.
  const MesClassesPage({super.key, this.onOuvrirClasse});

  /// Ce que fait une ligne pressee. Par defaut, l'Espace Classe (`ENS-07`) ;
  /// la demonstration le remplace pour rester dans ses donnees.
  final void Function(String groupeId)? onOuvrirClasse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<GroupeEnseignant>> groupes = ref.watch(
      groupesEnseignantProvider,
    );

    final Widget corps;
    if (groupes.hasError && !groupes.hasValue) {
      corps = EmptyState(
        message: t.enseignant.classes.erreur,
        icone: AppIcons.avertissement,
        libelleAction: t.commun.reessayer,
        onAction: () => ref.invalidate(groupesEnseignantProvider),
      );
    } else if (!groupes.hasValue) {
      // Le squelette prend la forme de la liste : une carte groupee de trois
      // lignes. Un seul noeud lu.
      corps = Semantics(
        label: t.enseignant.classes.chargement,
        child: const ExcludeSemantics(child: Skeleton.liste(lignes: 3)),
      );
    } else if (groupes.requireValue.isEmpty) {
      corps = EmptyState(
        message: t.enseignant.classes.vide,
        invitation: t.enseignant.classes.videDetail,
        icone: AppIcons.classes,
        registre: RegistreVide.subi,
      );
    } else {
      // Seances et cahiers sont des precisions : s'ils manquent, la liste
      // reste lisible, sans prochaine seance ni point de rappel.
      final List<ClasseListee> lignes = classesTriees(
        groupes: groupes.requireValue,
        seances:
            ref.watch(seancesEnseignantProvider).value ??
            const <SeanceEnseignant>[],
        cahiers:
            ref.watch(cahiersEnRetardProvider).value ??
            const <CahierEnRetard>[],
        details: ref.watch(detailsClassesProvider),
        maintenant: ref.watch(maintenantJourneeProvider)(),
      );
      final void Function(String) ouvrir =
          onOuvrirClasse ??
          // `push` : le retour de l'Espace Classe se referme sur Mes classes
          // (R1).
          (String id) => GoRouter.of(context).push(Routes.groupePour(id));
      corps = GroupeReglages(
        lignes: <LigneRubrique>[
          for (final ClasseListee l in lignes)
            _ligne(l, () => ouvrir(l.groupe.id)),
        ],
      );
    }

    // K-42 (style, regle 6) : sur bureau, une colonne bornee comme ENS-06B,
    // pour que pastille et chevron restent pres du nom de la Classe.
    return PageShell(
      titre: t.enseignant.classes.titre,
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: corps,
        ),
      ),
    );
  }
}

/// Une Classe, une ligne : son nom en titre, puis « niveau · langue ·
/// effectif » et la prochaine seance en texte doux. En fin de ligne, seulement
/// les exceptions : le point de rappel d'un cahier non valide (K-45) et la
/// pastille « Remplacement » (E12). Toute la ligne ouvre la Classe.
LigneRubrique _ligne(ClasseListee l, VoidCallback onPress) {
  final int? niveau = l.detail.niveau;
  final String? langue = l.detail.langue;
  final int n = l.groupe.nbMembres;
  final String contexte = <String>[
    if (niveau != null) t.enseignant.classes.niveau(niveau: '$niveau'),
    if (langue != null && langue.trim().isNotEmpty) langue.trim(),
    if (n == 1)
      t.enseignant.classes.eleveUn
    else
      t.enseignant.classes.eleves(nombre: '$n'),
  ].join(' · ');
  final DateTime? p = l.prochaine;
  final String quand = p == null
      ? t.enseignant.classes.sansProchaine
      : t.enseignant.classes.prochaine(
          jour: t.disponibilites.joursLongs[p.weekday - 1],
          heure:
              '${p.hour.toString().padLeft(2, '0')}:'
              '${p.minute.toString().padLeft(2, '0')}',
        );

  final List<Widget> marques = <Widget>[
    if (l.cahierAValider) const _CahierAValider(),
    if (l.detail.remplacement)
      StatusPill(
        libelle: t.enseignant.classes.remplacement,
        ton: TonEtat.accent,
      ),
  ];

  return LigneRubrique(
    libelle: l.groupe.libelle,
    icone: AppIcons.classes,
    legende: '$contexte\n$quand',
    onPress: onPress,
    marque: marques.isEmpty
        ? null
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final (int i, Widget m) in marques.indexed) ...<Widget>[
                if (i > 0) Ecart.hSm,
                m,
              ],
            ],
          ),
  );
}

/// Le rappel d'un cahier non valide (K-45) : le point **et** le mot
/// « Cahier a valider », jamais la couleur seule (WCAG 1.4.1, relecture
/// d'EN-3). Au ton calme : le mot en texte doux, sans alarme. Lu une seule
/// fois, par sa phrase complete.
class _CahierAValider extends StatelessWidget {
  const _CahierAValider();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Semantics(
      key: const ValueKey<String>('classes-cahier-a-valider'),
      label: t.enseignant.classes.rappelCahier,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          PointRappel(libelle: t.enseignant.classes.rappelCahier),
          Ecart.hXs,
          Flexible(
            child: Text(
              t.enseignant.classes.cahierAValider,
              style: palette.inkMuted.applyTo(
                textes.labelMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
