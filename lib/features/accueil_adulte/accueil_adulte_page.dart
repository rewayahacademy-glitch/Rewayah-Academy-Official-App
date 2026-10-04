// L'accueil de l'eleve adulte (EA-2, planches 1.1 et 5, UX_REVIEW_07
// lignes 2 et 3).
//
// Aucun composant neuf (K-51) : l'en-tete (`EntetePage`,
// `ClocheNotifications`), la lecture du groupe et sa carte de seance CL-4
// (`LecteurGroupe`, `LectureGroupe.identiteEtCarte`, donc `IdentiteGroupe`,
// `CarteSession` et `EmplacementEntree`) sont ceux de l'Espace Classe,
// extraits de `tc_espace_groupe/espace_groupe_page.dart` ; la disposition
// est la grille Bento partagee (`GrilleBento`, BENTO-3) ; « Avant le prochain cours » (`EmplacementAvantProchainCours`, R17),
// les seances passees (`GroupeReglages` : la date, puis une seule ligne, la
// plage ; une pastille pour une absence) et la Bibliotheque unique
// (`BlocBibliotheque`, trois au plus).
//
// Pas de photo de l'eleve dans l'en-tete : K-44 porte sur les ecrans ou
// l'enseignant voit l'eleve (outils/yaaden/YAADEN_RULES.md, ligne 44, « SI
// enseignant ALORS ... photo de l'eleve visible (K-44) » ; REVUE_EN-R m4),
// et ni la planche 1.1 ni 00_MAQUETTES ne la placent ici. La salutation
// tient ainsi sur une ligne a 390 (rectification C6), et passe a la ligne
// entre les mots a 200 %.
//
// Reportes, dits ici : « Voir mon historique » de « Mon parcours »
// (00_MAQUETTES 1.1, P) attend l'historique d'EA-3. La cloche ouvre ce que
// la coquille lui donne : en demonstration, le `NotificationsPage` existant,
// ou se trouve l'invitation recue par le second adulte (EA-7) ; le centre de
// notifications de l'eleve adulte reste a EA-8.
//
// Le seul provider propre a l'ecran, [accueilAdulteProvider], n'a aucune
// source serveur : il rend `CapaciteIndisponible` (EA-BR-04), la
// demonstration le surcharge (K-28).
//
// DASH-EA-PROD : l'ecran a une route reelle, `/eleve/adulte`
// (`routes_accueil_adulte.dart`), choisie par la capacite
// [capaciteAccueilAdulteProvider], jamais par le role. « Voir tout » des
// dernieres seances ouvre l'historique (`/eleve/adulte/seances`) ; sans
// destination, aucun lien (D9). Le chargement a la forme de la grille Bento
// (D11, revue BENTO-3-R m6).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/planning/service_planning.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/tc_groupe/group_home_vm.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entete_page.dart';
import '../../core/widgets/grille_bento.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../accueil_famille/accueil_famille_page.dart'
    show largeurMinCarteClasse;
import '../tc_espace_groupe/emplacements_groupe.dart';
import '../tc_espace_groupe/espace_groupe_page.dart'
    show LecteurGroupe, LectureGroupe;

/// Une seance passee, telle que le serveur la rendrait : la seance, sa date
/// deja rendue, et l'absence seule (une presence est l'etat normal et ne
/// porte aucune pastille, 00_MAQUETTES planche 5, C5).
@immutable
class SeancePasseeAdulte {
  /// Cree la seance passee.
  const SeancePasseeAdulte({
    required this.seance,
    required this.dateRendue,
    this.absence = false,
  });

  /// La seance (plage, Classe, enseignant).
  final Seance seance;

  /// La date, deja rendue par le serveur.
  final String dateRendue;

  /// Vrai quand l'eleve etait absent.
  final bool absence;
}

/// Ce que l'accueil de l'eleve adulte lit, en une fois.
@immutable
class AccueilAdulteVM {
  /// Cree la vue.
  const AccueilAdulteVM({
    required this.prenom,
    this.groupeId,
    this.ligneParcours,
    this.dernieresSeances = const <SeancePasseeAdulte>[],
    this.notificationsNonLues,
  });

