import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/tc_groupe/group_home_vm.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/tc_groupe/port_groupes.dart';
import '../../core/tc_horloge/port_horloge_seance.dart';
import '../../core/tc_horloge/session_clock_vm.dart';
import '../../core/tc_parcours/port_travail_a_venir.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../tc_catalogue/routes_tc_b.dart';
import '../tc_mes_groupes/carte_groupe.dart';
import '../tc_mes_groupes/chemins_tc_a.dart';
import '../tc_mes_groupes/photo_enseignant.dart';
import 'carte_session.dart';
import 'emplacements_groupe.dart';

/// L'Espace Groupe, pour les quatre roles.
///
/// **Aucune barre laterale interne. Aucun systeme de cinq onglets.** Une page
/// verticale, dont l'ordre ne change ni avec le role, ni avec la largeur :
/// identite du groupe, Session Card dominante, « Avant le prochain cours »,
/// Bibliotheque, puis ce qui est secondaire. Ce qui change avec la largeur,
/// c'est la mise en colonnes ; jamais la sequence de lecture.
///
/// « Reprendre le cours » **n'est pas une section permanente** : le bouton
/// n'apparait que lorsqu'il y a quelque chose a reprendre, c'est-a-dire quand
/// la seance est en cours ou vient de deborder.
class EspaceGroupePage extends ConsumerWidget {
  /// Cree l'Espace Groupe.
  const EspaceGroupePage({
    required this.groupeId,
    super.key,
    this.role = RoleEspaceGroupe.eleve,
    this.onRejoindre,
    this.onReprendreLeCours,
    this.contenuRoster,
    this.titre,
    this.tutoiement = false,
    this.pied,
    this.enPile = false,
  });

  /// Vrai en Mode Accessibilite (pose par l'hote, MA-4) : l'identite en
  /// pile. Lire ici le fournisseur de session casserait les hotes sans
  /// session (tests des autres roles).
  final bool enPile;

  /// Le titre de destination, quand l'espace EST une destination de la
  /// coquille (Ma classe du Mode Accessibilite, MA-4) : il remplace alors le
  /// chemin de sortie « Mes classes », qui contredirait l'onglet. Nul
  /// partout ailleurs : rendu inchange.
  final String? titre;

  /// Vrai pour l'eleve mineur : la carte de seance le tutoie (MA4, MA-3).
  final bool tutoiement;

  /// Ce que l'hote pose en dernier (MA-4 : le Suivi, puis l'aide, MA14).
  final Widget? pied;

  /// Le groupe a ouvrir.
  final String groupeId;

  /// Qui regarde.
  ///
  /// Par defaut l'eleve. Agent Z le derive de la session applicative : un
  /// widget lit une **capacite**, jamais un role brut, et cette resolution
  /// appartient au socle.
  final RoleEspaceGroupe role;

  /// Ce que fait « Rejoindre ». Branche par Agent Z sur le shell d'Agent E.
  final void Function(GroupSummaryVM groupe)? onRejoindre;

  /// Ce que fait « Reprendre le cours ».
  ///
  /// La position de groupe vient d'Agent F (`SharedContentState`) : Agent A
  /// pose l'action au bon moment, il ne restaure rien lui-meme.
  final void Function(GroupSummaryVM groupe)? onReprendreLeCours;

  /// La surface de roster d'Agent E, quand l'hote l'a branchee.
  final Widget? contenuRoster;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pas de titre d'ecran : l'identite du groupe EST le titre, et elle porte
    // la photo, la couleur et la capacite. Un « Mes groupes » en tete
    // repeterait le libelle du chemin de sortie, juste en dessous.
    final String? titreDestination = titre;
    final Widget corps = LecteurGroupe(
      groupeId: groupeId,
      role: role,
      construire: (BuildContext _, LectureGroupe lecture) => _Colonnes(
        lecture: lecture,
        onRejoindre: onRejoindre,
        onReprendreLeCours: onReprendreLeCours,
        contenuRoster: contenuRoster,
        tutoiement: tutoiement,
        enPile: enPile,
      ),
    );
    final Widget? basDePage = pied;
    final Widget contenu = basDePage == null
        ? corps
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[corps, Ecart.vSection, basDePage],
          );
    if (titreDestination != null) {
      return PageShell(titre: titreDestination, child: contenu);
    }
    return PageShell(entete: const _Sortie(), child: contenu);
  }
}

