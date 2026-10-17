/// RECRUT-ECRANS (2/5) : le code d'invitation du candidat enseignant.
/// Lot F2 : le meme ecran sert le candidat comptable (`comptable: true`),
/// sur ses propres ports de verification et son propre code retenu
/// (BF1-03) ; l'inscription appelle alors `inscrire_comptable_invite`.
///
/// Le candidat saisit son code (ou arrive par un lien qui le porte) ; le
/// serveur repond par l'une des quatre issues de [ResultatInvitation]
/// (contrat C-14) :
///
/// - valide : le code est retenu pour l'inscription et le formulaire s'ouvre ;
/// - expiree : « Cette invitation a expire », aucun champ, une demande de
///   nouvelle invitation a la direction ;
/// - deja utilisee : « Cette invitation a deja servi », et « Me connecter » ;
/// - inconnue : « Code non reconnu », ressaisie possible, sans rien reveler
///   (un code revoque et un code qui n'a jamais existe se disent pareil).
///
/// **Cette verification ne sert qu'a l'affichage.** Le serveur consomme le code
/// atomiquement a l'inscription et refuse tout code invalide, quoi qu'ait
/// montre cet ecran. Le code retenu ([codeInvitationRetenuProvider]) vit en
/// memoire, jamais sur disque.
///
/// Etats : saisie (contenu), verification en cours, quatre resultats, hors
/// ligne, erreur, et port absent (l'inscription garde alors son parcours
/// d'avant ; voir `UsageEtape`).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/dates_appareil.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/recrutement/ouvreur_lien.dart';
import '../../core/recrutement/port_invitations_comptable.dart';
import '../../core/recrutement/port_invitations_enseignant.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/zone_saisie.dart';
import '../inscription/brouillon_inscription.dart';
import '../inscription/code_comptable_retenu.dart';
import '../salle_seance/information_controle.dart' show InformationControle;

/// Ce que l'ecran montre apres la verification.
enum _Phase { saisie, verification, resultat, horsLigne, erreur }

/// L'ecran du code d'invitation.
class InvitationCandidatPage extends ConsumerStatefulWidget {
  /// Cree l'ecran ; [codeInitial] vient d'un lien d'invitation.
  const InvitationCandidatPage({
    super.key,
    this.codeInitial,
    this.comptable = false,
  });

  /// Le code porte par le lien, verifie des l'ouverture.
  final String? codeInitial;

  /// Vrai pour le candidat comptable (lot F2) : ports, code retenu et textes
  /// du comptable.
  final bool comptable;

  @override
  ConsumerState<InvitationCandidatPage> createState() =>
      _InvitationCandidatPageState();
}