  /// Le prenom de l'eleve.
  final String prenom;

  /// Sa Classe, `null` tant qu'il n'en a aucune.
  final String? groupeId;

  /// « Mon parcours », une ligne deja rendue ; `null` : pas de section.
  final String? ligneParcours;

  /// Les dernieres seances, les plus recentes d'abord (trois montrees).
  final List<SeancePasseeAdulte> dernieresSeances;

  /// Les notifications non lues, telles que le service les rend.
  final int? notificationsNonLues;
}

/// L'accueil de l'eleve adulte. **Aucune source serveur a ce jour**
/// (EA-BR-04) : `CapaciteIndisponible`, que `BlocAsynchrone` dit comme tel,
/// sans « Reessayer ». La demonstration le surcharge.
final FutureProvider<AccueilAdulteVM> accueilAdulteProvider =
    FutureProvider<AccueilAdulteVM>(
      (Ref _) => Future<AccueilAdulteVM>.error(
        const CapaciteIndisponible('accueil_eleve_adulte'),
      ),
      // Aucune relance automatique (Riverpod 3) : une capacite absente ne
      // revient pas en insistant ; « Reessayer » relit a la demande.
      retry: (int _, Object _) => null,
    );

/// La capacite « accueil de l'eleve adulte » du compte connecte
/// (DASH-EA-PROD) : vraie quand le serveur sert `accueil_eleve_adulte`
/// (EA-BR-04) a ce compte eleve. C'est elle, et non un role, qui fait ouvrir
/// `/eleve` sur l'Accueil adulte (`routes_accueil_adulte.dart`).
///
/// Une lecture en echec ou indisponible la laisse fausse, meme apres une
/// premiere lecture reussie : `/eleve` garde
/// l'accueil de l'eleve, rien n'est suppose. Elle n'est lue que pour un
/// compte eleve : aucun autre compte n'atteint `/eleve` (garde de role).
/// Quand EA-BR-04 sera servi, une capacite rendue avec la session evitera
/// d'attendre cette lecture (DASH-BR-02, registre `DASH_STRATEGIE.md`
/// §5 bis, a reporter dans `EA-BR.md`).
final Provider<bool> capaciteAccueilAdulteProvider = Provider<bool>((Ref ref) {
  final AppRole? role = ref.watch(
    sessionProvider.select((SessionState s) => s.role),
  );
  if (role != AppRole.student) return false;
  // Une relecture en echec garde la valeur precedente (`hasValue` reste
  // vrai) : sans `hasError`, la capacite resterait vraie apres l'echec
  // (revue DASH-EA-PROD-R, defaut 1). Une relecture en cours, elle, la garde
  // vraie : pas de va-et-vient du routeur pendant « Reessayer ».
  final AsyncValue<AccueilAdulteVM> lecture = ref.watch(accueilAdulteProvider);
  return lecture.hasValue && !lecture.hasError;
});

/// L'accueil de l'eleve adulte : salutation et cloche, prochaine seance,
/// « Avant le prochain cours » (s'il y a quelque chose a faire), « Mon
/// parcours » en une ligne, dernieres seances (3) et ressources de la
/// Classe (3). Grille Bento en hauteur de contenu (DASH_STRATEGIE.md §3.7).
class AccueilAdultePage extends ConsumerWidget {
  /// Cree l'accueil.
  const AccueilAdultePage({
    super.key,
    this.onNotifications,
    this.onRejoindre,
    this.onVoirRessources,
    this.onVoirDernieresSeances,
  });

  /// Ouvre le centre de notifications. Nul : pas de cloche (aucune cloche
  /// inerte, D9).
  final VoidCallback? onNotifications;

  /// Ouvre l'historique des seances passees (« Voir tout », D6). Nul : pas
  /// de lien (D9).
  final VoidCallback? onVoirDernieresSeances;

  /// Ce que fait le bouton de l'emplacement d'entree.
  final void Function(GroupSummaryVM groupe)? onRejoindre;

  /// Ouvre la Bibliotheque de la Classe.
  final void Function(String groupeId)? onVoirRessources;

