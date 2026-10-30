// Mes Classes (ENS-09, EN-3) : la deuxieme destination de la coquille
// enseignant (E10). Une ligne par Classe, dans une seule carte groupee
// (K-42 point 4), triee comme le demande le doc 04 §12.2. Aucun filtre, aucun
// « + Nouvelle classe » (E18) : le tri suffit, et l'enseignant ne cree rien
// d'administratif.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/controle/service_controle.dart' show graceApresFin;
import '../../core/domain/enums.dart';
import '../../core/enseignant/cta_seance.dart';
import '../../core/enseignant/modeles_enseignant.dart';
import '../../core/enseignant/service_enseignant.dart';
import '../../core/i18n/dates_appareil.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/tc_horloge/cadence_seance.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/video/pre_vol.dart' show seuilOuvertureSalle;
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pastille_etat_seance.dart';
import '../../core/widgets/point_rappel.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../com_messages/entree_messages_contexte.dart';
import '../journee/journee_page.dart'
    show entrerEnSalle, maintenantJourneeProvider;

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
    this.seance,
    this.detail = const DetailClasse(),
    this.cahierAValider = false,
  });

  /// Le groupe, tel que `mes_groupes_v` le rend.
  final GroupeEnseignant groupe;

  /// La seance en cours ou la prochaine, ou nulle.
  final SeanceEnseignant? seance;

  /// Le debut de [seance], ou nul.
  DateTime? get prochaine => seance?.debut;

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
  final Map<String, SeanceEnseignant> prochaines = <String, SeanceEnseignant>{};
  for (final SeanceEnseignant s in seances) {
    final String? id = s.groupeId;
    if (id == null) continue;
    final bool aVenir =
        (s.statut == StatutSeance.planifiee ||
            s.statut == StatutSeance.enCours) &&
        s.fin.isAfter(maintenant);
    if (!aVenir) continue;
    final SeanceEnseignant? deja = prochaines[id];
    if (deja == null || s.debut.isBefore(deja.debut)) prochaines[id] = s;
  }
  final Set<String?> aValider = <String?>{
    for (final CahierEnRetard c in cahiers) c.groupeId,
  };

  final List<ClasseListee> lignes = <ClasseListee>[
    for (final GroupeEnseignant g in groupes)
      ClasseListee(
        groupe: g,
        seance: prochaines[g.id],
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
  const MesClassesPage({super.key, this.onOuvrirClasse, this.ouvrable});

  /// Ce que fait une ligne pressee. Par defaut, l'Espace Classe (`ENS-07`) ;
  /// la demonstration le remplace pour rester dans ses donnees.
  final void Function(String groupeId)? onOuvrirClasse;

  /// Vrai pour une Classe qui s'ouvre ; par defaut, toutes. La demonstration
  /// n'ouvre que celle dont elle a les donnees (E3) : une ligne sans
  /// destination n'a ni chevron ni appui.
  final bool Function(String groupeId)? ouvrable;

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
      final List<SeanceEnseignant> seances =
          ref.watch(seancesEnseignantProvider).value ??
          const <SeanceEnseignant>[];
      final List<CahierEnRetard> cahiers =
          ref.watch(cahiersEnRetardProvider).value ?? const <CahierEnRetard>[];
      final Map<String, DetailClasse> details = ref.watch(
        detailsClassesProvider,
      );
      final void Function(String) ouvrir =
          onOuvrirClasse ??
          // `push` : le retour de l'Espace Classe se referme sur Mes classes
          // (R1).
          (String id) => GoRouter.of(context).push(Routes.groupePour(id));
      VoidCallback? appui(ClasseListee l) =>
          (ouvrable?.call(l.groupe.id) ?? true)
          ? () => ouvrir(l.groupe.id)
          : null;
      // Mes classes (directeur, 30/10/2026) : l'ordre se recalcule a chaque
      // bascule (ouverture a T-20, debut, fin) et a chaque minute, sans
      // recharger.
      corps = CadenceSeance(
        lire: ref.watch(maintenantJourneeProvider),
        instants: <DateTime>[
          for (final SeanceEnseignant s in seances)
            ...basculesSeance(s.debut, s.fin),
        ],
        constructeur: (DateTime maintenant) {
          final List<ClasseListee> lignes = classesTriees(
            groupes: groupes.requireValue,
            seances: seances,
            cahiers: cahiers,
            details: details,
            maintenant: maintenant,
          );
          // La Classe en cours ou la plus proche, seule mise en avant ; les
          // autres suivent dans l'ordre de leur prochaine seance.
          final ClasseListee? une =
              lignes.isNotEmpty && lignes.first.seance != null
              ? lignes.first
              : null;
          final List<ClasseListee> autres = une == null
              ? lignes
              : lignes.sublist(1);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (une != null)
                ClasseALaUne(
                  key: const ValueKey<String>('classes-a-la-une'),
                  classe: une,
                  maintenant: maintenant,
                  onOuvrir: appui(une),
                ),
              if (une != null && autres.isNotEmpty) Ecart.vSection,
              if (autres.isNotEmpty)
                GroupeReglages(
                  lignes: <LigneRubrique>[
                    for (final ClasseListee l in autres)
                      _ligne(l, maintenant, appui(l)),
                  ],
                ),
            ],
          );
        },
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
          // COM-F : l'entree generale des Messages, vide tant que la voie
          // COM-MSG ne la remplit pas ; en fin de page, l'ecart entre
          // sections se pose avant elle, rendu seulement quand elle rend
          // quelque chose.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              corps,
              const EntreeMessagesContexte(ecartAvant: Ecart.vSection),
            ],
          ),
        ),
      ),
    );
  }
}