class _InvitationCandidatPageState
    extends ConsumerState<InvitationCandidatPage> {
  late final TextEditingController _code;
  _Phase _phase = _Phase.saisie;
  ResultatInvitation? _resultat;
  bool _vide = false;
  bool _contactCopie = false;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.codeInitial ?? '');
    if ((widget.codeInitial ?? '').trim().isNotEmpty) {
      unawaited(Future<void>.microtask(_verifier));
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Provider<PortVerificationInvitation?> get _portVerification =>
      widget.comptable
      ? portVerificationInvitationComptableProvider
      : portVerificationInvitationProvider;

  CodeInvitationRetenu get _codeRetenu => ref.read(
    (widget.comptable
            ? codeComptableRetenuProvider
            : codeInvitationRetenuProvider)
        .notifier,
  );

  Future<void> _verifier() async {
    final PortVerificationInvitation? port = ref.read(_portVerification);
    final String saisi = _code.text.trim();
    if (saisi.isEmpty) {
      setState(() => _vide = true);
      return;
    }
    if (port == null) return;
    setState(() {
      _vide = false;
      _phase = _Phase.verification;
      _contactCopie = false;
    });
    _Phase phase;
    ResultatInvitation? resultat;
    try {
      resultat = await port.verifierInvitation(saisi);
      phase = _Phase.resultat;
    } on HorsLigne {
      phase = _Phase.horsLigne;
    } on Object {
      phase = _Phase.erreur;
    }
    if (!mounted) return;
    if (resultat is InvitationValide) {
      _codeRetenu.retenir(saisi);
    } else {
      _codeRetenu.oublier();
    }
    setState(() {
      _phase = phase;
      _resultat = resultat;
    });
  }

  void _ressaisir() {
    _code.clear();
    _codeRetenu.oublier();
    setState(() {
      _phase = _Phase.saisie;
      _resultat = null;
      _vide = false;
    });
  }

  void _creerProfil() {
    ref
        .read(brouillonInscriptionProvider.notifier)
        .choisirUsage(
          widget.comptable
              ? UsageInscription.comptable
              : UsageInscription.enseignant,
        );
    GoRouter.of(context).go(Routes.inscriptionIdentite);
  }

  Future<void> _demanderNouvelle() async {
    final ResultatOuverture r = await ref.read(ouvreurLienProvider)(
      Uri(scheme: 'mailto', path: InformationControle.contactConfidentialite),
    );
    if (mounted && r == ResultatOuverture.copie) {
      setState(() => _contactCopie = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = t.recrutement.candidat;
    final bool capable = ref.watch(_portVerification) != null;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final String titre = widget.comptable ? r.comptable.titre : r.titre;

    return PageShell(
      titre: titre,
      onRetour: () => GoRouter.of(context).go(Routes.inscriptionUsage),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: !capable
              ? EtatSysteme(
                  key: const ValueKey<String>('candidat-indisponible'),
                  nature: NatureEtat.indisponible,
                  titre: titre,
                  phrase: widget.comptable
                      ? r.comptable.indisponible
                      : r.indisponible,
                  dependance: widget.comptable
                      ? dependanceInvitationsComptable
                      : dependanceInvitations,
                )
              : _corps(horsLigne),
        ),
      ),
    );
  }

  Widget _corps(bool horsLigne) {
    final r = t.recrutement.candidat;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle doux = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final ResultatInvitation? res = _resultat;

    // Les trois issues qui ferment la saisie : aucun champ (expiree, valide)
    // ou un message puis la ressaisie (inconnue, deja utilisee).
    if (_phase == _Phase.resultat && res != null) {
      return switch (res) {
        InvitationValide(:final DateTime expireLe) => EmptyState(
          key: const ValueKey<String>('candidat-valide'),
          message: r.valide(date: dateDeLAppareil(expireLe.toLocal())),
          invitation: widget.comptable
              ? r.comptable.valideDetail
              : r.valideDetail,
          icone: AppIcons.invitationAcceptee,
          libelleAction: r.creerProfil,
          onAction: _creerProfil,
        ),
        InvitationExpiree() => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            EmptyState(
              key: const ValueKey<String>('candidat-expiree'),
              message: r.expiree,
              invitation: r.expireeDetail,
              icone: AppIcons.invitationExpiree,
              libelleAction: r.demanderNouvelle,
              onAction: () => unawaited(_demanderNouvelle()),
            ),
            if (_contactCopie) ...<Widget>[
              Ecart.vMd,
              Semantics(
                liveRegion: true,
                child: Text(
                  r.contactCopie,
                  textAlign: TextAlign.center,
                  style: doux,
                ),
              ),
            ],
            Ecart.vMd,
            LienFleche(libelle: r.ressaisir, onPress: _ressaisir),
          ],
        ),
        InvitationDejaUtilisee() => EmptyState(
          key: const ValueKey<String>('candidat-deja-utilisee'),
          message: r.dejaUtilisee,
          invitation: r.dejaUtiliseeDetail,
          icone: AppIcons.invitationRefusee,
          libelleAction: r.seConnecter,
          onAction: () => GoRouter.of(context).go(Routes.connexion),
        ),
        InvitationInconnue() => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            EmptyState(
              key: const ValueKey<String>('candidat-inconnue'),
              message: r.inconnue,
              invitation: r.inconnueDetail,
              icone: AppIcons.invitationRefusee,
            ),
            Ecart.vMd,
            LienFleche(libelle: r.ressaisir, onPress: _ressaisir),
          ],
        ),
      };
    }

    final bool enCours = _phase == _Phase.verification;
    final String? message = switch (_phase) {
      _Phase.horsLigne => r.horsLigne,
      _Phase.erreur => r.erreur,
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(widget.comptable ? r.comptable.intro : r.intro, style: doux),
        Ecart.vLg,
        ZoneSaisie(
          controleur: _code,
          cleChamp: const ValueKey<String>('candidat-code'),
          libelle: r.champ,
          majuscules: TextCapitalization.characters,
          actionClavier: TextInputAction.done,
          erreur: _vide ? r.champVide : null,
          lectureSeule: enCours,
          onChanged: (_) {
            if (_vide) setState(() => _vide = false);
          },
          onSubmitted: (_) => unawaited(_verifier()),
        ),
        if (message != null) ...<Widget>[
          Ecart.vMd,
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              key: const ValueKey<String>('candidat-message'),
              style: palette.inkAlert.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
        Ecart.vMd,
        ActionPrincipale(
          key: const ValueKey<String>('candidat-verifier'),
          libelle: r.verifier,
          enCours: enCours,
          // Hors ligne, la verification ne peut pas aboutir : le bouton n'est
          // pas rendu, la phrase du bandeau le dit.
          onPress: enCours || horsLigne ? null : () => unawaited(_verifier()),
        ),
      ],
    );
  }
}
