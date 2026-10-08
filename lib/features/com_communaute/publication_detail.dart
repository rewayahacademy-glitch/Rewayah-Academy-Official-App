// Une publication ouverte et ses reponses (COM-M02, COM-W02 colonne
// « Publication/Reponses » ; spec section 4, section 5.5, section 8.3,
// section 25 « Etats propres Communaute »).
//
// L'auteur se lit (nom et fonction autorises) et ne se touche pas : la
// Communaute n'expose aucun profil, donc aucun « Message prive » ni contact
// (spec section 4.2, R-COM-07). « Enregistrer » garde une reference a la
// publication (`PortElementsEnregistres`) ; « Signaler » passe par
// `PortModeration`. Chaque action n'est rendue qu'avec sa capacite, lue
// dans le port, jamais deduite d'un role : une action absente n'est pas
// grisee, elle n'existe pas.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../../core/accessibilite/sens_du_contenu.dart';
import '../../core/accessibilite/texte_agrandi.dart';
import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/communications/modeles_communication.dart';
import '../../core/communications/moderation.dart';
import '../../core/communications/port_brouillons.dart';
import '../../core/communications/port_elements_enregistres.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/carte_piece_jointe.dart';
import '../../core/widgets/espace_travail_adaptatif.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/menu_actions.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/vue_etat_communication.dart';
import 'feuille_signalement_communaute.dart';
import 'flux_publications.dart';
import 'port_communaute.dart';
import 'port_garde_promotion.dart';
import 'reponses.dart';

Duration? _sansRetentative(int essai, Object erreur) => null;

/// Les contenus que la personne a deja signales, rendus par le serveur
/// (revue COM-R, R-18) : un signalement fait avant la visite (autre page,
/// autre appareil) se dit aussi, et « Signaler » n'est pas repropose. Une
/// lecture en echec ou sans contrat ne cache rien : l'ensemble est vide.
final FutureProvider<Set<ObjetLie>> mesSignalementsProvider =
    FutureProvider.autoDispose<Set<ObjetLie>>(
      (Ref ref) async {
        try {
          return await ref.watch(portModerationProvider).mesSignalements();
        } on Object {
          return <ObjetLie>{};
        }
      },
      retry: _sansRetentative,
      dependencies: <ProviderOrFamily>[portModerationProvider],
    );

/// Vrai si un objet est dans les elements enregistres.
final estEnregistreProvider = FutureProvider.autoDispose.family<bool, ObjetLie>(
  (Ref ref, ObjetLie objet) =>
      ref.watch(portElementsEnregistresProvider).estEnregistre(objet),
  retry: _sansRetentative,
  dependencies: <ProviderOrFamily>[portElementsEnregistresProvider],
);

/// Une publication ouverte, ses actions, ses reponses et le composer de
/// reponse.
///
/// [onRevenir] ramene a la liste quand la publication n'est plus accessible.
class PublicationDetail extends ConsumerStatefulWidget {
  /// Cree le detail.
  const PublicationDetail({
    required this.publicationId,
    super.key,
    this.peutRepondre = false,
    this.signales = const <ObjetLie>{},
    this.onSignale,
    this.onRevenir,
  });

  /// La publication.
  final String publicationId;

  /// Vrai si la personne peut repondre (capacite du serveur).
  final bool peutRepondre;

  /// Les objets deja signales pendant la visite, tenus par la page : ils
  /// survivent a l'ouverture d'une autre publication (aucun double
  /// signalement, la confirmation reste dite).
  final Set<ObjetLie> signales;

  /// Un signalement accuse par le serveur, remonte a la page.
  final ValueChanged<ObjetLie>? onSignale;

  /// Ramene a la liste.
  final VoidCallback? onRevenir;

  /// Cles, pour les tests.
  static const ValueKey<String> cleTitre = ValueKey<String>(
    'communaute-detail-titre',
  );

  /// La cle de la zone qui defile (publication, reponses, composer).
  static const ValueKey<String> cleDefilement = ValueKey<String>(
    'communaute-detail-defilement',
  );

