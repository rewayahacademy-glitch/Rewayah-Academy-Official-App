import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/presence/service_presence.dart';
import '../../core/presence/vue_presence.dart';
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
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/ligne_presence.dart';
import '../../core/widgets/page_immersive.dart';
import '../../core/widgets/permanent_notice.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_pill.dart';
import '../salle_enseignant/panneau_enseignant.dart';
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
/// - il **ne calcule aucun etat de presence** : les quatorze etats sont derives
///   en base par `etat_presence()` et lus par `presence_seance_v`, bornee a ce
///   que l'appelant a le droit de savoir. L'ecran les **montre**, il ne les
///   decide pas -- et il ne dit jamais « absent » quand il ne sait pas
///   (invariant J3) ;
/// - il **ne presente aucun contenu lui-meme** : le transport existe depuis le
///   20 septembre 2026 -- `ContenuPresente`, `VideoSessionProvider.presenterContenu`
///   et `contenusPresentes`, sur le canal de donnees LiveKit -- mais la surface
///   qui l'emploie est celle de l'enseignant (`lib/features/salle_enseignant/`),
///   posee par-dessus cet ecran en un seul point. Le bouton « Ouvrir le Coran »
///   n'existe donc toujours pas ici, plutot que d'etre grise.
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

    // **Un seul chemin vers le pre-vol dans tout le produit** : `preVolProvider`.
    // Deux existaient -- ce provider, que personne n'employait, et un appel
    // imperatif a `servicePreVolProvider` -- et un ecran de plus en aurait
    // choisi un au hasard. `refresh` et non `read` : le materiel a pu changer
    // depuis la derniere mesure, et un casque branche apres un « Reessayer » ne
    // servirait a rien si l'on relisait une valeur en cache.
    final ResultatPreVol preVol = await ref.refresh(preVolProvider.future);
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
  ///
  /// [vue] est passee plutot que relue : la decision de sortie se prend sur
  /// l'etat d'AVANT la deconnexion. Apres `_moteur.quitter()`, la phase est
  /// retombee et `dansLaSalle` serait faux pour tout le monde.
  Future<void> _quitter(VueSalle vue) async {
    final bool confirme = await ConfirmDestructive.demander(
      context,
      question: t.salle.confirmerSortie,
      consequence: t.salle.consequenceSortie,
      libelleConfirmer: t.salle.quitterLeCours,
    );
    if (!confirme || !mounted) {
      return;
    }

    // Le cours a-t-il eu lieu ? La reponse se lit maintenant, pas apres.
    final bool versLeCahier =
        vue.role == RoleSalle.enseignant && vue.dansLaSalle;

    // **L'annonce precede la deconnexion, et cet ordre porte une information
    // que rien d'autre ne porte.** LiveKit envoie le meme evenement `left` dans
    // les deux cas ; seule cette ecriture distingue une sortie volontaire d'une
    // perte de reseau. Annoncer apres s'etre deconnecte laisserait le webhook
    // arriver le premier et inscrire une deconnexion.
    await ref.read(serviceVideoProvider).annoncerSortie(widget.seanceId);
    await _moteur.quitter();
    if (!mounted) {
      return;
    }
    if (versLeCahier) {
      // **L'invariant du catalogue est enfin tenu** : la sortie de `ENS-03`
      // mene a `ENS-04` et a rien d'autre. L'ecart inscrit ici depuis le lot N3
      // -- « `ENS-04` n'a pas de route, on renvoie donc chez soi » -- est leve :
      // le cahier existe (`Routes.cahierPour`) et il est l'ecran de sortie de
      // seance, pas un onglet. `go` et non `push` : la salle ne doit rester
      // sous aucune pile, l'ADR-005 lui interdit d'etre revenue en arriere.
      GoRouter.of(context).go(Routes.cahierPour(widget.seanceId));
      return;
    }
    _rentrer();
  }

  /// Retour a la racine de son role.
  ///
  /// C'est la sortie de qui n'a rien a transmettre : les trois autres roles, et
  /// l'enseignant qui n'est jamais entre -- une impasse ou un abandon pendant la
  /// connexion. Envoyer celui-la au cahier lui demanderait le compte rendu d'un
  /// cours qui n'a pas eu lieu.
  void _rentrer() {
    final AppRole? role = ref.read(sessionProvider).role;
    GoRouter.of(
      context,
    ).go(role == null ? Routes.racine : Routes.racinePour(role));
  }

  Future<void> _basculerMicro(bool ouvert) => _moteur.reglerMicro(actif: !ouvert);

  Future<void> _basculerCamera(bool ouverte) =>
      _moteur.reglerCamera(actif: !ouverte);

  /// Ouvre la presence en feuille, pour qui n'a pas la place de la garder
  /// ouverte a cote de la scene.
  Future<void> _voirPresence(List<_Presence> lignes) => AppBottomSheet.ouvrir(
    context,
    titre: t.presence.titre,
    constructeur: (BuildContext _) => _ListePresence(lignes: lignes),
  );

  @override
  Widget build(BuildContext context) {
    // La session est **observee**, pas lue au dernier moment : `_rentrer` a
    // besoin du role, et un `ref.read` au moment du clic trouverait le provider
    // encore en chargement s'il n'avait jamais ete observe. La sortie tomberait
    // alors sur la racine, qui redirige, au lieu de l'accueil du role.
    final String? monProfil = ref.watch(sessionProvider).profileId;

    final VueSalle vue = VueSalle.depuis(
      materielPret: _materielPret,
      acces: _acces,
      etatMoteur: _etatMoteur,
      participants: _participants,
      qualite: _qualite,
      impasse: _impasse,
    );
    final bool enImpasse = vue.phase == PhaseSalle.refus;

    // **`.value`, et surtout pas un filtrage par le type de l'AsyncValue**
    // (piege de l'etape 3, Riverpod 3). Les trois cas qui rendent `null` --
    // pas encore charge, lecture refusee, reseau coupe -- se disent de la meme
    // facon a l'ecran : inconnu. C'est J3, et c'est ce qui le rend simple.
    final List<PresenceParticipant>? presence = ref
        .watch(presenceSeanceProvider(widget.seanceId))
        .value;
    final List<_Presence> lignes = _Presence.composer(
      presence: presence,
      vue: vue,
      monProfil: monProfil,
      maintenant: DateTime.now(),
    );
    final VuePresence mienne = VuePresence.depuis(
      ligne: maPresence(presence, monProfil),
      maintenant: DateTime.now(),
    );

    return PageImmersive(
      registre: RegistreImmersif.salle,
      entete: _Entete(
        vue: vue,
        // L'eleve lit SON etat, et lui seul : la section 6.6 le dit deux fois,
        // et la vue en base le lui impose de toute facon. L'observateur, lui,
        // n'a aucun etat pedagogique a lire -- il assiste.
        mienne: vue.role == RoleSalle.eleve ? mienne : null,
        // Le bouton n'existe que pour qui a droit a la liste ET n'a pas la
        // place de la garder ouverte. Ailleurs il ferait doublon avec la
        // colonne, et un doublon finit par diverger.
        onVoirPresence:
            vue.voitLesParticipants && !_colonneDePresence(context, vue)
            ? () => unawaited(_voirPresence(lignes))
            : null,
      ),
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
              onQuitter: () => _quitter(vue),
            ),
      child: enImpasse
          ? _Impasse(cause: vue.cause, onReessayer: _entrer, onRentrer: _rentrer)
          // `ENS-03` : la surface de presentation de l'enseignant, en UN SEUL
          // point. Les deux conditions comptent. Le role vient du **jeton**
          // (`vue.role`), jamais de `sessionProvider.role` : c'est le jeton qui
          // decide ce qu'on peut faire dans une salle. Et `peutPresenter`
          // conditionne l'affichage, plutot que de montrer des commandes que le
          // moteur refuserait en silence -- `presenterContenu` refuse sans rien
          // dire quand `can_publish_data` est absent.
          : _panneauEnseignant(vue)
          ? _CorpsEnseignant(
              vue: vue,
              lignes: lignes,
              seanceId: widget.seanceId,
            )
          : _Corps(vue: vue, lignes: lignes),
    );
  }

}

