import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/video/livekit_session_provider.dart';
import '../../core/video/pre_vol.dart';
import '../../core/video/service_video.dart';
import '../../core/video/video_session_provider.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/page_immersive.dart';
import '../../core/widgets/permanent_notice.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_pill.dart';
import 'vue_salle.dart';

/// `ELV-03`, `ENS-03`, `CTR-02` : la salle.
///
/// **Un seul ecran pour trois codes, et pour quatre roles.** Ce qui les
/// distingue n'est pas le role du compte, que le client porte, mais le jeton
/// emis par `create-room-token` : son `role` et ses capacites signees. Un ecran
/// qui se fierait a `sessionProvider` promettrait des commandes que le serveur
/// LiveKit refuserait ensuite, et trois ecrans separes auraient fini par
/// divergerer sur le bandeau permanent -- ce que l'ADR-011 interdit.
///
/// Ce que cet ecran ne fait pas, et ou cela vit a la place :
///
/// - il **n'ecrit aucun appel reseau video** : tout passe par `lib/core/video/`,
///   et il n'importe pas `livekit_client` ;
/// - il **n'affiche aucun des quatorze etats de presence** : la presence est
///   derivee en base, c'est le lot suivant. Ici on ne dit que l'etat de la
///   connexion temps reel, ce que le moteur sait ;
/// - il **ne partage aucun document** : le Coran n'est pas importe et le canal
///   de diffusion de l'etat partage n'est pas tranche (question `e` de
///   `docs/architecture/etape-5-salle-coran-presence.md` section 10). Le bouton
///   « Ouvrir le Coran » n'existe donc pas, plutot que d'etre grise.
class SallePage extends ConsumerStatefulWidget {
  /// Cree la salle pour une seance.
  const SallePage({required this.seanceId, super.key});

  /// La seance visee, lue dans le billet d'entree (ADR-005). Elle ne transite
  /// jamais par l'URL : une adresse copiee arrive sans billet et repart.
  final String seanceId;

  @override
  ConsumerState<SallePage> createState() => _SallePageEtat();
}

class _SallePageEtat extends ConsumerState<SallePage> {
  /// Le moteur, capture une fois.
  ///
  /// Capture et non relu dans `dispose` : un `ref.read` au demontage arrive
  /// apres que le conteneur a commence a se defaire, et c'est precisement la
  /// que la liberation des pistes doit encore fonctionner.
  late final VideoSessionProvider _moteur = ref.read(moteurSalleProvider);

  StreamSubscription<EtatSalle>? _sEtats;
  StreamSubscription<List<ParticipantSalle>>? _sParticipants;
  StreamSubscription<QualiteLien>? _sQualite;

  bool _materielPret = false;
  AccesSalle? _acces;
  CauseImpasse? _impasse;
  EtatSalle _etatMoteur = EtatSalle.absent;
  List<ParticipantSalle> _participants = const <ParticipantSalle>[];
  QualiteLien _qualite = QualiteLien.inconnue;

  @override
  void initState() {
    super.initState();
    // On ecoute AVANT d'entrer : le moteur publie son premier etat pendant
    // `rejoindre`, et un abonnement pose apres manquerait la connexion.
    _sEtats = _moteur.etats.listen((EtatSalle etat) {
      if (mounted) {
        setState(() => _etatMoteur = etat);
      }
    });
    _sParticipants = _moteur.participants.listen((
      List<ParticipantSalle> liste,
    ) {
      if (mounted) {
        setState(() => _participants = liste);
      }
    });
    _sQualite = _moteur.qualite.listen((QualiteLien lien) {
      if (mounted) {
        setState(() => _qualite = lien);
      }
    });
    unawaited(_entrer());
  }

  @override
  void dispose() {
    unawaited(_sEtats?.cancel());
    unawaited(_sParticipants?.cancel());
    unawaited(_sQualite?.cancel());
    // Quitter au demontage, quelle que soit la raison du demontage : un retour
    // navigateur, une redirection, un billet expire. Sans cela, une salle
    // fermee a l'ecran continuerait a publier un micro ouvert.
    unawaited(_moteur.quitter());
    super.dispose();
  }

