/// MFA-DIRECTION (garde-cap G12, pilote, 03/11/2026) : Compte > Securite de
/// la direction (`/compte/securite`).
///
/// La direction active une fois la double verification (TOTP) : QR, cle,
/// premier code, par le flux du controleur ([FluxMfa], `port_mfa`). Ensuite,
/// le code est demande au moment d'un geste qui l'exige
/// ([demanderDoubleVerification]), jamais a l'entree : la direction n'est pas
/// bloquee a la connexion (`mfaRequise` reste au seul controleur).
///
/// Le niveau `aal2` est pose par le serveur d'authentification ; rien ici ne
/// l'accorde. Etats : chargement, activee, a activer (enrolement), erreur,
/// hors ligne.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../mfa_controleur/flux_mfa.dart';
import '../mfa_controleur/port_mfa.dart';

/// La situation du second facteur du compte, relue a chaque ouverture.
final situationMfaProvider = FutureProvider.autoDispose<SituationMfa>(
  (Ref ref) => ref.watch(portMfaProvider).situation(),
  retry: (int _, Object _) => null,
);

/// La page Securite de la direction.
class DoubleVerificationPage extends ConsumerStatefulWidget {
  /// Cree la page.
  const DoubleVerificationPage({super.key});

  /// La carte « La double verification est activee ».
  static const Key activeeKey = ValueKey<String>('double-verification-activee');

  @override
  ConsumerState<DoubleVerificationPage> createState() =>
      _DoubleVerificationPageState();
}

class _DoubleVerificationPageState
    extends ConsumerState<DoubleVerificationPage> {
  /// Le premier code vient d'etre accepte, dans cette page.
  bool _activeeIci = false;

  @override
  Widget build(BuildContext context) {
    final d = t.compte.doubleVerification;
    return PageShell(
      titre: d.titre,
      sousTitre: d.sousTitre,
      onRetour: () => GoRouter.of(context).go(Routes.compte),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: _activeeIci
              ? const _Activee()
              : BlocAsynchrone<SituationMfa>(
                  valeur: ref.watch(situationMfaProvider),
                  squelette: const Skeleton.liste(lignes: 2),
                  onReessayer: () => ref.invalidate(situationMfaProvider),
                  erreurVersEtat: (Object e, VoidCallback? reessayer) =>
                      EtatSysteme(
                        nature: e is MfaHorsLigne
                            ? NatureEtat.horsLigne
                            : NatureEtat.echecServeur,
                        onAction: reessayer,
                      ),
                  construire: (SituationMfa s) => switch (s) {
                    MfaAVerifier() => const _Activee(),
                    MfaAEnroler() => FluxMfa(
                      titreEnrolement: d.titreEnrolement,
                      introEnrolement: d.introEnrolement,
                      videPhrase: d.videPhrase,
                      onReussi: () {
                        if (mounted) setState(() => _activeeIci = true);
                      },
                    ),
                  },
                ),
        ),
      ),
    );
  }
}

class _Activee extends StatelessWidget {
  const _Activee();

  @override
  Widget build(BuildContext context) {
    final d = t.compte.doubleVerification;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return Semantics(
      liveRegion: true,
      child: AppCard(
        key: DoubleVerificationPage.activeeKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(d.activeeTitre, style: textes.titleMedium),
            Ecart.vSm,
            Text(
              d.activeePhrase,
              style: palette.inkStrong.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