/// La ligne de contexte : ou l'on en est, ce que vaut le lien, et -- pour
/// l'eleve -- comment sa presence est notee.
///
/// **Deux faits distincts, deux lignes.** La pastille du haut dit l'etat de la
/// **connexion** temps reel, ce que le moteur sait ; celle du bas dit l'etat de
/// **presence**, ce que la base derive. Les confondre serait faux : on peut
/// etre parfaitement connecte et note « en retard », et on peut avoir perdu le
/// lien depuis dix secondes sans etre encore note « deconnecte ».
class _Entete extends StatelessWidget {
  const _Entete({required this.vue, this.mienne, this.onVoirPresence});

  final VueSalle vue;

  /// Ma propre presence, pour l'eleve et lui seul. `null` ailleurs.
  final VuePresence? mienne;

  /// Ouvre la liste de presence, quand elle ne tient pas en colonne.
  final VoidCallback? onVoirPresence;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    // Les trois attentes se disent par des mots differents : elles n'echouent
    // pas pour les memes raisons, donc ne se corrigent pas de la meme facon.
    final String? attente = switch (vue.phase) {
      PhaseSalle.materiel => t.salle.verificationMateriel,
      PhaseSalle.ouverture => t.salle.ouverture,
      PhaseSalle.connexion => t.salle.connexion,
      PhaseSalle.enSalle ||
      PhaseSalle.instable ||
      PhaseSalle.reconnexion ||
      PhaseSalle.retabli ||
      PhaseSalle.refus => null,
    };

