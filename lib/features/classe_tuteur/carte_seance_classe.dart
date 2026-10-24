import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/presence/service_presence.dart';
import '../../core/presence/vue_presence.dart';
import '../../core/router/billet_salle.dart';
import '../../core/router/routes.dart';
import '../../core/seance_famille/seance_famille.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/video/pre_vol.dart' show seuilOuvertureSalle;
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/ligne_presence.dart';
import '../../core/widgets/pastille_etat_seance.dart';
import '../../core/widgets/selecteur_profils.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../accueil_famille/bloc_seance.dart';
import 'bloc_observation_classe.dart';
import 'contexte_classe.dart';

/// Le bandeau d'etat de la seance, en une ligne : ce que la seance est, et a
/// droite ce qui l'accompagne (compte a rebours, presence de l'eleve).
///
/// **Pure** : calcule depuis [AffichageSeance] (la meme fonction que l'Accueil,
/// pour que les deux ecrans disent la meme chose de la meme seance) et la
/// presence deja mise en mots.
({String gauche, String? droite, TonEtat ton}) bandeauSeance(
  AffichageSeance affichage, {
  String? presence,
}) => switch (affichage.etat) {
  EtatSeanceFamille.salleOuverte => (
    gauche: LibellesGroupe.salleOuverteCourt,
    droite: affichage.ligneEtat,
    ton: TonEtat.succes,
  ),
  EtatSeanceFamille.enDirect || EtatSeanceFamille.prolongee => (
    gauche: affichage.ligneEtat,
    droite: presence,
    ton: TonEtat.succes,
  ),
  EtatSeanceFamille.aVenir => (
    gauche: affichage.ligneEtat,
    droite: null,
    ton: TonEtat.accent,
  ),
  EtatSeanceFamille.annulee || EtatSeanceFamille.annuleeTardive => (
    gauche: affichage.ligneEtat,
    droite: null,
    ton: TonEtat.alerte,
  ),
  EtatSeanceFamille.nonTenue || EtatSeanceFamille.reportee => (
    gauche: affichage.ligneEtat,
    droite: null,
    ton: TonEtat.avertissement,
  ),
  EtatSeanceFamille.terminee || EtatSeanceFamille.horaireIncertain => (
    gauche: affichage.ligneEtat,
    droite: null,
    ton: TonEtat.neutre,
  ),
};

/// Vrai quand la salle est ouverte ou la seance en direct : la presence de
/// l'eleve se lit alors (indicative, jamais une absence deduite).
bool presenceUtile(EtatSeanceFamille etat) => switch (etat) {
  EtatSeanceFamille.salleOuverte ||
  EtatSeanceFamille.enDirect ||
  EtatSeanceFamille.prolongee => true,
  _ => false,
};

/// La carte principale de la Classe (maquette M1) : l'enseignant (photo
/// publique ou initiale, Sayyid / Sayyida), la classe et le parcours ; puis
/// la prochaine seance (bandeau d'etat, jour et heure, duree) ; puis
/// l'observation.
///
/// **Un seul rectangle** ; la seance n'est pas une carte dans la carte.
/// Telephone : surface elevee ; tablette et bureau : surface mise en avant,
/// comme la carte de l'Accueil (manifeste : seul le format change la
/// composition, jamais le theme).
class CarteSeanceClasse extends ConsumerWidget {
  /// Cree la carte.
  const CarteSeanceClasse({
    required this.contexte,
    required this.seance,
    required this.maintenantServeurUtc,
    required this.compact,
    required this.onReessayerSeance,
    super.key,
  });

  /// La classe et l'eleve.
  final ContexteClasse contexte;

  /// La prochaine seance de l'eleve dans cette classe (K2).
  final AsyncValue<SeanceFamille?> seance;

  /// L'instant serveur, `null` sans horloge serveur.
  final DateTime? maintenantServeurUtc;

  /// Vrai sur telephone.
  final bool compact;