  /// La cle de l'action « Enregistrer ».
  static const ValueKey<String> cleEnregistrer = ValueKey<String>(
    'communaute-enregistrer',
  );

  /// La ligne de l'auteur posee sous sa rangee (telephone, texte agrandi),
  /// pour les tests.
  static const ValueKey<String> cleLigneAuteur = ValueKey<String>(
    'publication-ligne-auteur',
  );

  /// La cle du menu de la publication.
  static const ValueKey<String> cleMenu = ValueKey<String>(
    'communaute-menu-publication',
  );

  /// La cle de la phrase « publication signalee ».
  static const ValueKey<String> cleSignalee = ValueKey<String>(
    'communaute-publication-signalee',
  );

  @override
  ConsumerState<PublicationDetail> createState() => _PublicationDetailState();
}

class _PublicationDetailState extends ConsumerState<PublicationDetail> {
  final List<ReponseEnAttente> _enAttente = <ReponseEnAttente>[];

  /// Les signalements de cette publication, quand aucune page ne les tient.
  final Set<ObjetLie> _signalesLocaux = <ObjetLie>{};
  static int _compteur = 0;

  Set<ObjetLie> get _signales => <ObjetLie>{
    ...?ref.watch(mesSignalementsProvider).value,
    ...widget.signales,
    ..._signalesLocaux,
  };

  String get _id => widget.publicationId;

  Future<IssueEnvoiReponse> _repondre(String texte) async {
    _compteur++;
    final ReponseEnAttente reponse = ReponseEnAttente(
      cle: 'rep-$_id-${DateTime.now().microsecondsSinceEpoch}-$_compteur',
      texte: texte,
    );
    setState(() => _enAttente.add(reponse));
    final IssueEnvoiReponse issue = await _envoyer(reponse);
    // Un premier envoi refuse revient dans le composer, avec son motif : la
    // ligne en attente disparait (COM-RC tour 4, reserve de R-01).
    if (issue is ReponseRefusee && mounted) {
      setState(
        () => _enAttente.removeWhere(
          (ReponseEnAttente r) => r.cle == reponse.cle,
        ),
      );
    }
    return issue;
  }

  void _remplacer(ReponseEnAttente reponse) {
    final int i = _enAttente.indexWhere(
      (ReponseEnAttente r) => r.cle == reponse.cle,
    );
    if (i >= 0) _enAttente[i] = reponse;
  }

  /// Envoie [reponse]. Un refus du serveur au nom de la politique
  /// ([ContenuRefuse]) n'est pas un echec : la ligne dit le refus et son
  /// motif, sans « Renvoyer » (COM-RC tour 4, reserve de R-01).
  Future<IssueEnvoiReponse> _envoyer(ReponseEnAttente reponse) async {
    setState(() => _remplacer(reponse.avecEchec(false)));
    try {
      await ref
          .read(portCommunauteProvider)
          .repondre(
            publicationId: _id,
            texte: reponse.texte,
            cleIdempotence: reponse.cle,
          );
    } on ContenuRefuse catch (refus) {
      if (mounted) {
        setState(() => _remplacer(reponse.refusee(refus.verification)));
      }
      return ReponseRefusee(refus.verification);
    } on Object {
      if (mounted) setState(() => _remplacer(reponse.avecEchec(true)));
      return const ReponseNonConfirmee();
    }
    const IssueEnvoiReponse confirmee = ReponseConfirmee();
    if (!mounted) return confirmee;
    // Un renvoi accuse (« Réessayer » dans la liste) efface aussi le
    // brouillon que le composer gardait pour ce texte : il ne reviendra pas
    // dans le champ a la reouverture.
    await _effacerBrouillonEnvoye(reponse.texte);
    if (!mounted) return confirmee;
    // La reponse quitte l'attente quand la liste relue la contient : jamais
    // de trou entre l'accuse et la relecture.
    ref
      ..invalidate(reponsesCommunauteProvider(_id))
      ..invalidate(publicationsCommunauteProvider);
    try {
      await ref.read(reponsesCommunauteProvider(_id).future);
    } on Object {
      // La relecture a echoue : la liste dira son etat, la reponse est
      // confirmee par le serveur.
    }
    if (mounted) {
      setState(
        () => _enAttente.removeWhere(
          (ReponseEnAttente r) => r.cle == reponse.cle,
        ),
      );
    }
    return confirmee;
  }