  /// Le nombre de dernieres seances et de ressources montrees.
  static const int limite = 3;

  /// La cle du bloc « rien a afficher » hors ligne (EA-HL-DOUBLE-1).
  static const Key sansDonneesKey = Key('adulte.accueil.sansDonnees');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    // Hors ligne se dit une fois (EA-HL-DOUBLE-1) : le bandeau de `PageShell`
    // le dit ; une lecture deja faite reste affichee, et sans elle le bloc dit
    // ce qui manque. Une capacite absente reste dite indisponible.
    final AsyncValue<AccueilAdulteVM> lecture = lectureHorsLigne(
      ref.watch(accueilAdulteProvider),
      horsLigne: horsLigne,
    );
    final AccueilAdulteVM? vue = lecture.value;
    void relire() => ref.invalidate(accueilAdulteProvider);
    final bool echecHorsLigne = sansDonneesHorsLigne(
      lecture,
      horsLigne: horsLigne,
    );
    // Pendant le chargement, l'en-tete garde sa place : une ligne de
    // squelette pour la salutation, et la cloche deja posee.
    // Une lecture en echec que Riverpod relance reste `isLoading` : sans
    // `hasError`, pas de ligne de squelette au-dessus d'un etat d'echec ou
    // d'indisponibilite (DASH-EA-PROD).
    final Widget? entete =
        vue != null || (lecture.isLoading && !lecture.hasError)
        ? _Salutation(
            prenom: vue?.prenom,
            nonLues: vue?.notificationsNonLues,
            onNotifications: onNotifications,
          )
        : null;
    return PageShell(
      entete: entete,
      // Sans lecture de l'accueil (indisponible, echec), la cloche reste :
      // le centre de notifications ne depend pas de cette lecture (EA-7,
      // l'invitation recue s'y trouve).
      actionsEntete: entete == null && onNotifications != null
          ? <Widget>[ClocheNotifications(onPress: onNotifications)]
          : const <Widget>[],
      child: echecHorsLigne
          ? EtatSansDonnees(
              key: sansDonneesKey,
              quoi: t.adulte.accueil.sansDonnees,
              onAction: relire,
            )
          : BlocAsynchrone<AccueilAdulteVM>(
              valeur: lecture,
              squelette: const SqueletteAccueilAdulte(),
              titreEchec: t.adulte.accueil.echec,
              onReessayer: relire,
              construire: (AccueilAdulteVM vue) => _Corps(
                vue: vue,
                onRejoindre: onRejoindre,
                onVoirRessources: onVoirRessources,
                onVoirDernieresSeances: onVoirDernieresSeances,
              ),
            ),
    );
  }
}

/// La salutation en une ligne et la cloche ; [prenom] `null` pendant le
/// chargement.
class _Salutation extends StatelessWidget {
  const _Salutation({
    required this.prenom,
    required this.nonLues,
    required this.onNotifications,
  });

  final String? prenom;
  final int? nonLues;
  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context) {
    // Sans destination, pas de cloche : jamais une cloche inerte (D9).
    final VoidCallback? ouvrir = onNotifications;
    final List<Widget> cloche = ouvrir == null
        ? const <Widget>[]
        : <Widget>[ClocheNotifications(onPress: ouvrir, nonLues: nonLues)];
    final String? p = prenom;
    if (p == null) {
      return Row(
        children: <Widget>[
          const Expanded(
            child: ExcludeSemantics(child: Skeleton(hauteur: AppSpacing.xxxl)),
          ),
          if (cloche.isNotEmpty) ...<Widget>[Ecart.hXs, ...cloche],
        ],
      );
    }
    return EntetePage(
      titre: t.adulte.accueil.salutation(prenom: p),
      actions: cloche,
    );
  }
}

class _Corps extends StatelessWidget {
  const _Corps({
    required this.vue,
    this.onRejoindre,
    this.onVoirRessources,
    this.onVoirDernieresSeances,
  });

  final AccueilAdulteVM vue;
  final void Function(GroupSummaryVM groupe)? onRejoindre;
  final void Function(String groupeId)? onVoirRessources;
  final VoidCallback? onVoirDernieresSeances;

