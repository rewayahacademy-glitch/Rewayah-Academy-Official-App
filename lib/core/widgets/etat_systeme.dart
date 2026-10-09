import 'package:flutter/material.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_elevation.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'action_principale.dart';
import 'ecran_resultat.dart';
import 'status_pill.dart';

/// La nature d'un etat systeme (mandat Tuteur V1 section 8, contrat K5).
///
/// « Suspendu » n'y figure pas : la porte `PorteAcces.suspendu` renvoie deja
/// vers `/attente`, qui dit le statut exact ; [dossierEnAttente] ne sert
/// qu'aux blocs internes.
enum NatureEtat {
  /// La reponse tarde : on le dit, sans encore parler d'echec.
  chargementProlonge,

  /// L'appareil n'a pas de reseau.
  horsLigne,

  /// Une nouvelle tentative de connexion est en cours.
  reconnexion,

  /// La lecture a echoue, ou n'a pas repondu a temps.
  echecServeur,

  /// La page ou la ressource n'existe pas (404).
  introuvable,

  /// Le compte n'a pas acces a ce contenu.
  accesRefuse,

  /// La session a pris fin.
  sessionExpiree,

  /// Le dossier du titulaire attend une etape.
  dossierEnAttente,

  /// Rien ne correspond : liste vide, filtres trop serres.
  aucunResultat,

  /// Une autorisation de l'appareil a ete refusee (camera, notifications).
  permissionRefusee,

  /// La ressource a ete retiree ou son acces a pris fin.
  ressourceExpiree,

  /// La capacite n'existe pas encore (`CapaciteIndisponible`) : ni un echec,
  /// ni un vide. Elle ne se reessaie pas.
  indisponible,
}

/// Ou l'etat s'affiche.
enum PorteeEtat {
  /// Dans un bloc de la page : le reste de la page reste en place.
  bloc,

  /// A la place de toute la page : grammaire de l'ecran resultat (M5).
  page,
}

/// Un etat systeme : un titre humain, une phrase utile, une action
/// principale, eventuellement un lien secondaire, **aucun code technique**
/// (mandat section 8).
///
/// Le titre et la phrase ont une valeur par defaut par [NatureEtat]
/// (`commun.etats.*`) ; un ecran ne les remplace que pour dire plus juste,
/// jamais pour dire autre chose. L'action n'est rendue qu'avec son geste
/// ([onAction]) ; son libelle par defaut suit la nature (« Reessayer »,
/// « Retour a l'accueil », « Se reconnecter »...).
///
/// [dependance] nomme ce qui manque (`DB-xxx`, `LOT-x`) pour la trace et les
/// tests : **il n'est jamais affiche**, ni lu par le lecteur d'ecran.
class EtatSysteme extends StatelessWidget {
  /// Cree un etat systeme.
  const EtatSysteme({
    required this.nature,
    super.key,
    this.portee = PorteeEtat.bloc,
    this.titre,
    this.phrase,
    this.libelleAction,
    this.onAction,
    this.actionEnCours = false,
    this.libelleSecondaire,
    this.onSecondaire,
    this.dependance,
    this.icone,
  });

  /// La nature de l'etat.
  final NatureEtat nature;

  /// Bloc ou page.
  final PorteeEtat portee;

  /// Le titre, s'il doit etre plus precis que celui de la nature.
  final String? titre;

  /// La phrase, si elle doit etre plus precise que celle de la nature.
  final String? phrase;

  /// Le libelle de l'action, s'il differe de celui de la nature.
  final String? libelleAction;

  /// L'action. Sans elle, aucun bouton n'est rendu.
  final VoidCallback? onAction;

  /// Vrai pendant que l'action aboutit (une nouvelle tentative en cours).
  final bool actionEnCours;

  /// Le libelle du lien secondaire.
  final String? libelleSecondaire;

  /// Le lien secondaire. Sans lui, aucun lien n'est rendu.
  final VoidCallback? onSecondaire;

  /// L'identifiant de ce qui manque, pour la trace et les tests seulement.
  final String? dependance;

  /// L'icone, si elle doit differer de celle de la nature : le bloc d'une
  /// page hors ligne qui ne peut rien afficher ne repose pas le « wifi
  /// barre » que le bandeau porte deja (EA-HL-DOUBLE-1).
  final AppIcon? icone;