  Future<void> _effacerBrouillonEnvoye(String texte) async {
    final PortBrouillons brouillons = ref.read(portBrouillonsProvider);
    final CleBrouillon cle = CleBrouillon(
      type: TypeObjetLie.publication,
      objetId: _id,
    );
    try {
      final Brouillon? garde = await brouillons.lire(cle);
      if (garde != null && garde.texte.trim() == texte) {
        await brouillons.effacer(cle);
      }
    } on Object {
      // Memoire indisponible : rien a effacer.
    }
  }

  Future<void> _signaler(ObjetLie objet) async {
    final bool accuse = await FeuilleSignalementCommunaute.ouvrir(
      context,
      moderation: ref.read(portModerationProvider),
      objet: objet,
    );
    if (!accuse || !mounted) return;
    setState(() => _signalesLocaux.add(objet));
    widget.onSignale?.call(objet);
  }

  Future<void> _basculerEnregistrement(ObjetLie objet, bool enregistre) async {
    final PortElementsEnregistres port = ref.read(
      portElementsEnregistresProvider,
    );
    try {
      if (enregistre) {
        await port.retirer(objet);
      } else {
        await port.enregistrer(objet);
      }
    } on Object {
      // L'etat relu dira ce qui est vrai : rien n'est affirme ici.
    }
    if (mounted) ref.invalidate(estEnregistreProvider(objet));
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<PublicationCommunaute> lue = ref.watch(
      publicationCommunauteProvider(_id),
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final p = t.com.communaute.publication;

    // Tant que la publication n'est pas lue, l'en-tete n'existe pas : (i)
    // garde sa rangee a part, au-dessus de l'etat (R-02 de l'espace).
    final bool lueAvecValeur = lue.hasValue && !lue.hasError;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!lueAvecValeur) const RangeeEnteteEspace(child: SizedBox.shrink()),
        Expanded(
          child: BlocAsynchrone<PublicationCommunaute>(
            valeur: lue,
            squelette: const SingleChildScrollView(child: Skeleton.liste()),
            titreEchec: t.com.socle.composants.etats.erreurTitre,
            onReessayer: () =>
                ref.invalidate(publicationCommunauteProvider(_id)),
            erreurVersEtat: (Object erreur, VoidCallback? reessayer) =>
                switch (erreur) {
                  PublicationIntrouvable() => EtatSysteme(
                    nature: NatureEtat.ressourceExpiree,
                    titre: p.introuvableTitre,
                    phrase: p.introuvable,
                    libelleAction: widget.onRevenir == null ? null : p.revenir,
                    onAction: widget.onRevenir,
                  ),
                  // R-23 : la capacite absente, le hors ligne et l'echec
                  // passent par l'aide partagee, jamais recopies ici.
                  _ => VueEtatCommunication.depuisErreur(
                    erreur,
                    horsLigne: horsLigne,
                    onReessayer: reessayer,
                  ),
                },
            // COM-RC tour 2 (R-01) : la publication garde la priorite de
            // lecture. Le composer de reponse et son garde ne sont plus une
            // zone fixe qui la reduit : ils defilent avec la page, apres
            // les reponses.
            construire: (PublicationCommunaute publication) =>
                SingleChildScrollView(
                  key: PublicationDetail.cleDefilement,
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _contenu(publication),
                      if (widget.peutRepondre) ...<Widget>[
                        Ecart.vXl,
                        ComposerReponse(
                          publicationId: _id,
                          onEnvoyer: _repondre,
                        ),
                      ],
                    ],
                  ),
                ),
          ),
        ),
      ],
    );
  }

  Widget _contenu(PublicationCommunaute publication) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final p = t.com.communaute.publication;
    final DateTime maintenant = ref.watch(horlogeCommunauteProvider)();
    final ObjetLie objet = publication.objet;
    final bool peutSignaler =
        ref.watch(capacitesModerationProvider).value?.peutSignaler ?? false;
    final Set<ObjetLie> signales = _signales;
    final bool signalee = signales.contains(objet);
    final AsyncValue<bool> enregistrement = ref.watch(
      estEnregistreProvider(objet),
    );
    final bool? enregistre = enregistrement.hasError
        ? null
        : enregistrement.value;
    final AsyncValue<List<ReponseCommunaute>> reponses = ref.watch(
      reponsesCommunauteProvider(publication.id),
    );
    final int nombre =
        (reponses.value?.length ?? publication.nombreReponses) +
        _enAttente.length;
    final String moment = momentCommunaute(publication.publieeLe, maintenant);
    final String ligneAuteur = ligneAuteurCommunaute(
      publication.auteur.fonction,
      moment,
    );
    // COM-RC tour 3 : sur telephone a texte agrandi, la colonne du nom,
    // serree entre l'avatar, (i) et le menu, faisait quatre lignes de
    // fonction et de moment (« Il y a 2 / h », 30 % de l'ecran a 320 et
    // texte x2). La ligne passe sous la rangee, sur toute la largeur.
    final bool compacte =
        SeuilsTexteAgrandi.texteAgrandi(context) &&
        MediaQuery.sizeOf(context).width < AppGabarit.seuilTablette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Le menu « ... » au bord de fin de la carte, jamais colle au nom
        // (revue COM-R, R-13). La rangee de l'auteur est l'en-tete du
        // contenu : (i) s'y pose apres le nom, au lieu d'une rangee a part
        // qui prenait de la hauteur a la publication ; le menu reste au
        // bord de fin (R-13).
        Row(
          children: <Widget>[
            Expanded(
              child: RangeeEnteteEspace(
                child: AvatarNom.enLigne(
                  prenom: publication.auteur.nomAffiche,
                  // Compacte, la ligne de l'auteur passe sous la rangee.
                  role: compacte ? null : ligneAuteur,
                  diametre: AppAvatar.petit,
                ),
              ),
            ),
            if (peutSignaler && !signalee) ...<Widget>[
              Ecart.hSm,
              MenuActions(
                key: PublicationDetail.cleMenu,
                points: true,
                tooltip: p.menu(titre: publication.titre),
                actions: <EntreeAction>[
                  EntreeAction(
                    libelle: p.signaler,
                    onChoix: () => unawaited(_signaler(objet)),
                  ),
                ],
              ),
            ],
          ],
        ),
        if (compacte) ...<Widget>[
          Ecart.vXs,
          _LigneAuteurCompacte(
            fonction: publication.auteur.fonction,
            moment: moment,
            ligne: ligneAuteur,
          ),
        ],
        Ecart.vLg,
        Semantics(
          header: true,
          child: Text(
            publication.titre,
            key: PublicationDetail.cleTitre,
            textDirection: sensDuContenu(context, publication.titre),
            style: palette.inkStrong.applyTo(
              textes.titleMedium ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vSm,
        Text(
          publication.texte,
          // Le contenu garde le sens de sa langue (COM-RC tour 3).
          textDirection: sensDuContenu(context, publication.texte),
          style: palette.inkStrong.applyTo(
            textes.bodyLarge ?? const TextStyle(),
          ),
        ),
        if (publication.piecesJointes.isNotEmpty) ...<Widget>[
          Ecart.vLg,
          PileCartes(
            children: <Widget>[
              for (final pj in publication.piecesJointes)
                CartePieceJointe(piece: pj),
            ],
          ),
        ],
        Ecart.vLg,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            Semantics(
              label: t.com.communaute.flux.categorie(
                categorie: publication.categorie.libelle,
              ),
              child: ExcludeSemantics(
                child: StatusPill(
                  libelle: publication.categorie.libelle,
                  ton: TonEtat.neutre,
                ),
              ),
            ),
            if (enregistre ?? false)
              StatusPill(libelle: p.enregistree, ton: TonEtat.accent),
          ],
        ),
        if (enregistre != null) ...<Widget>[
          Ecart.vMd,
          ActionPrincipale(
            key: PublicationDetail.cleEnregistrer,
            libelle: enregistre ? p.retirer : p.enregistrer,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
            compacte: true,
            affleurant: true,
            onPress: () =>
                unawaited(_basculerEnregistrement(objet, enregistre)),
          ),
        ],
        if (signalee) ...<Widget>[
          Ecart.vMd,
          Semantics(
            liveRegion: true,
            child: Text(
              p.signalee,
              key: PublicationDetail.cleSignalee,
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
        Ecart.vXxl,
        SectionHeader(titre: t.com.communaute.reponses.titre(nombre: nombre)),
        Ecart.vMd,
        BlocAsynchrone<List<ReponseCommunaute>>(
          valeur: reponses,
          squelette: const Skeleton.liste(),
          titreEchec: t.com.communaute.reponses.erreurTitre,
          onReessayer: () =>
              ref.invalidate(reponsesCommunauteProvider(publication.id)),
          erreurVersEtat: (Object erreur, VoidCallback? _) =>
              erreur is CapaciteIndisponible
              ? Text(
                  t.com.communaute.reponses.indisponible,
                  style: palette.inkMuted.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                )
              : null,
          construire: (List<ReponseCommunaute> lues) => FilReponses(
            reponses: lues,
            enAttente: List<ReponseEnAttente>.unmodifiable(_enAttente),
            maintenant: maintenant,
            peutSignaler: peutSignaler,
            signalees: signales,
            onSignaler: (ReponseCommunaute r) => unawaited(_signaler(r.objet)),
            onRenvoyer: (ReponseEnAttente r) => unawaited(_envoyer(r)),
          ),
        ),
      ],
    );
  }
}

