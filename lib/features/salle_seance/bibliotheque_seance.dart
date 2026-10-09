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

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
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
    super.key,
  });

  /// Presente l'apercu a la classe : se termine une fois le support charge
  /// et active, echoue sinon.
  final Future<void> Function(
    LibraryResource ressource,
    ContentPosition? position,
  )
  onPresenter;

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

  @override
  State<BibliothequeSeance> createState() => _BibliothequeSeanceState();
}

class _BibliothequeSeanceState extends State<BibliothequeSeance> {
  EtapeBibliotheque _etape = EtapeBibliotheque.catalogue;

  /// Le bas de l'apercu (message et bouton) : rendu visible apres un echec.
  final GlobalKey _bas = GlobalKey(debugLabel: 'bibliotheque-bas');
  LibraryResource? _choisie;
  ContentPosition? _position;

  void _choisir(LibraryResource ressource, ContentPosition? position) =>
      setState(() {
        _choisie = ressource;
        _position = position;
        _etape = EtapeBibliotheque.apercu;
      });

  void _revenir() => setState(() {
    _choisie = null;
    _position = null;
    _etape = EtapeBibliotheque.catalogue;
  });

  Future<void> _presenter() async {
    final LibraryResource? ressource = _choisie;
    if (ressource == null || _etape == EtapeBibliotheque.ouverture) return;
    setState(() => _etape = EtapeBibliotheque.ouverture);
    try {
      await widget.onPresenter(ressource, _position);
      // Reussi : l'appelant ferme le panneau ; s'il le garde, on revient au
      // catalogue.
      if (mounted) _revenir();
    } on Object {
      if (!mounted) return;
      setState(() => _etape = EtapeBibliotheque.echec);
      // Le message pousse le bouton : on fait defiler jusqu'a lui, pour voir
      // l'echec et « Reessayer » ensemble.
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        final BuildContext? bas = _bas.currentContext;
        if (mounted && bas != null) {
          unawaited(Scrollable.ensureVisible(bas, alignment: 1));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final LibraryResource? ressource = _choisie;
    if (_etape == EtapeBibliotheque.catalogue || ressource == null) {
      return SurfaceBibliotheque(
        contexte: ContexteDecouverte.enClasse,
        groupeId: widget.groupeId,
        onChoisir: _choisir,
        enTete: Text(
          t.salle.seance.bibliotheque.intro,
          style: AppPalette.of(context).inkMuted.applyTo(
            Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
          ),
        ),
      );
    }
    return _Apercu(
      cleBas: _bas,
      ressource: ressource,
      etape: _etape,
      onPresenter: () => unawaited(_presenter()),
      onRevenir: _revenir,
    );
  }
}

/// LIB-02 et LIB-03 : l'apercu personnel, Presenter, l'ouverture et l'echec.
class _Apercu extends StatelessWidget {
  const _Apercu({
    required this.cleBas,
    required this.ressource,
    required this.etape,
    required this.onPresenter,
    required this.onRevenir,
  });

  final GlobalKey cleBas;
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
    return SingleChildScrollView(
      key: BibliothequeSeance.cleApercu,
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: LienFleche(
              key: BibliothequeSeance.cleRevenir,
              libelle: t.salle.seance.bibliotheque.revenir,
              onPress: onRevenir,
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
          // L'apercu : une page neutre, la premiere, vue par l'enseignant
          // seul. Aucune image n'est livree avant BR-1 : jamais un faux
          // contenu. Bornee en hauteur : « Presenter » reste a portee.
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: _hauteurApercu),
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
          // Ce que voit la classe, dit une fois (UX-17).
          Text(
            t.salle.seance.bibliotheque.apercuClasse,
            style: style(palette.inkMuted, textes.bodySmall),
          ),
          Ecart.vLg,
          // L'etat de l'ouverture juste au-dessus de « Presenter » /
          // « Reessayer » : la ou l'enseignant vient de toucher, sans
          // defiler (l'apercu est borne en hauteur).
          if (echec) ...<Widget>[
            Semantics(
              liveRegion: true,
              child: Column(
                key: BibliothequeSeance.cleEchec,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    t.salle.seance.bibliotheque.echec,
                    style: style(palette.inkAlert, textes.titleSmall),
                  ),
                  Ecart.vXs,
                  Text(
                    t.salle.seance.bibliotheque.echecDetail,
                    style: style(palette.inkMuted, textes.bodySmall),
                  ),
                ],
              ),
            ),
            Ecart.vMd,
          ],
          if (ouverture) ...<Widget>[
            Semantics(
              liveRegion: true,
              child: Text(
                t.salle.seance.bibliotheque.ouverture,
                style: style(palette.inkMuted, textes.bodyMedium),
              ),
            ),
            Ecart.vMd,
          ],
          KeyedSubtree(
            key: cleBas,
            child: ActionPrincipale(
              key: BibliothequeSeance.clePresenter,
              libelle: echec
                  ? t.commun.reessayer
                  : t.salle.seance.bibliotheque.presenter,
              enCours: ouverture,
              onPress: onPresenter,
            ),
          ),
        ],
      ),
    );
  }
}

/// L'apercu garde le ratio d'une page A4 en portrait, comme la page de
/// demonstration ; la vraie page viendra du fournisseur des pages (BR-1).
const double _ratioApercu = 1240 / 1754;

/// La hauteur maximale de l'apercu : trois respirations (192), assez pour
/// reconnaitre la page, assez peu pour garder « Presenter » visible.
const double _hauteurApercu = AppSpacing.respiration * 3;