  /// Les trois temps de l'entree : le materiel, le jeton, la salle.
  ///
  /// Le pre-vol vient **avant** le jeton, et l'ordre n'est pas une preference :
  /// une salle qui echoue apres etre entree laisse deux personnes dedans dont
  /// l'une est muette sans savoir pourquoi. Verifier le micro pendant que l'on
  /// est encore seul devant son ecran coute une seconde et evite cela.
  Future<void> _entrer() async {
    setState(() {
      _impasse = null;
      _materielPret = false;
      _acces = null;
    });

    final ResultatPreVol preVol = await ref
        .read(servicePreVolProvider)
        .verifier();
    if (!mounted) {
      return;
    }
    if (!preVol.peutEntrer) {
      setState(() => _impasse = CauseImpasse.materiel);
      return;
    }
    setState(() => _materielPret = true);

    final AccesSalle acces;
    try {
      acces = await ref.read(serviceVideoProvider).acces(widget.seanceId);
    } on EchecSalle catch (echec) {
      if (mounted) {
        setState(() => _impasse = CauseImpasse.depuis(echec.motif));
      }
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _acces = acces);

    try {
      await _moteur.rejoindre(acces);
    } catch (erreur) {
      // Le moteur a deja pose son etat d'echec et tout libere ; il ne reste
      // qu'a nommer la cause pour l'usager. Aucun detail technique ne remonte
      // a l'ecran : « ICE failed » ne se lit pas devant un enfant.
      debugPrint('entree en salle impossible : $erreur');
      if (mounted) {
        setState(() => _impasse = CauseImpasse.reseau);
      }
    }
  }

  /// La sortie volontaire, confirmee une fois.
  Future<void> _quitter() async {
    final bool confirme = await ConfirmDestructive.demander(
      context,
      question: t.salle.confirmerSortie,
      consequence: t.salle.consequenceSortie,
      libelleConfirmer: t.salle.quitterLeCours,
    );
    if (!confirme || !mounted) {
      return;
    }

    // **L'annonce precede la deconnexion, et cet ordre porte une information
    // que rien d'autre ne porte.** LiveKit envoie le meme evenement `left` dans
    // les deux cas ; seule cette ecriture distingue une sortie volontaire d'une
    // perte de reseau. Annoncer apres s'etre deconnecte laisserait le webhook
    // arriver le premier et inscrire une deconnexion.
    await ref.read(serviceVideoProvider).annoncerSortie(widget.seanceId);
    await _moteur.quitter();
    if (mounted) {
      _rentrer();
    }
  }

  /// Retour a la racine de son role.
  ///
  /// **Ecart connu et assume** : l'invariant du catalogue veut que la sortie de
  /// `ENS-03` mene a `ENS-04`, le cahier de transmission, et a rien d'autre.
  /// `ENS-04` est l'etape 6 et n'a pas de route. Renvoyer vers un ecran vide
  /// pour tenir la lettre de l'invariant serait pire que l'ecart : on renvoie
  /// donc chez soi, et l'ecart est ecrit au catalogue.
  void _rentrer() {
    final AppRole? role = ref.read(sessionProvider).role;
    GoRouter.of(
      context,
    ).go(role == null ? Routes.racine : Routes.racinePour(role));
  }

  Future<void> _basculerMicro(bool ouvert) => _moteur.reglerMicro(actif: !ouvert);

  Future<void> _basculerCamera(bool ouverte) =>
      _moteur.reglerCamera(actif: !ouverte);

  @override
  Widget build(BuildContext context) {
    // La session est **observee**, pas lue au dernier moment : `_rentrer` a
    // besoin du role, et un `ref.read` au moment du clic trouverait le provider
    // encore en chargement s'il n'avait jamais ete observe. La sortie tomberait
    // alors sur la racine, qui redirige, au lieu de l'accueil du role.
    ref.watch(sessionProvider);

    final VueSalle vue = VueSalle.depuis(
      materielPret: _materielPret,
      acces: _acces,
      etatMoteur: _etatMoteur,
      participants: _participants,
      qualite: _qualite,
      impasse: _impasse,
    );
    final bool enImpasse = vue.phase == PhaseSalle.refus;

    return PageImmersive(
      registre: RegistreImmersif.salle,
      entete: _Entete(vue: vue),
      // Le bandeau disparait dans la seule situation ou il serait faux : une
      // impasse n'est pas une salle, rien n'y est enregistre. Partout ailleurs
      // il est present, y compris pendant l'attente : la regle se lit donc
      // AVANT que le micro puisse s'ouvrir.
      bandeau: enImpasse ? null : _Bandeaux(vue: vue),
      commandes: enImpasse
          ? null
          : _Commandes(
              vue: vue,
              onMicro: _basculerMicro,
              onCamera: _basculerCamera,
              onQuitter: _quitter,
            ),
      child: enImpasse
          ? _Impasse(cause: vue.cause, onReessayer: _entrer, onRentrer: _rentrer)
          : _Corps(vue: vue),
    );
  }
}

