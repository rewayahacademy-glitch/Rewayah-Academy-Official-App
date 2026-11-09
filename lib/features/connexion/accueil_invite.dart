/// ACCUEIL-INVITE (09/11/2026, lot correctif INVITATION-COMPTE, consigne du
/// directeur transmise par le pilote) : un seul accueil pour toutes les
/// personnes invitees, « Rewayah Academy vous invite en tant que … ».
///
/// Le role se lit cote serveur (`mon_invitation_accueil`, migration
/// 20261122600000), jamais dans l'adresse ni sur l'appareil. L'accueil se
/// pose devant l'inscription (`/inscription`), qui n'est atteinte que par une
/// session sans profil :
/// - invitee dans un foyer : prenom, nom, genre, puis « Accepter
///   l'invitation » cree son compte DANS le foyer qui invite
///   (`accepter_invitation_nouveau_compte`, decision du directeur du
///   09/11/2026 : aucun compte avant l'acceptation) ; « Refuser » ne cree
///   rien (`refuser_invitation_sans_compte`). Avant ce lot, elle tombait dans
///   le questionnaire des familles et l'invitation restait invisible ;
/// - enseignant, comptable, candidat : « Continuer » ouvre leur inscription
///   habituelle, qui reprend leur code ;
/// - sans invitation : l'inscription habituelle, sans attente visible.
///
/// Etats : chargement (`Skeleton`), contenu, echec de lecture (la phrase et
/// « Reessayer » : on ne devine pas qu'il n'y a pas d'invitation), vide
/// (l'inscription habituelle), hors ligne (le bandeau de la page ; l'envoi
/// echoue en erreur dite).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';

/// Le role pour lequel une adresse est invitee.
enum RoleInvite {
  /// La personne invitee dans un foyer (second adulte).
  foyer('foyer'),

  /// Un enseignant invite par la direction.
  enseignant('enseignant'),

  /// Un comptable invite par la direction.
  comptable('comptable'),

  /// Le candidat d'un formulaire importe.
  candidat('candidat');

  const RoleInvite(this.valeur);

  /// La valeur rendue par le serveur.
  final String valeur;
}

/// Ce que `mon_invitation_accueil` rend pour une adresse invitee.
@immutable
class InvitationAccueil {
  /// Cree l'invitation lue.
  const InvitationAccueil({required this.role, this.prenomInvitant});

  /// Lit la reponse du serveur ; `null` sans invitation, ou pour une forme
  /// inconnue (jamais un role suppose).
  static InvitationAccueil? depuisJson(Object? brut) {
    if (brut is! Map || brut['etat'] != 'invite') return null;
    final Object? role = brut['role'];
    for (final RoleInvite r in RoleInvite.values) {
      if (r.valeur == role) {
        final Object? prenom = brut['prenom_invitant'];
        return InvitationAccueil(
          role: r,
          prenomInvitant: prenom is String && prenom.trim().isNotEmpty
              ? prenom.trim()
              : null,
        );
      }
    }
    return null;
  }

  /// Le role.
  final RoleInvite role;

  /// Le prenom de la personne qui invite au foyer, ou nul.
  final String? prenomInvitant;
}

/// L'issue d'une reponse de la personne invitee dans un foyer, sans profil
/// (`accepter_invitation_nouveau_compte`, `refuser_invitation_sans_compte`).
enum IssueReponseInvite {
  /// Acceptee : le compte est cree dans le foyer qui invite ; la session se
  /// relit.
  acceptee,

  /// Refusee : rien n'est cree.
  refusee,

  /// L'invitation ne sert plus (echue, annulee).
  perimee,

  /// Ce compte ne peut pas repondre (adresse non confirmee, foyer qui
  /// n'invite plus, compte qui a deja un profil).
  nonAcceptable,
}

/// La porte vers le serveur.
abstract interface class PortAccueilInvite {
  /// L'invitation de la session sans profil, ou `null`. Une panne remonte.
  Future<InvitationAccueil?> lire();