/// Le chemin de sortie, visible et en tete.
///
/// L'Espace Groupe s'ouvre depuis une carte : il vit donc hors de la coquille
/// de navigation et porte sa propre sortie, comme `ENS-07` le fait deja.
class _Sortie extends StatelessWidget {
  const _Sortie();

  @override
  Widget build(BuildContext context) {
    // Au bord de debut (contrat B). `IntrinsicWidth` : sans lui,
    // `ActionPrincipale` s'etirerait et centrerait son libelle ; borne par la
    // largeur disponible, le libelle passe a la ligne a 200 %.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: IntrinsicWidth(
        child: ActionPrincipale(
          libelle: LibellesGroupe.retour,
          niveau: NiveauAction.tertiaire,
          pleineLargeur: false,
          // `go` et non `pop` : l'espace peut avoir ete ouvert par une adresse,
          // et une sortie qui n'existe que sur une pile laisserait l'utilisateur
          // enferme.
          onPress: () => GoRouter.of(context).go(CheminsTcA.mesGroupes),
        ),
      ),
    );
  }
}

/// Ce qu'un groupe rend une fois lu : l'espace du role, et ce que la carte de
/// seance CL-4 doit savoir du reseau et de l'horloge.
///
/// Partage par l'Espace Groupe et l'accueil de l'eleve adulte (EA-2, K-51) :
/// la carte dit la meme chose ici et la-bas, parce qu'elle est lue et cablee
/// au meme endroit.
@immutable
class LectureGroupe {
  /// Cree la lecture.
  const LectureGroupe({
    required this.espace,
    required this.portTravailBranche,
    required this.horsLigne,
    required this.annulee,
    required this.lectureEchouee,
    required this.onReessayer,
  });

  /// L'espace du groupe pour le role qui regarde.
  final GroupHomeVM espace;

  /// Vrai quand le port du travail a venir est branche.
  final bool portTravailBranche;

  /// Vrai hors ligne : « Rejoindre » est alors desactive.
  final bool horsLigne;

  /// Vrai quand la seance du jour est annulee.
  final bool annulee;

  /// Vrai quand l'horloge n'a jamais pu etre lue.
  final bool lectureEchouee;

  /// Relit le reseau et l'horloge.
  final VoidCallback onReessayer;

  /// La carte de seance CL-4, cablee sur cette lecture. « Rejoindre » est
  /// desactive hors ligne ou sans [onRejoindre]. [tutoiement] : l'eleve
  /// mineur est tutoye (MA4, MA-3).
  Widget carte({
    void Function(GroupSummaryVM groupe)? onRejoindre,
    bool tutoiement = false,
  }) {
    final GroupSummaryVM identite = espace.identite;
    return CarteSession(
      espace: espace,
      horsLigne: horsLigne,
      annulee: annulee,
      lectureEchouee: lectureEchouee,
      onReessayer: onReessayer,
      tutoiement: tutoiement,
      onRejoindre: horsLigne || onRejoindre == null
          ? null
          : () => onRejoindre(identite),
    );
  }

  /// L'identite du groupe puis la carte de seance, dans cet ordre. [enPile] :
  /// l'identite en pile (Mode Accessibilite, MA-4).
  List<Widget> identiteEtCarte({
    void Function(GroupSummaryVM groupe)? onRejoindre,
    bool tutoiement = false,
    bool enPile = false,
  }) => <Widget>[
    IdentiteGroupe(
      groupe: espace.identite,
      // Cote famille, une photo absente se replie sur les initiales, sans
      // pastille : « Photo a fournir » est une information interne.
      repliInitiales: espace.estCoteFamille,
      enPile: enPile,
    ),
    Ecart.vXl,
    carte(onRejoindre: onRejoindre, tutoiement: tutoiement),
  ];
}

/// Lit un groupe (identite, horloge, reseau, annulation, travail a venir) et
/// rend [construire] sur la lecture ; le chargement, l'erreur et le groupe
/// introuvable sont dits ici, une seule fois pour tous les ecrans.
class LecteurGroupe extends ConsumerWidget {
  /// Cree le lecteur.
  const LecteurGroupe({
    required this.groupeId,
    required this.construire,
    super.key,
    this.role = RoleEspaceGroupe.eleve,
  });

  /// Le groupe a lire.
  final String groupeId;

