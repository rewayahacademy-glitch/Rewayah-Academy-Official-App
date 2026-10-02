// CLV-03, PRE-ENS-01 : la preparation technique de l'enseignant (CL-4.5).
//
// Document du directeur §6 et §12, spec 02 CLV-03, regles R8 a R13 et R19.
// Le calcul du blocage n'est PAS refait ici : il vient de `VuePreCours.depuis`
// (le micro est la seule impasse, la camera ne bloque jamais).

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/video/pre_vol.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/lien_fleche.dart';
import '../tc_classe_live/pre_vol_classe.dart';
import 'vue_salle.dart';

/// L'etat de la connexion, lu sans second moteur de mesure (R12).
enum ReseauPreparation {
  /// Connexion utilisable.
  bonne,

  /// Connexion utilisable, mais instable : l'audio sera prioritaire.
  instable,

  /// Aucune connexion.
  horsLigne,
}

/// Une seance qu'on ne peut pas preparer.
enum IssuePreparation {
  /// La seance est terminee.
  terminee,

  /// La seance n'est pas attribuee a cet enseignant.
  nonAssignee,
}

/// Le contexte pedagogique de la seance (document §6.1). Chaque champ absent
/// est simplement omis : pas de tiret, pas de valeur inventee.
@immutable
class ContextePreparation {
  /// Cree le contexte.
  const ContextePreparation({
    this.classe,
    this.debut,
    this.support,
    this.reprise,
    this.eleves,
  });

  /// Nom de la classe.
  final String? classe;

  /// Temps avant le debut, deja formate.
  final String? debut;

  /// Support prevu.
  final String? support;

  /// Position de reprise.
  final String? reprise;

  /// Eleves attendus, deja formate.
  final String? eleves;
}

/// Seuil des deux volets : largeur utile divisee par le facteur de texte.
const double seuilDeuxVolets = 840;

/// La preparation de l'enseignant.
///
/// Chaque ligne d'equipement evolue seule : [reseau] et [resultat] valent
/// `null` tant que leur verification n'a pas rendu.
class PreparationEnseignant extends StatefulWidget {
  /// Cree la preparation.
  const PreparationEnseignant({
    required this.resultat,
    required this.reseau,
    required this.contexte,
    required this.onEntrer,
    required this.onRetour,
    required this.onReessayer,
    super.key,
    this.sortieAudioChoisissable = false,
    this.issue,
    this.onOuvrirReglages,
    this.onTesterCamera,
    this.onModifierPeripheriques,
    this.onRetourJournee,
  });

  /// Le materiel mesure, `null` pendant la verification.
  final ResultatPreVol? resultat;

  /// La connexion, `null` pendant la verification.
  final ReseauPreparation? reseau;

  /// La plateforme permet-elle de choisir la sortie audio ? Sinon la ligne
  /// n'existe pas (R10 : aucun faux controle inerte).
  final bool sortieAudioChoisissable;

  /// Le contexte de la seance.
  final ContextePreparation contexte;

  /// Une seance terminee ou non attribuee.
  final IssuePreparation? issue;

  /// Entre dans la classe.
  final VoidCallback onEntrer;

  /// Revient a la Classe.
  final VoidCallback onRetour;

  /// Remesure le materiel.
  final VoidCallback onReessayer;

  /// Ouvre les reglages systeme, quand une vraie action existe.
  final VoidCallback? onOuvrirReglages;

  /// Test local de la camera. Aucune camera n'est ouverte d'elle-meme.
  final VoidCallback? onTesterCamera;

  /// Change de peripherique, quand une vraie action existe.
  final VoidCallback? onModifierPeripheriques;

  /// Revient a la journee (seance non attribuee).
  final VoidCallback? onRetourJournee;

  @override
  State<PreparationEnseignant> createState() => _PreparationEnseignantEtat();
}

class _PreparationEnseignantEtat extends State<PreparationEnseignant> {
  bool _testCameraFait = false;

