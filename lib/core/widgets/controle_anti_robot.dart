// ANTI-ROBOT (03/11/2026) : le controle « je ne suis pas un robot » d'un
// ecran de connexion, seul point d'entree de cette fonction (lib/CLAUDE.md).
//
// Presque invisible : le widget de Cloudflare ne prend de place que s'il
// demande une interaction. L'ecran dit seulement ce qui compte pour la
// personne : la verification tourne pendant un envoi, elle n'a pas abouti
// (« Reessayer »), ou le reseau ne repond pas. Jamais le mot « robot » a une
// famille (fiche PLAN-LOTS §13).
import 'package:flutter/material.dart';

import '../auth/anti_robot.dart';
import '../auth/rendu_turnstile.dart';
import '../i18n/strings.g.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'lien_fleche.dart';

/// Le controle pose sur un ecran.
class ControleAntiRobot extends StatefulWidget {
  /// Cree le controle.
  const ControleAntiRobot({
    required this.cle,
    required this.controleur,
    this.envoiEnCours = false,
    super.key,
  });

  /// La cle publique du site.
  final String cle;

  /// Le controleur qui recoit le jeton.
  final ControleurAntiRobot controleur;

  /// Vrai pendant un envoi : « Verification de securite en cours. » se dit
  /// tant que le jeton n'est pas pret.
  final bool envoiEnCours;

  /// La cle de l'element.
  static const Key cleControle = ValueKey<String>('controle-anti-robot');

  /// La cle de la phrase d'erreur.
  static const Key cleErreur = ValueKey<String>('controle-anti-robot-erreur');

  /// La largeur et la hauteur de la case de Cloudflare quand elle se montre.
  static const Size tailleCase = Size(300, 65);

  @override
  State<ControleAntiRobot> createState() => _ControleAntiRobotState();
}

class _ControleAntiRobotState extends State<ControleAntiRobot> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String langue = LocaleSettings.currentLocale.languageCode;
    return ListenableBuilder(
      listenable: widget.controleur,
      builder: (BuildContext context, Widget? _) {
        final EtatAntiRobot etat = widget.controleur.etat;
        final String? phrase = switch (etat) {
          EtatAntiRobot.erreur => t.connexion.controle.erreur,
          EtatAntiRobot.horsLigne => t.connexion.controle.horsLigne,
          EtatAntiRobot.chargement when widget.envoiEnCours =>
            t.connexion.controle.chargement,
          _ => null,
        };
        final bool echec =
            etat == EtatAntiRobot.erreur || etat == EtatAntiRobot.horsLigne;
        // CONNEXION-UX (03/11/2026) : l'ecart avec le champ qui precede ne se
        // pose que quand la case ou une phrase se montre ; sinon le controle
        // ne prend qu'un point de haut et la page reste celle d'avant.
        final bool montre = _visible || phrase != null;
        return Semantics(
          key: ControleAntiRobot.cleControle,
          container: true,
          label: t.connexion.controle.libelle,
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              top: montre ? AppSpacing.lg : 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // La case garde une place minime tant qu'elle est cachee : le
                // widget de Cloudflare doit rester dans la page pour travailler.
                Center(
                  child: SizedBox(
                    width: ControleAntiRobot.tailleCase.width,
                    height: _visible ? ControleAntiRobot.tailleCase.height : 1,
                    child: RenduTurnstile(
                      cle: widget.cle,
                      langue: langue,
                      controleur: widget.controleur,
                      onVisible: (bool v) {
                        if (mounted && v != _visible) {
                          setState(() => _visible = v);
                        }
                      },
                    ),
                  ),
                ),
                if (phrase != null) ...<Widget>[
                  Ecart.vSm,
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      phrase,
                      key: echec ? ControleAntiRobot.cleErreur : null,
                      style: (echec ? palette.inkAlert : palette.inkMuted)
                          .applyTo(textes.bodyMedium ?? const TextStyle()),
                    ),
                  ),
                ],
                if (echec) ...<Widget>[
                  Ecart.vXs,
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: LienFleche(
                      libelle: t.commun.reessayer,
                      onPress: widget.controleur.relancer,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