/// La ligne de contexte : ou l'on en est, et ce que vaut le lien.
class _Entete extends StatelessWidget {
  const _Entete({required this.vue});

  final VueSalle vue;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    // Les trois attentes se disent par des mots differents : elles n'echouent
    // pas pour les memes raisons, donc ne se corrigent pas de la meme facon.
    final String? attente = switch (vue.phase) {
      PhaseSalle.materiel => t.salle.verificationMateriel,
      PhaseSalle.ouverture => t.salle.ouverture,
      PhaseSalle.connexion => t.salle.connexion,
      PhaseSalle.enSalle || PhaseSalle.reconnexion || PhaseSalle.refus => null,
    };

    if (attente != null) {
      return Text(attente, style: textes.labelLarge ?? const TextStyle());
    }

    return Row(
      children: <Widget>[
        if (vue.phase == PhaseSalle.reconnexion)
          // Une reconnexion n'est pas une absence : la seance continue, et
          // l'ecran le dit sans dramatiser.
          StatusPill(
            libelle: t.salle.reconnexionCourt,
            ton: TonEtat.avertissement,
          )
        else
          StatusPill(libelle: t.etat.enDirect, ton: TonEtat.succes),
        // La qualite du lien se dit en MOTS. Une pastille de couleur seule ne
        // represente jamais un etat critique (invariant J7 de l'etape 5).
        if (vue.lienADire) ...<Widget>[
          Ecart.hSm,
          Flexible(
            child: Text(
              vue.qualite == QualiteLien.perdue
                  ? t.salle.lienPerdu
                  : t.salle.lienMediocre,
              style: textes.labelMedium ?? const TextStyle(),
            ),
          ),
        ],
      ],
    );
  }
}

/// Le bandeau permanent, et le rappel propre a qui observe.
class _Bandeaux extends StatelessWidget {
  const _Bandeaux({required this.vue});

  final VueSalle vue;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Un SECOND bandeau, jamais une variante du premier. `PermanentNotice`
        // n'accepte aucun parametre, et c'est ce qui garantit qu'il affiche la
        // meme ligne pour les quatre roles (ADR-011). Le rappel d'invisibilite,
        // lui, ne concerne que l'ecran de qui observe.
        if (vue.role == RoleSalle.controleur)
          _Rappel(
            texte: t.salle.bandeauControle,
            ton: TonEtat.avertissement,
            icone: AppIcons.controleQualite,
          ),
        if (vue.role == RoleSalle.tuteurObservateur)
          _Rappel(
            texte: t.salle.observationMuette,
            ton: TonEtat.accent,
            icone: AppIcons.microCoupe,
          ),
        const PermanentNotice(),
      ],
    );
  }
}

/// Une ligne de rappel pleine largeur, en registre doux.
class _Rappel extends StatelessWidget {
  const _Rappel({
    required this.texte,
    required this.ton,
    required this.icone,
  });

