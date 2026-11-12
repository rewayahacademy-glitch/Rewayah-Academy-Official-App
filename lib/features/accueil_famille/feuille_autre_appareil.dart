// AUTRE-PROFIL-ELEVE (garde-cap, 12/11/2026) : le titulaire qui suit lui-meme
// des cours est un compte complet. Pour utiliser un autre appareil, il s'y
// connecte avec SON compte : aucun jumelage, aucun code. Le lien discret de
// l'accueil (TITULAIRE-SANS-APPAREIL, directeur, 11/11/2026) ouvrait la page
// d'appairage, que le serveur refuse toujours pour un compte tuteur
// (`creer_code_appairage` n'accepte qu'un profil eleve) : l'ecran disait
// « Profil eleve introuvable ». Il ouvre desormais cette feuille.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../admin_avis/lien_avis.dart' show origineParDefaut;
import '../compte/donnees_compte.dart';

/// L'adresse de l'application a ouvrir sur l'autre appareil : sur le Web,
/// celle de la page ouverte ; ailleurs, l'adresse de production
/// (`DECISION-DOMAINE-2026-10-23.md`). **Pure**, testee.
String adresseApplication({Uri? base}) {
  final Uri b = base ?? Uri.base;
  final bool web =
      (b.scheme == 'http' || b.scheme == 'https') && b.host.isNotEmpty;
  return web ? b.origin : origineParDefaut;
}

/// Ouvre la feuille « Utiliser un autre appareil » du titulaire.
Future<void> ouvrirFeuilleAutreAppareil(BuildContext context) =>
    AppBottomSheet.ouvrir<void>(
      context,
      titre: t.tuteur.accueil.autreAppareil,
      constructeur: (BuildContext _) => const CorpsAutreAppareil(),
    );

/// Le corps de la feuille : la consigne, l'adresse de l'application, celle du
/// compte, et la copie du lien. Sert aussi a la page d'appairage quand elle
/// recoit le titulaire ([AppairagePage]).
class CorpsAutreAppareil extends ConsumerStatefulWidget {
  /// Cree le corps.
  const CorpsAutreAppareil({this.base, super.key});

  /// L'adresse de la page (tests) ; `Uri.base` par defaut.
  final Uri? base;

  /// Le bouton de copie du lien.
  static const Key copierKey = Key('autreAppareil.copier');

  /// L'adresse de l'application affichee.
  static const Key adresseApplicationKey = Key('autreAppareil.application');

  /// L'adresse de connexion affichee.
  static const Key adresseConnexionKey = Key('autreAppareil.connexion');

  @override
  ConsumerState<CorpsAutreAppareil> createState() => _CorpsAutreAppareilState();
}

class _CorpsAutreAppareilState extends ConsumerState<CorpsAutreAppareil> {
  bool _copie = false;

  Future<void> _copier(String adresse) async {
    await Clipboard.setData(ClipboardData(text: adresse));
    if (!mounted) return;
    setState(() => _copie = true);
  }

  @override
  Widget build(BuildContext context) {
    final textes = t.tuteur.accueil.autreAppareilFeuille;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme theme = Theme.of(context).textTheme;
    final TextStyle base = theme.bodyMedium ?? const TextStyle();
    final String application = adresseApplication(base: widget.base);
    final String? courriel = ref
        .watch(identiteTitulaireProvider)
        .value
        ?.courriel;

    Widget valeur(String etiquette, String texte, Key cle) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(etiquette, style: palette.inkMuted.applyTo(base)),
        const SizedBox(height: AppSpacing.xs),
        // Une adresse se lit de gauche a droite, meme en arabe.
        Directionality(
          textDirection: TextDirection.ltr,
          child: SelectableText(
            texte,
            key: cle,
            style: palette.inkStrong.applyTo(theme.bodyLarge ?? base),
          ),
        ),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(textes.phrase, style: palette.inkStrong.applyTo(base)),
        const SizedBox(height: AppSpacing.sm),
        Text(textes.aucunCode, style: palette.inkMuted.applyTo(base)),
        const SizedBox(height: AppSpacing.lg),
        valeur(
          textes.adresseApplication,
          application,
          CorpsAutreAppareil.adresseApplicationKey,
        ),
        if (courriel != null && courriel.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          valeur(
            textes.adresseConnexion,
            courriel,
            CorpsAutreAppareil.adresseConnexionKey,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        ActionPrincipale(
          key: CorpsAutreAppareil.copierKey,
          libelle: _copie ? textes.copie : textes.copier,
          niveau: NiveauAction.secondaire,
          onPress: () => _copier(application),
        ),
      ],
    );
  }
}
