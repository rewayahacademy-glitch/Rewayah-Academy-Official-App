// ANTI-ROBOT (03/11/2026) : le controle « je ne suis pas un robot » d'un
// ecran de connexion, seul point d'entree de cette fonction (lib/CLAUDE.md).
//
// Presque invisible : le widget de Cloudflare ne prend de place que s'il
// demande une interaction. L'ecran dit seulement ce qui compte pour la
// personne : la verification tourne pendant un envoi, elle n'a pas abouti
// (« Reessayer »), ou le reseau ne repond pas. Jamais le mot « robot » a une
// famille (fiche PLAN-LOTS §13).
import 'package:flutter/material.dart';

import '../agent/recharger_adresse.dart';
import '../auth/anti_robot.dart';
import '../auth/rendu_turnstile.dart';
import '../i18n/strings.g.dart';
import '../theme/app_mouvement.dart';
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
    this.googlePropose = false,
    super.key,
  });

  /// La cle publique du site.
  final String cle;

  /// Le controleur qui recoit le jeton.
  final ControleurAntiRobot controleur;

  /// Vrai pendant un envoi : « Verification de securite en cours. » se dit
  /// tant que le jeton n'est pas pret.
  final bool envoiEnCours;

  /// PE-A5 : vrai quand l'ecran offre aussi Google (qui ne passe pas par ce
  /// controle) ; l'echec le rappelle alors en une phrase.
  final bool googlePropose;

  /// La cle de l'element.
  static const Key cleControle = ValueKey<String>('controle-anti-robot');

  /// La cle de la phrase d'erreur.
  static const Key cleErreur = ValueKey<String>('controle-anti-robot-erreur');

  /// La cle du lien « Recharger la page » (PE-A5).
  static const Key cleRecharger = ValueKey<String>(
    'controle-anti-robot-recharger',
  );

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
          EtatAntiRobot.erreur => phraseEchecControle(
            widget.controleur.cause,
            widget.controleur.echecs,
          ),
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
        // CAPTCHA-PLACE (directeur, 16/11/2026 ; DECISION-FLUIDITE) : la case
        // apparait et disparait sans saut : la hauteur s'anime (`AnimatedSize`),
        // environ 200 ms ; sous « reduire les animations », sans duree. Le
        // fondu de la case est retire (PE-A5, voir plus bas).
        final Duration duree = AppMouvement.duree(
          context,
          AppMouvement.apparition,
        );
        return Semantics(
          key: ControleAntiRobot.cleControle,
          container: true,
          label: t.connexion.controle.libelle,
          child: AnimatedSize(
            duration: duree,
            curve: AppMouvement.entree,
            alignment: AlignmentDirectional.topCenter,
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
                  // Sur la largeur du champ (taille `flexible` de Cloudflare, 300
                  // au moins) : l'element HTML est en bloc et rogne a cette
                  // place (`styleHoteTurnstile`, PE-CASE-VERIFICATION) ; il ne
                  // deborde plus sur le bouton quand la place se referme.
                  //
                  // PE-A5 (20/11/2026) : JAMAIS d'opacite nulle ici. Flutter ne
                  // peint pas l'enfant d'une opacite 0 (`RenderAnimatedOpacity`,
                  // `_alpha == 0`) : l'element HTML de Cloudflare sortait alors
                  // de la page, la verification ne tournait jamais et aucun lien
                  // ne partait (production : plus aucun lien envoye depuis le
                  // 17/11, date du fondu ajoute par CAPTCHA-PLACE). La case
                  // invisible de Cloudflare ne montre rien tant qu'elle ne
                  // demande rien ; la hauteur seule s'anime (`AnimatedSize`).
                  SizedBox(
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
                  // PE-A5 : la sortie de secours. « Reessayer » rend le widget
                  // a neuf ; « Recharger la page » recharge aussi le script de
                  // Cloudflare (reseau, script bloque) ; l'adresse, et donc la
                  // marque du candidat, reste la meme.
                  if (echec) ...<Widget>[
                    if (widget.googlePropose) ...<Widget>[
                      Ecart.vXs,
                      Text(
                        t.connexion.controle.autreCheminGoogle,
                        style: palette.inkMuted.applyTo(
                          textes.bodyMedium ?? const TextStyle(),
                        ),
                      ),
                    ],
                    Ecart.vXs,
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: LienFleche(
                        libelle: t.commun.reessayer,
                        onPress: widget.controleur.relancer,
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: LienFleche(
                        key: ControleAntiRobot.cleRecharger,
                        libelle: t.connexion.controle.rechargerPage,
                        onPress: rechargerAdresse,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// PE-A5 (20/11/2026) : la phrase d'un echec de la verification, selon sa
/// cause ; au second echec sans cause precise, elle propose un autre
/// navigateur (le navigateur d'une application de messagerie est la premiere
/// cause connue d'echec de Cloudflare Turnstile).
String phraseEchecControle(CauseEchecAntiRobot cause, int echecs) =>
    switch (cause) {
      CauseEchecAntiRobot.horloge => t.connexion.controle.erreurHorloge,
      CauseEchecAntiRobot.reglage => t.connexion.controle.erreurReglage,
      CauseEchecAntiRobot.navigateur => t.connexion.controle.erreurNavigateur,
      CauseEchecAntiRobot.inconnue || CauseEchecAntiRobot.delai =>
        echecs >= 2
            ? t.connexion.controle.erreurNavigateur
            : t.connexion.controle.erreur,
    };