  @override
  Widget build(BuildContext context) {
    final String? groupeId = vue.groupeId;

    // Sans Classe : un etat subi, rien a faire ici (l'inscription vit
    // ailleurs, doc section 3).
    if (groupeId == null) {
      return EmptyState(
        message: t.adulte.accueil.aucuneClasse,
        invitation: t.adulte.accueil.aucuneClasseDetail,
        icone: AppIcons.cours,
        registre: RegistreVide.subi,
      );
    }

    return LecteurGroupe(
      groupeId: groupeId,
      squelette: const SqueletteAccueilAdulte(),
      construire: (BuildContext contexte, LectureGroupe lecture) => _Sections(
        vue: vue,
        groupeId: groupeId,
        lecture: lecture,
        onRejoindre: onRejoindre,
        onVoirRessources: onVoirRessources,
        onVoirDernieresSeances: onVoirDernieresSeances,
      ),
    );
  }
}

class _Sections extends StatelessWidget {
  const _Sections({
    required this.vue,
    required this.groupeId,
    required this.lecture,
    this.onRejoindre,
    this.onVoirRessources,
    this.onVoirDernieresSeances,
  });

  final AccueilAdulteVM vue;
  final String groupeId;
  final LectureGroupe lecture;
  final void Function(GroupSummaryVM groupe)? onRejoindre;
  final void Function(String groupeId)? onVoirRessources;
  final VoidCallback? onVoirDernieresSeances;

  @override
  Widget build(BuildContext context) {
    final GroupHomeVM espace = lecture.espace;
    final List<SeancePasseeAdulte> passees = vue.dernieresSeances
        .take(AccueilAdultePage.limite)
        .toList();
    final String? parcours = vue.ligneParcours;

    final List<Widget> seance = <Widget>[
      SectionHeader(
        key: const ValueKey<String>('accueil-adulte-prochaine-seance'),
        titre: t.adulte.accueil.prochaineSeance,
      ),
      Ecart.vMd,
      ...lecture.identiteEtCarte(onRejoindre: onRejoindre),
    ];

    // Seulement ce que les donnees demandent : sans action, pas de section.
    final List<Widget> avant =
        lecture.portTravailBranche && espace.avantProchainCours.isNotEmpty
        ? <Widget>[
            EmplacementAvantProchainCours(
              actions: espace.avantProchainCours,
              portBranche: true,
            ),
          ]
        : const <Widget>[];

    final List<Widget> ligneParcours = parcours == null
        ? const <Widget>[]
        : <Widget>[
            SectionHeader(titre: t.adulte.accueil.parcours),
            Ecart.vMd,
            AppCard(
              child: Text(
                parcours,
                key: const ValueKey<String>('accueil-adulte-parcours'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ];

    // K-42 point 4 : la date, puis une seule ligne, la plage ; la Classe et
    // l'enseignant sont deja nommes par la carte au-dessus.
    final List<Widget> dernieres = passees.isEmpty
        ? const <Widget>[]
        : <Widget>[
            // « Voir tout » (D6) ouvre l'historique ; sans destination, pas
            // de lien (D9). Meme lien tertiaire, place comme celui des
            // ressources (`BlocBibliotheque`).
            EnteteVoirTout(
              titre: t.adulte.accueil.dernieresSeances,
              libelle: t.tuteur.accueil.voirTout,
              onVoirTout: onVoirDernieresSeances,
            ),
            Ecart.vMd,
            ListeSeancesPassees(
              key: const ValueKey<String>('accueil-adulte-dernieres'),
              seances: passees,
            ),
          ];

    final void Function(String groupeId)? voir = onVoirRessources;
    final Widget ressources = BlocBibliotheque(
      emplacement: espace.bibliotheque,
      titre: t.adulte.accueil.ressources,
      limite: AccueilAdultePage.limite,
      onVoirTout: voir == null ? null : () => voir(groupeId),
    );

    // BENTO-3 : la grille Bento partagee, disposition de DASH_STRATEGIE.md
    // §3.7, en hauteur de contenu (comme l'accueil famille, BENTO-2). Rang 1
    // Prochaine seance, rang 2 « Avant le prochain cours » (s'il y en a), en
    // grandes tuiles ; rang 3 « Mon parcours » en large ; rangs 4 et 5
    // dernieres seances et ressources en grandes tuiles. Deux grandes tuiles
    // ne partagent leur bande que si chaque moitie offre
    // [largeurMinCarteClasse] x echelle du texte (regle BENTO-2b de la carte
    // classe famille) ; sinon chacune passe en pleine largeur et aucun mot
    // n'est coupe. Une tuile seule dans sa bande s'y etire (placerBento).
    final double echelle = MediaQuery.textScalerOf(context).scale(1);
    Widget section(List<Widget> enfants) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: enfants,
    );
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints contraintes) {
        final bool coteACote =
            (contraintes.maxWidth - GrilleBento.ecart) / 2 >=
            largeurMinCarteClasse * math.max(1, echelle);
        final EtendueBento? grande = coteACote
            ? null
            : const EtendueBento(4, 1);
        TuileBento tuileGrande(List<Widget> enfants, {bool seule = false}) =>
            TuileBento(
              etendue: EtendueBento.grande,
              etendueLarge: seule ? const EtendueBento(4, 1) : grande,
              child: section(enfants),
            );
        final List<TuileBento> tuiles = <TuileBento>[
          // Sans « Avant », la seance prend toute sa bande : sinon la tuile
          // suivante (dernieres seances) monterait a cote d'elle, avant
          // « Mon parcours » (ordre de §3.7, D2).
          tuileGrande(seance, seule: avant.isEmpty),
          if (avant.isNotEmpty) tuileGrande(avant),
          if (ligneParcours.isNotEmpty)
            TuileBento(
              etendue: EtendueBento.large,
              etendueLarge: const EtendueBento(4, 1),
              child: section(ligneParcours),
            ),
          if (dernieres.isNotEmpty) tuileGrande(dernieres),
          tuileGrande(<Widget>[ressources]),
        ];
        // D14 : deux tuiles ou moins, pas de Bento ; une colonne, ecart 16.
        if (tuiles.length <= 2) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final (int i, TuileBento tuile)
                  in tuiles.indexed) ...<Widget>[
                if (i > 0) const SizedBox(height: GrilleBento.ecart),
                tuile.child,
              ],
            ],
          );
        }
        return GrilleBento(hauteurContenu: true, tuiles: tuiles);
      },
    );
  }
}