  /// Qui regarde.
  final RoleEspaceGroupe role;

  /// Ce qui se construit sur la lecture.
  final Widget Function(BuildContext context, LectureGroupe lecture) construire;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<GroupSummaryVM?> lecture = ref.watch(
      groupeProvider(groupeId),
    );

    if (lecture.hasError) {
      return EmptyState(
        message: LibellesGroupe.erreur,
        icone: AppIcons.avertissement,
        libelleAction: LibellesGroupe.reessayer,
        onAction: () => ref.invalidate(groupeProvider(groupeId)),
      );
    }

    if (!lecture.hasValue) {
      return const SqueletteGroupe();
    }

    final GroupSummaryVM? trouve = lecture.requireValue;
    if (trouve == null) {
      // `mesGroupes()` ne rend que ce que l'appelant a le droit de voir : une
      // absence n'est pas une erreur de lecture, c'est un groupe cloture ou
      // celui d'une autre classe. Un etat subi, donc aucun bouton.
      return EmptyState(
        message: LibellesGroupe.groupeIntrouvable,
        invitation: LibellesGroupe.groupeIntrouvableDetail,
        icone: AppIcons.rienAAfficher,
        registre: RegistreVide.subi,
      );
    }

    // Le temps se rafraichit par le flux du port ; l'identite du groupe, elle,
    // ne bouge pas. Tant que le flux n'a rien emis, l'horloge de la carte fait
    // foi : la page n'attend pas un tic pour s'afficher.
    final AsyncValue<SessionClockVM> flux = ref.watch(
      horlogeGroupeProvider(groupeId),
    );
    final SessionClockVM? tic = flux.value;
    final GroupSummaryVM identite = tic == null
        ? trouve
        : trouve.avecHorloge(tic);

    final PortTravailAVenir? travail = ref.watch(portTravailAVenirProvider);
    final List<SlotAction> actions =
        ref
            .watch(travailAVenirProvider((groupeId: groupeId, studentId: null)))
            .value ??
        const <SlotAction>[];
    final GroupHomeVM espace = GroupHomeVM.pourRole(
      identite: identite,
      role: role,
      // R17 : trois actions au plus.
      actions: actions.take(3).toList(),
    );

    return construire(
      context,
      LectureGroupe(
        espace: espace,
        portTravailBranche: travail != null,
        horsLigne: ref.watch(horsLigneProvider).value ?? false,
        annulee: ref.watch(seanceAnnuleeProvider(groupeId)),
        lectureEchouee: flux.hasError && tic == null,
        onReessayer: () => ref
          ..invalidate(horsLigneProvider)
          ..invalidate(horlogeGroupeProvider(groupeId)),
      ),
    );
  }
}

/// La forme de ce qui arrive : l'identite, puis la carte de seance.
class SqueletteGroupe extends StatelessWidget {
  /// Cree le squelette.
  const SqueletteGroupe({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ExcludeSemantics(child: Skeleton.tuileBento()),
        Ecart.vXl,
        SqueletteCarteSession(),
      ],
    );
  }
}

/// La page, composee par rangees (revue UX, ajustement n° 2).
///
/// Rangee 1 : [identite + seance | Avant le prochain cours] ; rangee 2 :
/// [bibliotheque | progression].
class _Colonnes extends StatelessWidget {
  const _Colonnes({
    required this.lecture,
    this.onRejoindre,
    this.onReprendreLeCours,
    this.contenuRoster,
    this.tutoiement = false,
    this.enPile = false,
  });

  final bool tutoiement;
  final bool enPile;
  final LectureGroupe lecture;
  final void Function(GroupSummaryVM groupe)? onRejoindre;
  final void Function(GroupSummaryVM groupe)? onReprendreLeCours;
  final Widget? contenuRoster;

