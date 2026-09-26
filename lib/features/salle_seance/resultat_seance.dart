// La fin de seance, cote eleve (CLV-09).
//
// Un etat resultat centre (grammaire `EcranResultat`, largeur
// `largeurEtatVide`) : titre, phrase, action pleine. Aucun recapitulatif,
// aucune presence, aucune mention d'enregistrement : la seance est finie
// pour cet appareil. L'Interface guidee se lit dans le theme
// (`AppMetriques.of(context)`), jamais en parametre.

import 'package:flutter/material.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/ecran_resultat.dart';
import '../../core/widgets/status_pill.dart';
import 'actions_seance.dart';
import 'chrome_seance.dart';
import 'rail_seance.dart';
import 'vue_seance.dart';

/// Pourquoi l'eleve quitte la salle.
enum IssueSeance {
  /// La seance est finie (fin serveur).
  terminee,

  /// L'eleve est sorti avant la fin, apres confirmation.
  quittee,
}

/// L'ecran de fin de l'eleve : standard ou guide, fin ou sortie.
class ResultatSeance extends StatelessWidget {
  const ResultatSeance({
    required this.issue,
    required this.onRetour,
    super.key,
  });

  final IssueSeance issue;

  /// Retour a la Classe (standard) ou a l'accueil (guidee).
  final VoidCallback onRetour;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool guidee = AppMetriques.of(context).mode == InterfaceMode.enfant;
    final bool large = AppGabarit.de(context) == Gabarit.desktop;
    final bool fin = guidee || issue == IssueSeance.terminee;
    // Guidee : une phrase courte, sans suite (S CLV-09, moins de 10 mots).
    final String titre = guidee
        ? t.salle.fin.titreGuidee
        : switch (issue) {
            IssueSeance.terminee => t.salle.fin.titre,
            IssueSeance.quittee => t.salle.fin.quitteTitre,
          };
    final String? phrase = guidee
        ? null
        : switch (issue) {
            IssueSeance.terminee => t.salle.fin.phrase,
            IssueSeance.quittee => t.salle.fin.quittePhrase,
          };
    return Material(
      key: const ValueKey<String>('resultat-seance'),
      color: palette.surfaceCanvas.background,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints contraintes) =>
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: large
                      ? AppPage.gouttiereDesktop
                      : AppPage.gouttiereMobile,
                  vertical: AppSpacing.xxl,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: contraintes.maxHeight - 2 * AppSpacing.xxl,
                  ),
                  child: Center(
                    child: EcranResultat(
                      // Guidee : un seul ecran de fin (« La seance est
                      // terminee. »), donc la coche au ton succes, meme apres
                      // Quitter : l'icone ne contredit jamais le texte.
                      icone: fin ? AppIcons.succes : AppIcons.sortie,
                      ton: fin ? TonEtat.succes : TonEtat.neutre,
                      titre: titre,
                      phrase: phrase,
                      libelleAction: guidee
                          ? t.salle.fin.retourAccueil
                          : t.salle.fin.retourClasse,
                      onAction: onRetour,
                    ),
                  ),
                ),
              ),
        ),
      ),
    );
  }
}

/// La largeur du corps de la fin enseignant (image CLV-10 : ≈ 480 en
/// desktop) ; pleine largeur moins la gouttiere sur telephone.
const double _largeurFin = AppPage.largeurEtatVide + AppSpacing.section * 2;

/// La fin de seance de l'enseignant (CLV-10, S l.1131-1185).
///
/// En-tete « Seance terminee » + Classe + pastille « Terminee » (desktop),
/// rail enseignant (desktop), icone validee, phrase du cahier, carte
/// recapitulative, « Ouvrir le cahier → » (seule action pleine) et « Revenir
/// a ma journee ». Aucune mention d'enregistrement. Le recapitulatif lit la
/// MEME liste que le compteur « Eleves x/y » (I-6) : jamais « present » ni
/// « absent ». Rien n'est rendu hors enseignant (`voitRecapitulatifFin`).
class FinSeanceEnseignant extends StatelessWidget {
  const FinSeanceEnseignant({
    required this.vue,
    required this.actions,
    this.onOuvrirCahier,
    this.onRevenirJournee,
    this.cahierIndisponible = false,
    super.key,
  });

  final VueSeance vue;

  /// Chevron, cloche, reglages, compte et rail (`onNaviguer`).
  final ActionsSeance actions;

  /// Ouvre le cahier (`Routes.cahierPour`) ; « Reessayer » en cas d'echec.
  final VoidCallback? onOuvrirCahier;
  final VoidCallback? onRevenirJournee;

  /// Le cahier n'a pas pu etre ouvert : message et « Reessayer ».
  final bool cahierIndisponible;