    if (attente != null) {
      return Text(attente, style: textes.labelLarge ?? const TextStyle());
    }

    // **Chaque etat porte son mot** (invariant J7) : une pastille jaune sans
    // libelle ne dirait rien a qui ne distingue pas les couleurs, et rien du
    // tout a qui ecoute l'ecran. Les cinq etats du protocole sont donc cinq
    // libelles, et « instable » reprend le mot que la qualite du lien emploie
    // deja plutot que d'en inventer un jumeau.
    final (String, TonEtat) etatDuLien = switch (vue.phase) {
      PhaseSalle.reconnexion => (
        t.salle.reconnexionCourt,
        TonEtat.avertissement,
      ),
      PhaseSalle.instable => (
        vue.qualite == QualiteLien.perdue
            ? t.salle.lienPerdu
            : t.salle.lienMediocre,
        TonEtat.avertissement,
      ),
      PhaseSalle.retabli => (t.reseau.retabli, TonEtat.succes),
      PhaseSalle.enSalle ||
      PhaseSalle.materiel ||
      PhaseSalle.ouverture ||
      PhaseSalle.connexion ||
      PhaseSalle.refus => (t.etat.enDirect, TonEtat.succes),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            // Une reconnexion n'est pas une absence, et un retablissement n'est
            // pas un silence : la seance continue, et l'ecran le dit sans
            // dramatiser.
            StatusPill(libelle: etatDuLien.$1, ton: etatDuLien.$2),
            // La qualite du lien se dit en MOTS. Une pastille de couleur seule
            // ne represente jamais un etat critique (invariant J7). La pastille
            // porte deja le mot quand la phase est `instable` : on ne le repete
            // pas a cote d'elle.
            if (vue.lienADire && vue.phase != PhaseSalle.instable) ...<Widget>[
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
            if (onVoirPresence != null) ...<Widget>[
              const Spacer(),
              // **Un mot, pas une icone.** Aucune icone du catalogue ne dit
              // « presence » : emprunter celle du foyer lui donnerait un
              // second sens, et `AppIcons` n'existe que pour qu'un signe garde
              // le sien. Le mot suffit, et `Pressable` lui donne sa cible
              // tactile.
              Pressable(
                onPress: onVoirPresence,
                libelleSemantique: t.presence.voir,
                child: Text(
                  t.presence.titre,
                  style: textes.labelMedium ?? const TextStyle(),
                ),
              ),
            ],
          ],
        ),
        // Visible en permanence, discrete, jamais superposee au contenu
        // (specification d'etape section 7, `ELV-03`).
        if (mienne case final VuePresence etat) ...<Widget>[
          Ecart.vSm,
          LignePresence(nom: t.presence.mienne, vue: etat),
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

/// Vrai quand la salle rend la surface de presentation de l'enseignant.
///
/// Les deux conditions ensemble, en un seul endroit, parce que trois endroits
/// s'en servent et qu'une seule des trois qui se tromperait suffirait a rendre
/// la presence injoignable.
bool _panneauEnseignant(VueSalle vue) =>
    vue.role == RoleSalle.enseignant && vue.peutPresenter;

/// Vrai quand la liste de presence est REELLEMENT posee a cote du contenu.
///
/// **Deux facons d'ouvrir la meme liste sur un meme ecran, c'est une de trop** :
/// l'entete n'offre son bouton que si cette fonction est fausse, et la liste
/// n'est posee que si elle est vraie. Elles doivent donc repondre ensemble, et
/// c'est pour cela que la reponse est ici et non recalculee de chaque cote.
///
/// L'enseignant qui presente l'a TOUJOURS sous les yeux, quel que soit le
/// gabarit : sa colonne defile, donc la liste y tient meme sur un telephone, la
/// ou `_Corps` doit renoncer a la poser faute de largeur. C'est la bonne reponse
/// pour lui, et pas un effet de bord : savoir qui manque est la premiere chose
/// qu'on regarde en ouvrant un cours de groupe.
bool _colonneDePresence(BuildContext context, VueSalle vue) {
  if (!vue.voitLesParticipants) {
    return false;
  }
  return _panneauEnseignant(vue) || AppGabarit.de(context).estLarge;
}

/// La salle de l'enseignant : le document d'abord, la scene ensuite.
///
/// **La hierarchie de `ENS-03` en une classe.** Le contenu pedagogique est le
/// premier niveau, le media le deuxieme : c'est l'ordre du protocole, et il ne
/// se lit nulle part ailleurs dans ce fichier parce que les trois autres roles
/// n'ont pas de document a presenter.
///
/// `[RESPONSIVE]` Sur telephone ET sur tablette, le document prend la plus
/// grande part et la scene garde la sienne DESSOUS -- jamais par-dessus : aucune
/// barre d'outils ne couvre le Coran. Au desktop seulement, les trois surfaces
/// se posent cote a cote, le document en tete parce qu'il est le premier niveau
/// de la hierarchie.
///
/// Elle compose `_Scene` et `_ListePresence` directement plutot que `_Corps` :
/// `_Corps` reserve 256 px fixes a la presence, et les lui laisser prendre sur
/// une demi-largeur est exactement ce qui etranglait la scene.
class _CorpsEnseignant extends StatelessWidget {
  const _CorpsEnseignant({
    required this.vue,
    required this.lignes,
    required this.seanceId,
  });

  final VueSalle vue;
  final List<_Presence> lignes;
  final String seanceId;

  /// La hauteur minimale du document, en dessous de laquelle la colonne defile.
  ///
  /// **Mesuree, pas choisie.** Deux etats du panneau ne defilent pas d'eux-memes
  /// -- ce sont des `EmptyState`, c'est-a-dire un `Center` sur une colonne de
  /// taille minimale : « rien n'est presente » demande un peu plus de quatre
  /// respirations et huit suffisent au plus haut des deux, celui du corpus
  /// absent, qui porte en plus un bouton. La page elle-meme, quand le corpus
  /// existe, defile dans son propre `ListView` et ne pese donc rien ici.
  ///
  /// **Le partage en fractions ne pouvait pas marcher, et c'est ce que la mesure
  /// a montre.** A 800 sur 600 -- la surface par defaut de `flutter_test`, donc
  /// une tablette en paysage -- trois cinquiemes de la place donnaient 269 points
  /// au document pour 464 demandes. Un plancher repond a la question une fois
  /// pour toutes, la ou une fraction la repose a chaque gabarit et a chaque
  /// echelle de texte.
  static const double _hauteurPlancherDocument = AppSpacing.respiration * 8;

  /// La bande reservee a la scene sous le document.
  ///
  /// Elle est FIXE et non proportionnelle, parce que le media est le deuxieme
  /// niveau de la hierarchie : il lui faut de quoi reconnaitre qui parle, pas une
  /// part de l'ecran. Trois respirations et non deux -- le plancher de la galerie
  /// -- parce que la vignette locale flotte a deux respirations de haut et se pose
  /// a `lg` du bord : une bande au plancher exact la ferait deborder de sa propre
  /// marge. Au dela de quatre visages la galerie defile a l'interieur, ce qu'elle
  /// sait faire seule (`_Galerie`, physique de defilement sous son plancher).
  static const double _hauteurScene = AppSpacing.respiration * 3;

  @override
  Widget build(BuildContext context) {
    final Widget panneau = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: PanneauEnseignantSalle(seanceId: seanceId),
    );

    if (AppGabarit.de(context) == Gabarit.desktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(flex: 3, child: panneau),
          Expanded(flex: 2, child: _Scene(vue: vue)),
          if (_colonneDePresence(context, vue))
            SizedBox(
              // La meme largeur que `_Corps` : une seule mesure de colonne de
              // presence dans ce fichier.
              width: AppGabarit.largeurBarreLaterale,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _ListePresence(lignes: lignes, entete: true),
              ),
            ),
        ],
      );
    }
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints contraintes) {
        // Le document prend tout ce qui reste sous la bande de la scene, sans
        // jamais descendre sous son plancher. Sur un telephone de reference --
        // 390 sur 844 -- le compte est juste et rien ne defile : le groupe reste
        // visible sans un geste. Sur une surface courte, c'est la scene qui passe
        // sous la ligne de flottaison, et non le Coran qui se rogne.
        final double reste = contraintes.hasBoundedHeight
            ? contraintes.maxHeight - _hauteurScene
            : _hauteurPlancherDocument;
        final double document = reste < _hauteurPlancherDocument
            ? _hauteurPlancherDocument
            : reste;
        // Le defilement est toujours pose, et ne defile que s'il le faut : quand
        // la place suffit, la colonne fait exactement la hauteur offerte et rien
        // ne bouge. C'est ce qui met l'echelle de texte a 200 % hors de danger --
        // le contenu grandit, la colonne defile, rien ne se rogne.
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(height: document, child: panneau),
              SizedBox(height: _hauteurScene, child: _Scene(vue: vue)),
              // La presence sous la scene, et non en feuille : la colonne defile
              // deja, elle a donc la place que `_Corps` n'a pas en largeur.
              // `_ListePresence` est une colonne de taille minimale, elle vit
              // sans hauteur bornee.
              if (_colonneDePresence(context, vue))
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _ListePresence(lignes: lignes, entete: true),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// La scene, et la presence quand l'ecran a la place de la garder ouverte.
class _Corps extends StatelessWidget {
  const _Corps({required this.vue, required this.lignes});

  final VueSalle vue;
  final List<_Presence> lignes;

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
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _ListePresence(lignes: lignes, entete: true),
          ),
        ),
      ],
    );
  }
}