  @override
  Widget build(BuildContext context) {
    final GroupHomeVM espace = lecture.espace;
    final GroupSummaryVM identite = espace.identite;
    final void Function(GroupSummaryVM groupe)? reprendre = onReprendreLeCours;
    final SlotRoster? roster = espace.roster;

    // R16 : contextuelle, jamais permanente. Rien a reprendre tant que la
    // seance n'a pas commence, et plus rien une fois qu'elle est close.
    final bool reprisePossible =
        !espace.estCoteFamille && (espace.horloge?.enDirect ?? false);
    final Widget? reprise = reprisePossible
        ? Align(
            alignment: AlignmentDirectional.centerStart,
            child: ActionPrincipale(
              libelle: LibellesGroupe.reprendreLeCours,
              niveau: NiveauAction.secondaire,
              pleineLargeur: false,
              onPress: reprendre == null ? null : () => reprendre(identite),
            ),
          )
        : null;

    final List<Widget> identiteEtSeance = <Widget>[
      ...lecture.identiteEtCarte(
        onRejoindre: onRejoindre,
        tutoiement: tutoiement,
        enPile: enPile,
      ),
      if (reprise != null) ...<Widget>[Ecart.vLg, reprise],
    ];
    final Widget avant = EmplacementAvantProchainCours(
      actions: espace.avantProchainCours,
      portBranche: lecture.portTravailBranche,
    );
    final Widget bibliotheque = BlocBibliotheque(
      emplacement: espace.bibliotheque,
      // Ouvre la Bibliotheque sur ce groupe : l'identifiant voyage dans
      // l'adresse, ce qui le fait survivre a un rechargement de page.
      onVoirTout: () =>
          GoRouter.of(context)
              .go(RoutesTcB.avecGroupe(espace.bibliotheque.groupeId)),
    );
    final List<Widget> secondaire = <Widget>[
      if (roster != null)
        BlocRoster(emplacement: roster, contenu: contenuRoster),
      if (roster != null && espace.progression != null) Ecart.vSection,
      if (espace.progression != null)
        BlocProgression(emplacement: espace.progression!),
    ];

    return ColonnesParRangees(
      rangees: <(List<Widget>, List<Widget>)>[
        (identiteEtSeance, <Widget>[avant]),
        (<Widget>[bibliotheque], secondaire),
      ],
    );
  }
}

/// Des rangees de deux colonnes (la principale, deux tiers ; la laterale, un
/// tiers), seulement quand la largeur utile divisee par le facteur de texte
/// atteint 840 (ajustements n° 3 et 4) ; en dessous, une colonne, dans le
/// meme ordre : la principale puis la laterale de chaque rangee. Chaque
/// rangee est un `FocusTraversalGroup` : le focus parcourt une rangee avant
/// la suivante. Partage par l'Espace Groupe et l'accueil de l'eleve adulte.
class ColonnesParRangees extends StatelessWidget {
  /// Cree la disposition.
  const ColonnesParRangees({required this.rangees, super.key});

  /// Les rangees, (principale, laterale), dans l'ordre de lecture.
  final List<(List<Widget>, List<Widget>)> rangees;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext contexte, BoxConstraints contraintes) {
        final double facteur = MediaQuery.textScalerOf(contexte).scale(1);
        final bool deuxColonnes =
            contraintes.maxWidth / facteur >= AppGabarit.seuilEtendu;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final (int i, (List<Widget>, List<Widget>) r)
                in rangees.indexed) ...<Widget>[
              if (i > 0) Ecart.vSection,
              if (deuxColonnes)
                Rangee(principale: r.$1, laterale: r.$2)
              else
                FocusTraversalGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      ...r.$1,
                      if (r.$2.isNotEmpty) ...<Widget>[Ecart.vSection, ...r.$2],
                    ],
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

/// Une rangee de deux colonnes : la principale (deux tiers) et la laterale,
/// separees de 24. Un groupe de focus.
class Rangee extends StatelessWidget {
  /// Cree la rangee.
  const Rangee({required this.principale, required this.laterale, super.key});

  /// La colonne principale.
  final List<Widget> principale;

  /// La colonne laterale.
  final List<Widget> laterale;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: principale,
            ),
          ),
          Ecart.hXxl,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: laterale,
            ),
          ),
        ],
      ),
    );
  }
}

/// L'identite du groupe, en tete de l'Espace Groupe.
///
/// La meme que sur la carte : repere de couleur **et** nom, photo obligatoire,
/// titre Sayyid ou Sayyida, cours et niveau en langage humain, capacite reelle.
/// Un groupe qui se nommerait autrement ici qu'ailleurs cesserait d'etre le
/// meme groupe aux yeux de la famille.
class IdentiteGroupe extends StatelessWidget {
  /// Cree l'identite.
  const IdentiteGroupe({
    required this.groupe,
    super.key,
    this.urlPhoto,
    this.repliInitiales = false,
    this.ligneDiscrete,
    this.typePublic,
    this.enPile = false,
  });

