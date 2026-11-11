// Lot PARTAGE-GENERIQUE (directeur, 11/11/2026 ; CAHIER-SALLE §7) : le
// partage en direct est commun a tout support.
//
// Un support presente se decrit par un identifiant, une version, une page et
// un nombre de pages (`ContenuPresente`). Ce fichier dit comment la salle
// REND une page selon le support :
// - le Coran garde son lecteur (`PageCoranSalle`, hors de ce fichier) ;
// - un support a pages d'images (livre de lecture, document converti en
//   images a son depot) a un lecteur simple : [PageImageSupport] ;
// - un support que cette application ne connait pas rend un etat clair,
//   [SupportIllisibleIci], jamais un ecran vide.
//
// Le pointeur, l'ecriture, le glissement de page et « suivre la page » ne
// lisent rien d'ici : ils travaillent sur la page a ratio fixe de
// `SurfacePageFixe` (coordonnees de 0 a 1 sur la page), quel que soit le
// support.
//
// Le support de demonstration ([supportDemonstration]) n'existe que sous
// `PLAYGROUND=true` et dans les tests : aucune donnee de production.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_bibliotheque/couverture_ressource.dart';
import '../../core/tc_bibliotheque/library_resource.dart' show TypeRessource;
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/video/video_session_provider.dart' show ContenuPresente;
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/skeleton.dart';
import 'depuis_salle.dart';
import 'vue_seance.dart';

/// Lit les octets de l'image de la page [numero] d'un support, ou `null`
/// quand le fichier n'existe pas. Les droits sont ceux du serveur : la salle
/// ne garde aucune adresse signee.
typedef ChargeurPage = Future<Uint8List?> Function(int numero);

/// Un support que la salle sait montrer et partager, hors le Coran : ce
/// qu'il faut pour le decrire a la classe et pour rendre une de ses pages.
@immutable
class SupportDeSalle {
  /// Cree un support. [page] rend la page [numero] dans la place donnee.
  const SupportDeSalle({
    required this.id,
    required this.version,
    required this.titre,
    required this.pages,
    required this.largeurPage,
    required this.hauteurPage,
    required this.page,
    required this.couverture,
    this.detail,
    this.repere,
    this.aValider = false,
  }) : assert(pages >= 1),
       assert(largeurPage > 0 && hauteurPage > 0);

  /// Un support a pages d'images : une image par page, toutes aux memes
  /// dimensions ([largeurPage] x [hauteurPage], en pixels de la source).
  factory SupportDeSalle.images({
    required String id,
    required String version,
    required String titre,
    required int pages,
    required int largeurPage,
    required int hauteurPage,
    required ChargeurPage charger,
    required CouvertureRessource couverture,
    String? detail,
    String? repere,
    bool aValider = false,
  }) => SupportDeSalle(
    id: id,
    version: version,
    titre: titre,
    pages: pages,
    largeurPage: largeurPage,
    hauteurPage: hauteurPage,
    couverture: couverture,
    detail: detail,
    repere: repere,
    aValider: aValider,
    page: (BuildContext _, int numero) => PageImageSupport(
      key: ValueKey<String>('page-image-$id-$version-$numero'),
      numero: numero,
      charger: charger,
    ),
  );

  /// L'identifiant du support dans la Bibliotheque.
  final String id;

  /// Sa version publiee : un trait reste attache a cette version.
  final String version;
  final String titre;

  /// Le nombre de pages.
  final int pages;

  /// Les dimensions d'une page, en pixels de la source.
  final int largeurPage;
  final int hauteurPage;

  /// Rend la page [numero] (de 1 a [pages]).
  final Widget Function(BuildContext context, int numero) page;

  /// Sa couverture sur l'etagere.
  final CouvertureRessource couverture;

  /// La ligne sous son titre sur l'etagere, ou `null`.
  final String? detail;

  /// Son repere dans le parcours (« Etape 1 »), ou `null`.
  final String? repere;

  /// Support de demonstration a valider par la direction : jamais presente
  /// comme officiel.
  final bool aValider;

  /// La page [numero] ramenee entre 1 et [pages].
  int borner(int numero) => numero < 1 ? 1 : (numero > pages ? pages : numero);

  /// Ce support a la page [numero], pour la surface a page fixe.
  SupportPageFixe aLaPage(int numero) => SupportPageFixe(
    id: id,
    version: version,
    titre: titre,
    page: borner(numero),
    total: pages,
    largeurCanonique: largeurPage,
    hauteurCanonique: hauteurPage,
    ratioFixe: true,
  );

  /// Le pointeur qui voyage vers la classe pour la page [numero].
  ContenuPresente contenu({
    required int numero,
    required String presentePar,
    required DateTime emisLe,
  }) => ContenuPresente.deSupport(
    support: id,
    version: version,
    page: borner(numero),
    total: pages,
    presentePar: presentePar,
    emisLe: emisLe,
  );
}