/// L'etat du bouton d'une Classe a [maintenant] (CTA-FIN-1, `ctaSeance`) :
/// le seuil d'ouverture est [seuilOuvertureSalle], la source unique.
CtaSeance? _cta(ClasseListee l, DateTime maintenant) {
  final SeanceEnseignant? s = l.seance;
  return s == null
      ? null
      : ctaDeSeance(
          s,
          maintenant,
          fenetreAcces: seuilOuvertureSalle,
          graceApresFin: graceApresFin,
        );
}

/// La prochaine seance en clair : « jeudi 18:00 · dans 6 jours ».
String _quand(ClasseListee l, DateTime maintenant) {
  final DateTime? p = l.prochaine;
  if (p == null) return t.enseignant.classes.sansProchaine;
  final TextesCompteARebours mots = (
    imminent: () => t.enseignant.classes.reste.imminent,
    minutes: (int m) => LibellesGroupe.insecable(
      t.enseignant.classes.reste.minutes(minutes: m),
    ),
    heures: (int h, String m) => LibellesGroupe.insecable(
      t.enseignant.classes.reste.heures(heures: h, minutes: m),
    ),
    demain: (String _) => t.enseignant.classes.reste.demain,
    jours: (int j) => t.enseignant.classes.reste.jours(jours: j),
  );
  return t.enseignant.classes.quand(
    jour: t.disponibilites.joursLongs[p.weekday - 1],
    heure: heureDeLAppareil(p),
    reste: LibellesGroupe.compteAReboursAvec(
      p.difference(maintenant),
      debut: p,
      textes: mots,
    ),
  );
}

/// « 3 élèves ».
String _effectif(ClasseListee l) => l.groupe.nbMembres == 1
    ? t.enseignant.classes.eleveUn
    : t.enseignant.classes.eleves(nombre: l.groupe.nbMembres);

/// Une Classe, une ligne (Mes classes, 30/10/2026) : son nom, sa prochaine
/// seance (« jeudi 18:00 · dans 6 jours ») et son effectif. En fin de ligne,
/// seulement les exceptions : « En direct », le cahier a valider (K-45) et
/// « Remplacement » (E12). Le niveau et la langue sont dans la Classe. Toute
/// la ligne ouvre la Classe.
LigneRubrique _ligne(
  ClasseListee l,
  DateTime maintenant,
  VoidCallback? onPress,
) {
  final bool enDirect = _cta(l, maintenant)?.enDirect ?? false;
  // COUPE-MOTS-2 : chaque ligne de la legende dans un isolat a sens detecte.
  return LigneRubrique(
    libelle: l.groupe.libelle,
    icone: AppIcons.classes,
    legende:
        '${isolerSens(enDirect ? _effectif(l) : _quand(l, maintenant))}'
        '${enDirect ? '' : '\n${isolerSens(_effectif(l))}'}',
    onPress: onPress,
    marque: enDirect || l.cahierAValider || l.detail.remplacement
        ? MarquesClasse(
            enDirect: enDirect,
            cahierAValider: l.cahierAValider,
            remplacement: l.detail.remplacement,
          )
        : null,
  );
}