  /// Accepte l'invitation de foyer en creant le compte (decision du directeur
  /// du 09/11/2026 : le profil nait a l'acceptation, dans le foyer qui
  /// invite). [cle] rend la nouvelle tentative sure. Une panne remonte.
  Future<IssueReponseInvite> accepter({
    required String prenom,
    required String nom,
    required Genre genre,
    required String cle,
  });

  /// Refuse l'invitation de foyer sans rien creer. Une panne remonte.
  Future<IssueReponseInvite> refuser({required String cle});
}

/// Le port ; `null` sans serveur (tests, demonstration) : l'inscription
/// habituelle s'ouvre, sans accueil.
final Provider<PortAccueilInvite?> portAccueilInviteProvider =
    Provider<PortAccueilInvite?>((Ref _) => null);

/// L'invitation lue, une fois par session.
final FutureProvider<InvitationAccueil?> invitationAccueilProvider =
    FutureProvider<InvitationAccueil?>((Ref ref) async {
      return ref.watch(portAccueilInviteProvider)?.lire();
    });

/// Pose l'accueil des personnes invitees devant [enfant] (l'inscription).
class PorteAccueilInvite extends ConsumerStatefulWidget {
  /// Cree la porte.
  const PorteAccueilInvite({required this.enfant, super.key});

  /// L'inscription habituelle.
  final Widget enfant;

  @override
  ConsumerState<PorteAccueilInvite> createState() => _PorteAccueilInviteState();
}

class _PorteAccueilInviteState extends ConsumerState<PorteAccueilInvite> {
  /// La personne a choisi « Continuer » vers son inscription habituelle.
  bool _passee = false;

  @override
  Widget build(BuildContext context) {
    if (_passee || ref.watch(portAccueilInviteProvider) == null) {
      return widget.enfant;
    }
    final AsyncValue<InvitationAccueil?> lecture = ref.watch(
      invitationAccueilProvider,
    );
    if (lecture.hasValue && !lecture.isLoading) {
      final InvitationAccueil? invitation = lecture.value;
      if (invitation == null) return widget.enfant;
      return AccueilInvitePage(
        invitation: invitation,
        onContinuer: () => setState(() => _passee = true),
      );
    }
    // Chargement ou echec : on ne devine pas qu'il n'y a pas d'invitation.
    return PageShell(
      child: BlocAsynchrone<InvitationAccueil?>(
        valeur: lecture,
        squelette: const Skeleton.texte(lignes: 4),
        onReessayer: () => ref.invalidate(invitationAccueilProvider),
        construire: (InvitationAccueil? _) => const SizedBox.shrink(),
      ),
    );
  }
}

/// L'accueil : une phrase qui dit pour quoi la personne est invitee, puis,
/// pour un foyer, son nom et son genre.
class AccueilInvitePage extends ConsumerStatefulWidget {
  /// Cree l'accueil.
  const AccueilInvitePage({
    required this.invitation,
    required this.onContinuer,
    super.key,
  });

  /// L'invitation lue au serveur.
  final InvitationAccueil invitation;

  /// Ouvre l'inscription habituelle (enseignant, comptable, candidat, ou
  /// apres un refus).
  final VoidCallback onContinuer;

  /// La cle de « Continuer » (enseignant, comptable, candidat, apres un refus).
  static const Key continuerKey = ValueKey<String>('accueil-invite-continuer');

  /// La cle de « Accepter l'invitation ».
  static const Key accepterKey = ValueKey<String>('accueil-invite-accepter');

  /// La cle de « Refuser l'invitation ».
  static const Key refuserKey = ValueKey<String>('accueil-invite-refuser');

  /// La cle du champ du prenom.
  static const Key prenomKey = ValueKey<String>('accueil-invite-prenom');

  /// La cle du champ du nom.
  static const Key nomKey = ValueKey<String>('accueil-invite-nom');

