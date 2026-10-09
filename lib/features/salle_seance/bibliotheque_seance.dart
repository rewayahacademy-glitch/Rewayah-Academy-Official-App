// TB-8 (LIB-01 a LIB-04 ; plan V2 §3 « Remplacer un support », §12, §19.1,
// UX-17) : la Bibliotheque ouverte dans la salle.
//
// Une seule bibliotheque (R14) : le catalogue est `SurfaceBibliotheque`, le
// meme que partout (recherche, filtres, chargement, vide, aucun resultat,
// indisponible). Choisir une carte ouvre un apercu PERSONNEL : la classe
// garde le support actuel jusqu'a « Presenter ». Presenter verifie le
// chargement ; en cas d'echec, le support d'avant reste et « Reessayer » est
// propose, avec le retour aux supports. Rien n'est diffuse avant Presenter,
// la connexion n'est jamais touchee (aucun import de `core/video`).
//
// Revue du 09/10 : « Revenir aux supports » (ou la fermeture du panneau)
// pendant l'ouverture annule vraiment : le chargement rend l'activation au
// lieu de l'executer, et la Bibliotheque ne l'execute que si l'enseignant
// n'a pas renonce entre-temps (jeton d'ouverture). « Presenter » est pose au
// pied de la feuille, hors du defilement : il reste dans la vue a toutes les
// tailles ; l'etat de l'ouverture (message, echec) est en tete, sous le
// retour, et la feuille defile jusqu'a son debut s'il est hors vue.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_bibliotheque/content_position.dart';
import '../../core/tc_bibliotheque/library_resource.dart';
import '../../core/tc_bibliotheque/vue_catalogue.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/lien_fleche.dart';
import '../tc_catalogue/libelles_bibliotheque.dart';
import '../tc_catalogue/surface_bibliotheque.dart';

/// TB-8 : « Presenter » un support choisi dans la Bibliotheque. Le futur
/// charge le support et se termine avec son ACTIVATION (le changement vu
/// par la classe), sans l'executer ; il echoue si le support n'est pas
/// charge, et la classe garde le support d'avant. La Bibliotheque n'appelle
/// l'activation que si l'enseignant n'a pas renonce pendant le chargement
/// (« Revenir aux supports », panneau ferme).
typedef PresenterSupport = Future<VoidCallback> Function(
  LibraryResource ressource,
  ContentPosition? position,
);

/// Ou en est la Bibliotheque en seance.
enum EtapeBibliotheque {
  /// LIB-01 : le catalogue et sa recherche.
  catalogue,

  /// LIB-02 : l'apercu personnel d'un support choisi.
  apercu,

  /// LIB-03 : « Ouverture du support... », Presenter en cours.
  ouverture,

  /// LIB-03 : le support n'a pas pu etre ouvert.
  echec,
}

/// Le contenu du panneau « Bibliotheque » de la salle de l'enseignant.
class BibliothequeSeance extends StatefulWidget {
  const BibliothequeSeance({
    required this.onPresenter,
    this.groupeId,
    this.reprises = const <RepriseEnSeance>[],
    super.key,
  });

  /// TB-9 : les supports ranges pendant la seance, en tete du catalogue,
  /// chacun avec son point de reprise ; « Presenter » les reprend a leur
  /// page, avec leurs notes de la seance.
  final List<RepriseEnSeance> reprises;

  /// Charge l'apercu et rend son activation pour la classe ; echoue si le
  /// support n'est pas charge ([PresenterSupport]).
  final PresenterSupport onPresenter;

  /// La Classe de la seance (section « Ce groupe »).
  final String? groupeId;

  /// La cle de « Presenter ».
  static const Key clePresenter = ValueKey<String>('bibliotheque-presenter');

  /// La cle de « Revenir aux supports ».
  static const Key cleRevenir = ValueKey<String>('bibliotheque-revenir');

  /// La cle de l'apercu personnel.
  static const Key cleApercu = ValueKey<String>('bibliotheque-apercu');

  /// La cle du message d'echec.
  static const Key cleEchec = ValueKey<String>('bibliotheque-echec');

  /// La cle du titre du message d'echec.
  static const Key cleTitreEchec = ValueKey<String>('bibliotheque-echec-titre');

  @override
  State<BibliothequeSeance> createState() => _BibliothequeSeanceState();
}

class _BibliothequeSeanceState extends State<BibliothequeSeance> {
  EtapeBibliotheque _etape = EtapeBibliotheque.catalogue;

  /// L'etat de l'ouverture (message ou echec), en tete de l'apercu : rendu
  /// visible des qu'il parait.
  final GlobalKey _etat = GlobalKey(debugLabel: 'bibliotheque-etat');
  LibraryResource? _choisie;
  ContentPosition? _position;