/// La scene : les autres en galerie, soi-meme en vignette, et ce qui s'affiche
/// quand on est seul.
///
/// **Elle etait dimensionnee pour deux, et le pivot du 19 septembre 2026 en
/// demande six.** La version precedente posait les vignettes dans une `Row` non
/// defilante de 96 points chacune : six participants demandaient 624 points
/// contre 390 de large sur un telephone, donc un debordement certain -- et il
/// etait deja mesure a deux, par le test d'invisibilite du controleur, ou une
/// vignette de 96x128 ne contenait pas son propre bloc « sans image ».
class _Scene extends StatelessWidget {
  const _Scene({required this.vue});

  final VueSalle vue;

  @override
  Widget build(BuildContext context) {
    // Les distants dans l'ordre de lecture que la vue a decide : le role
    // attendu d'abord, les autres ensuite. L'ordre ne bouge pas quand quelqu'un
    // ouvre son micro.
    final List<ParticipantSalle> distants = <ParticipantSalle>[
      if (vue.dominant case final ParticipantSalle premier) premier,
      ...vue.autres,
    ];

    // La vignette locale n'apparait que quand la camera publie : la fiche
    // produit le demande explicitement (« elle disparait si sa camera est
    // coupee »), et l'etat du micro est deja dans les commandes. Elle reste
    // FLOTTANTE et seule -- un seul cadre de 96 points tient partout, et se
    // voir parmi les autres serait se compter comme un eleve.
    final ParticipantSalle? moi = switch (vue.moi) {
      final ParticipantSalle local when local.camera => local,
      _ => null,
    };

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: distants.isEmpty
              ? _Seul(role: vue.role)
              : _Galerie(participants: distants),
        ),
        if (moi case final ParticipantSalle local)
          PositionedDirectional(
            bottom: AppSpacing.lg,
            end: AppSpacing.lg,
            child: SizedBox(
              // Derive de l'echelle, jamais posee : une vignette vaut une
              // respiration et demie de large.
              width: AppSpacing.respiration * 1.5,
              height: AppSpacing.respiration * 2,
              child: _Cadre(
                key: ValueKey<String>(local.identite),
                participant: local,
                moi: true,
                compact: true,
              ),
            ),
          ),
      ],
    );
  }
}