  /// Le titre et la phrase par defaut d'une nature.
  static ({String titre, String phrase}) textesPar(NatureEtat nature) {
    // Type infere : les classes generees par slang portent des `$`.
    final e = t.commun.etats;
    return switch (nature) {
      NatureEtat.chargementProlonge => (
        titre: e.chargementProlonge.titre,
        phrase: e.chargementProlonge.phrase,
      ),
      NatureEtat.horsLigne => (
        titre: e.horsLigne.titre,
        phrase: e.horsLigne.phrase,
      ),
      NatureEtat.reconnexion => (
        titre: e.reconnexion.titre,
        phrase: e.reconnexion.phrase,
      ),
      NatureEtat.echecServeur => (
        titre: e.echecServeur.titre,
        phrase: e.echecServeur.phrase,
      ),
      NatureEtat.introuvable => (
        titre: e.introuvable.titre,
        phrase: e.introuvable.phrase,
      ),
      NatureEtat.accesRefuse => (
        titre: e.accesRefuse.titre,
        phrase: e.accesRefuse.phrase,
      ),
      NatureEtat.sessionExpiree => (
        titre: e.sessionExpiree.titre,
        phrase: e.sessionExpiree.phrase,
      ),
      NatureEtat.dossierEnAttente => (
        titre: e.dossierEnAttente.titre,
        phrase: e.dossierEnAttente.phrase,
      ),
      NatureEtat.aucunResultat => (
        titre: e.aucunResultat.titre,
        phrase: e.aucunResultat.phrase,
      ),
      NatureEtat.permissionRefusee => (
        titre: e.permissionRefusee.titre,
        phrase: e.permissionRefusee.phrase,
      ),
      NatureEtat.ressourceExpiree => (
        titre: e.ressourceExpiree.titre,
        phrase: e.ressourceExpiree.phrase,
      ),
      NatureEtat.indisponible => (
        titre: e.indisponible.titre,
        phrase: e.indisponible.phrase,
      ),
    };
  }

  /// Le libelle d'action par defaut d'une nature.
  static String libelleActionPar(NatureEtat nature) {
    final a = t.commun.etats.actions;
    return switch (nature) {
      NatureEtat.chargementProlonge ||
      NatureEtat.horsLigne ||
      NatureEtat.reconnexion ||
      NatureEtat.echecServeur ||
      NatureEtat.indisponible => a.reessayer,
      NatureEtat.introuvable || NatureEtat.accesRefuse => a.retourAccueil,
      NatureEtat.sessionExpiree => a.seReconnecter,
      NatureEtat.dossierEnAttente => a.voirDossier,
      NatureEtat.aucunResultat => a.reinitialiserFiltres,
      NatureEtat.permissionRefusee || NatureEtat.ressourceExpiree => a.revenir,
    };
  }

  /// L'icone d'une nature.
  static AppIcon iconePar(NatureEtat nature) => switch (nature) {
    NatureEtat.chargementProlonge => AppIcons.attente,
    NatureEtat.horsLigne => AppIcons.horsLigne,
    NatureEtat.reconnexion => AppIcons.reconnexion,
    NatureEtat.echecServeur => AppIcons.avertissement,
    NatureEtat.introuvable => AppIcons.recherche,
    NatureEtat.accesRefuse => AppIcons.verrou,
    NatureEtat.sessionExpiree => AppIcons.seReconnecter,
    NatureEtat.dossierEnAttente => AppIcons.attente,
    NatureEtat.aucunResultat => AppIcons.rienAAfficher,
    NatureEtat.permissionRefusee => AppIcons.interdit,
    NatureEtat.ressourceExpiree => AppIcons.ressourceRetiree,
    NatureEtat.indisponible => AppIcons.rienAAfficher,
  };

  /// Le ton d'une nature : l'alerte pour l'echec seul, l'avertissement pour
  /// ce qui tient a la connexion ou a une autorisation, l'accent pour ce qui
  /// informe. Jamais un aplat : la paire douce du ton.
  static TonEtat tonPar(NatureEtat nature) => switch (nature) {
    NatureEtat.echecServeur => TonEtat.alerte,
    NatureEtat.chargementProlonge ||
    NatureEtat.horsLigne ||
    NatureEtat.reconnexion ||
    NatureEtat.sessionExpiree ||
    NatureEtat.permissionRefusee => TonEtat.avertissement,
    NatureEtat.introuvable ||
    NatureEtat.accesRefuse ||
    NatureEtat.dossierEnAttente ||
    NatureEtat.aucunResultat ||
    NatureEtat.ressourceExpiree ||
    NatureEtat.indisponible => TonEtat.accent,
  };

  @override
  Widget build(BuildContext context) {
    final ({String titre, String phrase}) defaut = textesPar(nature);
    final String titreRendu = titre ?? defaut.titre;
    final String phraseRendue = phrase ?? defaut.phrase;
    final String? action = onAction == null
        ? null
        : libelleAction ?? libelleActionPar(nature);

    if (portee == PorteeEtat.page) {
      return EcranResultat(
        icone: icone ?? iconePar(nature),
        titre: titreRendu,
        phrase: phraseRendue,
        ton: tonPar(nature),
        libelleAction: action,
        onAction: onAction,
        actionEnCours: actionEnCours,
        libelleSecondaire: libelleSecondaire,
        onSecondaire: onSecondaire,
      );
    }
    return _Bloc(
      icone: icone ?? iconePar(nature),
      ton: tonPar(nature),
      titre: titreRendu,
      phrase: phraseRendue,
      libelleAction: action,
      onAction: onAction,
      actionEnCours: actionEnCours,
      libelleSecondaire: libelleSecondaire,
      onSecondaire: onSecondaire,
    );
  }
}