  /// La cle du choix du genre.
  static const Key genreKey = ValueKey<String>('accueil-invite-genre');

  @override
  ConsumerState<AccueilInvitePage> createState() => _AccueilInvitePageState();
}

class _AccueilInvitePageState extends ConsumerState<AccueilInvitePage> {
  final TextEditingController _prenom = TextEditingController();
  final TextEditingController _nom = TextEditingController();

  /// Une cle par reponse : une nouvelle tentative apres une coupure reprend
  /// la meme.
  final String _cleAccepter = const Uuid().v4();
  final String _cleRefuser = const Uuid().v4();
  Genre? _genre;
  bool _enCours = false;
  bool _refusee = false;
  String? _erreur;

  bool get _foyer => widget.invitation.role == RoleInvite.foyer;

  @override
  void dispose() {
    _prenom.dispose();
    _nom.dispose();
    super.dispose();
  }

  void _echec(String phrase) {
    if (mounted) {
      setState(() {
        _enCours = false;
        _erreur = phrase;
      });
    }
  }

  String _phraseIssue(IssueReponseInvite issue) => switch (issue) {
    IssueReponseInvite.perimee => t.adulte.acceptation.perimee,
    _ => t.adulte.acceptation.impossible,
  };

  Future<void> _accepter() async {
    if (_enCours) return;
    final Genre? genre = _genre;
    if (_prenom.text.trim().isEmpty ||
        _nom.text.trim().isEmpty ||
        genre == null) {
      setState(() => _erreur = t.accueilInvite.champsRequis);
      return;
    }
    final PortAccueilInvite? port = ref.read(portAccueilInviteProvider);
    if (port == null) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    final IssueReponseInvite issue;
    try {
      issue = await port.accepter(
        prenom: _prenom.text.trim(),
        nom: _nom.text.trim(),
        genre: genre,
        cle: _cleAccepter,
      );
    } on Object {
      // Le serveur fait foi : sans reponse, rien n'est dit accepte.
      final a = t.adulte.acceptation;
      _echec('${a.acceptationEchecTitre} ${a.echecPhrase}');
      return;
    }
    if (issue != IssueReponseInvite.acceptee) {
      _echec(_phraseIssue(issue));
      return;
    }
    try {
      // Le role et le foyer entrent dans le jeton par le hook de la base :
      // le jeton emis avant la creation du profil ne les porte pas.
      await ref.read(sourceSessionProvider).rafraichir();
    } on Object {
      _echec(t.inscription.erreurActualisation);
      return;
    }
    if (mounted) {
      // Le routeur decide : l'accueil du tuteur, dans le foyer rejoint.
      GoRouter.of(context).go(Routes.racine);
    }
  }

  Future<void> _refuser() async {
    if (_enCours) return;
    final PortAccueilInvite? port = ref.read(portAccueilInviteProvider);
    if (port == null) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    final IssueReponseInvite issue;
    try {
      issue = await port.refuser(cle: _cleRefuser);
    } on Object {
      final a = t.adulte.acceptation;
      _echec('${a.refusEchecTitre} ${a.echecPhrase}');
      return;
    }
    if (issue != IssueReponseInvite.refusee) {
      _echec(_phraseIssue(issue));
      return;
    }
    if (mounted) {
      setState(() {
        _enCours = false;
        _refusee = true;
      });
    }
  }

  String _role() => switch (widget.invitation.role) {
    RoleInvite.foyer => t.accueilInvite.roles.foyer,
    RoleInvite.enseignant => t.accueilInvite.roles.enseignant,
    RoleInvite.comptable => t.accueilInvite.roles.comptable,
    RoleInvite.candidat => t.accueilInvite.roles.candidat,
  };