  @override
  Widget build(BuildContext context) {
    if (!vue.voitRecapitulatifFin) return const SizedBox.shrink();
    final AppPalette palette = AppPalette.of(context);
    final Gabarit gabarit = AppGabarit.de(context);
    final bool large = gabarit == Gabarit.desktop;
    final ValueChanged<String>? naviguer = actions.onNaviguer;
    return Material(
      key: const ValueKey<String>('fin-seance-enseignant'),
      color: palette.surfaceCanvas.background,
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (vue.voitRail(gabarit) && naviguer != null)
              RailSeance(
                onNaviguer: naviguer,
                groupeId: vue.groupeId,
                confirmerSortie: false,
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  EnteteFinSeance(vue: vue, actions: actions),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints c) {
                        final double vertical = large
                            ? AppSpacing.xl
                            : AppSpacing.xxl;
                        return SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: large
                                ? AppPage.gouttiereDesktop
                                : AppPage.gouttiereMobile,
                            vertical: vertical,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: c.maxHeight - 2 * vertical,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: _largeurFin,
                                ),
                                child: _CorpsFin(
                                  vue: vue,
                                  onOuvrirCahier: onOuvrirCahier,
                                  onRevenirJournee: onRevenirJournee,
                                  cahierIndisponible: cahierIndisponible,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CorpsFin extends StatelessWidget {
  const _CorpsFin({
    required this.vue,
    required this.onOuvrirCahier,
    required this.onRevenirJournee,
    required this.cahierIndisponible,
  });

  final VueSeance vue;
  final VoidCallback? onOuvrirCahier;
  final VoidCallback? onRevenirJournee;
  final bool cahierIndisponible;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final VoidCallback? ouvrir = onOuvrirCahier;
    final VoidCallback? revenir = onRevenirJournee;
    // Desktop : le titre des images, plus grand (CLV-10 desktop).
    final TextStyle? styleTitre = AppGabarit.de(context) == Gabarit.desktop
        ? textes.displaySmall
        : textes.headlineLarge;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _HerosValide(),
        Ecart.vLg,
        Semantics(
          header: true,
          child: Text(
            t.salle.fin.titre,
            textAlign: TextAlign.center,
            style: palette.inkStrong.applyTo(styleTitre ?? const TextStyle()),
          ),
        ),
        Ecart.vSm,
        Text(
          t.salle.fin.enseignant.phrase,
          textAlign: TextAlign.center,
          style: palette.inkMuted.applyTo(
            textes.bodyLarge ?? const TextStyle(),
          ),
        ),
        Ecart.vXl,
        _CarteRecapitulatif(vue: vue),
        if (cahierIndisponible) ...<Widget>[
          Ecart.vLg,
          Text(
            t.salle.fin.enseignant.erreurCahier,
            key: const ValueKey<String>('fin-erreur-cahier'),
            textAlign: TextAlign.center,
            style: palette.inkAlert.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
        if (ouvrir != null) ...<Widget>[
          Ecart.vLg,
          ActionPrincipale(
            libelle: cahierIndisponible
                ? t.commun.reessayer
                : t.salle.fin.enseignant.ouvrirCahier,
            onPress: ouvrir,
            fleche: !cahierIndisponible,
          ),
        ],
        if (revenir != null) ...<Widget>[
          Ecart.vMd,
          ActionPrincipale(
            libelle: t.salle.fin.enseignant.revenirJournee,
            onPress: revenir,
            niveau: NiveauAction.secondaire,
          ),
        ],
      ],
    );
  }
}

/// L'icone validee des images : la coche cerclee, a l'encre d'accent, et
/// des etincelles decoratives.
class _HerosValide extends StatelessWidget {
  const _HerosValide();

  static const double _cote = AppSpacing.section * 4;
  static const double _icone = AppSpacing.section * 3;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Color encre = palette.inkAccent.asBorderSide().color;
    return ExcludeSemantics(
      child: Center(
        child: SizedBox.square(
          dimension: _cote,
          child: CustomPaint(
            painter: _Etincelles(encre),
            child: Center(
              child: IconTheme(
                data: palette.inkAccent.asIconTheme(size: _icone),
                child: Icon(AppIcons.succes.repos),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Des etoiles a quatre branches autour de la coche (decor).
class _Etincelles extends CustomPainter {
  const _Etincelles(this.couleur);

  final Color couleur;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()..color = couleur;
    final double w = size.width;
    for (final (double x, double y, double r) in <(double, double, double)>[
      (0.24, 0.14, 0.065),
      (0.13, 0.28, 0.03),
      (0.86, 0.46, 0.055),
      (0.76, 0.76, 0.07),
    ]) {
      final Offset c = Offset(x * w, y * size.height);
      final double b = r * w;
      final double m = b * 0.12;
      final Path etoile = Path()
        ..moveTo(c.dx, c.dy - b)
        ..quadraticBezierTo(c.dx + m, c.dy - m, c.dx + b, c.dy)
        ..quadraticBezierTo(c.dx + m, c.dy + m, c.dx, c.dy + b)
        ..quadraticBezierTo(c.dx - m, c.dy + m, c.dx - b, c.dy)
        ..quadraticBezierTo(c.dx - m, c.dy - m, c.dx, c.dy - b)
        ..close();
      canvas.drawPath(etoile, p);
    }
  }

  @override
  bool shouldRepaint(_Etincelles oldDelegate) => oldDelegate.couleur != couleur;
}

/// La carte recapitulative : Classe, Fin, eleves connectes, cahier.
class _CarteRecapitulatif extends StatelessWidget {
  const _CarteRecapitulatif({required this.vue});

  final VueSeance vue;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final FinSeance fin = vue.fin!;
    final BorderSide filet = palette.borderHairline.asBorderSide();
    final TextStyle fort = palette.inkStrong.applyTo(
      textes.titleSmall ?? const TextStyle(),
    );
    final TextStyle simple = palette.inkStrong.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final TextStyle discret = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    // I-6 : les deux nombres viennent de la liste du compteur « Eleves x/y ».
    final int connectes = vue.connectesAuMoinsUneFois;
    final int inscrits = vue.inscrits;
    final List<Widget> lignes = <Widget>[
      // `/salle` ne connait pas encore le nom de la Classe (BR-1) : la ligne
      // porte alors le seul nom de l'enseignant.
      if (vue.nomClasse.isEmpty)
        _LigneRecap(
          icone: AppIcons.livreOuvert,
          haut: Text(vue.nomEnseignant, style: fort),
        )
      else
        _LigneRecap(
          icone: AppIcons.livreOuvert,
          haut: Text(vue.nomClasse, style: fort),
          bas: Text(vue.nomEnseignant, style: discret),
        ),
      _LigneRecap(
        icone: AppIcons.horloge,
        haut: Text(t.salle.fin.enseignant.fin, style: simple),
        bas: Text(fin.heureFin, style: fort),
      ),
      _LigneRecap(
        icone: AppIcons.eleves,
        haut: Text(
          connectes <= 1
              ? t.salle.fin.enseignant.unConnecte(n: connectes)
              : t.salle.fin.enseignant.connectes(n: connectes),
          style: fort,
        ),
        bas: Text(
          inscrits <= 1
              ? t.salle.fin.enseignant.unInscrit(n: inscrits)
              : t.salle.fin.enseignant.inscrits(n: inscrits),
          style: discret,
        ),
      ),
      _LigneRecap(
        icone: AppIcons.cahier,
        haut: Text(t.salle.fin.enseignant.cahierSeance, style: simple),
        bas: fin.cahierACompleter ? const _BadgeCahier() : null,
      ),
    ];
    return Semantics(
      container: true,
      label: t.salle.fin.enseignant.recapitulatif,
      child: DecoratedBox(
        key: const ValueKey<String>('fin-recapitulatif'),
        decoration: palette.surfaceRaised.decoration(
          borderRadius: AppRadius.arrondiMd,
          side: filet,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int i = 0; i < lignes.length; i++)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: i == 0 ? null : Border(top: filet),
                  ),
                  child: lignes[i],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LigneRecap extends StatelessWidget {
  const _LigneRecap({required this.icone, required this.haut, this.bas});

  final AppIcon icone;
  final Widget haut;
  final Widget? bas;

  @override
  Widget build(BuildContext context) {
    final Widget? suite = bas;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: AppSpacing.titreEcran,
            child: IconTheme(
              data: AppPalette.of(context).inkAccent
                  .asIconTheme(size: AppSpacing.xxxl),
              child: Icon(icone.repos),
            ),
          ),
          Ecart.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                haut,
                if (suite != null) ...<Widget>[Ecart.vXs, suite],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Le badge doux « Cahier a completer » : point d'attention + texte, sur la
/// paire douce d'avertissement. Jamais un fond plein.
class _BadgeCahier extends StatelessWidget {
  const _BadgeCahier();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: DecoratedBox(
        decoration: palette.washWarning.decoration(
          borderRadius: AppRadius.arrondiFull,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox.square(
                dimension: StatusPill.diametrePastille,
                child: DecoratedBox(
                  decoration: palette.pointsStatut.attention.pastille(),
                ),
              ),
              Ecart.hSm,
              Flexible(
                child: Text(
                  t.salle.fin.enseignant.cahierACompleter,
                  style: palette.washWarning.applyTo(
                    Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