/// Les participants distants, tous visibles, aucun rogne.
///
/// **La hauteur d'une tuile se deduit de la place reelle, elle ne se pose
/// jamais** : c'est la seule maniere de garantir qu'a un comme a six, rien ne
/// sort de l'ecran. En dessous d'un plancher -- au dela de six personnes, ce que
/// le seuil de groupe interdit deja en base -- la galerie prefere defiler
/// plutot que de reduire les visages a rien.
///
/// `[RESPONSIVE]` Le nombre de colonnes vient du gabarit, jamais d'une
/// comparaison de largeur : `AppGabarit` est le seul fichier du depot autorise
/// a comparer une largeur a un nombre.
class _Galerie extends StatelessWidget {
  const _Galerie({required this.participants});

  final List<ParticipantSalle> participants;

  /// La hauteur en dessous de laquelle une tuile ne montre plus rien d'utile.
  static const double _hauteurPlancher = AppSpacing.respiration * 2;

  @override
  Widget build(BuildContext context) {
    // Un seul distant : il occupe tout, exactement comme avant le pivot. C'est
    // le cas du cours a deux, et la raison pedagogique tient toujours -- les
    // makharij se lisent sur une bouche, pas sur une mosaique.
    if (participants.length == 1) {
      return _Cadre(
        key: ValueKey<String>(participants.first.identite),
        participant: participants.first,
        moi: false,
      );
    }

    final Gabarit gabarit = AppGabarit.de(context);
    final int total = participants.length;
    final int colonnes = switch (total) {
      2 => gabarit.estLarge ? 2 : 1,
      3 || 4 => 2,
      _ => gabarit.estLarge ? 3 : 2,
    };
    final int lignes = (total + colonnes - 1) ~/ colonnes;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        final double largeur =
            (contraintes.maxWidth - AppSpacing.sm * (colonnes - 1)) / colonnes;
        final double disponible =
            (contraintes.maxHeight - AppSpacing.sm * (lignes - 1)) / lignes;
        final double hauteur = disponible < _hauteurPlancher
            ? _hauteurPlancher
            : disponible;

        return GridView.count(
          crossAxisCount: colonnes,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: largeur / hauteur,
          // Tant que tout tient, la galerie ne defile pas : un geste vertical
          // dans une salle doit rester sans effet, sous peine de faire croire
          // qu'on a raccroche.
          physics: disponible < _hauteurPlancher
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          children: <Widget>[
            for (final ParticipantSalle personne in participants)
              _Cadre(
                key: ValueKey<String>(personne.identite),
                participant: personne,
                moi: personne.estLocal,
                // Une tuile de galerie a six est deja courte : la legende
                // « sans image » n'y tiendrait pas a cote de l'avatar.
                compact: hauteur <= _hauteurPlancher,
              ),
          ],
        );
      },
    );
  }
}