  /// « Tester la camera » n'existe que si un vrai test est branche (R10) :
  /// sans [PreparationEnseignant.onTesterCamera], ni bouton ni « Test local
  /// termine ».
  void _testerCamera() {
    final VoidCallback? tester = widget.onTesterCamera;
    if (tester == null) return;
    tester();
    setState(() => _testCameraFait = true);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final double facteur = MediaQuery.textScalerOf(context).scale(1);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        final bool bureau = contraintes.maxWidth / facteur >= seuilDeuxVolets;
        final double gouttiere = bureau
            ? AppPage.gouttiereDesktop
            : AppPage.gouttiereMobile;
        final Widget contenu = widget.issue == null
            ? _preparation(context, bureau, textes, palette)
            : _issue(widget.issue!, textes, palette);
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: gouttiere,
            vertical: AppSpacing.xxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: bureau
                    ? AppPage.largeurLecture
                    : AppPage.largeurFormulaire,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: LienFleche(
                      key: const ValueKey<String>('preparation-retour'),
                      libelle: t.salle.preparation.retour,
                      icone: AppIcons.retour,
                      fleche: false,
                      onPress: widget.onRetour,
                    ),
                  ),
                  Ecart.vMd,
                  Semantics(
                    header: true,
                    child: Text(
                      t.salle.preparation.titre,
                      style: palette.inkStrong.applyTo(
                        textes.headlineSmall ?? const TextStyle(),
                      ),
                    ),
                  ),
                  Ecart.vXxl,
                  contenu,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _issue(IssuePreparation issue, TextTheme textes, AppPalette palette) {
    final bool terminee = issue == IssuePreparation.terminee;
    final VoidCallback? retourJournee = widget.onRetourJournee;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              terminee
                  ? t.salle.preparation.terminee
                  : t.salle.preparation.nonAssignee,
              style: palette.inkStrong.applyTo(
                textes.bodyLarge ?? const TextStyle(),
              ),
            ),
          ),
          if (!terminee && retourJournee != null) ...<Widget>[
            Ecart.vLg,
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: IntrinsicWidth(
                child: ActionPrincipale(
                  libelle: t.salle.preparation.retourJournee,
                  onPress: retourJournee,
                  niveau: NiveauAction.secondaire,
                  pleineLargeur: false,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _preparation(
    BuildContext context,
    bool bureau,
    TextTheme textes,
    AppPalette palette,
  ) {
    final ResultatPreVol? resultat = widget.resultat;
    final VuePreCours vue = VuePreCours.depuis(
      role: RoleSalle.enseignant,
      resultat: resultat,
    );
    final ReseauPreparation? reseau = widget.reseau;
    final bool peutEntrer =
        resultat != null &&
        !vue.bloque &&
        reseau != null &&
        reseau != ReseauPreparation.horsLigne;
    // Un blocage deja connu garde son bouton desactive avec sa raison ecrite
    // au-dessus (revue UX n° 12 d) ; sinon, la verification est une ligne.
    final bool enVerification =
        !vue.bloque && (resultat == null || reseau == null);

    final Widget apercu = _Apercu(
      compact: !bureau,
      testable:
          widget.onTesterCamera != null &&
          (resultat?.cameraDisponible ?? false),
      testFait: _testCameraFait,
      onTester: _testerCamera,
    );
    final Widget equipement = _Equipement(
      resultat: resultat,
      vue: vue,
      reseau: reseau,
      sortieAudio: widget.sortieAudioChoisissable,
      onModifier: widget.onModifierPeripheriques,
    );

    final String? raison = switch (vue.motif) {
      MotifPreCours.microAbsent => t.salle.preparation.microAbsentRaison,
      MotifPreCours.permissionRefusee => t.salle.preparation.permissionRefusee,
      null => switch (reseau) {
        ReseauPreparation.instable => t.salle.preparation.reseauFaible,
        ReseauPreparation.horsLigne => t.salle.secours.horsLigne,
        _ => null,
      },
    };
    final VoidCallback? reglages = widget.onOuvrirReglages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (bureau)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: apercu),
              Ecart.hXxl,
              Expanded(child: equipement),
            ],
          )
        else ...<Widget>[apercu, Ecart.vLg, equipement],
        Ecart.vXxl,
        _Contexte(contexte: widget.contexte),
        if (raison != null) ...<Widget>[
          Ecart.vLg,
          Semantics(
            liveRegion: true,
            child: Text(
              raison,
              key: const ValueKey<String>('preparation-raison'),
              style: palette.inkStrong.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
        if (vue.bloque) ...<Widget>[
          Ecart.vSm,
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              if (vue.motif == MotifPreCours.permissionRefusee &&
                  reglages != null)
                IntrinsicWidth(
                  child: ActionPrincipale(
                    libelle: t.salle.preparation.ouvrirReglages,
                    onPress: reglages,
                    niveau: NiveauAction.secondaire,
                    pleineLargeur: false,
                  ),
                ),
              IntrinsicWidth(
                child: ActionPrincipale(
                  libelle: t.salle.preparation.reessayer,
                  onPress: widget.onReessayer,
                  niveau: NiveauAction.tertiaire,
                  pleineLargeur: false,
                ),
              ),
            ],
          ),
        ],
        Ecart.vLg,
        // Pendant la verification, l'emplacement du bouton porte une ligne
        // d'etat (patron R4) : jamais un bouton grise sans raison ecrite.
        if (enVerification)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppPage.hauteurBouton),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Semantics(
                liveRegion: true,
                child: MergeSemantics(
                  child: Row(
                    key: const ValueKey<String>('preparation-verification'),
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const IconeEtatPreparation(
                        ton: TonPreparation.verification,
                      ),
                      Ecart.hSm,
                      Flexible(
                        child: Text(
                          t.salle.preparation.verification,
                          style: palette.inkMuted.applyTo(
                            textes.bodyMedium ?? const TextStyle(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: bureau
                ? IntrinsicWidth(
                    child: ActionPrincipale(
                      key: const ValueKey<String>('preparation-entrer'),
                      libelle: t.salle.preparation.entrer,
                      onPress: peutEntrer ? widget.onEntrer : null,
                      pleineLargeur: !bureau,
                    ),
                  )
                : ActionPrincipale(
                    key: const ValueKey<String>('preparation-entrer'),
                    libelle: t.salle.preparation.entrer,
                    onPress: peutEntrer ? widget.onEntrer : null,
                    pleineLargeur: !bureau,
                  ),
          ),
      ],
    );
  }
}

/// L'apercu media, toujours coupe a l'ouverture (R8, point 16).
class _Apercu extends StatelessWidget {
  const _Apercu({
    required this.compact,
    required this.testable,
    required this.testFait,
    required this.onTester,
  });

  final bool compact;
  final bool testable;
  final bool testFait;
  final VoidCallback onTester;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: compact ? 96 : 200),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ExcludeSemantics(
                    child: IconTheme(
                      data: palette.inkMuted.asIconTheme(size: AppSpacing.xxxl),
                      child: Icon(AppIcons.cameraCoupee.repos),
                    ),
                  ),
                  Ecart.vSm,
                  Text(
                    t.salle.preparation.cameraCoupee,
                    textAlign: TextAlign.center,
                    style: palette.inkMuted.applyTo(
                      textes.bodyMedium ?? const TextStyle(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (testable) ...<Widget>[
            Ecart.vMd,
            if (testFait) ...<Widget>[
              Semantics(
                liveRegion: true,
                child: Text(
                  t.salle.preparation.testCameraFait,
                  style: palette.inkMuted.applyTo(
                    textes.bodySmall ?? const TextStyle(),
                  ),
                ),
              ),
              Ecart.vSm,
            ],
            // BTN-TESTER-1 : le bouton occupe toute la largeur de sa carte, en
            // bas, contenu centre (K-54) : la carte est une colonne etiree.
            ActionPrincipale(
              key: const ValueKey<String>('preparation-tester-camera'),
              libelle: t.salle.preparation.testerCamera,
              onPress: onTester,
              niveau: NiveauAction.secondaire,
            ),
          ],
        ],
      ),
    );
  }
}

/// « Votre equipement » : une ligne par verification, chacune avec son etat.
class _Equipement extends StatelessWidget {
  const _Equipement({
    required this.resultat,
    required this.vue,
    required this.reseau,
    required this.sortieAudio,
    required this.onModifier,
  });

  final ResultatPreVol? resultat;
  final VuePreCours vue;
  final ReseauPreparation? reseau;
  final bool sortieAudio;
  final VoidCallback? onModifier;

  @override
  Widget build(BuildContext context) {
    final ResultatPreVol? r = resultat;
    final String verif = t.salle.preparation.verification;

    final (String, TonPreparation) connexion = switch (reseau) {
      null => (verif, TonPreparation.verification),
      ReseauPreparation.bonne => (
        t.salle.preparation.connexionPrete,
        TonPreparation.ok,
      ),
      ReseauPreparation.instable => (
        t.salle.preparation.connexionInstable,
        TonPreparation.attention,
      ),
      ReseauPreparation.horsLigne => (
        t.salle.preparation.connexionInstable,
        TonPreparation.bloque,
      ),
    };
    final (String, TonPreparation) micro = r == null
        ? (verif, TonPreparation.verification)
        : vue.motif == MotifPreCours.permissionRefusee
        ? (t.salle.preparation.microBloque, TonPreparation.bloque)
        : vue.microPresent
        ? (t.salle.preparation.microPret, TonPreparation.ok)
        : (t.salle.preparation.microAbsent, TonPreparation.bloque);
    final (String, TonPreparation) sortie = r == null
        ? (verif, TonPreparation.verification)
        : (t.salle.preparation.sortieSysteme, TonPreparation.ok);
    final (String, TonPreparation) camera = r == null
        ? (verif, TonPreparation.verification)
        : vue.cameraPresente
        ? (t.salle.preparation.cameraPrete, TonPreparation.ok)
        : (t.salle.preparation.cameraAbsente, TonPreparation.attention);

    LigneRubrique ligne(
      String cle,
      AppIcon icone,
      String libelle,
      (String, TonPreparation) etat,
    ) => LigneRubrique(
      icone: icone,
      libelle: libelle,
      legende: etat.$1,
      controle: KeyedSubtree(
        key: ValueKey<String>('etat-$cle-${etat.$2.name}'),
        child: IconeEtatPreparation(ton: etat.$2),
      ),
    );

    final VoidCallback? modifier = onModifier;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        GroupeReglages(
          titre: t.salle.preparation.equipement,
          lignes: <LigneRubrique>[
            ligne(
              'connexion',
              AppIcons.reseau,
              t.salle.preparation.connexion,
              connexion,
            ),
            ligne('micro', AppIcons.micro, t.salle.preparation.micro, micro),
            if (sortieAudio)
              ligne(
                'sortie',
                AppIcons.micro,
                t.salle.preparation.sortieAudio,
                sortie,
              ),
            ligne(
              'camera',
              AppIcons.camera,
              t.salle.preparation.camera,
              camera,
            ),
          ],
        ),
        if (modifier != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: LienFleche(
              libelle: t.salle.preparation.modifierPeripheriques,
              onPress: modifier,
            ),
          ),
      ],
    );
  }
}