/// La Classe en cours ou la plus proche, en tete et mise en avant : une
/// carte a elle (K-55, separee de la liste par un ecart), avec « Rejoindre la
/// salle » seulement quand la salle est ouverte (CTA-FIN-1). C'est le seul
/// bouton plein de l'ecran (K-56) ; avant l'ouverture, la carte n'en a pas.
class ClasseALaUne extends StatelessWidget {
  /// Cree la carte.
  const ClasseALaUne({
    required this.classe,
    required this.maintenant,
    super.key,
    this.onOuvrir,
  });

  /// La Classe.
  final ClasseListee classe;

  /// L'heure de l'ecran.
  final DateTime maintenant;

  /// Ouvre la Classe ; `null` pour une Classe sans destination.
  final VoidCallback? onOuvrir;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final CtaSeance? cta = _cta(classe, maintenant);
    final bool enDirect = cta?.enDirect ?? false;
    final SeanceEnseignant? seance = classe.seance;
    final String groupeId = classe.groupe.id;
    final bool rejoindre =
        cta?.etat == EtatCtaSeance.rejoindre && seance != null;
    return AppCard(
      dominante: true,
      onPress: onOuvrir,
      lien: onOuvrir != null,
      actions: rejoindre
          ? ActionPrincipale(
              key: const ValueKey<String>('classes-rejoindre'),
              libelle: t.enseignant.journee.rejoindreSalle,
              libelleSemantique: t.enseignant.journee.rejoindreSalleLecteur(
                classe: classe.groupe.libelle,
              ),
              pleineLargeur: true,
              onPress: () =>
                  entrerEnSalle(GoRouter.of(context), seance.id, groupeId),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Lecon 8 : « An-Nour » ne se coupe jamais a son tiret.
          TexteSansCoupure(classe.groupe.libelle, style: textes.titleMedium),
          Ecart.vXs,
          if (enDirect)
            const PastilleEtatSeance(etat: EtatPastilleSeance.enDirect)
          else
            Text(
              isolerSens(_quand(classe, maintenant)),
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          Ecart.vXs,
          Text(
            isolerSens(_effectif(classe)),
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          if (classe.cahierAValider || classe.detail.remplacement) ...<Widget>[
            Ecart.vSm,
            MarquesClasse(
              cahierAValider: classe.cahierAValider,
              remplacement: classe.detail.remplacement,
            ),
          ],
        ],
      ),
    );
  }
}

/// Les marques d'une ligne de Mes Classes : le rappel « Cahier de
/// transmission a valider » et la pastille « Remplacement ». Public pour que
/// la galerie montre le composant reel (revue COUPE-MOTS-1-R, m7).
class MarquesClasse extends StatelessWidget {
  /// Cree les marques ; au moins l'une des deux est vraie.
  const MarquesClasse({
    required this.cahierAValider,
    required this.remplacement,
    super.key,
    this.enDirect = false,
  });

  /// La seance de la Classe se tient (« En direct », ON-AIR-1).
  final bool enDirect;

  /// Un cahier de la Classe attend sa validation (K-45).
  final bool cahierAValider;

  /// La Classe est assuree en remplacement.
  final bool remplacement;

  @override
  Widget build(BuildContext context) => Wrap(
    // Wrap, jamais Row : le mot « Cahier de transmission a valider »
    // (LIB-CAHIER-1) passe a la ligne et la pastille passe sous lui, au lieu
    // de deborder a 320 px ou a 200 % (lecon 8, K-41.6). La borne vient de
    // `LigneRubrique`, qui mesure sa ligne (CORR-SUITE-2) : plus de largeur
    // fixe de 200, qui repliait la marque meme a 1280 px.
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.xs,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: <Widget>[
      if (enDirect) const PastilleEtatSeance(etat: EtatPastilleSeance.enDirect),
      if (cahierAValider) const _CahierAValider(),
      if (remplacement)
        StatusPill(
          libelle: t.enseignant.classes.remplacement,
          ton: TonEtat.accent,
        ),
    ],
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
          // Entre les mots, jamais dans « transmission » (lecon 8).
          Flexible(
            child: TexteSansCoupure(
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