  /// Le jeton de l'ouverture en cours : tout retour ou tout nouveau choix
  /// le change, et un chargement termine sous un ancien jeton n'active rien.
  int _jeton = 0;

  void _choisir(LibraryResource ressource, ContentPosition? position) =>
      setState(() {
        _jeton++;
        _choisie = ressource;
        _position = position;
        _etape = EtapeBibliotheque.apercu;
      });

  void _revenir() => setState(() {
    _jeton++;
    _choisie = null;
    _position = null;
    _etape = EtapeBibliotheque.catalogue;
  });

  Future<void> _presenter() async {
    final LibraryResource? ressource = _choisie;
    if (ressource == null || _etape == EtapeBibliotheque.ouverture) return;
    final int jeton = ++_jeton;
    setState(() => _etape = EtapeBibliotheque.ouverture);
    _montrerEtat();
    final VoidCallback activer;
    try {
      activer = await widget.onPresenter(ressource, _position);
    } on Object {
      // Ouverture abandonnee entre-temps : l'enseignant est deja ailleurs
      // (catalogue, autre apercu), aucun echec a lui montrer.
      if (!mounted || jeton != _jeton) return;
      setState(() => _etape = EtapeBibliotheque.echec);
      _montrerEtat();
      return;
    }
    // « Revenir aux supports » ou panneau ferme pendant le chargement : la
    // classe garde son support, rien n'est presente.
    if (!mounted || jeton != _jeton) return;
    activer();
    // Reussi : l'appelant ferme le panneau ; s'il le garde, on revient au
    // catalogue.
    if (mounted) _revenir();
  }

  /// Apres le cadre : si l'etat de l'ouverture n'est pas entierement dans la
  /// vue de l'apercu, la feuille defile pour aligner son DEBUT (le titre du
  /// message) sur le haut de la vue ; « Presenter » / « Reessayer » reste au
  /// pied de la feuille, hors du defilement. Deja visible : rien ne bouge
  /// (le retour, au-dessus, reste aussi dans la vue).
  void _montrerEtat() =>
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        final BuildContext? etat = _etat.currentContext;
        if (!mounted || etat == null) return;
        final RenderObject? boite = etat.findRenderObject();
        final ScrollableState? defilement = Scrollable.maybeOf(etat);
        final RenderObject? vue = defilement?.context.findRenderObject();
        if (boite is! RenderBox || vue is! RenderBox) return;
        final double haut = boite.localToGlobal(Offset.zero, ancestor: vue).dy;
        final double hauteur = boite.size.height < vue.size.height
            ? boite.size.height
            : vue.size.height;
        if (haut >= 0 && haut + hauteur <= vue.size.height) return;
        unawaited(Scrollable.ensureVisible(etat));
      });

  @override
  Widget build(BuildContext context) {
    final LibraryResource? ressource = _choisie;
    if (_etape == EtapeBibliotheque.catalogue || ressource == null) {
      return SurfaceBibliotheque(
        contexte: ContexteDecouverte.enClasse,
        groupeId: widget.groupeId,
        onChoisir: _choisir,
        reprises: widget.reprises,
        titreReprises: t.salle.seance.rangement.section,
        enTete: Text(
          t.salle.seance.bibliotheque.intro,
          style: AppPalette.of(context).inkMuted.applyTo(
            Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
          ),
        ),
      );
    }
    return _Apercu(
      cleEtat: _etat,
      ressource: ressource,
      etape: _etape,
      onPresenter: () => unawaited(_presenter()),
      onRevenir: _revenir,
    );
  }
}

/// LIB-02 et LIB-03 : l'apercu personnel, Presenter, l'ouverture et l'echec.
///
/// Deux etages : le contenu, qui defile (retour, etat de l'ouverture,
/// apercu), et le pied de la feuille, fixe, qui porte « Presenter » /
/// « Reessayer » (K-56 : le bouton plein au bas de la feuille). Le pied ne
/// defile jamais : l'action reste dans la vue a 320 et 390, texte x1 et x2.
class _Apercu extends StatelessWidget {
  const _Apercu({
    required this.cleEtat,
    required this.ressource,
    required this.etape,
    required this.onPresenter,
    required this.onRevenir,
  });

