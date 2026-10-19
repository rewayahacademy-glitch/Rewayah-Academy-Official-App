import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/protection_enfants/responsable_protection.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/skeleton.dart';
import '../salle_seance/information_controle.dart';

/// Qui recoit un signalement de securite d'un enfant (PE, 18/10/2026).
///
/// Lit le responsable saisi par l'administration
/// ([responsableProtectionProvider]). **Vide, la phrase est « La direction
/// recoit votre signalement. »** ; nomme, elle dit qui, avec le courriel de
/// contact quand il existe. Les cinq etats :
/// - chargement : un squelette de deux lignes ;
/// - contenu : la phrase ci-dessus ;
/// - vide : la phrase « La direction recoit votre signalement. » (reglage vide,
///   cas normal tant que l'administration n'a rien saisi) ;
/// - erreur : la lecture n'a pas abouti, la phrase le dit et propose de
///   reessayer, sans pretendre que le reglage est vide ;
/// - hors ligne : meme rendu que l'erreur (la lecture passe par le reseau).
class LigneResponsableProtection extends ConsumerWidget {
  /// Cree la ligne.
  const LigneResponsableProtection({super.key});

  /// La cle de la phrase affichee.
  static const Key phraseKey = ValueKey<String>(
    'responsable-protection-phrase',
  );

  /// La cle de l'etat d'erreur.
  static const Key erreurKey = ValueKey<String>(
    'responsable-protection-erreur',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ResponsableProtection> lecture = ref.watch(
      responsableProtectionProvider,
    );
    final TextStyle style = AppPalette.of(context).inkMuted
        .applyTo(Theme.of(context).textTheme.bodyMedium ?? const TextStyle());

    if (lecture.hasValue) {
      final ResponsableProtection r = lecture.requireValue;
      final String phrase = r.estNomme
          ? t.protectionEnfants.recuPar(nom: r.nom)
          : t.protectionEnfants.direction;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TexteSansCoupure(phrase, key: phraseKey, style: style),
          if (r.aUnCourriel)
            Text(
              coupuresAdresse(
                t.protectionEnfants.contact(courriel: r.courriel),
              ),
              style: style,
            ),
        ],
      );
    }
    if (lecture.hasError) {
      return Column(
        key: erreurKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TexteSansCoupure(t.protectionEnfants.erreurLecture, style: style),
          LienFleche(
            libelle: t.commun.reessayer,
            onPress: () => ref.invalidate(responsableProtectionProvider),
          ),
        ],
      );
    }
    return const Skeleton.texte(lignes: 2);
  }
}
