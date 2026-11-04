import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session/deconnexion.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/marque_page.dart';
import '../../core/widgets/page_shell.dart';
import 'flux_mfa.dart';

/// Largeur de la carte, la meme que celle de la connexion.
const double _largeurCarte = 460;

/// La seconde etape de connexion du controleur (L1-10, decision A-02).
///
/// Elle s'affiche avant toute navigation tant que la capacite `mfaRequise`
/// est vraie : le routeur ne laisse rien d'autre atteignable. Reussir eleve le
/// jeton a `aal2` ; la session se met a jour et le routeur libere le compte.
/// Le flux lui-meme est [FluxMfa], partage avec la page Securite de la
/// direction.
class MfaControleurPage extends ConsumerWidget {
  /// Cree la page.
  const MfaControleurPage({super.key});

  /// La cle du champ du code.
  static const Key champCodeKey = FluxMfa.champCodeKey;

  /// La cle du bouton principal.
  static const Key boutonKey = FluxMfa.boutonKey;

  /// La cle du lien « je n'ai pas d'application ».
  static const Key sansApplicationKey = FluxMfa.sansApplicationKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget respiration = AppGabarit.de(context) == Gabarit.mobile
        ? Ecart.vXxl
        : Ecart.vSection;

    return PageShell(
      defilante: false,
      actionsCoquille: false,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints contraintes) =>
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: contraintes.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const MarquePage(),
                    respiration,
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _largeurCarte,
                      ),
                      child: FluxMfa(
                        onSeDeconnecter: () =>
                            unawaited(seDeconnecter(context, ref)),
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