/// Le cadre d'un participant : son image si elle existe, son nom sinon.
class _Cadre extends ConsumerWidget {
  const _Cadre({
    required this.participant,
    required this.moi,
    super.key,
    this.compact = false,
  });

  final ParticipantSalle participant;
  final bool moi;

  /// Vrai dans un cadre trop court pour porter une legende sous l'avatar.
  ///
  /// C'est ce qui manquait : le bloc « sans image » etait dessine a l'identique
  /// dans le grand cadre et dans une vignette de 96x128, ou il depassait de huit
  /// points -- et c'est cet ecart, et rien d'autre, qui faisait echouer le test
  /// d'invisibilite du controleur depuis le pivot.
  final bool compact;

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
              child:
                  image ??
                  _SansImage(nom: participant.nom, avecLegende: !compact),
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
///
/// **La legende cede avant l'avatar, et pas l'inverse.** Dans un cadre court,
/// l'avatar porte deja le prenom et le cadre porte deja le nom en bas : la
/// phrase « Sans image » y serait la troisieme fois qu'on dit la meme chose, et
/// c'est elle qui debordait. Elle reste annoncee aux technologies d'assistance,
/// pour qui rien ne se voit.
class _SansImage extends StatelessWidget {
  const _SansImage({required this.nom, this.avecLegende = true});