  /// Vrai en Mode Accessibilite (MA-4) : la photo au-dessus, le nom en
  /// dessous sur toute la largeur, qui ne passe a la ligne qu'entre les mots.
  /// La pile vient aussi seule des que le texte atteint 200 %.
  final bool enPile;

  /// Le type de groupe (« Enfants », « Adultes »), deja traduit, ajoute a la
  /// ligne de contexte cote enseignant : une information pedagogique
  /// (revue CL-4.R, m7). `null` cote famille.
  final String? typePublic;

  /// Le groupe.
  final GroupSummaryVM groupe;

  /// L'URL signee de la photo, quand l'hote sait la resoudre.
  final String? urlPhoto;

  /// Vrai cote eleve et tuteur : une photo absente devient les initiales,
  /// sans pastille « Photo a fournir » (information interne).
  final bool repliInitiales;

  /// Une ligne discrete sous l'enseignant, quand l'hote en a une : le
  /// rendez-vous hebdomadaire, cote enseignant (CL-4.4b).
  final String? ligneDiscrete;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final String? discrete = ligneDiscrete;
    final String coursEtNiveau = LibellesGroupe.joindre(
      LibellesGroupe.coursEtNiveau(
        cours: groupe.nomCours,
        niveau: groupe.niveauHumain,
      ),
      typePublic,
    );

    // Cote famille, les initiales (`AvatarTile`), jamais d'avertissement pour
    // une photo manquante ; rendu d'origine garde pour tous les roles.
    final Widget photo = repliInitiales
        ? AvatarTile(
            prenom: groupe.enseignant.nomAffichage,
            urlSignee: urlPhoto,
            diametre: AppAvatar.grand,
          )
        : PhotoEnseignant(
            enseignant: groupe.enseignant,
            urlSignee: urlPhoto,
            diametre: AppAvatar.grand,
          );
    // A 200 % (ou en Mode Accessibilite), une colonne a cote d'un grand
    // cercle couperait le nom au milieu d'un mot : la pile lui rend la
    // largeur entiere (MA-4).
    final bool pile = enPile || MediaQuery.textScalerOf(context).scale(1) >= 2;
    final Widget texte = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            LisereGroupe(jeton: groupe.couleurJeton),
            Ecart.hSm,
            Expanded(
              // En pile seulement (Mode Accessibilite ou 200 %), a
              // l'affichage : le trait d'union insecable (U+2011) garde
              // « An-Nour » entier (MA-4). Rendu standard inchange.
              child: Text(
                pile ? groupe.libelle.replaceAll('-', '‑') : groupe.libelle,
                style: textes.headlineSmall ?? const TextStyle(),
              ),
            ),
          ],
        ),
        // CLV-02 : le nom de la Classe, puis le cours et le niveau,
        // puis l'enseignant.
        if (coursEtNiveau.isNotEmpty) ...<Widget>[
          Ecart.vXs,
          Text(
            coursEtNiveau,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
        Ecart.vSm,
        // AVATAR-1 : couple avatar + nom du composant partage, nom centre
        // verticalement sur le cercle, au plus une ligne de role (le rendez-vous
        // hebdomadaire, cote enseignant). A 200 %, le nom passe a la ligne a
        // cote du cercle : plus de pile a part (MA-4).
        AvatarNom.enLigne(
          prenom: groupe.enseignant.nomAffichage,
          nom: LibellesGroupe.enseignantNomme(groupe.enseignant),
          role: (discrete != null && discrete.isNotEmpty) ? discrete : null,
          diametre: AppAvatar.grand,
          ecart: AppSpacing.lg,
          avatar: photo,
          styleNom: textes.titleSmall,
          styleRole: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
        Ecart.vSm,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            StatusPill(
              libelle: LibellesGroupe.capacitePhrase(
                membres: groupe.nombreMembres,
                seuil: groupe.seuilMax,
              ),
              ton: groupe.complet ? TonEtat.avertissement : TonEtat.neutre,
            ),
            if (!repliInitiales && groupe.enseignant.photoManquante)
              StatusPill(
                libelle: LibellesGroupe.photoManquante,
                ton: TonEtat.avertissement,
              ),
          ],
        ),
      ],
    );
    return MergeSemantics(child: texte);
  }
}
