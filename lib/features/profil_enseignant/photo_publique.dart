import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/appairage/service_avatar.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/point_rappel.dart';
import '../../core/widgets/raccourci_tactile.dart';
import '../tc_mes_groupes/photo_enseignant.dart';

// `ENS-05A` : la photo publique professionnelle de l'enseignant (doc 04
// section 24), distincte des pieces KYC.
//
// **Aucun branchement serveur avant BR-1 (K-28).** Le port d'envoi par
// defaut echoue honnetement : l'ecran dit que la photo n'a pas ete envoyee,
// il ne simule jamais un envoi. La demonstration (`/demo/enseignant`)
// surcharge le port par un envoi fictif qui ne quitte pas l'appareil.
//
// Aucun etat « En validation » n'est affiche : aucune validation humaine de
// photo n'existe au contrat (doc 04 section 24.2).

/// Une photo choisie, avant envoi.
@immutable
class PhotoChoisie {
  /// Cree la photo choisie.
  const PhotoChoisie({this.octets});

  /// Le contenu du fichier. Nul en demonstration : l'apercu retombe alors sur
  /// les initiales, comme toutes les photos de demonstration non livrees.
  final Uint8List? octets;
}

/// Le choix d'une photo sur l'appareil.
abstract interface class ChoixPhotoPublique {
  /// Ouvre le selecteur. Nul si la personne renonce.
  Future<PhotoChoisie?> choisir();
}

/// L'envoi de la photo publique.
abstract interface class EnvoiPhotoPublique {
  /// Envoie la photo et rend sa cle de stockage, jamais une URL.
  Future<String> envoyer(PhotoChoisie photo);
}

class _ChoixNatif implements ChoixPhotoPublique {
  const _ChoixNatif(this._selecteur);

  final SelecteurPhoto _selecteur;

  @override
  Future<PhotoChoisie?> choisir() async {
    final PhotoEnfant? photo = await _selecteur.choisirPhoto();
    return photo == null ? null : PhotoChoisie(octets: photo.octets);
  }
}

class _EnvoiNonBranche implements EnvoiPhotoPublique {
  const _EnvoiNonBranche();

  @override
  Future<String> envoyer(PhotoChoisie photo) =>
      Future<String>.error(UnsupportedError('photo publique : BR-1'));
}

/// Le choix de photo employe par l'application : le selecteur natif.
final Provider<ChoixPhotoPublique> choixPhotoPubliqueProvider =
    Provider<ChoixPhotoPublique>(
      (Ref ref) => _ChoixNatif(ref.watch(selecteurPhotoProvider)),
    );

/// L'envoi employe par l'application : non branche avant BR-1.
final Provider<EnvoiPhotoPublique> envoiPhotoPubliqueProvider =
    Provider<EnvoiPhotoPublique>((Ref ref) => const _EnvoiNonBranche());

/// La cle de la photo publique confirmee, nulle sans photo.
class PhotoPubliqueControleur extends Notifier<String?> {
  @override
  String? build() => null;

  /// Retient la cle rendue par un envoi confirme.
  void confirmer(String cle) => state = cle;
}

/// La photo publique de l'enseignant.
final NotifierProvider<PhotoPubliqueControleur, String?> photoPubliqueProvider =
    NotifierProvider<PhotoPubliqueControleur, String?>(
      PhotoPubliqueControleur.new,
    );

/// Ouvre `ENS-05A` en feuille (dialogue sur bureau).
///
/// La feuille vit dans l'overlay du `Navigator`, hors du `ProviderScope` de
/// l'appelant : elle recoit donc explicitement le conteneur de l'appelant,
/// pour lire les memes ports (demonstration comprise).
Future<void> ouvrirPhotoPublique(
  BuildContext context, {
  required String prenom,
}) {
  final ProviderContainer conteneur = ProviderScope.containerOf(context);
  return AppBottomSheet.ouvrir<void>(
    context,
    titre: t.enseignant.photo.titre,
    constructeur: (BuildContext _) => UncontrolledProviderScope(
      container: conteneur,
      child: EditeurPhotoPublique(prenom: prenom),
    ),
  );
}

/// Le portrait public de l'enseignant : la photo, ou l'etat « photo a
/// fournir » de [PhotoEnseignant].
class PortraitPublic extends StatelessWidget {
  /// Cree le portrait.
  const PortraitPublic({
    required this.prenom,
    required this.cle,
    super.key,
    this.diametre,
  });

  /// Le prenom, source des initiales de repli.
  final String prenom;

