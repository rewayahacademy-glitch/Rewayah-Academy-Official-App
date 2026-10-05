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

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/communications/modeles_communication.dart';
import '../../core/communications/moderation.dart';
import '../../core/communications/port_elements_enregistres.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/carte_piece_jointe.dart';
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
import 'reponses.dart';

Duration? _sansRetentative(int essai, Object erreur) => null;

/// Les capacites de moderation de la personne connectee (signaler).
final FutureProvider<CapacitesModeration>
capacitesModerationCommunauteProvider =
    FutureProvider.autoDispose<CapacitesModeration>(
      (Ref ref) => ref.watch(portModerationProvider).capacites(),
      retry: _sansRetentative,
      dependencies: <ProviderOrFamily>[portModerationProvider],
    );

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

  /// La cle de l'action « Enregistrer ».
  static const ValueKey<String> cleEnregistrer = ValueKey<String>(
    'communaute-enregistrer',
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

  Future<bool> _repondre(String texte) {
    _compteur++;
    final ReponseEnAttente reponse = ReponseEnAttente(
      cle: 'rep-$_id-${DateTime.now().microsecondsSinceEpoch}-$_compteur',
      texte: texte,
    );
    setState(() => _enAttente.add(reponse));
    return _envoyer(reponse);
  }

  void _remplacer(ReponseEnAttente reponse) {
    final int i = _enAttente.indexWhere(
      (ReponseEnAttente r) => r.cle == reponse.cle,
    );
    if (i >= 0) _enAttente[i] = reponse;
  }

  Future<bool> _envoyer(ReponseEnAttente reponse) async {
    setState(() => _remplacer(reponse.avecEchec(false)));
    try {
      await ref
          .read(portCommunauteProvider)
          .repondre(
            publicationId: _id,
            texte: reponse.texte,
            cleIdempotence: reponse.cle,
          );
    } on Object {
      if (mounted) setState(() => _remplacer(reponse.avecEchec(true)));
      return false;
    }
    if (!mounted) return true;
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
    return true;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
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
                  CapaciteIndisponible() => VueEtatCommunication(
                    etat: EtatCommunication.indisponible,
                    dependance: erreur.dependance,
                  ),
                  _ => VueEtatCommunication(
                    etat: horsLigne
                        ? EtatCommunication.horsLigne
                        : EtatCommunication.erreur,
                    onReessayer: reessayer,
                  ),
                },
            construire: (PublicationCommunaute publication) =>
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                  child: _contenu(publication),
                ),
          ),
        ),
        if (widget.peutRepondre && lue.hasValue && !lue.hasError) ...<Widget>[
          Ecart.vMd,
          // Le composer et son garde (R-01) restent bornes : au-dela d'un
          // peu moins de la moitie de la hauteur, ils defilent eux-memes et
          // la publication reste lisible (texte agrandi, petit ecran).
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.45,
            ),
            child: SingleChildScrollView(
              child: ComposerReponse(publicationId: _id, onEnvoyer: _repondre),
            ),
          ),
          Ecart.vLg,
        ],
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
        ref.watch(capacitesModerationCommunauteProvider).value?.peutSignaler ??
        false;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Le menu « ... » au bord de fin de la carte, jamais colle au nom
        // (revue COM-R, R-13).
        Row(
          children: <Widget>[
            Expanded(
              child: AvatarNom.enLigne(
                prenom: publication.auteur.nomAffiche,
                role: ligneAuteurCommunaute(
                  publication.auteur.fonction,
                  momentCommunaute(publication.publieeLe, maintenant),
                ),
                diametre: AppAvatar.petit,
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
        Ecart.vLg,
        Semantics(
          header: true,
          child: Text(
            publication.titre,
            key: PublicationDetail.cleTitre,
            style: palette.inkStrong.applyTo(
              textes.titleMedium ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vSm,
        Text(
          publication.texte,
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