/// Un titre de section et son « Voir tout », places comme ceux des
/// ressources (`BlocBibliotheque`) : sur la ligne du titre, au bord de fin,
/// sur mobile comme sur bureau ; a grande taille de texte
/// ([AppGabarit.seuilTexteColonne]), sous le titre, au bord de debut.
/// `SectionHeader` seul passerait le lien sous le titre des 600 px de large :
/// deux « Voir tout » voisins ne seraient pas au meme endroit (contre-revue
/// DASH-EA-PROD-R). Sans [onVoirTout], pas de lien (D9). Le titre ne coupe
/// aucun mot : `SectionHeader` le rend en `TexteSansCoupure` des que le texte
/// est agrandi, sans le reduire en bloc.
class EnteteVoirTout extends StatelessWidget {
  /// Cree l'en-tete.
  const EnteteVoirTout({
    required this.titre,
    required this.libelle,
    super.key,
    this.onVoirTout,
  });

  /// Le titre de section.
  final String titre;

  /// Le libelle du lien.
  final String libelle;

  /// La destination du lien ; nulle : pas de lien.
  final VoidCallback? onVoirTout;

  @override
  Widget build(BuildContext context) {
    final Widget entete = SectionHeader(titre: titre);
    final VoidCallback? ouvrir = onVoirTout;
    if (ouvrir == null) return entete;
    final Widget lien = IntrinsicWidth(
      child: ActionPrincipale(
        libelle: libelle,
        niveau: NiveauAction.tertiaire,
        pleineLargeur: false,
        onPress: ouvrir,
      ),
    );
    final bool empile =
        MediaQuery.textScalerOf(context).scale(1) >=
        AppGabarit.seuilTexteColonne;
    if (empile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          entete,
          Ecart.vSm,
          Align(alignment: AlignmentDirectional.centerStart, child: lien),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Flexible(flex: 2, child: entete),
        Ecart.hLg,
        Flexible(child: lien),
      ],
    );
  }
}