  /// Relit la seance.
  final VoidCallback onReessayerSeance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final SeanceFamille? lue = seance.value;
    // Une seance annulee attenue la carte par sa surface (ANNUL-VIS-1).
    final bool annulee =
        lue != null &&
        AffichageSeance.depuis(
              lue,
              maintenantServeurUtc: maintenantServeurUtc,
            ).etatPastille ==
            EtatPastilleSeance.annulee;
    return AppCard(
      surface: annulee
          ? surfaceCarteSeance(palette, annulee: true)
          : compact
          ? palette.surfaceRaised
          : palette.surfaceMiseEnAvant,
      marge: compact ? AppSpacing.lg : AppSpacing.xxl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _Enseignant(classe: contexte.classe.classe, compact: compact),
          Ecart.vLg,
          ..._seance(context, ref),
        ],
      ),
    );
  }

  List<Widget> _seance(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle discret = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    if (seance.hasError) {
      return <Widget>[
        Text(t.classe.seance.illisible, style: discret),
        if (seance.error is! CapaciteIndisponible)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ActionPrincipale(
              libelle: t.commun.reessayer,
              onPress: onReessayerSeance,
              niveau: NiveauAction.tertiaire,
              pleineLargeur: false,
            ),
          ),
      ];
    }
    if (!seance.hasValue) {
      return const <Widget>[Skeleton(hauteur: AppSpacing.respiration * 2)];
    }
    final SeanceFamille? laSeance = seance.value;
    if (laSeance == null) {
      return <Widget>[
        Text(
          t.classe.seance.aucune,
          style: palette.inkStrong.applyTo(
            textes.titleMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vXs,
        Text(
          t.classe.seance.aucuneDetail(
            dePrenom: deDevant(
              contexte.eleve.prenom,
              cle: 'classe.seance.aucuneDetail',
            ),
          ),
          style: discret,
        ),
      ];
    }

    final AffichageSeance affichage = AffichageSeance.depuis(
      laSeance,
      maintenantServeurUtc: maintenantServeurUtc,
    );
    final EtatPresence? presence = presenceUtile(affichage.etat)
        ? maPresence(
            ref.watch(presenceSeanceProvider(laSeance.seanceId)).value,
            contexte.eleveId,
          )?.etat
        : null;
    final ({String gauche, String? droite, TonEtat ton}) bandeau =
        bandeauSeance(
          affichage,
          presence: presenceUtile(affichage.etat)
              ? t.classe.seance.presence(
                  prenom: contexte.eleve.prenom,
                  etat: LignePresence.libelle(presence ?? EtatPresence.inconnu),
                )
              : null,
        );

    return <Widget>[
      _Bandeau(
        gauche: bandeau.gauche,
        droite: bandeau.droite,
        ton: bandeau.ton,
        compact: compact,
        etat: affichage.etatPastille,
      ),
      Ecart.vLg,
      _Heures(
        affichage: affichage,
        compact: compact,
        annulee: affichage.etatPastille == EtatPastilleSeance.annulee,
      ),
      if (affichage.heureClasse != null) ...<Widget>[
        Ecart.vSm,
        Text(affichage.heureClasse!, style: discret),
      ],
      ..._rejoindreAvecEleve(context, laSeance, affichage.etat, discret),
      Ecart.vXl,
      BlocObservationClasse(
        classeId: contexte.classeId,
        eleveId: contexte.eleveId,
        prenom: contexte.eleve.prenom,
        seance: laSeance,
        etat: affichage.etat,
        presence: presence,
      ),
    ];
  }

  /// D6 : l'enfant rejoint la salle depuis l'appareil de son tuteur, sans
  /// appairage. Salle ouverte ou seance en direct : « Rejoindre la salle avec
  /// {prenom} », qui demande le jeton de l'eleve ; avant la porte, l'heure
  /// d'ouverture, jamais un bouton qui ne peut pas aboutir (R7). Le serveur
  /// seul decide : foyer, inscription a la seance, role eleve.
  List<Widget> _rejoindreAvecEleve(
    BuildContext context,
    SeanceFamille laSeance,
    EtatSeanceFamille etat,
    TextStyle discret,
  ) {
    switch (etat) {
      case EtatSeanceFamille.salleOuverte ||
          EtatSeanceFamille.enDirect ||
          EtatSeanceFamille.prolongee:
        return <Widget>[
          Ecart.vXl,
          ActionPrincipale(
            libelle: t.classe.seance.rejoindreAvec(
              prenom: contexte.eleve.prenom,
            ),
            onPress: () => GoRouter.of(context).push(
              Routes.salle,
              extra: BilletSalle(
                sessionId: laSeance.seanceId,
                emisA: DateTime.now(),
                groupeId: laSeance.groupeId,
                eleveId: contexte.eleveId,
                interfaceGuidee: contexte.eleve.mode == InterfaceMode.enfant,
              ),
            ),
          ),
        ];
      case EtatSeanceFamille.aVenir:
        final DateTime ouverture = laSeance.debutUtc.subtract(
          laSeance.fenetre?.fenetreAcces ?? seuilOuvertureSalle,
        );
        return <Widget>[
          Ecart.vSm,
          Text(
            t.classe.seance.salleOuvreA(
              heure: heureDeLAppareil(ouverture.toLocal()),
            ),
            style: discret,
          ),
        ];
      case EtatSeanceFamille.terminee ||
          EtatSeanceFamille.annulee ||
          EtatSeanceFamille.annuleeTardive ||
          EtatSeanceFamille.nonTenue ||
          EtatSeanceFamille.reportee ||
          EtatSeanceFamille.horaireIncertain:
        return const <Widget>[];
    }
  }
}