  final String nom;

  /// Vrai quand le cadre a la place d'ecrire « Sans image » sous l'avatar.
  final bool avecLegende;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Center(
      child: Semantics(
        label: avecLegende ? null : t.salle.sansImage,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AvatarTile(prenom: nom),
            if (avecLegende) ...<Widget>[
              Ecart.vSm,
              Text(
                t.salle.sansImage,
                textAlign: TextAlign.center,
                style: palette.surfaceSunken.applyTo(
                  textes.labelSmall ?? const TextStyle(),
                ),
              ),
            ],
          ],
        ),
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

/// Une personne de la seance, telle que la liste la montre.
///
/// **Les inscrits comme ossature, la video comme complement, et l'ordre
/// compte.** Celui qui n'est jamais arrive n'a aucune piste LiveKit, donc
/// aucune ligne cote moteur -- et c'est justement de lui que l'enseignant a
/// besoin de savoir quelque chose. Batir la liste sur les participants
/// connectes reviendrait a ne montrer que ceux dont on n'a pas a s'inquieter.
@immutable
class _Presence {
  const _Presence({
    required this.nom,
    required this.role,
    required this.vue,
    this.micro,
  });

  /// Compose la liste que l'ecran affiche.
  ///
  /// Quand la presence est indisponible, la liste retombe sur les participants
  /// que le moteur connait, chacun avec un etat **inconnu** -- et non « absent »
  /// (invariant J3). Une salle ne perd pas sa liste parce qu'une requete a
  /// echoue ; elle perd ce qu'elle ne sait pas, et le dit.
  static List<_Presence> composer({
    required List<PresenceParticipant>? presence,
    required VueSalle vue,
    required String? monProfil,
    required DateTime maintenant,
  }) {
    if (presence == null) {
      return <_Presence>[
        for (final ParticipantSalle personne in vue.participantsListes)
          _Presence(
            nom: personne.estLocal ? t.salle.vousMeme : personne.nom,
            role: _libelleRole(personne.role),
            vue: VuePresence.depuis(ligne: null, maintenant: maintenant),
            micro: personne.micro,
          ),
      ];
    }

    return <_Presence>[
      for (final PresenceParticipant ligne in tableauDePresence(presence))
        _Presence(
          nom: ligne.profilId == monProfil ? t.salle.vousMeme : ligne.prenom,
          role: _libelleRole(ligne.role),
          vue: VuePresence.depuis(ligne: ligne, maintenant: maintenant),
          // La base emet `identity = profile_id` : le rapprochement se fait
          // donc sans table de correspondance. `null` quand la personne n'est
          // pas dans la salle -- et « pas de micro » ne se dit pas alors, parce
          // que ce serait un fait, la ou il n'y a qu'une absence de fait.
          micro: _microDe(vue.participantsListes, ligne.profilId),
        ),
    ];
  }