/// Des seances passees en une carte groupee : la date, puis une seule
/// ligne, la plage ; une pastille pour une absence seulement (K-42 point 4).
/// La Classe et l'enseignant ne sont pas repetes. Partagee par l'Accueil
/// (trois seances) et l'historique (toutes).
class ListeSeancesPassees extends StatelessWidget {
  /// Cree la liste.
  const ListeSeancesPassees({required this.seances, super.key});

  /// Les seances, les plus recentes d'abord.
  final List<SeancePasseeAdulte> seances;

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations l10n = MaterialLocalizations.of(context);
    String heure(DateTime quand) => l10n.formatTimeOfDay(
      TimeOfDay.fromDateTime(quand),
      alwaysUse24HourFormat: true,
    );
    return GroupeReglages(
      lignes: <LigneRubrique>[
        for (final SeancePasseeAdulte s in seances)
          LigneRubrique(
            icone: AppIcons.cours,
            libelle: s.dateRendue,
            legende: t.enseignant.journee.plage(
              debut: heure(s.seance.debut),
              fin: heure(s.seance.fin),
            ),
            marque: s.absence
                ? StatusPill(
                    libelle: t.adulte.accueil.absence,
                    ton: TonEtat.avertissement,
                  )
                : null,
          ),
      ],
    );
  }
}

/// Le chargement de l'Accueil adulte, a la forme de sa grille Bento (D11,
/// DESIGN-GOV §4 bis.6 regle 3 ; revue BENTO-3-R m6) : la prochaine seance
/// et « Avant le prochain cours » en grandes tuiles, cote a cote seulement
/// quand chaque moitie offre [largeurMinCarteClasse] x echelle du texte,
/// « Mon parcours » en large, puis dernieres seances et ressources. Aucune
/// fausse donnee : des blocs seuls.
class SqueletteAccueilAdulte extends StatelessWidget {
  /// Cree le squelette.
  const SqueletteAccueilAdulte({super.key});

  /// Hauteur d'une grande tuile qui charge, composee des jetons de ce
  /// qu'elle attend (revue DASH-EA-PROD-R, defaut 2) : un titre de section,
  /// son ecart, trois lignes de reglage (les trois dernieres seances ou
  /// ressources, [AccueilAdultePage.limite]) et la marge de la carte.
  static const double hauteurGrande =
      AppSpacing.xxxl +
      AppSpacing.md +
      AccueilAdultePage.limite * AppPage.hauteurReglage +
      AppSpacing.xxl;

  /// Hauteur de « Mon parcours » qui charge : un titre de section, son
  /// ecart et une seule ligne de carte.
  static const double hauteurLarge =
      AppSpacing.xxxl + AppSpacing.md + AppPage.hauteurReglage;

  @override
  Widget build(BuildContext context) {
    final double echelle = MediaQuery.textScalerOf(context).scale(1);
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (BuildContext _, BoxConstraints contraintes) {
          final bool coteACote =
              (contraintes.maxWidth - GrilleBento.ecart) / 2 >=
              largeurMinCarteClasse * math.max(1, echelle);
          TuileBento grande() => TuileBento(
            etendue: EtendueBento.grande,
            etendueLarge: coteACote ? null : const EtendueBento(4, 1),
            child: const Skeleton.tuileBento(hauteur: hauteurGrande),
          );
          return GrilleBento(
            hauteurContenu: true,
            tuiles: <TuileBento>[
              grande(),
              grande(),
              const TuileBento(
                etendue: EtendueBento.large,
                etendueLarge: EtendueBento(4, 1),
                child: Skeleton.tuileBento(hauteur: hauteurLarge),
              ),
              grande(),
              grande(),
            ],
          );
        },
      ),
    );
  }
}
