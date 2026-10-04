import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/video/video_session_provider.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/pastille_etat_seance.dart';
import '../../core/widgets/status_pill.dart';
import 'barre_commandes_observation.dart';
import 'compteur_visite.dart';
import 'vue_observation_tuteur.dart';

/// La salle d'observation : ce que le tuteur voit pendant sa visite (lot O,
/// sous-paquet 2 ; maquettes V8 M3, M4 et D1, decision du directeur `03`
/// section 1 bis-5).
///
/// **Presentation seule, aucun provider.** Le panneau recoit une
/// [VueObservationTuteur] deja calculee : c'est ce qui rend l'invariant « aucun
/// roster complet » verifiable par un test de widget aussi bien que par un test
/// de fonction pure.
///
/// Composition, de haut en bas : le **bandeau pleine largeur** du decompte et
/// des visites restantes ([BandeauDecompteVisite]), l'en-tete (classe, enfant
/// et enseignant, etat du direct), le **support dominant**, les deux vignettes
/// secondaires (sous le support sur telephone, en colonne a droite des la
/// tablette, comme D1), la barre de trois commandes. « Agrandir » retire
/// l'en-tete et les vignettes : le bandeau et « Quitter » restent toujours a
/// l'ecran.
///
/// Le support partage est un **emplacement**, pas une implementation : c'est la
/// Classe Live qui sait afficher le Coran ou un PDF, et une seconde surface de
/// rendu serait une seconde Bibliotheque. Tant que l'hote n'en fournit pas, le
/// panneau le dit en clair.
///
/// **Aucun faux direct** : la pastille suit l'etat reel du lien
/// ([etatSalle]) ; pendant une reconnexion elle dit « Reconnexion » et le
/// decompte continue, jamais remis a zero.
class PanneauObservationTuteur extends StatefulWidget {
  /// Cree le panneau.
  const PanneauObservationTuteur({
    required this.vue,
    required this.onQuitter,
    super.key,
    this.titre,
    this.sousTitre,
    this.etatSalle = EtatSalle.connecte,
    this.supportPartage,
    this.videoEnseignant,
    this.videoEnfant,
    this.budgetIncertain = false,
    this.videoIndisponible = false,
  });

  /// Ce qui est expose au tuteur.
  final VueObservationTuteur vue;

  /// La sortie volontaire (la page demande confirmation avant).
  final VoidCallback onQuitter;

  /// Le nom de la classe. `null` : « Observation en cours ».
  final String? titre;

  /// « Mariam · Sayyida Amina ». `null` : les noms portes par la salle.
  final String? sousTitre;

  /// L'etat du lien avec la salle video.
  final EtatSalle etatSalle;

  /// Le support partage, fourni par l'hote. `null` = pas encore branche.
  final Widget? supportPartage;

  /// L'image de l'enseignant, deja montee par le moteur de salle.
  ///
  /// **Un widget, jamais une piste.** L'hote appelle `renduVideo(identite)` et
  /// passe le resultat : c'est ainsi que la portabilite de l'ADR-001 survit au
  /// rendu, et c'est ce qui laisse ce panneau sans provider ni SDK.
  final Widget? videoEnseignant;

  /// L'image de l'enfant du tuteur. `null` quand sa camera est fermee.
  final Widget? videoEnfant;

  /// Vrai quand la derniere lecture de budget a echoue.
  final bool budgetIncertain;

  /// Vrai quand la salle video n'a pas pu s'ouvrir.
  ///
  /// Une ligne discrete, pas un ecran de remplacement : la visite continue de
  /// se consommer cote serveur, et un panneau sans compte a rebours ni bouton
  /// « Quitter » empecherait le tuteur de la refermer.
  final bool videoIndisponible;

  @override
  State<PanneauObservationTuteur> createState() =>
      _PanneauObservationTuteurEtat();
}

class _PanneauObservationTuteurEtat extends State<PanneauObservationTuteur> {
  /// Vrai quand le support occupe toute la salle. Etat d'ecran seulement.
  bool _agrandi = false;