  /// L'etat du micro d'une personne, si le moteur la connait.
  static bool? _microDe(List<ParticipantSalle> connectes, String profilId) {
    for (final ParticipantSalle personne in connectes) {
      if (personne.identite == profilId) {
        return personne.micro;
      }
    }
    return null;
  }

  /// Le role de seance, en mots. Un role inconnu ne s'affiche pas du tout
  /// plutot que de s'afficher faux : le vocabulaire vit en base et grandira.
  static String _libelleRole(String brut) => switch (RoleSalle.depuis(brut)) {
    RoleSalle.enseignant => t.salle.roleEnseignant,
    RoleSalle.eleve => t.salle.roleEleve,
    RoleSalle.tuteurObservateur => t.salle.roleTuteur,
    RoleSalle.controleur || RoleSalle.inconnu => '',
  };

  final String nom;
  final String role;
  final VuePresence vue;

  /// Micro ouvert, ferme, ou absent de la salle.
  final bool? micro;
}

/// La presence de la seance, pour qui a le droit de la lire.
///
/// Le meme corps en colonne et en feuille : deux rendus d'une meme liste
/// finiraient par ne plus dire la meme chose, et c'est precisement ce que le
/// lot N3 a evite en refusant trois ecrans de salle.
class _ListePresence extends StatelessWidget {
  const _ListePresence({required this.lignes, this.entete = false});

  final List<_Presence> lignes;

  /// L'en-tete de section, en colonne seulement : la feuille a deja son titre.
  final bool entete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (entete) ...<Widget>[
          SectionHeader(titre: t.presence.titre, compteur: lignes.length),
          Ecart.vMd,
        ],
        for (final _Presence personne in lignes) ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: LignePresence(
                  nom: personne.nom,
                  role: personne.role,
                  vue: personne.vue,
                ),
              ),
              // Le micro n'apparait que pour qui est dans la salle : un micro
              // barre a cote de « Pas encore la » dirait deux fois la meme
              // chose, et la deuxieme serait fausse.
              if (personne.micro case final bool ouvert) ...<Widget>[
                Ecart.hSm,
                Icon(
                  ouvert ? AppIcons.micro.repos : AppIcons.microCoupe.repos,
                  semanticLabel: ouvert ? t.salle.micro : t.salle.microCoupe,
                  size: AppSpacing.xl,
                ),
              ],
            ],
          ),
          Ecart.vMd,
        ],
      ],
    );
  }
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
    // Les quatre phases ou la seance continue, reunies par la vue : un lien
    // instable ou un retour de coupure ne ferme pas un micro.
    final bool enSalle = vue.dansLaSalle;

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