  /// La cle de la photo, nulle sans photo.
  final String? cle;

  /// Le diametre.
  final double? diametre;

  @override
  Widget build(BuildContext context) => Semantics(
    label: cle == null ? null : t.enseignant.photo.alternatif,
    child: PhotoEnseignant(
      enseignant: EnseignantVM(
        enseignantId: '',
        titre: TitreEnseignant.sayyid,
        nomAffichage: prenom,
        photoUrlOuCle: cle,
      ),
      diametre: diametre,
    ),
  );
}

enum _Phase { repos, apercu, envoi, echec }

/// Le contenu de `ENS-05A` : aide, notice, choix, apercu, envoi.
class EditeurPhotoPublique extends ConsumerStatefulWidget {
  /// Cree l'editeur.
  const EditeurPhotoPublique({required this.prenom, super.key});

  /// Le prenom de l'enseignant, pour les initiales de repli.
  final String prenom;

  /// L'action « Choisir une photo » ou « Remplacer la photo ».
  static const Key choisirKey = Key('photoPublique.choisir');

  /// L'action « Utiliser cette photo ».
  static const Key utiliserKey = Key('photoPublique.utiliser');

  /// L'apercu de la photo choisie.
  static const Key apercuKey = Key('photoPublique.apercu');

  @override
  ConsumerState<EditeurPhotoPublique> createState() =>
      _EditeurPhotoPubliqueState();
}

class _EditeurPhotoPubliqueState extends ConsumerState<EditeurPhotoPublique> {
  _Phase _phase = _Phase.repos;
  PhotoChoisie? _photo;
  String? _refus;
  bool _succes = false;

  static const double _diametre = AppSpacing.respiration + AppSpacing.xxxl;