/// Le ton d'une ligne de preparation (enseignant et eleve).
enum TonPreparation {
  /// Verification en cours.
  verification,

  /// Tout va bien.
  ok,

  /// A surveiller, jamais bloquant.
  attention,

  /// Bloque.
  bloque,
}

/// L'icone d'un etat. Le texte de la legende porte le sens : l'icone est
/// exclue de la semantique, et n'est jamais la seule marque (W-141).
class IconeEtatPreparation extends StatelessWidget {
  /// Cree l'icone.
  const IconeEtatPreparation({required this.ton, super.key});

  /// Le ton montre.
  final TonPreparation ton;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final (AppIcon icone, AppInkColor couleur) = switch (ton) {
      TonPreparation.verification => (AppIcons.attente, palette.inkMuted),
      TonPreparation.ok => (AppIcons.succes, palette.inkAccent),
      TonPreparation.attention => (AppIcons.avertissement, palette.inkMuted),
      TonPreparation.bloque => (AppIcons.avertissement, palette.inkStrong),
    };
    return ExcludeSemantics(
      child: IconTheme(
        data: couleur.asIconTheme(size: AppSpacing.xxl),
        child: Icon(icone.repos),
      ),
    );
  }
}

/// « Contexte de la seance » : Classe, debut, support, reprise, eleves
/// attendus (document §6.1). Une ligne = un seul noeud semantique.
class _Contexte extends StatelessWidget {
  const _Contexte({required this.contexte});

  final ContextePreparation contexte;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final List<(String, String)> lignes = <(String, String)>[
      for (final (String libelle, String? valeur) in <(String, String?)>[
        (t.salle.preparation.classe, contexte.classe),
        (t.salle.preparation.debut, contexte.debut),
        (t.salle.preparation.support, contexte.support),
        (t.salle.preparation.reprise, contexte.reprise),
        (t.salle.preparation.eleves, contexte.eleves),
      ])
        if (valeur != null && valeur.trim().isNotEmpty)
          (libelle, valeur.trim()),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              t.salle.preparation.contexte,
              style: palette.inkStrong.applyTo(
                textes.titleMedium ?? const TextStyle(),
              ),
            ),
          ),
          for (final (String libelle, String valeur) in lignes) ...<Widget>[
            Ecart.vMd,
            MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    libelle,
                    style: palette.inkMuted.applyTo(
                      textes.bodySmall ?? const TextStyle(),
                    ),
                  ),
                  Text(
                    valeur,
                    style: palette.inkStrong.applyTo(
                      textes.bodyMedium ?? const TextStyle(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