/// Le support que [contenu] designe parmi [connus], ou `null` : le Coran
/// (qui a son lecteur), ou un support que cette application ne connait pas
/// (identifiant ou version differents).
SupportDeSalle? supportDeSalleDe(
  ContenuPresente contenu,
  List<SupportDeSalle> connus,
) {
  if (contenu.estCoran) return null;
  for (final SupportDeSalle s in connus) {
    if (s.id == contenu.support && s.version == contenu.version) return s;
  }
  return null;
}

/// Le support presente tel que la surface a page fixe le lit, quel que soit
/// le support : le Coran, un support connu, ou un support inconnu (qui garde
/// une page, pour porter l'etat [SupportIllisibleIci]).
SupportPageFixe supportPresenteDe(
  ContenuPresente contenu,
  List<SupportDeSalle> connus,
) {
  if (contenu.estCoran) return DepuisSalle.pageCoran(contenu.page);
  final SupportDeSalle? connu = supportDeSalleDe(contenu, connus);
  if (connu != null) return connu.aLaPage(contenu.page);
  final int page = contenu.page < 1 ? 1 : contenu.page;
  final int total = contenu.total ?? page;
  return SupportPageFixe(
    id: contenu.support,
    version: contenu.version,
    titre: t.salle.support.inconnuNom,
    page: page,
    total: total < page ? page : total,
    // Sans donnee, la page d'un document : A4 en portrait.
    largeurCanonique: 1000,
    hauteurCanonique: 1414,
    ratioFixe: true,
  );
}

/// Les supports que la salle sait partager, hors le Coran : ceux de la
/// demonstration sous [demo], aucun sinon (la Bibliotheque de production ne
/// contient aucun support le 11/11/2026).
List<SupportDeSalle> supportsDeSalleSelon({required bool demo}) =>
    demo ? <SupportDeSalle>[supportDemonstration()] : const <SupportDeSalle>[];

/// Les supports de la salle, hors le Coran. La demonstration ne sort que sous
/// `PLAYGROUND=true`, que le deploiement force a `false`.
final Provider<List<SupportDeSalle>> supportsDeSalleProvider =
    Provider<List<SupportDeSalle>>(
      (Ref ref) => supportsDeSalleSelon(demo: Env.playgroundActif),
    );

/// L'identifiant du support de demonstration.
const String idSupportDemonstration = 'demonstration-lettres';

/// Le nombre de pages du support de demonstration.
const int pagesSupportDemonstration = 4;

/// Le support de demonstration : quelques pages qui ne portent que leur
/// titre, leur numero et la mention « A valider ». Aucun contenu religieux ni
/// pedagogique : il sert a essayer le partage, jamais a enseigner.
SupportDeSalle supportDemonstration() => SupportDeSalle(
  id: idSupportDemonstration,
  version: 'demonstration-1',
  titre: t.salle.etagere.demo.lettres,
  pages: pagesSupportDemonstration,
  largeurPage: PageDemonstration.largeur.round(),
  hauteurPage: PageDemonstration.hauteur.round(),
  couverture: const CouvertureRessource(
    indexTeinte: 0,
    motif: MotifCouverture.lignes,
    monogramme: 'L',
    type: TypeRessource.texteStructure,
  ),
  detail: t.salle.support.demoDetail,
  repere: t.salle.etagere.etape(numero: 1),
  aValider: true,
  page: (BuildContext _, int numero) => PageDemonstration(
    key: ValueKey<int>(numero),
    titre: t.salle.etagere.demo.lettres,
    numero: numero,
    pages: pagesSupportDemonstration,
  ),
);

/// Une page du support de demonstration : son titre, « Page N sur M » et la
/// mention « A valider ». Composee sur une feuille de taille fixe puis mise a
/// l'echelle d'un bloc : le meme point de la page tombe au meme endroit sur
/// tous les appareils.
class PageDemonstration extends StatelessWidget {
  const PageDemonstration({
    required this.titre,
    required this.numero,
    required this.pages,
    super.key,
  });

  final String titre;
  final int numero;
  final int pages;