/// L'enseignant et la classe : photo publique de l'enseignant (DB-CRS-09 :
/// son initiale tant qu'aucun service ne resout la photo, jamais le portrait
/// de l'eleve), nom de la classe, « Sayyid / Sayyida » et prenom, parcours.
class _Enseignant extends StatelessWidget {
  const _Enseignant({required this.classe, required this.compact});

  final GroupSummaryVM classe;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String parcours = LibellesGroupe.coursEtNiveau(
      cours: classe.nomCours,
      niveau: classe.niveauHumain,
    );
    // AVATAR-1 : le nom de la classe est le titre ; l'enseignant est un couple
    // avatar + nom du composant partage, avec au plus une ligne de role (le
    // parcours).
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // `nomClasseInsecable` garde « An-Nour » entier : a 320 px en
          // texte x2, « Classe An- / Nour » passait a la ligne dans le nom.
          Text(
            nomClasseInsecable(classe.libelle),
            style: palette.inkStrong.applyTo(
              (compact ? textes.titleMedium : textes.titleLarge) ??
                  const TextStyle(),
            ),
          ),
          Ecart.vSm,
          AvatarNom.enLigne(
            prenom: classe.enseignant.nomAffichage,
            nom: LibellesGroupe.enseignantNomme(classe.enseignant),
            pays: classe.enseignant.pays,
            role: parcours.isEmpty ? null : parcours,
            diametre: SelecteurProfils.diametreLarge,
            styleNom: palette.inkMuted.applyTo(
              textes.bodyLarge ?? const TextStyle(),
            ),
            styleRole: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Le bandeau d'etat pleine largeur : un point, l'etat, et a droite ce qui
/// l'accompagne. Le point double toujours un mot (jamais la couleur seule).
class _Bandeau extends StatelessWidget {
  const _Bandeau({
    required this.gauche,
    required this.droite,
    required this.ton,
    required this.compact,
    this.etat,
  });

  /// L'etat de seance a reconnaitre d'un coup d'oeil, ou `null`.
  final EtatPastilleSeance? etat;
  final String gauche;
  final String? droite;
  final TonEtat ton;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppColorPair paire = palette.paireDe(ton);
    final EtatPastilleSeance? seance = etat;
    if (seance != null) {
      // « En direct » et « Annulee » : le composant partage, jamais un point
      // de couleur et un mot posés a la main (ON-AIR-1, ANNUL-VIS-1).
      final bool annulee = seance == EtatPastilleSeance.annulee;
      return MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                // Annulee : le mot de la pastille, puis la raison dessous.
                PastilleEtatSeance(
                  etat: seance,
                  libelle: annulee ? null : gauche,
                ),
                if (droite != null)
                  Text(
                    droite!,
                    style: palette.inkMuted.applyTo(
                      AppTypography.tabulaire(
                        (compact ? textes.bodySmall : textes.bodyMedium) ??
                            const TextStyle(),
                      ),
                    ),
                  ),
              ],
            ),
            if (annulee) ...<Widget>[
              Ecart.vSm,
              LigneRaisonSeance(raison: gauche),
            ],
          ],
        ),
      );
    }
    final BoxDecoration point = switch (ton) {
      TonEtat.succes => palette.pointsStatut.succes.pastille(),
      TonEtat.avertissement => palette.pointsStatut.attention.pastille(),
      TonEtat.alerte => palette.pointsStatut.alerte.pastille(),
      TonEtat.neutre => palette.pointsStatut.neutre.pastille(),
      TonEtat.accent => BoxDecoration(
        shape: BoxShape.circle,
        color: palette.surfacePrimary.background,
      ),
    };
    final TextStyle styleGauche = paire.applyTo(
      AppTypography.tabulaire(
        (compact ? textes.labelLarge : textes.titleSmall) ?? const TextStyle(),
      ),
    );
    return MergeSemantics(
      child: DecoratedBox(
        decoration: paire.decoration(borderRadius: AppRadius.arrondiSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          // Le point reste sur la premiere ligne de l'etat : quand
          // l'accompagnement passe dessous (320 px, texte x2), il n'est pas
          // centre entre les deux lignes (COM-RC tour 7, lot L).
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: _hauteurLigne(context, styleGauche),
                child: Center(
                  child: SizedBox.square(
                    dimension: StatusPill.diametrePastille,
                    child: DecoratedBox(decoration: point),
                  ),
                ),
              ),
              Ecart.hSm,
              // L'etat au debut, l'accompagnement au bout de la ligne ; quand
              // les deux ne tiennent pas (texte agrandi, colonne etroite),
              // l'accompagnement passe dessous, sans rien couper.
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: <Widget>[
                    Text(gauche, style: styleGauche),
                    if (droite != null)
                      Text(
                        droite!,
                        style: paire.applyTo(
                          AppTypography.tabulaire(
                            (compact ? textes.bodySmall : textes.bodyMedium) ??
                                const TextStyle(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Jour et heure, puis duree, en deux colonnes a medaillon separees par un
/// filet vertical (M1). L'heure est celle rendue par le serveur dans le
/// fuseau du foyer ; sans horloge serveur, celle de l'appareil, **dite comme
/// telle** (jamais un fuseau devine).
class _Heures extends StatelessWidget {
  const _Heures({
    required this.affichage,
    required this.compact,
    this.annulee = false,
  });

  /// Vrai quand la seance est annulee : l'heure est barree.
  final bool annulee;
  final AffichageSeance affichage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final String valeurHeure = affichage.ville == null
        ? affichage.heure
        : LibellesGroupe.heureEtVille(
            heure: affichage.heure,
            ville: affichage.ville!,
          );
    final String? complement = affichage.ville == null
        ? affichage.fuseau
        : null;
    // « 4 octobre » reste sur une ligne quand il y tient : jamais « 4 » seul
    // en fin de ligne, loin de son mois (COM-RC tour 7, lot L).
    Widget colonneHeure(String date) => _Colonne(
      icone: AppIcons.journee,
      libelle: date,
      valeur: valeurHeure,
      complement: complement,
      compact: compact,
      annulee: annulee,
    );
    final Widget duree = _Colonne(
      icone: AppIcons.horloge,
      libelle: LibellesGroupe.dureeLibelle,
      valeur: affichage.duree,
      compact: compact,
    );
    final ({TextStyle discret, TextStyle valeur}) styles = _Colonne.styles(
      context,
      compact: compact,
    );
    final TextScaler echelle = MediaQuery.textScalerOf(context);
    final double filet = palette.contourCarte.asBorderSide().width;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        // Deux colonnes seulement si chaque mot y tient entier, mesure sur la
        // largeur REELLE du texte de chaque colonne (le medaillon et son
        // ecart ; a droite, en plus, le filet et ses deux marges) ; sinon la
        // duree passe sous l'heure, sans filet : a 320 px en texte x2, la
        // demi-colonne coupait « Diman/che », « Duré/e » et « 14:1/0 »
        // (COM-RC tour 7, lot L), comme le bloc seance de l'Accueil.
        bool tient(String? texte, TextStyle style, double largeur) =>
            texte == null ||
            largeurMotLePlusLong(context, texte, style, echelle) <= largeur;
        // La duree tient sur UNE ligne : « 45 / min » se lisait mal.
        bool tientSurUneLigne(String texte, TextStyle style, double largeur) =>
            _largeurSurUneLigne(context, texte, style) <= largeur;
        final double demi = c.maxWidth / 2;
        final double texteGauche = demi - _Colonne.retrait;
        final double texteDroite =
            demi - AppSpacing.md * 2 - filet - _Colonne.retrait;
        final String dateEnColonne = nombresLiesSiTient(
          context,
          affichage.date,
          styles.discret,
          texteGauche,
        );
        final bool deuxColonnes =
            tient(dateEnColonne, styles.discret, texteGauche) &&
            tient(valeurHeure, styles.valeur, texteGauche) &&
            tient(complement, styles.discret, texteGauche) &&
            tientSurUneLigne(
              LibellesGroupe.dureeLibelle,
              styles.discret,
              texteDroite,
            ) &&
            tientSurUneLigne(affichage.duree, styles.valeur, texteDroite);
        if (!deuxColonnes) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              colonneHeure(
                nombresLiesSiTient(
                  context,
                  affichage.date,
                  styles.discret,
                  c.maxWidth - _Colonne.retrait,
                ),
              ),
              Ecart.vMd,
              duree,
            ],
          );
        }
        final Widget heure = colonneHeure(dateEnColonne);
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: heure),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.md,
                  ),
                  // Le filet vertical, comme les autres separateurs
                  // (`contourCarte`), jamais plus fonce (manifeste, bloc
                  // seance).
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: BorderDirectional(
                        start: palette.contourCarte.asBorderSide(),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: AppSpacing.md,
                      ),
                      child: duree,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Colonne extends StatelessWidget {
  const _Colonne({
    required this.icone,
    required this.libelle,
    required this.valeur,
    required this.compact,
    this.complement,
    this.annulee = false,
  });

  /// Vrai quand la valeur est l'heure d'une seance annulee : barree.
  final bool annulee;
  final AppIcon icone;
  final String libelle;
  final String valeur;
  final String? complement;
  final bool compact;

  /// Ce que le medaillon et son ecart prennent a la largeur du texte.
  static const double retrait = AppSpacing.section + AppSpacing.sm;

  /// Le style du libelle et celui de la valeur. Tablette et bureau : le
  /// corps a 14 et la valeur a 22 (manifeste, typographie : legende et
  /// chiffre d'horaire du bureau).
  static ({TextStyle discret, TextStyle valeur}) styles(
    BuildContext context, {
    required bool compact,
  }) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return (
      discret: palette.inkMuted.applyTo(
        (compact ? textes.bodySmall : textes.bodyMedium) ?? const TextStyle(),
      ),
      valeur: AppTypography.tabulaire(
        palette.inkStrong.applyTo(
          (compact ? textes.titleMedium : textes.titleLarge) ??
              const TextStyle(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ({TextStyle discret, TextStyle valeur}) style = styles(
      context,
      compact: compact,
    );
    final TextStyle discret = style.discret;
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ExcludeSemantics(
            child: SizedBox.square(
              dimension: AppSpacing.section,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.washAccent.background,
                ),
                child: Center(
                  child: IconTheme(
                    data: palette.inkAccent.asIconTheme(size: AppSpacing.xl),
                    child: Icon(icone.repos),
                  ),
                ),
              ),
            ),
          ),
          Ecart.hSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(libelle, style: discret),
                TexteHeureSeance(
                  heure: valeur,
                  annulee: annulee,
                  style: style.valeur,
                ),
                if (complement != null) Text(complement!, style: discret),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// La largeur de [texte] sur une seule ligne, au [style] donne et a
/// l'echelle de texte de [context].
double _largeurSurUneLigne(
  BuildContext context,
  String texte,
  TextStyle style,
) => _peindre(context, texte, style).width;

/// La hauteur d'une ligne de texte au [style] donne, a l'echelle de texte de
/// [context] : la place du point d'etat a cote de la premiere ligne.
double _hauteurLigne(BuildContext context, TextStyle style) =>
    _peindre(context, 'Hg', style).height;

/// Mesure [texte] sur une ligne, comme `Text` le rendrait ici.
Size _peindre(BuildContext context, String texte, TextStyle style) {
  final TextPainter peintre = TextPainter(
    text: TextSpan(
      text: texte,
      style: DefaultTextStyle.of(context).style.merge(style),
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    locale: Localizations.maybeLocaleOf(context),
    maxLines: 1,
  )..layout();
  final Size taille = peintre.size;
  peintre.dispose();
  return taille;
}