  /// La hauteur d'une ligne de [style] a l'echelle de l'appareil : le point
  /// « obligatoire » se centre sur la premiere ligne du paragraphe.
  static double _hauteurPremiereLigne(BuildContext context, TextStyle style) {
    final TextPainter p = TextPainter(
      text: TextSpan(
        text: 'M',
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final double hauteur = p.height;
    p.dispose();
    return hauteur;
  }

  Future<void> _choisir() async {
    setState(() {
      _refus = null;
      _succes = false;
    });
    final PhotoChoisie? photo;
    try {
      photo = await ref.read(choixPhotoPubliqueProvider).choisir();
    } on Object {
      if (mounted) setState(() => _refus = t.enseignant.photo.selectionEchec);
      return;
    }
    if (!mounted || photo == null) return;
    setState(() {
      _photo = photo;
      _phase = _Phase.apercu;
    });
  }

  Future<void> _utiliser() async {
    final PhotoChoisie? photo = _photo;
    if (photo == null) return;
    setState(() => _phase = _Phase.envoi);
    final String cle;
    try {
      cle = await ref.read(envoiPhotoPubliqueProvider).envoyer(photo);
    } on Object {
      if (mounted) setState(() => _phase = _Phase.echec);
      return;
    }
    // Le succes ne s'affiche que sur reponse (UX_REVIEW_04 ligne ENS-05A c).
    ref.read(photoPubliqueProvider.notifier).confirmer(cle);
    if (mounted) {
      setState(() {
        _photo = null;
        _phase = _Phase.repos;
        _succes = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final TextStyle alerte = palette.inkAlert.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final String? cle = ref.watch(photoPubliqueProvider);
    final PhotoChoisie? photo = _photo;
    final bool avecApercu = photo != null && _phase != _Phase.repos;

    final Widget portrait = avecApercu
        ? _Apercu(photo: photo, prenom: widget.prenom, diametre: _diametre)
        // Toucher la photo ouvre aussi le choix (PHOTO-LIEN-1) : le lien en
        // dessous reste le controle du clavier et du lecteur d'ecran.
        : RaccourciTactile(
            onPress: _phase == _Phase.envoi ? null : _choisir,
            child: PortraitPublic(
              prenom: widget.prenom,
              cle: cle,
              diametre: _diametre,
            ),
          );

    final TextStyle styleAide = palette.inkStrong.applyTo(
      textes.bodyLarge ?? const TextStyle(),
    );
    // KYC-PHOTO-1 : la photo est obligatoire, le point rouge partage le dit
    // (fixe, sans pulsation). COUPE-MOTS-1 point 3 : le point se pose au bord
    // de debut, centre sur la PREMIERE ligne du paragraphe, comme une puce,
    // et non plus colle au bout du texte.
    final double premiereLigne = _hauteurPremiereLigne(context, styleAide);
    final Widget aide = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: premiereLigne,
          child: Center(
            child: PointRappel(
              key: const ValueKey<String>('photo-obligatoire'),
              libelle: t.enseignant.photo.obligatoireLecteur,
              battements: 0,
            ),
          ),
        ),
        Ecart.hSm,
        Expanded(
          child: TexteSansCoupure(t.enseignant.photo.aide, style: styleAide),
        ),
      ],
    );
    final Widget textesAide = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        aide,
        Ecart.vSm,
        TexteSansCoupure(t.enseignant.photo.voile, style: attenue),
        Ecart.vSm,
        TexteSansCoupure(t.enseignant.photo.notice, style: attenue),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // COUPE-MOTS-1 point 3 : a cote du portrait tant que le mot le plus
        // long des textes y tient (« obligatoire » a 200 %, 320 px) ; sinon
        // le portrait passe au-dessus et les textes prennent toute la
        // largeur, au lieu de couper « obligatoir / e ».
        LayoutBuilder(
          builder: (BuildContext contexte, BoxConstraints c) {
            final double colonne =
                c.maxWidth -
                _diametre -
                AppSpacing.lg -
                PointRappel.diametre * 2 -
                AppSpacing.sm;
            final bool cote =
                largeurMotLePlusLong(
                  contexte,
                  '${t.enseignant.photo.aide} '
                  '${t.enseignant.photo.voile} '
                  '${t.enseignant.photo.notice}',
                  styleAide,
                  MediaQuery.textScalerOf(contexte),
                ) <=
                colonne;
            if (!cote) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[portrait, Ecart.vLg, textesAide],
              );
            }
            return Row(
              children: <Widget>[
                portrait,
                Ecart.hLg,
                Expanded(child: textesAide),
              ],
            );
          },
        ),
        Ecart.vXl,
        if (_refus != null) ...<Widget>[
          Semantics(liveRegion: true, child: Text(_refus!, style: alerte)),
          Ecart.vMd,
        ],
        if (_phase == _Phase.echec) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: Text(t.enseignant.photo.echec, style: alerte),
          ),
          Ecart.vMd,
        ],
        if (_succes) ...<Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              t.enseignant.photo.succes,
              style: palette.inkSuccess.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vMd,
        ],
        if (avecApercu && horsLigne) ...<Widget>[
          Text(t.enseignant.photo.horsLigne, style: attenue),
          Ecart.vMd,
        ],
        if (avecApercu)
          // « Choisir une autre photo » au bord de debut, 8 avant le bouton
          // principal (UX_REVIEW_04 ligne ENS-05A b).
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              LienFleche(
                libelle: t.enseignant.photo.autre,
                onPress: _phase == _Phase.envoi ? null : _choisir,
              ),
              ActionPrincipale(
                key: EditeurPhotoPublique.utiliserKey,
                libelle: t.enseignant.photo.utiliser,
                pleineLargeur: false,
                enCours: _phase == _Phase.envoi,
                onPress: horsLigne || _phase == _Phase.envoi ? null : _utiliser,
              ),
            ],
          )
        else
          Align(
            alignment: AlignmentDirectional.centerEnd,
            // Une action secondaire n'est jamais un bouton plein (K-56,
            // PHOTO-LIEN-1) : une ligne de lien, texte et fleche.
            child: LienFleche(
              key: EditeurPhotoPublique.choisirKey,
              libelle: cle == null
                  ? t.enseignant.photo.choisir
                  : t.enseignant.photo.remplacer,
              onPress: _choisir,
            ),
          ),
      ],
    );
  }
}

/// L'apercu de la photo choisie, avant tout envoi (UX_REVIEW_04 ENS-05A a).
class _Apercu extends StatelessWidget {
  const _Apercu({
    required this.photo,
    required this.prenom,
    required this.diametre,
  });

  final PhotoChoisie photo;
  final String prenom;
  final double diametre;

  @override
  Widget build(BuildContext context) {
    final Uint8List? octets = photo.octets;
    return SizedBox.square(
      key: EditeurPhotoPublique.apercuKey,
      dimension: diametre,
      child: octets == null
          // Demonstration : aucun fichier, les initiales en repli.
          ? Semantics(
              label: t.enseignant.photo.alternatif,
              child: AvatarTile(prenom: prenom, diametre: diametre),
            )
          : ClipOval(
              child: Image.memory(
                octets,
                fit: BoxFit.cover,
                semanticLabel: t.enseignant.photo.alternatif,
              ),
            ),
    );
  }
}
