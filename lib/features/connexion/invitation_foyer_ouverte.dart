/// INVITATION-SECOND-ADULTE (07/11/2026) : le lien d'une invitation de foyer
/// (`/connexion?mode=creer&foyer=1&code=...`) ouvert alors qu'un compte est
/// deja connecte. Rien n'est consomme : la page lit seulement si le code est
/// pour l'adresse de ce compte (`invitation_foyer_pour_moi`).
///
/// - pour cette adresse : l'accueil, ou la carte « invitation recue » attend ;
/// - pour une autre : « Cette invitation est pour une autre adresse :
///   deconnectez-vous pour l'ouvrir. », et « Se deconnecter » ramene au lien ;
/// - plus valable : la phrase le dit, avec quoi faire.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/session/deconnexion.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import 'invitation_compte.dart';

/// La lecture du code, une par code.
final FutureProviderFamily<EtatInvitationPourMoi, String>
invitationPourMoiProvider =
    FutureProvider.family<EtatInvitationPourMoi, String>(
      (Ref ref, String code) =>
          ref.watch(portInvitationCompteProvider).pourMoi(code),
    );

/// La page.
class InvitationFoyerOuvertePage extends ConsumerWidget {
  /// Cree la page.
  const InvitationFoyerOuvertePage({required this.code, super.key});

  /// Le code porte par le lien.
  final String code;

  /// L'etat « autre adresse ».
  static const Key autreAdresseKey = Key('invitationFoyer.autreAdresse');

  /// L'etat « plus valable ».
  static const Key plusValableKey = Key('invitationFoyer.plusValable');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void accueil() => GoRouter.of(context).go(Routes.racine);
    final AsyncValue<EtatInvitationPourMoi> lu = ref.watch(
      invitationPourMoiProvider(code),
    );
    final Widget contenu = switch (lu) {
      AsyncData<EtatInvitationPourMoi>(value: EtatInvitationPourMoi.pourVous) =>
        _VersAccueil(onAller: accueil),
      AsyncData<EtatInvitationPourMoi>(
        value: EtatInvitationPourMoi.autreAdresse,
      ) =>
        EtatSysteme(
          key: autreAdresseKey,
          nature: NatureEtat.accesRefuse,
          titre: t.connexion.invitationFoyer.autreAdresse,
          phrase: t.connexion.invitationFoyer.autreAdressePhrase,
          libelleAction: t.compte.deconnexion,
          onAction: () => unawaited(_deconnecterPuisOuvrir(context, ref)),
          libelleSecondaire: t.commun.etats.actions.retourAccueil,
          onSecondaire: accueil,
        ),
      AsyncData<EtatInvitationPourMoi>() => EtatSysteme(
        key: plusValableKey,
        nature: NatureEtat.ressourceExpiree,
        titre: t.connexion.invitationFoyer.plusValable,
        phrase: t.connexion.invitationFoyer.plusValablePhrase,
        libelleAction: t.commun.etats.actions.retourAccueil,
        onAction: accueil,
      ),
      AsyncError<EtatInvitationPourMoi>() => EtatSysteme(
        nature: NatureEtat.echecServeur,
        onAction: () => ref.invalidate(invitationPourMoiProvider(code)),
      ),
      _ => const Skeleton.texte(lignes: 2),
    };
    return PageShell(
      titre: t.connexion.invitationFoyer.titre,
      onRetour: accueil,
      child: contenu,
    );
  }

  /// Se deconnecter, puis rouvrir le lien : la creation du compte de
  /// l'adresse invitee reprend la ou elle doit.
  Future<void> _deconnecterPuisOuvrir(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final GoRouter routeur = GoRouter.of(context);
    final bool fait = await seDeconnecter(context, ref);
    if (!fait) return;
    routeur.go(
      Uri(
        path: Routes.connexion,
        queryParameters: <String, String>{
          'mode': 'creer',
          'foyer': '1',
          'code': code,
        },
      ).toString(),
    );
  }
}

/// Pour cette adresse : l'accueil, ou la carte « invitation recue » attend.
class _VersAccueil extends StatefulWidget {
  const _VersAccueil({required this.onAller});

  final VoidCallback onAller;

  @override
  State<_VersAccueil> createState() => _VersAccueilState();
}

class _VersAccueilState extends State<_VersAccueil> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) widget.onAller();
    });
  }

  @override
  Widget build(BuildContext context) => const Skeleton.texte(lignes: 2);
}