  final GlobalKey cleEtat;
  final LibraryResource ressource;
  final EtapeBibliotheque etape;
  final VoidCallback onPresenter;
  final VoidCallback onRevenir;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool ouverture = etape == EtapeBibliotheque.ouverture;
    final bool echec = etape == EtapeBibliotheque.echec;
    TextStyle style(AppInkColor encre, TextStyle? base) =>
        encre.applyTo(base ?? const TextStyle());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            key: BibliothequeSeance.cleApercu,
            // Avec le haut du pied (8) : 16 du contenu au bouton (contrat
            // A, objet vers le CTA).
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Un retour : la fleche pointe vers le debut de la lecture
                // (`AppIcons.retour`, miroitee en arabe), et le texte part
                // du bord du contenu, comme les lignes qui suivent.
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: LienFleche(
                    key: BibliothequeSeance.cleRevenir,
                    libelle: t.salle.seance.bibliotheque.revenir,
                    icone: AppIcons.retour,
                    fleche: false,
                    alignerEnDebut: true,
                    onPress: onRevenir,
                  ),
                ),
                // L'etat de l'ouverture, en tete : le retour au-dessus et
                // « Reessayer » au pied restent les deux issues visibles.
                // La cle est sous la marge : defiler aligne le titre du
                // message lui-meme sur le haut de la vue (320 x2 : 51 de
                // vue pour un titre de 48).
                if (echec || ouverture)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: KeyedSubtree(
                      key: cleEtat,
                      child: echec
                          ? Semantics(
                              liveRegion: true,
                              child: Column(
                                key: BibliothequeSeance.cleEchec,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    t.salle.seance.bibliotheque.echec,
                                    key: BibliothequeSeance.cleTitreEchec,
                                    style: style(
                                      palette.inkAlert,
                                      textes.titleSmall,
                                    ),
                                  ),
                                  Ecart.vXs,
                                  Text(
                                    t.salle.seance.bibliotheque.echecDetail,
                                    style: style(
                                      palette.inkMuted,
                                      textes.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Semantics(
                              liveRegion: true,
                              child: Text(
                                t.salle.seance.bibliotheque.ouverture,
                                style: style(
                                  palette.inkMuted,
                                  textes.bodyMedium,
                                ),
                              ),
                            ),
                    ),
                  ),
                Ecart.vMd,
                Text(
                  t.salle.seance.bibliotheque.apercu,
                  style: style(palette.inkMuted, textes.labelMedium),
                ),
                Ecart.vXs,
                Text(
                  ressource.title,
                  style: style(palette.inkStrong, textes.titleMedium),
                ),
                Ecart.vXs,
                Text(
                  libelleTypeRessource(ressource.resourceType),
                  style: style(palette.inkMuted, textes.bodySmall),
                ),
                Ecart.vMd,
                // L'apercu : une page neutre, la premiere, vue par
                // l'enseignant seul. Aucune image n'est livree avant BR-1 :
                // jamais un faux contenu. Bornee en hauteur pour rester
                // lisible d'un coup d'oeil ; « Presenter » ne depend plus
                // d'elle (il est au pied, hors du defilement).
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: _hauteurApercu,
                    ),
                    child: AspectRatio(
                      aspectRatio: _ratioApercu,
                      child: DecoratedBox(
                        decoration: palette.surfaceSunken.decoration(
                          borderRadius: AppRadius.arrondiMd,
                          side: palette.borderHairline.asBorderSide(),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            child: Text(
                              ressource.shortTitle.isEmpty
                                  ? ressource.title
                                  : ressource.shortTitle,
                              textAlign: TextAlign.center,
                              style: style(palette.inkMuted, textes.bodySmall),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Ecart.vMd,
                // Ce que voit la classe, dit une fois dans l'apercu (UX-17) ;
                // le message d'echec ne le repete pas.
                Text(
                  t.salle.seance.bibliotheque.apercuClasse,
                  style: style(palette.inkMuted, textes.bodySmall),
                ),
              ],
            ),
          ),
        ),
        // Le pied : 8 au-dessus (avec le bas du contenu, 16), 8 au-dessous,
        // pour que le bouton ne touche pas le bord de la feuille.
        Ecart.vSm,
        ActionPrincipale(
          key: BibliothequeSeance.clePresenter,
          libelle: echec
              ? t.commun.reessayer
              : t.salle.seance.bibliotheque.presenter,
          enCours: ouverture,
          onPress: onPresenter,
        ),
        Ecart.vSm,
      ],
    );
  }
}

/// L'apercu garde le ratio d'une page A4 en portrait, comme la page de
/// demonstration ; la vraie page viendra du fournisseur des pages (BR-1).
const double _ratioApercu = 1240 / 1754;

/// La hauteur maximale de l'apercu : trois respirations (192), assez pour
/// reconnaitre la page d'un coup d'oeil.
const double _hauteurApercu = AppSpacing.respiration * 3;
