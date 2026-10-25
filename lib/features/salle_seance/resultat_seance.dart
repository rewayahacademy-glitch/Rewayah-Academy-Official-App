// La fin de seance, cote eleve (CLV-09).
//
// Un etat resultat centre (grammaire `EcranResultat`, largeur
// `largeurEtatVide`) : titre, phrase, action pleine. Aucun recapitulatif,
// aucune presence, aucune mention d'enregistrement : la seance est finie
// pour cet appareil. L'Interface guidee se lit dans le theme
// (`AppMetriques.of(context)`), jamais en parametre.

import 'package:flutter/material.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/pause_seance/port_pause_seance.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/ecran_resultat.dart';
import '../../core/widgets/lien_fleche.dart';
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

  /// Le serveur a retire l'acces (P12) : aucune reconnexion tentee.
  accesRetire,
}

/// L'ecran de fin de l'eleve : standard ou guide, fin ou sortie.
class ResultatSeance extends StatelessWidget {
  const ResultatSeance({
    required this.issue,
    required this.onRetour,
    this.onRevenir,
    this.onAccueil,
    super.key,
  });

  final IssueSeance issue;

  /// Retour a la Classe (standard) ou a l'accueil (guidee).
  final VoidCallback onRetour;

  /// Lot salle 2 (directeur, 25/10/2026, standard Meet « You left the
  /// meeting / Rejoin ») : apres « Quitter », revenir dans la salle tant
  /// qu'elle est ouverte (le serveur seul dit si elle l'est). Seule action
  /// pleine ; [onAccueil] passe en lien.
  final VoidCallback? onRevenir;

  /// Le retour a l'accueil qui accompagne [onRevenir].
  final VoidCallback? onAccueil;

