import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';

/// Le QR d'appairage : noir sur blanc dans LES DEUX themes.
///
/// Un QR inverse (modules clairs sur fond sombre) n'est pas decode par une
/// bonne partie des lecteurs (C05 section 3.2 point 9, manifeste section
/// 3.5 : « le QR reste noir sur blanc pour le scan »). La paire est donc
/// prise dans la palette CLAIRE quel que soit le theme affiche : fond
/// `surfaceRaised` blanc, encre `#110E20`. Une paire dediee est demandee au
/// coordinateur (`demandes/D.md`), sans changement de jeton ici.
///
/// Le QR ne porte que le code brut : ni adresse, ni identifiant de foyer. Ce
/// qu'un tiers photographie ne lui apprend rien de plus que le code ecrit en
/// dessous.
class EmetteurQr extends StatelessWidget {
  /// Cree le QR d'un code, dans un carre de [cote] pixels logiques.
  const EmetteurQr({required this.code, required this.cote, super.key});

  /// Le code a six caracteres.
  final String code;

  /// Le cote du carre blanc, marge de silence comprise.
  final double cote;

  /// Modules d'un QR de version 1 (six caracteres alphanumeriques).
  static const int _modules = 21;

  /// La marge de silence recommandee : quatre modules de chaque cote.
  static const int _modulesSilence = 4;

  /// La paire du QR, identique en clair et en sombre.
  static AppColorPair get paire => AppPalette.claire().surfaceRaised;

  @override
  Widget build(BuildContext context) {
    final AppColorPair couleurs = paire;
    final double marge =
        cote * _modulesSilence / (_modules + 2 * _modulesSilence);

    return Semantics(
      image: true,
      label: t.appareils.emetteur.libelleQr,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: cote,
          child: DecoratedBox(
            // Le filet suit le theme : il detache le carre blanc du fond clair
            // sans toucher aux modules.
            decoration: couleurs.decoration(
              borderRadius: AppRadius.arrondiSm,
              side: AppPalette.of(context).borderHairline.asBorderSide(),
            ),
            child: Padding(
              padding: EdgeInsets.all(marge),
              child: QrImageView(
                data: code,
                padding: EdgeInsets.zero,
                size: cote - 2 * marge,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
                backgroundColor: couleurs.background,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: couleurs.onBackground,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: couleurs.onBackground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Le code en clair, espace pour etre lu a voix haute sans se tromper.
///
/// Chiffres tabulaires (`AppTypography.chiffre`, 0b section 5, lot D) : DM
/// Sans n'en a pas, et un code dont les caracteres dansent se recopie mal.
class CodeEnClair extends StatelessWidget {
  /// Cree l'affichage d'un code.
  const CodeEnClair({required this.code, super.key});

  /// Le code a six caracteres.
  final String code;

  /// Le code espace, tel qu'il est affiche et lu.
  static String espace(String code) => code.split('').join(' ');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final String lisible = espace(code);

    return Semantics(
      label: t.appareils.emetteur.codeLu(code: lisible),
      excludeSemantics: true,
      child: Text(
        lisible,
        textAlign: TextAlign.center,
        style: palette.inkStrong.applyTo(AppTypography.chiffre()),
      ),
    );
  }
}