  bool get _lienVivant => switch (widget.etatSalle) {
    EtatSalle.connecte || EtatSalle.retabli || EtatSalle.instable => true,
    _ => false,
  };

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints cadre) {
      final bool large =
          AppGabarit.classe(cadre.maxWidth) != ClasseLargeur.compacte;
      final VueObservationTuteur vue = widget.vue;
      final AppPalette palette = AppPalette.of(context);
      final Widget barre = BarreCommandesObservation(
        sonRecu: _lienVivant && !widget.videoIndisponible,
        agrandi: _agrandi,
        onAgrandir: () => setState(() => _agrandi = !_agrandi),
        onQuitter: widget.onQuitter,
        large: large,
      );
      final Widget bandeau = BandeauDecompteVisite(
        budget: vue.budget,
        budgetIncertain: widget.budgetIncertain,
      );

      if (!large) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            bandeau,
            Ecart.vMd,
            Expanded(child: _corpsTelephone()),
            Ecart.vMd,
            barre,
            Ecart.vLg,
          ],
        );
      }
      // Des la tablette (D1) : la salle est UNE carte (en-tete, support,
      // vignettes, barre), sous le bandeau du decompte.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          bandeau,
          Ecart.vMd,
          Expanded(
            child: DecoratedBox(
              decoration: palette.surfaceRaised.decoration(
                borderRadius: AppRadius.arrondiLg,
                side: palette.borderHairline.asBorderSide(),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(child: _corpsLarge()),
                    Ecart.vMd,
                    barre,
                  ],
                ),
              ),
            ),
          ),
          Ecart.vLg,
        ],
      );
    },
  );

  /// Telephone (M4) : en-tete, support, deux vignettes cote a cote. Le support
  /// remplit la hauteur restante ; quand la hauteur manque (telephone en
  /// paysage, texte agrandi), la salle defile avec un support de hauteur
  /// fixe : jamais un debordement.
  Widget _corpsTelephone() => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints cadre) {
      final List<Widget> vignettes = <Widget>[
        Ecart.vMd,
        Row(
          children: <Widget>[
            Expanded(child: _vignetteEnseignant()),
            Ecart.hMd,
            Expanded(child: _vignetteEnfant()),
          ],
        ),
      ];
      final bool texteAgrandi =
          MediaQuery.textScalerOf(context).scale(AppSpacing.lg) /
              AppSpacing.lg >
          seuilTexteEmpile;
      if (_agrandi || (cadre.maxHeight >= _hauteurMinCorps && !texteAgrandi)) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (!_agrandi) ...<Widget>[_entete(), Ecart.vMd],
            Expanded(child: _support()),
            if (!_agrandi) ...vignettes,
          ],
        );
      }
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _entete(),
            Ecart.vMd,
            // OBS-COUPE-1b : sans support partage, la ligne d'attente prend
            // la hauteur qu'il lui faut (a 320 px et 200 %, « s'affiche ici »
            // etait rogne a mi-texte dans 200 points) ; un support reel garde
            // sa hauteur fixe, il ne sait pas se mesurer seul.
            if (widget.supportPartage == null)
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: _hauteurMinSupport,
                ),
                child: _support(),
              )
            else
              SizedBox(height: _hauteurMinSupport, child: _support()),
            ...vignettes,
          ],
        ),
      );
    },
  );

  /// En deca, la salle du telephone defile plutot que d'ecraser le support.
  static const double _hauteurMinCorps = 300;

  /// Tablette et bureau (D1) : en-tete, puis le support a environ trois
  /// quarts de la largeur et la colonne des vignettes a droite.
  Widget _corpsLarge() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      if (!_agrandi) ...<Widget>[_entete(), Ecart.vMd],
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(flex: 7, child: _support()),
            if (!_agrandi) ...<Widget>[
              Ecart.hMd,
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _vignetteEnseignant(),
                      Ecart.vMd,
                      _vignetteEnfant(),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );

  /// Le plus petit support qui reste lisible quand la page defile.
  static const double _hauteurMinSupport = 200;

  Widget _entete() {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final v = t.tc.observation.visite;
    final String? sousTitre =
        widget.sousTitre ??
        _joindre(widget.vue.monEnfant?.nom, widget.vue.enseignant?.nom);
    final String? detail = widget.videoIndisponible
        ? v.videoIndisponible
        : widget.etatSalle == EtatSalle.reconnexion
        ? v.reconnexionDetail
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Semantics(
                    header: true,
                    child: Text(
                      widget.titre ?? v.titre,
                      style: palette.inkStrong.applyTo(
                        textes.titleMedium ?? const TextStyle(),
                      ),
                    ),
                  ),
                  if (sousTitre != null)
                    Text(
                      sousTitre,
                      style: palette.inkMuted.applyTo(
                        textes.bodySmall ?? const TextStyle(),
                      ),
                    ),
                ],
              ),
            ),
            Ecart.hSm,
            _pastilleDirect(),
          ],
        ),
        if (detail != null) ...<Widget>[
          Ecart.vSm,
          Semantics(
            liveRegion: true,
            child: Text(
              detail,
              style: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// L'etat reel du direct : jamais « En direct » quand le lien est perdu.
  Widget _pastilleDirect() {
    final v = t.tc.observation.visite;
    if (widget.videoIndisponible || widget.etatSalle == EtatSalle.echec) {
      return StatusPill(libelle: v.videoCoupee, ton: TonEtat.alerte);
    }
    return switch (widget.etatSalle) {
      EtatSalle.connecte ||
      EtatSalle.retabli ||
      EtatSalle.instable => PastilleEtatSeance(
        etat: EtatPastilleSeance.enDirect,
        libelle: v.enDirect,
      ),
      EtatSalle.reconnexion => StatusPill(
        libelle: v.reconnexion,
        ton: TonEtat.avertissement,
      ),
      _ => StatusPill(libelle: v.connexion, ton: TonEtat.neutre),
    };
  }

  Widget _support() {
    final AppPalette palette = AppPalette.of(context);
    return DecoratedBox(
      key: const ValueKey<String>('support-observation'),
      decoration: palette.surfaceRaised.decoration(
        borderRadius: AppRadius.arrondiMd,
        side: palette.borderHairline.asBorderSide(),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.arrondiMd,
        child:
            widget.supportPartage ??
            // Aucun support partage : une ligne discrete au centre, pas un
            // etat vide de page (le support reste la zone dominante).
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ExcludeSemantics(
                      child: IconTheme(
                        data: palette.inkFaint.asIconTheme(
                          size: AppSpacing.xxxl,
                        ),
                        child: Icon(AppIcons.bibliotheque.repos),
                      ),
                    ),
                    Ecart.vSm,
                    Text(
                      t.tc.observation.visite.supportIndisponible,
                      textAlign: TextAlign.center,
                      style: palette.inkMuted.applyTo(
                        Theme.of(context).textTheme.bodyMedium ??
                            const TextStyle(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _vignetteEnseignant() => _Vignette(
    cle: const ValueKey<String>('vignette-enseignant'),
    personne: widget.vue.enseignant,
    repli: t.tc.observation.visite.enseignant,
    video: widget.videoEnseignant,
  );

  Widget _vignetteEnfant() => _Vignette(
    cle: const ValueKey<String>('vignette-enfant'),
    personne: widget.vue.monEnfant,
    repli: t.tc.observation.visite.monEnfant,
    video: widget.videoEnfant,
  );

  static String? _joindre(String? a, String? b) {
    final List<String> parties = <String>[?a, ?b];
    return parties.isEmpty ? null : parties.join(' · ');
  }
}

/// Une des deux seules vignettes que la visite expose (M3, M4, D1).
///
/// L'image, quand la personne en publie une, **s'ajoute** a son nom, elle ne
/// le remplace pas : un cadre video sans legende obligerait le tuteur a deviner
/// qui il regarde. Sans image : l'initiale et « Camera fermee » ; personne
/// dans la salle : « Pas encore dans la salle », jamais « absent » (la
/// presence est dite par le serveur, pas deduite d'une connexion).
class _Vignette extends StatelessWidget {
  const _Vignette({
    required this.cle,
    required this.personne,
    required this.repli,
    this.video,
  });

  final Key cle;
  final ParticipantSalle? personne;

  /// Le libelle quand le nom n'est pas connu : « Votre enfant », « Enseignant ».
  final String repli;
  final Widget? video;

  /// Le format d'une vignette : 4:3, celui des maquettes (M4 ≈ 176 x 126,
  /// D1 ≈ 272 x 200).
  static const double _format = 4 / 3;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final ParticipantSalle? p = personne;
    final String nom = p?.nom ?? repli;
    final bool parle = p?.parle ?? false;
    final Widget? image = p == null ? null : video;
    final v = t.tc.observation.visite;

    final Widget fond = image != null
        ? SizedBox.expand(child: image)
        : ColoredBox(
            color: palette.surfaceSunken.background,
            // AVATAR-1 : le petit cercle du composant partage, contenu dans la
            // vignette ; la legende est l'unique ligne de texte.
            child: p == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: Text(
                        v.pasEncoreLa,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: palette.inkMuted.applyTo(
                          textes.bodySmall ?? const TextStyle(),
                        ),
                      ),
                    ),
                  )
                // TUILE-TUTEUR-1 : la meme tuile sans image que la salle et
                // la scene live (VIDEO-TUILE-1) : cercle, nom centre dessous ;
                // « Camera fermee » est lu, la tuile parle dans son coin.
                : TuileSansImage(
                    prenom: p.nom,
                    nom: nom,
                    libelleSansImage: v.cameraFermee,
                    styleNom: palette.surfaceSunken.applyTo(
                      textes.labelMedium ?? const TextStyle(),
                    ),
                    coin: parle ? const _OndesParole() : null,
                  ),
          );
    // Sans image, le nom est deja sous le cercle : l'etiquette du bas ne le
    // redit pas.
    final bool etiquette = image != null || p == null;

    // Une vignette est un cadre video de taille fixe : son texte grossit
    // jusqu'au seuil des commandes, pas au-dela (les noms se relisent en
    // taille pleine dans l'en-tete).
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: seuilTexteEmpile,
      child: _cadre(
        palette,
        fond,
        nom,
        parle,
        v.parle(nom: nom),
        etiquette: etiquette,
        sansImage: etiquette ? null : v.cameraFermee,
      ),
    );
  }

  Widget _cadre(
    AppPalette palette,
    Widget fond,
    String nom,
    bool parle,
    String nomQuiParle, {
    required bool etiquette,
    required String? sansImage,
  }) {
    return Semantics(
      key: cle,
      container: true,
      // TUILE-TUTEUR-1b : sans image, le cadre dit tout en un seul noeud
      // (« Mariam, Camera fermee ») ; la tuile partagee ne le redit pas
      // dessous, sinon le nom est annonce deux fois.
      label: <String>[if (parle) nomQuiParle else nom, ?sansImage].join(', '),
      excludeSemantics: sansImage != null,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: AppRadius.arrondiSm,
          // Le liseré d'accent ne s'affiche que sur un signal reel du moteur
          // (`ParticipantSalle.parle`), jamais par defaut (V8, D1).
          border: parle
              ? Border.fromBorderSide(palette.inkAccent.asBorderSide(width: 2))
              : null,
        ),
        child: ClipRRect(
          borderRadius: AppRadius.arrondiSm,
          child: AspectRatio(
            aspectRatio: _format,
            child: Stack(
              children: <Widget>[
                Positioned.fill(child: fond),
                if (etiquette)
                  PositionedDirectional(
                    start: AppSpacing.sm,
                    bottom: AppSpacing.sm,
                    end: AppSpacing.sm,
                    child: Align(
                      alignment: AlignmentDirectional.bottomStart,
                      child: _Etiquette(nom: nom, parle: parle),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Les ondes de parole, seules, dans le coin d'une tuile sans image (signal
/// reel seulement, comme l'etiquette).
class _OndesParole extends StatelessWidget {
  const _OndesParole();

  @override
  Widget build(BuildContext context) => IconTheme(
    data: AppPalette.of(context).pointsStatut.succes
        .asIconTheme(size: AppSpacing.lg),
    child: Icon(AppIcons.libelleAudio.repos),
  );
}

/// L'etiquette du nom sur la vignette : pilule sombre, nom, ondes quand la
/// personne parle (signal reel seulement).
class _Etiquette extends StatelessWidget {
  const _Etiquette({required this.nom, required this.parle});

  final String nom;
  final bool parle;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: palette.surfaceInverse.decoration(
          borderRadius: AppRadius.arrondiFull,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: Text(
                  nom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: palette.surfaceInverse.applyTo(
                    textes.labelMedium ?? const TextStyle(),
                  ),
                ),
              ),
              if (parle) ...<Widget>[
                Ecart.hXs,
                IconTheme(
                  data: palette.pointsStatut.succes.asIconTheme(
                    size: AppSpacing.lg,
                  ),
                  child: Icon(AppIcons.libelleAudio.repos),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