/// La ligne de l'auteur sous sa rangee, sur une ligne (COM-RC tour 3) : la
/// fonction s'abrege si la place manque, le moment reste entier ; le lecteur
/// d'ecran lit la ligne complete.
class _LigneAuteurCompacte extends StatelessWidget {
  const _LigneAuteurCompacte({
    required this.fonction,
    required this.moment,
    required this.ligne,
  });

  final String? fonction;
  final String moment;
  final String ligne;

  /// La part de la largeur que le moment peut prendre en restant sur la
  /// ligne de la fonction ; au-dela, la ligne entiere passe a la ligne
  /// entre ses mots.
  static const double _partMomentMax = 0.6;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppPalette.of(context).inkMuted
        .applyTo(Theme.of(context).textTheme.bodySmall ?? const TextStyle());
    final String? f = fonction;
    final bool avecFonction = f != null && f.isNotEmpty;
    // « · Il y a 2 h » : la ligne de l'auteur sans sa fonction.
    final String suite = avecFonction
        ? t.com.communaute.publication
              .auteur(fonction: '', moment: moment)
              .trimLeft()
        : moment;
    final TextDirection sens = Directionality.of(context);
    final TextScaler echelle = MediaQuery.textScalerOf(context);
    return Semantics(
      key: PublicationDetail.cleLigneAuteur,
      label: ligne,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (BuildContext _, BoxConstraints c) {
            final TextPainter mesure = TextPainter(
              text: TextSpan(text: suite, style: style),
              textDirection: sens,
              textScaler: echelle,
              maxLines: 1,
            )..layout();
            final bool tient = mesure.width <= c.maxWidth * _partMomentMax;
            mesure.dispose();
            if (!tient) {
              // Tres peu de place : la ligne entiere, entre ses mots.
              return TexteSansCoupure(ligne, style: style);
            }
            return Row(
              children: <Widget>[
                if (avecFonction)
                  Flexible(
                    child: Text(
                      f,
                      style: style,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Text(suite, style: style, maxLines: 1, softWrap: false),
              ],
            );
          },
        ),
      ),
    );
  }
}