/// La forme bloc : la carte garde son cadre, avec son titre humain et son
/// action (manifeste visuel section 6.3, « Erreur de bloc »).
///
/// L'action est de niveau **secondaire** : l'action principale de l'ecran
/// appartient a l'ecran, un bloc en erreur ne la lui prend pas. Le bloc est
/// une region vivante : son apparition est annoncee.
class _Bloc extends StatelessWidget {
  const _Bloc({
    required this.icone,
    required this.ton,
    required this.titre,
    required this.phrase,
    required this.libelleAction,
    required this.onAction,
    required this.actionEnCours,
    required this.libelleSecondaire,
    required this.onSecondaire,
  });

  final AppIcon icone;
  final TonEtat ton;
  final String titre;
  final String phrase;
  final String? libelleAction;
  final VoidCallback? onAction;
  final bool actionEnCours;
  final String? libelleSecondaire;
  final VoidCallback? onSecondaire;

  /// Diametre du medaillon d'icone.
  static const double diametreMedaillon = AppSpacing.section;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppColorPair medaillon = palette.paireDe(ton);
    final bool avecAction = libelleAction != null && onAction != null;
    final bool avecSecondaire =
        libelleSecondaire != null && onSecondaire != null;

    // EA-PL : jamais une carte de 1100 en bureau. La carte garde la largeur
    // de lecture (K-42), posee au bord de debut ; `heightFactor` : elle ne
    // prend que sa hauteur, meme dans un parent borne.
    return Align(
      alignment: AlignmentDirectional.topStart,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppPage.largeurLecture),
        child: _carte(
          palette,
          textes,
          medaillon,
          avecAction,
          avecSecondaire,
          // DASH-MA-PROD (lecon 8) : a texte agrandi (au-dela de 130 %), le
          // medaillon passe AU-DESSUS du texte, qui garde toute la largeur
          // de la carte (« connexi / on » a 320 px x2 sinon).
          empile: MediaQuery.textScalerOf(context).scale(1) > seuilTexteEmpile,
        ),
      ),
    );
  }

  Widget _carte(
    AppPalette palette,
    TextTheme textes,
    AppColorPair medaillon,
    bool avecAction,
    bool avecSecondaire, {
    required bool empile,
  }) {
    final Widget medaillonRendu = ExcludeSemantics(
      child: SizedBox.square(
        dimension: diametreMedaillon,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: medaillon.background,
          ),
          child: Center(
            child: IconTheme(
              data: IconThemeData(
                color: medaillon.onBackground,
                size: AppSpacing.xl,
              ),
              child: Icon(icone.actif),
            ),
          ),
        ),
      ),
    );
    final Widget texte = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TexteSansCoupure(
          titre,
          style: palette.surfaceRaised.applyTo(
            textes.titleSmall ?? const TextStyle(),
          ),
        ),
        // Une phrase vide n'est pas rendue (titre seul, spec).
        if (phrase.isNotEmpty) ...<Widget>[
          Ecart.vXs,
          TexteSansCoupure(
            phrase,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
        // HU-1 (EA-PL) : une seule rangee, celle du contrat B,
        // pour tous les blocs ; « Reessayer » garde la largeur
        // de son libelle, au bord de fin, jamais toute la carte.
        if (avecAction || avecSecondaire) ...<Widget>[
          Ecart.vLg,
          RangeeActions(
            children: <Widget>[
              if (avecSecondaire)
                ActionPrincipale(
                  key: const ValueKey<String>('etat-systeme-secondaire'),
                  libelle: libelleSecondaire!,
                  onPress: onSecondaire,
                  niveau: NiveauAction.tertiaire,
                  pleineLargeur: false,
                ),
              if (avecAction)
                ActionPrincipale(
                  key: const ValueKey<String>('etat-systeme-action'),
                  libelle: libelleAction!,
                  onPress: onAction,
                  enCours: actionEnCours,
                  niveau: NiveauAction.secondaire,
                  pleineLargeur: false,
                ),
            ],
          ),
        ],
      ],
    );
    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: AppElevation.avecFilet(
          surface: palette.surfaceRaised,
          filet: palette.contourCarte,
          ombre: palette.ombre,
          arrondi: AppRadius.arrondiMd,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: empile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[medaillonRendu, Ecart.vMd, texte],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    medaillonRendu,
                    Ecart.hMd,
                    Expanded(child: texte),
                  ],
                ),
        ),
      ),
    );
  }
}