  @override
  Widget build(BuildContext context) {
    final a = t.accueilInvite;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle corps = textes.bodyLarge ?? const TextStyle();
    final String? prenom = widget.invitation.prenomInvitant;
    final bool repondre = _foyer && !_refusee;
    return PageShell(
      titre: a.titre,
      actions: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (_erreur != null) ...<Widget>[
            Semantics(
              liveRegion: true,
              child: Text(
                _erreur!,
                textAlign: TextAlign.center,
                style: palette.inkAlert.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vMd,
          ],
          // Un seul bouton plein : « Accepter l'invitation » tant que la
          // personne invitee dans un foyer n'a pas repondu, « Continuer »
          // sinon (enseignant, comptable, candidat, ou apres un refus).
          ActionPrincipale(
            key: repondre
                ? AccueilInvitePage.accepterKey
                : AccueilInvitePage.continuerKey,
            libelle: repondre
                ? t.adulte.acceptation.accepter
                : t.commun.continuer,
            // `_accepter` et `_refuser` ignorent un second appui pendant l'envoi.
            onPress: repondre ? _accepter : widget.onContinuer,
            enCours: repondre && _enCours,
          ),
          if (repondre) ...<Widget>[
            Ecart.vXs,
            Center(
              child: ActionPrincipale(
                key: AccueilInvitePage.refuserKey,
                libelle: t.adulte.acceptation.refuser,
                niveau: NiveauAction.tertiaire,
                pleineLargeur: false,
                onPress: _refuser,
              ),
            ),
          ],
        ],
      ),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TexteSansCoupure(
                _role(),
                style: palette.inkStrong.applyTo(corps),
              ),
              if (_foyer && prenom != null) ...<Widget>[
                Ecart.vSm,
                TexteSansCoupure(
                  a.invitant(prenom: isolerSens(prenom)),
                  style: palette.inkStrong.applyTo(corps),
                ),
              ],
              Ecart.vMd,
              if (_refusee) ...<Widget>[
                // Refus : rien n'est cree ; « Continuer » ouvre
                // l'inscription habituelle (sous admission).
                Semantics(
                  liveRegion: true,
                  child: TexteSansCoupure(
                    t.adulte.acceptation.refuseeTitre,
                    style: palette.inkStrong.applyTo(corps),
                  ),
                ),
              ] else
                TexteSansCoupure(
                  _foyer ? a.foyerIdentite : a.suite,
                  style: palette.inkMuted.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
              if (_foyer && !_refusee) ...<Widget>[
                Ecart.vXl,
                TextField(
                  key: AccueilInvitePage.prenomKey,
                  controller: _prenom,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.givenName],
                  onChanged: (String _) => setState(() => _erreur = null),
                  decoration: InputDecoration(labelText: t.inscription.prenom),
                ),
                Ecart.vMd,
                TextField(
                  key: AccueilInvitePage.nomKey,
                  controller: _nom,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  autofillHints: const <String>[AutofillHints.familyName],
                  onChanged: (String _) => setState(() => _erreur = null),
                  decoration: InputDecoration(labelText: t.inscription.nom),
                ),
                Ecart.vXl,
                Text(
                  t.inscription.genreQuestion,
                  style: palette.inkStrong.applyTo(corps),
                ),
                Ecart.vSm,
                ChoiceCardGroup(
                  key: AccueilInvitePage.genreKey,
                  autoriserSaisieLibre: false,
                  coteACote: true,
                  // Deux choix egaux a toutes les largeurs, jamais de bento.
                  choixEgaux: true,
                  options: <OptionChoix>[
                    OptionChoix(
                      valeur: Genre.homme.name,
                      libelle: t.inscription.genreHomme,
                      icone: AppIcons.homme,
                    ),
                    OptionChoix(
                      valeur: Genre.femme.name,
                      libelle: t.inscription.genreFemme,
                      icone: AppIcons.femme,
                    ),
                  ],
                  onChange: (ReponseChoix reponse) {
                    for (final Genre g in Genre.values) {
                      if (reponse.valeurs.contains(g.name)) {
                        setState(() {
                          _genre = g;
                          _erreur = null;
                        });
                      }
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