  final String texte;
  final TonEtat ton;
  final AppIcon icone;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    // Registre DOUX, jamais un aplat : la seule zone pleine d'un ecran est son
    // action principale, et une salle n'en a pas. Le « bandeau noir » du
    // catalogue visait une salle sur fond creme ; la salle est desormais en
    // registre inverse, ou un bandeau noir serait invisible -- ironique, pour
    // un rappel d'invisibilite.
    final AppColorPair paire = switch (ton) {
      TonEtat.avertissement => palette.washWarning,
      TonEtat.accent => palette.washAccent,
      TonEtat.neutre || TonEtat.succes || TonEtat.alerte => palette.washAccent,
    };
    final TextTheme textes = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: paire.decoration(),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: <Widget>[
            IconTheme(
              data: IconThemeData(
                color: paire.onBackground,
                size: AppSpacing.xl,
              ),
              child: Icon(icone.repos),
            ),
            Ecart.hSm,
            Flexible(
              child: Text(
                texte,
                style: paire.applyTo(
                  textes.bodySmall ?? const TextStyle(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La scene, et la liste des participants quand l'ecran a la place.
class _Corps extends StatelessWidget {
  const _Corps({required this.vue});

  final VueSalle vue;

  @override
  Widget build(BuildContext context) {
    final Gabarit gabarit = AppGabarit.de(context);
    final bool colonne = gabarit.estLarge && vue.voitLesParticipants;

    if (!colonne) {
      return _Scene(vue: vue);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(child: _Scene(vue: vue)),
        SizedBox(
          // Une largeur de chrome, deja posee pour la barre laterale : la
          // reutiliser evite d'en inventer une seconde.
          width: AppGabarit.largeurBarreLaterale,
          child: _Participants(vue: vue),
        ),
      ],
    );
  }
}

/// Le grand cadre, les vignettes, et ce qui s'affiche quand on est seul.
class _Scene extends StatelessWidget {
  const _Scene({required this.vue});

  final VueSalle vue;

  @override
  Widget build(BuildContext context) {
    final ParticipantSalle? grand = vue.dominant;

    // La vignette locale n'apparait que quand la camera publie : la fiche
    // produit le demande explicitement (« elle disparait si sa camera est
    // coupee »), et l'etat du micro est deja dans les commandes.
    final List<ParticipantSalle> vignettes = <ParticipantSalle>[
      ...vue.autres,
      if (vue.moi case final ParticipantSalle local when local.camera) local,
    ];

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: grand == null
              ? _Seul(role: vue.role)
              : _Cadre(participant: grand, moi: false),
        ),
        if (vignettes.isNotEmpty)
          PositionedDirectional(
            bottom: AppSpacing.lg,
            end: AppSpacing.lg,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final ParticipantSalle vignette in vignettes) ...<Widget>[
                  Ecart.hSm,
                  SizedBox(
                    // Derive de l'echelle, jamais posee : une vignette vaut une
                    // respiration et demie de haut.
                    width: AppSpacing.respiration * 1.5,
                    height: AppSpacing.respiration * 2,
                    child: _Cadre(
                      key: ValueKey<String>(vignette.identite),
                      participant: vignette,
                      moi: vignette.estLocal,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Le cadre d'un participant : son image si elle existe, son nom sinon.
class _Cadre extends ConsumerWidget {
  const _Cadre({required this.participant, required this.moi, super.key});

  final ParticipantSalle participant;
  final bool moi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    // **L'ecran ne recoit pas une piste, il recoit un widget deja monte.** C'est
    // ainsi que la portabilite de l'ADR-001 survit au rendu : aucun import de
    // `livekit_client` ici, et changer de moteur ne rouvrirait pas cet ecran.
    final Widget? image = ref
        .watch(moteurSalleProvider)
        .renduVideo(participant.identite);

    final String nom = moi ? t.salle.vousMeme : participant.nom;

    return DecoratedBox(
      decoration: palette.surfaceSunken.decoration(
        borderRadius: metriques.arrondi,
      ),
      child: ClipRRect(
        borderRadius: metriques.arrondi,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: image ?? _SansImage(nom: participant.nom),
            ),
            PositionedDirectional(
              start: AppSpacing.sm,
              bottom: AppSpacing.sm,
              end: AppSpacing.sm,
              // Une seule lecture pour les technologies d'assistance : le nom,
              // puis ce qui manque. Trois elements separes feraient trois
              // annonces pour une personne.
              child: MergeSemantics(
                child: Row(
                  children: <Widget>[
                    if (!participant.micro)
                      IconTheme(
                        data: IconThemeData(
                          color: palette.surfaceSunken.onBackground,
                          size: AppSpacing.xl,
                        ),
                        child: Icon(
                          AppIcons.microCoupe.repos,
                          semanticLabel: t.salle.microCoupe,
                        ),
                      ),
                    if (!participant.micro) Ecart.hXs,
                    Flexible(
                      child: Text(
                        nom,
                        overflow: TextOverflow.ellipsis,
                        style: palette.surfaceSunken.applyTo(
                          textes.labelMedium ?? const TextStyle(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ce qui occupe un cadre sans image.
class _SansImage extends StatelessWidget {
  const _SansImage({required this.nom});

  final String nom;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AvatarTile(prenom: nom),
          Ecart.vSm,
          Text(
            t.salle.sansImage,
            textAlign: TextAlign.center,
            style: palette.surfaceSunken.applyTo(
              textes.labelSmall ?? const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Seul dans la salle.
class _Seul extends StatelessWidget {
  const _Seul({required this.role});

  final RoleSalle role;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    // Qui manque depend de qui attend. « Un participant n'est pas connecte »
    // serait vrai et inutile : l'enfant attend son professeur, le professeur
    // attend son eleve, et l'observateur attend que le cours commence.
    final (String, String) phrase = switch (role) {
      RoleSalle.eleve => (t.salle.seulEnseignant, t.salle.seulEnseignantDetail),
      RoleSalle.enseignant => (t.salle.seulEleve, t.salle.seulEleveDetail),
      RoleSalle.tuteurObservateur ||
      RoleSalle.controleur ||
      RoleSalle.inconnu => (
        t.salle.seulObservation,
        t.salle.seulObservationDetail,
      ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              phrase.$1,
              textAlign: TextAlign.center,
              style: textes.titleMedium ?? const TextStyle(),
            ),
            Ecart.vSm,
            Text(
              phrase.$2,
              textAlign: TextAlign.center,
              style: textes.bodyMedium ?? const TextStyle(),
            ),
          ],
        ),
      ),
    );
  }
}

/// La liste des participants, pour qui a le droit de la voir.
class _Participants extends StatelessWidget {
  const _Participants({required this.vue});

  final VueSalle vue;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final List<ParticipantSalle> liste = vue.participantsListes;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionHeader(titre: t.salle.participants, compteur: liste.length),
          Ecart.vMd,
          for (final ParticipantSalle personne in liste) ...<Widget>[
            MergeSemantics(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          personne.estLocal ? t.salle.vousMeme : personne.nom,
                          style: textes.labelLarge ?? const TextStyle(),
                        ),
                        Text(
                          _libelleRole(personne.role),
                          style: textes.bodySmall ?? const TextStyle(),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    personne.micro
                        ? AppIcons.micro.repos
                        : AppIcons.microCoupe.repos,
                    semanticLabel: personne.micro
                        ? t.salle.micro
                        : t.salle.microCoupe,
                  ),
                ],
              ),
            ),
            Ecart.vMd,
          ],
        ],
      ),
    );
  }

  /// Le role de seance, en mots. Un role inconnu ne s'affiche pas du tout
  /// plutot que de s'afficher faux : le vocabulaire vit en base et grandira.
  String _libelleRole(String brut) => switch (RoleSalle.depuis(brut)) {
    RoleSalle.enseignant => t.salle.roleEnseignant,
    RoleSalle.eleve => t.salle.roleEleve,
    RoleSalle.tuteurObservateur => t.salle.roleTuteur,
    RoleSalle.controleur || RoleSalle.inconnu => '',
  };
}

/// Les commandes, selon ce que le jeton permet.
///
/// **Le nombre de commandes decoule du jeton, jamais du mode d'interface.** La
/// fiche produit annonce « deux commandes seulement » en mode enfant : c'est le
/// resultat, pas la regle. Un mineur a `camera_policy` a `forbidden` par
/// defaut, donc son jeton refuse l'image, donc le bouton n'existe pas -- il
/// reste le micro et la sortie. Coder le mode plutot que le jeton priverait de
/// sa camera l'enfant dont le tuteur l'a justement autorisee.
class _Commandes extends StatelessWidget {
  const _Commandes({
    required this.vue,
    required this.onMicro,
    required this.onCamera,
    required this.onQuitter,
  });

  final VueSalle vue;
  final Future<void> Function(bool ouvert) onMicro;
  final Future<void> Function(bool ouverte) onCamera;
  final Future<void> Function() onQuitter;

  @override
  Widget build(BuildContext context) {
    final bool microOuvert = vue.moi?.micro ?? false;
    final bool cameraOuverte = vue.moi?.camera ?? false;
    final bool enSalle =
        vue.phase == PhaseSalle.enSalle ||
        vue.phase == PhaseSalle.reconnexion;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // Un controle que le jeton refuse n'est PAS rendu, et n'est jamais
        // grise : un bouton visible mais inactif invite a appuyer dessus, son
        // absence ne pose pas la question.
        if (vue.peutParler)
          _Commande(
            icone: microOuvert ? AppIcons.micro : AppIcons.microCoupe,
            libelle: t.salle.micro,
            acte: microOuvert ? t.salle.fermerMicro : t.salle.ouvrirMicro,
            actif: microOuvert,
            onPress: enSalle ? () => unawaited(onMicro(microOuvert)) : null,
          ),
        if (vue.peutMontrer)
          _Commande(
            icone: cameraOuverte ? AppIcons.camera : AppIcons.cameraCoupee,
            libelle: t.salle.camera,
            acte: cameraOuverte ? t.salle.fermerCamera : t.salle.ouvrirCamera,
            actif: cameraOuverte,
            onPress: enSalle ? () => unawaited(onCamera(cameraOuverte)) : null,
          ),
        _Commande(
          icone: AppIcons.sortie,
          libelle: t.salle.quitter,
          acte: t.salle.quitterLeCours,
          actif: false,
          onPress: () => unawaited(onQuitter()),
        ),
      ],
    );
  }
}

/// Une commande : un cercle, une icone, un mot court, et l'acte pour qui ecoute.
///
/// Deux libelles, et ils ne disent pas la meme chose. **Le mot visible est
/// court** (« Micro ») parce que trois libelles complets cote a cote ne tiennent
/// pas sur 390 points, et qu'un libelle tronque ne vaut rien. **Le libelle parle
/// dit l'ACTE** (« Ouvrir le micro »), parce qu'un bouton se lit par ce qu'il
/// declenche, jamais par l'etat ou il se trouve.
///
/// L'etat, lui, se lit par la FORME : l'icone change, et le cercle se remplit.
/// Jamais par la couleur seule -- pas plus pour la sortie, que la regle de la
/// zone pleine unique interdit de peindre en aplat rouge, et qui se distingue
/// donc par son mot et sa place.
class _Commande extends StatelessWidget {
  const _Commande({
    required this.icone,
    required this.libelle,
    required this.acte,
    required this.actif,
    required this.onPress,
  });

  final AppIcon icone;
  final String libelle;
  final String acte;
  final bool actif;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppColorPair ouverte = palette.surfaceRaised;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Pressable(
        onPress: onPress,
        libelleSemantique: acte,
        arrondiFocus: AppRadius.arrondiFull,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox.square(
              dimension: metriques.cibleTactile,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: actif ? ouverte.background : null,
                  border: actif
                      ? null
                      : Border.fromBorderSide(
                          palette.borderStrong.asBorderSide(),
                        ),
                ),
                child: Center(
                  child: Icon(
                    icone.resoudre(selectionne: actif),
                    color: actif ? ouverte.onBackground : null,
                  ),
                ),
              ),
            ),
            Ecart.vXs,
            Text(
              libelle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textes.labelSmall ?? const TextStyle(),
            ),
          ],
        ),
      ),
    );
  }
}

/// L'impasse : ce qui bloque, et la seule chose a faire.
class _Impasse extends StatelessWidget {
  const _Impasse({
    required this.cause,
    required this.onReessayer,
    required this.onRentrer,
  });

  final CauseImpasse cause;
  final Future<void> Function() onReessayer;
  final VoidCallback onRentrer;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    // Une cause, un message, une reparation. Le detail dit ou se trouve la
    // faute : sur l'appareil, dans l'heure, ou chez nous. Sans cela, l'usager
    // cherche toujours de son cote.
    final (String, String) dit = switch (cause) {
      CauseImpasse.materiel => (
        t.salle.refusMateriel,
        t.salle.refusMaterielDetail,
      ),
      CauseImpasse.acces => (t.salle.refusAcces, t.salle.refusAccesDetail),
      CauseImpasse.configuration => (
        t.salle.refusConfiguration,
        t.salle.refusConfigurationDetail,
      ),
      CauseImpasse.reseau => (t.salle.refusReseau, t.salle.refusReseauDetail),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              dit.$1,
              textAlign: TextAlign.center,
              style: textes.titleMedium ?? const TextStyle(),
            ),
            Ecart.vSm,
            Text(
              dit.$2,
              textAlign: TextAlign.center,
              style: textes.bodyMedium ?? const TextStyle(),
            ),
            Ecart.vXxl,
            // Une seule action principale : reessayer quand cela a un sens,
            // rentrer sinon. Un refus d'acces ne se reessaye pas, l'heure
            // n'aura pas change.
            if (cause.seReessaye) ...<Widget>[
              ActionPrincipale(
                libelle: t.commun.reessayer,
                onPress: () => unawaited(onReessayer()),
              ),
              Ecart.vMd,
              ActionPrincipale(
                libelle: t.salle.retourAccueil,
                onPress: onRentrer,
                niveau: NiveauAction.secondaire,
              ),
            ] else
              ActionPrincipale(
                libelle: t.salle.retourAccueil,
                onPress: onRentrer,
              ),
          ],
        ),
      ),
    );
  }
}