  /// La feuille de composition (A4 en portrait).
  static const double largeur = 400;
  static const double hauteur = 566;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String position = t.salle.seance.page(page: numero, pages: pages);
    return Semantics(
      container: true,
      label: '$titre, $position. ${t.salle.etagere.aValiderDetail}',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: palette.surfaceRaised.decoration(),
          child: FittedBox(
            child: SizedBox(
              width: largeur,
              height: hauteur,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: MediaQuery.withNoTextScaling(
                  // Une page est un document : son texte suit la taille de la
                  // page, jamais celle du texte de l'interface.
                  child: Column(
                    children: <Widget>[
                      DecoratedBox(
                        decoration: palette.washWarning.decoration(
                          borderRadius: AppRadius.arrondiFull,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          child: Text(
                            t.salle.etagere.aValider,
                            style: palette.washWarning.applyTo(
                              textes.labelLarge ?? const TextStyle(),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        titre,
                        textAlign: TextAlign.center,
                        style: palette.inkStrong.applyTo(
                          textes.headlineMedium ?? const TextStyle(),
                        ),
                      ),
                      Ecart.vMd,
                      Text(
                        position,
                        key: ValueKey<String>('page-demonstration-$numero'),
                        textAlign: TextAlign.center,
                        style: palette.inkStrong.applyTo(
                          textes.titleLarge ?? const TextStyle(),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        t.salle.etagere.aValiderDetail,
                        textAlign: TextAlign.center,
                        style: palette.inkMuted.applyTo(
                          textes.bodyMedium ?? const TextStyle(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// La page d'un support a pages d'images : l'image entiere, jamais etiree.
/// Chargement, contenu, fichier absent ou echec avec « Reessayer » : jamais
/// une page vide.
class PageImageSupport extends StatefulWidget {
  const PageImageSupport({
    required this.numero,
    required this.charger,
    super.key,
  });

  final int numero;
  final ChargeurPage charger;

  @override
  State<PageImageSupport> createState() => _EtatPageImage();
}

class _EtatPageImage extends State<PageImageSupport> {
  late Future<Uint8List?> _lecture = widget.charger(widget.numero);

  @override
  void didUpdateWidget(PageImageSupport ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.numero != widget.numero) {
      _lecture = widget.charger(widget.numero);
    }
  }

  void _relire() => setState(() {
    _lecture = widget.charger(widget.numero);
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: _lecture,
    builder: (BuildContext context, AsyncSnapshot<Uint8List?> lecture) {
      if (lecture.connectionState != ConnectionState.done) {
        return const Padding(
          key: ValueKey<String>('page-image-chargement'),
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Skeleton.texte(lignes: 6),
        );
      }
      final Uint8List? octets = lecture.data;
      if (lecture.hasError || octets == null) {
        return _EtatDePage(
          key: const ValueKey<String>('page-image-erreur'),
          icone: AppIcons.horsLigne,
          titre: t.salle.support.pageIllisible,
          detail: t.salle.support.pageIllisibleDetail,
          action: ActionPrincipale(
            key: const ValueKey<String>('page-image-reessayer'),
            libelle: t.commun.reessayer,
            libelleSemantique: t.salle.support.reessayerPage(
              page: widget.numero,
            ),
            onPress: _relire,
            pleineLargeur: false,
            // K-56 : « Partager » reste le seul bouton plein de la salle.
            niveau: NiveauAction.secondaire,
          ),
        );
      }
      return Image.memory(
        octets,
        key: const ValueKey<String>('page-image-contenu'),
        fit: BoxFit.contain,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        errorBuilder: (BuildContext _, Object _, StackTrace? _) => _EtatDePage(
          key: const ValueKey<String>('page-image-erreur'),
          icone: AppIcons.horsLigne,
          titre: t.salle.support.pageIllisible,
          detail: t.salle.support.pageIllisibleDetail,
        ),
      );
    },
  );
}

/// Un support que cette application ne sait pas afficher (identifiant ou
/// version inconnus : application pas encore mise a jour, ou support retire
/// de la Bibliotheque). La phrase dit ce qui se passe, pourquoi, et quoi
/// faire ; le cours continue a la voix.
class SupportIllisibleIci extends StatelessWidget {
  const SupportIllisibleIci({super.key});

  /// La cle de l'etat (tests, captures).
  static const Key cle = ValueKey<String>('support-illisible-ici');

  @override
  Widget build(BuildContext context) => _EtatDePage(
    key: cle,
    icone: AppIcons.livreOuvert,
    titre: t.salle.support.inconnuTitre,
    detail: t.salle.support.inconnuDetail,
  );
}

/// Un etat qui tient la place d'une page : une icone, un titre, une phrase,
/// une action au plus. Il se reduit d'un bloc quand la place manque (jamais
/// un mot coupe, jamais un debordement).
class _EtatDePage extends StatelessWidget {
  const _EtatDePage({
    required this.icone,
    required this.titre,
    required this.detail,
    this.action,
    super.key,
  });

  final AppIcon icone;
  final String titre;
  final String detail;
  final Widget? action;

  static const double _largeur = 320;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final Widget? action = this.action;
    return DecoratedBox(
      decoration: palette.surfaceRaised.decoration(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: _largeur,
              child: Semantics(
                container: true,
                liveRegion: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconTheme(
                      data: IconThemeData(
                        color: palette.surfaceRaised.onBackground,
                        size: AppSpacing.xxl,
                      ),
                      child: ExcludeSemantics(child: Icon(icone.repos)),
                    ),
                    Ecart.vMd,
                    Text(
                      titre,
                      textAlign: TextAlign.center,
                      style: palette.inkStrong.applyTo(
                        textes.titleMedium ?? const TextStyle(),
                      ),
                    ),
                    Ecart.vSm,
                    Text(
                      detail,
                      textAlign: TextAlign.center,
                      style: palette.inkMuted.applyTo(
                        textes.bodyMedium ?? const TextStyle(),
                      ),
                    ),
                    if (action != null) ...<Widget>[Ecart.vLg, action],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