  /// L'action « Retourner dans la salle ».
  static const Key revenirKey = ValueKey<String>('resultat-revenir-salle');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool guidee = AppMetriques.of(context).mode == InterfaceMode.enfant;
    final bool large = AppGabarit.de(context) == Gabarit.desktop;
    final bool fin = guidee || issue == IssueSeance.terminee;
    final bool revenir =
        !guidee && issue == IssueSeance.quittee && onRevenir != null;
    // Guidee : une phrase courte, sans suite (S CLV-09, moins de 10 mots).
    final String titre = guidee
        ? t.salle.fin.titreGuidee
        : switch (issue) {
            IssueSeance.terminee => t.salle.fin.titre,
            IssueSeance.quittee => t.salle.fin.quitteTitre,
            IssueSeance.accesRetire => t.salle.fin.accesRetireTitre,
          };
    final String? phrase = guidee
        ? null
        : switch (issue) {
            IssueSeance.terminee => t.salle.fin.phrase,
            IssueSeance.quittee => t.salle.fin.quittePhrase,
            // S l.673 : un titre seul, aucune phrase.
            IssueSeance.accesRetire => null,
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
                      libelleAction: revenir
                          ? t.salle.retourner
                          : guidee
                          ? t.salle.fin.retourAccueil
                          : t.salle.fin.retourClasse,
                      onAction: revenir ? onRevenir : onRetour,
                      cleAction: revenir ? revenirKey : null,
                      libelleSecondaire: revenir
                          ? t.salle.fin.retourAccueil
                          : null,
                      onSecondaire: revenir ? (onAccueil ?? onRetour) : null,
                      // P12 (UX_REVIEW CL-7) : l'acces retire remplace la
                      // salle sans geste de l'eleve ; le focus clavier se
                      // pose sur la seule action, visible a l'ouverture.
                      focusAction: issue == IssueSeance.accesRetire,
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

/// La largeur de la phrase du cahier sur telephone (coupure de l'image 390).
const double _largeurPhraseTelephone =
    AppPage.largeurEtatVide - AppSpacing.section * 2 - AppSpacing.md;

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
    this.onRetournerSalle,
    this.cahierIndisponible = false,
    super.key,
  });

  final VueSeance vue;

  /// D10 : retourner dans la salle (prière, coupure) tant que la seance n'est
  /// pas close ; le serveur seul dit si elle l'est.
  final VoidCallback? onRetournerSalle;

  /// Le lien « Retourner dans la salle ».
  static const Key retourSalleKey = ValueKey<String>('fin-retour-salle');

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
                        // Lot salle 3 (pilote, 25/10/2026) : sur ordinateur
                        // (fenetre « expanded », 840 utiles), la fin tient
                        // dans 1440 x 768 sans defilement ; le telephone ne
                        // change pas.
                        final bool bureau =
                            c.maxWidth /
                                MediaQuery.textScalerOf(context).scale(1) >=
                            AppGabarit.seuilEtendu;
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
                                constraints: BoxConstraints(
                                  maxWidth: bureau
                                      ? AppPage.largeurLecture
                                      : _largeurFin,
                                ),
                                child: _CorpsFin(
                                  bureau: bureau,
                                  vue: vue,
                                  onRetournerSalle: onRetournerSalle,
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
    required this.bureau,
    required this.vue,
    required this.onRetournerSalle,
    required this.onOuvrirCahier,
    required this.onRevenirJournee,
    required this.cahierIndisponible,
  });

  /// Vrai sur ordinateur : en-tete compact, carte et actions cote a cote.
  final bool bureau;
  final VueSeance vue;
  final VoidCallback? onRetournerSalle;
  final VoidCallback? onOuvrirCahier;
  final VoidCallback? onRevenirJournee;
  final bool cahierIndisponible;

  @override
  Widget build(BuildContext context) {
    if (bureau) return _bureau(context);
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
        // D10 : en haut, avant tout le reste ; une sortie involontaire ou une
        // pause (priere, coupure) ne ferme pas la salle.
        if (onRetournerSalle case final VoidCallback retourner) ...<Widget>[
          LienFleche(
            key: FinSeanceEnseignant.retourSalleKey,
            libelle: t.salle.retourner,
            onPress: retourner,
            alignerEnDebut: true,
          ),
          Ecart.vLg,
        ],
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
        // Telephone : la phrase coupe comme l'image (« ...les informations /
        // de la seance. »), jamais sur un mot seul.
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppGabarit.de(context) == Gabarit.mobile
                  ? _largeurPhraseTelephone
                  : double.infinity,
            ),
            child: Text(
              t.salle.fin.enseignant.phrase,
              textAlign: TextAlign.center,
              style: palette.inkMuted.applyTo(
                textes.bodyLarge ?? const TextStyle(),
              ),
            ),
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
          _plein(
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

  /// L'unique action pleine de la fin, au telephone comme sur ordinateur
  /// (branches exclusives : une seule est rendue).
  Widget _plein({
    required String libelle,
    required VoidCallback onPress,
    required bool fleche,
    Key? key,
    bool? pleineLargeur,
  }) => ActionPrincipale(
    key: key,
    libelle: libelle,
    onPress: onPress,
    fleche: fleche,
    pleineLargeur: pleineLargeur,
  );

  /// Ordinateur (lot salle 3, pilote, 25/10/2026) : titre et phrase compacts,
  /// sans l'icone de 160 ; la carte recapitulative au debut, les actions a
  /// la fin, cote a cote. « Retourner dans la salle » est la seule action
  /// pleine ; « Ouvrir le cahier » (ou « Reessayer ») et « Revenir a ma
  /// journee » sont des liens avec fleche. Sans retour possible (seance
  /// close), le cahier reprend l'action pleine.
  Widget _bureau(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final VoidCallback? ouvrir = onOuvrirCahier;
    final VoidCallback? revenir = onRevenirJournee;
    final VoidCallback? retourner = onRetournerSalle;
    final String libelleCahier = cahierIndisponible
        ? t.commun.reessayer
        : t.salle.fin.enseignant.ouvrirCahier;
    // Une seule action pleine : le retour dans la salle, ou, seance close,
    // le cahier.
    final VoidCallback? plein = retourner ?? ouvrir;
    final List<Widget> rangee = <Widget>[
      if (retourner != null && ouvrir != null)
        LienFleche(libelle: libelleCahier, onPress: ouvrir),
      if (plein != null)
        _plein(
          key: retourner != null ? FinSeanceEnseignant.retourSalleKey : null,
          libelle: retourner != null ? t.salle.retourner : libelleCahier,
          onPress: plein,
          fleche: retourner == null && !cahierIndisponible,
          pleineLargeur: false,
        ),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            t.salle.fin.titre,
            style: palette.inkStrong.applyTo(
              textes.headlineSmall ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vSm,
        Text(
          t.salle.fin.enseignant.phrase,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vXl,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: _CarteRecapitulatif(vue: vue)),
            Ecart.hXxl,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (cahierIndisponible) ...<Widget>[
                    Text(
                      t.salle.fin.enseignant.erreurCahier,
                      key: const ValueKey<String>('fin-erreur-cahier'),
                      style: palette.inkAlert.applyTo(
                        textes.bodyMedium ?? const TextStyle(),
                      ),
                    ),
                    Ecart.vLg,
                  ],
                  if (rangee.isNotEmpty) RangeeActions(children: rangee),
                  if (revenir != null) ...<Widget>[
                    Ecart.vMd,
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: LienFleche(
                        libelle: t.salle.fin.enseignant.revenirJournee,
                        onPress: revenir,
                        alignerEnFin: true,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
    // Le halo lavande doux des images, derriere la coche.
    final Color halo = palette.washAccent.background;
    return ExcludeSemantics(
      child: Center(
        child: SizedBox.square(
          dimension: _cote,
          child: CustomPaint(
            painter: _Etincelles(
              encre,
              halo,
              // Desktop : quatre etincelles ; telephone et web etroit : trois
              // (images CLV-10).
              quatre: AppGabarit.de(context) == Gabarit.desktop,
            ),
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
  const _Etincelles(this.couleur, this.halo, {required this.quatre});

  final Color couleur;
  final Color halo;
  final bool quatre;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = size.center(Offset.zero);
    final double rayon = size.shortestSide * 0.62;
    canvas.drawCircle(
      centre,
      rayon,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[halo, halo.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: centre, radius: rayon)),
    );
    final Paint p = Paint()..color = couleur;
    final double w = size.width;
    for (final (double x, double y, double r) in <(double, double, double)>[
      (0.24, 0.14, 0.065),
      (0.13, 0.28, 0.03),
      (0.86, 0.46, 0.055),
      if (quatre) (0.76, 0.76, 0.07),
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
  bool shouldRepaint(_Etincelles oldDelegate) =>
      oldDelegate.couleur != couleur ||
      oldDelegate.halo != halo ||
      oldDelegate.quatre != quatre;
}

/// « n eleve(s) connecte(s) » : en francais, 0 et 1 prennent le singulier.
String libelleConnectes(int n) => n <= 1
    ? t.salle.fin.enseignant.unConnecte(n: n)
    : t.salle.fin.enseignant.connectes(n: n);

/// « sur n inscrit(s) » : 0 et 1 au singulier.
String libelleInscrits(int n) => n <= 1
    ? t.salle.fin.enseignant.unInscrit(n: n)
    : t.salle.fin.enseignant.inscrits(n: n);

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
    // Les sous-lignes des images (« Sayyida Amina », « sur 3 inscrits ») :
    // corps courant, a l'encre discrete.
    final TextStyle discret = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
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
        haut: Text(libelleConnectes(connectes), style: fort),
        bas: Text(libelleInscrits(inscrits), style: discret),
      ),
      _LigneRecap(
        icone: AppIcons.cahier,
        haut: Text(t.salle.fin.enseignant.cahierSeance, style: simple),
        bas: fin.cahierACompleter ? const _BadgeCahier() : null,
      ),
      // LIVE-PAUSE-01 : le systeme dit si la pause a ete prise ou non. Rien
      // n'est rendu quand aucune pause n'etait prevue.
      if (_phrasePause(vue.pause ?? const PauseSeance.nonPrevue())
          case final String phrase)
        _LigneRecap(
          icone: AppIcons.horloge,
          haut: Text(t.salle.seance.pause.recapTitre, style: simple),
          bas: Text(phrase, style: fort),
          cle: const ValueKey<String>('fin-recapitulatif-pause'),
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

/// La phrase du recapitulatif sur la pause, ou `null` sans pause prevue.
String? _phrasePause(PauseSeance pause) {
  switch (pause.statut) {
    case StatutPause.nonPrevue:
      return null;
    case StatutPause.prise:
      final int minutes = (pause.dureeReelle?.inMinutes ?? 0).clamp(1, 1440);
      return isolerSens(
        LibellesGroupe.insecable(
          t.salle.seance.pause.recapPrise(minutes: minutes),
        ),
      );
    case StatutPause.programmee:
    case StatutPause.enCours:
    case StatutPause.nonPrise:
      return isolerSens(t.salle.seance.pause.recapNonPrise);
  }
}

class _LigneRecap extends StatelessWidget {
  const _LigneRecap({
    required this.icone,
    required this.haut,
    this.bas,
    this.cle,
  });

  final Key? cle;

  final AppIcon icone;
  final Widget haut;
  final Widget? bas;

  @override
  Widget build(BuildContext context) {
    final Widget? suite = bas;
    return Padding(
      key: cle,
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
